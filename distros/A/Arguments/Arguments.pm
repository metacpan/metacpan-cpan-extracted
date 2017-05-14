#
# Arguments.pm -- Perl subroutine type-checking
#
# $Id: Arguments.pm,v 1.2 2001/10/07 21:38:35 binkley Exp $
#

package Arguments;

use v5.6;
use strict;
use warnings;

use constant RCSID =>
  '$Id: Arguments.pm,v 1.2 2001/10/07 21:38:35 binkley Exp $';

use Carp ( );
use Devel::Peek ( );

# 'our' won't work since we haven't been processed yet when
# MODIFY_CODE_ATTRIBUTES is called.  Weird.  --bko FIXME
use vars qw(@DELAYED_CHECKS %ARGUMENT_CHECKS);

# Evil sets in.  Arrange for ourselves to be in the importer's @ISA so
# that MODIFY_CODE_ATTRIBUTES works without the importer needing to
# declare us as a base package.
sub import {
  no strict qw(refs);

  my $caller = caller;
  push @{"$caller\::ISA"}, __PACKAGE__;
}

# Add them rather than redefine the hash so that other modules have a
# chance to install their own during BEGIN before we are compiled.
$ARGUMENT_CHECKS{REF} ||= sub { UNIVERSAL::isa ($_[0], $_[1]) };
$ARGUMENT_CHECKS{RX} ||= sub { defined $_[0] and $_[0] =~ $_[1] };

# Convience.
our $Arguments_Package = __PACKAGE__;

# For error messages
sub _quote_strings {
  my @s;

  for (@_) {
    push @s, (defined $_ ? do {
      my $s = $_;
      $s =~ s/\\/\\\\/g;
      $s =~ s/'/\\'/g;
      "'$s'";
    } : 'undef');
  }

  @s;
}

# Cribbed from dumpvar.pl.
sub find_sub_name ($) {
  my $code = shift;
  $code = \&$code;		# guarantee a hard reference

  my $gv = Devel::Peek::CvGV ($code) or return;

  *$gv{PACKAGE} . '::' . *$gv{NAME};
}

# We don't want to be bothered by "%s package attribute may clash with
# future reserved word: %s" for MODIFY_CODE_ATTRIBUTES.  HOW DO YOU
# MAKE THIS WORK??  --bko XXX
{
  no warnings qw(reserved);

  sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $coderef, @attributes) = @_;

    my @arguments = map {
      my $s = $_;
      $s =~ s/^$Arguments_Package\s*\(\s*//;
      $s =~ s/\s*\)$//;
      split /\s*,\s*/, $s;
    } grep /^$Arguments_Package\s*\(/, @attributes;

    if (0) {
      # Collect the true source of any problems.
      my @caller = qw(package filename line subroutine hasargs wantarray
		      evaltext is_require hints bitmask);
      my %caller;
      @caller{@caller} = do { package DB; caller (1) };

      push @DELAYED_CHECKS,
	[$package, $coderef, [@arguments], {%caller}];

    } else {
      my $longmess;

      {
	local $Carp::CarpLevel = 1;
	$longmess = Carp::longmess ('');
      }

      $longmess =~ s/\n.*//s;

      # The funky last argument is so that croak looks right
      push @DELAYED_CHECKS,
	[$package, $coderef, [@arguments], $longmess];
    }

    grep !/^$Arguments_Package\s*\(/, @attributes;
  }
}

sub synthesize_call_wrapper ($$$$@) {
  my ($package, $sub_name, $prototype, $longmess, @arguments) = @_;
  my $required = grep !/\?$/, @arguments;
  my $optional = @arguments;

  my $coderef;
  { no strict qw(refs); $coderef = *{$sub_name}{CODE} }

  my $s = "sub ($prototype) {
  Carp::croak \"Not enough arguments for $sub_name\"
    if \@_ < $required;
  Carp::croak \"Too many arguments for $sub_name\"
    if \@_ > $optional;
";

  my $i = 0;

  for my $a (@arguments) {
    my $j = $i + 1;

    $s .= "  Carp::croak \"Type of arg $j to $sub_name must be $a (not \"
       . defined \$_[$i] ? \$_[$i] : 'undef' . ')'
";

    # How to handle these?  --bko FIXME
    my $opt = $a =~ s/\?$//;

    if (exists $ARGUMENT_CHECKS{$a}) {
      $s .= "        unless \$ARGUMENT_CHECKS{'$a'}->(\$_[$i]);
";

    } elsif ($a =~ /^\//) {
      eval "use strict; use warnings; qr$a";

      if ($@) {
	# Hide the eval
	my ($s) = $@ =~ /(.*) at .*$/;
	Carp::croak "$s$longmess.\n"; # test RX first
      }

      $s .= "        unless \$ARGUMENT_CHECKS{RX}->(\$_[$i], qr$a);
";

    } else {
      eval "use strict; use warnings; \${'$a'};";

      if ($@) {
	# Hide the eval
	my ($s) = $@ =~ /(.*) at .*$/;
	Carp::croak "$s$longmess.\n"; # test RX first
      }


      $s .= "        unless \$ARGUMENT_CHECKS{REF}->(\$_[$i], '$a');
";
    }

    $i = $j;
  }

  $s .= "
  goto &\$coderef;
};
";

  # The 'misc' warning is weird -- eval keep seeing "unrecognized
  # escape \d" while dealing with /^\d+$/ (an unsigned integer), which
  # doesn't seem right.  --bko FIXME
  { no strict qw(refs); no warnings qw(misc redefine);
    *{$sub_name} = eval $s }

  croak $@ if $@;
}

sub process_delayed_checks ( ) {
  for (@DELAYED_CHECKS) {
    my ($package, $coderef, $arguments, $longmess) = @$_;
    my @arguments = @$arguments;

    my $prototype = prototype $coderef;

    # Normal, variadic sub.
    return if not defined $prototype and not @arguments;

    my $sub_name = find_sub_name $coderef;
    my (@prototypes, $ref, $opt);

    for my $token (split //, $prototype) {
      if ($ref) {
	undef $ref;
	push @prototypes, $opt ? "\\$token?" : "\\$token";

      } elsif ($token eq ';') {
	$opt = 1;

      } elsif ($token eq "\\") {
	$ref = 1;

      } else {
	push @prototypes, $opt ? "$token?" : $token;
      }
    }

    # Check that they match.  Use the "\n" trick from Carp::Heavy.
    Carp::croak "Not enough prototypes for $sub_name$longmess.\n"
      if @arguments < @prototypes;
    Carp::croak "Too many prototypes for $sub_name$longmess.\n"
      if @arguments > @prototypes;

    synthesize_call_wrapper
      ($package, $sub_name, $prototype, $longmess, @arguments);
  }
}

# Work around that subs don't have prototypes defined yet at the time
# that attributes are processed.  I'd consider this a bug. --bko FIXME
{
  # We need to be in the main package do delay our processing until
  # all the other packages have had a chance to declare and/or define
  # their prototypes.  Otherwise, we get called too soon, and
  # encounter the 'no prototypes' bug.  --bko FIXME
  package main;

  CHECK {
    # This will try to move the problem so that it shows up in the sub
    # declaration rather that in this processing.
    local $Carp::CarpLevel = 3;
    Arguments::process_delayed_checks ( );
  }
}

1;

__END__

=head1 NAME

Arguments - Perl subroutine type-checking

=head1 SYNOPSIS

(This documents version 0.2 of B<Arguments>.)

  package Flintstone;

  use Arguments;

  BEGIN {
    $Arguments::ARGUMENT_CHECKS{INTEGER}
      = sub { defined $_[0] and $_[0] =~ /^[+-]?\d+$/ },
  }

  sub fooby ($\%) : Arguments (INTEGER, HASH);
  sub tv_show ($) : Arguments (Flintstone);

=head1 DESCRIPTION

B<Arguments> provides argument checking during compile and run time,
supplementing prototype declarations.

=head2 Why?

There are other ways of doing this -- Damian Conway's
B<Attribute::Handlers> and B<Attribute::Types> are one very
interesting route; Dave Rolsky's B<Params::Validate> is another.  I am
doubtful if I have covered the gamut with the mention of just those
two.

However, I had an epiphany to use subroutine attributes for argument
type checking, and to try and make it clean and simple to use
(DCONWAY's work is too general-purpose for my needs, and has a lot of
overhead).  It is not there yet, but I hope to get it there.  If
nothing else, it is a new, fun area of Perl for me to explore.

An obvious area to explore is reimplementing this module using
B<Attribute::Handlers> and hooking in B<Params::Validate> for richer
type-checking.  Maybe I'll do that after installing L4.  :-)

=head2 Basic Use

To use B<Arguments>, a sub declares an attribute named I<Arguments>
listing the type of arguments, each matching a protype declaration:

  sub fooby ($\%) : Arguments (INTEGER, HASH);

By default, B<Arguments> has only two checks:

=over 4

=item Regular Expressions

Any argument to the I<Arguments> attribute starting with a C</> (the
forward-slash character) is assumed to be the beginning of a regular
expression formed by appending that argument to C<qr>.  See
L<perlop/"qr/STRING/imosx"> for details.  Arguments to the sub call
are then checked against this pattern.  An example:

  sub eat_int_and_live ($) : Arguments (/^[+-]?\d+$/);

=item References (the default)

Any other argument is assumed to be a reference checked by
C<UNIVERSAL::isa>.  This includes non-blessed reference types such as
I<HASH>.  An example:

  sub eat_code_and_die (&) : Arguments (CODE);

This example is unexciting since Perl's own prototype-checking should
catch argument mismatches.

=back

=head2 Enforcing Method Calls

A more interesting example enforces method calls:

  package Flintstone;

  sub yabba_dabba_doo ($) : Arguments (Flintstone);

The creates a run-time check that the first argument to
C<yabba_dabba_doo> is indeed a C<Flintstone> or a package which has
C<Flintstone> as a base.  Presently, Perl has no way of enforcing this
restriction.

=head2 Extending Argument Checks

Packages may extend the argument checks by manipulating
C<%Arguments::ARGUMENT_CHECKS> in their C<BEGIN> blocks.  An example:

  BEGIN {
    $Arguments::ARGUMENT_CHECKS{INTEGER}
      = sub { defined $_[0] and $_[0] =~ /^[+-]?\d+$/ },
  }

  sub eat_int_and_live ($) : Arguments (INTEGER);

This is the same as the example above for regular expressions, except
that the intent of the sub declaration is more clear.

=head2 EXPORT

None.  However, B<Arguements> pushes itself onto the caller's @ISA
array so that the MODIFY_CODE_ATTRIBUTES technique may work.  See
L<attributes/"Package-specific Attribute Handling"> for an
explanation.

=head1 DIAGNOSTICS

The following are the diagnostics generated by B<Arguments>.  Items
marked "(W)" are non-fatal (invoke C<Carp::carp>); those marked "(F)"
are fatal (invoke C<Carp::croak>).  None of the diagnostics may be
selectively disabled with categores.  See <perllexwarn>.

=over 4

=item Can't use string ("%s") as %s ref while "strict refs" in use

(F) Only hard references are allowed by C<strict refs>.  Symbolic
references are disallowed.  See L<perlref>.

What this usually means for B<Arguments> is that you have a poorly
formed argument list to the I<Arguments> attribute such as C<Arguments
(Apple Core)> instead of C<Arguments (Apple, Core)>.

(F) The function requires more arguments than you specified.

=item Not enough prototypes for %s

(F) The function requires more prototypes in the I<Arguments>
attribute than you specified.

=item Too many arguments for %s

(F) The function requires fewer arguments than you specified.

=item Too many prototypes for %s

(F) The function requires fewer prototypes in the I<Arguments>
attribute than you specified.

=item Type of arg %d to %s must be %s (not %s)

(F) This function requires the argument in that position to be of a
certain type.  Arrays must be @NAME or C<@{EXPR}>.  Hashes must be
%NAME or C<%{EXPR}>.  No implicit dereferencing is allowed--use the
{EXPR} forms as an explicit dereference.  See L<perlref>.  For blessed
references, C<UNIVERSAL::isa ($_[%d], '%s')> need be true.

=back

=head1 TODO

=over 4

=item Tie type-checking of prototypes and attributes.

=item Support for non-scalar prototypes (e.g., C<sub (\@)>).

=item Support for optional prototypes (e.g., C<sub ($;$)>).

=item Support for list prototypes (e.g., C<sub (%)>).

=item Generate prototype declarations from the attributes.

=item Tests.

=back

=head1 AUTHOR

B. K. Oxley (binkley) E<lt>binkley@bigfoot.comE<lt>

=head1 SEE ALSO

=over 4

=item L<Attribute::Handlers>

=item L<Attribute::Types>

=item L<UNIVERSAL/"isa ( TYPE )">

=item L<attributes>

=item L<perlop/"qr/STRING/imosx">

=item L<perllexwarn>

=item L<perlref>

=cut
