package Audio::Ecasound;

require 5.005_62;
use Carp;
use strict;
use vars qw(@ISA @EXPORT %EXPORT_TAGS @EXPORT_OK $VERSION $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

# base names for methods (correspond to the C eci_X and eci_X_r versions)
my @cmds = qw(
        command
        command_float_arg

        last_float
        last_integer
        last_long_integer
        last_string
        last_string_list_count
        last_string_list_item
        last_type
        
        error
        last_error
    );

%EXPORT_TAGS = ( 
    simple => [qw( eci on_error errmsg )],
    std => [ @cmds ],
    raw => [ map { "eci_$_" } @cmds ],
    raw_r => [ qw(eci_init_r eci_cleanup_r), map { "eci_$_"."_r" } @cmds ],
    # NOTE the :iam tag is added dynamically in &import
);

# NOTE :iam adds to this in &import
@EXPORT_OK = ( map { @{$_} } @EXPORT_TAGS{'simple', 'std','raw','raw_r'} );

my %iam_cmds;
sub get_iam_cmds { return keys %iam_cmds; }

sub import {
    # When :iam is imported, the internal commands (len >=2)
    # are found with eci 'int-cmd-list' and declared
    # hyphens are converted to underscores to produce legal names
    if(grep { /^:iam$/ } @_) {
        my @iam_cmds = map { s/-/_/g; (/^\w{2,}$/)? $_ : () } eci('int-cmd-list');
        $EXPORT_TAGS{iam} = [ @iam_cmds ];
        push @EXPORT_OK, @iam_cmds;
        $iam_cmds{$_} = 1 for (@iam_cmds);
    }
    Audio::Ecasound->export_to_level(1,@_);
}

# AUTOLOAD to proxy iam commands as functions
# defines iam commands as they are used
sub AUTOLOAD {
    my $cmd = $AUTOLOAD;
    $cmd =~ s/.*:://;

    unless($iam_cmds{$cmd}) {
        # can't you pass? Just pretend by doing what perl would do
        croak "Undefined subroutine $AUTOLOAD called";
    }

    no strict 'refs';
    *$cmd = sub {
        $cmd =~ s/_/-/g; # eg cop_list => cop-list;
        eci(join ' ', $cmd, @_);
    };
    goto &$cmd;
}

$VERSION = '1.01';
bootstrap Audio::Ecasound $VERSION;

# Generate wrappers(OO or not-OO) for raw C functions
for my $cmd (@cmds) {
    # eg. the 'command' sub is a perl wrapper which
    # calls 'eci_command' or 'eci_command_r' depending
    # on whether it's called as a method
    no strict 'refs';
    *$cmd = sub {
        my $self = &_shift_self;
        if(ref $self) {
            # treat string as function name (symref), pass handle
            "eci_${cmd}_r"->($self->{eci_handle}, @_);
        } else {
            "eci_$cmd"->(@_);
        }
    };
}

# Overriding DynaLoader's method so that .so symbols are
# globally visible, hence ecasound-plugins (like libaudioio_af.so)
# can link to them
sub dl_load_flags { 0x01 }

my %opts = (
        on_error => 'warn', # 'die', '', 'cluck', 'confess'
        errmsg => '',
    );

# generate accessors
for my $option (keys %opts) {
    no strict 'refs';
    *$option = sub {

        my $self = &_shift_self;
        my $opts = \%opts;

        if(ref $self) {
            # use object's hash
            $opts = $self;
        }
        $opts->{$option} = shift if @_;
        return $opts->{$option};
    };
}

sub new {
    my $arg = shift;
    my $class = ref($arg) || $arg;
    my $self = { %opts }; # object gets current package values
    $self->{eci_handle} = eci_init_r();
    bless $self, $class;
}

sub do_error {
    my $self = &_shift_self;
    my $errstr = shift;

    $self->errmsg($errstr);
    
    my $on_error = $self->on_error;
    no strict 'refs';
    if($on_error eq 'die') {
        die "Audio::Ecasound::error: $errstr\n";
    } elsif($on_error eq 'warn') {
        warn "Audio::Ecasound::error: $errstr\n";
    } elsif(exists &{"Carp::$on_error"}) {
        &{"Carp::$on_error"}("Audio::Ecasound::error: $errstr\n");
    } elsif($on_error) {
        die "Audio::Ecasound::error: $errstr\n"
            ."(And on_error=$on_error is bad)\n";
    }
    return;
}

# do everything in one function
sub eci {

    my $self = &_shift_self;
    
    my $cmdstr = shift;
    if(@_) {
        my $float = shift;
        $self->command_float_arg($cmdstr, $float);
        $cmdstr .= ' ' . $float;
        # Handle an eci error
        if($self->error()) {
            my $errstr = $self->last_error() . "(in $cmdstr)";
            return $self->do_error($errstr);
        }
    } else {
        # multiline commands
        for my $mcmdstr (split /\n/, $cmdstr) {
            
            # Comments
            $mcmdstr =~ s/#.*//;
            $mcmdstr =~ s/^\s+//;
            $mcmdstr =~ s/\s+$//;
            # Skip blanks
            next if $mcmdstr =~ /^$/;

            $self->command($mcmdstr);

            # Handle an eci error ( would be 'e' return code )
            if($self->error()) {
                my $errstr = $self->last_error() . "(in $mcmdstr)";
                return $self->do_error($errstr);
            }
        }
    }

    # do return value
    return unless defined wantarray;
    my $ret;
    my $type = $self->last_type();
    if($type eq 'i') {
        return $self->last_integer();
    } elsif($type eq 'f') {
        return $self->last_float();
    } elsif($type eq 's') {
        return $self->last_string();
    } elsif($type eq 'li') {
        return $self->last_long_integer();
    } elsif($type eq '' || $type eq '-') { # - from python
        return ''; # false but defined
    } elsif($type eq 'S') {
        my $count = $self->last_string_list_count();
        # differentiate from () err when ambiguous
        return ('') unless ($count && $self->on_error); 
        my @ret;
        for my $n (0..$count-1) {
            push @ret, $self->last_string_list_item($n);
        }
        return @ret;
    } elsif($type eq 'e') { # should be handled above...
        my $errstr = $self->last_error() . "(in $cmdstr)";
        return $self->do_error($errstr);
    } else {
        die "last_type() returned unexpected type <$type>";
    }
}


# Look at first argument and return something that
# can be used as an object, either a blessed ref
# a class name which isa A::E or the string
# 'Audio::Ecasound' (can be used 'Audio::Ecasound'->eci($c))
# NOTE: should be called &_shift_self to shift @_ for parent;
sub _shift_self {
    if(!defined $_[0]) {
        return __PACKAGE__;
    } elsif(ref $_[0]) {
        return shift;
    } elsif ( $_[0] =~ /^[_a-zA-Z][\w:']*$/ # Common package names
            && UNIVERSAL::isa($_[0],__PACKAGE__) ) {
            #&& $_[0]->isa(__PACKAGE__) ) {
        return shift;
    } else {
        return __PACKAGE__;
    }
}

DESTROY {
    my $self = shift;
    eci_cleanup_r($self->{eci_handle});
}

END {
    # Partner eci_init in XS BOOT:
    eci_cleanup();
}


1;
__END__

=head1 NAME

Audio::Ecasound - Perl binding to the ecasound sampler, recorder, fx-processor

=head1 SYNOPSIS

One function interface:

    use Audio::Ecasound qw(:simple);

    eci("cs-add play_chainsetup");
    eci("c-add 1st_chain");
    eci("-i:some_file.wav");
    eci("-o:/dev/dsp");
    # multiple \n separated commands
    eci("cop-add -efl:100
         # with comments
         cop-select 1
         copp-select 1
         cs-connect");
    eci("start");
    my $cutoff_inc = 500.0;
    while (1) {
        sleep(1);
        last if eci("engine-status") ne "running";

        my $curpos = eci("get-position");
        last if $curpos > 15;

        my $next_cutoff = $cutoff_inc + eci("copp-get");
        # Optional float argument
        eci("copp-set", $next_cutoff);
    }
    eci("stop");
    eci("cs-disconnect");
    print "Chain operator status: ", eci("cop-status");

Object Interface

  use Audio::Ecasound;

  my $e = new Audio::Ecasound;
  $e->on_error('');
  $e->eci("cs-add play_chainsetup");
  # etc.

Vanilla Ecasound Control Interface (See Ecasound's Programmer Guide):

  use Audio::Ecasound qw(:std);

  command("copp-get");
  $precise_float = last_float() / 2;
  command_float_arg("copp-set", $precise_float);
  warn last_error() if error();

IAM Interface, pretend interactive mode commands are functions.

  use Audio::Ecasound qw(:iam :simple);

  # iam commands as functions with s/-/_/g
  my $val = copp_get;
  copp_set $val+0.1; # floats are stringified so beware
  eci("-i /dev/dsp"); # not all commands are exported

=head1 DESCRIPTION

Audio::Ecasound provides perl bindings to the ecasound control interface of the
ecasound program.  You can use perl to automate or interact with
ecasound so you don't have to turn you back on the adoring masses
packed into Wembly Stadium.

Ecasound is a software package designed for multitrack audio processing.
It can be used for audio playback, recording, format conversions,
effects processing, mixing, as a LADSPA plugin host and JACK node.  
Version E<gt>= 2.2.X must be installed to use this package.
L<SEE ALSO> for more info.

=head1 INSTALLATION

 perl Makefile.PL

If your perl wasn't built with -Dusethreads or -D_REENTRANT you
will be prompted whether to continue with the install.  It's in
your hands... See L<THREADING NOTE>

 make
 make test
 make install

=head1 THREADING NOTE

The ecasoundc library uses pthreads so will may only work if
your perl was compiled with threading enabled, check with:

 % perl -V:usethreads

You are welcome to try using the module with non-threaded perls
(perhaps -D_REENTRANT alone would work) it have worked for some.

=head1 EXPORT

=over 4

=item *

Nothing by default as when going OO.

=item *

:simple gives eci() which does most everything, also errmsg and on_error.
Or you could just import 'eci' and call the others C<Audio::Ecasound::errmsg()>

=item *

:iam imports many iam commands so that you can use them as perl functions.
Basically everything listed by ecasound's 'int-cmd-list' except the single
letter commands and hyphens are replaced by underscores.  
The list is produced at run-time and returned by Audio::Ecasound::get_iam_cmds().
See L<IAM COMMANDS>;

=item *

:std to import the full ecasound control interface detailed in the 
Ecasound Programmer's Guide.

=item *

:raw and raw_r, C functions with minimal wrapping, _r ones are reentrant
and must be passed the object returned by eci_init_r().  I don't know why
you would use these, presumably you do.  These options may be removed in
future.

=back

=head1 METHODS AND FUNCTIONS

The procedural and OO interfaces use the same functions, the differences
are that when called on an Audio::Ecasound object the reentrant C versions
are used so you can have multiple independent engine (with independent
options).

=over 2

=item B<new()>

Constructor for Audio::Ecasound objects, inherits the on_error and
other options from the current package settings (defaults if untouched).

=item B<eci('ecasound command string', [$float_argument])>

Sends commands to the Ecasound engine. A single command may be called with an
optional float argument (to avoid precision loss). Alternatively,
multiple commands may be given separated by newlines (with C<#> starting
a comment).

If called in non-void context the result of the last command is
returned, it may be an integer, float, string (ie. scalar) or a list of
strings. Which will depend on the ecasound command, see L<ecasound-iam>
for each function's return value.

If there is an error the action given to on_error will be taken.
See on_error below for return value caveats when on_error = ''.
Error processing is performed for each command in a multiline command.

=item B<on_error('die')>

Set the action to be taken when an error occurs from and C<eci>
command, may be 'die', 'warn', '', 'confess', ... (default is 'warn'). 

When '' is selected C<return;> is used for an error, that is undef or
().  To disamibiguate eci will return '' or ('') for no return value
and no string list respectively.

=item B<errmsg()>

The last error message from an C<eci> command.  It is not reset
so clear it yourself if required C<errmsg('')>.  This shouldn't
be necessary as you can use C<defined> or on_error to find out
when errors occur.

=back

The remainder of the functions/methods are the standard Ecasound
Control Interface methods but they come in three flavours.
The bare function name may be called with or without an object:

  use Audio::Ecasound ':simple':
  command($cmd);
  # or
  my $e = new Audio::Ecasound;
  $e = command($cmd);

The other two flavours are low-level, reentrant and non-reentrant.
These are thinly wrapped C functions better documented in the ECI
document with the ecasound distribution.  Just add 'eci_' to the
names below for the non-reentrant version and then add a '_r'
to the end for the reentrant version.  The reentrant version takes
an extra first argument, the object returned by eci_init_r() which
must be destroyed with eci_cleanup_r().

=over 4

=item B<command($cmd_string)>

=item B<eci_command_float_arg($cmd_string, $float_arg)>

=item B<$bool = eci_error()>

=item B<$err_str = eci_last_error()>

=item B<$float = eci_last_float()>

=item B<$int = eci_last_integer()>

=item B<$lint = eci_last_long_integer()>

=item B<$str = eci_last_string()>

=item B<$n = eci_last_string_list_count()>

=item B<$str_n = eci_last_string_list_item($n)>

=item B<$type_str = eci_last_type()> 's' 'S' 'i' 'li' 'f' ''

=back

=head1 IAM COMMANDS

When the :iam tag is imported most of the commands in ecasounds
interactive mode become perl functions.  The '-'s become '_'s
to become valid perl names ('cop-get' is cop_get, etc.)
The list is printed with:

  use Audio::Ecasound qw(:iam :simple);
  print join ' ', Audio::Ecasound::get_iam_cmds();

The arguments joined together as a string and then sent to ecasound.
This means that float precision is lost, unlike with the two
argument C<eci> so use it.  Also use C<eci> for command-line style
commands like C<eci "-i /dev/dsp">.  But most other things you
can just use the iam command itself (s/-/_/g):

  use Audio::Ecasound qw(:iam :simple);
  ... # setup stuff
  print status;
  start;
  $v = copp_get;
  copp_set $v + 1.2;

I would never encourage anyone to use C<no strict 'subs';> but with :iam you
may enjoy a little less discipline.

See the iam_int.pl example file in the eg directory.

=head1 EXAMPLES

See the C<eg/> subdirectory.

=head1 TROUBLESHOOTING

The ecasound command 'debug' could be useful, add C<eci "debug 63">
to the top of your program.  The argument is various bits OR'd
and controls the amount and type of debugging information, see the
ecasound documentation of source or just try your favorite powers
of two.

There was a bug effecting Audio::Ecasound with ecasound version
2.4.4, causing problems with :iam mode, and test failure
("Do you need to predeclare cs_set_length").  See
L<http://www.eca.cx/ecasound-list/2006/12/0007.html> and
L<http://www.eca.cx/ecasound-list/2006/06/0004.html>.

=head1 FILES AND ENVIRONMENT

The libecasoundc library now uses the environment variable
"ECASOUND" to find the ecasound executable.  If it is not set then
the libarary will print a warning.  To suppress it, simply set
the ECASOUND variable: eg. export ECASOUND=ecaosund

The ecasound library will still process ~/.ecasoundrc and other
setup files for default values.  See the library documentation.

=head1 AUTHOR

(c) 2001-2007 Brad Bowman E<lt>eci-perl@bereft.netE<gt>
This software may be distributed under the same terms as Perl itself.

=head1 SEE ALSO

The Ecasound Programmer's Guide and ECI doc,
L<ecasound>, L<ecasound-iam> http://eca.cx/, http://www.ladspa.org/

The internals of libecasoundc have been rebuilt and now interact with
a running ecasound via a socket using a protocol defined in the
Programmer's Guide.  The C library is now just a compatibility layer
and the Python version now talks directly to the socket.
It would be straight forward to write an equivalent Perl version
should the need arise.

=cut
