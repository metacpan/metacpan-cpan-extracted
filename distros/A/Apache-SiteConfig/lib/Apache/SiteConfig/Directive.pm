package Apache::SiteConfig::Directive;
use Moose;
use Apache::SiteConfig::Statement;

extends 'Apache::SiteConfig::Statement';

has name => ( is => 'rw' );
has values => ( is => 'rw' , isa => 'ArrayRef' , default => sub { [ ] } );

sub to_string {
    my ($self) = @_;
    my $indent = ' ' x 4 x $self->get_level;
    return $indent . join(' ' , $self->name, @{ $self->values } );
}

1;
