#!/usr/bin/perl
####################################################################################################
# sass (scss) compiler
####################################################################################################

use strict;
use warnings;

####################################################################################################
# dependencies
####################################################################################################

# parse options
use Pod::Usage;
use Getopt::Long;

# convenient file handling
use File::Slurp qw(write_file);

# load constants from libsass
use CSS::Sass qw(SASS_STYLE_EXPANDED);
use CSS::Sass qw(SASS_STYLE_NESTED);
use CSS::Sass qw(SASS_STYLE_COMPRESSED);
use CSS::Sass qw(SASS_STYLE_COMPACT);
use CSS::Sass::Watchdog qw(start_watchdog);

####################################################################################################
# normalize command arguments to utf8
####################################################################################################

# get cmd arg encoding
use Encode::Locale qw();
# convert cmd args to utf8
use Encode qw(decode encode);
# now just decode every command arguments
@ARGV = map { decode(locale => $_, 1) } @ARGV;

####################################################################################################
# config variables
####################################################################################################

# init options
my $watchdog;
my $benchmark;
my $precision;
my $output_file;
my $output_style;
my $source_comments;
my $source_map_file;
my $source_map_embed;
my $source_map_contents;
my $omit_source_map_url;

# define a sub to print out the version (mimic behaviour of node.js blessc)
# this script has it's own version numbering as it's not dependent on any libs
sub version {
	printf "psass %s (perl sass/scss compiler)\n", "0.4.0";
	printf "  libsass: %s\n", CSS::Sass::libsass_version();
	printf "  sass2scss: %s\n", CSS::Sass::sass2scss_version();
exit 0 };

# paths arrays
my @plugin_paths;
my @include_paths;

# output styles
my $indent = "  ";
my $linefeed = "auto";

# get options
GetOptions (
	'help|h' => sub { pod2usage(1); },
	'watch|w!' => \ $watchdog,
	'version|v' => \ &version,
	'benchmark|b!' => \ $benchmark,
	'indent=s' => \ $indent,
	'linefeed=s' => \ $linefeed,
	'precision|p=s' => \ $precision,
	'output-file|o=s' => \ $output_file,
	'output-style|t=s' => \ $output_style,
	'source-comments|c!' => \ $source_comments,
	'source-map-file|m=s' => \ $source_map_file,
	'source-map-embed|e!' => \ $source_map_embed,
	'source-map-contents|s!' => \ $source_map_contents,
	'no-source-map-url!' => \ $omit_source_map_url,
	'plugin-path|L=s' => sub { push @plugin_paths, $_[1] },
	'include-path|I=s' => sub { push @include_paths, $_[1] }
);

# set default if not configured
unless (defined $output_style)
{ $output_style = SASS_STYLE_NESTED }

# parse string to constant
elsif ($output_style =~ m/^n/i)
{ $output_style = SASS_STYLE_NESTED }
elsif ($output_style =~ m/^compa/i)
{ $output_style = SASS_STYLE_COMPACT }
elsif ($output_style =~ m/^compr/i)
{ $output_style = SASS_STYLE_COMPRESSED }
elsif ($output_style =~ m/^e/i)
{ $output_style = SASS_STYLE_EXPANDED }
# die with message if style is unknown
else { die "unknown output style: $output_style" }

# resolve linefeed options
if ($linefeed =~ m/^a/i)
{ $linefeed = undef; }
elsif ($linefeed =~ m/^w/i)
{ $linefeed = "\r\n"; }
elsif ($linefeed =~ m/^[u]/i)
{ $linefeed = "\n"; }
elsif ($linefeed =~ m/^[n]/i)
{ $linefeed = ""; }
# die with message if linefeed type is unknown
else { die "unknown linefeed type: $linefeed" }

# do we have output path in second arg?
if (defined $ARGV[1] && $ARGV[1] ne '-')
{ $output_file = $ARGV[1]; }

# check if the benchmark module is available
if ($benchmark && ! eval "use Benchmark; 1" )
{ die "Error loading Benchmark module\n", $@; }

####################################################################################################
# get sass standard option list
####################################################################################################

sub sass_options ()
{
	return (
		dont_die => $watchdog,
		indent => $indent,
		linefeed => $linefeed,
		precision => $precision,
		output_path => $output_file,
		output_style  => $output_style,
		plugin_paths => \ @plugin_paths,
		include_paths => \ @include_paths,
		source_comments => $source_comments,
		source_map_file => $source_map_file,
		source_map_embed => $source_map_embed,
		source_map_contents => $source_map_contents,
		omit_source_map_url => $omit_source_map_url,
	);
}

####################################################################################################
use CSS::Sass qw(sass_compile_file sass_compile);
####################################################################################################

# first run we always want to die on error
# because we will not get any included files
our $error = sub { die @_ };

sub compile ()
{
	# variables
	my ($css, $err, $stats);

	# get benchmark stamp before compiling
	my $t0 = $benchmark ? Benchmark->new : 0;

	# open filehandle if path is given
	if (defined $ARGV[0] && $ARGV[0] ne '-')
	{
		($css, $err, $stats) = sass_compile_file(
			$ARGV[0], sass_options()
		);
	}
	# or use standard input
	else
	{
		($css, $err, $stats) = sass_compile(
			join('', <STDIN>), sass_options()
		);
	}

	# get benchmark stamp after compiling
	my $t1 = $benchmark ? Benchmark->new : 0;
	# only print benchmark result when module is available
	if ($benchmark) { print timestr(timediff($t1, $t0), 'auto', '5.4f'), "\n"; }

	# process return status values
	if (defined $css)
	{
		# by default we just print to standard out
		unless (defined $output_file) { print $css; }
		# or if output_file is defined via options we write it there
		else { write_file($output_file, { binmode => ':utf8' }, $css ); }
	}
	elsif (defined $err) { $error->($err); }
	else { $error->("fatal error - aborting"); }

	# output source-map
	if ($source_map_file)
	{
		my $smap = $stats->{'source_map_string'};
		unless ($smap) { $error->("source-map not generated <$source_map_file>") }
		else { write_file($source_map_file, { binmode => ':utf8' }, $smap ); }
	}

	# return according to expected return type
	return wantarray ? ($css, $err, $stats) : $css;
}

####################################################################################################
# main program execution
####################################################################################################

my ($css, $err, $stats) = compile();

if ($watchdog)
{
	local $error = sub { warn @_ };
	start_watchdog($stats, \&compile);
}

####################################################################################################
####################################################################################################

__END__

=head1 NAME

psass - perl sass (scss) compiler

=head1 SYNOPSIS

psass [options] [ path_in | - ] [ path_out | - ]

 Options:
   -v, --version                 print version
   -h, --help                    print this help
   -w, --watch                   start watchdog mode
   -p, --precision=int           precision for float output
       --indent=string           set indent string used for output
       --linefeed=type           linefeed used for output [auto|unix|win|none]
   -o, --output-file=file        output file to write result to
   -t, --output-style=style      output style [expanded|nested|compressed|compact]
   -L, --plugin-path=path        plugin load path (repeatable)
   -I, --include-path=path       sass include path (repeatable)
   -c, --source-comments         enable source debug comments
   -e, --source-map-embed        embed source-map in mapping url
   -s, --source-map-contents     include original contents
   -m, --source-map-file=file    create and write source-map to file
       --no-source-map-url       omit sourceMappingUrl from output
       --benchmark               print benchmark for compilation time

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message with options and exits.

=back

=head1 DESCRIPTION

B<This program> is a sass (scss) compiler

=cut
