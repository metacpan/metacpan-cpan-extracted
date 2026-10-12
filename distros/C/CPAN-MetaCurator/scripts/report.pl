#!/usr/bin/env perl

use feature 'say';
use open qw(:std :utf8);
use strict;
use warnings;
use warnings qw(FATAL utf8);

use Data::Dumper::Concise; # For Dumper().

use CPAN::MetaCurator::Search;

use Getopt::Long;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options) = @_;

	return CPAN::MetaCurator::Search
			-> new(home_path => $options{home_path}, log_level => $options{log_level}, report_type => $options{report_type})
			-> report;

} # End of process.

# ------------------------------------------------

#say "report.pl - Read tiddlers file and report various things\n";

my(%options);

$options{help}		 	= 0;
$options{home_path}		= "$ENV{HOME}/perl.modules/CPAN-MetaCurator";
$options{log_level}		= 'info';
$options{report_type}	= 'topics';
my(%opts)			=
(
	'help'			=> \$options{help},
	'home_path'		=> \$options{home_path},
	'log_level=s'	=> \$options{log_level},
	'report_type=s'	=> \$options{report_type},
);

GetOptions(%opts) || die("Error in options. Options: " . Dumper(%opts) );

if ($options{help} == 1)
{
	pod2usage(1);

	exit 0;
}

exit process(%options);

__END__

=pod

=head1 NAME

report.pl - Read tiddlers file and report various things

=head1 SYNOPSIS

create.tables.pl [options]

	Options:
	-help
	-home_path
	-log_level info

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -home_path String

The path to the directory containing data/ and html/.
Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaCurator.

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=back

=cut

__DATA__

binmode STDOUT, ':encoding(UTF-8)';

my($log_level)	= 'debug';
my($importer)	= CPAN::MetaCurator::Import -> new(home_path => '.', log_level => $log_level);
my($data)		= $importer -> read_tiddlers_file;
my($count)		= 0;

my($text, $title);

for my $index (0 .. $#$data)
{
	# Node keys: created, modified, text, title.

	$text	= $$data[$index]{text};
	$title	= $$data[$index]{title};

	$count++;

	say "Record: $count. Missing prefix", next if ($text !~ m/^\"\"\"\no (.+)$/s);
#	say "$$data[$index]{title}: $$data[$index]{text}";
	say $$data[$index]{title};
}