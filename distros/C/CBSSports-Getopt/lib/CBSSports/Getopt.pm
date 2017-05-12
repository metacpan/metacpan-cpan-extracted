package CBSSports::Getopt;
use warnings;
use strict;
use Getopt::Long qw();
use File::Basename qw(basename);
use Exporter 'import';
our @EXPORT    = qw(GetOptions Usage Configure);
our $VERSION = '1.1';

our $PRESET_OPTIONS = {
    h       => 'help',
    help    => 'help',
    v       => 'verbose',
    verbose => 'verbose',
    H       => 'man',
    man     => 'man',
    version => 'version',
};

our $ALLOW_PRESET_OVERRIDE = 0;

sub GetOptions {
    my (@option_args) = @_;
    my %opts = ();
    _merge_config_file_options();
    Getopt::Long::Configure( 'no_auto_abbrev', 'no_ignore_case', 'bundling' );
    Getopt::Long::GetOptions( _filter_options( \%opts, \@option_args ) ) || Usage( verbose => 0 );
    _print_version() if $opts{version};
    _clean_options( \%opts );
    return wantarray ? %opts : \%opts;
}

sub Usage {
    my %args = @_;
    print $args{message}, "\n" if $args{message};
    require Pod::Usage && Pod::Usage::pod2usage(
        '-verbose' => $args{verbose} || 99,
        '-sections' => '(?i:(Usage|Options))',
        '-exitval'  => 0,
    );
    return;
}

sub Configure {
    my @config = @_;
    $ALLOW_PRESET_OVERRIDE = scalar grep { $_ eq 'allow_preset_override' } @_;
    return Getopt::Long::Configure( grep { $_ ne 'allow_preset_override' } @_ );
}

sub _clean_options {
    my ( $opts ) = @_;
    for my $option ( keys %$opts ) {
        delete $opts->{$option} unless defined $opts->{$option} 
    }
    return;
}

sub _print_version {
    my $script = basename($0);
    my $version = $main::VERSION ? ( 'v' . $main::VERSION ) : '(unknown version)'; 
    print "$script $version\n";
    exit 1;
}

sub _merge_config_file_options {
    my $config_file = _default_config();
    if ( -e $config_file && open( my $fh, '<', $config_file ) ) {
        my @options = ();
        while ( my $line = <$fh> ) {
            $line =~ s/\#.+$//;
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            next unless $line;
            push @options, split( /\s+/, $line );
        }
        close $fh;
        unshift @ARGV, @options;
    }
}

sub _default_config {
    my $script = basename($0);
    $script =~ s/\.pl$//;
    require File::HomeDir && return File::HomeDir->my_home . '/.' . $script . 'rc';
    warn q|Can't load File::HomeDir|;
    return;
}

sub _filter_options {
    my ( $opts, $option_args ) = @_;
    my $getopt_long_options = {};

    my $found_presets = {};
    my $illegal_preset_count = 0;
    for my $opt (@$option_args) {
        my ( $option_lookup, $hash_key ) = _cleanup_options($opt);
        for my $option ( keys %$option_lookup ) {
            if ( $PRESET_OPTIONS->{$option} && !$ALLOW_PRESET_OVERRIDE) {
                print "By default, you may not override preset option '$option'\n"
                    . "To enable preset overriding use \"Configure( 'allow_preset_override' );\"\n";
                $illegal_preset_count++;
                next;
            }
            elsif ( $PRESET_OPTIONS->{$option} ) {
                $found_presets->{ $PRESET_OPTIONS->{$option} }++;
            }
            $getopt_long_options->{$opt} = \$opts->{$hash_key};
        }
    }

    if ( $illegal_preset_count ) {
        print "\n";
        exit;
    }

    $getopt_long_options->{'h|help'} = sub { Usage( verbose => 0 ) }
        unless $found_presets->{help};
    $getopt_long_options->{'H|man'} = sub { Usage( verbose => 2 ) }
        unless $found_presets->{man};
    $getopt_long_options->{'v|verbose+'} = \$opts->{verbose} unless $found_presets->{verbose};
    $getopt_long_options->{'version'}    = \$opts->{version} unless $found_presets->{version};

    return %$getopt_long_options;
}

sub _cleanup_options {
    my ( $opt ) = @_;
    my $option_lookup = {};
    my ( $option, @modifier ) = split( /([\!\+\=\:])/, $opt );
    my $modifier = join( '', grep { $_ }  @modifier );

    if ( length( $option ) == 1 ) {
        print "Short option definition '$option' is invalid.\n"
            . "A descriptive long option is required when defining short option (ie 'h|help')\n\n";
        exit;
    }

    my @alt_options = split /\|/, $option;
    $option_lookup->{$_} = 1 for @alt_options;

    return ( $option_lookup, _determine_key( \@alt_options ) );
}

sub _determine_key {
    my ( $alt_options ) = @_;
    my @keys = sort { length($b) <=> length($a) } @$alt_options;
    my $key = $keys[0];
    $key =~ s/\-/\_/g;
    return $key;
}

1;

__END__

=head1 NAME

CBSSports::Getopt - Encapsulate Option Parsing and Usage for all CBSSports Perl Scripts

=head1 VERSION

1.1

=head1 SYNOPSIS

The basic usage of CBSSports::Getopt:

  #!/usr/bin/perl
  use strict;
  use warnings;
  use CBSSports::Getopt qw(GetOptions Usage);
  
  my $opts = GetOptions( 'l|league-name' );
  Usage() unless $opts->{league_name};
  
  __END__
  
  =head1 Name
  
  sample-script - A sample script using CBSSports::Getopt
  
  =head1 Usage
  
  sample-script [options]
  
  =head1 Options
  
    -h --help     Print this usage statement and exit.
    -H --man      Print the complete documentation and exit.
    -v --verbose  Turn on verbose output
       --version  Print script version information and quit

=head1 Examples

=head2 Calling the Script's Usage

  sample-script -h


You can also pass additonal options to Getopt::Long::Configure via Configure

  use CBSSports::Getopt qw(GetOptions Usage Configure);
  
  Configure( 'bundling' );
  my $opts = GetOptions( 'l|league-name' );
  Usage() unless $opts->{league_name};

=head1 DESCRIPTION

The purpose of this module is to provide a simple way that script authors 
can easily define options and usage without have to duplicate code in 
each of their scripts.

This module provides the following functionality:

=head2 Getopt::Long for Option Parsing

Simply pass an array of Getopt::Long options to GetOptions and receive a hash 
populated with the options you defined.  See L<Getopt::Long> for details on 
option syntax.  (note that 'no_auto_abbr' and 'no_ignore_case' are enabled 
insead of Getopt::Long's defaults)

=over

=item *

The following options are automatically defined for you.

  -h --help     Show script usage and options
  -H --man      Show full manpage (all pod in script)
  -v --verbose  Incremental verbose ( -v -v -v, verbose = 3 );
     --version  Display version and exit.

You can override these options if nessesary via Configure( 'allow_preset_override' ), 
but are advised against.  We'd like to keep a common interface to all our scripts.

=item *

When specifying a short option name, you should define a long one as well.

  GetOptions( 'l' );  VS   GetOptions( 'l|league-name' );

The long option name gets turned into the hash key.  The more verbose you are in choosing 
an option names, the easier it is to tell what the option is.  You don't get penalized 
for naming these options so other people can understand them.  (other people also includes 
yourself a month from now) :)

=item *

The longest option names get translated into the hash key ( with '_' subsituted for '-' )

For example, if you pass in

  my $opts = GetOptions( 'league-id|league-name|l' );

The result will be stored in

  $opts->{league_name}

If two keys of the same length are passed in, the first one found will be used 
for the hash key.

=item *

Getopt::Long auto abbreviate is turned off by default

By default Getopt::Long auto abbreviates all long options.  Although this functionality
can be clever,  it is not always clear.  Let's err on the side of caution and avoid cleverness.

=item *

Getopt::Long ignore case turned off by default.

Similarly, ignoring case on options may result in confusion.  In order to keep things 
clear, the script should always require the proper case on command line options.

=item *

By using CBSSports::Getopt, you will automatically get the ability to use a .rc file.

For example, say you have a script named 'doit'.  By using CBSSports::Getopt, you will automatically 
be able to store commonly used options in a '.doitrc' file in your home directory.  When the 
script runs, it will read in that optional file and will append any options to @ARGV before 
the command line arguments are run.  Comments and leading/trailing whitespace are removed 
before processing.  You can have multiples options per line.

  # contents of .doitrc
  -u web   # run as user web

=back

=head2 Pod::Usage for Displaying Script Usage

=over

=item *

Usage is just simply pod within your script

At a minimum, you should write pod within your script that contains the USAGE and 
OPTIONS sections.  However, you can write a whole man page if you like :)

=back

=head1 INTERFACE 

=head2 GetOptions( $option1, $option2 );

Pass in an array of options for Getopt::Long::GetOptions to parse.  The function call
will return a hash reference of the options you chose to capture.  Only specifying single 
character options is not allowed.  Each single character option must have a long couterpart.
However, a long option can be specified without a single character counterpart.

  'h'       # incorrect - will fail
  'h|help'  # fine - will define -h and --help
  'help'    # fine - will define --help

For example:

  use CBSSports::Getopt;
  my $opts = GetOptions(
      's|source-point=s', 'r|range-point=s', 'p|single-point=s', 'b|copy-to-begining',
      'e|copy-to-end',    'q|quiet',         'n|do-nothing',
  );

If the script is executed without command line parameters, the hash reference returned from 
the GetOptions call (ex. $opts) will contain: 

  {
    'verbose'          => undef,
    'quiet'            => undef,
    'copy_to_end'      => undef,
    'version'          => undef,
    'range_point'      => undef,
    'source_point'     => undef,
    'single_point'     => undef,
    'do_nothing'       => undef,
    'copy_to_begining' => undef
  }

(Note: verbose and version are automatically defined for you)

=head2 Usage( message => $error_message, verbose => $verbosity_level )

Call usage with an error message string which will be displayed before
the output and verbosity level.  If no verbosity level is specified, 
Usage will only show USAGE and OPTIONS pod secitons.

=head2 Configure( $config1, $config2 );

Configure checks for 'allow_preset_override' before passing the rest of the arguments to 
Getopt::Long::Configure.  See L<Getopt::Long> for details.  'allow_preset_override' allows you
define '-h', '-H', and '-v' for another purpose other than their defaults.

=head1 CONFIGURATION AND ENVIRONMENT

By default, every command line script that uses CBSSports::Getopt will be able to pull commonly used 
options from an .rc file of the same name.  For example, 'auto-load-rosters' would use 
'.auto-load-rostersrc' from your home directory.  

Leading/trailing whitespace and comments in the '.rc' files are removed before processing.

=head1 DEPENDENCIES

CBSSports::Getopt has the following dependancies:

=over

=item *

Getopt::Long

=item *

Pod::Usage

=item *

File::HomeDir

=back

=head1 BUGS AND LIMITATIONS

Some scripts may use '-h', '-H' or '-v' for something other than 'help', 'verbose', 'man'.  You can
override these defaults via Configure( 'allow_preset_override' );

=head1 AUTHOR

Jeff Bisbee  C<< <jbisbee@cbs.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Jeff Bisbee C<< <jbisbee@cbs.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
