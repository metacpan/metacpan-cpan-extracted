#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package App::Magpie::Constants;
# ABSTRACT: Various constants
$App::Magpie::Constants::VERSION = '2.010';
use Exporter::Lite;
use File::ShareDir qw{ dist_dir };
use Path::Tiny;
 
our @EXPORT_OK = qw{ $SHAREDIR };

our $SHAREDIR = -e path("dist.ini")
    ? path("share")
    : path( dist_dir("App-Magpie") );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Constants - Various constants

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This module provides some helper variables, to be used on various
occasions throughout the code. Available constants:

=over 4

=item * C<$SHAREDIR>

=back

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
