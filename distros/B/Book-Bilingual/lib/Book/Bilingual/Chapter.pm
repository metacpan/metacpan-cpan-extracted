package Book::Bilingual::Chapter;
# ABSTRACT: A book chapter class
use Mojo::Base -base;
use Carp;

has 'number';
has 'title';
has 'body';

sub new { $_[0]->SUPER::new({ body => [] }) }
sub num_paragraphs {
    my ($self) = @_;

    return scalar @{$self->{body}};
}
sub dlineset_at { ## ($i) :> Dlineset
    my ($self,$i) = @_;
    return $self->number if $i == 0;
    return $self->title  if $i == 1;
    return $self->body->[$i-2];
}
sub dlineset_count {
    my ($self) = @_;

    return (defined $self->number ? 1 : 0)
           + (defined $self->title ? 1 : 0)
           + scalar @{$self->{body}};
}

1;
