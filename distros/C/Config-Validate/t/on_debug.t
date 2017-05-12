#!/sw/bin/perl

use strict;
use warnings;

Test::Class->runtests;

package Test::OnDebug;

use base qw(Test::Class);
use Test::More;
use Data::Dumper;
use Storable qw(dclone);

use Config::Validate qw(validate);

sub on_debug :Test(4) {
  my $cv;
  my $call_count = 0;
  my $on_debug = sub {
    my ($self, @args) = @_;
    is($self, $cv, "\$self matches C::V object");
    is(join('', @args), "Validating [/test]", "message as expected");
    $call_count++;
  };

  $cv = Config::Validate->new(debug => 1,
                              on_debug => $on_debug);
  $cv->schema({test => { type => 'boolean' }});
  eval { $cv->validate({test => 1}) };
  is($@, '', "validate successful");
  is($call_count, 1, "on_debug ran once");
  return;
}

sub mkpath_array_index :Test(10) {
  my $cv;
  my $call_count = 0;
  my $on_debug = sub {
    my ($self, @args) = @_;
    is($self, $cv, "\$self matches C::V object");
    if ($call_count == 0) {
      is(join('', @args), "Validating [/test]", "message as expected");
    } else {
      my $index = $call_count - 1;
      is(join('', @args), "Validating [/test/[$index]]", "message as expected");      
    }
    $call_count++;
  };

  $cv = Config::Validate->new(debug => 1,
                              on_debug => $on_debug);
  $cv->schema({test => { 
    type => 'array',
    subtype => 'integer',
   }});
  eval { $cv->validate({test => [ 1, 2, 3]}) };
  is($@, '', "validate successful");
  is($call_count, 4, "on_debug_ran_once");
  return;
}

