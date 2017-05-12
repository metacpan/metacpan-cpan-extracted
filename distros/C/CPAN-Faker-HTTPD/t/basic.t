use strict;
use warnings;

use Test::Most;
use CPAN::Faker::HTTPD;
use Module::Faker::Dist;
use Module::Faker::Package;
use File::Temp  ();
use Path::Class ();
use LWP::Simple ();

my $cpan = CPAN::Faker::HTTPD->new({
    source => '.' # irrelevant in our case, but required by CPAN::Faker
});

my $dist = Module::Faker::Dist->new(
    name     => 'Multi-Relevant',
    abstract => 'there will be two indexed dists',
    version  => '1.00',
    provides => [ map { Module::Faker::Package->new( %$_) }
        { name => 'Multi::Relevant::Sane',    version => '1.00', in_file => 'lib/Multi/Relevant/Sane.pm'    },
        { name => 'Multi::Relevant::Dropped', version => '1.00', in_file => 'lib/Multi/Relevant/Dropped.pm' },
        { name => 'Multi::Relevant::Stale',   version => '1.00', in_file => 'lib/Multi/Relevant/Stale.pm'   },
    ],
);

$cpan->add_dist($dist);

$cpan->$_ for qw(_update_author_checksums write_package_index
                 write_author_index write_modlist_index write_perms_index);

my $index_uri = $cpan->endpoint;
$index_uri->path('modules/02packages.details.txt.gz');

ok LWP::Simple::get($index_uri->as_string), "we have a 02packages";

my $dist_uri = $cpan->endpoint;
$dist_uri->path('authors/id/L/LO/LOCAL/Multi-Relevant-1.00.tar.gz');

ok LWP::Simple::get($dist_uri->as_string), "we have files in LOCAL's dir";

done_testing;
