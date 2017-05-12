#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Catalyst::TraitFor::Controller::jQuery::jqGrid::Search;


# test each of the search operators
my @tests = (
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'eq','searchString'=>'val'},name=>'eq',result=>{'fld'=>{'='=>'val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'ne','searchString'=>'val'},name=>'ne',result=>{'fld'=>{'!='=>'val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'lt','searchString'=>'val'},name=>'lt',result=>{'fld'=>{'<'=>'val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'le','searchString'=>'val'},name=>'le',result=>{'fld'=>{'<='=>'val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'gt','searchString'=>'val'},name=>'gt',result=>{'fld'=>{'>'=>'val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'ge','searchString'=>'val'},name=>'ge',result=>{'fld'=>{'>='=>'val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'bw','searchString'=>'val'},name=>'bw',result=>{'fld'=>{'-like'=>'val%'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'bn','searchString'=>'val'},name=>'bn',result=>{'fld'=>{'-not_like'=>'val%'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'in','searchString'=>'val'},name=>'in',result=>{'val'=>{'-like'=>'%fld%'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'ni','searchString'=>'val'},name=>'ni',result=>{'val'=>{'-not_like'=>'%fld%'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'ew','searchString'=>'val'},name=>'ew',result=>{'fld'=>{'-like'=>'%val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'en','searchString'=>'val'},name=>'en',result=>{'fld'=>{'-not_like'=>'%val'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'cn','searchString'=>'val'},name=>'cn',result=>{'fld'=>{'-like'=>'%val%'}}},
    {search=>{'_search'=>'true','searchField'=>'fld','searchOper'=>'nc','searchString'=>'val'},name=>'nc',result=>{'fld'=>{'-not_like'=>'%val%'}}},
);

plan tests => @tests + 1;

can_ok( 'Catalyst::TraitFor::Controller::jQuery::jqGrid::Search', 'jqGrid_search');

for my $t (@tests) {
  is_deeply(Catalyst::TraitFor::Controller::jQuery::jqGrid::Search->jqGrid_search($t->{search}), $t->{result}, $t->{name});
}
