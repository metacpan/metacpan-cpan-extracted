#!/usr/bin/perl -w

use Test::More;

use t::app::Main;
use strict;

plan tests => 8;

use Data::Dumper 'Dumper';

use t::app::Main::Result::Track;
t::app::Main::Result::Track->load_components(qw/ Result::ProxyField /);
t::app::Main::Result::Track->init_proxy_field();

#test de la fonction rh_ext_to_bdd
my $rh_ext_to_bdd = {
  'cd_id' => 'cdid',
  'track_title' => 'title'
};
is_deeply(t::app::Main::Result::Track->rh_ext_to_bdd(), $rh_ext_to_bdd, "class->rh_ext_to_bdd without argument return table mapping from public name to database name");
is(t::app::Main::Result::Track->rh_ext_to_bdd('cd_id'), $rh_ext_to_bdd->{cd_id}, "class->rh_ext_to_bdd with 1 argument return database mapping value of its public name");
is(t::app::Main::Result::Track->rh_ext_to_bdd('track_title'), $rh_ext_to_bdd->{track_title}, "class->rh_ext_to_bdd with 1 argument return database mapping value of its public name");
t::app::Main::Result::Track->rh_ext_to_bdd('cd_id', 'test');
is(t::app::Main::Result::Track->rh_ext_to_bdd('cd_id'), 'test', "class->rh_ext_to_bdd with 2 arguments set database mapping value of its public name");
t::app::Main::Result::Track->rh_ext_to_bdd('cd_id', 'cdid');

# test de la fonction rh_bdd_to_ext
my $rh_bdd_to_ext = {
  'cdid' => 'cd_id',
  'title' => 'track_title'
};
is_deeply(t::app::Main::Result::Track->rh_bdd_to_ext(), $rh_bdd_to_ext, "class->rh_bdd_to_ext without argument return table mapping from database name to public_name");
is(t::app::Main::Result::Track->rh_bdd_to_ext('cdid'), $rh_bdd_to_ext->{cdid}, "class->rh_bdd_to_ext with 1 argument return public name mapping value of its database name");
is(t::app::Main::Result::Track->rh_bdd_to_ext('title'), $rh_bdd_to_ext->{title}, "class->rh_bdd_to_ext with 1 argument return public name mapping value of its database name");
t::app::Main::Result::Track->rh_bdd_to_ext('cdid', 'test');
is(t::app::Main::Result::Track->rh_bdd_to_ext('cdid'), 'test', "class->rh_bdd_to_ext with 2 arguments set public name mapping of its database name");
t::app::Main::Result::Track->rh_bdd_to_ext('cdid', 'cd_id');



