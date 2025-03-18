package Data::Random::HashType;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::HashType 0.05;
use DateTime;
use Error::Pure qw(err);
use Mo::utils 0.25 qw(check_bool check_isa check_number_min check_required);
use Random::Day::InThePast;
use Readonly;

Readonly::Array our @OBSOLETE_HASH_TYPES => qw(MD4 MD5 SHA1);
Readonly::Array our @DEFAULT_HASH_TYPES => qw(SHA-256 SHA-384 SHA-512);
Readonly::Array our @ALL_HASH_TYPES => (@OBSOLETE_HASH_TYPES, @DEFAULT_HASH_TYPES);

our $VERSION = 0.06;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Start date time.
	$self->{'dt_start'} = DateTime->new(
		'day' => 1,
		'month' => 1,
		'year' => ((localtime)[5] + 1900 - 1),
	);

	# Id.
	$self->{'id'} = 1;
	$self->{'cb_id'} = sub {
		return $self->{'id'}++;
	};

	# Add id or not.
	$self->{'mode_id'} = 0;

	# Number of hash types.
	$self->{'num_generated'} = 1;

	# Hash types.
	$self->{'possible_hash_types'} = \@DEFAULT_HASH_TYPES;

	# Process parameters.
	set_params($self, @params);

	check_required($self, 'dt_start');
	check_isa($self, 'dt_start', 'DateTime');
	check_bool($self, 'mode_id');
	check_number_min($self, 'num_generated', 1);
	check_required($self, 'num_generated');
	if (ref $self->{'possible_hash_types'} ne 'ARRAY') {
		err "Parameter 'possible_hash_types' must be a reference to array.";
	}
	if (! @{$self->{'possible_hash_types'}}) {
		err "Parameter 'possible_hash_types' must contain at least one hash type name.";
	}

	$self->{'_random_valid_from'} = Random::Day::InThePast->new(
		'dt_from' => $self->{'dt_start'},
	);

	return $self;
}

sub random {
	my $self = shift;

	my @ret;
	if ($self->{'num_generated'} < @{$self->{'possible_hash_types'}}) {

		my @list = @{$self->{'possible_hash_types'}};
		foreach my $id (1 .. $self->{'num_generated'}) {
			my $rand_index = int(rand(scalar @list));
			my $hash_type = splice @list, $rand_index, 1;
			push @ret, Data::HashType->new(
				$self->{'mode_id'} ? (
					'id' => $self->{'cb_id'}->($self),
				) : (),
				'name' => $hash_type,
				'valid_from' => $self->{'_random_valid_from'}->get->clone,
			);
		}
	} else {
		my $i = 1;
		foreach my $hash_type (@{$self->{'possible_hash_types'}}) {
			push @ret, Data::HashType->new(
				$self->{'mode_id'} ? (
					'id' => $self->{'cb_id'}->($self),
				) : (),
				'name' => $hash_type,
				'valid_from' => $self->{'_random_valid_from'}->get->clone,
			);
			$i++;
		}
	}

	return @ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Random::HashType - Random hash type objects.

=head1 SYNOPSIS

 use Data::Random::HashType;

 my $obj = Data::Random::HashType->new(%params);
 my @hash_types = $obj->random;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Random::HashType->new(%params);

Constructor.

=over 8

=item * C<cb_id>

Callback to adding of id.

Default value is subroutine which returns C<$self->{'id'}++>.

=item * C<dt_start>

L<DateTime> object with start date for random valid_from date. Range is dt_start
and actual date.

Default value is January 1. year ago.

=item * C<id>

Minimal id for adding. Only if C<mode_id> is set to 1.

Default value is 1.

=item * C<mode_id>

Boolean value if we are generating id in hash type object.

Default value is 0.

=item * C<num_generated>

Number of generated hash types.

Default value is 1.

=item * C<possible_hash_types>

Possible hash type names for result.

Default value is list (SHA-256 SHA-384 SHA-512).

=back

Returns instance of object.

=head2 C<random>

 my @hash_types = $obj->random;

Get random hash type object.

Returns instance of L<Data::HashType>.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'dt_start' is required.
                 Parameter 'dt_start' must be a 'DateTime' object.
                         Value: %s
                         Reference: %s
                 Parameter 'mode_id' must be a bool (0/1).
                         Value: %s
                 Parameter 'num_generated' must be greater than %s.
                         Value: %s
                 Parameter 'num_generated' is required.
         Parameter 'possible_hash_types' must be a reference to array.
         Parameter 'possible_hash_types' must contain at least one hash type name.

=head1 EXAMPLE

=for comment filename=random_hash_type.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::Random::HashType;

 my $obj = Data::Random::HashType->new(
         'mode_id' => 1,
         'num_generated' => 2,
 );

 my @hash_types = $obj->random;

 # Dump hash types to out.
 p @hash_types;

 # Output like:
 # [
 #     [0] Data::HashType  {
 #             parents: Mo::Object
 #             public methods (6):
 #                 BUILD
 #                 Error::Pure:
 #                     err
 #                 Mo::utils:
 #                     check_isa, check_length, check_number, check_required
 #             private methods (0)
 #             internals: {
 #                 id           1,
 #                 name         "SHA-384",
 #                 valid_from   2023-03-17T00:00:00 (DateTime)
 #             }
 #         },
 #     [1] Data::HashType  {
 #             parents: Mo::Object
 #             public methods (6):
 #                 BUILD
 #                 Error::Pure:
 #                     err
 #                 Mo::utils:
 #                     check_isa, check_length, check_number, check_required
 #             private methods (0)
 #             internals: {
 #                 id           2,
 #                 name         "SHA-256",
 #                 valid_from   2023-01-27T00:00:00 (DateTime)
 #             }
 #         }
 # ]

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::HashType>,
L<DateTime>,
L<Error::Pure>,
L<Mo::utils>,
L<Random::Day>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Random-HashType>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
