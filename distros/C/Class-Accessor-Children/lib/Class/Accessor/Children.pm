package Class::Accessor::Children;
use base qw( Class::Accessor );
use Carp;
use vars qw( $VERSION );
$VERSION = '0.02';

sub mk_child_accessors {
    _mk_child_classes( mk_accessors => @_ );
}
sub mk_child_ro_accessors {
    _mk_child_classes( mk_ro_accessors => @_ );
}
sub mk_child_wo_accessors {
    _mk_child_classes( mk_wo_accessors => @_ );
}

sub _mk_child_classes {
    my $method  = shift;
    my $base    = shift;
    Carp::croak 'Odd number arguments' if scalar @_ % 2;
    while ( scalar @_ ) {
        my $name = shift;
        my $list = shift;
        Carp::croak 'Invalid child class name' if ref $name;
        $list = [ grep {$_ ne ''} split( /\s+/, $list )] unless ref $list;
        my $child = ( $name ne '' ) ? $base.'::'.$name : $base;
        if ( ! $child->isa( __PACKAGE__ )) {
            no strict 'refs';
            push( @{$child.'::ISA'}, __PACKAGE__ );
        }
        $child->$method( @$list );
    }
}

=head1 NAME

Class::Accessor::Children - Automated child-class/accessor generation

=head1 SYNOPSIS

BEFORE (WITHOUT THIS)

    package MyClass::Foo;
    use base qw( Class:Accessor );
    __PACKAGE__->mk_ro_accessors(qw( jacob michael joshua ethan ));

    package MyClass::Bar;
    use base qw( Class:Accessor );
    __PACKAGE__->mk_ro_accessors(qw( emily emma madison isabella ));

    package MyClass::Baz;
    use base qw( Class:Accessor );
    __PACKAGE__->mk_ro_accessors(qw( haruka haruto miyu yuto ));

AFTER (WITH THIS)

    package MyClass;
    use base qw( Class::Accessor::Children );
    __PACKAGE__->mk_child_ro_accessors(
        Foo => [qw( jacob michael joshua ethan )],
        Bar => [qw( emily emma madison isabella )],
        Baz => [qw( haruka haruto miyu yuto )],
    );

=head1 DESCRIPTION

This module automagically generates child classes 
which have accessor/mutator methods.

This module inherits C<Class::Accessor> to make accessors.

=head1 METHODS

This module provides the following methods in addition to all methods 
provided by C<Class::Accessor>.

=head2 mk_child_accessors

    MyClass->mk_child_accessors( Foo => \@fields, ... );

This generates a child class named C<MyClass::Foo> 
which have accessor/mutator methods each named in C<\@fields>.

=head2 mk_child_ro_accessors

    MyClass->mk_child_ro_accessors( Bar => \@fields, ... );

This generates a child class named C<MyClass::Bar>
which have read-only accessors (ie. true accessors).

=head2 mk_child_wo_accessors

    MyClass->mk_child_wo_accessors( Baz => \@fields, ... );

This generates a child class named C<MyClass::Baz>
which have write-only accessor (ie. mutators).

=head1 SEE ALSO

L<Class::Accessor>

=head1 AUTHOR

Yusuke Kawasaki L<http://www.kawa.net/>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 Yusuke Kawasaki. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
1;
