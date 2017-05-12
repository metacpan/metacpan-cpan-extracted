use lib 't/lib';

use strict;
use warnings;
use Data::Dumper;

#use Mojo::Base -strict;

use Test::More;
#use Test::Mojo;
use AnyEvent;
use Promises backend => ['AnyEvent'];

use Dallycot::Parser;
use Dallycot::Processor;

BEGIN {
  use_ok 'Dallycot::Value'
};

my $processor = Dallycot::Processor -> new;

my $parser = Dallycot::Parser->new;

run('times(x, y) :> x * y');

my $times = get_resolution($processor -> get_assignment('times'));

isa_ok $times, 'Dallycot::Value::Lambda';

my $double = run('times(2, _)');

isa_ok $double, 'Dallycot::Value::Lambda';

$double = run('times(2, 2)');

isa_ok $double, 'Dallycot::Value::Numeric';

is $double -> value, 4, 'times(2, 2) = 4';

$double = run('times(2, _)(2)');

isa_ok $double, 'Dallycot::Value::Numeric';

is $double -> value, 4, 'times(2, _)(2) = 4';


done_testing();

#==============================================================================

use Data::Dumper;

sub run {
  my($stmt) = @_;
  #print STDERR "Running ($stmt)\n";
  my $cv = AnyEvent -> condvar;

  eval {
    my $parse = $parser -> parse($stmt);
    if('HASH' eq $parse) {
      $parse = [ $parse ];
    }
    $processor->add_cost(-$processor->cost);
    $processor -> execute(@{$parse}) -> done(
      sub { $cv -> send( @_ ) },
      sub { $cv -> croak( @_ ) }
    );
  };

  if($@) {
    $cv -> croak($@);
  }

  my $ret = eval {
    $cv -> recv;
  };
  if($@) {
    warn "$stmt: $@";
    #print STDERR "($stmt): ", Data::Dumper->Dump([$parser->program($stmt)]);
  }
  $ret;
}

sub get_resolution {
  my($promise) = @_;
  my $cv = AnyEvent -> condvar;
  $promise -> done( sub {
    $cv -> send(@_);
  }, sub {
    $cv -> croak( @_ );
  });

  $cv -> recv;
}
