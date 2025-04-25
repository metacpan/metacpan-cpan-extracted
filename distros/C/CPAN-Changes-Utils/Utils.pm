package CPAN::Changes::Utils;

use base qw(Exporter);
use strict;
use warnings;

use List::Util qw(max min);
use Readonly;

# Constants.
Readonly::Array our @EXPORT => qw(construct_copyright_years);

our $VERSION = 0.01;

sub construct_copyright_years {
	my $changes = shift;

	my $copyright_years;
	my @years = map { $_->date =~ m/^(\d{4})/ms; $1 }
		grep { defined $_->date }
		$changes->releases;
	my $year_from = min(@years);
	my $year_to = max(@years);
	if (defined $year_from) {
		$copyright_years = $year_from;
		if ($year_from != $year_to) {
			$copyright_years .= '-'.$year_to;
		}
	}

	return $copyright_years;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CPAN::Changes::Utils - Utilities for CPAN::Changes.

=head1 SYNOPSIS

 use CPAN::Changes::Utils qw(construct_copyright_years);

 my $copyright_years = construct_copyright_years($changes);

=head1 SUBROUTINES

=head2 C<construct_copyright_years>

 my $copyright_years = construct_copyright_years($changes);

Construct copyright year(s) from L<CPAN::Changes> instance.

Returns string or undef.

=head1 EXAMPLE

=for comment filename=print_copyright_years.pl

 use strict;
 use warnings;

 use IO::Barf qw(barf);
 use File::Temp;
 use CPAN::Changes;
 use CPAN::Changes::Utils qw(construct_copyright_years);

 # Content.
 my $content = <<'END';
 0.02 2019-07-13
  - item #2
  - item #3
 
 0.01 2009-07-06
  - item #1
 END

 # Temporary file.
 my $temp_file = File::Temp->new->filename;

 # Barf out.
 barf($temp_file, $content);

 # Create CPAN::Changes instance.
 my $changes = CPAN::Changes->load($temp_file);

 # Construct copyright years.
 my $copyright_years = construct_copyright_years($changes);

 # Print copyright years to stdout.
 print "Copyright years: $copyright_years\n";

 # Unlink temporary file.
 unlink $temp_file;

 # Output:
 # Copyright years: 2009-2019

=head1 DEPENDENCIES

L<Exporter>,
L<List::Util>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CPAN-Changes-Utils>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
