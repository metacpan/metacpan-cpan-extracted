package Catmandu::Validator::MARC;
use Catmandu::Sane;
use Catmandu::Util qw(:io :is :check);
use MARC::Schema;
use Moo;

our $VERSION = '1.251';

with qw(Catmandu::Validator);

has schema => ( is => 'ro' );
has ignore_unknown_fields => ( is => 'ro' );
has ignore_unknown_subfields => ( is => 'ro' );

has options => (
    is => 'ro',
    init_arg => undef,
    builder => sub {
        return {
            ignore_unknown_fields    => $_[0]->ignore_unknown_fields,
            ignore_unknown_subfields => $_[0]->ignore_unknown_subfields,
        }
    },
);

sub BUILD {
    my ($self, $args) = @_;
    if (defined $self->schema) {
        unless (is_instance($self->schema, 'MARC::Schema')) {
            if (is_string($self->schema)) {
                $self->{schema} = MARC::Schema->new({file => $self->schema});
            }
        }
    } else {
        $self->{schema} = MARC::Schema->new();
    }
}

sub validate_data {
    my ($self, $record) = @_;

    my @errors = $self->schema->check($record, %{$self->options});

    return @errors ? \@errors : undef;
}

1;
__END__

=head1 NAME

Catmandu::Validator::MARC - Validate MARC records against a MARC21 Schema

=head1 SYNOPSIS

In Perl code:

    use Catmandu::Validator::MARC;
    Catmandu::Validator::MARC;
    use DDP;
        
    # load default MARC schema
    my $validator = Catmandu::Validator::MARC->new();
    
    # ... or load custom MARC schema
    my $validator = Catmandu::Validator::MARC->new( schema => 'schema.json' );

    my $importer = Catmandu::Importer::MARC->new(
        file => 't/camel.mrc',
        type => "ISO"
    );

    $importer->each( sub {
        my $record = shift;
        unless($validator->validate($record)){
            p $_ for @{$validator->last_errors()};
        }
    });

In Catmandu Fix language:

    # reject all items not conforming to the default MARC schema
    select valid(., MARC)
    # reject all items not conforming to a custom MARC schema
    select valid(., MARC, schema: 'schema.json')


=head1 DESCRIPTION

This L<Catmandu::Validator> can be used to check MARC records against an MARC21 schema. For more information see L<MARC::Schema> and L<"MARC21 structure in JSON"|https://pkiraly.github.io/2018/01/28/marc21-in-json/>.

See also L<Catmandu::Fix::validate>, and L<Catmandu::Fix::Condition::valid> for usage of validators in Catmandu Fix language.

=head1 CONFIGURATION

=over

=item schema

MARC Schema given as filename (JSON) or instance of L<MARC::Schema>.

=item ignore_unknown_fields

Don't report fields not included in the schema.

=item ignore_unknown_subfields

Don't report subfields not included in the schema.

=back

=cut
