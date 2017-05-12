package DBIx::Mint::Schema::Class;

use Carp;
use Moo;

has class            => ( is => 'ro', required  => 1 );
has table            => ( is => 'ro', required  => 1 );
has pk               => ( is => 'ro', required  => 1 );
has fields_not_in_db => ( is => 'rw', default   => sub { [] });
has auto_pk          => ( is => 'ro', predicate => 1 );

sub BUILDARGS {
    my ($class, %args) = @_;
    $args{pk} = [ $args{pk} ] unless ref $args{pk};
    return \%args;
}

sub BUILD {
    my $self = shift;
    croak "Only a single primary key is supported if you use auto-incrementing values"
        if $self->has_auto_pk && @{ $self->pk } > 1;
    $self->not_in_db('_name');
}

sub not_in_db {
    my $self = shift;
    push @{ $self->fields_not_in_db }, @_;
}

1;
