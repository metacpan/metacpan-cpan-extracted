use strict;
use warnings;

use Test::Most;
use CPAN::Faker::HTTPD;
use File::Copy;
use Module::Faker::Dist;
use CPAN::Local::Plugin::DistroList;
use File::Temp qw(tempdir tempfile);
use Path::Class qw(file dir);
use Moose::Meta::Class;

### setup

sub _test_distrolist {
    my ( $test, $distrolist ) = @_;
    isa_ok $distrolist, 'CPAN::Local::Plugin::DistroList';

    my @distros = $distrolist->gather;
    is $#distros, 1, "distros gathered $test";
    is $_->metadata->name, 'Foo-Bar', "file fetched $test"
        for @distros;
}

my @fake_distros = (
    Module::Faker::Dist->new(
        name    => 'Foo-Bar',
        version => '0.01',
    ),
    Module::Faker::Dist->new(
        name    => 'Foo-Bar',
        version => '0.02',
    ),
);

my $fakepan = CPAN::Faker::HTTPD->new({ source => '.' });
$fakepan->add_dist($_) for @fake_distros;

$fakepan->$_ for qw(_update_author_checksums write_package_index
                 write_author_index write_modlist_index write_perms_index);

my $distro_path_tmpl = 'authors/id/L/LO/LOCAL/Foo-Bar-%s.tar.gz';

my @fake_distro_uris;

my $cachedir = tempdir;

for ( '0.01', '0.02') {
    my $path = sprintf $distro_path_tmpl, $_;

    # uris
    my $uri  = $fakepan->endpoint;
    $uri->path($path);
    push @fake_distro_uris, $uri->as_string;

    # paths
    my $source = file($fakepan->dest, $path)->stringify;
    my $target = file($cachedir, file($path)->basename)->stringify;
    File::Copy::copy($source, $target) or die $!;
}

my ( $fh, $configfile ) = tempfile;
print $fh "Foo-Bar-0.01.tar.gz\nFoo-Bar-0.02.tar.gz" or die $!;
close $fh or die $!;

my $plugin = 'CPAN::Local::Plugin::DistroList';

my $metaclass = Moose::Meta::Class->create_anon_class(
    superclasses => ['CPAN::Local::Distribution'],
    roles        => ['CPAN::Local::Distribution::Role::Metadata',
                     'CPAN::Local::Distribution::Role::FromURI',
                     'CPAN::Local::Distribution::Role::NameInfo'],
    cache        => 1,
);

my %args = ( root => '.', distribution_class => $metaclass->name );

### add distros from mirror

_test_distrolist 'from mirror' => $plugin->new(
    uris  => \@fake_distro_uris,
    cache => tempdir(),
    %args,
);

### add local distros

_test_distrolist 'from path' => $plugin->new(
    uris     => [ map { $_->make_archive } @fake_distros ],
    local    => 1,
    authorid => 'FOOBAR',
    %args,
);

### use configuration file

_test_distrolist 'using configuration file' => $plugin->new(
    list     => $configfile,
    local    => 1,
    authorid => 'FOOBAR',
    prefix   => "$cachedir/",
    %args,
);

done_testing;
