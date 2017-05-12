# ABSTRACT: Simple way to create applications


package App::Basis ;
$App::Basis::VERSION = '1.2';
use 5.014 ;
use warnings ;
use strict ;
use Getopt::Long ;
use Exporter ;
use File::HomeDir ;
use Path::Tiny ;
use IPC::Cmd qw(run run_forked) ;
use List::Util qw(max) ;
use POSIX qw(strftime) ;
use utf8::all ;
use Digest::MD5 qw(md5_base64) ;
use YAML::Tiny::Color ;

use vars qw( @EXPORT @ISA) ;

@ISA = qw(Exporter) ;

# this is the list of things that will get imported into the loading packages
# namespace
@EXPORT = qw(
    init_app
    show_usage
    msg_exit
    get_program
    debug set_debug
    daemonise
    execute_cmd run_cmd
    set_log_file
    fix_filename
    set_test_mode
    saymd
    set_verbose
    verbose
    verbose_data
    ) ;

# ----------------------------------------------------------------------------

my $PROGRAM  = path($0)->basename ;
my $LOG_FILE = fix_filename("~/$PROGRAM.log") ;

# these variables are held available throughout the life of the app
my $_app_simple_ctrlc_count = 0 ;
my $_app_simple_ctrlc_handler ;
my $_app_simple_help_text    = 'Application has not defined help_text yet.' ;
my $_app_simple_help_options = '' ;
my $_app_simple_cleanup_func ;
my $_app_simple_help_cmdline = '' ;

my %_app_simple_objects = () ;
my %_cmd_line_options   = () ;

# we may want to die rather than exiting, helps with testing!
my $_test_mode = 0 ;


# ----------------------------------------------------------------------------
# control how we output things to help with testing
sub _output
{
    my ( $where, $msg ) = @_ ;

    if ( !$_test_mode ) {
        if ( $where =~ /stderr/i ) {
            say STDERR $msg ;
        } else {
            say $msg ;
        }
    }
}

# ----------------------------------------------------------------------------


sub set_log_file
{
    my ($file) = @_ ;
    $LOG_FILE = $file ;
}

# ----------------------------------------------------------------------------


sub debug
{
    my ( $level, @debug ) = @_ ;

    # we may want to undef the debug object, so no debug comes out

    if ( exists $_app_simple_objects{logger} ) {

        # run the coderef for the logger
        $_app_simple_objects{logger}->( $level, @debug )
            if ( defined $_app_simple_objects{logger} ) ;
    } else {
        path($LOG_FILE)
            ->append_utf8( strftime( '%Y-%m-%d %H:%M:%S', gmtime( time() ) )
                . " [$level] "
                . join( ' ', @debug )
                . "\n" ) ;
    }
}

# ----------------------------------------------------------------------------


sub set_debug
{
    my $func = shift ;
    if ( !$func || ref($func) ne "CODE" ) {
        warn "set_debug function expects a CODE, got a " . ref($func) ;
    } else {
        $_app_simple_objects{logger} = $func ;
    }
}

# -----------------------------------------------------------------------------
my $verbose = 1 ;


sub set_verbose
{
    $verbose = shift ;
}


sub verbose
{
    my ($msg) = @_ ;
    say STDERR $msg if ($verbose) ;
}


sub verbose_data
{
    if ( @_ % 2 ) {
        say STDERR Dump(@_) if ($verbose) ;

    } else {
        my ($data) = @_ ;
        say STDERR Dump($data) if ($verbose) ;
    }
}

# ----------------------------------------------------------------------------
# check that the option structure does not have repeated things in it
# returns string of any issue

sub _validate_options
{
    my ($options) = @_ ;
    my %seen ;
    my $result = "" ;

    foreach my $opt ( keys %{$options} ) {
        # options are long|short=, or thing=, or flags long|sort, or long
        my ( $long, $short ) ;
        if ( $opt =~ /^(.*?)\|(.*?)=/ ) {
            $long  = $1 ;
            $short = $2 ;
            if ( $seen{$long} ) {
                $result
                    = "Long option '$long' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            } elsif ( $seen{$short} ) {
                $result
                    = "Short option '$short' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }
            $seen{$short} = 1 ;
            $seen{$long}  = 1 ;
        } elsif ( $opt =~ /^(.*?)\|(.*?)$/ ) {
            $long  = $1 ;
            $short = $2 ;
            if ( $seen{$long} ) {
                $result
                    = "Long flag '$long' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }

            if ( $seen{$short} ) {
                $result
                    = "short flag '$short' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }
            $seen{$short} = 1 ;
            $seen{$long}  = 1 ;
        } elsif ( $opt =~ /^(.*?)=/ ) {
            $long = $1 ;
            if ( $seen{$long} ) {
                $result
                    = "Option '$long' has already been used. option line '$opt' is at fault"
                    ;

                last ;
            }
            $seen{$long} = 1 ;
        } elsif ( $opt =~ /^(.*?)$/ ) {
            $long = $1 ;
            if ( $seen{$long} ) {
                $result
                    = "flag '$long' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }
            $seen{$long} = 1 ;
        } elsif ( $opt =~ /^(.*?)\|(.*?)\|(.*?)\$/ ) {
            $long  = $1 ;
            $short = $2 ;
            my $extra = $3 ;
            if ( $seen{$long} ) {
                $result
                    = "flag '$long' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }
            if ( $seen{$short} ) {
                $result
                    = "flag '$short' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }
            if ( $seen{$extra} ) {
                $result
                    = "flag '$extra' has already been used. option line '$opt' is at fault"
                    ;
                last ;
            }
            $seen{$long}  = 1 ;
            $seen{$short} = 1 ;
            $seen{$extra} = 1 ;
        }
    }
    return $result ;
}

# ----------------------------------------------------------------------------


sub init_app
{
    my %args
        = @_ % 2
        ? die("Odd number of values passed where even is expected.")
        : @_ ;
    my @options ;
    my $has_required = 0 ;
    my %full_options ;

    if ( $args{log_file} ) {
        $LOG_FILE = fix_filename( $args{log_file} ) ;
    }

    if ( $args{debug} ) {
        set_debug( $args{debug} ) ;
    }

    # get program description
    $_app_simple_help_text = $args{help_text} if ( $args{help_text} ) ;
    $_app_simple_help_cmdline = $args{help_cmdline}
        if ( $args{help_cmdline} ) ;

    die "options must be a hashref" if ( ref( $args{options} ) ne 'HASH' ) ;

    $args{options}->{'help|h|?'} = 'Show help' ;

    my @keys         = sort keys %{ $args{options} } ;
    my %dnames       = _desc_names(@keys) ;
    my $max_desc_len = max( map length, values %dnames ) + 1 ;
    my $help_fmt     = "    %-${max_desc_len}s    %s\n" ;

    # add help text for 'help' first.
    $_app_simple_help_options .= sprintf $help_fmt, $dnames{'help|h|?'},
        'Show help' ;

    #
    my $msg = _validate_options( $args{options} ) ;
    if ($msg) {
        die "$msg" ;
    }

    # get options and their descriptions
    foreach my $o (@keys) {

        # save the option
        push @options, $o ;

        my $name = $o ;

        # we want the long version of the name if its provided
        $name =~ s/.*?(\w+).*/$1/ ;

        # remove any type data
        $name =~ s/=(.*)// ;

        if ( ref( $args{options}->{$o} ) eq 'HASH' ) {
            die "parameterised option '$name' require a desc option"
                if ( !$args{options}->{$o}->{desc} ) ;
            $full_options{$name} = $args{options}->{$o} ;
            $has_required++ if ( $full_options{$name}->{required} ) ;
        } else {
            $full_options{$name} = {
                desc => $args{options}->{$o},

                # possible options that can be passed
                # depends => '',
                # default => '',
                # required => 0,
                # validate => sub {}
            } ;
        }

        # save the option string too
        $full_options{$name}->{options} = $o ;

        # build the entry for the help text
        my $desc = $full_options{$name}->{desc} ;
        if ( $name ne 'help' ) {
            my $desc = $full_options{$name}->{desc} ;

            # show the right way to use the options
            my $dname = $dnames{$o} ;
            $dname .= '*' if ( $full_options{$name}->{required} ) ;

            $desc .= " [DEFAULT: $full_options{$name}->{default}]"
                if ( $full_options{$name}->{default} ) ;
            $_app_simple_help_options .= sprintf $help_fmt, $dname, $desc ;
        }
    }

    # show required options
    if ($has_required) {
        $_app_simple_help_options
            .= "* required option" . ( $has_required > 1 ? 's' : '' ) . "\n" ;
    }

    # catch control-c, user provided or our default
    $_app_simple_ctrlc_handler
        = $args{ctrl_c} ? $args{ctrl_c} : \&_app_simple_ctrlc_func ;
    $SIG{'INT'} = $_app_simple_ctrlc_handler ;

    # get an cleanup function handler
    $_app_simple_cleanup_func = $args{cleanup} if ( $args{cleanup} ) ;

    # check command line args
    GetOptions( \%_cmd_line_options, @options ) ;

    # help is a built in
    show_usage() if ( $_cmd_line_options{help} ) ;

    # now if we have the extended version we can do some checking
    foreach my $name ( sort keys %full_options ) {
        warn "Missing desc field for $name"
            if ( !$full_options{$name}->{desc} ) ;
        if ( $full_options{$name}->{required} ) {
            show_usage( "Required option '$name' is missing", 1 )
                if (
                !(     $_cmd_line_options{$name}
                    || $full_options{$name}->{default}
                )
                ) ;
        }
        if ( $full_options{$name}->{depends} ) {
            if ( !$_cmd_line_options{ $full_options{$name}->{depends} } ) {
                show_usage(
                    "Option '$name' depends on option '$full_options{$name}->{depends}' but it is missing",
                    1
                ) ;
            }
        }

        # set a default if there is no value
        if ( $full_options{$name}->{default} ) {
            $_cmd_line_options{$name} = $full_options{$name}->{default}
                if ( !$_cmd_line_options{$name} ) ;
        }

        # call the validation routine if we have one
        if ( $_cmd_line_options{$name} && $full_options{$name}->{validate} ) {
            die "need to pass a coderef to validate for option '$name'"
                if ( !ref( $full_options{$name}->{validate} ) eq 'CODE' ) ;
            die
                "Option '$name' has validate and should either also have a default or be required"
                if (
                !(     $full_options{$name}->{required}
                    || $full_options{$name}->{default}
                )
                ) ;
            my $coderef = $full_options{$name}->{validate} ;
            my $result  = $coderef->( $_cmd_line_options{$name} ) ;
            show_usage("Option '$name' does not pass validation")
                if ( !$result ) ;
        }
    }

    # auto set verbose if it has been used
    set_verbose( $_cmd_line_options{verbose} ) ;

    return %_cmd_line_options ;
}

# ----------------------------------------------------------------------------


sub get_program
{
    return $PROGRAM ;
}

# ----------------------------------------------------------------------------


sub get_options
{
    return %_cmd_line_options ;
}

# ----------------------------------------------------------------------------
# handle the ctrl-c presses

sub _app_simple_ctrlc_func
{

    # exit if we are already in ctrlC
    exit(2) if ( $_app_simple_ctrlc_count++ ) ;
    _output( 'STDERR', "\nCaught Ctrl-C. press again to exit immediately" ) ;

    # re-init the handler
    $SIG{'INT'} = $_app_simple_ctrlc_handler ;
}

# ----------------------------------------------------------------------------

# to help with testing we may want to die, which can be caught rather than
# exiting, so lets find out

sub _exit_or_die
{
    my $state = shift || 1 ;

    if ($_test_mode) {
        STDERR->flush() ;
        STDOUT->flush() ;
        die "exit state $state" ;
    }
    exit($state) ;
}

# ----------------------------------------------------------------------------


sub show_usage
{
    my ( $msg, $state ) = @_ ;

    my $help = qq{
Syntax: $PROGRAM [options] $_app_simple_help_cmdline

About:  $_app_simple_help_text

[options]
$_app_simple_help_options} ;
    if ($msg) {

        # if we have an error message it MUST go to STDERR
        # to make sure that any program the output is piped to
        # does not get the message to process
        _output( 'STDERR', "$help\nError: $msg\n" ) ;
    } else {
        _output( 'STDOUT', $help ) ;
    }

    _exit_or_die($state) ;
}

# ----------------------------------------------------------------------------


sub msg_exit
{
    my ( $msg, $state ) = @_ ;

    _output( 'STDERR', $msg ) if ($msg) ;
    _exit_or_die($state) ;
}

# -----------------------------------------------------------------------------


sub daemonise
{
    my $rootdir = shift ;

    if ($rootdir) {
        chroot($rootdir)
            or die
            "Could not chroot to $rootdir, only the root user can do this." ;
    }

    # fork once and let the parent exit
    my $pid = fork() ;

    # exit if $pid ;
    # parent to return 0, as it is logical
    if ($pid) {
        return 0 ;
    }
    die "Couldn't fork: $!" unless defined $pid ;

    # disassociate from controlling terminal, leave the
    # process group behind

    POSIX::setsid() or die "Can't start a new session" ;

    # show that we have started a daemon process
    return 1 ;
}

# ----------------------------------------------------------------------------


sub execute_cmd
{
    my %args = @_ ;

    my $command = $args{command} or die "command required" ;
    # pass everything thought encode incase there is utf8 there
    utf8::encode($command) ;

    my $r = IPC::Cmd::run_forked( $command, \%args ) ;

    return $r ;
}

# ----------------------------------------------------------------------------


sub run_cmd
{
    my ( $cmd, $timeout ) = @_ ;

    # use our local version of path so that it can pass taint checks
    local $ENV{PATH} = $ENV{PATH} ;

    # pass everything thought encode incase there is utf8 there
    utf8::encode($cmd) ;

    my %data = ( command => $cmd ) ;
    $data{timeout} = $timeout if ($timeout) ;
    my ( $ret, $err, $full_buff, $stdout_buff, $stderr_buff ) = run(%data) ;

    my $stdout = join( "\n", @{$stdout_buff} ) ;
    my $stderr = join( "\n", @{$stderr_buff} ) ;

    return ( !$ret, $stdout, $stderr ) ;
}

# -----------------------------------------------------------------------------


sub fix_filename
{
    my $file = shift ;
    return if ( !$file ) ;

    my $home = File::HomeDir->my_home ;
    $file =~ s/^~/$home/ ;
    if ( $file =~ m|^\.\./| ) {
        my $parent = path( Path::Tiny->cwd )->dirname ;
        $file =~ s|^(\.{2})/|$parent/| ;
    }
    if ( $file =~ m|^\./| || $file eq '.' ) {
        my $cwd = Path::Tiny->cwd ;
        $file =~ s|^(\.)/?|$cwd| ;
    }

    # replace multiple separators
    $file =~ s|//|/|g ;

    # get the OS specific path
    return path($file)->canonpath ;
}

# ----------------------------------------------------------------------------
# Returns a hash containing a formatted name for each option. For example:
# ( 'help|h|?' ) -> { 'help|h|?' => '-h, -?, --help' }
sub _desc_names
{
    my %descs ;
    foreach my $o (@_) {
        $_ = $o ;    # Keep a copy of key in $o.
        s/=.*$// ;

        # Sort by length so single letter options are shown first.
        my @parts = sort { length $a <=> length $b } split /\|/ ;

        # Single chars get - prefix, names get -- prefix.
        my $s = join ", ", map { ( length > 1 ? '--' : '-' ) . $_ } @parts ;

        $descs{$o} = $s ;
    }
    return %descs ;
}

# ----------------------------------------------------------------------------
# special function to help us test this module, as it flags that we can die
# rather than exiting when doing some operations
# also test mode will not output to STDERR/STDOUT

sub set_test_mode
{
    $_test_mode = shift ;
}

# ----------------------------------------------------------------------------




# saymd function taken and modied from
# echomd -- An md like conversion tool for shell terminals
# https://raw.githubusercontent.com/WebReflection/echomd/master/perl/echomd
# some mod's of my own

#
# Fully inspired by the work of John Gruber
# <http://daringfireball.net/projects/markdown/>
#
# -----------------------------------------------------------------------------
# The MIT License (MIT)
# Copyright (c) 2016 Andrea Giammarchi - @WebReflection
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
# THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# -----------------------------------------------------------------------------

# for *bold* _underline_ ~strike~ (strike on Linux only)
# it works with both double **__~~ or just single *_~
sub _bold_underline_strike
{
    my ($txt) = @_ ;
    $txt =~ s/(\*{1,2})(?=\S)(.+?)(?<=\S)\1/\x1B[1m$2\x1B[22m/gs ;
    $txt =~ s/(\_{1,2})(?=\S)(.+?)(?<=\S)\1/\x1B[4m$2\x1B[24m/gs ;
    $txt =~ s/(\~{1,2})(?=\S)(.+?)(?<=\S)\1/\x1B[9m$2\x1B[29m/gs ;
    return $txt ;
}

# for #color(text) or bg#bgcolor(text)
# virtually compatible with #RGBA(text)
# or for background via bg#RGBA(text)
sub _color
{
    my ($txt) = @_ ;
    $txt =~ s{(bg)?#([a-zA-Z0-9]{3,8})\((.+?)\)(?!\))}
           {_get_color($1,$2,$3)}egs ;
    return $txt ;
}

# for very important # Headers
# and for less important ## One
sub _header
{
    my ($txt) = @_ ;
    $txt =~ s{^(\#{1,6})[ \t]+(.+?)[ \t]*\#*([\r\n]+|$)}
           {_get_header($1,$2).$3}egm ;
    return $txt ;
}

# for horizontal lines
# --- or - - - or ___ or * * *
sub _horizontal
{
    my ($txt) = @_ ;
    my $line = "─" x 72 ;
    $txt =~ s{^[ ]{0,2}([ ]?[\*_-][ ]?){3,}[ \t]*$}
           {\x1B[1m$line\x1B[22m}gm ;
    return $txt ;
}

# for lists such:
#   * list 1
#     etc, etc
#   * list 2
#   * list 3
sub _list
{
    my ($txt) = @_ ;
    $txt =~ s/^([ \t]{2,})[*+-]([ \t]{1,})/$1•$2/gm ;
    return $txt ;
}

# for quoted text such:
# > this is quote
# > this is the rest of the quote
sub _quote
{
    my ($txt) = @_ ;
    $txt =~ s/^[ \t]*>([ \t]?)/\x1B[7m$1\x1B[27m$1/gm ;
    return $txt ;
}

# HELPERS

# used to grab colors by name
sub _get_color
{
    my $bg  = $1 ;
    my $rgb = $2 ;
    my $out = "" ;
    # one day, when it won't show experimental warnings
    # given($rgb){
    #   when("black")   { $out = "\x1B[30m" }
    #   when("red")     { $out = "\x1B[31m" }
    #   when("green")   { $out = "\x1B[32m" }
    #   when("blue")    { $out = "\x1B[34m" }
    #   when("magenta") { $out = "\x1B[35m" }
    #   when("cyan")    { $out = "\x1B[36m" }
    #   when("white")   { $out = "\x1B[37m" }
    #   when("yellow")  { $out = "\x1B[39m" }
    #   when("grey")    { $out = "\x1B[90m" }
    # }
    if ( $rgb eq "black" ) {
        $out = "\x1B[30m" ;
    } elsif ( $rgb eq "red" ) {
        $out = "\x1B[31m" ;
    } elsif ( $rgb eq "green" ) {
        $out = "\x1B[32m" ;
    } elsif ( $rgb eq "blue" ) {
        $out = "\x1B[34m" ;
    } elsif ( $rgb eq "magenta" ) {
        $out = "\x1B[35m" ;
    } elsif ( $rgb eq "cyan" ) {
        $out = "\x1B[36m" ;
    } elsif ( $rgb eq "white" ) {
        $out = "\x1B[37m" ;
    } elsif ( $rgb eq "yellow" ) {
        $out = "\x1B[39m" ;
    } elsif ( $rgb eq "grey" ) {
        $out = "\x1B[90m" ;
    }
    $out .= ( $out eq "" ) ? $3 : "$3\x1B[39m" ;
    return ( !defined $bg ) ? $out : "\x1B[7m$out\x1B[27m" ;
}

sub _get_header
{
    my ( $hash, $txt ) = @_ ;
    if ( length($hash) eq 1 ) {
        $txt = "\x1B[1m$txt\x1B[22m" ;
    }
    return "\x1B[7m $txt \x1B[27m" ;
}

# used to place parsed code back
sub _get_source
{
    my ($hash) = @_ ;
    my %code = %{ $_[1] } ;
    for my $source ( keys %code ) {
        if ( $code{$source} eq $hash ) {
            return $source ;
        }
    }
}

# main transformer
# takes care of code blocks too
# without modifying their content
# inline `code blocks` as well as
# ```
# multiline code blocks
# ```
sub saymd
{
    my ($txt) = @_ ;
    my %code ;
    # preserve code blocks
    $txt =~ s{(`{2,})(.+?)(?<!`)\1(?!`)}
           {$1.($code{$2}=md5_base64($2)).$1}egs ;
    # preserve inline blocks too
    $txt =~ s{(`)(.+?)\1}{$1.($code{$2}=md5_base64($2)).$1}egm ;
    # converter everything else
    $txt = _horizontal($txt) ;
    $txt = _header($txt) ;
    $txt = _bold_underline_strike($txt) ;
    $txt = _list($txt) ;
    $txt = _quote($txt) ;
    $txt = _color($txt) ;
    # put back inline blocks
    $txt =~ s{(`)(.+?)\1}{$1._get_source($2,\%code).$1}egm ;
    # put back code blocks too
    $txt =~ s{(`{3})(.+?)(?<!`)\1(?!`)}
           {$1._get_source($2,\%code).$1}egs ;
    say $txt;
}

# ----------------------------------------------------------------------------
# make sure we do any cleanup required

END {

    # call any user supplied cleanup
    if ($_app_simple_cleanup_func) {
        $_app_simple_cleanup_func->() ;
        $_app_simple_cleanup_func = undef ;
    }
}


# ----------------------------------------------------------------------------

1 ;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Basis - Simple way to create applications

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use 5.10.0 ;
    use strict ;
    use warnings ;
    use POSIX qw(strftime) ;
    use App::Basis

    sub ctrlc_func {
        # code to decide what to do when CTRL-C is pressed
    }

    sub cleanup_func {
        # optionally clean up things when the script ends
    }

    sub debug_func {
        my ($lvl, $debug) = @_;
        if(!$debug) {
            $debug = $lvl ;
            # set a default level
            $lvl = 'INFO' ;
        }

        say STDERR strftime( '%Y-%m-%d %H:%M:%S', gmtime( time() ) ) . " [$lvl] " . get_program() . " " . $debug;
    }

    # main
    my %opt = App::Basis::init_app(
    help_text   => 'Sample program description'
    , help_cmdline => 'extra stuff to print about command line use'
    , options   =>  {
        'file|f=s'  => {
            desc => 'local system location of xml data'
            , required => 1
        }
        , 'url|u=s' => {
            desc => 'where to find xml data on the internet'
            , validate => sub { my $url = shift ; return $url =~ m{^(http|file|ftp)://} ; }
        }
        , 'keep|k'  => {
            # no point in having this if there is no file option
            desc => 'keep the local file, do not rename it'
            , depends => 'file'
        }
        , 'counter|c=i' => {
            desc => 'check a counter'
            , default   => 5
        }
        , 'basic'   => 'basic argument, needs no hashref data'
    }
    , ctrl_c   => \&ctrl_c_handler  # override built in ctrl-c handler
    , cleanup  => \&cleanup_func    # optional func to call to clean up
    , debug    => \&debug_func      # optional func to call with debugging data
    , 'verbose|v' => 'be verbose about things',
    , log_file => "~/log/fred.log"  # alternative place to store default log messages
    ) ;

    show_usage("need keep option") if( !$opt{keep}) ;

    msg_exit( "spurious reason to exit with error code 3", 3) ;

=head1 DESCRIPTION

There are a number of ways to help script development and to encorage people to do the right thing.
One of thses is to make it easy to get parameters from the command line. Obviously you can play with Getopt::Long and
continuously write the same code and add in your own handlers for help etc, but then your co-workers and friends
make not be so consistent, leading to scripts that have no help and take lots of cryptic parameters.

So I created this module to help with command line arguments and displaying help, then I added L<App::Basis::Config> because
everyone needs config files and does not want to constantly repeat themselves there either.

So how is better than other similar modules? I can't say that it is, but it meets my needs.

There is app help available, there is basic debug functionality, which you can extend using your own function,
you can daemonise your script or run a shell command and get the output/stderr/return code.

If you choose to use App::Basis::Config then you will find easy methods to manage reading/saving YAML based config data.

There are (or will be) other App::Basis modules available to help you write scripts without you having to do complex things
or write lots of code.

There is a helper script to create the boilerplate for an appbasis script, see L<appbasis>

=head1 NAME

 App::Basis

=head1 Public Functions

=over 4

=item set_log_file

Set the name of the log file for the debug function

    set_log_file( "/tmp/lof_file_name") ;
    debug( "INFO", "adding to the debug log") ;

=item debug

Write some debug data. If a debug function was passed to init_app that will be
used, otherwise we will write to STDERR.

    debug( "WARN", "some message") ;
    debug( "ERROR", "Something went wrong") ;

B<Parameters>
  string used as a 'level' of the error
  array of anything else, normally error description strings

If your script uses App::Basis make sure your modules do too, then any debug
can go to your default debug handler, like log4perl, but simpler!

=item set_debug

Tell App:Simple to use a different function for the debug calls.
Generally you don't need this if you are using init_app, add the link there.

B<Parameters>
  coderef pointing to the function you want to do the debugging

=item set_verbose

Turn on use of verbose or verbose_data functions, verbose outputs to STDERR
its different to debug logging with generally will go to a file

    set_verbose( 1) ;
    verbose( "note that I performed some action") ;

=item verbose

Write to STDERR if verbose has been turned on
its different to debug logging with generally will go to a file

    set_verbose( 1) ;
    verbose( "note that I performed some action") ;

=item verbose

Dump a data structure to STDERR if verbose has been turned on
its different to debug logging with generally will go to a file

    set_verbose( 1) ;
    verbose_data( \%some_hash) ;

=item init_app

B<Parameters> hash of these things

    help_text    - what to say when people do app --help
    help_cmdline - extra things to put after the sample args on a sample command line (optional)
    cleanup      - coderef of function to call when your script ends (optional)
    debug        - coderef of function to call to save/output debug data (optional, recommended)
    'verbose'    - use verbose mode (optional) will trigger set_verbose by default
    log_file     - alternate name of file to store debug to
    ctrlc_func   - coderef of function to call when user presses ctrl-C
    options      - hashref of program arguments
      simple way
      'fred'     => 'some description of fred'
      'fred|f'   => 'fred again, also allows -f as a variant'
      'fred|f=s' => 'fred needs to be a string'
      'fred|f=i' => 'fred needs to be an integer'

      complex way, more features, validation, dependancies etc
      'fred|f=s' => {
         desc      => 'description of argument',
         # check if fred is one of the allowed things
         validate  => sub { my $fred = shift ; $fred =~ m/bill|mary|jane|sam/i ;},
         # does this option need another option to exist
         depends   => 'otheroption'
       }
      'fred|f=s' => {
         desc     => 'description of argument',
         default  => 'default value for fred'
      }

B<Note will die if not passed a HASH of arguments>

=item get_program

get the name of the running program
just a helper function

=item get_options

return the command line options hash
just a helper function

=item show_usage

show how this program is used, outputs help, parameters etc, this is written
to STDERR

B<Parameters>
  msg     - additional message to explain why help is displayed (optional)
  state   - int value to exit the program with

B<Sample output help>
    Syntax: app [options] other things

    About:  Boiler plate code for an App::Basis app

    [options]
        -h, --help          Show help
        -i, --item          another item [DEFAULT: 123]
        -t, --test          test item [DEFAULT: testing 123]
        -v --verbose        Dump extra useful information

=item msg_exit

Exit this program writting a message to to STDERR

B<Parameters>
  msg     - message to explain what is going on
  state   - int value to exit the program with

=item daemonise

create a daemon process, detach from the controlling tty
if called by root user, we can optionally specify a dir to chroot into to keep things safer

B<Parameters>
    rootdir - dir to root the daemon into  (optional, root user only)

B<Note: will die on errors>

=item execute_cmd

 execute_cmd(command => ['/my/command','--args'], timeout => 10);

Executes a command using IPC::Cmd::run_forked, less restrictive than run_cmd
see L<IPC::Cmd> for more options that

Input hashref

    command         - string to execute (arrayrefs aren't supported, for some reason)
    timeout         - timeout (in seconds) before command is killed
    stdout_handler  - see IPC::Cmd docs
    stderr_handler  - see IPC::Cmd docs
    child_stdin     - pass data to STDIN of forked processes
    discard_output  - don't return output in hash
    terminate_on_parent_sudden_death

Output HASHREF

    exit_code       - exit code
    timeout         - time taken to timeout or 0 if timeout not used
    stdout          - text written to STDOUT
    stderr          - text written to STDERR
    merged          - stdout and stderr merged into one stream
    err_msg         - description of any error that occurred.

=item run_cmd

Basic way to run a shell program and get its output, this is not interactive.
For interactiviness see execute_cmd.

By default if you do not pass a full path to the command, then unless the command
is in /bin, /usr/bin, /usr/local/bin then the command will not run.

my ($code, $out, $err) = run_cmd( 'ls') ;
#
($code, $out, $err) = run_cmd( 'ls -R /tmp') ;

B<Parameters>
  string to run in the shell
  timeout (optional) in seconds

=item fix_filename

Simple way to replace ~, ./ and ../ at the start of filenames

B<Parameters>
  file name that needs fixing up

=item saymd

convert markdown text into something that can be output onto the terminal

saymd "# # Bringing MD Like Syntax To Bash Shell
It should be something as ***easy***
and as ___natural___ as writing text.

> Keep It Simple
> With quoted sections

Is the idea

  * behind
  * all this

~~~striking~~~ UX for `shell` users too.
- - -
#green(green text)
bg#red(red background text)
" ;

=back

=head1 AUTHOR

Kevin Mulholland <moodfarm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kevin Mulholland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
