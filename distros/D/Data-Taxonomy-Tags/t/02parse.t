#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 13;
use Data::Taxonomy::Tags;

is_deeply([Data::Taxonomy::Tags->new('foo bar baz bat')->tags], [qw/foo bar baz bat/]);
is_deeply([Data::Taxonomy::Tags->new(' foo bar   ')->tags], [qw/foo bar/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta:bar')->tags], [qw/foo meta:bar/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta:bar')->categories], [qw/meta/]);
is_deeply([Data::Taxonomy::Tags->new('foo bar')->categories], []);
is_deeply([Data::Taxonomy::Tags->new->tags], []);
is_deeply([Data::Taxonomy::Tags->new('foo meta:bar meta:baz system:blah')
                               ->tags_with_category('meta')], [qw/bar baz/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta:bar meta:baz system:blah')
                               ->tags_with_category], [qw/foo/]);

is_deeply([Data::Taxonomy::Tags->new(' foo|bar   ',{separator=>'|'})->tags], [qw/foo bar/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta!bar',{category=>'!'})->tags], [qw/foo meta!bar/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta!bar',{category=>'!'})->categories], [qw/meta/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta!bar meta!baz system!blah', {category=>'!'})
                               ->tags_with_category('meta')], [qw/bar baz/]);
is_deeply([Data::Taxonomy::Tags->new('foo meta!bar meta!baz system!blah', {category=>'!'})
                               ->tags_with_category], [qw/foo/]);

__END__

