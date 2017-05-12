use strict;
use Test::More tests => 18;
use Test::Exception;
use Mojolicious::Lite;
use Test::Mojo;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

my ($wh, @processed);
lives_ok {
   require Whatever::WH;
   $wh = Whatever::WH->new(
      app       => app(),
      path      => '/wh',
      processor => sub {
         my $record = shift;
         push @processed, $record;
         return $record;
      }
   );
} ## end lives_ok
'minimal formally compliant WebHook';

isa_ok $wh, 'Whatever::WH';

my $code;
lives_ok { $code = $wh->code } 'code lives';
is $code, 202, 'code is fine';

lives_ok { $wh->install_route } 'install_route';

my $t = Test::Mojo->new;

{
   @processed = ();
   $t->post_ok('/wh')->status_is(202);
   is scalar(@processed), 1, 'something arrived to the process phase';
   my ($processed) = @processed;
   my $source = {%{$processed->{source}}};

   isa_ok $source->{refs}, 'Bot::ChatBots::Weak';
   my $refs = delete $source->{refs};
   ok exists($refs->{$_}), $_ for qw< app controller self stash >;

   is_deeply $processed->{batch}, {count => 1, total => 1}, 'batch';
   ok exists($processed->{update}), 'update exists';
   is $processed->{update}, undef, 'update is undefined';
}

{
   @processed = ();
   $t->post_ok('/wh', json => {hey => 'you'})->status_is(202);
}

done_testing();
