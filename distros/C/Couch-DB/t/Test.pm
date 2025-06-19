# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

#!!! leading blank to make Pause ignore this package
   package Test;{
our $VERSION = '0.200';
}

   use parent 'Exporter';

use Test::More;
use Data::Dumper  qw/Dumper/;

$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;
$Data::Dumper::Sortkeys  = 1;

use lib '../lib';
use Couch::DB::Util qw(simplified);

our @EXPORT_OK = qw/$dump_answers $dump_values $trace _result _framework Dumper/;

our $dump_answers = 0;
our $dump_values  = 0;
our $trace = 0;

sub _result($$)
{	my ($name, $result) = @_;
	ok defined $result, "New call: $name";
	isa_ok $result, 'Couch::DB::Result', "... $name, result";
	$dump_answers && warn Data::Dumper->Dump([$result->answer], ['$answer']);

	$dump_values  && warn simplified values => $result->values;
	$result;
}

sub framework_mojo
{	eval "require Mojolicious";
	if($@)
	{	warn "Mojolicious cannot be used";
		return undef;
	}

	require_ok 'Mojolicious::Lite';
	require_ok 'Test::Mojo';

	my $mojo  = Test::Mojo->new;
	ok defined $mojo, 'Created Mojolicious tester';

	require_ok 'Couch::DB::Mojolicious';
	my $couch = Couch::DB::Mojolicious->new(api => '3.3.3');

	isa_ok $couch, 'Couch::DB::Mojolicious', '...';
	isa_ok $couch, 'Couch::DB', '...';
	$couch;
}

sub _framework()
{
	defined $ENV{PERL_COUCH_DB_SERVER}
    	or plan skip_all => "PERL_COUCH_DB_SERVER not set";

	framework_mojo;
}

sub import
{	my $class  = shift;
	$_->import for qw(strict warnings utf8 version);
	$class->export_to_level(1, undef, @EXPORT_OK);
}

1;
