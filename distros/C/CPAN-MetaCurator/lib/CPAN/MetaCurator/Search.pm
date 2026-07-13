package CPAN::MetaCurator::Search;

use boolean;
use feature 'say';
use open qw(:std :utf8);
use parent 'CPAN::MetaCurator::HTML';
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Data::Dumper::Concise; # For Dumper().

use File::Slurper 'read_lines';
use File::Spec;

use Moo;

use Types::Standard qw/Str/;

has names_path =>
(
	default		=> sub{return 'data/module.names.txt'},
	is			=> 'rw',
	isa			=> Str,
	required	=> 0,
);

our $VERSION = '1.26';

# --------------------------------------------------

sub check
{
	my($self) = @_;

	$self -> init_config;
	$self -> init_db;

	my($pad)			= $self -> build_pad;
	my($database_path)	= File::Spec -> catfile($self -> home_path, $self -> database_path);
	my($names_path)		= File::Spec -> catfile($self -> home_path, $self -> names_path);

	$self -> logger -> info("Searching modules table");
	$self -> logger -> info("Reading: $database_path");
	$self -> logger -> info("Reading: $names_path");
	$self -> logger -> debug(Dumper $$pad{module_names});

	my(@names) = read_lines($names_path);

	my($found, @found);
	my(@not_found);

	for my $name (sort @names)
	{
		$found = exists $$pad{module_names}{$name};

		if ($found)
		{
			push @found, $name;
		}
		else
		{
			push @not_found, $name;
		}
	}

	$self -> logger -> info('Found:');
	$self -> logger -> info(Dumper @found);
	$self -> logger -> info('Not found:');
	$self -> logger -> info(Dumper @not_found);
	$self -> logger -> info('check() finished');

} # End of check.

# --------------------------------------------------

1;

=pod

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author.

=head1 Method check()

Note: Module names are case-sensitive.

The purpose is to read a file of module names and classify them as found (already in the db)
and not found (new). This makes updating Perl.Wiki.html much easier since I can ignore the former.

This module is used via check.module.names.pl.

=head1 Author

L<CPAN::MetaCurator> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2025.

My homepage: L<https://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2026, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
