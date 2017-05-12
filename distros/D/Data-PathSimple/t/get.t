#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw{ no_plan };

BEGIN {
  use_ok( 'Data::PathSimple', 'get' );
}

my @tests = (
  undef_data_tests(),
  array_tests(),
  hash_tests(),
);

foreach my $test ( @tests ) {
  my $return_value = get( $test->{data_before}, $test->{path} );

  is_deeply(
    $return_value,
    $test->{return_value},
    "$test->{name}: return value"
  );

  is_deeply(
    $test->{data_before},
    $test->{data_after},
    "$test->{name}: data structure"
  )
}

sub undef_data_tests {
  return (
    {
      name         => 'undef data, undef path',
      data_before  => undef,
      data_after   => undef,
      return_value => undef,
      path         => undef,
    },
    {
      name         => 'undef data, empty path',
      data_before  => undef,
      data_after   => undef,
      return_value => undef,
      path         => '',
    },
    {
      name         => 'undef data, non-rooted path',
      data_before  => undef,
      data_after   => undef,
      return_value => undef,
      path         => 'a/non/rooted/path',
    },
    {
      name         => 'undef data, rooted path',
      data_before  => undef,
      data_after   => undef,
      return_value => undef,
      path         => '/a/rooted/path',
    },
  );
}

sub array_tests {
  my @array_tests = (
    {
      name         => 'array data, undef path',
      data_before  => array_data(),
      data_after   => array_data(),
      return_value => undef,
      path         => undef,
    },
    {
      name         => 'array data, empty path',
      data_before  => array_data(),
      data_after   => array_data(),
      return_value => undef,
      path         => '',
    },
    {
      name         => 'array data, non-integer, non-rooted path',
      data_before  => array_data(),
      data_after   => array_data(),
      return_value => undef,
      path         => 'a/non/integer/path',
    },
    {
      name         => 'array data, non-integer, rooted path',
      data_before  => array_data(),
      data_after   => array_data(),
      return_value => undef,
      path         => '/a/non/integer/path',
    },
    {
      name         => 'array data, non-existent, non-rooted path',
      data_before  => array_data(),
      data_after   => array_data(),
      return_value => undef,
      path         => '99/98/97'
    },
    {
      name         => 'array data, non-existent, rooted path',
      data_before  => array_data(),
      data_after   => array_data(),
      return_value => undef,
      path         => '/99/98/97'
    },
  );

  for ( my $i = 0; $i < @{ array_data() }; $i++ ) {
    push @array_tests, (
      {
        name         => "array data, non-rooted path $i",
        data_before  => array_data(),
        data_after   => array_data(),
        return_value => array_data()->[$i],
        path         => "$i",
      },
      {
        name         => "array data, rooted path /$i",
        data_before  => array_data(),
        data_after   => array_data(),
        return_value => array_data()->[$i],
        path         => "/$i",
      },
    );

    for ( my $j = 0; $j < @{ array_data()->[$i] }; $j++ ) {
      push @array_tests, (
        {
          name         => "array data, non-rooted path $i/$j",
          data_before  => array_data(),
          data_after   => array_data(),
          return_value => array_data()->[$i][$j],
          path         => "$i/$j",
        },
        {
          name         => "array data, rooted path /$i/$j",
          data_before  => array_data(),
          data_after   => array_data(),
          return_value => array_data()->[$i][$j],
          path         => "/$i/$j",
        },
      );

      for ( my $k = 0; $k < @{ array_data()->[$i][$j] }; $k++ ) {
        push @array_tests, (
          {
            name         => "array data, non-rooted path $i/$j/$k",
            data_before  => array_data(),
            data_after   => array_data(),
            return_value => array_data()->[$i][$j][$k],
            path         => "$i/$j/$k",
          },
          {
            name         => "array data, rooted path /$i/$j/$k",
            data_before  => array_data(),
            data_after   => array_data(),
            return_value => array_data()->[$i][$j][$k],
            path         => "/$i/$j/$k",
          },
        );

        for ( my $l = 0; $l < @{ array_data()->[$i][$j][$k] }; $l++ ) {
          push @array_tests, (
            {
              name         => "array data, non-rooted path $i/$j/$k/$l",
              data_before  => array_data(),
              data_after   => array_data(),
              return_value => array_data()->[$i][$j][$k][$l],
              path         => "$i/$j/$k/$l",
            },
            {
              name         => "array data, rooted path /$i/$j/$k/$l",
              data_before  => array_data(),
              data_after   => array_data(),
              return_value => array_data()->[$i][$j][$k][$l],
              path         => "/$i/$j/$k/$l",
            },
          );
        }
      }
    }
  }

  return @array_tests;
}

sub array_data {
  my @array_data;

  for ( my $i = 0; $i < 3; $i++ ) {
    for ( my $j = 0; $j < 3; $j++ ) {
      for ( my $k = 0; $k < 3; $k++ ) {
        for ( my $l = 0; $l < 3; $l++ ) {
          $array_data[$i][$j][$k][$l] = $i + $j + $k + $l + 1;
        }
      }
    }
  }

  return \@array_data;
}

sub hash_tests {
  my @hash_tests = (
    {
      name         => 'hash data, undef path',
      data_before  => hash_data(),
      data_after   => hash_data(),
      return_value => undef,
      path         => undef,
    },
    {
      name         => 'hash data, empty path',
      data_before  => hash_data(),
      data_after   => hash_data(),
      return_value => undef,
      path         => '',
    },
    {
      name         => 'hash data, non-existent, non-rooted path',
      data_before  => hash_data(),
      data_after   => hash_data(),
      return_value => undef,
      path         => 'a/non/existent/path',
    },
    {
      name         => 'hash data, non-existent, rooted path',
      data_before  => hash_data(),
      data_after   => hash_data(),
      return_value => undef,
      path         => '/a/non/existent/path',
    },
  );

  foreach my $i ( keys %{ hash_data() } ) {
    push @hash_tests, (
      {
        name         => "hash data, non-rooted path $i",
        data_before  => hash_data(),
        data_after   => hash_data(),
        return_value => hash_data()->{$i},
        path         => "$i",
      },
      {
        name         => "hash data, rooted path /$i",
        data_before  => hash_data(),
        data_after   => hash_data(),
        return_value => hash_data()->{$i},
        path         => "/$i",
      },
    );

    foreach my $j ( keys %{ hash_data()->{$i} } ) {
      push @hash_tests, (
        {
          name         => "hash data, non-rooted path $i/$j",
          data_before  => hash_data(),
          data_after   => hash_data(),
          return_value => hash_data()->{$i}{$j},
          path         => "$i/$j",
        },
        {
          name         => "hash data, rooted path /$i/$j",
          data_before  => hash_data(),
          data_after   => hash_data(),
          return_value => hash_data()->{$i}{$j},
          path         => "/$i/$j",
        },
      );

      foreach my $k ( keys %{ hash_data()->{$i}{$j} } ) {
        push @hash_tests, (
          {
            name         => "hash data, non-rooted path $i/$j/$k",
            data_before  => hash_data(),
            data_after   => hash_data(),
            return_value => hash_data()->{$i}{$j}{$k},
            path         => "$i/$j/$k",
          },
          {
            name         => "hash data, rooted path /$i/$j/$k",
            data_before  => hash_data(),
            data_after   => hash_data(),
            return_value => hash_data()->{$i}{$j}{$k},
            path         => "/$i/$j/$k",
          },
        );

        foreach my $l ( keys %{ hash_data()->{$i}{$j}{$k} } ) {
          push @hash_tests, (
            {
              name         => "hash data, non-rooted path $i/$j/$k/$l",
              data_before  => hash_data(),
              data_after   => hash_data(),
              return_value => hash_data()->{$i}{$j}{$k}{$l},
              path         => "$i/$j/$k/$l",
            },
            {
              name         => "hash data, rooted path /$i/$j/$k/$l",
              data_before  => hash_data(),
              data_after   => hash_data(),
              return_value => hash_data()->{$i}{$j}{$k}{$l},
              path         => "/$i/$j/$k/$l",
            },
          );
        }
      }
    }
  }

  return @hash_tests;
}

sub hash_data {
  my @names = qw{
    first
    second
    third
    fourth
    fifth
    sixth
    seventh
    eighth
    ninth
  };

  my %hash_data;

  for ( my $i = 0; $i < 3; $i++ ) {
    for ( my $j = 0; $j < 3; $j++ ) {
      for ( my $k = 0; $k < 3; $k++ ) {
        for ( my $l = 0; $l < 3; $l++ ) {
          my $name = $names[ $i + $j + $k + $l ];
          $hash_data{ $names[$i] }{ $names[$j] }{ $names[$k] }{ $name } = $name;
        }
      }
    }
  }

  return \%hash_data;
}
