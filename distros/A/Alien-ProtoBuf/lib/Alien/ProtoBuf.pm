package Alien::ProtoBuf;
# ABSTRACT: find Google ProtoBuf library

use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.05'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::ProtoBuf - find Google ProtoBuf library

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Alien::ProtoBuf;

    my $cflags = Alien::ProtoBuf->cflags;
    my $libs = Alien::ProtoBuf->libs;

    # use $cflags and $libs to compile a program using protocol buffers

=head1 AUTHOR

Mattia Barbon <mattia@barbon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mattia Barbon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
