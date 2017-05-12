use strict;
use warnings;

use Test::Most;

use CPAN::Local::Plugin::MailRc;
use CPAN::Index::API::File::MailRc;
use CPAN::Index::API::File::PackagesDetails;
use File::Temp  qw(tempdir);
use Path::Class qw(file dir);

my @mailrc_obj = map { CPAN::Index::API::File::MailRc->new(authors => $_) }
    [
        { authorid => 'FOO', name => 'Foo', email => 'foo@foo.com' },
        { authorid => 'BAR', name => 'Bar', email => 'bar@bar.com' },
    ],
    [
        { authorid => 'BAZ', name => 'Baz', email => 'baz@baz.com' },
        { authorid => 'QUZ', name => 'Quz', email => 'quz@quz.com' },
    ];

my $mailrc_dir = tempdir( CLEANUP => 0 );
my $root_dir   = tempdir( CLEANUP => 0 );

my @mailrc_files = (
    file($mailrc_dir, "mailrc_0.tar.gz")->stringify,
    file($mailrc_dir, "mailrc_1")->stringify,
);

$mailrc_obj[0]->write_to_tarball($mailrc_files[0]);
$mailrc_obj[1]->write_to_file($mailrc_files[1]);

my $packages_details = CPAN::Index::API::File::PackagesDetails->new(
    repo_path => $root_dir,
    packages  => [
        { name => 'A', version => '1.00', distribution => 'F/FO/FOO/A-1.00.tar.gz' },
        { name => 'B', version => '1.00', distribution => 'B/BA/BAR/B-1.00.tar.gz' },
        { name => 'C', version => '1.00', distribution => 'B/BA/BAZ/C-1.00.tar.gz' },
    ],
);

$packages_details->write_to_tarball;

my $plugin = CPAN::Local::Plugin::MailRc->new(
    root   => $root_dir,
    source => \@mailrc_files,
    distribution_class => 'CPAN::Local::Distribution',
);

$plugin->index;

my $combined_mailrc = CPAN::Index::API::File::MailRc->read_from_repo_path($root_dir);

is_deeply(
    [ $combined_mailrc->sorted_authors ],
    [
        { authorid => 'BAR', name => 'Bar', email => 'bar@bar.com' },
        { authorid => 'BAZ', name => 'Baz', email => 'baz@baz.com' },
        { authorid => 'FOO', name => 'Foo', email => 'foo@foo.com' },
    ],
    'mailrc records merged correctly'
);

done_testing;
