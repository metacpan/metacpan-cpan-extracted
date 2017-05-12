package Clustericious::Admin::Dump;

use strict;
use warnings;
use 5.010;
use Data::Dumper ();
use base qw( Exporter );

our @EXPORT_OK = qw( perl_dump );

our $VERSION = '1.09'; # VERSION

sub perl_dump ($)
{
  "#perl\n" .
  Data::Dumper
    ->new([$_[0]])
    ->Terse(1)
    ->Indent(0)
    ->Dump;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Admin::Dump

=head1 VERSION

version 1.09

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
