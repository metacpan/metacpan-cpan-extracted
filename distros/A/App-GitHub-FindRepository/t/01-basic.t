#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

plan skip_all => "Only go out to the Internet for author" unless -e 'inc/.author';

plan qw/no_plan/;

use App::GitHub::FindRepository;

is( App::GitHub::FindRepository->find( 'git://github.com/robertkrimen/Algorithm-BestChoice.git' ), 'git://github.com/robertkrimen/Algorithm-BestChoice.git' );
is( `script/github-find-repository git\@github.com:robertkrimen/dOc-SiMply.git --git-protocol`, "git\@github.com:robertkrimen/doc-simply.git\n" );
is( `script/github-find-repository git\@github.com:robertkrimen/dOc-SiMply.git`, "git\@github.com:robertkrimen/doc-simply.git\n" );
is( App::GitHub::FindRepository->find( 'robertkrimen,DBIx-Deploy' ), 'git://github.com/robertkrimen/dbix-deploy.git' );
is( App::GitHub::FindRepository->find( 'git://github.com/robertkrimen/Algorithm-bestChoice.git' ), 'git://github.com/robertkrimen/Algorithm-BestChoice.git' );
is( App::GitHub::FindRepository->find( 'robertkrimen,Algorithm-bestChoice' ), 'git://github.com/robertkrimen/Algorithm-BestChoice.git' );
is( App::GitHub::FindRepository->find( 'robertkrimen/Algorithm-BestChoice.git' ), 'git://github.com/robertkrimen/Algorithm-BestChoice.git' );
is( App::GitHub::FindRepository->find( 'robertkrimen/Algorithm-BestChoice' ), 'git://github.com/robertkrimen/Algorithm-BestChoice.git' );
is( App::GitHub::FindRepository->find( 'github.com/robertkrimen/Algorithm-BestChoice' ), 'github.com/robertkrimen/Algorithm-BestChoice.git' );
is( App::GitHub::FindRepository->find_by_git( 'git://github.com/robertkrimen/Algorithm-bestChoice.git' ), undef );
is( `script/github-find-repository robertkrimen,DBIx-Deploy`, "git://github.com/robertkrimen/dbix-deploy.git\n" );
is( `script/github-find-repository git://github.com/robertkrimen/alGorithm-bestChoIce.git`, "git://github.com/robertkrimen/Algorithm-BestChoice.git\n" );
is( `script/github-find-repository robertkrimen,DBIx-Deploy --getter curl`, "git://github.com/robertkrimen/dbix-deploy.git\n" );
is( `script/github-find-repository robertkrimen,DBIx-Deploy --getter LWP`, "git://github.com/robertkrimen/dbix-deploy.git\n" );
is( `script/github-find-repository robertkrimen,DBIx-Deploy --getter ^ --git-protocol`, "git://github.com/robertkrimen/dbix-deploy.git\n" );
is( App::GitHub::FindRepository->find( 'git@github.com/robertkrimen/aLgorithm-beStChoice.git' ), 'git@github.com/robertkrimen/Algorithm-BestChoice.git' );
is( `script/github-find-repository git\@github.com/robertkrimen/dOc-SiMply.git --git-protocol`, "git\@github.com/robertkrimen/doc-simply.git\n" );
is( `script/github-find-repository git\@github.com/robertkrimen/dOc-SiMply.git --output=private`, "git\@github.com:robertkrimen/doc-simply.git\n" );
is( `script/github-find-repository git\@github.com/robertkrimen/dOc-SiMply.git --output=public`, "git://github.com/robertkrimen/doc-simply.git\n" );
is( `script/github-find-repository git\@github.com/robertkrimen/dOc-SiMply.git --output=url`, "git\@github.com/robertkrimen/doc-simply.git\n" );
is( `script/github-find-repository git\@github.com/robertkrimen/dOc-SiMply.git --output=base`, "robertkrimen/doc-simply\n" );
is( `script/github-find-repository git\@github.com/robertkrimen/dOc-SiMply.git --output=name`, "doc-simply\n" );
