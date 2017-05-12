use lib 't/lib';

use strict;
use warnings;

#use Mojo::Base -strict;

use Test::More;
#use Test::Mojo;
use AnyEvent;
use Promises backend => ['AnyEvent'];

BEGIN { use_ok 'Dallycot::Resolver' };

my $resolver = Dallycot::Resolver -> instance;

is $resolver, Dallycot::Resolver->instance, "Resolver is a singleton";

if($ENV{'NETWORK_TESTS'}) {
  my $cv = AnyEvent -> condvar;

  $resolver->get("http://dbpedia.org/resource/Semantic_Web")->done(
    sub { $cv -> send( @_ ); },
    sub { $cv -> croak( @_ ); }
  );

  my $data = eval {
    $cv -> recv;
  };
  if($@) {
    warn $@;
  }

  ok $data;
}

done_testing();
