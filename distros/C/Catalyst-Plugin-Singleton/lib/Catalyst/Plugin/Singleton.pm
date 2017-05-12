package Catalyst::Plugin::Singleton;

use strict;
use Scalar::Util;
use MRO::Compat;

our $VERSION = '0.2';

*context = \&instance;

sub instance {
    my $class = shift;

    no strict 'refs';
    return ${"$class\::_instance"};
}

sub prepare {
    my $class   = shift;
    my $context = $class->next::method(@_);

    {
        no strict 'refs';
        Scalar::Util::weaken( ${"$class\::_instance"} = $context );
    }

    return $context;
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Singleton - DEPRECATED - Singleton to context

=head1 SYNOPSIS

    use Catalyst qw[Singleton];

    # Retrieve a instance of context
    my $c = MyApp->instance;
    my $c = MyApp->context;


=head1 DESCRIPTION

DEPRECATED - Singleton accessors to context.

DO NOT USE IN NEW CODE!

=head1 METHODS

=over 4

=item context

alias for instance 

=item instance

Returns the current instance of the context object.

=back 

=head1 OVERRIDES

=over 4

=item prepare

=back

=head1 SEE ALSO

L<Catalyst>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify 
it under the same terms as perl itself.

=cut
