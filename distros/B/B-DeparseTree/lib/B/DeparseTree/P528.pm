# B::DeparseTree::P528.pm
# Copyright (c) 2018 Rocky Bernstein
# All rights reserved.
# This module is free software; you can redistribute and/or modify
# it under the same terms as Perl itself.

use rlib '../..';

package B::DeparseTree::P528;
use B::DeparseTree::P526;

use strict;
use warnings ();

our(@EXPORT, @ISA);
our $VERSION = '3.2.0';

# Is the same as P522. Note however
# we import from B::Deparse and there are differences
# in those routines between 5.22 and 5.24
@ISA = qw(B::DeparseTree::P526);

sub maybe_var_attr {
    my ($self, $op, $cx) = @_;

    my @other_ops = ($op->first);
    my $kid = $op->first->sibling; # skip pushmark
    return if class($kid) eq 'NULL';

    Carp::confess("Can't handle var attr yet");

    my $lop;
    my $type;

    # Extract out all the pad ops and entersub ops into
    # @padops and @entersubops. Return if anything else seen.
    # Also determine what class (if any) all the pad vars belong to
    my $class;
    my $decl; # 'my' or 'state'
    my (@padops, @entersubops);
    for ($lop = $kid; !B::Deparse::null($lop); $lop = $lop->sibling) {
	my $lopname = $lop->name;
	my $loppriv = $lop->private;
        if ($lopname =~ /^pad[sah]v$/) {
            return unless $loppriv & OPpLVAL_INTRO;

            my $padname = $self->padname_sv($lop->targ);
            my $thisclass = ($padname->FLAGS & SVpad_TYPED)
                                ? $padname->SvSTASH->NAME : 'main';

            # all pad vars must be in the same class
            $class //= $thisclass;
            return unless $thisclass eq $class;

            # all pad vars must be the same sort of declaration
            # (all my, all state, etc)
            my $this = ($loppriv & OPpPAD_STATE) ? 'state' : 'my';
            if (defined $decl) {
                return unless $this eq $decl;
            }
            $decl = $this;

            push @padops, $lop;
        }
        elsif ($lopname eq 'entersub') {
            push @entersubops, $lop;
        }
        else {
            return;
        }
    }

    return unless @padops && @padops == @entersubops;

    # there should be a balance: each padop has a corresponding
    # 'attributes'->import() method call, in the same order.

    my @varnames;
    my $attr_text;

    for my $i (0..$#padops) {
        my $padop = $padops[$i];
        my $esop  = $entersubops[$i];

        push @varnames, $self->padname($padop->targ);

        return unless ($esop->flags & OPf_KIDS);

        my $kid = $esop->first;
        return unless $kid->type == OP_PUSHMARK;

        $kid = $kid->sibling;
        return unless $$kid && $kid->type == OP_CONST;
	return unless $self->const_sv($kid)->PV eq 'attributes';

        $kid = $kid->sibling;
        return unless $$kid && $kid->type == OP_CONST; # __PACKAGE__

        $kid = $kid->sibling;
        return unless  $$kid
                    && $kid->name eq "srefgen"
                    && ($kid->flags & OPf_KIDS)
                    && ($kid->first->flags & OPf_KIDS)
                    && $kid->first->first->name =~ /^pad[sah]v$/
                    && $kid->first->first->targ == $padop->targ;

        $kid = $kid->sibling;
        my @attr;
        while ($$kid) {
            last if ($kid->type != OP_CONST);
            push @attr, $self->const_sv($kid)->PV;
            $kid = $kid->sibling;
        }
        return unless @attr;
        my $thisattr = ":" . join(' ', @attr);
        $attr_text //= $thisattr;
        # all import calls must have the same list of attributes
        return unless $attr_text eq $thisattr;

        return unless $kid->name eq 'method_named';
	return unless $self->meth_sv($kid)->PV eq 'import';

        $kid = $kid->sibling;
        return if $$kid;
    }

    my $res = $decl;
    $res .= " $class " if $class ne 'main';
    $res .=
            (@varnames > 1)
            ? "(" . join(', ', @varnames) . ')'
            : " $varnames[0]";

    return "$res $attr_text";
}

1;
