# Copyrights 2024 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Util;
use vars '$VERSION';
$VERSION = '0.002';

use parent 'Exporter';

use warnings;
use strict;

use Log::Report 'couch-db';

our @EXPORT_OK = qw/flat/;

sub import
{	my $class  = shift;
	$_->import for qw(strict warnings utf8 version);
	$class->export_to_level(1, undef, @_);
}


sub flat(@) { grep defined, map +(ref eq 'ARRAY' ? @$_ : $_), @_ }

1;
