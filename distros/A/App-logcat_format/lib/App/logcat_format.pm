package App::logcat_format;

# ABSTRACT: pretty print adb logcat output 

use strict;
use warnings;

use Cache::LRU;
use Term::ReadKey;
use Term::ANSIColor;
use IO::Async::Loop;
use IO::Async::Process;
use Getopt::Long::Descriptive;
use IO::Interactive qw( is_interactive );

=pod

=head1 NAME

logcat_format - pretty print android adb logcat output

=head1 DESCRIPTION

A tool to pretty print the output of the android sdk 'adb logcat' command.

=head1 SYNOPSIS

Default adb logcat pretty print ..

    % logcat_format 

For default logcat output for emulator only ..

    % logcat_format -e 

For default logcat output for device only ..

    % logcat_format -d

For other adb logcat commands, just pipe into logcat_format ..

    % adb logcat -v threadtime | logcat_format
    % adb -e logcat -v process | logcat_format

=head1 VERSION

version 0.06

=cut

# set it up
my ($opt, $usage) = describe_options(
  'logcat_format',
  [ 'emulator|e', "connect to emulator", ],
  [ 'device|d',   "connect to device", ],
  [],
  [ 'help|h',     "print usage message and exit" ],
);
 
print($usage->text), exit if $opt->help;
 
my %priority = 
(
    V => 'bold black on_bright_white',  # Verbose
    D => 'bold black on_bright_blue',   # Debug
    I => 'bold black on_bright_green',  # Info
    W => 'bold black on_bright_yellow', # Warn
    E => 'bold black on_bright_red',    # Error
    F => 'bold white on_black',         # Fatal
    S => 'not printed',                 # Silent
);

my %known_tags = 
(
    dalvikvm        => 'bright_blue',
    PackageManager  => 'cyan',
    ActivityManager => 'blue',
);

my $cache = Cache::LRU->new( size => 1000 );
my @colors = ( 1 .. 15 );

my ( $wchar, $hchar, $wpixels, $hpixels ) = GetTerminalSize();

my %longline;

sub run
{
    my $class = shift;

    if ( is_interactive() ) 
    {
        # kick off adb logcat with args
        my $loop = IO::Async::Loop->new;

        my $argument = '-a';
        $argument = '-e' if $opt->emulator;
        $argument = '-d' if $opt->device;
       
        my $process = IO::Async::Process->new(
           command => [ 'adb', $argument, 'logcat' ],
           stdout => {
              on_read => sub {
                 my ( $stream, $buffref ) = @_;
                 format_line( $1 ) while( $$buffref =~ s/^(.*)\n// );
                 return 0;
              },
           },
           on_finish => sub {
              print "The process has finished\n";
           }
        );
        $loop->add( $process );
        $loop->run();
    }
    else
    {
        # piped to STDIN 
        format_line( $_ ) while ( <STDIN> );
    }
}

sub format_line 
{
    my $line = shift; chomp $line;

    if ( $line =~ m!^
        (?<priority>V|D|I|W|E|F|S)
          \/
            (?<tag>.+?)
              \(\s{0,5}
              (?<pid>\d{1,5})
            \):\s
          (?<log>.*)
        $!xms )
    {
        # 'BRIEF' format
        print colored( sprintf( " %5s ", $+{pid} ), 'bold black on_grey9' );
        print colored( sprintf( " %s ", $+{priority} ), "bold $priority{ $+{priority} }" );
        print colored( sprintf( "  %25s ", tag_format( $+{tag} ) ), tag_colour( $+{tag} ) );
        print colored( sprintf( " %s", log_format( $+{log}, 39 ) ), 'white' );
        print "\n";
    }
    elsif ( $line =~ m!^
        (?<priority>V|D|I|W|E|F|S)
          \(\s{0,}?
            (?<pid>\d{1,5})
              \){1}\s{1}
                (?<log>.*)
              \s{1,}?\(
            (?<tag>.+?)
          \)\s{1,}?
        $!xms )
    {
        # 'PROCESS' format
        print colored( sprintf( " %5s ", $+{pid} ), 'bold black on_grey9' );
        print colored( sprintf( " %s ", $+{priority} ), "bold $priority{ $+{priority} }" );
        print colored( sprintf( "  %25s ", tag_format( $+{tag} ) ), tag_colour( $+{tag} ) );
        print colored( sprintf( " %s", log_format( $+{log}, 39 ) ), 'white' );
        print "\n";
    }
    elsif ( $line =~ m!^
        (?<priority>V|D|I|W|E|F|S)
          \/
            (?<tag>.+?)
            :\s{1}
          (?<log>.*)
        $!xms )
    {
        # 'TAG' format
        print colored( sprintf( " %s ", $+{priority} ), "bold $priority{ $+{priority} }" );
        print colored( sprintf( "  %25s ", tag_format( $+{tag} ) ), tag_colour( $+{tag} ) );
        print colored( sprintf( " %s", log_format( $+{log}, 32 ) ), 'white' );
        print "\n";
    }
    elsif ( $line =~ m!^
        (?<date>\d\d-\d\d)
          \s
            (?<time>\d\d:\d\d:\d\d\.\d\d\d)
              \s
                (?<priority>V|D|I|W|E|F|S)
                  \/
                  (?<tag>.+)
                \(\s*
              (?<pid>\d{1,5})
            \):\s
          (?<log>.*)
        $!xms )
    {
        # 'TIME' format
        print colored( sprintf( " %5s ", $+{time} ), 'bold black on_grey12' );
        print colored( sprintf( " %5s ", $+{date} ), 'bold black on_grey7' );
        print colored( sprintf( " %5s ", $+{pid} ), 'bold black on_grey9' );
        print colored( sprintf( " %s ", $+{priority} ), "bold $priority{ $+{priority} }" );
        print colored( sprintf( "  %25s ", tag_format( $+{tag} ) ), tag_colour( $+{tag} ) );
        print colored( sprintf( " %s", log_format( $+{log}, 60 ) ), 'white' );
        print "\n";
    }
    elsif ( $line =~ m/^
        (?<date>\d\d-\d\d)
          \s
            (?<time>\d\d:\d\d:\d\d\.\d\d\d)
              \s{1,5}
                (?<pid>\d{1,5})
                  \s{1,5}
                    (?<tid>\d{1,5})
                    \s
                  (?<priority>V|D|I|W|E|F|S)
                \s
              (?<tag>.+?)
            :\s{1,}?
          (?<log>.*)
        $/xms )
    {
        # 'THREADTIME' format
        print colored( sprintf( " %5s ", $+{time} ), 'bold black on_grey12' );
        print colored( sprintf( " %5s ", $+{date} ), 'bold black on_grey7' );
        print colored( sprintf( " %5s ", $+{pid} ), 'bold black on_grey9' );
        print colored( sprintf( " %5s ", $+{tid} ), 'bold black on_grey10' );
        print colored( sprintf( " %s ", $+{priority} ), "bold $priority{ $+{priority} }" );
        print colored( sprintf( "  %25s ", tag_format( $+{tag} ) ), tag_colour( $+{tag} ) );
        print colored( sprintf( " %s", log_format( $+{log}, 67 ) ), 'white' );
        print "\n";
    }
    else
    {
        print "$line\n";
    }
}

sub tag_format
{
    my $tag = shift;

    $tag =~ s/^\s+|\s+$//g;
    return substr( $tag, ( length $tag ) - 25 ) if ( length $tag > 25 );
    return $tag;
}

sub tag_colour 
{
    my $tag = shift;

    return $known_tags{$tag} if ( exists $known_tags{$tag} );
    return $cache->get( $tag ) if ( $cache->get( $tag ) );

    $cache->set ( $tag => "ANSI$colors[0]" );
    push @colors, shift @colors;

    return $cache->get( $tag );
}

sub log_format
{
    my ( $msg, $wrap ) = @_;

    $msg =~ s/^\s+|\s+$//g;

    return $msg if ( ! defined $wrap ); 
    return $msg if length $msg < ( $wchar - $wrap );

    my $str = substr $msg, 0, ( $wchar - $wrap );
    $str .= "\n";
    $str .= ' ' x $wrap;
    $str .= substr $msg, ( $wchar - $wrap );

    return $str;
}

1;
