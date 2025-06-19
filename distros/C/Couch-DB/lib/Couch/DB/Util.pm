# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Util;{
our $VERSION = '0.200';
}

use parent 'Exporter';

use warnings;
use strict;

use Log::Report 'couch-db';
use Data::Dumper ();
use Scalar::Util qw(blessed);

our @EXPORT_OK   = qw/flat pile apply_tree simplified/;
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

sub import
{	my $class  = shift;
	$_->import for qw(strict warnings utf8 version);
	$class->export_to_level(1, undef, @_);
}


sub flat(@) { grep defined, map +(ref eq 'ARRAY' ? @$_ : $_), @_ }


sub pile(@) { +[ flat @_ ] }


#XXX why can't I find a CPAN module which does this?

sub apply_tree($$);
sub apply_tree($$)
{	my ($tree, $code) = @_;
	    ! ref $tree          ? $code->($tree)
	  : ref $tree eq 'ARRAY' ? +[ map apply_tree($_, $code), @$tree ]
	  : ref $tree eq 'HASH'  ? +{ map +($_ => apply_tree($tree->{$_}, $code)), keys %$tree }
	  : ref $tree eq 'CODE'  ? "$tree"
	  :                        $code->($tree);
}


sub simplified($$)
{	my ($name, $data) = @_;

	my $v = apply_tree $data, sub ($) {
		my $e = shift;
		    ! blessed $e         ? $e
		  : $e->isa('DateTime')  ? "DATETIME($e)"
		  : $e->isa('Couch::DB::Document') ? 'DOCUMENT('.$e->id.')'
		  : $e->isa('JSON::PP::Boolean')   ? ($e ? 'BOOL(true)' : 'BOOL(false)')
		  : $e->isa('version')   ? "VERSION($e)"
		  : 'OBJECT('.(ref $e).')';
	};

	Data::Dumper->new([$v], [$name])->Indent(1) ->Quotekeys(0)->Sortkeys(1)->Dump;
}

1;
