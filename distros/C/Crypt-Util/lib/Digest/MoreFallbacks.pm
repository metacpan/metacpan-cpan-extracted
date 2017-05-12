#!/usr/bin/perl

package Digest::MoreFallbacks;

use strict;
use warnings;

use Digest ();

for ( $Digest::MMAP{"RIPEMD-160"} ) {
	s/PIPE/RIPE/ if defined;
}

_add_fallback($_, "Crypt::RIPEMD160") for "RIPEMD160", "RIPEMD-160";

foreach my $sha (1, 224, 256, 384, 512) {
	_add_fallback("SHA$sha", [ "Digest::SHA::PurePerl", $sha ]);
	_add_fallback("SHA-$sha", [ "Digest::SHA::PurePerl", $sha ]);
}

_add_fallback(MD5 => $_) for qw(Digest::MD5 Digest::Perl::MD5);

sub _add_fallback {
	my ( $alg, @args ) = @_;

	my $list;

	if ( $list = $Digest::MMAP{$alg} ) {
		unless ( ref $list eq 'ARRAY' ) {
			$list = $Digest::MMAP{$alg} = [ $list ];
		}
	} else {
		$list = $Digest::MMAP{$alg} = [];
	}

	_append_fallback($list, @args);
}

sub _append_fallback {
	my ( $list, $impl ) = @_;

	if ( ref $impl ) {
		push @$list, $impl;
	} else {
		my %seen;
		@$list = grep { ref($_) or !$seen{$_}++ } @$list, $impl;
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Digest::MoreFallbacks - Provide additional fallbacks in L<Digest>'s MMAP table.

=head1 SYNOPSIS

	use Digest::MoreFallbacks;

	Digest->new("SHA-1")

=head1 DESCRIPTION

This module adds entries to L<Digest>'s algorithm to implementation table. The
intent is to provide better fallback facilities, including pure Perl modules
(L<Digest::SHA::PurePerl>, L<Digest::MD5>), and facilitating for modules that
don't match the naming convention (L<Crypt::RIPEMD160> would have worked if it
were named L<Digest::RIPEMD160>).

=cut


