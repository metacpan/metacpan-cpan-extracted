#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;
use Data::Reach 'each_path';

# test data
my $data = {
  foo => [ undef,
           'abc',
           {bar => {buz => 987}},
           1234,
          ],
  empty_array => [],
  empty_hash  => {},
  empty_slot  => undef,
  qux         => 'qux',
  stringref   => \"ref",
  refref      => \\"ref",
};



{
  my %got_path;
  my $next_path = each_path $data;
  while (my ($path, $val) = $next_path->()) {
    $got_path{join ",", @$path} = $val;
  }
  is_deeply(\%got_path, 
            {   'empty_slot'    => undef,
                'foo,0'         => undef,
                'foo,1'         => 'abc',
                'foo,2,bar,buz' => 987,
                'foo,3'         => 1234,
                'qux'           => 'qux',
                'refref'        => \\'ref',
                'stringref'     => \'ref', },
             'without empty subtrees' );


}


{
  use Data::Reach qw/keep_empty_subtrees/;
  my %got_path;
  my $next_path = each_path $data;
  while (my ($path, $val) = $next_path->()) {
    $got_path{join ",", @$path} = $val;
  }
  is_deeply(\%got_path,
            { 'empty_array'   => [],
              'empty_hash'    => {},
              'empty_slot'    => undef,
              'foo,0'         => undef,
              'foo,1'         => 'abc',
              'foo,2,bar,buz' => 987,
              'foo,3'         => 1234,
              'qux'           => 'qux',
              'refref'        => \\'ref',
              'stringref'     => \'ref',    },
             'with empty subtrees' );
}




