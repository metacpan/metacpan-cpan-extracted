use strict;
use warnings;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'TEST_DB_DSN=mysql://root@/blog_test' unless $ENV{TEST_DB_DSN};
plan skip_all => 'Mojolicious is required'             unless eval 'require Mojolicious; 1';

my $tmpdb = DBIx::TempDB->new($ENV{TEST_DB_DSN});
$ENV{BLOG_DSN} = $tmpdb->url;

require File::Spec;
require Test::Mojo;
unshift @INC, File::Spec->catdir(qw(t blog lib));
my $t = Test::Mojo->new('Blog');

$t->get_ok('/posts')->status_is(200)->element_exists_not('a[href="/posts/1"]');

$t->post_ok('/posts', form => {title => 'Best blog post ever', body => 'Too cool!'})->status_is(302)
  ->header_is('Location', '/posts/1');

$t->get_ok($t->tx->res->headers->location)->status_is(200)->text_is('h2', 'Best blog post ever');

$t->get_ok('/posts')->status_is(200)->text_is('a[href="/posts/1"]', 'Best blog post ever');

$tmpdb->execute_file(File::Spec->catfile(qw(blog migrations data.sql)));
$t->get_ok('/posts/42')->status_is(200)->text_is('h2', 'The answer');

my $dbh = DBI->connect($tmpdb->dsn);
my $sth = $dbh->prepare('select count(*) from posts');
$sth->execute;
is $sth->fetchrow_arrayref->[0], 2, 'two blog posts';

done_testing;
