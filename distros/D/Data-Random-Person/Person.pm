package Data::Random::Person;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Data::Person;
use Error::Pure qw(err);
use List::Util 1.33 qw(none);
use Mo::utils 0.06 qw(check_bool);
use Mock::Person::CZ qw(name);
use Text::Unidecode;

our $VERSION = 0.02;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Domain.
	$self->{'domain'} = 'example.com';

	# Id.
	$self->{'id'} = 1;
	$self->{'cb_id'} = sub {
		return $self->{'id'}++;
	};

	# Name callback.
	$self->{'cb_name'} = sub {
		return name();
	};

	# Add id or not.
	$self->{'mode_id'} = 0;

	# Number of users.
	$self->{'num_people'} = 10;

	# Process parameters.
	set_params($self, @params);

	check_bool($self, 'mode_id');

	# Check domain.
	if ($self->{'domain'} !~ m/^[a-zA-Z0-9\-\.]+$/ms) {
		err "Parameter 'domain' is not valid.";
	}

	return $self;
}

sub random {
	my $self = shift;

	my @data;
	foreach my $i (1 .. $self->{'num_people'}) {
		my $ok = 1;
		while ($ok) {
			my $people = $self->{'cb_name'}->($self);
			my $email = $self->_name_to_email($people);
			if (none { $_->email eq $email } @data) {
				my $id;
				if ($self->{'mode_id'}) {
					$id = $self->{'cb_id'}->($self);
				}
				push @data, Data::Person->new(
					'email' => $email,
					defined $id ? ('id' => $id) : (),
					'name' => $people,
				);
				$ok = 0;
			} else {
				print "Fail\n";
			}
		}
	}

	return @data;
}

sub _name_to_email {
	my ($self, $name) = @_;

	my $email = unidecode(lc($name));
	$email =~ s/\s+/\./g;
	$email .= '@'.$self->{'domain'};

	return $email;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::Random::Person - Random person objects.

=head1 SYNOPSIS

 use Data::Random::Person;

 my $obj = Data::Random::Person->new(%params);
 my @people = $obj->random;

=head1 METHODS

=head2 C<new>

 my $obj = Data::Random::Person->new(%params);

Constructor.

=over 8

=item * C<cb_id>

Callback to adding of id.

Default value is subroutine which returns C<$self->{'id'}++>.

=item * C<cb_name>

Callback to create person name.

Default value is subroutine which returns C<Mock::Person::CZ::name()>.

=item * C<domain>

Domain for email.

Default value is 'example.com'.

=item * C<id>

Minimal id for adding. Only if C<mode_id> is set to 1.

Default value is 1.

=item * C<mode_id>

Boolean value if we are generating id in hash type object.

Default value is 0.

=item * C<num_people>

Number of generated person records.

Default value is 10.

=back

Returns instance of object.

=head2 C<random>

 my @people = $obj->random;

Get random person records.

Returns instance of L<Data::Person>.

=head1 ERRORS

 new():
         From Mo::utils::check_bool():
                 Parameter 'mode_id' must be a bool (0/1).
                         Value: %s
         Parameter 'domain' is not valid.

=head1 EXAMPLE

=for comment filename=random_person.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::Random::Person;

 my $obj = Data::Random::Person->new(
         'mode_id' => 1,
         'num_people' => 2,
 );

 my @people = $obj->random;

 # Dump person records to out.
 p @people;

 # Output like:
 # [
 #     [0] Data::Person  {
 #             parents: Mo::Object
 #             public methods (6):
 #                 BUILD
 #                 Mo::utils:
 #                     check_length, check_number_id, check_strings
 #                 Mo::utils::Email:
 #                     check_email
 #                 Readonly:
 #                     Readonly
 #             private methods (0)
 #             internals: {
 #                 email   "jiri.sykora@example.com",
 #                 id      1,
 #                 name    "Jiří Sýkora"
 #             }
 #         },
 #     [1] Data::Person  {
 #             parents: Mo::Object
 #             public methods (6):
 #                 BUILD
 #                 Mo::utils:
 #                     check_length, check_number_id, check_strings
 #                 Mo::utils::Email:
 #                     check_email
 #                 Readonly:
 #                     Readonly
 #             private methods (0)
 #             internals: {
 #                 email   "bedrich.pavel.stepanek@example.com",
 #                 id      2,
 #                 name    "Bedřich Pavel Štěpánek"
 #             }
 #         }
 # ]

=head1 DEPENDENCIES

L<Class::Utils>,
L<Data::Person>,
L<Error::Pure>,
L<List::Util>,
L<Mo::utils>,
L<Mock::Person::CZ>,
L<Text::Unidecode>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-Random-Person>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
