package App::Sqitch;

# ABSTRACT: Sensible database change management

use 5.010;
use strict;
use warnings;
use utf8;
use Getopt::Long;
use Hash::Merge qw(merge);
use Path::Class;
use Config;
use Locale::TextDomain 1.20 qw(App-Sqitch);
use Locale::Messages qw(bind_textdomain_filter);
use App::Sqitch::X qw(hurl);
use Moo 1.002000;
use Type::Utils qw(where declare);
use App::Sqitch::Types qw(Str UserName UserEmail Maybe Config HashRef);
use Encode ();
use Try::Tiny;
use List::Util qw(first);
use IPC::System::Simple 1.17 qw(runx capturex $EXITVAL);
use namespace::autoclean 0.16;
use constant ISWIN => $^O eq 'MSWin32';

our $VERSION = 'v1.5.2'; # VERSION

BEGIN {
    # Force Locale::TextDomain to encode in UTF-8 and to decode all messages.
    $ENV{OUTPUT_CHARSET} = 'UTF-8';
    bind_textdomain_filter 'App-Sqitch' => \&Encode::decode_utf8, Encode::FB_DEFAULT;
}

# Okay to load Sqitch classes now that types are created.
use App::Sqitch::Config;
use App::Sqitch::Command;
use App::Sqitch::Plan;

has options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

has verbosity => (
    is       => 'ro',
    lazy     => 1,
    default  => sub {
        my $self = shift;
        $self->options->{verbosity} // $self->config->get( key => 'core.verbosity' ) // 1;
    }
);

has sysuser => (
    is       => 'ro',
    isa      => Maybe[Str],
    lazy     => 1,
    default  => sub {
        $ENV{ SQITCH_ORIG_SYSUSER } || do {
            # Adapted from User.pm.
            require Encode::Locale;
            return Encode::decode( locale => getlogin )
                || Encode::decode( locale => scalar getpwuid( $< ) )
                || $ENV{ LOGNAME }
                || $ENV{ USER }
                || $ENV{ USERNAME }
                || try {
                    require Win32;
                    Encode::decode( locale => Win32::LoginName() )
                };
        };
    },
);

has user_name => (
    is      => 'ro',
    lazy    => 1,
    isa     => UserName,
    default => sub {
        my $self = shift;
        $ENV{ SQITCH_FULLNAME }
            || $self->config->get( key => 'user.name' )
            || $ENV{ SQITCH_ORIG_FULLNAME }
        || do {
            my $sysname = $self->sysuser || hurl user => __(
                'Cannot find your name; run sqitch config --user user.name "YOUR NAME"'
            );
            if (ISWIN) {
                try { require Win32API::Net } || return $sysname;
                # https://stackoverflow.com/q/12081246/79202
                Win32API::Net::UserGetInfo( $ENV{LOGONSERVER}, $sysname, 10, my $info = {} );
                return $sysname unless $info->{fullName};
                require Encode::Locale;
                return Encode::decode( locale => $info->{fullName} );
            }
            require User::pwent;
            my $name = User::pwent::getpwnam($sysname) || return $sysname;
            $name = ($name->gecos)[0] || return $sysname;
            require Encode::Locale;
            return Encode::decode( locale => $name );
        };
    }
);

has user_email => (
    is      => 'ro',
    lazy    => 1,
    isa     => UserEmail,
    default => sub {
        my $self = shift;
         $ENV{ SQITCH_EMAIL }
            || $self->config->get( key => 'user.email' )
            || $ENV{ SQITCH_ORIG_EMAIL }
        || do {
            my $sysname = $self->sysuser || hurl user => __(
                'Cannot infer your email address; run sqitch config --user user.email you@host.com'
            );
            require Sys::Hostname;
            "$sysname@" . Sys::Hostname::hostname();
        };
    }
);

has config => (
    is      => 'ro',
    isa     => Config,
    lazy    => 1,
    default => sub {
        App::Sqitch::Config->new;
    }
);

has editor => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        return
             $ENV{SQITCH_EDITOR}
          || shift->config->get( key => 'core.editor' )
          || $ENV{VISUAL}
          || $ENV{EDITOR}
          || ( ISWIN ? 'notepad.exe' : 'vi' );
    }
);

has pager_program => (
    is      => "ro",
    lazy    => 1,
    default => sub {
        my $self = shift;
        return
            $ENV{SQITCH_PAGER}
         || $self->config->get(key => "core.pager")
         || $ENV{PAGER};
    },
);

has pager => (
    is       => 'ro',
    lazy     => 1,
    isa      => declare('Pager', where {
        eval { $_->isa('IO::Pager') || $_->isa('IO::Handle') }
    }),
    default  => sub {
        # Dupe and configure STDOUT.
        require IO::Handle;
        my $fh = IO::Handle->new_from_fd(*STDOUT, 'w');
        binmode $fh, ':utf8_strict';

        # Just return if no pager is wanted or there is no TTY.
        return $fh if shift->options->{no_pager} || !(-t *STDOUT);

        # Load IO::Pager and tie the handle to it.
        eval "use IO::Pager 0.34"; die $@ if $@;
        return IO::Pager->new($fh, ':utf8_strict');
    },
);

sub go {
    my $class = shift;
    my @args = @ARGV;

    # 1. Parse core options.
    my $opts = $class->_parse_core_opts(\@args);

    # 2. Load config.
    my $config = App::Sqitch::Config->new;

    # 3. Instantiate Sqitch.
    my $sqitch = $class->new({ options => $opts, config  => $config });

    # 4. Find the command.
    my $cmd = $class->_find_cmd(\@args);

    # 5. Instantiate the command object.
    my $command = $cmd->create({
        sqitch => $sqitch,
        config => $config,
        args   => \@args,
    });

    # IO::Pager respects the PAGER environment variable.
    local $ENV{PAGER} = $sqitch->pager_program;

    # 6. Execute command.
    return try {
        $command->execute( @args ) ? 0 : 2;
    } catch {
        # Just bail for unknown exceptions.
        $sqitch->vent($_) && return 2 unless eval { $_->isa('App::Sqitch::X') };

        # It's one of ours.
        if ($_->exitval == 1) {
            # Non-fatal exception; just send the message to info.
            $sqitch->info($_->message);
        } elsif ($_->ident eq 'DEV') {
            # Vent complete details of fatal DEV error.
            $sqitch->vent($_->as_string);
        } else {
            # Vent fatal error message, trace details.
            $sqitch->vent($_->message);
            $sqitch->trace($_->details_string);
        }

        # Bail.
        return $_->exitval;
    };
}

sub _core_opts {
    return qw(
        chdir|cd|C=s
        etc-path
        no-pager
        quiet
        verbose|V|v+
        help
        man
        version
    );
}

sub _parse_core_opts {
    my ( $self, $args ) = @_;
    my %opts;
    Getopt::Long::Configure(qw(bundling pass_through));
    Getopt::Long::GetOptionsFromArray(
        $args,
        map {
            ( my $k = $_ ) =~ s/[|=+:!].*//;
            $k =~ s/-/_/g;
            $_ => \$opts{$k};
        } $self->_core_opts
    ) or $self->_pod2usage('sqitchusage', '-verbose' => 99 );

    # Handle documentation requests.
    if ($opts{help} || $opts{man}) {
        $self->_pod2usage(
            $opts{help} ? 'sqitchcommands' : 'sqitch',
            '-exitval' => 0,
            '-verbose' => 2,
        );
    }

    # Handle version request.
    if ( delete $opts{version} ) {
        $self->emit( _bn($0), ' (', __PACKAGE__, ') ', __PACKAGE__->VERSION );
        exit;
    }

    # Handle --etc-path.
    if ( $opts{etc_path} ) {
        $self->emit( App::Sqitch::Config->class->system_dir );
        exit;
    }

    # Handle --chdir
    if ( my $dir = delete $opts{chdir} ) {
        chdir $dir or hurl fs => __x(
            'Cannot change to directory {directory}: {error}',
            directory => $dir,
            error   => $!,
        );
    }

    # Normalize the options (remove undefs) and return.
    $opts{verbosity} = delete $opts{verbose};
    $opts{verbosity} = 0 if delete $opts{quiet};
    delete $opts{$_} for grep { !defined $opts{$_} } keys %opts;
    return \%opts;
}

sub _find_cmd {
    my ( $class, $args ) = @_;
    my (@tried, $prev);
    for (my $i = 0; $i <= $#$args; $i++) {
        my $arg = $args->[$i] or next;
        if ($arg =~ /^-/) {
            last if $arg eq '--';
            # Skip the next argument if this looks like a pre-0.9999 option.
            # There shouldn't be many since we now recommend putting options
            # after the command. XXX Remove at some future date.
            $i++ if $arg =~ /^(?:-[duhp])|(?:--(?:db-\w+|client|engine|extension|plan-file|registry|top-dir))$/;
            next;
        }
        push @tried => $arg;
        my $cmd = try { App::Sqitch::Command->class_for($class, $arg) } or next;
        splice @{ $args }, $i, 1;
        return $cmd;
    }

    # No valid command found. Report those we tried.
    $class->vent(__x(
        '"{command}" is not a valid command',
        command => $_,
    )) for @tried;
    $class->_pod2usage('sqitchcommands');
}

sub _pod2usage {
    my ( $self, $doc ) = ( shift, shift );
    require App::Sqitch::Command::help;
    # Help does not need the Sqitch command; since it's required, fake it.
    my $help = App::Sqitch::Command::help->new( sqitch => bless {}, $self );
    $help->find_and_show( $doc || 'sqitch', '-exitval' => 2, @_ );
}

sub run {
    my $self = shift;
    local $SIG{__DIE__} = sub {
        ( my $msg = shift ) =~ s/\s+at\s+.+/\n/ms;
        hurl ipc => $msg;
    };
    if (ISWIN && IPC::System::Simple->VERSION < 1.28) {
        runx ( shift, $self->quote_shell(@_) );
        return $self;
    }
    runx @_;
    return $self;
}

sub shell {
    my ($self, $cmd) = @_;
    local $SIG{__DIE__} = sub {
        ( my $msg = shift ) =~ s/\s+at\s+.+/\n/ms;
        hurl ipc => $msg;
    };
    IPC::System::Simple::run $cmd;
    return $self;
}

sub quote_shell {
    my $self = shift;
    if (ISWIN) {
        require Win32::ShellQuote;
        return Win32::ShellQuote::quote_native(@_);
    }
    require String::ShellQuote;
    return String::ShellQuote::shell_quote(@_);
}

sub capture {
    my $self = shift;
    local $SIG{__DIE__} = sub {
        ( my $msg = shift ) =~ s/\s+at\s+.+/\n/ms;
        hurl ipc => $msg;
    };
    return capturex ( shift, $self->quote_shell(@_) )
        if ISWIN && IPC::System::Simple->VERSION <= 1.25;
    capturex @_;
}

sub _is_interactive {
  return -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;   # Pipe?
}

sub _is_unattended {
    my $self = shift;
    return !$self->_is_interactive && eof STDIN;
}

sub _readline {
    my $self = shift;
    return undef if $self->_is_unattended;
    my $answer = <STDIN>;
    chomp $answer if defined $answer;
    return $answer;
}

sub prompt {
    my $self = shift;
    my $msg  = shift or hurl 'prompt() called without a prompt message';

    # use a list to distinguish a default of undef() from no default
    my @def;
    @def = (shift) if @_;
    # use dispdef for output
    my @dispdef = scalar(@def)
        ? ('[', (defined($def[0]) ? $def[0] : ''), '] ')
        : ('', '');

    # Don't use emit because it adds a newline.
    local $|=1;
    print $msg, ' ', @dispdef;

    if ($self->_is_unattended) {
        hurl io => __(
            'Sqitch seems to be unattended and there is no default value for this question'
        ) unless @def;
        print "$dispdef[1]\n";
    }

    my $ans = $self->_readline;

    if ( !defined $ans or !length $ans ) {
        # Ctrl-D or user hit return;
        $ans = @def ? $def[0] : '';
    }

    return $ans;
}

sub ask_yes_no {
    my ($self, @msg) = (shift, shift);
    hurl 'ask_yes_no() called without a prompt message' unless $msg[0];

    my $y = __p 'Confirm prompt answer yes', 'Yes';
    my $n = __p 'Confirm prompt answer no',  'No';
    push @msg => $_[0] ? $y : $n if @_;

    my $answer;
    my $i = 3;
    while ($i--) {
        $answer = $self->prompt(@msg);
        return 1 if $y =~ /^\Q$answer/i;
        return 0 if $n =~ /^\Q$answer/i;
        $self->emit(__ 'Please answer "y" or "n".');
    }

    hurl io => __ 'No valid answer after 3 attempts; aborting';
}

sub ask_y_n {
    my $self = shift;
    $self->warn('The ask_y_n() method has been deprecated. Use ask_yes_no() instead.');
    return $self->ask_yes_no(@_) unless @_ > 1;

    my ($msg, $def) = @_;
    hurl 'Invalid default value: ask_y_n() default must be "y" or "n"'
        if $def && $def !~ /^[yn]/i;
    return $self->ask_yes_no($msg, $def =~ /^y/i ? 1 : 0);
}

sub spool {
    my ($self, $fh) = (shift, shift);
    local $SIG{__WARN__} = sub { }; # Silence warning.
    my $pipe;
    if (ISWIN) {
        no warnings;
        open $pipe, '|' . $self->quote_shell(@_) or hurl io => __x(
            'Cannot exec {command}: {error}',
            command => $_[0],
            error   => $!,
        );
    } else {
        no warnings;
        open $pipe, '|-', @_ or hurl io => __x(
            'Cannot exec {command}: {error}',
            command => $_[0],
            error   => $!,
        );
    }

    local $SIG{PIPE} = sub { die 'spooler pipe broke' };
    if (ref $fh eq 'ARRAY') {
        for my $h (@{ $fh }) {
            print $pipe $_ while <$h>;
        }
    } else {
        print $pipe $_ while <$fh>;
    }

    close $pipe or hurl io => $! ? __x(
        'Error closing pipe to {command}: {error}',
         command => $_[0],
         error   => $!,
    ) : __x(
        '{command} unexpectedly returned exit value {exitval}',
        command => $_[0],
        exitval => ($? >> 8),
    );
    return $self;
}

sub probe {
    my ($ret) = shift->capture(@_);
    chomp $ret if $ret;
    return $ret;
}

sub _bn {
    require File::Basename;
    File::Basename::basename($0);
}

sub _prepend {
    my $prefix = shift;
    my $msg = join '', map { $_ // '' } @_;
    $msg =~ s/^/$prefix /gms;
    return $msg;
}

sub page {
    my $pager = shift->pager;
    return $pager->say(@_);
}

sub page_literal {
    my $pager = shift->pager;
    return $pager->print(@_);
}

sub trace {
    my $self = shift;
    $self->emit( _prepend 'trace:', @_ ) if $self->verbosity > 2;
}

sub trace_literal {
    my $self = shift;
    $self->emit_literal( _prepend 'trace:', @_ ) if $self->verbosity > 2;
}

sub debug {
    my $self = shift;
    $self->emit( _prepend 'debug:', @_ ) if $self->verbosity > 1;
}

sub debug_literal {
    my $self = shift;
    $self->emit_literal( _prepend 'debug:', @_ ) if $self->verbosity > 1;
}

sub info {
    my $self = shift;
    $self->emit(@_) if $self->verbosity;
}

sub info_literal {
    my $self = shift;
    $self->emit_literal(@_) if $self->verbosity;
}

sub comment {
    my $self = shift;
    $self->emit( _prepend '#', @_ );
}

sub comment_literal {
    my $self = shift;
    $self->emit_literal( _prepend '#', @_ );
}

sub emit {
    shift;
    local $|=1;
    say @_;
}

sub emit_literal {
    shift;
    local $|=1;
    print @_;
}

sub vent {
    shift;
    my $fh = select;
    select STDERR;
    local $|=1;
    say STDERR @_;
    select $fh;
}

sub vent_literal {
    shift;
    my $fh = select;
    select STDERR;
    local $|=1;
    print STDERR @_;
    select $fh;
}

sub warn {
    my $self = shift;
    $self->vent(_prepend 'warning:', @_);
}

sub warn_literal {
    my $self = shift;
    $self->vent_literal(_prepend 'warning:', @_);
}

1;

__END__

=head1 Name

App::Sqitch - Sensible database change management

=head1 Synopsis

  use App::Sqitch;
  exit App::Sqitch->go;

=head1 Description

This module provides the implementation for L<sqitch>. You probably want to
read L<its documentation|sqitch>, or L<the tutorial|sqitchtutorial>. Unless
you want to hack on Sqitch itself, or provide support for a new engine or
L<command|Sqitch::App::Command>. In which case, you will find this API
documentation useful.

=head1 Interface

=head2 Class Methods

=head3 C<go>

  App::Sqitch->go;

Called from C<sqitch>, this class method parses command-line options and
arguments in C<@ARGV>, parses the configuration file, constructs an
App::Sqitch object, constructs a command object, and runs it.

=head2 Constructor

=head3 C<new>

  my $sqitch = App::Sqitch->new(\%params);

Constructs and returns a new Sqitch object. The supported parameters include:

=over

=item C<options>

=item C<user_name>

=item C<user_email>

=item C<editor>

=item C<verbosity>

=back

=head2 Accessors

=head3 C<user_name>

=head3 C<user_email>

=head3 C<editor>

=head3 C<options>

  my $options = $sqitch->options;

Returns a hashref of the core command-line options.

=head3 C<config>

  my $config = $sqitch->config;

Returns the full configuration, combined from the project, user, and system
configuration files.

=head3 C<verbosity>

=head2 Instance Methods

=head3 C<run>

  $sqitch->run('echo', '-n', 'hello');

Runs a system command and waits for it to finish. Throws an exception on
error. Does not use the shell, so arguments must be passed as a list. Use
C<shell> to run a command and its arguments as a single string.

=over

=item C<target>

The name of the target, as passed.

=item C<uri>

A L<database URI|URI::db> object, to be used to connect to the target
database.


=item C<registry>

The name of the Sqitch registry in the target database.

=back

If the C<$target> argument looks like a database URI, it will simply returned
in the hash reference. If the C<$target> argument corresponds to a target
configuration key, the target configuration will be returned, with the C<uri>
value a upgraded to a L<URI> object. Otherwise returns C<undef>.

=head3 C<shell>

  $sqitch->shell('echo -n hello');

Shells out a system command and waits for it to finish. Throws an exception on
error. Always uses the shell, so a single string must be passed encapsulating
the entire command and its arguments. Use C<quote_shell> to assemble strings
into a single shell command. Use C<run> to execute a list without a shell.

=head3 C<quote_shell>

  my $cmd = $sqitch->quote_shell('echo', '-n', 'hello');

Assemble a list into a single string quoted for execution by C<shell>. Useful
for combining a specified command, such as C<editor()>, which might include
the options in the string, for example:

  $sqitch->shell( $sqitch->editor, $sqitch->quote_shell($file) );

=head3 C<capture>

  my @files = $sqitch->capture(qw(ls -lah));

Runs a system command and captures its output to C<STDOUT>. Returns the output
lines in list context and the concatenation of the lines in scalar context.
Throws an exception on error.

=head3 C<probe>

  my $git_version = $sqitch->capture(qw(git --version));

Like C<capture>, but returns just the C<chomp>ed first line of output.

=head3 C<spool>

  $sqitch->spool($sql_file_handle, 'sqlite3', 'my.db');
  $sqitch->spool(\@file_handles, 'sqlite3', 'my.db');

Like run, but spools the contents of one or ore file handle to the standard
input the system command. Returns true on success and throws an exception on
failure.

=head3 C<trace>

=head3 C<trace_literal>

  $sqitch->trace_literal('About to fuzzle the wuzzle.');
  $sqitch->trace('Done.');

Send trace information to C<STDOUT> if the verbosity level is 3 or higher.
Trace messages will have C<trace: > prefixed to every line. If it's lower than
3, nothing will be output. C<trace> appends a newline to the end of the
message while C<trace_literal> does not.

=head3 C<debug>

=head3 C<debug_literal>

  $sqitch->debug('Found snuggle in the crib.');
  $sqitch->debug_literal('ITYM "snuggie".');

Send debug information to C<STDOUT> if the verbosity level is 2 or higher.
Debug messages will have C<debug: > prefixed to every line. If it's lower than
2, nothing will be output. C<debug> appends a newline to the end of the
message while C<debug_literal> does not.

=head3 C<info>

=head3 C<info_literal>

  $sqitch->info('Nothing to deploy (up-to-date)');
  $sqitch->info_literal('Going to frobble the shiznet.');

Send informational message to C<STDOUT> if the verbosity level is 1 or higher,
which, by default, it is. Should be used for normal messages the user would
normally want to see. If verbosity is lower than 1, nothing will be output.
C<info> appends a newline to the end of the message while C<info_literal> does
not.

=head3 C<comment>

=head3 C<comment_literal>

  $sqitch->comment('On database flipr_test');
  $sqitch->comment_literal('Uh-oh...');

Send comments to C<STDOUT> if the verbosity level is 1 or higher, which, by
default, it is. Comments have C<# > prefixed to every line. If verbosity is
lower than 1, nothing will be output. C<comment> appends a newline to the end
of the message while C<comment_literal> does not.

=head3 C<emit>

=head3 C<emit_literal>

  $sqitch->emit('core.editor=emacs');
  $sqitch->emit_literal('Getting ready...');

Send a message to C<STDOUT>, without regard to the verbosity. Should be used
only if the user explicitly asks for output, such as for C<sqitch config --get
core.editor>. C<emit> appends a newline to the end of the message while
C<emit_literal> does not.

=head3 C<vent>

=head3 C<vent_literal>

  $sqitch->vent('That was a misage.');
  $sqitch->vent_literal('This is going to be bad...');

Send a message to C<STDERR>, without regard to the verbosity. Should be used
only for error messages to be printed before exiting with an error, such as
when reverting failed changes. C<vent> appends a newline to the end of the
message while C<vent_literal> does not.

=head3 C<page>

=head3 C<page_literal>

  $sqitch->page('Search results:');
  $sqitch->page("Here we go\n");

Like C<emit()>, but sends the output to a pager handle rather than C<STDOUT>.
Unless there is no TTY (such as when output is being piped elsewhere), in
which case it I<is> sent to C<STDOUT>. C<page> appends a newline to the end of
the message while C<page_literal> does not. Meant to be used to send a lot of
data to the user at once, such as when display the results of searching the
event log:

  $iter = $engine->search_events;
  while ( my $change = $iter->() ) {
      $sqitch->page(join ' - ', @{ $change }{ qw(change_id event change) });
  }

=head3 C<warn>

=head3 C<warn_literal>

  $sqitch->warn('Could not find nerble; using nobble instead.');
  $sqitch->warn_literal("Cannot read file: $!\n");

Send a warning messages to C<STDERR>. Warnings will have C<warning: > prefixed
to every line. Use if something unexpected happened but you can recover from
it. C<warn> appends a newline to the end of the message while C<warn_literal>
does not.

=head3 C<prompt>

  my $ans = $sqitch->('Why would you want to do this?', 'because');

Prompts the user for input and returns that input. Pass in an optional default
value for the user to accept or to be used if Sqitch is running unattended. An
exception will be thrown if there is no prompt message or if Sqitch is
unattended and there is no default value.

=head3 C<ask_yes_no>

  if ( $sqitch->ask_yes_no('Are you sure?', 1) ) { # do it! }

Prompts the user with a "yes" or "no" question. Returns true if the user
replies in the affirmative and false if the reply is in the negative. If the
optional second argument is passed and true, the answer will default to the
affirmative. If the second argument is passed but false, the answer will
default to the negative. When a translation library is in use, the affirmative
and negative replies from the user should be localized variants of "yes" and
"no", and will be matched as such. If no translation library is in use, the
answers will default to the English "yes" and "no".

If the user inputs an invalid value three times, an exception will be thrown.
An exception will also be thrown if there is no message. As with C<prompt()>,
an exception will be thrown if Sqitch is running unattended and there is no
default.

=head3 C<ask_y_n>

This method has been deprecated in favor of C<ask_yes_no()> and will be
removed in a future version of Sqitch.


=head2 Constants

=head3 C<ISWIN>

  my $app = 'sqitch' . ( ISWIN ? '.bat' : '' );

True when Sqitch is running on Windows, and false when it's not.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 License

Copyright (c) 2012-2025 David E. Wheeler, 2012-2021 iovation Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
