use Test::More tests => 19;
use Data::Page::Navigation;

#first
{
    my $total_entries=30;
    my $entries_per_page = 5;
    my $pages_per_navigation = 5;

    my $pager = Data::Page->new(
        $total_entries,
        $entries_per_page,
        2
    );
    
    #pages_per_navigation
    $pager->pages_per_navigation($pages_per_navigation);
    is($pager->pages_per_navigation,$pages_per_navigation,"first: class method: pages_per_navigation");
    
    is($pager->pages_per_navigation,$pages_per_navigation,"first: object method: pages_per_navigation");
    is_deeply([$pager->pages_in_navigation],[qw/1 2 3 4 5/],"first: pages_in_navigation p2");
    
    is_deeply(scalar $pager->pages_in_navigation, [qw/1 2 3 4 5/],"scalar context");
    
    #first/last_naviagtion_page
    is($pager->first_navigation_page,1,"first: first_navigation_page p2");
    is($pager->last_navigation_page,5,"first: last_navigation_page p2");

    #page change
    $pager->current_page(6);
    is_deeply([$pager->pages_in_navigation],[qw/2 3 4 5 6/],"first: pages_in_navigation p6");
    is($pager->first_navigation_page,2,"first: first_navigation_page p6");
    is($pager->last_navigation_page,6,"first: last_navigation_page p6");
}

#second
{
    my $total_entries=180;
    my $entries_per_page = 10;
    my $pages_per_navigation = 10;

    my $pager = Data::Page->new(
        $total_entries,
        $entries_per_page,
        2
    );

    #pages_per_navigation
    $pager->pages_per_navigation($pages_per_navigation);
    is($pager->pages_per_navigation,$pages_per_navigation,"first: class method: pages_per_navigation");
    
    is($pager->pages_per_navigation,$pages_per_navigation,"second: object method: pages_per_navigation");
    is_deeply([$pager->pages_in_navigation],[qw/1 2 3 4 5 6 7 8 9 10/],"second: pages_in_navigation p2");

    #first/last_naviagtion_page
    is($pager->first_navigation_page,1,"second: first_navigation_page p2");
    is($pager->last_navigation_page,10,"second: last_navigation_page p2");
    
    #page change
    $pager->current_page(9);
    is_deeply([$pager->pages_in_navigation],[qw/5 6 7 8 9 10 11 12 13 14/],"second: pages_in_navigation p9");
    is($pager->first_navigation_page,5,"second: first_navigation_page p9");
    is($pager->last_navigation_page,14,"second: last_navigation_page p9");
}

{
    my $total_entries=90;
    my $entries_per_page = 10;
    my $pages_per_navigation = 10;

    my $pager = Data::Page->new(
        $total_entries,
        $entries_per_page,
        1
    );
    $pager->pages_per_navigation($pages_per_navigation);
    is_deeply([$pager->pages_in_navigation],[qw/1 2 3 4 5 6 7 8 9/],"third: pages_in_navigation");    
    is_deeply(scalar $pager->pages_in_navigation, [qw/1 2 3 4 5 6 7 8 9/],"scalar context");
}
