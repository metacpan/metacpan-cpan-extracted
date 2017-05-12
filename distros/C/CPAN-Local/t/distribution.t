use strict;
use warnings;

use CPAN::Local::Distribution;
use Module::Faker::Dist;
use CPAN::Faker::HTTPD;
use Path::Class qw(file);
use File::Temp  qw(tempdir);
use Test::Most;

my @distribution_roles = qw(
    CPAN::Local::Distribution::Role::Metadata
    CPAN::Local::Distribution::Role::NameInfo
    CPAN::Local::Distribution::Role::FromURI
);

my $distribution_class = Moose::Meta::Class->create_anon_class(
    superclasses => ['CPAN::Local::Distribution'],
    roles        => \@distribution_roles,
    cache        => 1,
)->name;


my %distro;

$distro{authorid_and_filename} = $distribution_class->new(
    authorid => 'ADAMK',
    filename => 'File-Which-1.09.tar.gz',
);

isa_ok ( $distro{authorid_and_filename}, 'CPAN::Local::Distribution' );
isa_ok ( $distro{authorid_and_filename}->nameinfo, 'CPAN::DistnameInfo' );

is ( $distro{authorid_and_filename}->path,
     'authors/id/A/AD/ADAMK/File-Which-1.09.tar.gz',
     'calculate distro path' );

$distro{filename} = $distribution_class->new(
    filename => '/foo/bar/authors/id/A/AD/ADAMK/File-Which-1.09.tar.gz',
);

is ( $distro{filename}->authorid, 'ADAMK', 'calculate authorid' );

dies_ok (
    sub {
        my $distro_filename_no_author = $distribution_class->new(
            filename => '/foo/bar/File-Which-1.09.tar.gz',
        );
    },
    'fail to calculate authorid',
);

my $fake_distro = Module::Faker::Dist->new( name => 'Foo-Bar' );

$distro{existing_filename} = $distribution_class->new(
    authorid => 'ADAMK',
    filename => $fake_distro->make_archive,
);

isa_ok ( $distro{existing_filename}->metadata, 'CPAN::Meta' );

my $fakepan = CPAN::Faker::HTTPD->new({ source => '.' });
$fakepan->add_dist($fake_distro);

$fakepan->$_ for qw(_update_author_checksums write_package_index
                 write_author_index write_modlist_index write_perms_index);

my $distro_path = 'authors/id/L/LO/LOCAL/Foo-Bar-0.01.tar.gz';
my $distro_uri = $fakepan->endpoint;
$distro_uri->path($distro_path);
$distro_uri = $distro_uri->as_string;

$distro{uri} = $distribution_class->new( uri => $distro_uri );

isa_ok ( $distro{uri}, 'CPAN::Local::Distribution' );

is ( $distro{uri}->authorid, 'LOCAL', 'calculate authorid from uri' );

is ( $distro{uri}->path, $distro_path, 'calculate distro path from uri' );

my $tempdir = tempdir( CLEANUP => 1 );

$distro{uri_and_cache} = $distribution_class->new(
    uri   => $distro_uri,
    cache => $tempdir,
);

ok( -e file( $tempdir, $distro_path ), 'fetch from uri into cache' );

$distro{uri_and_author} = $distribution_class->new(
    uri      => $distro_uri,
    cache    => $tempdir,
    authorid => 'FOOBAR',
);

is ( $distro{uri_and_author}->authorid, 'FOOBAR', 'honor custom author' );
ok( -e file( $tempdir, 'authors/id/F/FO/FOOBAR/Foo-Bar-0.01.tar.gz' ), 'fetch from uri with custom author' );

done_testing;
