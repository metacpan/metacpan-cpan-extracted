package AnyEvent::Net::Amazon::S3::Request;

# ABSTRACT: Base class for request objects
our $VERSION = 'v0.04.0.80'; # VERSION

use strict;
use warnings;

use Module::AnyEvent::Helper::Filter -as => __PACKAGE__,
        -target => substr(__PACKAGE__, 10),
        -transformer => 'Net::Amazon::S3';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Amazon::S3::Request - Base class for request objects

=head1 VERSION

version v0.04.0.80

=head1 SYNOPSIS

  # do not instantiate directly

=head1 DESCRIPTION

This module is a base class for all the AnyEvent::Net::Amazon::S3::Request::* classes
and the same as L<Net::Amazon::S3::Request>, except for its name.

=head1 AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
