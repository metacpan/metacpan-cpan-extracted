package Apache::SiteConfig::Root;
use Moose;
use Apache::SiteConfig::Section;
use Apache::SiteConfig::Directive;
extends 'Apache::SiteConfig::Statement';

has statements => ( is => 'rw' , isa => 'ArrayRef' , default => sub { [ ] } );

sub add_directive {
    my ($self,$name,$values) = @_;
    $values = ref($values) ? $values : [ $values ];
    my $dt = Apache::SiteConfig::Directive->new( 
        name => $name,
        values => $values,
        parent => $self,
    );
    push @{$self->statements} , $dt;
    return $dt;
}

sub add_section {
    my ($self,$name,$value) = @_;
    my $section = Apache::SiteConfig::Section->new( 
        name => $name, 
        value => $value,
        parent => $self,
    );
    push @{$self->statements} , $section;
    return $section;
}

sub to_string {
    my ($self) = @_;
    return join "\n",
        (map { $_->to_string } @{ $self->statements });
}


1;
