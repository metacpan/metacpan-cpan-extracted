#!/usr/bin/perl

use strict;
use warnings;

use App::PTP::Args;
use App::PTP::Commands qw(do_perl do_grep do_substitute do_sort);
use English;
use Test::More;

if ($ENV{HARNESS_ACTIVE}) {
  plan skip_all => 'Benchmarks need to be run explicitly.';
}

BEGIN {
  eval 'use Benchmark qw(:hireswallclock :all)';
  if ($EVAL_ERROR) {
    skip_all('TheBenchmark module is required');
  }
}

my $content_size = 5000;

my @content = ('abcdefgh') x $content_size;
my @markers = (0) x $content_size;

my %modes = App::PTP::Args::get_default_modes();
my %options = App::PTP::Args::get_default_options();

{
  my $input = [@content];
  my @expected = ('obcdefgh') x $content_size;
  do_perl($input, \@markers, \%modes, \%options, 'perl', 's/a/o/');
  is_deeply(\@$input, \@expected);
}

sub substitute_perl_version {
  my ($use_safe) = @_;
  my %o = (%options, use_safe => $use_safe);
  App::PTP::Commands::prepare_perl_env(\'dummy', \%o);
  do_perl([@content], \@markers, \%modes, \%o, 'perl', 's/a/o/')
};

my $substitute_native_version = sub {
  App::PTP::Commands::prepare_perl_env(\'dummy', \%options);
  do_substitute([@content], \@markers, \%modes, \%options, 'a', 'o')
};

timethese(10, {
  'substitute' => $substitute_native_version,
  'perl' => sub { substitute_perl_version(0) },
  'perl safe' => sub { substitute_perl_version(1) },
});

sub grep_perl_version {
  my ($use_safe) = @_;
  my %o = (%options, use_safe => $use_safe);
  App::PTP::Commands::prepare_perl_env(\'dummy', \%o);
  do_perl([@content], \@markers, \%modes, \%o, 'perl', '/a/')
};

my $grep_native_version = sub {
  App::PTP::Commands::prepare_perl_env(\'dummy', \%options);
  do_grep([@content], \@markers, \%modes, \%options, 'a')
};

timethese(10, {
  'grep' => $grep_native_version,
  'perl' => sub { grep_perl_version(0) },
  'perl safe' => sub { grep_perl_version(1) },
});


srand(42);
my @random_content = map { rand(1000) } (1..$content_size);

my $native_sort = sub {
  do_sort([@random_content], \@markers, \%modes, \%options)
};

my $custom_sort = sub {
  my %m = (%modes, comparator => '$a cmp $b');
  do_sort([@random_content], \@markers, \%m, \%options)
};

timethese(2, {
  'native sort' => $native_sort,
  'custom sort' => $custom_sort,
});

done_testing();
