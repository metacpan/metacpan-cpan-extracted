use strict;
use Test::More tests => 11;
use Test::Exception;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

my ($wh, @processed);
lives_ok {
   require Whatever::WH;
   $wh = Whatever::WH->new(
      custom_pairs => {what => 'ever', wow => 'overrides'},
      processor    => sub {
         push @processed, shift;
         return $processed[-1];
      }
   );
} ## end lives_ok
'minimal formally compliant WebHook';

isa_ok $wh, 'Whatever::WH';
is $wh->typename, 'wh', 'typename';

my $source;
lives_ok { $source = $wh->pack_source(source_pairs => {some => 'args'}) }
'pack_source lives';

isa_ok $source->{refs}, 'Bot::ChatBots::Weak';
ok exists($source->{refs}{self}), 'refs.self exists';
isa_ok $source->{refs}{self}, 'Whatever::WH';
delete $source->{refs};
is_deeply $source,
  {
   class => 'Whatever::WH',
   type  => 'wh',
   what  => 'ever',
   wow   => 'overrides',
   some  => 'args',
   this  => 'goes',
  },
  'source';

{
   @processed = ();
   lives_ok { $wh->process({hey => 'you'}) } 'process lives';
   is scalar(@processed), 1, 'something arrived to the process phase';
   is_deeply $processed[0], {hey => 'you'}, 'process goes';
}

done_testing();
