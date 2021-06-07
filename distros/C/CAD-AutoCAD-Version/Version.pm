package CAD::AutoCAD::Version;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Readonly;

# Constants.
# Based on https://autodesk.blogs.com/between_the_lines/autocad-release-history.html
Readonly::Hash my %ACADVER => (
	# ACADVER => Version of AutoCAD
	'MC0.0' => 'Version 1.0',
	'AC1.2' => 'Version 1.2',
	'AC1.3' => 'Version 1.3',
	'AC1.40' => 'Version 1.40',
	'AC1.50' => 'Version 2.05',
	'AC2.10' => 'Version 2.10',
	'AC2.21' => 'Version 2.21',
	'AC2.22' => 'Version 2.22',
	'AC1001' => 'Version 2.40',
	'AC1002' => 'Version 2.50',
	'AC1003' => 'Version 2.60',
	'AC1004' => 'Release 9',
	'AC1006' => 'Release 10',
	'AC1009' => 'Release 11/12',
	'AC1012' => 'Release 13',
	'AC1013' => 'Release 13c3',
	'AC1014' => 'Release 14',
	'AC1015' => 'AutoCAD 2000',
	'AC1016' => 'AutoCAD 2000i',
	'AC1017' => 'AutoCAD 2002',
	'AC1018' => 'AutoCAD 2004',
	'AC1019' => 'AutoCAD 2005',
	'AC1020' => 'AutoCAD 2006',
	'AC1021' => 'AutoCAD 2007',
	'AC1022' => 'AutoCAD 2008',
	'AC1023' => 'AutoCAD 2009',
	'AC1024' => 'AutoCAD 2010',
	'AC1025' => 'AutoCAD 2011',
	'AC1026' => 'AutoCAD 2012',
	'AC1027' => 'AutoCAD 2013',
	'AC1028' => 'AutoCAD 2014',
	'AC1029' => 'AutoCAD 2015',
	'AC1030' => 'AutoCAD 2016',
	'AC1031' => 'AutoCAD 2017',
	'AC1032' => 'AutoCAD 2018',
	'AC1033' => 'AutoCAD 2019',
	'AC1034' => 'AutoCAD 2020',
	'AC1035' => 'AutoCAD 2021',
);

our $VERSION = 0.05;

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

sub list_of_acad_identifiers {
	my $self = shift;

	return keys %ACADVER;
}

sub list_of_acad_identifiers_real {
	my $self = shift;

	my @mcs = sort grep { $_ =~ m/^MC/ms } keys %ACADVER;
	my @ac_dot = sort grep { $_ =~ m/^AC\d+\.\d+$/ms } keys %ACADVER;
	my @ac = sort grep { $_ =~ m/^AC\d+$/ms } keys %ACADVER;

	my @ids = (@mcs, @ac_dot, @ac);

	return @ids;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CAD::AutoCAD::Version - Class which work with AutoCAD versions.

=head1 DESCRIPTION

This class describes AutoCAD versions and it's identifiers.

List of identifiers is in L<Wikipedia article|https://en.wikipedia.org/wiki/AutoCAD_version_history>.

=head1 SYNOPSIS

 use CAD::AutoCAD::Version;

 my $obj = CAD::AutoCAD::Version->new;
 my @acad_identifiers = $obj->list_of_acad_identifiers;
 my @acad_identifiers_real = $obj->list_of_acad_identifiers_real;

=head1 METHODS

=head2 C<new>

 my $obj = CAD::AutoCAD::Version->new;

Constructor.

Returns instance of object.

=head2 C<list_of_acad_identifiers>

 my @acad_identifiers = $obj->list_of_acad_identifiers;

List AutoCAD release identifiers.
This identifiers are used e.g. as magic string in DWG file or as $ACADVER in DXF
files.

Returns array of identifiers.

=head2 C<list_of_acad_identifiers_real>

 my @acad_identifiers_real = $obj->list_of_acad_identifiers_real;

List AutoCAD release identifiers.
This identifiers are used e.g. as magic string in DWG file or as $ACADVER in DXF
files.
Ordered by date of AutoCAD releases.

Returns array of identifiers.

=head1 ERRORS

 new():
         From Class::Utils:
                 Unknown parameter '%s'.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Data::Printer;
 use CAD::AutoCAD::Version;

 # Object.
 my $obj = CAD::AutoCAD::Version->new;

 # Create image.
 my @acad_identifiers = sort $obj->list_of_acad_identifiers;

 # Print out type.
 p @acad_identifiers;

 # Output:
 # [
 #     [0]  "AC1.2",
 #     [1]  "AC1.3",
 #     [2]  "AC1.40",
 #     [3]  "AC1.50",
 #     [4]  "AC1001",
 #     [5]  "AC1002",
 #     [6]  "AC1003",
 #     [7]  "AC1004",
 #     [8]  "AC1006",
 #     [9]  "AC1009",
 #     [10] "AC1012",
 #     [11] "AC1013",
 #     [12] "AC1014",
 #     [13] "AC1015",
 #     [14] "AC1016",
 #     [15] "AC1017",
 #     [16] "AC1018",
 #     [17] "AC1019",
 #     [18] "AC1020",
 #     [19] "AC1021",
 #     [20] "AC1022",
 #     [21] "AC1023",
 #     [22] "AC1024",
 #     [23] "AC1025",
 #     [24] "AC1026",
 #     [25] "AC1027",
 #     [26] "AC1028",
 #     [27] "AC1029",
 #     [28] "AC1030",
 #     [29] "AC1031",
 #     [30] "AC1032",
 #     [31] "AC1033",
 #     [32] "AC1034",
 #     [33] "AC1035",
 #     [34] "AC2.10",
 #     [35] "AC2.21",
 #     [36] "AC2.22",
 #     [37] "MC0.0"
 # ]

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Data::Printer;
 use CAD::AutoCAD::Version;

 # Object.
 my $obj = CAD::AutoCAD::Version->new;

 # Create image.
 my @acad_identifiers_real = $obj->list_of_acad_identifiers_real;

 # Print out type.
 p @acad_identifiers_real;

 # Output:
 # [
 #     [0]  "MC0.0"
 #     [1]  "AC1.2",
 #     [2]  "AC1.3",
 #     [3]  "AC1.40",
 #     [4]  "AC1.50",
 #     [5]  "AC2.10",
 #     [6]  "AC2.21",
 #     [7]  "AC2.22",
 #     [8]  "AC1001",
 #     [9]  "AC1002",
 #     [10] "AC1003",
 #     [11] "AC1004",
 #     [12] "AC1006",
 #     [13] "AC1009",
 #     [14] "AC1012",
 #     [15] "AC1013",
 #     [16] "AC1014",
 #     [17] "AC1015",
 #     [18] "AC1016",
 #     [19] "AC1017",
 #     [20] "AC1018",
 #     [21] "AC1019",
 #     [22] "AC1020",
 #     [23] "AC1021",
 #     [24] "AC1022",
 #     [25] "AC1023",
 #     [26] "AC1024",
 #     [27] "AC1025",
 #     [28] "AC1026",
 #     [29] "AC1027",
 #     [30] "AC1028",
 #     [31] "AC1029",
 #     [32] "AC1030",
 #     [33] "AC1031",
 #     [34] "AC1032",
 #     [35] "AC1033",
 #     [36] "AC1034",
 #     [37] "AC1035",
 # ]

=head1 DEPENDENCIES

L<Class::Utils>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<CAD::AutoCAD::Detect>

Detect AutoCAD files through magic string.

=item L<File::Find::Rule::DWG>

Common rules for searching DWG files.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CAD-AutoCAD-Version>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
