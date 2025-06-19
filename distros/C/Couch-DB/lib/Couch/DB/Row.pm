# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Row;{
our $VERSION = '0.200';
}


use Couch::DB::Util;

use Log::Report 'couch-db';

use Scalar::Util   qw/weaken/;


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;

	$self->{CDR_result} = delete $args->{result} or panic;
	weaken $self->{CDR_result};

	$self->{CDR_doc}    = delete $args->{doc};
	$self->{CDR_answer} = delete $args->{answer} or panic;
	$self->{CDR_values} = delete $args->{values};
	$self->{CDR_rownr}  = delete $args->{rownr}  or panic;
	$self;
}

#-------------

sub result() { $_[0]->{CDR_result} }


sub doc() { $_[0]->{CDR_doc} }


sub answer() { $_[0]->{CDR_answer} }


sub values() { $_[0]->{CDR_values} || $_[0]->answer }

#-------------

sub pageNumber() { $_[0]->result->pageNumber }
sub rowNumberInPage() { ... }
sub rowNumberInSearch() { ... }
sub rowNumberInResult() { $_[0]->{CDR_rownr} }

1;
