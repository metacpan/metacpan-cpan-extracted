package Acme::Goto::Line;

use 5.008;
use strict;
use warnings;
sub gotol;
BEGIN {
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01;
@ISA         = qw (Exporter);
#Give a hoot don't pollute, do not export more than needed by default
@EXPORT      = qw (gotol);
@EXPORT_OK   = qw (gotol);
%EXPORT_TAGS = ();


require XSLoader;
XSLoader::load('Acme::Goto::Line', $VERSION);
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::Goto::Line - Perl extension for extending goto with line number goto

=head1 SYNOPSIS

  use Acme::Goto::Line;
  print "This is a loop\n";
  goto(2);

=head1 ABSTRACT

  Perl has long lacked a vital feature present in even basic, goto a line!
  After some thinking and then hacking at the Nordic Perl Workshop in 
  Copenhagen 2004, this is the result

=head1 DESCRIPTION

How hard can it be? You do goto, then a line number! It jumps to that line.

You cannot currently goto a place inside a subroutine. Adn you cannot currently goto out of a subroutine running in anything that is used or required. This is because perl removes all that information for us. The goblins are working on a way to fix this.

=head2 EXPORT

It overrides your global goto!



=head1 SEE ALSO

Why goto is harmful: http://www.acm.org/classics/oct95/

=head1 AUTHOR

Arthur Bergman, E<lt>sky@nanisky.comE<gt>

Various other people at NPW 2004 helped with ideas and suggestions.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Arthur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
