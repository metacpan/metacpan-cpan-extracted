#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

require Catmandu::Fix;

use_ok('Catmandu::Fix::datetime_diff');

#using defaults
{
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_diff('diff','start','end')"]
  );
  my $tests = [
    {
      input => {
        start => '2016-01-01T00:00:00.000Z',
        end => '2016-01-02T00:00:00.000Z',
      },
      expected => {
        start => '2016-01-01T00:00:00.000Z',
        end => '2016-01-02T00:00:00.000Z',
        diff => 86400
      },
      text => "using defaults"
    },
    #only compute seconds, no milliseconds
    {
      input => {
        start => '2016-01-01T00:00:00.000Z',
        end => '2016-01-02T00:00:00.10Z',
      },
      expected => {
        start => '2016-01-01T00:00:00.000Z',
        end => '2016-01-02T00:00:00.10Z',
        diff => 86400
      },
      text => "using defaults (only compute seconds, no milliseconds)"
    }
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected},$test->{text});
  }
}
#using explicit time zones
{
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_diff('diff','start','end','start_time_zone' => 'UTC','end_time_zone' => 'Europe/Brussels','start_pattern' => '%FT%T.%N','end_pattern' => '%FT%T.%N')"]
  );
  my $tests = [
    {
      input => {
        start => '2016-01-01T00:00:00.000',
        end => '2016-01-02T00:00:00.000',
      },
      expected => {
        start => '2016-01-01T00:00:00.000',
        end => '2016-01-02T00:00:00.000',
        diff => 82800
      },
      text => "using explicit timezones"
    },
    #only compute seconds, no milliseconds
    {
      input => {
        start => '2016-01-01T00:00:00.000',
        end => '2016-01-02T00:00:00.10',
      },
      expected => {
        start => '2016-01-01T00:00:00.000',
        end => '2016-01-02T00:00:00.10',
        diff => 82800
      },
      text => "using explicit timezones (only compute seconds, no milliseconds)"
    }
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected},,$test->{text});
  }
}
#using time zones from date string
{
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_diff('diff','start','end','start_pattern' => '%FT%T.%N%z','end_pattern' => '%FT%T.%N%z')"]
  );
  my $tests = [
    {
      input => {
        start => '2016-01-01T00:00:00.000+0000',
        end => '2016-01-02T00:00:00.000+0100',
      },
      expected => {
        start => '2016-01-01T00:00:00.000+0000',
        end => '2016-01-02T00:00:00.000+0100',
        diff => 82800
      },
      text => "using time zones from date string"
    },
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected},$test->{text});
  }
}
#using different patterns
{
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_diff('diff','start','end','start_pattern' => '%FT%T','end_pattern' => '%F')"]
  );
  my $tests = [
    {
      input => {
        start => '2016-01-01T00:00:00',
        end => '2016-01-02',
      },
      expected => {
        start => '2016-01-01T00:00:00',
        end => '2016-01-02',
        diff => 86400
      },
      text => "using different patterns"
    }
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected},$test->{text});
  }
}

done_testing 7;
