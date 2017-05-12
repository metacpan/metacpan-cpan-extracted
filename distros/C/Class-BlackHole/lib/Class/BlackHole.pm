
# Time-stamp: "2004-12-29 20:04:51 AST"
require 5;
package Class::BlackHole;
use strict;
use vars qw(@ISA $Debug $VERSION);

$VERSION = "0.04";
@ISA = ();
$Debug = 0 unless defined $Debug;

=head1 NAME

Class::BlackHole - base class to treat unhandled method calls as no-ops

=head1 SYNOPSIS

  use Class::BlackHole;

  # set up a class X, to inherit from Class::BlackHole
  @X::ISA = qw(Class::BlackHole);
  # put a method in it
  sub X::zaz { 123123; }
  
  print "Zaz is <", X->zaz, ">\n";
  print "Flork is <", X->flork, ">\n";
  print "can zaz : <", X->can('zaz'), ">\n";
  print "can flork : <", X->can('flork'), ">\n";
  
  
  The above code prints:
   Zaz is <123123>
   Flork is <>
   can zaz : <CODE(0x392c7d4)>
   can flork : <>

=head1 DESCRIPTION

Normally, if you try to call a method that there's no handler for,
you get an error:

  Can't locate object method "flork" via package "X".

But for classes that inherit from Class::BlackHole, unhandled methods
become just no-operations.

=head1 CAVEATS

Be sure to have Class::BlackHole be the absolute last item in your
class's ISA list.

This class will almost definitely not work right as part of any ISA
tree that has multiple inheritance.

=head1 IMPLEMENTATION

Class::BlackHole just traps everything with an AUTOLOAD sub that is a
no-operation.

HOWEVER, what makes Class::Blackhole different than merely:

  @Class::BlackHole::ISA = ();
  sub Class::BlackHole::AUTOLOAD { }

is that this would (unhappily) trap calls to the helpful methods in
UNIVERSAL, like C<can>, C<VERSION>, and C<isa>.  Class::BlackHole
aliases those methods (or better said, all subs in package UNIVERSAL)
into its own package, so that they'll be accessible instead of being
caught by the AUTOLOAD.

=head1 FUNCTIONS AND METHODS

This module provides no functions or methods.

It exports no symbols into the calling package or anywhere else.

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful,
but B<without any warranty>; without even the implied warranty of
B<merchantability> or B<fitness for a particular purpose>.

But let me know if it gives you any problems, OK?

=head1 COPYRIGHT

Copyright 1999, 2000, Sean M. Burke C<sburke@cpan.org>, all rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

###########################################################################
sub AUTOLOAD { return; } # no-op -- the famed black hole!
sub import   { return; } # no-op
sub export   { return; } # no-op

###########################################################################
# Now copy (well, alias) Universal's subs up into this class

foreach my $symbol (keys %UNIVERSAL::) {
  no strict 'refs';
  if(defined &{"UNIVERSAL::$symbol"}) {
    print "aliasing my $symbol to sub UNIVERSAL::$symbol\n" if $Debug;
    *{$symbol} = \&{"UNIVERSAL::$symbol"} unless defined &{$symbol};
  } else {
    print "there's no sub UNIVERSAL::$symbol\n" if $Debug;
  } 
}

###########################################################################
1;

__END__
