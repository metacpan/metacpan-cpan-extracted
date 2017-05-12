package Acme::MetaSyntactic::Alias;
use strict;
use warnings;
use Carp;

our $VERSION = '1.000';

sub init {
    my ( $self, $alias ) = @_;
    my $class = caller(0);

    eval "require Acme::MetaSyntactic::$alias;";
    croak "Aliased theme Acme::MetaSyntactic::$alias failed to load: $@"
        if $@;

    no strict 'refs';
    no warnings;

    # copy almost everything over from the original
    for my $k ( grep { ! /^(?:Theme|meta|import)$/ }
        keys %{"Acme::MetaSyntactic::$alias\::"} )
    {
        *{"$class\::$k"} = *{"Acme::MetaSyntactic::$alias\::$k"};
    }

    # local things
    ${"$class\::Theme"} = ( split /::/, $class )[-1];
    ${"$class\::meta"}  = $class->new();
    *{"$class\::import"} = sub {
        my $callpkg = caller(0);
        my $theme   = ${"$class\::Theme"};
        my $meta    = $class->new();
        *{"$callpkg\::meta$theme"} = sub { $meta->name(@_) };
      };
}

1;

__END__

=head1 NAME

Acme::MetaSyntactic::Alias - Alias one theme to another

=head1 SYNOPSIS

    package Acme::MetaSyntactic::bonk;
    use Acme::MetaSyntactic::Alias;
    our @ISA = qw( Acme::MetaSyntactic::Alias );
    __PACKAGE__->init('batman');
    1;

    =head1 NAME
    
    Acme::MetaSyntactic::bonk - The bonk theme
    
    =head1 DESCRIPTION
    
    This theme is just an alias of the C<batman> theme.

    =cut
    
    # no __DATA__ section required!

=head1 DESCRIPTION

C<Acme::MetaSyntactic::Alias> is the base class for any themes that is
simply an alias of another theme.

=head1 METHOD

Acme::MetaSyntactic::Alias defines a single method, C<init()> that
make aliases very easy to write (see the full example in L<SYNOPSIS>):

=over 4

=item init( $original )

C<init()> must be called when the subclass is loaded, so as to correctly
load and alias the original theme.

C<$original> is the name of the original theme we want to alias.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

