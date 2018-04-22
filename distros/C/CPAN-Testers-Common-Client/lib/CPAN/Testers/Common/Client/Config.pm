package CPAN::Testers::Common::Client::Config;
use strict;
use warnings;

use Carp               ();
use File::Glob         ();
use File::Spec    3.19 ();
use File::HomeDir 0.58 ();
use File::Path    qw( mkpath );
use IPC::Cmd;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        _prompt => undef,
        _warn   => undef,
        _print  => undef,
        _config => {},
    }, $class;

    my $warn = exists $args{'warn'} ? $args{'warn'} : sub { warn @_ };
    $self->_set_mywarn( $warn )
        or Carp::croak q(the 'warn' parameter must be a coderef);

    my $print = exists $args{'print'} ? $args{'print'} : sub { print @_ };
    $self->_set_myprint( $print )
        or Carp::croak q(the 'print' parameter must be a coderef);

    # prompt is optional
    if (exists $args{'prompt'}) {
        $self->_set_myprompt( $args{'prompt'} )
            or Carp::croak q(the 'prompt' parameter must be a coderef);
    }

    return $self;
}

sub read {
    my $self = shift;
    my $config = $self->_read_config_file or return;
    my $options = $self->_get_config_options( $config );
    $self->_config_data( $options );
    return 1;
}

#######################
### basic accessors ###
#######################

sub email_from  { return shift->{_config}{email_from} }
sub edit_report { return shift->_config_data_for('edit_report', @_) }
sub send_report { return shift->_config_data_for('send_report', @_) }
sub send_duplicates { return shift->_config_data_for('send_duplicates', @_) }
sub transport { return shift->{_config}{transport} }
sub transport_name { return shift->{_transport_name} }
sub transport_args { return shift->{_transport_args} }

sub get_config_dir {
    if ( defined $ENV{PERL_CPAN_REPORTER_DIR} &&
         length  $ENV{PERL_CPAN_REPORTER_DIR}
    ) {
        return $ENV{PERL_CPAN_REPORTER_DIR};
    }

    my $conf_dir = File::Spec->catdir(File::HomeDir->my_home, ".cpanreporter");

    if ($^O eq 'MSWin32') {
      my $alt_dir = File::Spec->catdir(File::HomeDir->my_documents, ".cpanreporter");
      $conf_dir = $alt_dir if -d $alt_dir && ! -d $conf_dir;
    }

    return $conf_dir;
}

sub get_config_filename {
    if (  defined $ENV{PERL_CPAN_REPORTER_CONFIG} &&
          length  $ENV{PERL_CPAN_REPORTER_CONFIG}
    ) {
        return $ENV{PERL_CPAN_REPORTER_CONFIG};
    }
    else {
        return File::Spec->catdir( get_config_dir, 'config.ini' );
    }
}

# the provided subrefs do not know about $self.
sub mywarn   { my $r = shift->{_warn}; return $r->(@_)   }
sub myprint  { my $r = shift->{_print}; return $r->(@_)  }
sub myprompt { my $r = shift->{_prompt}; return $r->(@_) }
sub _has_prompt { return exists $_[0]->{_prompt} }

sub setup {
    my $self = shift;

    Carp::croak q{please provide a 'prompt' coderef to new()}
        unless $self->_has_prompt;

    my $config_dir = $self->get_config_dir;
    mkpath $config_dir unless -d $config_dir;

    unless ( -d $config_dir ) {
        $self->myprint(
          "\nCPAN Testers: couldn't create configuration directory '$config_dir': $!"
        );
        return;
    }

    my $config_file = $self->get_config_filename;

    # explain grade:action pairs to the user
    $self->myprint( _grade_action_prompt() );

    my ($config, $existing_options) = ( {}, {} );

    # read or create the config file
    if ( -f $config_file ) {
        $self->myprint("\nCPAN Testers: found your config file at:\n$config_file\n");

        # bail out if we can't read it
        $existing_options = $self->_read_config_file;
        if ( !$existing_options ) {
            $self->mywarn("\nCPAN Testers: configuration will not be changed\n");
            return;
        }

        $self->myprint("\nCPAN Testers: Updating your configuration settings:\n");
    }
    else {
        $self->myprint("\nCPAN Testers: no config file found; creating a new one.\n");
    }

    my %spec = $self->_config_spec;

    foreach my $k ( $self->_config_order ) {
        my $option_data = $spec{$k};
        $self->myprint("\n$option_data->{info}\n");

        # options with defaults are mandatory
        if (defined $option_data->{default}) {

            # as a side-effect, people may use '' without
            # an actual default value to mark the option
            # as mandatory. So we only show de default value
            # if there is one.
            if (length $option_data->{default}) {
                $self->myprint("(Recommended: '$option_data->{default}')\n\n");
            }
            # repeat until validated
            PROMPT:
            while ( defined (
                my $answer = $self->myprompt(
                    "$k?",
                    $existing_options->{$k} || $option_data->{default}
                )
            )) {
                # TODO: I don't think _validate() is being used
                # because of this. Should we remove it?
                if ( ! $option_data->{validate} ||
                       $option_data->{validate}->($self, $k, $answer, $config)
                ) {
                    $config->{$k} = $answer;
                    last PROMPT;
                }
            }
        }
        else {
            # only initialize options without defaults if the answer
            # matches non white space and validates properly.
            # Otherwise, just ignore it.
            my $answer = $self->myprompt("$k?", $existing_options->{$k} || q{});
            if ( $answer =~ /\S/ ) {
                $config->{$k} = $answer;
            }
        }
        # delete existing keys as we proceed so we know what's left
        delete $existing_options->{$k};
    }

    # initialize remaining options
    $self->myprint(
        "\nYour CPAN Testers config file also contains these advanced options\n\n"
    ) if keys %$existing_options;

    foreach my $k ( keys %$existing_options ) {
        $config->{$k} = $self->myprompt("$k?", $existing_options->{$k});
    }

    $self->myprint("\nCPAN Testers: writing config file to '$config_file'.\n");
    if ( $self->_write_config_file( $config ) ) {
        $self->_config_data( $config );
        return $config;
    }
    else {
        return;
    }
}

#--------------------------------------------------------------------------#
# _config_spec -- returns configuration options information
#
# Keys include
#   default     --  recommended value, used in prompts and as a fallback
#                   if an options is not set; mandatory if defined
#   prompt      --  short prompt for EU::MM prompting
#   info        --  long description shown before prompting
#   validate    --  CODE ref; return normalized option or undef if invalid
#--------------------------------------------------------------------------#
sub _config_spec {
    return (
    email_from => {
        default => '',
        prompt => 'What email address will be used to reference your reports?',
        validate => \&_validate_email,
        info => <<'HERE',
CPAN Testers requires a valid email address to identify senders
in the body of a test report. Please use a standard email format
like: "John Doe" <jdoe@example.com>
HERE
    },
    smtp_server => {
        default => undef, # (deprecated)
        prompt  => "[DEPRECATED] It's safe to remove this from your config file.",
    },
    edit_report => {
        default => 'default:ask/no pass/na:no',
        prompt => 'Do you want to review or edit the test report?',
        validate => \&_validate_grade_action_pair,
        info => <<'HERE',
Before test reports are sent, you may want to review or edit the test
report and add additional comments about the result or about your system
or Perl configuration.  By default, we will ask after each report is
generated whether or not you would like to edit the report. This option
takes "grade:action" pairs.
HERE
    },
    send_report => {
        default => 'default:ask/yes pass/na:yes',
        prompt => 'Do you want to send the report?',
        validate => \&_validate_grade_action_pair,
        info => <<'HERE',
By default, we will prompt you for confirmation that the test report
should be sent before actually doing it. This gives the opportunity to
skip sending particular reports if you need to (e.g. if you caused the
failure). This option takes "grade:action" pairs.
HERE
    },
    transport => {
        default  => 'Metabase uri https://metabase.cpantesters.org/api/v1/ id_file metabase_id.json',
        prompt   => 'Which transport system will be used to transmit the reports?',
        validate => \&_validate_transport,
        info     => <<'HERE',
CPAN Testers gets your reports over HTTPS using Metabase. This option lets
you set a different uri, transport mechanism and metabase profile path. If you
are receiving HTTPS errors, you may change the uri to use plain HTTP, though
this is not recommended. Unless you know what you're doing, just accept
the default value.
HERE
    },
    send_duplicates => {
        default => 'default:no',
        prompt => 'This report is identical to a previous one. Send it anyway?',
        validate => \&_validate_grade_action_pair,
        info => <<'HERE',
CPAN Testers records tests grades for each distribution, version and
platform. By default, duplicates of previous results will not be sent at
all, regardless of the value of the "send_report" option. This option takes
"grade:action" pairs.
HERE
    },
    send_PL_report => {
        prompt => 'Do you want to send the PL report?',
        default => undef,
        validate => \&_validate_grade_action_pair,
    },
    send_make_report => {
        prompt => 'Do you want to send the make/Build report?',
        default => undef,
        validate => \&_validate_grade_action_pair,
    },
    send_test_report => {
        prompt => 'Do you want to send the test report?',
        default => undef,
        validate => \&_validate_grade_action_pair,
    },
    send_skipfile => {
        prompt => "What file has patterns for things that shouldn't be reported?",
        default => undef,
        validate => \&_validate_skipfile,
    },
    cc_skipfile => {
        prompt => "What file has patterns for things that shouldn't CC to authors?",
        default => undef,
        validate => \&_validate_skipfile,
    },
    command_timeout => {
        prompt => 'If no timeout is set by CPAN, halt system commands after how many seconds?',
        default => undef,
        validate => \&_validate_seconds,
    },
    email_to => {
        default => undef,
        validate => \&_validate_email,
    },
    editor => {
        default => undef,
    },
    debug => {
        default => undef,
    },
    retry_submission => {
        default => undef,
    },
  );
}

#--------------------------------------------------------------------------#
# _config_order -- determines order of interactive config.  Only items
# in interactive config will be written to a starter config file
#--------------------------------------------------------------------------#
sub _config_order {
    return qw(
        email_from
        edit_report
        send_report
        transport
    );
}


sub _set_myprompt {
    my ($self, $prompt) = @_;
    if ($prompt and ref $prompt and ref $prompt eq 'CODE') {
        $self->{_prompt} = $prompt;
        return $self;
    }
    return;
}

sub _set_mywarn {
    my ($self, $warn) = @_;
    if ($warn and ref $warn and ref $warn eq 'CODE') {
        $self->{_warn} = $warn;
        return $self;
    }
    return;
}

sub _set_myprint {
    my ($self, $print) = @_;
    if ($print and ref $print and ref $print eq 'CODE') {
        $self->{_print} = $print;
        return $self;
    }
    return;
}

# _read_config_file() is a trimmed down version of
# Adam Kennedy's great Config::Tiny to fit our needs
# (while also avoiding the extra toolchain dep).
sub _read_config_file {
    my $self = shift;
    my $file = $self->get_config_filename;

    # check the file
    return $self->_config_error("File '$file' does not exist") unless -e $file;
    return $self->_config_error("'$file' is a directory, not a file") unless -f _;
    return $self->_config_error("Insufficient permissions to read '$file'") unless -r _;

    open my $fh, '<', $file
        or return $self->_config_error("Failed to open file '$file': $!");
    my $contents = do { local $/; <$fh> };
    close $fh;

    my $config = {};
    my $counter = 0;
    foreach my $line ( split /(?:\015{1,2}\012|\015|\012)/, $contents ) {
        $counter++;
        next if $line =~ /^\s*(?:\#|\;|$)/; # skip comments and empty lines
        $line =~ s/\s\;\s.+$//g;            # remove inline comments

        # handle properties
        if ( $line =~ /^\s*([^=]+?)\s*=\s*(.*?)\s*$/ ) {
            $config->{$1} = $2;
            next;
        }

        return $self->_config_error(
            "Syntax error in config file '$file' at line $counter: '$_'"
        );
    }
    return $config;
}

sub _write_config_file {
    my ($self, $config) = @_;

    my $contents = '';
    foreach my $item ( sort keys %$config ) {
        if ( $config->{$item} =~ /(?:\012|\015)/s ) {
            return $self->_config_error("Illegal newlines in option '$item'");
        }
        $contents .= "$item=$config->{$item}\n";
    }

    my $file = $self->get_config_filename;
    open my $fh, '>', $file
        or return $self->_config_error("Error writing config file '$file': $!");

    print $fh $contents;
    close $fh;
}

sub _config_error {
    my ($self, $msg) = @_;
    $self->mywarn( "\nCPAN Testers: $msg\n" );
    return;
}

sub _config_data {
    my ($self, $config) = @_;
    $self->{_config} = $config if $config;
    return $self->{_config};
}

sub _config_data_for {
    my ($self, $type, $grade) = @_;
    my %spec = $self->_config_spec;
    my $data = exists $self->{_config}{$type} ? $self->{_config}{$type} : q();

    my $dispatch = $spec{$type}{validate}->(
        $self,
        $type,
        join( q{ }, 'default:no', $data )
    );
    return lc( $dispatch->{$grade} || $dispatch->{default} );
}

# extract and return valid options,
# with fallback to defaults
sub _get_config_options {
    my ($self, $config) = @_;
    my %spec = $self->_config_spec;

    my %active;
    OPTION: foreach my $option (keys %spec) {
        if (exists $config->{$option} ) {
            my $val = $config->{$option};
            if ( $spec{$option}{validate}
              && !$spec{$option}{validate}->($self, $option, $val)
            ) {
                $self->mywarn( "\nCPAN Testers: invalid option '$val' in '$option'. Using default value instead.\n\n" );
                $active{$option} = $spec{$option}{default};
                next OPTION;
            }
            $active{$option} = $val;
        }
        else {
            $active{$option} = $spec{$option}{default}
                if defined $spec{$option}{default};
        }
    }
    return \%active;
}

#--------------------------------------------------------------------------#
# _normalize_id_file
#--------------------------------------------------------------------------#

sub _normalize_id_file {
    my ($self, $id_file) = @_;

    # if file path is enclosed in quotes, remove them:
    if ($id_file =~ s/\A(['"])(.+)\1\z/$2/) {
        $id_file =~ s/\\(.)/$1/g;
    }

    # Windows does not use ~ to signify a home directory
    if ( $^O eq 'MSWin32' && $id_file =~ m{^~/(.*)} ) {
        $id_file = File::Spec->catdir(File::HomeDir->my_home, $1);
    }
    elsif ( $id_file =~ /~/ ) {
        $id_file = File::Spec->canonpath(File::Glob::bsd_glob( $id_file ));
    }
    unless ( File::Spec->file_name_is_absolute( $id_file ) ) {
        $id_file = File::Spec->catfile(
            $self->get_config_dir, $id_file
        );
    }
    return $id_file;
}

sub _generate_profile {
    my ($id_file, $email) = @_;

    my $cmd = IPC::Cmd::can_run('metabase-profile');
    return unless $cmd;

    # XXX this is an evil assumption about email addresses, but
    # might do for simple cases that users might actually provide

    my @opts = ("--output" => $id_file);

    if ($email =~ /\A(.+)\s+<([^>]+)>\z/ ) {
        push @opts, "--email"   => $2;
        my $name = $1;
        $name =~ s/\A["'](.*)["']\z/$1/;
        push ( @opts, "--name"    => $1)
            if length $name;
    }
    else {
        push @opts, "--email"   => $email;
    }

    # XXX profile 'secret' is really just a generated API key, so we
    # can create something fairly random for the user and use that
    push @opts, "--secret"      => sprintf("%08x", rand(2**31));

    return scalar IPC::Cmd::run(
        command => [ $cmd, @opts ],
        verbose => 1,
    );
}

sub _grade_action_prompt {
    return << 'HERE';

Some of the following configuration options require one or more "grade:action"
pairs that determine what grade-specific action to take for that option.
These pairs should be space-separated and are processed left-to-right. See
CPAN::Testers::Common::Client::Config documentation for more details.

    GRADE   :   ACTION  ======> EXAMPLES
    -------     -------         --------
    pass        yes             default:no
    fail        no              default:yes pass:no
    unknown     ask/no          default:ask/no pass:yes fail:no
    na          ask/yes
    default

HERE
}

sub _is_valid_action {
    my $action = shift;
    my @valid_actions = qw{ yes no ask/yes ask/no ask };
    return grep { $action eq $_ } @valid_actions;
}


sub _is_valid_grade {
    my $grade = shift;
    my @valid_grades = qw{ pass fail unknown na default };
    return grep { $grade eq $_ } @valid_grades;
}

#--------------------------------------------------------------------------#
# _validate
#
# anything is OK if there is no validation subroutine
#--------------------------------------------------------------------------#

sub _validate {
    my ($self, $name, $value) = @_;
    my $specs = $self->_config_spec;
    return 1 if ! exists $specs->{$name}{validate};
    return $specs->{$name}{validate}->($self, $name, $value);
}

#--------------------------------------------------------------------------#
# _validate_grade_action
# returns hash of grade => action
# returns undef
#--------------------------------------------------------------------------#

sub _validate_grade_action_pair {
    my ($self, $name, $option) = @_;
    $option ||= 'no';

    my %ga_map; # grade => action

    PAIR: for my $grade_action ( split q{ }, $option ) {
        my ($grade_list,$action);
        if ( $grade_action =~ m{.:.} ) {
            # parse pair for later check
            ($grade_list, $action) = $grade_action =~ m{\A([^:]+):(.+)\z};
        }
        elsif ( _is_valid_action($grade_action) ) {
            # action by itself
            $ga_map{default} = $grade_action;
            next PAIR;
        }
        elsif ( _is_valid_grade($grade_action) ) {
            # grade by itself
            $ga_map{$grade_action} = 'yes';
            next PAIR;
        }
        elsif( $grade_action =~ m{./.} ) {
            # gradelist by itself, so setup for later check
            $grade_list = $grade_action;
            $action = 'yes';
        }
        else {
            # something weird, so warn and skip
            $self->mywarn(
                "\nignoring invalid grade:action '$grade_action' for '$name'.\n\n"
            );
            next PAIR;
        }

        # check gradelist
        my %grades = map { ($_,1) } split( "/", $grade_list);
        for my $g ( keys %grades ) {
            if ( ! _is_valid_grade($g) ) {
                $self->mywarn(
                    "\nignoring invalid grade '$g' in '$grade_action' for '$name'.\n\n"
                );
                delete $grades{$g};
            }
        }

        # check action
        if ( ! _is_valid_action($action) ) {
            $self->mywarn(
                "\nignoring invalid action '$action' in '$grade_action' for '$name'.\n\n"
            );
            next PAIR;
        }

        # otherwise, it all must be OK
        $ga_map{$_} = $action for keys %grades;
    }

    return scalar(keys %ga_map) ? \%ga_map : undef;
}

sub _validate_transport {
    my ($self, $name, $option, $config) = @_;
    $config = $self->_config_data unless $config;
    my $transport = '';
    my $transport_args = '';

    if ( $option =~ /^(\w+(?:::\w+)*)\s*(\S.*)$/ ) {
        ($transport, $transport_args) = ($1, $2);
        my $full_class = "Test::Reporter::Transport::$transport";
        eval "use $full_class ()";
        if ($@) {
            $self->mywarn(
                "\nerror loading $full_class. Please install the missing module or choose a different transport mechanism.\n\n"
            );
        }
    }
    else {
        $self->mywarn(
            "\nPlease provide a transport mechanism.\n\n"
        );
        return;
    }

    # we do extra validation for Metabase and offer to create the profile
    if ( $transport eq 'Metabase' ) {
        unless ( $transport_args =~ /\buri\s+\S+/ ) {
            $self->mywarn(
                "\nPlease provide a target uri.\n\n"
            );
            return;
        }

        unless ( $transport_args =~ /\bid_file\s+(\S.+?)\s*$/ ) {
            $self->mywarn(
                "\nPlease specify an id_file path.\n\n"
            );
            return;
        }

        my $id_file = $self->_normalize_id_file($1);

        # Offer to create if it doesn't exist
        if ( ! -e $id_file )  {
            return unless $self->_has_prompt; # skip unless we have a prompt!

            my $answer = $self->myprompt(
                "\nWould you like to run 'metabase-profile' now to create '$id_file'?", "y"
            );
            if ( $answer =~ /^y/i ) {
                return unless _generate_profile( $id_file, $config->{email_from} );
            }
            else {
                $self->mywarn( <<"END_ID_FILE" );
You can create a Metabase profile by typing 'metabase-profile' in your
command prompt and moving the resulting file to the location you specified.
If you did not specify an absolute path, put it in your .cpanreporter
directory.  You will need to do this before continuing.
END_ID_FILE
                return;
            }
        }
        # Warn and fail validation if there but not readable
        elsif (! -r $id_file) {
            $self->mywarn(
                "'$id_file' was not readable.\n\n"
            );
            return;
        }

        # when we store the transport args internally,
        # we should use the normalized id_file
        # (always quoted to support spaces).
        # Since _normalize_id_file removed '\' from the path in order
        # to test the real file path, we now need to put them back if we
        # have them, as _parse_transport_args expects '\\' instead of '\':
        $id_file =~ s/\\/\\\\/g;
        $transport_args =~ s/(\bid_file\s+)(\S.+?)\s*$/$1"$id_file"/;
    } # end Metabase

    $self->{_transport_name} = $transport;
    $self->{_transport_args} = _parse_transport_args($transport_args);
    return 1;
}

# converts a string into a list of arguments for the transport module.
# arguments are separated by spaces. If an argument has space, enclose it
# using ' or ".
sub _parse_transport_args {
    my ($transport_args) = @_;
    my @args;
    while ($transport_args =~ /\s*((?:[^'"\s]\S*)|(["'])(?:(?>\\?).)*?\2)/g) {
        my $arg = $1;
        if ($2) {
            $arg =~ s/\A(['"])(.+)\1\z/$2/;
            $arg =~ s/\\(.)/$1/g;
        }
        push @args, $arg;
    }
    return \@args;
}

sub _validate_seconds {
    my ($self, $name, $option) = @_;
    return unless defined($option) && length($option)
        && ($option =~ /^\d/) && $option >= 0;
    return $option;
}

sub _validate_skipfile {
    my ($self, $name, $option) = @_;
    return unless $option;
    my $skipfile = File::Spec->file_name_is_absolute( $option )
                 ? $option : File::Spec->catfile( get_config_dir(), $option );
    return -r $skipfile ? $skipfile : undef;
}

# not really a validation, just making sure
# it's not empty and contains a '@'
sub _validate_email {
  my ($self, $name, $option) = @_;
  return unless $option;
  my @data = split '@', $option;
  return $option if scalar @data == 2;
}


1;
__END__

=head1 NAME

CPAN::Testers::Common::Client::Config - basic configuration for CPAN Testers clients

=head1 WARNING!!!

C:T:C:C:Config is a *very* early module and a *highly* EXPERIMENTAL one for
that matter. The API B<WILL CHANGE>. We're still moving stuff around, so
please only use it if you understand and accept the consequences.

If you have any questions, please contact the author.

=head1 SYNOPSIS

    my $config = CPAN::Testers::Common::Client::Config->new(
        prompt => \&IO::Prompt::Tiny::prompt,
    );

    if ( -e $config->get_config_filename ) {
        $config->read or return;
    }
    else {
        print "CPAN Testers config file not found. Creating...";
        $config->setup;
    }

    ## perform your test logging according to $config's data

    ## send the report!
    my $reporter = Test::Reporter->new(
        from           => $config->email_from,
        transport      => $config->transport_name,
        transport_args => $config->transport_args,
        ...
    );

=head1 METHODS

=head2 new

Instantiates a new CPAN::Testers::Common::Client::Config object. It may
receive the following (optional) parameters:

=over 4

=item * warn => \&my_warn_function

Inject your own warning function. Defaults to CORE::warn.

=item * print => \&my_print_function

Inject your own printing function. Defaults to C<< sub { print @_ } >>.

=item * prompt => \&my_prompt_function

Inject your own prompt function. Does B<not> have a default. The function
is expected to receive two values: C<< ( $question, $default_value ) >>, and
return a scalar containing the answer. Take a look at L<IO::Prompt::Tiny>
and L<ExtUtils::MakeMaker>'s C<prompt()> functions for suitable candidates.

If you plan on calling L</setup>, make sure you pass the 'prompt' argument to
C<new()>.

=back

=head2 read

Reads and parses the existing CPAN Tester's configuration file
(usually C<$HOME/.cpanreporter/config.ini> into the main object.

=head2 setup

Prompts the user and sets up the CPAN Tester's configuration file (usually
C<$HOME/.cpanreporter/config.ini>). This method B<requires> you to have set
a proper C<prompt> function when you instantiated the object.


=head2 get_config_dir()

The base directory in which your 'C<config.ini>' and other files reside.
Defaults to the '.cpanreporter' directory  under your home directory
(if you're using Linux or OS X) or under the 'my documents' folder
(if you're running Windows).

=head2 get_config_filename()

Returns the full path for the 'C<config.ini>' file.

=head2 CONFIGURATION AND ENVIRONMENT

=over 4

=item * PERL_CPAN_REPORTER_DIR

Overrides the value for C<get_config_dir()>.

=item * PERL_CPAN_REPORTER_CONFIG

Overrides the value for C<get_config_filename()>.

=back

=head2 Other methos & accessors

This class also provides some semi-public methods and accessors that most
likely will move around even more than the others, but that are listed here
for completeness sake. You should really not use nor rely on those:

=over 4

=item * edit_report - accessor for the 'edit_report' setting.

=item * email_from - accessor for the 'email_from' setting.

=item * myprint - accessor for the print function.

=item * myprompt - accessor for the prompt function.

=item * mywarn - accessor for the warn function.

=item * send_duplicates - accessor for the 'send_duplicates' setting.

=item * send_report - accessor for the 'send_report' setting.

=item * transport - accessor for the 'transport' setting.

=item * transport_name - returns the transport name.

=item * transport_args - returns the transport arguments.

=back

