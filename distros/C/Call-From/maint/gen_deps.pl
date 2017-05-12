#!/usr/bin/env perl
# FILENAME: gen_deps.pl
# CREATED: 12/24/15 18:16:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Generate a cpanfile by skimming your source tree

use strict;
use warnings;

use PIR;

use lib 'maint/lib';

use KENTNL::Prereqr;

my $ignore = PIR->new->name('perlcritic.rc.gen.pl');

my $prereqr = KENTNL::Prereqr->new(
    rules => [
        {
            rule     => PIR->new->max_depth(1)->perl_file->name('Makefile.PL'),
            start_in => [''],
            deps_to  => [ 'configure', 'requires' ],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['inc'],
            deps_to  => [ 'configure', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['inc'],
            provides_to => ['configure'],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['lib'],
            deps_to  => [ 'runtime', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['lib'],
            provides_to => [ 'runtime', 'test' ],
        },
        {
            rule     => PIR->new->perl_file->not($ignore),
            start_in => [ 'maint', 'Distar','xt' ],
            deps_to  => [ 'develop', 'requires'],
        },
        {
            rule => PIR->new->perl_module->not($ignore),
            start_in    => [ 'maint', 'Distar', 'xt' ],
            provides_to => ['develop'],
        },
        {
            rule     => PIR->new->perl_file,
            start_in => ['t'],
            deps_to  => [ 'test', 'requires' ],
        },
        {
            rule        => PIR->new->perl_module,
            start_in    => ['t'],
            provides_to => ['test'],
        }
    ]
);

my ( $prereqs, $provided ) = $prereqr->collect;

use Module::CPANfile;
use Data::Dumper qw();
use CPAN::Meta::Converter;
use Path::Tiny qw( path );

my $cpanfile =
  Module::CPANfile->from_prereqs( $prereqr->prereqs->as_string_hash );
$cpanfile->save('cpanfile');

my $dumper = Data::Dumper->new( [] );
$dumper->Terse(1)->Sortkeys(1)->Indent(1)->Useqq(1)->Quotekeys(0);
path('maint/provided.pl')->spew_raw(
    $dumper->Values(
        [ CPAN::Meta::Converter::_dclone( $provided->{runtime} ) ]
    )->Dump
);
