package LibraryHelper;

use strict;
use warnings;

use Test::More;
use AnyEvent;
use Promises backend => ['AnyEvent'];

use Dallycot::Processor;
use Dallycot::Parser;
use Dallycot::Registry;

use Exporter 'import';

our @EXPORT = qw(
  run
  uses
  Numeric
  Boolean
  String
  Vector
  Stream
  Duration
);

my $processor = Dallycot::Processor -> new(
  context => Dallycot::Context -> new,
  max_cost => 1_000_000,
);

my $parser = Dallycot::Parser -> new;

sub uses {
  my(@urls) = @_;

  my $cv = AnyEvent -> condvar;
  Dallycot::Registry->instance->register_used_namespaces(@urls)->done(sub {
    $processor -> append_namespace_search_path(@urls);
    $cv -> send();
  }, sub {
    $cv -> croak(@_);
  });
  $cv -> recv;
  return;
}

sub run {
  my($stmt) = @_;
  my $cv = AnyEvent -> condvar;

  eval {
    my $parse = $parser -> parse($stmt);
    if('HASH' eq ref $parse) {
      $parse = [ $parse ];
    }
    $processor -> add_cost(-$processor->cost);
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
  }
  #print STDERR "Cost of running ($stmt): ", $processor -> cost, "\n";
  $ret;
}

sub Numeric {
  Dallycot::Value::Numeric -> new($_[0]);
}

sub Boolean {
  Dallycot::Value::Boolean -> new($_[0]);
}

sub String {
  Dallycot::Value::String->new(@_);
}

sub Vector {
  Dallycot::Value::Vector->new(@_);
}

sub Stream {
  my(@things) = @_;

  my $stream = Dallycot::Value::Stream -> new(pop @things);
  foreach my $thing (reverse @things) {
    $stream = Dallycot::Value::Stream -> new($thing, $stream);
  }
  return $stream;
}

sub Duration {
  my(%parts) = @_;

  return Dallycot::Value::Duration->new(%parts);
}

1;
