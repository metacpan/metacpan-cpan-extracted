package Clustericious::Coder::YAML;

use strict;
use warnings;
use YAML::XS ();
use 5.010;

# ABSTRACT: YAML encoder for AutodataHandler
our $VERSION = '1.29'; # VERSION

sub coder
{
  my %coder = (
    type   => 'text/x-yaml',
    format => 'yml',
    encode => sub { YAML::XS::Dump($_[0]) },
    decode => sub { YAML::XS::Load($_[0]) },
  );
  
  \%coder;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Coder::YAML - YAML encoder for AutodataHandler

=head1 VERSION

version 1.29

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
