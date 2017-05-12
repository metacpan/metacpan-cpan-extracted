use strict;
use POSIX qw(locale_h); BEGIN { setlocale(LC_MESSAGES,'en_US.UTF-8') } # avoid UTF-8 in $!
use Test::More;
use Test::Exception;
use Path::Tiny qw( path tempfile );
use App::migrate;


my @steps;
my @versions;
my $migrate = App::migrate->new;
$migrate->on(VERSION    => sub { push @versions, $_[0]->{version} });
$migrate->on(BACKUP     => sub {});
$migrate->on(RESTORE    => sub {});
$migrate->on(error      => sub {die});
my $file    = tempfile('migrate.XXXXXX');
$file->spew_utf8(<<'MIGRATE');
VERSION 0.0.0
VERSION 0.1.0
VERSION 0.2.0
upgrade true
RESTORE
VERSION 0.3.0
VERSION 0.4.0
VERSION 0.5.0
MIGRATE


lives_ok { $migrate->load($file) } 'load';

# bug was:
# optimization which skip all steps before RESTORE wasn't update
# "prev_version" of related steps
for my $from (qw( 0.5.0 0.3.0 0.4.0 )) {
    is_deeply [$migrate->get_steps($migrate->find_paths($from,'0.0.0'))], [
        ($from ge '0.5.0' ? {
            prev_version   => '0.5.0',
            next_version   => '0.4.0',
            type           => 'VERSION',
            version        => '0.4.0'
        } : ()),
        ($from ge '0.4.0' ? {
            prev_version   => '0.4.0',
            next_version   => '0.3.0',
            type           => 'VERSION',
            version        => '0.3.0'
        } : ()),
        {
            prev_version   => '0.3.0',
            next_version   => '0.2.0',
            type           => 'RESTORE',
            version        => '0.2.0'
        },
        {
            prev_version   => '0.3.0',
            next_version   => '0.2.0',
            type           => 'VERSION',
            version        => '0.2.0'
        },
        {
            prev_version   => '0.2.0',
            next_version   => '0.1.0',
            type           => 'VERSION',
            version        => '0.1.0'
        },
        {
            prev_version   => '0.1.0',
            next_version   => '0.0.0',
            type           => 'VERSION',
            version        => '0.0.0'
        },
    ], "get_steps: $from -> 0.0.0";
}

# bug was:
# run() wasn't affected by optimization
@versions = ();
$migrate->run(['0.5.0', '0.4.0', '0.3.0', '0.2.0', '0.1.0', '0.0.0']);
is_deeply \@versions, ['0.4.0', '0.3.0', '0.2.0', '0.1.0', '0.0.0'], "run: 0.5.0 -> 0.0.0";
@versions = ();
$migrate->run(['0.5.0', '0.4.0', '0.3.0']);
is_deeply \@versions, ['0.4.0', '0.3.0'], "run: 0.5.0 -> 0.3.0";


done_testing;
