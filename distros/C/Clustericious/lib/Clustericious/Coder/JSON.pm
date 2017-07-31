package Clustericious::Coder::JSON;

use strict;
use warnings;
use JSON::MaybeXS ();
use 5.010;

# ABSTRACT: JSON encoder for AutodataHandler
our $VERSION = '1.26'; # VERSION

sub coder
{
  my $json = JSON::MaybeXS->new
    ->allow_nonref
    ->allow_blessed
    ->convert_blessed;

  my %coder = (
    type   => 'application/json',
    format => 'json',
    encode => sub { $json->encode($_[0]) },
    decode => sub { $json->decode($_[0]) },
  );
  
  \%coder;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Coder::JSON - JSON encoder for AutodataHandler

=head1 VERSION

version 1.26

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
