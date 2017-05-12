package Clustericious::Coder::BSON;

use strict;
use warnings;
use BSON ();
use 5.010;

# ABSTRACT: BSON encoder for AutodataHandler
our $VERSION = '0.01'; # VERSION


sub coder
{
  my %coder = (
    type   => 'application/bson',
    format => 'bson',
    encode => sub { BSON::encode($_[0]) },
    decode => sub { BSON::decode($_[0]) },
  );
  
  \%coder;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Coder::BSON - BSON encoder for AutodataHandler

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 % cpanm Clustericious::Coder::BSON

=head1 DESCRIPTION

Simply install this module and any L<Clustericious> 1.12 applications
will automatically handle L<BSON> encoded requests and responses.

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
