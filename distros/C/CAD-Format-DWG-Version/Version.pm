package CAD::Format::DWG::Version;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Readonly;

# Constants.
# Based on https://ru.wikipedia.org/wiki/DWG
Readonly::Hash my %DWGVER => (
	# DWG magic => DWG name and publication order
	'MC0.0' => { 'name' => 'DWG R1.0', 'order' => 1 },
	'AC1.2' => { 'name' => 'DWG R1.2', 'order' => 2 },
	'AC1.40' => { 'name' => 'DWG R1.40', 'order' => 3 },
	'AC1.50' => { 'name' => 'DWG R2.05', 'order' => 4 },
	'AC2.10' => { 'name' => 'DWG R2.10', 'order' => 5 },
	'AC1001' => { 'name' => 'DWG R2.22', 'order' => 8 },
	'AC1002' => { 'name' => 'DWG R2.50', 'order' => 9 },
	'AC1003' => { 'name' => 'DWG R2.60', 'order' => 10 },
	'AC1004' => { 'name' => 'DWG R9', 'order' => 11 },
	'AC1006' => { 'name' => 'DWG R10', 'order' => 12 },
	'AC1009' => { 'name' => 'DWG R11/12', 'order' => 13 },
	'AC1010' => { 'name' => 'DWG pre-R13 a', 'order' => 14 },
	'AC1011' => { 'name' => 'DWG pre-R13 b', 'order' => 15 },
	'AC1012' => { 'name' => 'DWG R13', 'order' => 16 },
	'AC1013' => { 'name' => 'DWG R13 beta', 'order' => 17 },
	'AC1014' => { 'name' => 'DWG R14', 'order' => 18 },
	'AC1500' => { 'name' => 'DWG 2000 beta', 'order' => 19 },
	'AC1015' => { 'name' => 'DWG 2000', 'order' => 20 },
	'AC402a' => { 'name' => 'DWG 2004 alpha', 'order' => 21 },
	'AC402b' => { 'name' => 'DWG 2004 beta', 'order' => 22 },
	'AC1018' => { 'name' => 'DWG 2004', 'order' => 23 },
	'AC1021' => { 'name' => 'DWG 2007', 'order' => 24 },
	'AC1024' => { 'name' => 'DWG 2010', 'order' => 25 },
	'AC1027' => { 'name' => 'DWG 2013', 'order' => 26 },
	'AC1032' => { 'name' => 'DWG 2018', 'order' => 27 },
	'AC103-4' => { 'name' => 'DWG 2022 beta', 'order' => 28 },
);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

sub list_of_dwg_identifiers {
	my $self = shift;

	my @keys = sort { $DWGVER{$a}->{'order'} <=> $DWGVER{$b}->{'order'} } keys %DWGVER;

	return @keys;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CAD::Format::DWG::Version - Class for work with DWG file versions.

=head1 DESCRIPTION

This class describes AutoCAD DWG format versions and it's identifiers.

List of identifiers is in L<Wikipedia article|https://en.wikipedia.org/wiki/AutoCAD_version_history>.

This Perl class replaces L<CAD::AutoCAD::Version>@0.06, which has the wrong name.

=head1 SYNOPSIS

 use CAD::Format::DWG::Version;

 my $obj = CAD::Format::DWG::Version->new;
 my @dwg_identifiers = $obj->list_of_dwg_identifiers;

=head1 METHODS

=head2 C<new>

 my $obj = CAD::Format::DWG::Version->new;

Constructor.

Returns instance of object.

=head2 C<list_of_dwg_identifiers>

 my @dwg_identifiers = $obj->list_of_dwg_identifiers;

List DWG version identifiers sorted by publication.
This identifiers are used e.g. as magic string in DWG files or as C<$ACADVER> in DXF
files.

Returns array of identifiers.

=head1 ERRORS

 new():
         From Class::Utils:
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=list_of_dwg_identifiers.pl

 use strict;
 use warnings;

 use Data::Printer;
 use CAD::Format::DWG::Version;

 # Object.
 my $obj = CAD::Format::DWG::Version->new;

 # Create image.
 my @dwg_identifiers = $obj->list_of_dwg_identifiers;

 # Print out type.
 p @dwg_identifiers;

 # Output:
 # [
 #     [0]  "MC0.0",
 #     [1]  "AC1.2",
 #     [2]  "AC1.40",
 #     [3]  "AC1.50",
 #     [4]  "AC2.10",
 #     [5]  "AC1001",
 #     [6]  "AC1002",
 #     [7]  "AC1003",
 #     [8]  "AC1004",
 #     [9]  "AC1006",
 #     [10] "AC1009",
 #     [11] "AC1010",
 #     [12] "AC1011",
 #     [13] "AC1012",
 #     [14] "AC1013",
 #     [15] "AC1014",
 #     [16] "AC1500",
 #     [17] "AC1015",
 #     [18] "AC402a",
 #     [19] "AC402b",
 #     [20] "AC1018",
 #     [21] "AC1021",
 #     [22] "AC1024",
 #     [23] "AC1027",
 #     [24] "AC1032",
 #     [25] "AC103-4"
 # ]

=head1 DEPENDENCIES

L<Class::Utils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<CAD::AutoCAD::Detect>

Detect AutoCAD files through magic string.

=item L<CAD::AutoCAD::Version>

Class which work with AutoCAD versions.

=item L<File::Find::Rule::DWG>

Common rules for searching DWG files.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CAD-Format-DWG-Version>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
