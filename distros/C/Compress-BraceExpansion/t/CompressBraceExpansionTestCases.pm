package CompressBraceExpansionTestCases;
use strict;
use warnings;
use Data::Dumper;

my $test_case_data = [
    { 'expanded' => [ 'abc' ],
      'tree' => { 'ROOT' => { 'a' => { 'b' => { 'c' => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { 'a' => { 'b' => { 'c' => { 'end' => 1 } } } } },
      'compressed' => 'abc',
      'tree_print' => 'abc',
      'merge_point' => 1,
      'description' => 'single string - abc => abc'
  },
    { 'expanded' => [ qw( abc abc ) ],
      'tree' => { 'ROOT' => { 'a' => { 'b' => { 'c' => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { 'a' => { 'b' => { 'c' => { 'end' => 1 } } } } },
      'compressed' => 'abc',
      'tree_print' => 'abc',
      'merge_point' => 1,
      'description' => 'two identical strings - abc abc => abc'
  },
    { 'expanded' => [ qw( ab0 ab0 ) ],
      'tree' => { 'ROOT' => { 'a' => { 'b' => { '0' => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { 'a' => { 'b' => { '0' => { 'end' => 1 } } } } },
      'compressed' => 'ab0',
      'tree_print' => 'ab0',
      'merge_point' => 1,
      'description' => 'two identical strings ending in 0 - ab0 ab0 => ab0'
  },
    { 'expanded' => [ qw( aaa bbb ) ],
      'tree' => { 'ROOT' => { 'a' => { 'a' => { 'a' => { 'end' => 1 } } },
                              'b' => { 'b' => { 'b' => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { 'a' => { 'a' => { 'a' => { 'end' => 1 } } },
                                    'b' => { 'b' => { 'b' => { 'end' => 1 } } } } },
      'compressed' => '{aaa,bbb}',
      'tree_print' => '{aaa,bbb}',
      'merge_point' => undef,
      'description' => 'two strings that share no characters - aaa bbb => {aaa,bbb}'
  },
    { 'expanded' => [ qw( ab ax ) ],
      'tree' => { 'ROOT' => { a => { b => { 'end' => 1 },
                                     x => { 'end' => 1 } } } },
      'tree_merge' => { 'ROOT' => { a => { b => { 'end' => 1 },
                                           x => { 'end' => 1 } } } },
      'compressed' => 'a{b,x}',
      'tree_print' => 'a{b,x}',
      'merge_point' => undef,
      'description' => 'two strings that begin with the same characters - ab ax  => a{b,x}',
  },
    { 'expanded' => [ qw( abc abx ) ],
      'tree' => { 'ROOT' => { a => { b => { c => { 'end' => 1 },
                                            x => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { a => { b => { c => { 'end' => 1 },
                                            x => { 'end' => 1 } } } } },
      'compressed' => 'ab{c,x}',
      'tree_print' => 'ab{c,x}',
      'merge_point' => undef,
      'description' => 'two strings that begin with the same characters - abc abx  => ab{c,x}',
  },
    { 'expanded' => [ qw( abc axc ) ],
      'tree' => { 'ROOT' => { a => { b => { c => { 'end' => 1 } },
                                     x => { c => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { a => { b => { POINTER => 'PID:1001' },
                                           x => { POINTER => 'PID:1001' } } },
                        'POINTERS' => { 'PID:1001' => { 'c' => { 'end' => 1 } } },
              },
      'compressed' => 'a{b,x}c',
      'tree_print' => 'a{bc,xc}',
      'merge_point' => 3,
      'description' => 'two strings that begin and end with the same characters - abc axc  => a{b,x}c',
  },
    { 'expanded' => [ qw( ab xb ) ],
      'tree' => { 'ROOT' => { a => { b => { 'end' => 1 } },
                              x => { b => { 'end' => 1 } } } },
      'tree_merge' => { 'ROOT' => { a => { POINTER => 'PID:1001' },
                                    x => { POINTER => 'PID:1001' } },
                        'POINTERS' => { 'PID:1001' => { 'b' => { 'end' => 1 } } } },
      'compressed' => '{a,x}b',
      'tree_print' => '{ab,xb}',
      'merge_point' => 2,
      'description' => 'two strings that end with the same character - ab xb  => {a,x}b',
  },
    { 'expanded' => [ qw( abc xbc ) ],
      'tree' => { 'ROOT' => { a => { b => { c => { 'end' => 1 } } },
                              x => { b => { c => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { a => { POINTER => 'PID:1001' },
                                    x => { POINTER => 'PID:1001' } },
                        'POINTERS' => { 'PID:1001' => { 'b' => { c => { 'end' => 1 } } } } },
      'compressed' => '{a,x}bc',
      'tree_print' => '{abc,xbc}',
      'merge_point' => 2,
      'description' => 'two strings that end with multiple identical characters - abc xbc  => {a,x}bc',
  },
    { 'expanded' => [ qw( ab xb yb ) ],
      'tree' => { 'ROOT' => { a => { b => { 'end' => 1 } },
                              x => { b => { 'end' => 1 } },
                              y => { b => { 'end' => 1 } } } },
      'tree_merge' => { 'ROOT' => { a => { POINTER => 'PID:1001' },
                                    x => { POINTER => 'PID:1001' },
                                    y => { POINTER => 'PID:1001' } },
                        'POINTERS' => { 'PID:1001' => { 'b' => { 'end' => 1 } } } },
      'compressed' => '{a,x,y}b',
      'tree_print' => '{ab,xb,yb}',
      'merge_point' => 2,
      'description' => 'three strings that end with one identical characters - ab xb yb  => {a,x,y}b',
  },
    { 'expanded' => [ qw( abc xbc ybc ) ],
      'tree' => { 'ROOT' => { a => { b => { c => { 'end' => 1 } } },
                              x => { b => { c => { 'end' => 1 } } },
                              y => { b => { c => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { a => { POINTER => 'PID:1001' },
                                    x => { POINTER => 'PID:1001' },
                                    y => { POINTER => 'PID:1001' } },
                        'POINTERS' => { 'PID:1001' => { 'b' => { c => { 'end' => 1 } } } } },
      'compressed' => '{a,x,y}bc',
      'tree_print' => '{abc,xbc,ybc}',
      'merge_point' => 2,
      'description' => 'three strings that end with multiple identical characters - abc xbc  => {a,x}bc',
  },
    { 'expanded' => [ qw( abc abcd ) ],
      'tree' => { 'ROOT' => { 'a' => { 'b' => { 'c' => { 'end' => 1, d => { 'end' => 1 } } } } } },
      'tree_merge' => { 'ROOT' => { 'a' => { 'b' => { 'c' => { 'end' => 1, d => { 'end' => 1 } } } } } },
      'compressed' => 'abc{d,}',
      'tree_print' => 'abc{d,}',
      'merge_point' => undef,
      'description' => 'one string is a substring of another string - abc abcd => abc{d,}'
  },
    { 'expanded' => [ qw( abc abx aby ) ],
      'tree' => { 'ROOT' => { a => { b => { c => { 'end' => 1 },
                                            x => { 'end' => 1 },
                                            y => { 'end' => 1 } } } } },
      'tree_merge' => { 'ROOT' => { a => { b => { c => { 'end' => 1 },
                                                  x => { 'end' => 1 },
                                                  y => { 'end' => 1 } } } } },
      'compressed' => 'ab{c,x,y}',
      'tree_print' => 'ab{c,x,y}',
      'merge_point' => undef,
      'description' => 'three strings that begin with the same characters - abc abx aby  => ab{c,x,y}',
  },
];

sub get_next_test_case {
    # get the next test case from the array
    my $next_test_case = shift @{ $test_case_data };

    # and send it back
    return $next_test_case;
}



1;



# +    { 'expanded' => [ qw( abcdf abcef xxxf xzzf ) ],
# +      'tree' => { 'ROOT' => {
# +                      'a' => {
# +                               'b' => {
# +                                        'c' => {
# +                                                 'e' => {
# +                                                          'f' => {
# +                                                                   'end' => 1
# +                                                                 }
# +                                                        },
# +                                                 'd' => {
# +                                                          'f' => {
# +                                                                   'end' => 1
# +                                                                 }
# +                                                        }
# +                                               }
# +                                      }
# +                             },
# +                      'x' => {
# +                               'x' => {
# +                                        'x' => {
# +                                                 'f' => {
# +                                                          'end' => 1
# +                                                        }
# +                                               }
# +                                      },
# +                               'z' => {
# +                                        'z' => {
# +                                                 'f' => {
# +                                                          'end' => 1
# +                                                        }
# +                                               }
# +                                      }
# +                             }
# +                    } },
# +      'tree_merge' => undef,
# +      'compressed' => '{abc{d,e},x{xx,zz}}f',
# +      'tree_print' => '{abc{d,e},x{xx,zz}}f',
# +      'merge_point' => undef,
# +      'description' => 'four branches that converge at the end - abcdf abcef xxxf xzzf  => {abc{d,e},x{xx,zz}}f',
# +  },
