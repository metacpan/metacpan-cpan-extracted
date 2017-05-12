#!perl ## no critic (TidyCode)
use strict;
use warnings;

our $VERSION = '0.001';

require 'DBI.pm.fake'; ## no critic (BarewordIncludes)
use syntax qw(function);
use Carp qw(confess);
use Const::Fast qw(const);
require Data::Page;
require Data::Page::Pagination;
require DBI;
use English qw(-no_match_vars $OS_ERROR);
use HTML::Zoom 0.009005 ();
require IO::File;

my $dbh = DBI->connect(
    'dbi:fake:database',
    'user',
    'password',
    {
        PrintError => 0,
        RiseError  => 1,
        AutoCommit => 1,
    },
);

my $current_page = 2; # normally got from webserver request

const my $ENTRIES_PER_PAGE => 2; # because I have less data
const my $PAGE_NUMBERS     => 5; # visible 2 left + 1 current + 2 right

# total entries
my $sth_count = $dbh->prepare(<<'EO_SQL');
    SELECT count(*)
    FROM   table
EO_SQL
$sth_count->execute;
my ($total_entries) = $sth_count->fetchrow_array;
$sth_count->finish;

# create the page object
my $page = Data::Page->new(
    $total_entries,
    $ENTRIES_PER_PAGE,
    $current_page,
);

# fetch the slice only
my $sth_data = $dbh->prepare(<<'EO_SQL');
    SELECT given_name, surname
    FROM   table
    LIMIT  ?, ?
EO_SQL
$sth_data->execute( $page->skipped, $page->entries_per_page );
my $results_ref = $sth_data->fetchall_arrayref( {} );
$sth_data->finish;

# prepare the pagination
my $pagination = Data::Page::Pagination->new(
    page         => $page,
    page_numbers => $PAGE_NUMBERS,
);

# render HMTL

fun _create_page_link ($current_page) {
    return "?current_page=$current_page";
}

my $zoom = HTML::Zoom->from_file('template.html');
$zoom = $zoom
    ->replace_content( title => 'Example' )
    ->select('.z-result')->repeat(
        [
            map { ## no critic (ComplexMappings)
                my $result_ref = $_;
                sub {
                    return $_
                        ->replace_content( '.z-given-name' => $result_ref->{given_name} )
                        ->replace_content( '.z-surname'    => $result_ref->{surname} );
                }
            } @{$results_ref}
        ],
    );

# It's a little optimized
# There are single page numbers.
my @single_value = qw(
    previous_page first_page current_page last_page next_page
);
# There are lists of page numbers.
my @multi_value  = qw(previous_pages next_pages);
# There are switches of made them visible or not.
my @bool_value   = qw(
    previous_page first_page hidden_previous
    hidden_next last_page next_page
);

for my $type (@single_value) {
    ( my $css_class = "z-$type" ) =~ tr{_}{-};
    my $page_number = $pagination->$type;
    my $link = _create_page_link($page_number);
    $zoom ## no critic (LongChainsOfMethodCalls)
        = $type eq 'current_page'
        ? $zoom
            ->select(".$css_class")
            ->set_attribute( value => $page_number )
            ->then
            ->set_attribute( size => length $page_number )
            ->select('.z-current-page-form')
            ->set_attribute( action => $link )
        : do {
            $zoom = $zoom
                ->select(".$css_class")
                ->set_attribute( href => $link );
            $zoom
                = ( $type eq 'previous_page' || $type eq 'next_page' )
                ? $zoom
                : $zoom
                    ->then
                    ->replace_content($page_number);
        };
}
for my $type (@multi_value) {
    my $page_number_ref = $pagination->$type;
    ( my $css_class = "z-$type" ) =~ tr{_}{-};
    $zoom
        = $zoom
        ->select(".$css_class")
        ->repeat_content(
            [
                map { ## no critic (ComplexMappings)
                    my $page_number = $_;
                    sub {
                        my $link = _create_page_link($page_number);
                        $_->select('a') ## no critic (LongChainsOfMethodCalls)
                            ->set_attribute( href => $link )
                            ->then
                            ->replace_content($page_number);
                    };
                } @{$page_number_ref}
            ]
        );
}
for my $type (@bool_value) {
    my $method     = "visible_${type}";
    (my $css_class = "z-$type") =~ tr{_}{-};
    if ( ! $pagination->$method ) {
        $zoom = $zoom
            ->select(".$css_class")
            ->add_to_attribute( class => 'invisible' );
    }
}

# write HTML output
my $fh = IO::File->new( 'output.html', '>' )
    or confess $OS_ERROR;
print {$fh} $zoom->to_html
    or confess $OS_ERROR;

# $Id$
