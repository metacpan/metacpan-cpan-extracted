package App::CPAN::Get::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Readonly;

Readonly::Array our @EXPORT_OK => qw(process_module_name_and_version);

our $VERSION = 0.13;

# Code from Menlo::CLI::Compat
sub process_module_name_and_version {
	my $module_string = shift;

	# Plack@1.2 -> Plack~"==1.2"
	# BUT don't expand @ in git URLs
	$module_string =~ s/^([A-Za-z0-9_:]+)@([v\d\._]+)$/$1~== $2/;

	# Plack~1.20, DBI~"> 1.0, <= 2.0"
	my ($module_name, $module_version_range);
	if ($module_string =~ /\~[v\d\._,\!<>= ]+$/) {
		($module_name, $module_version_range)
			= split '~', $module_string, 2;
	} else {
		$module_name = $module_string;
	}

	return ($module_name, $module_version_range);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::CPAN::Get::Utils - Utilities for App::CPAN::Get.

=head1 SYNOPSIS

 use App::CPAN::Get::Utils qw(process_module_name_and_version);

 my ($module_name, $module_version_range) = process_module_name_and_version($module_string);

=head1 SUBROUTINES

=head2 C<process_module_name_and_version>

 my ($module_name, $module_version_range) = process_module_name_and_version($module_string);

Process module name string.

Returns array with module name and module version range strings.

=head1 EXAMPLE

=for comment filename=process_module_name_and_version.pl

 use strict;
 use warnings;

 use App::CPAN::Get::Utils qw(process_module_name_and_version);

 if (@ARGV < 1) {
         print STDERR "Usage: $0 module_name[\@module_version]\n";
         exit 1;
 }
 my $module_name_and_version = $ARGV[0];

 my ($module_name, $module_version_range) = process_module_name_and_version($module_name_and_version);

 print "Module string from input: $module_name_and_version\n";
 print "Module name: $module_name\n";
 if (defined $module_version_range) {
         print "Module version range: $module_version_range\n";
 }

 # Output for 'Module':
 # Module string from input: Module
 # Module name: Module

 # Output for 'Module@1.23':
 # Module string from input: Module@1.23
 # Module name: Module
 # Module version range: == 1.23

=head1 DEPENDENCIES

L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-CPAN-Get>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.13

=cut
