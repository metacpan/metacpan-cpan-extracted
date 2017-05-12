package Bot::BasicBot::Pluggable::Store::Storable;
$Bot::BasicBot::Pluggable::Store::Storable::VERSION = '1.20';
use warnings;
use strict;
use Storable qw( nstore retrieve );
use File::Spec;
use File::Temp qw(tempfile);

use base qw( Bot::BasicBot::Pluggable::Store );

sub init {
    my $self = shift;
    if ( !$self->{dir} ) {
        $self->{dir} = File::Spec->curdir();
    }
}

sub save {
    my $self      = shift;
    my $namespace = shift;
    my @modules   = $namespace ? ($namespace) : keys( %{ $self->{store} } );

    for my $name (@modules) {
        my $filename = File::Spec->catfile( $self->{dir}, $name . ".storable" );
        my ( $fh, $tempfile ) = tempfile( DIR => $self->{dir}, UNLINK => 0 );
        nstore( $self->{store}{$name}, $tempfile )
          or die "Cannot save to $tempfile\n";
        rename $tempfile, $filename
          or die "Cannot create $filename: $!\n";
    }
}

sub load {
    my $self = shift;
    for my $file ( glob File::Spec->catfile( $self->{dir}, '*.storable' ) ) {
        my (undef, undef, $name) = map {File::Spec->splitpath($_)} $file =~ /^(.*?)\.storable$/;
        $self->{store}{$name} = retrieve($file);
    }
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Store::Storable - use Storable to provide a storage backend

=head1 VERSION

version 1.20

=head1 SYNOPSIS

  my $store = Bot::BasicBot::Pluggable::Store::Storable->new(
    dir => "directory"
  );

  $store->set( "namespace", "key", "value" );
  
=head1 DESCRIPTION

This is a L<Bot::BasicBot::Pluggable::Store> that uses Storable to store
the values set by modules.

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
