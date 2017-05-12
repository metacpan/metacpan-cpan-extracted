#!/usr/bin/perl

use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions;
use Cwd;

use App::Padadoy;

my ($cwd) = (cwd =~ /^(.*)$/g); # untainted cwd

my $devdir = tempdir( CLEANUP => 1 );
diag "creating Foo::Bar app in $devdir";
chdir $devdir;

my $padadoy = App::Padadoy->new('', quiet => 1);
$padadoy->create('Foo::Bar');

foreach my $dir (qw(app data app/lib app/t app/lib/Foo libs)) {
    ok( -d catdir($devdir,$dir), "$dir/ created" )
}

foreach my $file (qw(app/app.psgi app/lib/Foo/Bar.pm dotcloud.yml perl/index.pl)) {
    ok( -f catdir($devdir,$file), "$file created" )
}

#$padadoy->checkout

# TODO: deplist.txt is not checked

# TODO: test newly created application

chdir $cwd; # be back before cleanup
done_testing;
