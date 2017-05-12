# $Id: Amb.pm,v 1.7 2008/09/03 12:56:14 dk Exp $
package Amb;
use strict;

require Exporter;
require DynaLoader;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw(Exporter DynaLoader);
$VERSION = '0.02';
@EXPORT = qw(amb);
@EXPORT_OK = qw(angelic demonic);

bootstrap Amb $VERSION;

use B::Generate 1.13; 
use Carp qw(confess croak);
use PadWalker;

BEGIN { *CORE::GLOBAL::die = \&dier } ;

my (%patched, %cv, @stack, $charged, $debug);
$debug = $ENV{AMB_DEBUG}||0;

sub dier
{
	CORE::die(@_) if $^S; # eval

AGAIN:
	my $c = pop @stack;
	unless ( $c) {
		my @c = caller;
		push @_, " at $c[1] line $c[2]\n" unless join('', @_) =~ /\n/;
		CORE::die @_;
	}

	if ( $c-> {angelic}) {
		$charged = $c;
		print "angelic/die in branch # $c->{state} at $c->{label}\n" if $debug;
		$c-> {state}++;
		goto $c-> {label};
	} else {
		print "demonic/die in branch # $c->{state} at $c->{label}\n" if $debug;
		$c-> {state} = 0;
		goto AGAIN; # that means die again
	}
}

sub after
{
	my $c = pop @stack;
	if ( $c) {
		if ( $c-> {angelic}) {
			print "angelic/after\n" if $debug;
			$c-> {state} = 0;
		} else {
			print "demonic/after\n" if $debug;
			$c-> {state}++;
			$charged = $c;
			goto $c-> {label};
		}
	}
	undef $charged;
}

sub fail($)
{
	local $Carp::CarpLevel = 3 unless $debug;
	confess "Can't call $_[0]\(\) that way";
}

sub patch
{
	my ($name, $xop, $cv, $upcontext) = @_;
	
	printf("$name: patch at COP( 0x%x)\n", $$xop) if $debug;

	my $cv_frame = $cv ? B::svref_2object($cv) : B::main_cv;

	# enter other CV's padlist
	my $savecp = B::cv_pad;
	B::cv_pad( $cv_frame);

	my $psm = B::GVOP-> new( 'gv', 0, \&after);

       # calling ops
	my $gc2 = B::UNOP-> new( 'null', 0, $psm);
	my $gc3 = B::UNOP-> new( 'entersub', 0, $gc2);
	my $cop = B::COP-> new( 0, '', 0); # this line appears as a calling point for after()
	# this is the COP we put $cop after
	my $gs  = $xop-> sibling-> sibling;
	if ( ref($gs) eq 'B::NULL') {
		# there's no COP -- it was last already
		# create an artificial cop then
		$gs = B::COP-> new( 1, '', 0);
		$xop-> sibling-> sibling( $gs);
	} elsif ( ref($gs) ne 'B::COP') {
		fail $name;
	}

	my $gss = $gs-> sibling;
	my $gsn = $gs-> next;

	$gs->  next($cop);
	$cop-> next($psm);
	$psm-> next($gc2);
	$gc2-> next($gc3);
	$gc3-> next($gsn);

	$gs->  sibling($cop);
	$cop-> sibling($gc3);
	$gc3-> sibling($gss);

	# create COP with label and put it before the entry COP
	my $id  = sprintf "$name\:\:0x%x/0x%x", $$xop, $upcontext;
	my $lab = B::COP-> new( 0, $id, 0);
	$lab-> sibling( $xop-> sibling);
	$xop-> sibling( $lab);
	$lab-> next( $xop-> next);
	$xop-> next($lab);

	# restore padlist	
	B::cv_pad( $savecp);

	if ( $debug > 1) {
		no strict;
		local $SIG{__WARN__};
		eval "*B::CV::NAME      = sub { 'fake' };" unless exists ${'B::CV'}{NAME};
		eval "*B::NV::int_value = sub { '0.0' };"  unless exists ${'B::NV'}{int_value};

		require B::Concise;
		my $walker = B::Concise::compile('-terse',($cv?$cv:()));
		$walker->();
	}

	return $id;
	
}

sub find_ctx
{
	# get the COP that is right before the call of amb()
	my $what = shift;
	my $up  = PadWalker::_upcontext(1);
	fail $what unless $up;
	my $op  = Amb::caller_op($up);
	fail $what unless $op and ref($op) eq 'B::COP';

	# ensure that the call is inside if(...) statement
	my $x = $op-> sibling;
	fail $what unless $x and ref($x) eq 'B::UNOP';
	$x = $x-> first;
	fail $what unless $x and ref($x) eq 'B::LOGOP' and $x-> name =~ /^(cond_expr|and)$/;

	# get the cv frame that has called
	my $upper = PadWalker::_upcontext(2);
	my $cx;
	if ( $upper) {
		$cx = Amb::context_cv($upper);
		fail $what unless $cx and ref($cx) eq 'CODE';
	}

	return $op, $cx, $up;
}

sub amb
{
	croak "format: amb(arg1,arg2)" if 1 != $#_;
	
	my $c;
	unless ( $charged) {
		my ($op, $cx, $up) = find_ctx('amb');
		printf("amb: 1st call at %x\n", $$op) if $debug;

		my $id;
		unless ( exists $patched{$$op}) {
			$id = patch( 'amb', $op, $cx, $up);
			$patched{$$op} = {
				angelic => 1,
				label   => $id,
			}
		}
		$c = $patched{$$op};
		$c-> {state} = 0;
	} else {
		$c = $charged;
		undef $charged;
		print "amb: jump from $c->{label}\n" if $debug;
	}

	die "amb: all branches fail" if $c-> {state} > $#_;

	push @stack, $c;
	return $_[ $c-> {state} ];
}

*angelic = \&amb;

sub demonic
{
	croak "format: demonic(arg1,arg2)" if 1 != $#_;

	my $c;
	unless ( $charged) {
		my ($op, $cx, $up) = find_ctx('demonic');
		printf("demonic: 1st call at %x\n", $op) if $debug;

		my $id;
		unless ( exists $patched{$$op}) {
			$id = patch( 'demonic', $op, $cx, $up);
			$patched{$$op} = {
				angelic => 0,
				label   => $id,
			}
		}
		$c = $patched{$$op};
		$c-> {state} = 0;
	} else {
		$c = $charged;
		undef $charged;
		print "demonic: jump from $c->{label}\n" if $debug;
	}

	die "demonic: all branches succeed" if $c-> {state} > $#_;

	push @stack, $c;
	return $_[ $c-> {state} ];
}

1;

__DATA__

=pod

=head1 NAME

Amb - non-deterministic operators

=head1 SYNOPSIS

   use Amb;

   if ( amb(1,0)) {
        print "failure"; 
	die;
   } else {
	print "success"
   }

will print 'failure' and then 'success'.

=head1 DESCRIPTION

There exist two kinds of non-deterministic operators, 'angelic' and 'demonic',
that accept two parameters, and return one of them depending whether the result
will lead to failure (C<die>, in perl world) or success. Angelic operators will
return the parameter that won't lead to the branch that dies. Demonic
operators, on the contrary, return the parameter that leads to the branch that
dies.

The non-deterministic operators are usually implemented using continuations.
Perl5 lacks these, so this implementation hacks the optree to achieve the
result.  The side effect of this is that branches won't backtrack, and can be
thought of as non-deterministic operators implemented with C<goto>.

=head2 amb(arg1,arg2)

C<amb>, the only operator exported by default, is an angelic operator. Returns
either arg1 or arg2, depending on which one won't lead do C<die> call. If all
branches lead to C<die> call, dies itself.

=head2 angelic(arg1,arg2)

Same as C<amb>

=head2 demonic(arg1,arg2)

Returns the argument that will lead to C<die>.

=head1 USAGE RESTIRICTIONS

Since C<amb()> is implemented with hacking op-tree, there are currently a number
of untested calling combinations, that might fail or even coredump. For example,
calling C<amb()> like

    my $a = amb(@a);
    if ( $a) ...

won't work. The only tested (and yet, up to a point) calling sequence is

    if ( amb(@a) { ... } else { ... }

Other call styles are obliviously untested, so beware.

=head1 INSTALLATION

The module requires latest development version of B::Generate, which doesn't
build on MSWin32. Apply patch from http://rt.perl.org/rt3/Public/Bug/Display.html?id=56536
and recompile perl.

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
