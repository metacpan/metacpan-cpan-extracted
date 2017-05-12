#line 1
package Class::Accessor::Fast;
use base 'Class::Accessor';
use strict;
$Class::Accessor::Fast::VERSION = '0.30';

#line 32

sub make_accessor {
    my($class, $field) = @_;

    return sub {
        return $_[0]->{$field} unless @_ > 1;
        my $self = shift;
        $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
    };
}


sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        return $_[0]->{$field} unless @_ > 1;
        my $self = shift;
        my $caller = caller;
        $self->_croak("'$caller' cannot alter the value of '$field' on objects of class '$class'");
    };
}


sub make_wo_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        unless (@_) {
            my $caller = caller;
            $self->_croak("'$caller' cannot access the value of '$field' on objects of class '$class'");
        }
        else {
            return $self->{$field} = (@_ == 1 ? $_[0] : [@_]);
        }
    };
}


#line 94

1;
