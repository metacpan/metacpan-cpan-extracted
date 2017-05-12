#line 1
package Class::Accessor::Fast;
use base 'Class::Accessor';
use strict;
$Class::Accessor::Fast::VERSION = '0.31';

#line 32

sub make_accessor {
    my($class, $field) = @_;

    return sub {
        return $_[0]->{$field} if @_ == 1;
        return $_[0]->{$field} = $_[1] if @_ == 2;
        return (shift)->{$field} = \@_;
    };
}


sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        return $_[0]->{$field} if @_ == 1;
        my $caller = caller;
        $_[0]->_croak("'$caller' cannot alter the value of '$field' on objects of class '$class'");
    };
}


sub make_wo_accessor {
    my($class, $field) = @_;

    return sub {
        if (@_ == 1) {
            my $caller = caller;
            $_[0]->_croak("'$caller' cannot access the value of '$field' on objects of class '$class'");
        }
        else {
            return $_[0]->{$field} = $_[1] if @_ == 2;
            return (shift)->{$field} = \@_;
        }
    };
}


#line 92

1;
