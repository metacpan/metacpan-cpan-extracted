#!/usr/bin/perl -w

$SIG{__WARN__} = sub { return if $_[0] =~ /^Pseudo-hashes are deprecated/ };

use Test::More tests => 6;
use strict;

BEGIN {
    use_ok 'public';
    use_ok 'private';
    use_ok 'fields';
}

# Test the example from the Class::Fields man page.

package Test::Autoload::Example;

use base qw(Class::Fields);
use public  qw(this that up down);
use private qw(_left _right);
use fields;

use vars qw($AUTOLOAD);
{
    no strict 'refs';

    sub AUTOLOAD {
        my $self = $_[0];
        my $class = ref $self;

        my($field) = $AUTOLOAD =~ /::([^:]+)$/;

        return if $field eq 'DESTROY';

        # If its a public field, set up a named closure as its
        # data accessor.
        if ( $self->is_public($field) ) {
            *{$class."::$field"} = sub {
                my($self) = shift;
                if (@_) {
                    $self->{$field} = shift;
                }
                return $self->{$field};
            };
            goto &{$class."::$field"};
        } else {
            die "'$field' is not a public data member of '$class'";
        }
    }
}

my $obj = fields::new(__PACKAGE__);
$obj->this(42);
::is( $obj->this,   42 );
::is( $obj->{this}, 42 );

eval {
    $obj->_left;
};
::like( $@, q[/^'_left' is not a public data member of 'Test::Autoload::Example'/] );
