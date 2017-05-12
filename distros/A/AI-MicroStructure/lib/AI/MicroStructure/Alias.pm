package AI::MicroStructure::Alias;
use strict;
use warnings;
use Carp;

our $VERSION = '1.000';

sub init {
    my ( $self, $alias ) = @_;
    my $class = caller(0);

    eval "require AI::MicroStructure::$alias;";
    croak "Aliased structure AI::MicroStructure::$alias failed to load: $@"
        if $@;

    no strict 'refs';
    no warnings;

    # copy almost everything over from the original
    for my $k ( grep { ! /^(?:Theme|meta|import)$/ }
        keys %{"AI::MicroStructure::$alias\::"} )
    {
        *{"$class\::$k"} = *{"AI::MicroStructure::$alias\::$k"};
    }

    # local things
    ${"$class\::Theme"} = ( split /::/, $class )[-1];
    ${"$class\::meta"}  = $class->new();
    *{"$class\::import"} = sub {
        my $callpkg = caller(0);
        my $structure   = ${"$class\::Theme"};
        my $meta    = $class->new();
        *{"$callpkg\::meta$structure"} = sub { $meta->name(@_) };
      };
}

1;

__END__

=head1 NAME

AI::MicroStructure::Alias - Alias one structure to another

=head1 SYNOPSIS

    package AI::MicroStructure::bonk;
    use AI::MicroStructure::Alias;
    our @ISA = qw( AI::MicroStructure::Alias );
    __PACKAGE__->init('batman');
    1;

    =head1 NAME
    
    AI::MicroStructure::bonk - The bonk structure
    
    =head1 DESCRIPTION
    
    This structure is just an alias of the C<batman> theme.

    =cut
    
    # no __DATA__ section required!

=head1 DESCRIPTION

C<AI::MicroStructure::Alias> is the base class for any structures that is
simply an alias of another structure.

=head1 METHOD

AI::MicroStructure::Alias defines a single method, C<init()> that
make aliases very easy to write (see the full example in L<SYNOPSIS>):

=over 4

=item init( $original )

C<init()> must be called when the subclass is loaded, so as to correctly
load and alias the original structure.

C<$original> is the name of the original structure we want to alias.

=back

=head1 AUTHOR

Philippe 'BooK' Bruhat, C<< <book@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Philippe 'BooK' Bruhat, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

