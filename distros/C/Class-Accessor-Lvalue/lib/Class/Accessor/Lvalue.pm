use strict;
package Class::Accessor::Lvalue;
use base qw( Class::Accessor );
use Scalar::Util qw(weaken);
use Want qw( want );
our $VERSION = '0.11';

sub make_accessor {
    my ($class, $field) = @_;

    return sub :lvalue {
        tie my $tie, "Class::Accessor::Lvalue::Tied" => $field, @_;
        $tie;
    };
}

sub make_ro_accessor {
    my ($class, $field) = @_;

    return sub :lvalue {
        if (want 'LVALUE') {
            my $caller = caller;
            require Carp;
            Carp::croak("'$caller' cannot alter the value of '$field' on ".
                          "objects of class '$class'");
        }
        tie my $tie, "Class::Accessor::Lvalue::Tied" => $field, @_;
        $tie;
    };
}

sub make_wo_accessor {
    my($class, $field) = @_;

    return sub :lvalue {
        unless (want 'LVALUE') {
            my $caller = caller;
            require Carp;
            Carp::croak("'$caller' cannot access the value of '$field' on ".
                          "objects of class '$class'");
        }
        tie my $tie, "Class::Accessor::Lvalue::Tied" => $field, @_;
        $tie;
    };
}


package Class::Accessor::Lvalue::Tied;
sub TIESCALAR { shift; bless [@_] }

sub STORE {
    my ($field, $self) = @{ shift() };
    $self->set( $field, @_ );
}

sub FETCH {
    my ($field, $self) = @{ shift() };
    $self->get( $field );
}

1;
__END__

=head1 NAME

Class::Accessor::Lvalue - create Lvalue accessors

=head1 SYNOPSIS

 package Foo;
 use base qw( Class::Accessor::Lvalue );
 __PACKAGE__->mk_accessors(qw( bar ))

 my $foo = Foo->new;
 $foo->bar = 42;
 print $foo->bar; # prints 42

=head1 DESCRIPTION

This module subclasses L<Class::Accessor> in order to provide lvalue
accessor makers.

=head1 CAVEATS

=over

=item

Though L<Class::Accessor> mutators allows for the setting of multiple
values to an attribute, the mutators that this module creates handle
single scalar values only.  This should not be too much of a
hinderance as you can still explictly use an anonymous array.

=item

Due to the hoops we have to jump through to preserve the
Class::Accessor ->get and ->set behaviour this module is potentially
slow.  Should you not need the flexibility granted by the ->get and
->set methods, it's highly reccomended that you use
L<Class::Accessor::Lvalue::Fast> which is simpler and much faster.

=back

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net> with many thanks to Yuval
Kogman for helping with the groovy lvalue tie magic used in the main
class.

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::Accessor>, L<Class::Accessor::Lvalue::Fast>

=cut
