use strict;
use warnings;

package My::NoDESTROY;
use Autoload::AUTOCAN;

sub new { bless {}, shift }

sub AUTOCAN { undef }

package main;
use Test::More;
use Test::Warnings;

{
  my $obj = My::NoDESTROY->new;
  ok !defined $obj->can('DESTROY'), 'no DESTROY method';
}

done_testing;
