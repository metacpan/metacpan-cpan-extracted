package CPAN::Local::Distribution::Role::MD5;
{
  $CPAN::Local::Distribution::Role::MD5::VERSION = '0.010';
}

# ABSTRACT: Calculate checksums for a distribution

use strict;
use warnings;
use Digest::MD5;
use Moose::Role;

has md5 => ( is => 'ro', isa => 'Str', lazy_build => 1 );

sub _build_md5
{
    my $self = shift;
    my $fh = file($self->filename)->open or die $!;
    binmode $fh;
    return Digest::MD5->new->addfile($fh)->hexdigest;
}

1;


__END__
=pod

=head1 NAME

CPAN::Local::Distribution::Role::MD5 - Calculate checksums for a distribution

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 md5

Checksum for the distribution archive cacluclated using L<Digest::MD5>.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

