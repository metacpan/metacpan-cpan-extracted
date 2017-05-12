package Clone::AsUTF8Bytes;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw( clone_as_utf8_bytes );

$VERSION = '0.34';

__PACKAGE__->bootstrap($VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Clone::AsUTF8Bytes - recursively copy Perl data converting to UTF-8 bytes

=head1 SYNOPSIS

  package Foo;
  use parent 'Clone::AsUTF8Bytes';

  package main;
  my $original = Foo->new;
  $copy = $original->clone_as_utf8_bytes;
  
  # or

  use Clone::AsUTF8Bytes qw(clone_as_utf8_bytes);
  
  $a = { 'M\x{f8}\x{f8}se' => "\x{1F44D}" };
  $b = [ "L\x{e9}on', "\N{SNOWMAN}" ];
  $c = Foo->new;

  $d = clone_as_utf8_bytes($a);
  $e = clone_as_utf8_bytes($b);
  $f = clone_as_utf8_bytes($c);

=head1 DESCRIPTION

This module provides a clone_as_utf8_bytes() method which makes recursive copies
of nested hash, array, scalar and reference types, including tied variables and
objects, modifying the characters in the strings as it does so into UTF-8 bytes.
For example the Perl string C<L\x{e9}on> in the data strucutre will be converted
to the string C<L\x{c3}\x{a9}on>.

clone_as_ut8_bytes() takes a scalar argument and duplicates and modifies it. To
duplicate lists, arrays or hashes, pass them in by reference. e.g.
    
    my $copy = clone (\@array);

    # or

    my %copy = %{ clone (\%hash) };

=head1 SEE ALSO

This module is essentially the L<Clone> module slightly altered to do the
utf-8 byte conversion.

=head1 COPYRIGHT

Copyright 2013 OmniTI.  All Rights Reserved.

Majority of code in this module copyright 2001-2012 Ray Finch. All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Coversion from Clone to Clone::AsUTF8Bytes was performed by Mark Fowler.
C<< <mark@twoshortplanks.com> >>.

Original Clone module - which makes up the overall majority of the module - was
written by Ray Finch C<< <rdf@cpan.org> >>.  Breno G. de Oliveira C<<
<garu@cpan.org> >> and Florian Ragwitz C<< <rafl@debian.org> >> performed
routine maintenance releases on the Clone module since 2012.

=cut
