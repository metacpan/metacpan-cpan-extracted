#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 7;

use ok 'App::TemplateServer::Provider::TT';
use ok 'App::TemplateServer::Context';
use Directory::Scratch;
use Moose;

my $tmp = Directory::Scratch->new;
$tmp->mkdir('foo');
$tmp->touch('include.tt', 'this got included');
$tmp->touch('plain.tt', 'this is plain TT');
$tmp->touch('try_include.tt', '>>[% INCLUDE include.tt %]<<');
$tmp->touch('subdir/foo.tt', 'hopefully subdirs also work');

my $ctx = App::TemplateServer::Context->new( data => { foo => 'bar' } );
my $provider = App::TemplateServer::Provider::TT->new(docroot => ["$tmp"]);
is_deeply [sort $provider->list_templates],
          [sort qw\include.tt plain.tt try_include.tt subdir/foo.tt\],
  'got all expected templates via list_templates';

sub is_rendered($$) { 
    my $out = $provider->render_template($_[0], $ctx);
    chomp $out;
    is $out,  $_[1],
      $_[2] || "$_[0] renders to $_[1]";
}

is_rendered 'plain.tt', 'this is plain TT';
is_rendered 'include.tt', 'this got included';
is_rendered 'try_include.tt', ">>this got included\n<<";
is_rendered 'subdir/foo.tt', 'hopefully subdirs also work';
