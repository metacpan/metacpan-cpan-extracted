#!/usr/bin/perl

package B::XSUB::Dumber;

use strict;
use warnings;

use Carp qw(croak);
use B qw(svref_2object class);
use B::Generate;
use Scalar::Util qw(reftype);
use XSLoader;

our $VERSION = '0.01';

XSLoader::load __PACKAGE__, $VERSION;

use base qw(B::OPCheck);

sub null {
    my $op = shift;
    return class($op) eq "NULL";
}

sub import {
	my ( $class, @subs ) = @_;

	my $xsubs = $^H{$class} || do {
		my %xsubs;
		use B::Utils;
		$class->SUPER::import(entersub => check => sub {
			my $op = shift;

			# FIXME only if !hasargs

			return unless null $op->first->sibling; # method

			my $kid = $op->first;
			$kid = $kid->first->sibling; # skip ex-list, pushmark
			while ( not null $kid->sibling ) {
				$kid = $kid->sibling;
			}

			my $cvop = $kid->first;

			if ($cvop->name eq "gv") {
				my $gv = $cvop->gv;
				my $cv = $gv->CV;
				if ( my $xsub = $cv->XSUB ) {
					if ( $xsubs{$xsub} ) {
						$op->ppaddr(simple_xsub_ppaddr());
						#$op->ppaddr($xsub); # not possible, it's not a PP (returns an OP*)
					}
				}
			}
		});

		\%xsubs;
	};

	foreach my $sub ( @subs ) {
		my $ref;

		unless ( ref($sub) ) {
			$ref = eval 'package ' . caller(). '; no strict "refs"; \&{$sub}';
			warn $@ if $@;
		} elsif ( reftype($sub) eq 'CODE' ) {
			$ref = $sub;
		}

		unless ( ref($ref) && reftype($ref) eq 'CODE' ) {
			croak "Must supply a sub name or a code reference to an XSUB";
		}

		my $xsub = svref_2object($ref)->XSUB;

		unless ( $xsub ) {
			croak "$sub is not an XSUB";
		}

		$xsubs->{$xsub}++;
	}
}

sub unimport {
	my $class = shift;
	$class->SUPER::unimport(); # FIXME only call if really everything is removed, and with the right opname and callback sub
}

__PACKAGE__

__END__

=pod

=head1 NAME

B::XSUB::Dumber - L<B::OPCheck> demo for microoptimizing XSUB invocation.

=head1 SYNOPSIS

	use Scalar::Util qw(blessed reftype);

	{
		use B::XSUB::Dumber qw(blessed reftype);
		reftype($thingy);
	}

=head1 DESCRIPTION

Certain XSUBs don't need lots of fluff from pp_entersub to be invoked since
they don't do anything fancy. For XSUBs fitting this description this module
lexically replaces the implementation of the entersub ops calling them with a
much simpler version that doesn't do anything except invoke the XSUB function
pointer from the CV.

This is meant mostly as a demo of the sort of thing B::OPCheck lets you do, so
please don't take it too seriously or rely on it in any way.

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
