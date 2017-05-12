#!perl
use Test::More;

use_ok 'App::Provision::Tiny';
use_ok 'App::Provision::Chameleon5';
use_ok 'App::Provision::Cpanupdate';
use_ok 'App::Provision::Foundation';
use_ok 'App::Provision::Git';
use_ok 'App::Provision::Homebrew';
use_ok 'App::Provision::Mysql';
use_ok 'App::Provision::Perlbrew';
use_ok 'App::Provision::Repoupdate';
use_ok 'App::Provision::Sequelpro';
use_ok 'App::Provision::Ssh';

diag("Testing App::Provision::Tiny $App::Provision::Tiny::VERSION, Perl $], $^X");

done_testing();
