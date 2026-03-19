#!/usr/bin/env perl

use 5.36.0;

use Data::Dumper::Concise; # For Dumper.

use Getopt::Long;

use CPAN::MetaPackager::Import;

use Pod::Usage; # For pod2usage().

# ------------------------------------------------

sub process
{
	my(%options)	= @_;

	return CPAN::MetaPackager::Import
			-> new(home_path => $options{home_path}, log_level => $options{log_level}) -> populate_all_tables;

} # End of process.

# ------------------------------------------------

say "populate.sqlite.tables.pl - Populate all SQLite tables\n";

my(%options);

$options{help}		 	= 0;
$options{home_path}		= "$ENV{HOME}/perl.modules/CPAN-MetaPackager";
$options{log_level}		= 'info';
$options{packages_path}	= '/tmp/02packages.details.txt';
my(%opts)			=
(
	'help'				=> \$options{help},
	'home_path'			=> \$options{home_path},
	'packages_path=s'	=> \$options{packages_path},
	'log_level=s'		=> \$options{log_level},
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

populate.sqlite.tables.pl - Populate all SQLite tables

=head1 SYNOPSIS

populate.sqlite.tables.pl [options]

	Options:
	-help
	-home_path string
	-packages_path string
	-log_level info

All switches can be reduced to a single letter, except of course -he and -ho.

Exit value: 0.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item home_path String

The path to the directory containing data/ and html/. Unpack distro to populate.

Default: $ENV{HOME}/perl.modules/CPAN-MetaPackager.

=item -log_level String

Available log levels are trace, debug, info, warn, error and fatal, in that order.

Default: info.

=item -packages_path String

The path to 02packages.details.txt.

Default: /tmp/02packages.details.txt.

=back

=cut
