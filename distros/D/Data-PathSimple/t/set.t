#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw{ no_plan };

BEGIN {
  use_ok( 'Data::PathSimple', 'set' );
}

my @tests = (
  undef_data_tests(),
  array_tests(),
  hash_tests(),
);

foreach my $test ( @tests ) {
  my $return_value = set( $test->{data_before}, $test->{path}, $test->{set_value} );

  is_deeply(
    $return_value,
    $test->{return_value},
    "$test->{name}: return value",
  );

  is_deeply(
    $test->{data_before},
    $test->{data_after},
    "$test->{name}: data structure"
  );
}

sub undef_data_tests {
  my @undef_tests;

  foreach my $value ( 42, undef ) {
    my $type = $value ? 'real' : 'undef';

    push @undef_tests, (
      {
        name         => "undef data, undef path, $type value",
        data_before  => undef,
        data_after   => undef,
        path         => undef,
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "undef data, empty path, $type value",
        data_before  => undef,
        data_after   => undef,
        path         => '',
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "undef data, non-rooted path, $type value",
        data_before  => undef,
        data_after   => undef,
        path         => 'a/non/rooted/path',
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "undef data, rooted path, $type value",
        data_before  => undef,
        data_after   => undef,
        path         => '/a/rooted/path',
        set_value    => $value,
        return_value => undef,
      },
    );
  }

  return @undef_tests;
}

sub array_tests {
  my @array_tests;

  foreach my $value ( undef, 42 ) {
    my $type = $value ? 'real' : 'undef';

    push @array_tests, (
      {
        name         => "array data, undef path, $type value",
        data_before  => array_data(),
        data_after   => array_data(),
        path         => undef,
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "array data, empty path, $type value",
        data_before  => array_data(),
        data_after   => array_data(),
        path         => '',
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "array data, non-integer, non-rooted, $type value",
        data_before  => array_data(),
        data_after   => array_data(),
        path         => 'a/non/integer/path',
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "array data, non-integer, rooted, $type value",
        data_before  => array_data(),
        data_after   => array_data(),
        path         => '/a/non/integer/path',
        set_value    => $value,
        return_value => undef,
      },
    );

    my $data_after = array_data();
    $data_after->[99][98][97] = $value;

    push @array_tests, (
      {
        name         => "array data, non-existent, non-rooted, $type value",
        data_before  => array_data(),
        data_after   => $data_after,
        path         => '99/98/97',
        set_value    => $value,
        return_value => $value,
      },
      {
        name         => "array data, non-existent, rooted, $type value",
        data_before  => array_data(),
        data_after   => $data_after,
        path         => '/99/98/97',
        set_value    => $value,
        return_value => $value,
      },
    );
  }

  for ( my $i = 0; $i < @{ array_data() }; $i++ ) {
    my $data_after = array_data();
    $data_after->[$i] = $i;

    push @array_tests, (
      {
        name         => "array data, non-rooted path $i",
        data_before  => array_data(),
        data_after   => $data_after,
        path         => "$i",
        set_value    => $i,
        return_value => $i,
      },
      {
        name         => "array data, rooted path /$i",
        data_before  => array_data(),
        data_after   => $data_after,
        path         => "$i",
        set_value    => $i,
        return_value => $i,
      },
    );

    for ( my $j = 0; $j < @{ array_data()->[$i] }; $j++ ) {
      my $data_after = array_data();
      $data_after->[$i][$j] = $j;

      push @array_tests, (
        {
          name         => "array data, non-rooted path $i/$j",
          data_before  => array_data(),
          data_after   => $data_after,
          path         => "$i/$j",
          set_value    => $j,
          return_value => $j,
        },
        {
          name         => "array data, rooted path /$i/$j",
          data_before  => array_data(),
          data_after   => $data_after,
          path         => "/$i/$j",
          set_value    => $j,
          return_value => $j,
        },
      );

      for ( my $k = 0; $k < @{ array_data()->[$i][$j] }; $k++ ) {
        my $data_after = array_data();
        $data_after->[$i][$j][$k] = $k;

        push @array_tests, (
          {
            name         => "array data, non-rooted path $i/$j/$k",
            data_before  => array_data(),
            data_after   => $data_after,
            path         => "$i/$j/$k",
            set_value    => $k,
            return_value => $k,
          },
          {
            name         => "array data, rooted path /$i/$j/$k",
            data_before  => array_data(),
            data_after   => $data_after,
            path         => "/$i/$j/$k",
            set_value    => $k,
            return_value => $k,
          },
        );

        for ( my $l = 0; $l < @{ array_data()->[$i][$j][$k] }; $l++ ) {
          my $data_after = array_data();
          $data_after->[$i][$j][$k][$l] = $l;

          push @array_tests, (
            {
              name         => "array data, non-rooted path $i/$j/$k/$l",
              data_before  => array_data(),
              data_after   => $data_after,
              path         => "$i/$j/$k/$l",
              set_value    => $l,
              return_value => $l,
            },
            {
              name         => "array data, rooted path /$i/$j/$k/$l",
              data_before  => array_data(),
              data_after   => $data_after,
              path         => "/$i/$j/$k/$l",
              set_value    => $l,
              return_value => $l,
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
  my @hash_tests;

  foreach my $value ( undef, 42 ) {
    my $type = $value ? 'real' : 'undef';

    push @hash_tests, (
      {
        name         => "hash data, undef path, $type value",
        data_before  => hash_data(),
        data_after   => hash_data(),
        path         => undef,
        set_value    => $value,
        return_value => undef,
      },
      {
        name         => "hash data, empty path, $type value",
        data_before  => hash_data(),
        data_after   => hash_data(),
        path         => '',
        set_value    => $value,
        return_value => undef,
      },
    );

    my $data_after = hash_data();
    $data_after->{a}{non}{existent}{path} = $value;

    push @hash_tests, (
      {
        name         => "hash data, non-existent, non-rooted path, $type value",
        data_before  => hash_data(),
        data_after   => $data_after,
        path         => 'a/non/existent/path',
        set_value    => $value,
        return_value => $value,
      },
      {
        name         => "hash data, non-existent, rooted path, $type value",
        data_before  => hash_data(),
        data_after   => $data_after,
        path         => '/a/non/existent/path',
        set_value    => $value,
        return_value => $value,
      },
    );
  }

  foreach my $i ( keys %{ hash_data() } ) {
    my $data_after = hash_data();
    $data_after->{$i} = $i;

    push @hash_tests, (
      {
        name         => "hash data, non-rooted path $i",
        data_before  => hash_data(),
        data_after   => $data_after,
        path         => "$i",
        set_value    => $i,
        return_value => $i,
      },
      {
        name         => "hash data, rooted path /$i",
        data_before  => hash_data(),
        data_after   => $data_after,
        path         => "/$i",
        set_value    => $i,
        return_value => $i,
      }
    );

    foreach my $j ( keys %{ hash_data()->{$i} } ) {
      my $data_after = hash_data();
      $data_after->{$i}{$j} = $j;

      push @hash_tests, (
        {
          name         => "hash data, non-rooted path $i/$j",
          data_before  => hash_data(),
          data_after   => $data_after,
          path         => "$i/$j",
          set_value    => $j,
          return_value => $j,
        },
        {
          name         => "hash data, rooted path /$i/$j",
          data_before  => hash_data(),
          data_after   => $data_after,
          path         => "/$i/$j",
          set_value    => $j,
          return_value => $j,
        }
      );

      foreach my $k ( keys %{ hash_data()->{$i}{$j} } ) {
        my $data_after = hash_data();
        $data_after->{$i}{$j}{$k} = $k;

        push @hash_tests, (
          {
            name         => "hash data, non-rooted path $i/$j/$k",
            data_before  => hash_data(),
            data_after   => $data_after,
            path         => "$i/$j/$k",
            set_value    => $k,
            return_value => $k,
          },
          {
            name         => "hash data, rooted path /$i/$j/$k",
            data_before  => hash_data(),
            data_after   => $data_after,
            path         => "/$i/$j/$k",
            set_value    => $k,
            return_value => $k,
          }
        );

        foreach my $l ( keys %{ hash_data()->{$i}{$j}{$k} } ) {
          my $data_after = hash_data();
          $data_after->{$i}{$j}{$k}{$l} = $l;

          push @hash_tests, (
            {
              name         => "hash data, non-rooted path $i/$j/$k/$l",
              data_before  => hash_data(),
              data_after   => $data_after,
              path         => "$i/$j/$k/$l",
              set_value    => $l,
              return_value => $l,
            },
            {
              name         => "hash data, rooted path /$i/$j/$k/$l",
              data_before  => hash_data(),
              data_after   => $data_after,
              path         => "/$i/$j/$k/$l",
              set_value    => $l,
              return_value => $l,
            }
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
          $hash_data{ $names[$i] }{ $names[$j] }{ $names[$k] }{ $name } = 1;
        }
      }
    }
  }

  return \%hash_data;
}
