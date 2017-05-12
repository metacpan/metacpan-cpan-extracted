#!/usr/bin/perl
# 02-preregister.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

    use strict;
    use warnings;
    use Test::More;
    BEGIN { 
        plan skip_all => "Set TEST_LIVE environment variable to run live tests." 
            unless $ENV{TEST_LIVE};
    plan tests => 6;
    use_ok('Catalyst::Model::XML::Feed'); 
    
}

my $model = Catalyst::Model::XML::Feed->
  new(undef, 
      {feeds => [
		 {title => 'delicious', uri => 'http://feeds.delicious.com/v2/rss/'},
		 {location => 'http://googleblog.blogspot.com/'},
		]
      },
     );

ok($model, 'created model');
ok(scalar $model->get_all_feeds > 2, 'at least two feeds added');

my $d;
eval {
    $d = $model->get('delicious');
};
ok(!$@, 'got feed ok');
isa_ok($d, 'XML::Feed');
ok($d->title, 'delicious');

