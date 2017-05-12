package TestsFor::Cikl::Smrt::Fetchers;
use base qw(Test::Class);
use strict;
use warnings;
use Test::More;
use URI;

sub startup : Test(startup => 1) {
  use_ok( 'Cikl::Smrt::Fetchers' );
}

sub setup : Test(setup) {
  my $self = shift;
  my $fetchers = Cikl::Smrt::Fetchers->new();
  $self->{fetchers} = $fetchers;
}

sub test_lookup_http : Test(1) {
  my $self = shift;
  my $http_fetcher = $self->{fetchers}->lookup(URI->new("http://foobar.com/bla.txt"));
  is($http_fetcher,'Cikl::Smrt::Fetchers::Http', "lookup(http://...) returns the Http fetcher");
}
sub test_lookup_https : Test(1) {
  my $self = shift;
  my $https_fetcher = $self->{fetchers}->lookup(URI->new("https://foobar.com/bla.txt"));
  is($https_fetcher,'Cikl::Smrt::Fetchers::Http', "lookup(https://...) returns the Http fetcher");
}
sub test_lookup_file : Test(3) {
  my $self = shift;
  my $file_fetcher = $self->{fetchers}->lookup(URI->new("file:///foo/bar/test.txt"));
  is($file_fetcher,'Cikl::Smrt::Fetchers::File', "lookup(file://...) returns the File fetcher");
  my $relative_file_fetcher = $self->{fetchers}->lookup(URI->new("./subdir/test.txt"));
  is($relative_file_fetcher,'Cikl::Smrt::Fetchers::File', "lookup(./subdir/test.txt) (relative path) returns the File fetcher");
  my $relative_file_fetcher2 = $self->{fetchers}->lookup(URI->new("subdir/test.txt"));
  is($relative_file_fetcher2,'Cikl::Smrt::Fetchers::File', "lookup(subdir/test.txt) (relative path) returns the File fetcher");
}

sub test_lookup_unknown : Test(1) {
  my $self = shift;
  my $unknown_fetcher = $self->{fetchers}->lookup(URI->new("foobar://foobar.com/bla.txt"));
  is($unknown_fetcher,undef, "lookup(foobar://...) (unknown scheme) returns undef");
}

TestsFor::Cikl::Smrt::Fetchers->runtests;
