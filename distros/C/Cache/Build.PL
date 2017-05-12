use strict;
use warnings;

use lib "./inc";
use Devel::AssertOS qw(Unix);

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Cache',
    license             => 'perl',
    dist_author         => 'Chris Leishman <chris@leishman.org>',
    dist_version_from   => 'lib/Cache.pm',
    dist_abstract       => "Provide a generic Cache mechanism.",
    requires =>
    {
        'DB_File'			=> '1.72',
        'Date::Parse'		=> '2.24',
        'Digest::SHA'		=> '0',
        'Fcntl'			=> '1.03',
        'File::Find'		=> '0',
        'File::NFSLock'		=> '1.20',
        'File::Path'		=> '1.00',
        'File::Spec'		=> '0.8',
        'Heap::Fibonacci'		=> '0.01',
        'IO::File'		=> '1.08',
        'IO::Handle'		=> '1.21',
        'IO::String'		=> '1.02',
        'Storable'		=> '1.00',
        'Symbol'			=> '1.02',
        'Test::More'		=> '0.45',
        'perl'              => '5.006',
    },
    configure_requires =>
    {
        'Module::Build' => 0,
    },
    add_to_cleanup      => [ 'Cache-*' ],
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/web-cpan",
        },
        keywords =>
        [
            'cache',
            'caching',
            'file',
            'generic',
            'memory',
            'optimisation',
            'optimise',
            'optimization',
            'optimize',
            'speed',
        ],
    },
);

$builder->create_build_script();
