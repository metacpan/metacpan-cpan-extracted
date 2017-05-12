package CGI::Widget::DBI::TEST::Browse;

use strict;
use CGI::Widget::DBI::TEST::TestCase;
use base qw/ CGI::Widget::DBI::TEST::TestCase /;

use CGI::Widget::DBI::Browse;

sub init_test_object
{
    my $self = shift;
    my $q = CGI->new;
    $self->{_test_obj} = $self->{wb} = CGI::Widget::DBI::Browse->new(
        q => $q, -dbh => $self->{-dbh},
        -sql_table => 'cities left outer join cities_join using (city_no)',
        -sql_retrieve_columns => [
            qw/city_no name description population cities.state_or_province/,
            'coalesce(cities.country, cities.state_or_province) as nation'
        ],
        -cache_categories => $ENV{CACHE_CATEGORIES},
        _DEBUG => 0,
    );
    $self->{wb}->{-category_columns} = [ qw/continent nation state_or_province/ ];
    $self->{wb}->{-category_sql_retrieve_columns} = { state_or_province => [qw/nation/] };
    $self->{wb}->{-category_column_closures} = {
        state_or_province => sub {
            my ($obj, $row) = @_;
            return $row->{'state_or_province'}.', '.$row->{'nation'};
        },
    };
}

sub tear_down
{
    my $self = shift;
    $self->{-dbh}->do('DROP TABLE IF EXISTS browse_widget_category_cache');
    $self->SUPER::tear_down();
}

sub _db_schemas {
    my @schemas = (<<'DDL1', <<'DDL2');
create temporary table cities (
  city_no            integer     not null primary key auto_increment,
  continent          varchar(16),
  country            varchar(24),
  state_or_province  varchar(24),
  name               varchar(32),
  description        text,
  population         integer,

  index continent (continent),
  index country (country),
  index state_or_province (state_or_province)
)
DDL1
create temporary table cities_join (
  city_no            int,
  state_or_province  varchar(24)
)
DDL2
    # second table is an empty table just to test two columns with same name
    return @schemas;
}

sub _insert_test_data {
    my ($self) = @_;
    my $sth1 = $self->{-dbh}->prepare_cached(q{
        insert into
            cities (city_no, continent, country, state_or_province, name, description, population)
        values (?, ?, ?, ?, ?, ?, ?)
    });
    map {
        $sth1->execute(@$_);
    } (
        [  1, 'Africa',        'Madagascar',    'Antananarivo',     'Antananarivo',  'Capital of Madagascar',                                           1_403_449 ],
        [  2, 'Africa',        undef,           undef,              'Sahara Desert', 'Largest desert in the world',                                            13 ],
        [  3, 'Asia',          'Japan',         'Kanto',            'Tokyo',         'Largest city in the world',                                      34_450_000 ],
        [  4, 'Asia',          'India',         'Maharashtra',      'Mumbai',        'Largest city in India, capital of western state of Maharashtra', 19_380_000 ],
        [  5, 'Asia',          'Thailand',      'Bangkok',          'Bangkok',       'City with the longest full name in the world',                    8_190_000 ],
        [  6, 'Australia',     'Australia',     'Victoria',         'Melbourne',     'State capital of Victoria, second largest city in Australia',     3_340_000 ],
        [  7, 'Europe',        'Norway',        'Oslo',             'Oslo',          'Capital of Norway',                                                 548_617 ],
        [  8, 'Europe',        'Denmark',       'Oresund',          'Copenhagen',    'Second most livable city in the world',                           1_835_467 ],
        [  9, 'Europe',        'Italy',         'Lombardy',         'Milan',         'Fashion capital of the world',                                    4_950_000 ],
        [ 10, 'North America', 'Canada',        'British Columbia', 'Vancouver',     'Beautiful B.C.',                                                  2_249_725 ],
        [ 11, 'North America', 'United States', 'New York',         'New York',      'Financial capital of the world',                                 20_420_000 ],
        [ 12, 'North America', 'United States', 'New York',         'Ithaca',        'Ithaca is Gorges',                                                  100_018 ],
        [ 13, 'North America', 'United States', 'Oregon',           'Portland',      'Microbrew capital of the world',                                  1_583_138 ],
        [ 14, 'South America', 'Brazil',        'Sao Paulo',        'Sao Paulo',     'Most populous city in South America',                            18_130_000 ],
        [ 15, 'South America', 'Argentina',     '(federal)',        'Buenos Aires',  'Capital of Argentina',                                           13_460_000 ],
    );

    $self->assert_table_contents_equal(
        'cities', [qw/city_no continent country state_or_province name description population/],
        [
            [  1, 'Africa',        'Madagascar',    'Antananarivo',     'Antananarivo',  'Capital of Madagascar',                                           1_403_449 ],
            [  2, 'Africa',        undef,           undef,              'Sahara Desert', 'Largest desert in the world',                                            13 ],
            [  3, 'Asia',          'Japan',         'Kanto',            'Tokyo',         'Largest city in the world',                                      34_450_000 ],
            [  4, 'Asia',          'India',         'Maharashtra',      'Mumbai',        'Largest city in India, capital of western state of Maharashtra', 19_380_000 ],
            [  5, 'Asia',          'Thailand',      'Bangkok',          'Bangkok',       'City with the longest full name in the world',                    8_190_000 ],
            [  6, 'Australia',     'Australia',     'Victoria',         'Melbourne',     'State capital of Victoria, second largest city in Australia',     3_340_000 ],
            [  7, 'Europe',        'Norway',        'Oslo',             'Oslo',          'Capital of Norway',                                                 548_617 ],
            [  8, 'Europe',        'Denmark',       'Oresund',          'Copenhagen',    'Second most livable city in the world',                           1_835_467 ],
            [  9, 'Europe',        'Italy',         'Lombardy',         'Milan',         'Fashion capital of the world',                                    4_950_000 ],
            [ 10, 'North America', 'Canada',        'British Columbia', 'Vancouver',     'Beautiful B.C.',                                                  2_249_725 ],
            [ 11, 'North America', 'United States', 'New York',         'New York',      'Financial capital of the world',                                 20_420_000 ],
            [ 12, 'North America', 'United States', 'New York',         'Ithaca',        'Ithaca is Gorges',                                                  100_018 ],
            [ 13, 'North America', 'United States', 'Oregon',           'Portland',      'Microbrew capital of the world',                                  1_583_138 ],
            [ 14, 'South America', 'Brazil',        'Sao Paulo',        'Sao Paulo',     'Most populous city in South America',                            18_130_000 ],
            [ 15, 'South America', 'Argentina',     '(federal)',        'Buenos Aires',  'Capital of Argentina',                                           13_460_000 ],
        ],
    );
}


sub test_display__top_level
{
    my $self = shift;

    # TODO: make the test for id="categoryNavLink" independent of attribute order in <a> tag
    $self->assert_display_contains(
        [ 'tr', 'td' ],

        [ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*',       'Africa'    ],
        [ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*',           'Asia'      ],
        [ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'continent=Europe[^<>]+id="categoryNavLink-Europe".*',       'Europe'    ],

        [ 'td', 'tr', 'tr', 'td' ],

        [ 'continent=North%20America[^<>]+id="categoryNavLink-North America".*', 'North America' ],
        [ 'continent=South%20America[^<>]+id="categoryNavLink-South America".*', 'South America' ],

        [ 'td', 'tr' ],
    );
    $self->assert_equals('', $self->{wb}->category_title());

    $self->assert_display_does_not_contain([ 'input type="hidden' ]);
    $self->assert_display_does_not_contain([ 'At first page', 'At last page' ]);
    $self->assert_display_does_not_contain([ 'Sort by', 'sortby_columns_popup' ]);
    $self->assert_display_does_not_contain([ 'Sort field' ]);

    $self->assert_equals('continent', $self->{wb}->is_browsing());
    $self->assert(! $self->{wb}->parent_category_column());
    $self->assert_deep_equals([], [$self->{wb}->ancestor_category_columns()]);
}

sub test_display__top_level__works_with_stray_sortby_param
{
    my $self = shift;
    $self->{wb}->{q}->param('sortby', 'nation');
    $self->test_display__top_level();
}

sub test_display__top_level__uses_href_extra_vars_for_category_nav_links
{
    my $self = shift;
    $self->{wb}->{q}->param('href_testvar', 'foo');
    $self->{wb}->{ws}->{-href_extra_vars} = { href_testvar => undef };

    $self->test_display__top_level();

    $self->assert_display_contains(
        [ 'continent=Africa\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Africa".*',                 'Africa'        ],
        [ 'continent=Asia\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Asia".*',                     'Asia'          ],
        [ 'continent=Australia\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Australia".*',           'Australia'     ],
        [ 'continent=Europe\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Europe".*',                 'Europe'        ],
        [ 'continent=North%20America\S*&href_testvar=foo"[^<>]+id="categoryNavLink-North America".*', 'North America' ],
        [ 'continent=South%20America\S*&href_testvar=foo"[^<>]+id="categoryNavLink-South America".*', 'South America' ],
    );
}

sub test_display__top_level__creates_category_cache_table
{
    my $self = shift;
    local $ENV{CACHE_CATEGORIES} = 1;
    $self->init_test_object();

    $self->test_display__top_level();

    $self->assert_table_contents_equal(
        'browse_widget_category_cache', [qw/category_column category_value child_value/],
        [
            [ undef, undef, 'Africa'        ],
            [ undef, undef, 'Asia'          ],
            [ undef, undef, 'Australia'     ],
            [ undef, undef, 'Europe'        ],
            [ undef, undef, 'North America' ],
            [ undef, undef, 'South America' ],
        ],
    );

    # test again to verify cached results show up
    $self->init_test_object();
    $self->test_display__top_level();
}

sub test_display__second_level
{
    my $self = shift;
    my $wb = $self->{wb};

    $wb->{q}->param('continent', 'Africa');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'continent=Africa&_browse_skip_to_results_=1"[^<>]+id="skipToResultsLink',
          "Show all items in this category" ],
        [ 'input type="hidden" name="continent" value="Africa' ],
        [ 'tr', 'td' ],
        [ 'continent=Africa&nation=Madagascar[^<>]+id="categoryNavLink-Madagascar".*', 'Madagascar' ],
        [ 'td', 'tr' ],
    );
    # test does not contain NULL category
    $self->assert_display_does_not_contain([ 'a href="\?continent=Africa&nation=" id="categoryNavLink-Africa"></a' ]);
    $self->assert_equals('Africa', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Asia');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Asia' ],
        [ 'tr', 'td' ],
        [ 'continent=Asia&nation=India[^<>]+id="categoryNavLink-India".*', 'India' ],
        [ 'continent=Asia&nation=Japan[^<>]+id="categoryNavLink-Japan".*', 'Japan' ],
        [ 'continent=Asia&nation=Thailand[^<>]+id="categoryNavLink-Thailand".*', 'Thailand' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('Asia', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Australia');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Australia' ],
        [ 'tr', 'td' ],
        [ 'continent=Australia&nation=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('Australia', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Europe');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Europe' ],
        [ 'tr', 'td' ],
        [ 'continent=Europe&nation=Denmark[^<>]+id="categoryNavLink-Denmark".*', 'Denmark' ],
        [ 'continent=Europe&nation=Italy[^<>]+id="categoryNavLink-Italy".*', 'Italy' ],
        [ 'continent=Europe&nation=Norway[^<>]+id="categoryNavLink-Norway".*', 'Norway' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('Europe', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'North America');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="North America' ],
        [ 'tr', 'td' ],
        [ 'continent=North%20America&nation=Canada[^<>]+id="categoryNavLink-Canada".*', 'Canada' ],
        [ 'continent=North%20America&nation=United%20States[^<>]+id="categoryNavLink-United States".*', 'United States' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('North America', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'South America');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="South America' ],
        [ 'tr', 'td' ],
        [ 'continent=South%20America&nation=Argentina[^<>]+id="categoryNavLink-Argentina".*', 'Argentina' ],
        [ 'continent=South%20America&nation=Brazil[^<>]+id="categoryNavLink-Brazil".*', 'Brazil' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('South America', $wb->category_title());

    $self->assert_display_does_not_contain([ 'At first page', 'At last page' ]);
    $self->assert_display_does_not_contain([ 'Sort by', 'sortby_columns_popup' ]);
    $self->assert_display_does_not_contain([ 'Sort field' ]);
}

sub test_display__second_level__uses_href_extra_vars_for_category_nav_links
{
    my $self = shift;
    $self->{wb}->{q}->param('href_testvar', 'foo');
    $self->{wb}->{ws}->{-href_extra_vars} = { href_testvar => undef };

    $self->{wb}->{q}->param('continent', 'South America');

    $self->assert_display_contains(
        [ 'continent=South%20America&nation=Argentina\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Argentina".*', 'Argentina' ],
        [ 'continent=South%20America&nation=Brazil\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Brazil".*',    'Brazil'    ],
    );
    $self->assert_display_does_not_contain(
        [ 'continent=South%20America\S*continent=South%20America[^<>]+id="categoryNavLink-' ],
    );
    $self->assert_display_does_not_contain(
        [ 'nation=Brazil\S*nation=Brazil[^<>]+id="categoryNavLink-' ],
    );
}

sub test_display__second_level__creates_category_cache_table
{
    my $self = shift;
    local $ENV{CACHE_CATEGORIES} = 1;
    $self->init_test_object();

    $self->test_display__second_level();

    $self->assert_table_contents_equal(
        'browse_widget_category_cache', [qw/category_column category_value child_value/],
        [
            [ 'continent', 'Africa',        'Madagascar',    ],
            [ 'continent', 'Asia',          'India',         ],
            [ 'continent', 'Asia',          'Japan',         ],
            [ 'continent', 'Asia',          'Thailand',      ],
            [ 'continent', 'Australia',     'Australia',     ],
            [ 'continent', 'Europe',        'Denmark',       ],
            [ 'continent', 'Europe',        'Italy',         ],
            [ 'continent', 'Europe',        'Norway',        ],
            [ 'continent', 'North America', 'Canada',        ],
            [ 'continent', 'North America', 'United States', ],
            [ 'continent', 'South America', 'Argentina',     ],
            [ 'continent', 'South America', 'Brazil',        ],
        ],
    );

    # test again to verify cached results show up
    $self->init_test_object();
    $self->test_display__second_level();
}

sub test_display__third_level
{
    my $self = shift;
    my $wb = $self->{wb};

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');

    $self->assert_equals('state_or_province', $wb->is_browsing());
    $self->assert_equals('nation', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="North America' ],
        [ 'input type="hidden" name="nation" value="United States' ],
        [ 'tr', 'td' ],
        [ 'continent=North%20America&nation=United%20States&state_or_province=New%20York[^<>]+id="categoryNavLink-New York".*', 'New York, United States' ],
        [ 'continent=North%20America&nation=United%20States&state_or_province=Oregon[^<>]+id="categoryNavLink-Oregon".*', 'Oregon, United States' ],
        [ 'td', 'tr' ],
    );
    # test New York not listed twice
    $self->assert_display_does_not_contain(
        [ 'state_or_province=New%20York', 'New York' ],
        [ 'New York' ],
        [ 'state_or_province=New%20York', 'New York' ],
        [ 'New York' ],
    );
    $self->assert_equals('North America > United States', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Asia');
    $wb->{q}->param('nation', 'India');

    $self->assert_equals('state_or_province', $wb->is_browsing());
    $self->assert_equals('nation', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Asia' ],
        [ 'input type="hidden" name="nation" value="India' ],
        [ 'tr', 'td' ],
        [ 'continent=Asia&nation=India&state_or_province=Maharashtra[^<>]+id="categoryNavLink-Maharashtra".*', 'Maharashtra, India' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('Asia > India', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Asia');
    $wb->{q}->param('nation', 'Japan');

    $self->assert_equals('state_or_province', $wb->is_browsing());
    $self->assert_equals('nation', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Asia' ],
        [ 'input type="hidden" name="nation" value="Japan' ],
        [ 'tr', 'td' ],
        [ 'continent=Asia&nation=Japan&state_or_province=Kanto[^<>]+id="categoryNavLink-Kanto".*', 'Kanto, Japan' ],
        [ 'td', 'tr' ],
    );
    $self->assert_equals('Asia > Japan', $wb->category_title());

    $self->assert_display_does_not_contain([ 'At first page', 'At last page' ]);
    $self->assert_display_does_not_contain([ 'Sort by', 'sortby_columns_popup' ]);
    $self->assert_display_does_not_contain([ 'Sort field' ]);
}

sub test_display__third_level__uses_href_extra_vars_for_category_nav_links
{
    my $self = shift;
    $self->{wb}->{q}->param('href_testvar', 'foo');
    $self->{wb}->{ws}->{-href_extra_vars} = { href_testvar => undef };

    $self->{wb}->{q}->param('continent', 'Asia');
    $self->{wb}->{q}->param('nation', 'Japan');

    $self->assert_display_contains(
        [ 'continent=Asia&nation=Japan&state_or_province=Kanto\S*&href_testvar=foo"[^<>]+id="categoryNavLink-Kanto".*', 'Kanto, Japan' ],
    );
    $self->assert_display_does_not_contain(
        [ 'continent=Asia\S*continent=Asia[^<>]+id="categoryNavLink-' ],
    );
    $self->assert_display_does_not_contain(
        [ 'nation=Japan\S*nation=Japan[^<>]+id="categoryNavLink-' ],
    );
    $self->assert_display_does_not_contain(
        [ 'state_or_province=Kanto\S*state_or_province=Kanto[^<>]+id="categoryNavLink-' ],
    );
}

sub test_display__third_level__creates_category_cache_table
{
    my $self = shift;
    local $ENV{CACHE_CATEGORIES} = 1;
    $self->init_test_object();

    $self->test_display__third_level();

    $self->assert_table_contents_equal(
        'browse_widget_category_cache', [qw/category_column category_value child_value/],
        [
            [ 'nation', 'India',         'Maharashtra', ],
            [ 'nation', 'Japan',         'Kanto',       ],
            [ 'nation', 'United States', 'New York',    ],
            [ 'nation', 'United States', 'Oregon',      ],
        ],
    );

    # test again to verify cached results show up
    $self->init_test_object();
    $self->test_display__third_level();
}

sub test_display__paging_category_navigation
{
    my $self = shift;
    my $wb = $self->{wb};
    $wb->{-max_category_results_per_page} = 3;

    # multi-page browse of categories: that paging links do show up, and
    # that correct total num_results shows
    $self->assert_display_contains(
        [ 'At first page', '3', 'results displayed', '1 - 3', 'of', '6', 'search_startat=1', 'Next &gt' ],
        [ 'tr', 'td' ],
        [ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*', 'Africa' ],
        [ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*', 'Asia' ],
        [ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'search_startat=1', 'Next &gt' ],
    );
    $self->assert_display_does_not_contain([ 'continent=Europe[^<>]+id="categoryNavLink-Europe".*', 'Europe' ]);
    $self->assert_display_does_not_contain([ 'continent=North%20America[^<>]+id="categoryNavLink-North America".*', 'North America' ]);
    $self->assert_display_does_not_contain([ 'continent=South%20America[^<>]+id="categoryNavLink-South America".*', 'South America' ]);
    $self->assert_display_does_not_contain([ 'Sort by', 'sortby_columns_popup' ]);
    $self->assert_display_does_not_contain([ 'Sort field' ]);

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{-max_category_results_per_page} = 3;
    $wb->{q}->param('search_startat', 1);

    $self->assert_display_contains(
        [ 'search_startat=0', 'lt; Previous', '3', 'results displayed', '4 - 6', 'of', '6', 'At last page', ],
        [ 'tr', 'td' ],
        [ 'continent=Europe[^<>]+id="categoryNavLink-Europe".*', 'Europe' ],
        [ 'continent=North%20America[^<>]+id="categoryNavLink-North America".*', 'North America' ],
        [ 'continent=South%20America[^<>]+id="categoryNavLink-South America".*', 'South America' ],
        [ 'td', 'tr' ],
        [ 'search_startat=0', 'lt; Previous', 'At last page', ],
    );
    $self->assert_display_does_not_contain([ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*', 'Africa' ]);
    $self->assert_display_does_not_contain([ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*', 'Asia' ]);
    $self->assert_display_does_not_contain([ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ]);

    # test 'Top' breadcrumb does not get repeatedly prepended to -optional_header
    $self->assert_display_does_not_contain([ 'breadcrumbNavLink', 'Top', 'breadcrumbNavLink', 'Top' ]);
}

sub test_display__skip_to_results_from_category_navigation
{
    my $self = shift;
    my $wb = $self->{wb};

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{-skip_to_results} = 1;

    $self->assert(! $wb->is_browsing());
    $self->assert_equals('state_or_province', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation state_or_province/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="North America' ],
        [ 'input type="hidden" name="nation" value="United States' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'sortby=city_no', 'continent=North%20America', 'city_no' ],
        [ 'sortby=name', 'nation=United%20States', 'name' ],
        [ 'sortby=population', 'continent=North%20America', 'population' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'New York', 'Financial capital of the world', 20_420_000 ],
        [ 'Ithaca', 'Ithaca is Gorges', 100_018 ],
        [ 'Portland', 'Microbrew capital of the world', 1_583_138 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_equals('North America > United States', $wb->category_title());

    $self->assert_display_does_not_contain(
        [ 'continent=North%20America&nation=United%20States&state_or_province=New%20York[^<>]+id="categoryNavLink-New York".*', 'New York' ],
    );
    $self->assert_display_does_not_contain(
        [ 'continent=North%20America&nation=United%20States&state_or_province=Oregon[^<>]+id="categoryNavLink-Oregon".*', 'Oregon' ],
    );
    $self->assert_display_does_not_contain([ 'categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Asia');
    $wb->{q}->param('_browse_skip_to_results_', 1);

    $self->assert(! $wb->is_browsing());
    $self->assert_equals('state_or_province', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation state_or_province/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        # test for hidden _browse_skip_to_results_: required for persistent results where subclasses submit form
        [ 'input type="hidden" name="_browse_skip_to_results_" value="1' ],
        [ 'input type="hidden" name="continent" value="Asia' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'sortby=city_no', 'continent=Asia', 'city_no' ],
        [ 'sortby=name', 'continent=Asia', 'name' ],
        [ 'sortby=population', 'continent=Asia', 'population' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Tokyo', 'Largest city in the world', 34_450_000 ],
        [ 'Mumbai', 'Largest city in India, capital of western state of Maharashtra', 19_380_000 ],
        [ 'Bangkok', 'City with the longest full name in the world', 8_190_000 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_equals('Asia (all results)', $wb->category_title());

    $self->assert_display_does_not_contain([ 'input type="hidden" name="nation' ]);
    $self->assert_display_does_not_contain([ 'continent=Asia[^<>]+id="categoryNavLink-', 'Japan' ]);
    $self->assert_display_does_not_contain([ 'continent=Asia[^<>]+id="categoryNavLink-', 'India' ]);
    $self->assert_display_does_not_contain([ 'continent=Asia[^<>]+id="categoryNavLink-', 'Thailand' ]);
}

sub test_display__auto_skip_to_results_from_category_navigation
{
    my $self = shift;
    my $wb = $self->{wb};

    my $sth1 = $self->{-dbh}->prepare_cached(q{
        insert into cities (continent, country, name, description) values (?, ?, ?, ?)
    });
    $sth1->execute('Antarctica', undef, 'Penguin Camp 1', 'Home of Linux');
    $sth1->execute('Pacific Ocean', '', 'Tahiti Village', 'Pacific island village of Tahiti');
    $sth1->execute('Pacific Ocean', '', 'Samoa', 'Pacific island of Samoa');
    $sth1->execute('Atlantic Ocean', ' ***** ', 'Trade winds', 'Atlantic hurricane central');
    # end setup

    $wb->{q}->param('continent', 'Antarctica');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_display_contains(
        [ 'continent=Antarctica&_browse_skip_to_results_=1"[^<>]+id="skipToResultsLink',
          "Show all items in this category" ],
        [ 'input type="hidden" name="continent" value="Antarctica' ],
    );
    $self->assert_display_does_not_contain(['Penguin Camp 1']);
    $self->assert_display_does_not_contain(['Home of Linux']);

    $self->assert_equals('Antarctica', $wb->category_title());

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{-auto_skip_to_results} = 1; # enable auto_skip_to_results feature

    $wb->{q}->param('continent', 'Antarctica');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Antarctica' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],

        [ 'sortby=city_no',           'continent=Antarctica', 'city_no'           ],
        [ 'sortby=name',              'continent=Antarctica', 'name'              ],
        [ 'sortby=description',       'continent=Antarctica', 'description'       ],
        [ 'sortby=population',        'continent=Antarctica', 'population'        ],
        [ 'sortby=state_or_province', 'continent=Antarctica', 'state_or_province' ],
        [ 'sortby=nation',            'continent=Antarctica', 'nation'            ],

        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Penguin Camp 1', 'Home of Linux' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );

    # note that these changed after $wb->search, since we detected no category members and skipped to results
    $self->assert(! $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_equals('Antarctica', $wb->category_title());

    $self->assert_display_does_not_contain([ 'categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{-auto_skip_to_results} = 1; # enable auto_skip_to_results feature

    $wb->{q}->param('continent', 'Pacific Ocean');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Pacific Ocean' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],

        [ 'sortby=city_no',           'continent=Pacific%20Ocean', 'city_no'           ],
        [ 'sortby=name',              'continent=Pacific%20Ocean', 'name'              ],
        [ 'sortby=description',       'continent=Pacific%20Ocean', 'description'       ],
        [ 'sortby=population',        'continent=Pacific%20Ocean', 'population'        ],
        [ 'sortby=state_or_province', 'continent=Pacific%20Ocean', 'state_or_province' ],
        [ 'sortby=nation',            'continent=Pacific%20Ocean', 'nation'            ],

        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Tahiti Village', 'Pacific island village of Tahiti' ],
        [ 'Samoa', 'Pacific island of Samoa' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );

    # note that these changed after $wb->search, since we detected no category members and skipped to results
    $self->assert(! $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_equals('Pacific Ocean', $wb->category_title());

    $self->assert_display_does_not_contain([ 'categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{-auto_skip_to_results} = 1; # enable auto_skip_to_results feature

    $wb->{q}->param('continent', 'Atlantic Ocean');

    $self->assert_equals('nation', $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Atlantic Ocean' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],

        [ 'sortby=city_no',           'continent=Atlantic%20Ocean', 'city_no'           ],
        [ 'sortby=name',              'continent=Atlantic%20Ocean', 'name'              ],
        [ 'sortby=description',       'continent=Atlantic%20Ocean', 'description'       ],
        [ 'sortby=population',        'continent=Atlantic%20Ocean', 'population'        ],
        [ 'sortby=state_or_province', 'continent=Atlantic%20Ocean', 'state_or_province' ],
        [ 'sortby=nation',            'continent=Atlantic%20Ocean', 'nation'            ],

        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Trade winds', 'Atlantic hurricane central' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );

    # note that these changed after $wb->search, since we detected no category members and skipped to results
    $self->assert(! $wb->is_browsing());
    $self->assert_equals('continent', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent/], [$self->{wb}->ancestor_category_columns()]);

    $self->assert_equals('Atlantic Ocean', $wb->category_title());

    $self->assert_display_does_not_contain([ 'categoryNavLink-' ]);
}

sub test_display__records_aka_leaf_nodes
{
    my $self = shift;
    my $wb = $self->{wb};

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{q}->param('state_or_province', 'Oregon');

    $self->assert(! $wb->is_browsing());
    $self->assert_equals('state_or_province', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation state_or_province/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="North America' ],
        [ 'input type="hidden" name="nation" value="United States' ],
        [ 'input type="hidden" name="state_or_province" value="Oregon' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'sortby=city_no', 'state_or_province=Oregon', 'city_no' ],
        [ 'sortby=name', 'nation=United%20States', 'name' ],
        [ 'sortby=population', 'continent=North%20America', 'population' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Portland', 'Microbrew capital of the world', 1_583_138 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_equals('North America > United States > Oregon (results)', $wb->category_title());

    $self->assert_display_does_not_contain([ 'continent=North%20America', 'id="categoryNavLink-'  ]);
    $self->assert_display_does_not_contain([ 'nation=United%20States', 'id="categoryNavLink-' ]);
    $self->assert_display_does_not_contain([ 'state_or_province=Oregon', 'id="categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{q}->param('state_or_province', 'New York');

    $self->assert(! $wb->is_browsing());
    $self->assert_equals('state_or_province', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation state_or_province/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="North America' ],
        [ 'input type="hidden" name="nation" value="United States' ],
        [ 'input type="hidden" name="state_or_province" value="New York' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'sortby=city_no', 'state_or_province=New%20York', 'city_no' ],
        [ 'sortby=name', 'nation=United%20States', 'name' ],
        [ 'sortby=population', 'continent=North%20America', 'population' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'New York', 'Financial capital of the world', 20_420_000 ],
        [ 'Ithaca', 'Ithaca is Gorges', 100_018 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_equals('North America > United States > New York (results)', $wb->category_title());

    $self->assert_display_does_not_contain([ 'state_or_province=New%20York', 'id="categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Asia');
    $wb->{q}->param('nation', 'India');
    $wb->{q}->param('state_or_province', 'Maharashtra');

    $self->assert(! $wb->is_browsing());
    $self->assert_equals('state_or_province', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation state_or_province/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Asia' ],
        [ 'input type="hidden" name="nation" value="India' ],
        [ 'input type="hidden" name="state_or_province" value="Maharashtra' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'sortby=city_no', 'continent=Asia', 'city_no' ],
        [ 'sortby=name', 'nation=India', 'name' ],
        [ 'sortby=population', 'state_or_province=Maharashtra', 'population' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Mumbai', 'Largest city in India, capital of western state of Maharashtra', 19_380_000 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_equals('Asia > India > Maharashtra (results)', $wb->category_title());

    $self->assert_display_does_not_contain([ 'continent=Asia', 'id="categoryNavLink-' ]);
    $self->assert_display_does_not_contain([ 'nation=India', 'id="categoryNavLink-' ]);
    $self->assert_display_does_not_contain([ 'state_or_province=Maharashtra', 'id="categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{q}->param('continent', 'Asia');
    $wb->{q}->param('nation', 'Japan');
    $wb->{q}->param('state_or_province', 'Kanto');

    $self->assert(! $wb->is_browsing());
    $self->assert_equals('state_or_province', $wb->parent_category_column());
    $self->assert_deep_equals([qw/continent nation state_or_province/], [$self->{wb}->ancestor_category_columns()]);
    $self->assert_display_contains(
        [ 'input type="hidden" name="continent" value="Asia' ],
        [ 'input type="hidden" name="nation" value="Japan' ],
        [ 'input type="hidden" name="state_or_province" value="Kanto' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'sortby=city_no', 'state_or_province=Kanto', 'city_no' ],
        [ 'sortby=name', 'state_or_province=Kanto', 'name' ],
        [ 'sortby=population', 'state_or_province=Kanto', 'population' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Tokyo', 'Largest city in the world', 34_450_000 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_equals('Asia > Japan > Kanto (results)', $wb->category_title());

    $self->assert_display_does_not_contain([ 'continent=Asia', 'id="categoryNavLink-' ]);
    $self->assert_display_does_not_contain([ 'nation=Japan', 'id="categoryNavLink-' ]);
    $self->assert_display_does_not_contain([ 'state_or_province=Kanto', 'id="categoryNavLink-' ]);
}

sub test_display__records_with_column_using_link_for_category_column
{
    my $self = shift;
    my $wb = $self->{wb};
    $wb->{q}->param('href_testvar', 'foo');
    $wb->{q}->param('href_testvar2', 'bar');
    $wb->{ws}->{-href_extra_vars} = { href_testvar => undef, href_testvar2 => undef };

    $wb->{ws}->{-columndata_closures}->{'state_or_province'} = sub {
        my ($obj, $row) = @_;
        return $obj->{b}->link_for_category_column('state_or_province', $row, 'href_testvar2');
    };
    # note: for this to work correctly, all category columns must be retrieved in
    #  -sql_retrieve_columns, so we have to add 'continent' since it is not retrieved by default
    push(@{ $wb->{ws}->{-sql_retrieve_columns} }, 'continent');

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{q}->param('state_or_province', 'Oregon');

    $self->assert_display_contains(
        [ 'Portland', 'Microbrew capital of the world', 1_583_138,
          'a href="\?continent=North%20America&nation=United%20States&state_or_province=Oregon\S*&href_testvar=foo" id="jumpToCategoryLink"[^<>]*>Oregon' ],
    );
    $self->assert_display_does_not_contain([ '[^<>]*href_testvar2[^<>]*id="jumpToCategoryLink'       ] );
    $self->assert_display_does_not_contain([ 'continent=North%20America\S*continent=North%20America' ] );
    $self->assert_display_does_not_contain([ 'nation=United%20States\S*nation=United%20States'       ] );
    $self->assert_display_does_not_contain([ 'state_or_province=Oregon\S*state_or_province=Oregon'   ] );
}

sub test_display__paging_records
{
    my $self = shift;
    my $wb = $self->{wb};
    $wb->{ws}->{-max_results_per_page} = 1;

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{q}->param('state_or_province', 'New York');
    $self->assert_display_contains(
        [ 'At first page', 'search_startat=1', 'Next &gt' ],
        [ 'tr', 'td' ],
        [ 'New York', 'Financial capital of the world', 20_420_000 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'search_startat=1', 'Next &gt' ],
    );

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{ws}->{-max_results_per_page} = 1;

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{q}->param('state_or_province', 'New York');
    $wb->{q}->param('search_startat', 1);
    $self->assert_display_contains(
        [ 'search_startat=0', 'lt; Previous', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'Ithaca', 'Ithaca is Gorges', 100_018 ],
        [ 'td', 'tr' ],
        [ 'search_startat=0', 'lt; Previous', 'At last page' ],
    );
}

sub test_display__breadcrumb_navigation
{
    my $self = shift;
    my $wb = $self->{wb};

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $wb->{q}->param('state_or_province', 'New York');
    $self->assert_display_contains(
        [ 'href="?"[^<>]+class="breadcrumbNavLink', 'Top', 'gt' ],
        [ 'continent=North%20America', 'class="breadcrumbNavLink', 'North America', 'gt' ],
        [ 'continent=North%20America', 'nation=United%20States', 'class="breadcrumbNavLink', 'United States', 'gt' ],
        [ 'continent=North%20America', 'nation=United%20States', 'state_or_province=New%20York', 'class="breadcrumbNavLink', 'New York' ],
        [ 'Sort by', 'sortby_columns_popup', 'Sort field' ],
        [ 'At first page', 'At last page' ],
        [ 'tr', 'td' ],
        [ 'New York', 'Financial capital of the world', 20_420_000 ],
        [ 'Ithaca', 'Ithaca is Gorges', 100_018 ],
        [ 'td', 'tr' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_deep_equals(['Top', 'North America', 'United States', 'New York'], $wb->{'breadcrumbs'});
    $self->assert_matches(
        $self->word_sequence_regex_for_rows([ 'href="\?"[^<>]+class="breadcrumbNavLink', 'Top' ]),
        $wb->{'breadcrumb_links'}->[0],
    );
    $self->assert_matches(
        $self->word_sequence_regex_for_rows([ 'continent=North%20America', 'class="breadcrumbNavLink', 'North America' ]),
        $wb->{'breadcrumb_links'}->[1],
    );
    $self->assert_matches(
        $self->word_sequence_regex_for_rows([ 'continent=North%20America', 'nation=United%20States', 'class="breadcrumbNavLink', 'United States' ]),
        $wb->{'breadcrumb_links'}->[2],
    );
    $self->assert_matches(
        $self->word_sequence_regex_for_rows([ 'continent=North%20America', 'nation=United%20States', 'state_or_province=New%20York', 'class="breadcrumbNavLink', 'New York' ]),
        $wb->{'breadcrumb_links'}->[3],
    );

    $self->assert_display_does_not_contain([ 'state_or_province=New%20York', 'id="categoryNavLink-' ]);

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{q}->param('href_testvar', 'foo');
    $wb->{ws}->{-href_extra_vars} = { href_testvar => undef };

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $self->assert_display_contains(
        [ 'href="?"[^<>]+class="breadcrumbNavLink', 'Top', 'gt' ],
        [ 'continent=North%20America', 'href_testvar=foo', 'class="breadcrumbNavLink', 'North America', 'gt' ],
        [ 'continent=North%20America', 'nation=United%20States', 'href_testvar=foo', 'class="breadcrumbNavLink', 'United States' ],

        [ 'state_or_province=New%20York', 'href_testvar=foo', 'id="categoryNavLink-New York".*', 'New York, United States' ],
        [ 'state_or_province=Oregon',     'href_testvar=foo', 'id="categoryNavLink-Oregon".*',   'Oregon, United States'   ],
    );

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{-exclude_vars_from_breadcrumbs} = [ 'href_testvar2' ];
    $wb->{q}->param('href_testvar', 'foo');
    $wb->{q}->param('href_testvar2', 'bar');
    $wb->{ws}->{-href_extra_vars} = { href_testvar => undef, href_testvar2 => undef };

    $wb->{q}->param('continent', 'North America');
    $wb->{q}->param('nation', 'United States');
    $self->assert_display_contains(
        [ 'href="?"[^<>]+class="breadcrumbNavLink', 'Top', 'gt' ],
        [ 'continent=North%20America', 'href_testvar=foo', 'class="breadcrumbNavLink', 'North America', 'gt' ],
        [ 'continent=North%20America', 'nation=United%20States', 'href_testvar=foo', 'class="breadcrumbNavLink', 'United States' ],

        [ 'state_or_province=New%20York', 'href_testvar2=bar', 'href_testvar=foo', 'id="categoryNavLink-New York".*', 'New York, United States' ],
        [ 'state_or_province=Oregon',     'href_testvar2=bar', 'href_testvar=foo', 'id="categoryNavLink-Oregon".*',   'Oregon, United States'   ],
    );
    $self->assert_display_does_not_contain([ 'href_testvar2=bar[^<>]*class="breadcrumbNavLink' ]);
}

sub test_display__passing_where_clause_and_bind_params
{
    my $self = shift;
    my $wb = $self->{wb};
    $wb->{ws}->{-where_clause} = 'continent LIKE ?';
    $wb->{ws}->{-bind_params} = ['A%'];

    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*', 'Africa' ],
        [ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*', 'Asia' ],
        [ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'td', 'tr' ],
    );
    $self->assert_display_does_not_contain([ 'Europe' ]);
    $self->assert_display_does_not_contain([ 'America' ]);

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{ws}->{-where_clause} = 'cities.state_or_province = ?';
    $wb->{ws}->{-bind_params} = ['Oregon'];

    $wb->{q}->param('continent', 'North America');
    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 'continent=North%20America&nation=United%20States[^<>]+id="categoryNavLink-United States".*', 'United States' ],
        [ 'td', 'tr' ],
    );
    # test Canada not listed at all
    $self->assert_display_does_not_contain([ 'Canada' ]);
}

sub test_display__passing_href_extra_vars
{
    my $self = shift;
    my $wb = $self->{wb};
    $wb->{-max_category_results_per_page} = 3;
    $wb->{ws}->{-href_extra_vars} = { myVar1 => undef, myVar2 => 'constant' };

    $self->assert_display_contains(
        [ 'At first page', '3', 'results displayed', '1 - 3', 'of', '6', 'search_startat=1&myVar2=constant', 'Next &gt' ],
        [ 'tr', 'td' ],
        [ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*', 'Africa' ],
        [ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*', 'Asia' ],
        [ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'search_startat=1&myVar2=constant', 'Next &gt' ],
    );
    $self->assert_display_does_not_contain([ 'myVar1=' ]);

    $self->init_test_object();
    $wb = $self->{wb};

    $wb->{-max_category_results_per_page} = 3;
    $wb->{ws}->{-href_extra_vars} = { myVar1 => undef, myVar2 => 'constant' };
    $wb->{q}->param('myVar1', 'foo');
    # test that both myVar1 and myVar2 params are in navigation link
    $self->assert_display_contains(
        [ 'At first page', '3', 'results displayed', '1 - 3', 'of', '6', 'search_startat=1', 'myVar1=foo', 'Next &gt' ],
        [ 'tr', 'td' ],
        [ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*', 'Africa' ],
        [ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*', 'Asia' ],
        [ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'search_startat=1', 'myVar2=constant', 'Next &gt' ],
    );
}

sub test_display__with_sql_search_columns_and_join_for_dataset
{
    my $self = shift;
    my $wb = $self->{wb};
    $wb->{ws}->{-sql_search_columns} = [qw/city_no continent/];
    $wb->{ws}->{-sql_join_for_dataset} = 'inner join cities using (city_no)';
    $wb->{ws}->{-where_clause} = 'continent LIKE ?';
    $wb->{ws}->{-bind_params} = ['A%'];

    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 'continent=Africa[^<>]+id="categoryNavLink-Africa".*', 'Africa' ],
        [ 'continent=Asia[^<>]+id="categoryNavLink-Asia".*', 'Asia' ],
        [ 'continent=Australia[^<>]+id="categoryNavLink-Australia".*', 'Australia' ],
        [ 'td', 'tr' ],
    );
    $self->assert_display_does_not_contain([ 'Europe' ]);
    $self->assert_display_does_not_contain([ 'America' ]);

    $self->init_test_object();
    $wb = $self->{wb};
    $wb->{ws}->{-where_clause} = 'cities.state_or_province = ?';
    $wb->{ws}->{-bind_params} = ['Oregon'];

    $wb->{q}->param('continent', 'North America');
    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 'continent=North%20America&nation=United%20States[^<>]+id="categoryNavLink-United States".*', 'United States' ],
        [ 'td', 'tr' ],
    );
    # test Canada not listed at all
    $self->assert_display_does_not_contain([ 'Canada' ]);
}


1;
