#!/usr/bin/perl -w

use strict;
use lib qw(t/lib);
use Test::More tests => 2;
use App::Build;

my $build1 = App::Build->new
  ( module_name  => 'Foo::Boo',
    dist_version => '0.01',
    quiet        => 1,
    );
is( $build1->packlist,
    File::Spec->catfile( $build1->install_destination( 'arch' ),
                         qw(auto Foo Boo .packlist) ) );

my $build2 = App::Build->new
  ( dist_name    => 'Foo-Boo',
    dist_version => '0.01',
    quiet        => 1,
    );
is( $build2->packlist,
    File::Spec->catfile( $build2->install_destination( 'arch' ),
                         qw(auto Foo-Boo .packlist) ) );
