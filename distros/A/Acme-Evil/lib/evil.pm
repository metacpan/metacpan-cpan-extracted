#!/usr/bin/perl
package evil;

use 5.010001;
use strict;
use warnings;

use Carp;

my $INTERMEDIATE = __PACKAGE__.'/intermediate';
my $LAX          = __PACKAGE__.'/lax';

our $VERSION = 0.003001;

our %tainted;
our %wants_strict;

sub import {
	croak "Cannot load evil module when \"no evil ':strict'\" is in effect" if %wants_strict;

	my $hinthash = (caller 0)[10] || {};
	croak "Current module requested no evilness" if $hinthash->{$LAX};

	$hinthash = (caller 3)[10] || {};
	croak "Cannot load evil module when parent requested \"no evil ':lax'\"" if $hinthash->{$LAX};

	my $level = 4;
	my @caller;
	while (@caller = caller $level) {
		$hinthash = $caller[10] || {};
		croak "Cannot load evil module when ancestor requested \"no evil ':intermediate'\""
		  if $hinthash->{$INTERMEDIATE};
		$level++;
	}

	$tainted{caller()} = 1;
}

sub unimport {
	my $strict_arg = grep /^:strict$/i, @_;
	my $intermediate_arg = grep /^:intermediate$/i, @_;
	my $lax_arg = grep /^:lax$/i, @_;
	my $disable_arg = grep /^:disable$/i, @_;

	if (!$disable_arg && $tainted{caller()}) { # caller is evil
		croak 'Current module is evil'
	}

	if ($strict_arg) {
		$wants_strict{caller()} = 1;
		croak "Evil module already loaded. Cannot enforce \"no evil ':strict'\"" if %tainted
	} elsif ($lax_arg) {
		$^H{$LAX} = 1
	} elsif ($disable_arg) {
		delete $wants_strict{caller()};
		delete $^H{$LAX};
		delete $^H{$INTERMEDIATE};
	} else { # $intermediate_arg or no arg
		$^H{$INTERMEDIATE} = $^H{$LAX} = 1
	}
}

1;
__END__

=encoding utf-8

=head1 NAME

evil - RFC 3514 (evil bit) implementation for Perl modules

=head1 SYNOPSIS

  # in A.pm
  package A;
  use evil;

  # in B.pm
  package B;
  no evil ':strict';
  use A; # <dies>

  # in C.pm
  package C;
  use A;

  # in D.pm
  package D;
  no evil;
  use C; # <dies>

  # in E.pm
  package E;
  no evil ':lax';
  use C; # does not die, as C is not evil

  # in F.pm
  package F;
  use C;
  no evil;
  # does not die, as modules loaded before the pragma are ignored

=head1 DESCRIPTION

L<RFC3514|https://www.ietf.org/rfc/rfc3514.txt> introduces a new flag
called the "evil bit" in all IP packets. The intention is to simplify
the work of firewalls. Software that sends IP packets with malicious
intent must set the evil bit to true, and firewalls can simply drop
such packets.

The evil pragma is a Perl implementation of the same concept. With
this pragma malicious modules can declare their evil intent while
critical modules can request that they will only use / run alongside
non-evil code.

The pragma can be used in the following ways:

=over

=item use B<evil>;

Marks the current package as evil. All malicious modules MUST use this
directive to ensure the full functionality of this pragma.

=item no B<evil> ':strict';

The calling module function properly if malignant code is loaded
anywhere in the program. Throws an exception if an evil module is
loaded, whether at the moment of calling this pragma or in the future.

=item no B<evil> ':disable';

Removes the effect of any previous C<no B<evil> ':something'> used in
this module, thus stating the module does not care about evil code.

=item no B<evil> ':intermediate'

The calling module cannot function properly if it is using evil code,
whether directly or indirectly. Throws an exception if an evil module
is subsequently loaded by the calling module or by one of the children
modules (or by one of their children modules, etc). Also throws an
exception if the current module is evil.

=item no B<evil> ':lax';

The calling module cannot function properly if it is using evil code
direcly. Throws an exception if the calling module subsequently loads
an evil module, or if the current module is evil.

=item no B<evil>;

Synonym for C<no evil ':intermediate'>.

=back

=head1 BUGS

The following does not die:

  # Evil.pm
  package Evil;
  use evil;

  # A.pm
  package A;
  use Evil;

  # B.pm
  package B;
  no evil ':intermediate';
  use Evil;

  # script.pl
  #!/usr/bin/perl
  use A;
  use B;

Since Evil was loaded by A, B does not load Evil and therefore does
not detect that Evil is... evil. If we loaded B before A in script.pl,
we would get an exception. So order of loading modules matters for
intermediate and lax modes. Strict mode is unaffected by this bug.

=head1 CAVEATS

When using intermediate and lax modes, any evil modules loaded before
the pragma is enabled are ignored. This is by design, to allow
temporarily disabling the pragma. An example:

  package MyModule;
  no evil;
  use Some::Module;
  use Another::Module;

  no evil ':disable';
  use Evil::Module; # does not die
  no evil;

  use Some::More::Modules;
  ...

Correct functioning of this pragma depends critically on the evil bit
being set properly. If a faulty evil module fails to C<use evil;>, the
pragma will not function properly.

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
