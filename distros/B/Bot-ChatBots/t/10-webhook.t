use strict;
use Test::More tests => 35;
use Test::Exception;
use Mojolicious::Lite;
use Test::Mojo;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

throws_ok { require WH2 } qr{missing\ normalize_record}mxs,
  'one method is not implemented';

my $wh;
lives_ok {
   require WH;
   $wh = WH->new(app => app(), path => '/wh');
}
'minimal formally compliant WebHook';

isa_ok $wh, 'WH';

lives_ok { $wh->install_route } 'install_route';

my $t = Test::Mojo->new;

{
   $wh->reset;
   $t->post_ok('/wh')->status_is(204);
   is scalar($wh->processed), 1, 'something arrived to the process phase';

   my ($processed) = $wh->processed;
   ok exists($processed->{refs}), 'refs exists';
   my $refs = delete $processed->{refs};
   ok exists($refs->{app}), 'refs.app';
   isa_ok $refs->{app}, 'Mojolicious';
   ok exists($refs->{controller}), 'refs.controller';
   isa_ok $refs->{controller}, 'Mojolicious::Controller';
   ok exists($refs->{stash}), 'refs.stash';

   is_deeply $processed,
     {updates => [], source_pairs => {flags => {rendered => 0}}},
     'rest of processed stuff';
}

{
   $wh->reset;
   $t->post_ok('/wh', json => {hey => 'you'})->status_is(204);
   is scalar($wh->processed), 1, 'something arrived to the process phase';

   my ($processed) = $wh->processed;
   ok exists($processed->{refs}), 'refs exists';
   my $refs = delete $processed->{refs};
   ok exists($refs->{app}), 'refs.app';
   isa_ok $refs->{app}, 'Mojolicious';
   ok exists($refs->{controller}), 'refs.controller';
   isa_ok $refs->{controller}, 'Mojolicious::Controller';
   ok exists($refs->{stash}), 'refs.stash';

   is_deeply $processed,
     {
      updates => [{hey => 'you'}],
      source_pairs => {flags => {rendered => 0}}
     },
     'rest of processed stuff';
}

{
   $wh->reset;
   $t->post_ok('/wh', json => {answer => 'me'})->status_is(200);
   $t->content_is('All OK!');  # look Ma!
   is scalar($wh->processed), 1, 'something arrived to the process phase';

   my ($processed) = $wh->processed;
   ok exists($processed->{refs}), 'refs exists';
   my $refs = delete $processed->{refs};
   ok exists($refs->{app}), 'refs.app';
   isa_ok $refs->{app}, 'Mojolicious';
   ok exists($refs->{controller}), 'refs.controller';
   isa_ok $refs->{controller}, 'Mojolicious::Controller';
   ok exists($refs->{stash}), 'refs.stash';

   is_deeply $processed, {
      updates => [{answer => 'me'}],
      source_pairs => {flags => {rendered => 1}},    # look Ma!
     },
     'rest of processed stuff';
}

done_testing();
