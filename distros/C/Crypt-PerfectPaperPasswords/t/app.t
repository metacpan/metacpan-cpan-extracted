use strict;
use warnings;
use Test::More;
use App::PerlPPP;

my @schedule = ( { name => 'Create only', } );
plan tests => @schedule * 1;

for my $test ( @schedule ) {
  my $name = $test->{name};
  my %args = %{ $test->{args} || {} };
  my $app  = App::PerlPPP->new( %args );
  isa_ok $app, 'App::PerlPPP';
}

