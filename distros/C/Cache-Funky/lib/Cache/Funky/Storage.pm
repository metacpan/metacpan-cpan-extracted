package Cache::Funky::Storage;

use strict;
use warnings;
use Carp;
use base qw( Class::Accessor::Fast );

sub get    { croak "You need function by get()" }
sub set    { croak "You need function by set()" }
sub delete { croak "You need function by delete()" }

1;

=head1 NAME

Cache::Funky::Storage - Base Class for Cache::Funky::Storage::*

=head1 SYNOPSIS

    package Cache::Funky::Storage::MyStorage;

    use base qw( Cache::Funky::Storage );

=head1 DESCRIPTION

When you create Storage class, use base this module.

=head1 How to write Storage Class.

You must have get ,set ,delete methods for your storage module. Read L<Cache::Funky::Storage::Simple> then you will get idea.

=head1 METHODS

=head2 get( $key [ ,$id ] )

=head2 set( $key, $value [, $id ] )

=head2 delete( $key [ , $id ] )

=head1 SEE ALSO

L<Cache::Funky::Storage::Simple>

=head1 AUTHOR

Masahiro Funakoshi <masap@cpan.org>

=cut
