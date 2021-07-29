#!/usr/bin/perl

# Process property files and produce JSON data.

# Author          : Johan Vromans
# Created On      : Tue Sep  8 18:49:04 2020
# Last Modified By: Johan Vromans
# Last Modified On: Fri Apr 16 19:35:47 2021
# Update Count    : 36
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'Data-Properties';
# Program name and version.
my ($my_name, $my_version) = qw( prp2json 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $includes = 1;		# handle includes
my $raw = 0;			# raw(er) data
my $verbose = 1;		# verbose processing
my $output;			# output
my $pretty = 0;			# human readable output
my $perl = 0;			# dump perl data instead
my $prp = 0;			# dump properties instead

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################


################ The Process ################

use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Properties;
use JSON::PP;

binmode STDOUT => ':utf8';
binmode STDERR => ':utf8';

my $cfg = Data::Properties->new( _noinc => !$includes, _raw => $raw );

$cfg->parse_file($_) for @ARGV;

if ( $output && $output ne '-' ) {
    open( STDOUT, '>:utf8', $output )
      or die("$output: $!\n");
}

if ( $perl ) {
    print STDOUT ( ::dump($cfg->data) );
}
elsif ( $prp ) {
    print STDOUT ( $cfg->dump );
}
else {
    my $pp = JSON::PP->new->canonical;
    $pp->pretty if $pretty;
    print STDOUT ( $pp->encode($cfg->data) );
}

################ Subroutines ################

sub ::dump {
    use Data::Dumper qw();
    local $Data::Dumper::Sortkeys  = 1;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Trailingcomma = 1;
    local $Data::Dumper::Useperl = 1;
    local $Data::Dumper::Useqq     = 0; # I want unicode visible

    my $s = Data::Dumper::Dumper @_;
    defined wantarray or warn $s;
    return $s;
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions( 'raw!'	=> \$raw,
		    'includes!'	=> \$includes,
		    'output=s'	=> \$output,
		    'pretty'	=> \$pretty,
		    'perl'	=> \$perl,
		    'properties|prp'	=> \$prp,
		    'ident'	=> \$ident,
		    'verbose+'	=> \$verbose,
		    'quiet'	=> sub { $verbose = 0 },
		    'trace'	=> \$trace,
		    'help|?'	=> \$help,
		    'man'	=> \$man,
		    'debug'	=> \$debug )
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}

__END__

################ Documentation ################

=head1 NAME

prp2json - process property files and produce JSON data.

=head1 SYNOPSIS

prp2json [options] [file ...]

 Options:
   --[no]includes	"include" is an ordinary key
   --[no]raw		slightly rawer output
   --output=XXX		JSON output
   --pretty		JSON output is readable
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

=item B<--no-includes>

Inhibits include processing. C<"include"> will be considered an
ordinary property.

=item B<--raw>

For internal use only.

=item B<--output=>I<XXX>

Output file for JSON data.

=item B<--pretty>

JSON data will be human readable.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.
This option may be repeated to increase verbosity.

=item B<--quiet>

Suppresses all non-essential information.

=item I<file>

The input file(s) to process.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and output the
resultant data as JSON.

=cut
