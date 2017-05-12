use strict;
use warnings;
use lib "t";
use Test::More;
use BusyBird::Main;
use BusyBird::Main::PSGI qw(create_psgi_app);
use BusyBird::Log;
use BusyBird::StatusStorage::SQLite;
use Plack::Test;
use testlib::HTTP;
use testlib::Main_Util qw(create_main);

$BusyBird::Log::Logger = undef;

sub get_title {
    my ($html_tree) = @_;
    my ($title_node) = $html_tree->findnodes('//title');
    my ($title_text) = $title_node->content_list;
    return $title_text;
}

sub get_timeline_name_list {
    my ($html_tree) = @_;
    my @name_nodes = $html_tree->findnodes('//table[@id="bb-timeline-list"]//span[@class="bb-timeline-name"]');
    return map { ($_->content_list)[0] } @name_nodes;
}

note("----- static HTML view tests");

{
    my $main = create_main();
    $main->timeline('foo');
    $main->timeline('bar');
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        note('--- timeline view');
        foreach my $case (
            {path => '/timelines/foo', exp_timeline => 'foo'},
            {path => '/timelines/foo/', exp_timeline => 'foo'},
            {path => '/timelines/foo/index.html', exp_timeline => 'foo'},
            {path => '/timelines/foo/index.htm', exp_timeline => 'foo'},
            {path => '/timelines/bar/', exp_timeline => 'bar'},
        ) {
            my $tree = $tester->request_htmltree_ok('GET', $case->{path}, undef, qr/^200$/, "$case->{path}: GET OK");
            like(get_title($tree), qr/$case->{exp_timeline}/, '... View title OK');
        }

        note('--- not found cases');
        foreach my $case (
            {path => '/timelines/buzz'},
            {path => '/timelines/home/index.html'},
            {path => '/timelines/foo/index.json'},
            {path => '/timelines/'},
            {path => '/timelines'},
        ) {
            $tester->request_ok('GET', $case->{path}, undef, qr/^404$/, "$case->{path}: not found OK");
        }
    };
}

{
    my $main = create_main();
    note('--- weird timeline cases');
    foreach my $case (
        {name => 'myline.old', path => '/timelines/myline.old', title => qr/myline\.old/},
        {name => 'A & B', path => '/timelines/A+%26+B', title => qr/A \&amp\; B/ },
        {name => q{"that's weird"}, path => '/timelines/%22that%27s+weird%22', title => qr{\&quot;that(\'|\&apos;|\&\#39;)s weird\&quot;}},
        {name => '<><>', path => '/timelines/%3C%3E%3C%3E/', title => qr{&lt;&gt;&lt;&gt;}},

        #### The following won't work because HTTP::Message::PSGI::req_to_psgi automatically URI-unescapes %2F into /,
        #### so the router cannot extract the timeline name.
        ## {name => '/', path => '/timelines/%2F', title => qr{/}},
    ) {
        $main->timeline($case->{name});
        test_psgi create_psgi_app($main), sub {
            my $tester = testlib::HTTP->new(requester => shift);
            my $tree = $tester->request_htmltree_ok('GET', $case->{path}, undef, qr/^200$/, "$case->{name}: GET OK");
            like(get_title($tree), $case->{title}, "$case->{name}: title OK");
            $main->uninstall_timeline($case->{name});
            $tester->request_ok('GET', $case->{path}, undef, qr/^404$/, "$case->{name}: uninstalled OK");
        };
    }
}

{
    my $main = create_main();
    $main->timeline($_) foreach 1..12;
    $main->set_config(timeline_list_per_page => 5);
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        
        note("--- timeline list view (page param and selection of timelines)");
        foreach my $case (
            {label => "root", path => '/', exp_timelines => [1 .. 5]},
            {label => "index.html", path => '/index.html', exp_timelines => [1 .. 5]},
            {label => "root 0", path => '/?page=0', exp_timelines => [1 .. 5]},
            {label => "index.html 1", path => '/index.html?page=1', exp_timelines => [6 .. 10]},
            {label => "root 2", path => '/index.html?page=2', exp_timelines => [11 .. 12]}
        ) {
            note("--- -- case $case->{label}");
            my $tree = $tester->request_htmltree_ok('GET', $case->{path}, undef, qr/^200$/, "GET OK");
            my @names = get_timeline_name_list($tree);
            is_deeply(\@names, $case->{exp_timelines}, "timeline names OK");
        };

        note("--- timeline list view (invalid requests)");
        foreach my $case (
            {label => 'negative page', path => '/?page=-1'},
            {label => 'too large page number', path => '/?page=5'},
            {label => 'string page', path => '/?page=hoge'},
            {label => 'empty page', path => '/?page='},
        ) {
            note("--- -- case $case->{label}");
            $tester->request_ok("GET", $case->{path}, undef, qr/^[45]/, "GET fails OK");
        }
    };
}

{
    note("-- hidden timelines in list view");
    my $main = create_main();
    $main->timeline("hidden1")->set_config(hidden => 1);
    $main->timeline("visible1");
    $main->timeline("hidden2")->set_config(hidden => 1);
    $main->timeline("visible2");
    test_psgi create_psgi_app($main), sub {
        my $tester = testlib::HTTP->new(requester => shift);
        my $tree = $tester->request_htmltree_ok('GET', "/", undef, qr/^200$/, "GET OK");
        my @got_names = get_timeline_name_list($tree);
        is_deeply \@got_names, [qw(visible1 visible2)], "hidden timelines are hidden from the list";
    };
}

done_testing();

