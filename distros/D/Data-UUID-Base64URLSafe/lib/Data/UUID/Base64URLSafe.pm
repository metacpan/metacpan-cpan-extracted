package Data::UUID::Base64URLSafe;
use strict;
use warnings;
use MIME::Base64::URLSafe;
use base qw(Data::UUID);
our @EXPORT  = @{Data::UUID::EXPORT};
our $VERSION = '0.34';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    bless $self, $class;
    return $self;
}

sub create_b64_urlsafe {
    my $self = shift;
    return urlsafe_b64encode( $self->create );
}

sub create_from_name_b64_urlsafe {
    my $self = shift;
    return urlsafe_b64encode( $self->create_from_name(@_) );
}

sub to_b64_urlsafe {
    my $self = shift;
    my $uuid = shift;
    return urlsafe_b64encode($uuid);
}

sub from_b64_urlsafe {
    my $self = shift;
    my $uuid = shift;
    return urlsafe_b64decode($uuid);
}

1;

__END__

=head1 NAME

Data::UUID::Base64URLSafe - URL-safe UUIDs

=head1 SYNOPSIS

  use Data::UUID::Base64URLSafe;
  my $ug = Data::UUID::Base64URLSafe->new;
  my $uuid = $ug->create_b64_urlsafe;

=head1 DESCRIPTION

L<Data::UUID> creates wonderful Globally/Universally Unique
Identifiers (GUIDs/UUIDs). This module is a subclass of that
module which adds a method to get a URL-safe Base64-encoded
version of the UUID using L<MIME::Base64::URLSafe>. What that
means is that you can get a 22-character UUID string which
you can use safely in URLs.

=head1 METHODS

=head2 new

The constructor:

  my $ug = Data::UUID::Base64URLSafe->new;

=head2 create_b64_urlsafe

Create a URL-safe Base64-encoded UUID:

  my $uuid = $ug->create_b64_urlsafe;

=head2 create_from_name_b64_urlsafe

Creates a URL-safe Base64 encoded UUID with the namespace and data 
specified (See the L<Data::UUID> docs on create_from_name

=head2 from_b64_urlsafe

   my $uuid2 = $ug−>create_from_name_b64_urlsafe(<namespace>, <name>);


=head2 to_b64_urlsafe

Convert a binary UUID to a URL-safe Base64 encoded UUID

=head2 from_b64_urlsafe

Convert a Base 64-encoded URL-safe UUID to its canonical binary representation


=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

