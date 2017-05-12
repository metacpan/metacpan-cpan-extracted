#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 7;
use Data::Taxonomy::Tags;

my $t;

$t = Data::Taxonomy::Tags->new('foo bar baz bat');
$t->remove_from_tags('baz');
is_deeply([$t->tags], [qw/foo bar bat/]);

$t = Data::Taxonomy::Tags->new('foo bar baz bat');
$t->remove_from_tags('baz foo');
is_deeply([$t->tags], [qw/bar bat/]);

$t = Data::Taxonomy::Tags->new('foo bar');
$t->add_to_tags('baz');
is_deeply([$t->tags], [qw/foo bar baz/]);

$t = Data::Taxonomy::Tags->new('foo bar');
$t->add_to_tags('baz bat');
is_deeply([$t->tags], [qw/foo bar baz bat/]);

$t = Data::Taxonomy::Tags->new('foo bar');
$t->add_to_tags('bar bat');
is_deeply([$t->tags], [qw/foo bar bat/]);

$t = Data::Taxonomy::Tags->new('foo meta:bar baz system:bat');
$t->remove_category('meta');
is_deeply([$t->tags], [qw/foo baz system:bat/]);

$t = Data::Taxonomy::Tags->new('foo meta:bar baz system:bat');
$t->remove_category;
is_deeply([$t->tags], [qw/meta:bar system:bat/]);


__END__

