package Catmandu::Validator::PICA;
use Catmandu::Sane;
use Catmandu::Util qw(:io :is :check);
use PICA::Schema;
use Moo;

our $VERSION = '0.26';

with qw(Catmandu::Validator);

has schema => (
    is => 'ro',
    required => 1,
    trigger => sub {
        my ($self, $schema) = @_;
        unless (is_instance($schema, 'PICA::Schema')) {
            if (is_string($schema)) {
                $schema = read_json($schema);
            }
            $self->{schema} = PICA::Schema->new(check_hash_ref($schema));
        }
    }
);

has ignore_unknown_fields => ( is => 'ro' );
has ignore_unknown_subfields => ( is => 'ro' );
has ignore_subfield_order => ( is => 'ro' );

has options => (
    is => 'ro',
    init_arg => undef,
    builder => sub {
        return {
            ignore_unknown_fields    => $_[0]->ignore_unknown_fields,
            ignore_unknown_subfields => $_[0]->ignore_unknown_subfields,
            ignore_subfield_order    => $_[0]->ignore_subfield_order,
        }
    },
);

sub validate_data {
    my ($self, $record) = @_;

    my @errors = $self->schema->check($record, %{$self->options});

    return @errors ? \@errors : undef;
}

1;
__END__

=head1 NAME

Catmandu::Validator::PICA - Validate PICA+ records with an Avram Schema

=head1 SYNOPSIS

In Perl code:

    use Catmandu::Validator::PICA;
    use Catmandu qw(importer);

    my $validator = Catmandu::Validator::PICA->new( schema => 'schema.json' );

    importer('PICA', file => 'pica.xml')->each( sub {
        my $record = shift;
        unless($validator->validate($record)){
            say "$_" for @{$validator->last_errors()};
        }
    }});

In Catmandu Fix language:

    # reject all items not conforming to the schema
    select valid('', PICA, schema: 'schema.json')

=head1 DESCRIPTION

This L<Catmandu::Validator> can be used to check PICA+ records against an
L<Avram Schema language|https://format.gbv.de/schema/avram/specification>.

See also L<Catmandu::Fix::validate>, and L<Catmandu::Fix::Condition::valid> for
usage of validators in Catmandu Fix language.

=head1 CONFIGURATION

=over

=item schema

Avram Schema given as hash reference, filename (JSON), or instance of
L<PICA::Schema>.

=item ignore_unknown_fields

Don't report fields not included in the schema.

=item ignore_unknown_subfields

Don't report subfields not included in the schema.

=item ignore_subfield_order

Don't report subfields in wrong order.

=back

=cut
