package Clone::Any;

use strict;

use Devel::UseAnyFunc '-isasubclass';

use vars qw($VERSION $EXPORT @SOURCES);

BEGIN {
  $VERSION = 1.01;
  
  $EXPORT = 'clone';
  @SOURCES = (
    'Clone'	=> 'clone',
    'Util'	=> 'clone',
    'Storable'	=> 'dclone',
    'Clone::PP'	=> 'clone',
    'Class::MakeMethods::Utility::Ref' => 'ref_clone',
  );
}

sub import { 
  my ( $self, $name, @sources ) = @_;
  $self->SUPER::import( $name || $EXPORT, @sources ? @sources : @SOURCES );
}

1;

__END__

=head1 NAME

Clone::Any - Select an available recursive-copy function

=head1 SYNOPSIS

  use Clone::Any qw(clone);
  
  $a = { 'foo' => 'bar', 'move' => 'zig' };
  $b = [ 'alpha', 'beta', 'gamma', 'vlissides' ];
  $c = new Foo();
  
  $d = clone($a);
  $e = clone($b);
  $f = clone($c);

=head1 DESCRIPTION

This module checks for several different modules which can provide
a clone() function to make deep copies of Perl data structures.

=head2 Clone Interface

The clone function makes recursive copies of nested hash, array,
scalar and reference types, including tied variables and objects.

The clone() function takes a scalar argument to copy. To duplicate
lists, arrays or hashes, pass them in by reference. e.g.

  my $copy = clone(\@array);    my @copy = @{ clone(\@array) };
  my $copy = clone(\%hash);     my %copy = %{ clone(\%hash) };

=head2 Multiple Implementations

Depending on which modules are available, this may load Clone, Clone::PP,
Util, Storable, or Class::MakeMethods::Utility::Ref. 
If none of those modules are available, it will C<croak>.

=head1 SEE ALSO

For the various implementations, see L<Clone>, L<Clone::PP>, L<Storable>, 
L<Util>, and L<Class::MakeMethods::Utility::Ref>.

See L<Devel::UseAnyFunc> for the underlying module loader and exporter functionality.

=head1 CREDITS AND COPYRIGHT

Developed by Matthew Simon Cavalletto at Evolution Softworks. 
More free Perl software is available at C<www.evoscript.org>.

You may contact the author directly at C<evo@cpan.org> or C<simonm@cavalletto.org>. 

To report bugs via the CPAN web tracking system, go to 
C<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Clone-Any> or send mail 
to C<Dist=Clone-Any#rt.cpan.org>, replacing C<#> with C<@>.

Copyright 2003 Matthew Simon Cavalletto. 

Orignally inspired by Clone by Ray Finch with contributions from chocolateboy.
Portions Copyright 2001 Ray Finch. Portions Copyright 2001 chocolateboy. 

You may use, modify, and distribute this software under the same terms as Perl.

=cut
