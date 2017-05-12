package Cache::Funky::Storage::Simple;

use strict;
use warnings;
use base qw( Cache::Funky::Storage );

my $_CACHE = {};

sub get {
    my $s   = shift;
    my $key = shift;
    my $id  = shift;

    return $id ? $_CACHE->{ $key }{ $id } : $_CACHE->{ $key };
}

sub set {
    my $s     = shift;
    my $key   = shift;
    my $value = shift;
    my $id    = shift;

    if( $id ) {
        $_CACHE->{ $key }{ $id } = $value;
    }
    else {
        $_CACHE->{$key} = $value;
    }
    return 1;
}

sub delete {
    my $s   = shift;
    my $key = shift;
    my $id  = shift;

    $id ? delete $_CACHE->{ $key }{ $id } : delete $_CACHE->{ $key };
}

1;

=head1 NAME

Cache::Funky::Storage::Simple - Simple storage class.

=head1 SYNOPSIS

    use Cache::Funky::Storage::Simple;

=head1 DESCRIPTION

This is not recommended to be used by your application. 

=head1 METHODS

=head2 get( $key , [ $id )

=head2 set( $key, $value , [ $id )

=head2 delete ( $key , [ $id )

=head1 AUTHOR

Masahiro Funakoshi <masap@cpan.org>

=cut
