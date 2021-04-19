package Book::Bilingual::Dline;
# ABSTRACT: A dual language line
use Mojo::Base -base;
use Carp;

has 'class';
has 'str';

sub new {       ## ({class:STRING,str:STRING}) :> Dline
    @_ > 1
        ? $_[0]->SUPER::new($_[1])
        : $_[0]->SUPER::new({ class => '', str => '' })
}
sub to_html {   ## () :> HTML
    my ($self) = @_;
    return '<div class="'.$self->class.'">'.$self->str.'</div>';
}

1;
