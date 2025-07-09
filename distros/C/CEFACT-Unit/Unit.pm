package CEFACT::Unit;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::CEFACT::Unit;
use File::Share ':all';
use IO::File;
use List::Util 1.33 qw(any);
use Mo::utils 0.21 qw(check_array_object);
use Text::CSV_XS;

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Units list.
	$self->{'units'} = [];

	# Process parameters.
	set_params($self, @params);

	# Init all units.
	check_array_object($self, 'units', 'Data::CEFACT::Unit', 'UN/CEFACT unit');
	if (! @{$self->{'units'}}) {
		$self->_init;
	}

	return $self;
}

sub check_common_code {
	my ($self, $common_code) = @_;

	my $ret;
	if (any { $_->common_code eq $common_code } @{$self->{'units'}}) {
		$ret = 1;
	} else {
		$ret = 0;
	}

	return $ret;
}

sub _init {
	my $self = shift;

	# Object.
	my $csv = Text::CSV_XS->new({
		'binary' => 1,
		'escape_char' => '"',
		'quote_char' => '"',
		'sep_char' => ',',
	});

	# Parse file.
	my $fh = IO::File->new;
	my $csv_file = dist_file('CEFACT-Unit', 'code-list.csv');
	$fh->open($csv_file, 'r');
	my $i = 0;
	while (my $columns_ar = $csv->getline($fh)) {
		$i++;

		# Header.
		if ($i == 1) {
			next;
		}

		for (my $i = 0; $i < @{$columns_ar}; $i++) {
			$columns_ar->[$i] = $columns_ar->[$i] ne '' ? $columns_ar->[$i] : undef;
		}

		push @{$self->{'units'}}, Data::CEFACT::Unit->new(
			'common_code' => $columns_ar->[1],
			'conversion_factor' => $columns_ar->[6],
			'description' => $columns_ar->[3],
			'level_category' => $columns_ar->[4],
			'symbol' => $columns_ar->[5],
			'name' => $columns_ar->[2],
			'status' => $columns_ar->[0],
		);
	}
	$fh->close;

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

CEFACT::Unit - CEFACT unit handling.

=head1 SYNOPSIS

 use CEFACT::Unit;

 my $obj = CEFACT::Unit->new(%params);
 my $bool = $obj->check_common_code($unit_common_code);

=head1 METHODS

=head2 C<new>

 my $obj = CEFACT::Unit->new(%params);

Constructor.

=over 8

=item * C<units>

List of units in L<Data::CEFACT::Unit> instances.

Default value is [].

=back

Returns instance of object.

=head2 C<check_common_code>

 my $bool = $obj->check_common_code($unit_common_code);

Check UN/CEFACT unit common code.

Returns bool (0/1).

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         From Mo::utils::check_array_object():
                 Parameter 'units' must be a array.
                         Value: %s
                         Reference: %s
                 UN/CEFACT isn't 'Data::CEFACT::Unit' object.
                         Value: %s
                         Reference: %s

=head1 EXAMPLE

=for comment filename=check_unit_common_code.pl

 use strict;
 use warnings;

 use CEFACT::Unit;

 if (@ARGV < 1) {
         print STDERR "Usage: $0 unit_common_code\n";
         exit 1;
 }
 my $unit_common_code = $ARGV[0];

 # Object.
 my $obj = CEFACT::Unit->new;

 # Check unit common code.
 my $bool = $obj->check_common_code($unit_common_code);

 # Print out.
 print "Unit '$unit_common_code' is ".($bool ? 'valid' : 'invalid')."\n";

 # Output for 'KGM':
 # Unit 'KGM' is valid

 # Output for 'XXX':
 # Unit 'XXX' is invalid

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::CEFACT::Unit>,
L<File::Share>,
L<IO::File>,
L<List::Util>,
L<Text::CSV_XS>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/CEFACT-Unit>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
