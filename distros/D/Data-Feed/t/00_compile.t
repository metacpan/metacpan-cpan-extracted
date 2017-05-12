use strict;
use Test::More;

my @modules = qw(
    Data::Feed::Atom::Entry
    Data::Feed::Atom
    Data::Feed::Feed
    Data::Feed::Item
    Data::Feed::Parser::Atom
    Data::Feed::Parser::RSS
    Data::Feed::Parser
    Data::Feed::RSS::Entry
    Data::Feed::RSS
    Data::Feed::Web::Content
    Data::Feed::Web::Enclosure
    Data::Feed::Web::Entry
    Data::Feed::Web::Feed
    Data::Feed
);

plan tests => scalar @modules;
use_ok $_ for @modules;
