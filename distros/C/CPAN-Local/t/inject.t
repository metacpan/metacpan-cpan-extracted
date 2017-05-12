use strict;
use warnings;

use CPAN::Local::Plugin::Inject;
use Module::Faker::Dist;
use File::Temp qw(tempdir);
use Path::Class qw(file);
use Moose::Meta::Class;

use Test::Most;

my $repo_root = tempdir;
my $repo_uri  = 'http://www.example.com/';

my $metaclass = Moose::Meta::Class->create_anon_class(
    superclasses => ['CPAN::Local::Distribution'],
    cache        => 1,
);

my $plugin = CPAN::Local::Plugin::Inject->new(
    uri  => $repo_uri,
    root => $repo_root,
    distribution_class => $metaclass->name,
);

isa_ok( $plugin, 'CPAN::Local::Plugin::Inject' );

my %distros = (
    file_which => CPAN::Local::Distribution->new(
        authorid => 'ADAMK',
        filename => Module::Faker::Dist->new(
            name => 'File-Which'
        )->make_archive,
    ),
    any_moose => CPAN::Local::Distribution->new(
        authorid => 'SARTAK',
        filename => Module::Faker::Dist->new(
            name => 'Any-Moose'
        )->make_archive,
    ),
    bogus => CPAN::Local::Distribution->new(
        authorid => 'FOOBAR',
        filename => file( tempdir, 'foobar' )->stringify,
    ),
);

my @injected = $plugin->inject( $distros{bogus} );

is ( scalar @injected, 0, 'inject failed' );

@injected = $plugin->inject( @distros{qw(file_which any_moose)} );

is ( scalar @injected, 2, 'inject succeded' );

is_deeply (
    [ sort map file($_->filename)->basename, @injected ],
    [ 'Any-Moose-0.01.tar.gz', 'File-Which-0.01.tar.gz' ],
    'injected package names',
);

my $existing = grep { -e } map { file( $repo_root, $_->path ) } @injected;

is ( $existing, 2, 'injected tarballs exist' );

ok ( -e file($repo_root, 'authors/id/S/SA/SARTAK/CHECKSUMS'), "Checksums file created" );

done_testing;
