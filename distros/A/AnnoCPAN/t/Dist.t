use strict;
use warnings;
use Test::More;
use AnnoCPAN::Config 't/config.pl';
use AnnoCPAN::Dist;

# simple tests for AnnoCPAN::Dist that don't require a database

#plan 'no_plan';
plan tests => 44;

# try an old-fashioned dist
my $dist = AnnoCPAN::Dist->new(
    't/CPAN/authors/id/A/AL/ALICE/My-Dist-0.10.tar.gz');

isa_ok( $dist, 'AnnoCPAN::Dist' );

# just double-check that the inherited methods work, even though
# CPAN::DistnameInfo has a much more comprehensive test suite.
is ( $dist->dist,       'My-Dist',              'dist'); 
is ( $dist->filename,   'My-Dist-0.10.tar.gz',  'filename'); 
is ( $dist->pathname,   't/CPAN/authors/id/A/AL/ALICE/My-Dist-0.10.tar.gz', 
    'pathname'); 
is ( $dist->cpanid,     'ALICE',                'cpanid'); 
is ( $dist->extension,  'tar.gz',               'extension'); 
is ( $dist->version,    '0.10',                 'version'); 
is ( $dist->maturity,   'released',             'maturity'); 
is ( $dist->distvname,  'My-Dist-0.10',         'distvname'); 

# stringification overloading
is ( "$dist",           'My-Dist-0.10',         'overload ""'); 

# delegate objects
isa_ok( $dist->archive, 'AnnoCPAN::Archive' );
isa_ok( $dist->stat,    'File::stat' );

# other simple methods
#is ( $dist->mtime,      1109479191,     'mtime'); 
ok ( ! $dist->verbose,                  'verbose'); 
ok ( ! $dist->has_lib,                  'has_lib (old)'); 

# namespace_from_path
is ( $dist->namespace_from_path('My-Dist-0.10/Dist.pm'), 
    'My::Dist',           'namespace_from_path (old, root)'); 
is ( $dist->namespace_from_path('My-Dist-0.10/bin/script'), 
    'script',             'namespace_from_path (old, bin)'); 
is ( $dist->namespace_from_path('My-Dist-0.10/Stuff/Here.pm'), 
    'My::Stuff::Here',     'namespace_from_path (old, subdir)'); 

# try a modern-style dist
$dist = AnnoCPAN::Dist->new(
    't/CPAN/authors/id/A/AL/ALICE/My-Dist-0.20.tar.gz');

ok ( $dist->has_lib,                  'has_lib (new)'); 
is ( $dist->namespace_from_path('My-Dist-0.10/lib/My/Dist.pm'), 
    'My::Dist',         'namespace_from_path (new, lib)'); 
is ( $dist->namespace_from_path('My-Dist-0.10/bin/script'), 
    'script',           'namespace_from_path (new, bin)'); 
is ( $dist->namespace_from_path('My-Dist-0.10/my_tutorial.pod'), 
    'my_tutorial',      'namespace_from_path (new, root)'); 
is ( $dist->namespace_from_path('My-Dist-0.10/pod/my_tutorial.pod'), 
    'my_tutorial',      'namespace_from_path (new, subdir)'); 
# a 'combined' style
#is ( $dist->namespace_from_path('My-Dist-0.10/Dist.pm'), 
    #'My::Dist',      'namespace_from_path (combined)'); 

# try the include/exclude system
my @wanted = (qw(
    My-Dist-0.10/lib/My/Dist.pm
    My-Dist-0.10/tutorial.pod
    My-Dist-0.10/bin/script
    My-Dist-0.10/bin/script.pl
    My-Dist-0.10/script.pl
    My-Dist-0.10/script
    My-Dist-0.10/Dist.pm
    My-Dist-0.10/Other/Dist.pm
    My-Dist-0.10/Makefile.pm
    My-Dist-0.10/Makefile/Create.pm
));

for my $file (@wanted) {
    ok ( $dist->want($file),    "want ($file)" );
}

my @not_wanted = (qw(
    My-Dist-0.10/Makefile.PL
    My-Dist-0.10/Makefile
    My-Dist-0.10/blib/My/Dist.pm
    My-Dist-0.10/inc/BUNDLES/Other-Dist/Dist.pm
    My-Dist-0.10/inc/Module/Install.pm
    My-Dist-0.10/Changes
    My-Dist-0.10/MANIFEST
    My-Dist-0.10/META.yml
    My-Dist-0.10/setup.exe
    My-Dist-0.10/eg/eg.pl
    My-Dist-0.10/t/config.pl
    My-Dist-0.10/t/my_test.pm
));

for my $file (@not_wanted) {
    ok ( !$dist->want($file),    "not want ($file)" );
}
