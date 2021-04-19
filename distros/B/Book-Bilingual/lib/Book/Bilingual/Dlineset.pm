package Book::Bilingual::Dlineset;
# ABSTRACT: A set of dual language lines
use Mojo::Base -base;
use Carp;

has 'set';      # Arrayref of Dlines

sub new { $_[0]->SUPER::new({ set => [] }) }
sub dline_count {
    my ($self) = @_;
    return scalar @{$self->{set}};
}
sub dline_at {        ## ($idx :>Int) :> Dline
    my ($self, $idx) = @_;

    return $self->{set}[$idx];
}
sub target {    ## () :> Dline
    my ($self, $idx) = @_;

    return $self->{set}[-1];
}
sub push {      ## ($d:Dline) :> $Dlineset
    my ($self,$d) = @_;

    croak 'Not a Book::Bilingual::Dline'
        unless ref($d) eq 'Book::Bilingual::Dline';

    push @{$self->{set}}, $d;

    return $self;
}

1;
