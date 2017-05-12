package CURRENT;

use strict;
use vars qw( $VERSION );
use Carp;

$VERSION = '0.01';

sub AUTOLOAD {
    my ($self) = @_;

    my $caller_class = caller;
    my ($wanted_method) = $CURRENT::AUTOLOAD =~ m{.*::(.*)}g;

    my $object_method = $caller_class->can($wanted_method);
    goto $object_method if $object_method;

    if ( my $autoload = $caller_class->can('AUTOLOAD') ) {
        require B;
        my $autoload_class = B::svref_2object($autoload)->GV->STASH->NAME;

        no strict 'refs';
        ${"${autoload_class}::AUTOLOAD"} = "${caller_class}::$wanted_method";

        goto $autoload;
    }

    croak(
        qq{Can't locate object method "$wanted_method"},
        qq{ via package "$caller_class"},
    );
}

1;
__END__

=head1 NAME

CURRENT - Alias of current class

=head1 SYNOPSIS

    package LONG::LONG::LONG::LONG::Class;

    require CURRENT;

    sub _my_method {}

    $self->CURRENT::_my_method();
    # same as
    $self->LONG::LONG::LONG::LONG::Class::_my_method();

=head1 DESCRIPTION

CURRENT.pm adds class C<CURRENT>. When a method C<m> is called as
C<< $self->CURRENT::m >>, C<__PACKAGE__::m> is called.

Note that C<CURRENT> only supports calling method.

This helps calling a local method in a long name class.

CURRENT.pm supports C<AUTOLOAD>, also.

=head1 AUTHOR

Yuji Tamashiro, E<lt>yuji@tamashiro.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Yuji Tamashiro

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
