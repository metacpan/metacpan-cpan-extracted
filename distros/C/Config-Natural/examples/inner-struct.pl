#!/usr/bin/perl -w
# 
# This simple example will show you the inner structure of 
# the data in the object. It is the same as the one used in 
# HTML::Template. 
# 
use strict;
use Config::Natural;
use Data::Dumper;

$|=1;

my $t = new Config::Natural \*DATA;
print Dumper($t->{'param'});


__END__

foo = machin

bar = chose


element {
    name = root
    attr = attribut specifique a l'item
    
    node {
        name = node one
        attr = attribut specifique au noeud
        
        leaf {
            name = leaf
            attr = attribut specifique a la feuille
        }
    }
    
    iterm {
        name = intermedaire
    }
    
    node {
        name = second node
    }
    
    tail = fin de non recevoir
}

