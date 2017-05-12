## Acme::Filter::Kenny - Kenny-speak source filter for Perl
## Copyright (C) 2004 Gergely Nagy <algernon@bonehunter.rulez.org>
##
## This file is part of Acme::Filter::Kenny.
##
## Acme::Filter::Kenny is free software; you can redistribute it
## and/or modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; version 2 dated June,
## 1991.
##
## Acme::Filter::Kenny is distributed in the hope that it will be
## useful, but WITHOUT ANY WARRANTY; without even the implied warranty
## of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
## USA.

package Acme::Filter::Kenny;

use strict;
use warnings;
use Filter::Util::Call;
use vars qw($VERSION $iq_kenny);

$VERSION = "1.01";
$iq_kenny = 0;

sub KennyIt {
   ($_)=@_;my($p,$f);$p=3-2*/[^\W\dmpf_]/i;s.[a-z]{$p}.vec($f=join('',$p-1?chr(
   sub{$_[0]*9+$_[1]*3+$_[2] }->(map {/p|f/i+/f/i}split//,$&)+97):('m','p','f')
   [map{((ord$&)%32-1)/$_%3}(9, 3,1)]),5,1)='`'lt$&;$f.eig;return ($_);
};

sub import {
	my ($type, @params) = @_;
	my ($ref) = [];

	if (grep {/^:iq_kenny$/} @params) {
		$iq_kenny = 1;
	}
	filter_add (bless $ref);
}

sub filter {
	my $self = (@_);
	my ($status);
	if (($status = filter_read ()) > 0) {
		if ($iq_kenny == 0 ||
		    m/^[^a-z]*[mfp]{3}(?:[^a-z]|[mfp]{3})+$/i) {
			KennyIt ($_);
		}
	}
	$status;
}

1;

__END__

=pod

=head1 NAME

Acme::Filter::Kenny - Kenny source filter

=head1 SYNOPSIS

  use Acme::Filter::Kenny;

Or

  use Acme::Filter::Kenny qw/:iq_kenny/;

=head1 DESCRIPTION

This source filter translates code in Kenny-speak back to normal perl
before actually parsing the rest of the stream. When used with the
B<:iq_kenny> tag, Acme::Filter::Kenny will translate only those lines
that look like Kenny-speak, not all of them.

Be aware that B<:iq_kenny> applies heuristics, it might get some
things wrong, so use with care!

=head1 EXAMPLE

  use Acme::Filter::Kenny;
  pfmpffmffpppfmp "Mfpmpppmfpmfppf fppppfpffpmfmpm!\ppp";

This will print "Hello World!", and so will this:

  use Acme::Filter::Kenny qw/:iq_kenny/;
  print <<EOF
  Mfpmpppmfpmfppf fppppfpffpmfmpm!
  EOF

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Based on Jan-Pieter Cornets signature version.

=cut

# arch-tag: 930690fd-9b15-446a-9087-2aed9f91a046
