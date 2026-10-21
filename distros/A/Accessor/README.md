# NAME

Accessor - base class for accessor-pattern classes

# USAGE

    my $obj = new Hash(myattr => 1);
    
    say $obj->myattr();   # get myattr, say 1
    say $obj->myattr(0);  # set myattr to 0
    
    package Hash;
    
    use base 'Accessor';
    
    sub new {
        my $class = shift;
        return bless {@_}, $class;
    }

# VERSION

0.4

# AUTHOR

Developed by Ivan Trunaev

Contacts <ivan@trunaev.ru>
