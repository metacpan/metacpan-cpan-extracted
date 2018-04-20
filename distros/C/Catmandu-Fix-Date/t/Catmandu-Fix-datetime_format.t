#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

require Catmandu::Fix;

use_ok('Catmandu::Fix::datetime_format');

#default
{
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_format('date','source_pattern' => '%Y-%m-%d','destination_pattern' => '%Y-%m-%d','default' => '1970-01-01')"]
  );
  my $tests = [
    {
      input => {
        date => undef
      },
      expected => {
        date => '1970-01-01'
      }
    },
    {
      input => {
        date => ''
      },
      expected => {
        date => '1970-01-01'
      }
    },
    {
      input => {
        date => ["2014-01-01"]
      },
      expected => {
        date => '1970-01-01'
      }
    },
    {
      input => {
        date => '2014-01-01'
      },
      expected => {
        date => '2014-01-01'
      }
    }

  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected});
  }
}
#delete
{
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_format('date','source_pattern' => '%Y-%m-%d','destination_pattern' => '%Y-%m-%d','delete' => 1)"]
  );
  my $tests = [
    {
      input => {
        date => undef
      },
      expected => {
      }
    },
    {
      input => {
        date => ''
      },
      expected => {
      }
    },
    {
      input => {
        date => ["2014-01-01"]
      },
      expected => {
      }
    },
    {
      input => {
        date => '2014-01-01'
      },
      expected => {
        date => '2014-01-01'
      }
    }

  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected});
  }
}
#set time zone
{
  #expect to go back one hour
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_format('date','source_pattern' => '%Y-%m-%dT%H:%M:%SZ','destination_pattern' => '%Y-%m-%dT%H:%M:%SZ','time_zone' => 'Europe/Brussels','set_time_zone' => 'UTC')"]
  );
  my $tests = [
    {
      input => {
        date => '2014-01-01T00:00:00Z'
      },
      expected => {
        date => '2013-12-31T23:00:00Z'
      }
    }
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected});
  }
}
#change pattern AND set time zone
{
  #expect to go back one hour
  my $fixer = Catmandu::Fix->new(
    fixes => ["clone()","datetime_format('date','source_pattern' => '%Y-%m-%dT%H:%M:%SZ','destination_pattern' => '%Y-%m-%d','time_zone' => 'Europe/Brussels','set_time_zone' => 'UTC')"]
  );
  my $tests = [
    {
      input => {
        date => '2014-01-01T00:00:00Z'
      },
      expected => {
        date => '2013-12-31'
      }
    }
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected});
  }
}

#locale
{

  my $fixer = Catmandu::Fix->new(
    fixes => [
      "clone()",
      "datetime_format('date','source_pattern' => '%Y-%m-%dT%H:%M:%SZ','destination_pattern' => '%A %B','time_zone' => 'Europe/Brussels','set_time_zone' => 'UTC', 'set_locale' => 'fr_FR')"
    ]
  );
  my $tests = [
    {
      input => {
        date => '2018-04-19T12:00:00Z'
      },
      expected => {
        date => 'jeudi avril'
      }
    }
  ];

  for my $test(@$tests){
    is_deeply($fixer->fix($test->{input}),$test->{expected});
  }

}

done_testing 12;
