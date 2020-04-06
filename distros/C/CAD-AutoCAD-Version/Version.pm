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
	'AC1.40' => 'Version 1.40',
	'AC1.50' => 'Version 2.05',
	'AC2.10' => 'Version 2.10',
	'AC2.21' => 'Version 2.21',
	'AC2.22' => 'Version 2.22',
	'AC1001' => 'Version 2.22',
	'AC1002' => 'Version 2.50',
	'AC1003' => 'Version 2.60',
	'AC1004' => 'Release 9',
	'AC1006' => 'Release 10',
	'AC1009' => 'Release 11/12',
	'AC1012' => 'Release 13',
	'AC1014' => 'Release 14',
	'AC1015' => 'AutoCAD 2000/2000i/2002',
	'AC1018' => 'AutoCAD 2004/2005/2006',
	'AC1021' => 'AutoCAD 2007/2008/2009',
	'AC1024' => 'AutoCAD 2010/2011/2012',
	'AC1027' => 'AutoCAD 2013/2014/2015/2016/2017',
	'AC1032' => 'AutoCAD 2018/2019/2020',
);

our $VERSION = 0.03;

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

=head1 SYNOPSIS

 use CAD::AutoCAD::Version;

 my $obj = CAD::AutoCAD::Version->new;
 my @acad_identifiers = $obj->list_of_acad_identifiers;
 my @acad_identifiers_real = $obj->list_of_acad_identifiers_real;

=head1 METHODS

=head2 C<new>

 my $obj = CAD::AutoCAD::Version->new;

Constructor.

=head2 C<list_of_acad_identifiers>

 my @acad_identifiers = $obj->list_of_acad_identifiers;

List AutoCAD identifiers used as DWG file magic string or $ACADVER in DXF file.

Returns array of identifiers.

=head2 C<list_of_acad_identifiers_real>

 my @acad_identifiers_real = $obj->list_of_acad_identifiers_real;

List AutoCAD identifiers used as DWG file magic string or $ACADVER in DXF file.
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
 #     [1]  "AC1.40",
 #     [2]  "AC1.50",
 #     [3]  "AC1001",
 #     [4]  "AC1002",
 #     [5]  "AC1003",
 #     [6]  "AC1004",
 #     [7]  "AC1006",
 #     [8]  "AC1009",
 #     [9]  "AC1012",
 #     [10] "AC1014",
 #     [11] "AC1015",
 #     [12] "AC1018",
 #     [13] "AC1021",
 #     [14] "AC1024",
 #     [15] "AC1027",
 #     [16] "AC1032",
 #     [17] "AC2.10",
 #     [18] "AC2.21",
 #     [19] "AC2.22",
 #     [20] "MC0.0"
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
 #     [2]  "AC1.40",
 #     [3]  "AC1.50",
 #     [4]  "AC2.10",
 #     [5]  "AC2.21",
 #     [6]  "AC2.22",
 #     [7]  "AC1001",
 #     [8]  "AC1002",
 #     [9]  "AC1003",
 #     [10] "AC1004",
 #     [11] "AC1006",
 #     [12] "AC1009",
 #     [13] "AC1012",
 #     [14] "AC1014",
 #     [15] "AC1015",
 #     [16] "AC1018",
 #     [17] "AC1021",
 #     [18] "AC1024",
 #     [19] "AC1027",
 #     [20] "AC1032",
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

© 2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
