use strict;
use warnings;
use Parallel::ForkManager;
use BusyBird::Input::Feed;
use open qw(:std :encoding(utf8));

my @feeds = (
    'https://metacpan.org/feed/recent?f=',
    'http://www.perl.com/pub/atom.xml',
    'https://github.com/perl-users-jp/perl-users.jp-htdocs/commits/master.atom',
);
my $MAX_PROCESSES = 10;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);
my $input = BusyBird::Input::Feed->new;

my @statuses = ();

$pm->run_on_finish(sub {
    my ($pid, $exitcode, $id, $signal, $coredump, $statuses) = @_;
    push @statuses, @$statuses;
});

foreach my $feed (@feeds) {
    $pm->start and next;
    warn "Start loading $feed\n";
    my $statuses = $input->parse_url($feed);
    warn "End loading $feed\n";
    $pm->finish(0, $statuses);
}
$pm->wait_all_children;

foreach my $status (@statuses) {
    print "$status->{user}{screen_name}: $status->{text}\n";
}
