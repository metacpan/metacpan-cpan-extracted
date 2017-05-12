#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb
#


use strict;


our $disabled_tests;

BEGIN
{
    $disabled_tests
	= {
	   1 => '',
	   2 => '',
	   3 => 'transformation fails miserably, has never worked I guess',
	   4 => '',
	   5 => '',
	   6 => '',
	   7 => '',
	   8 => '',
	   9 => '',
	   10 => '',
	   11 => '',
	   12 => '',
	   13 => '',
	   14 => '',
	   15 => '',
	   16 => '',
	   17 => '',
	   18 => '',
	   19 => '',
	  };
}


use Test::More tests => (scalar ( grep { print "$_\n" ; !$_ } values %$disabled_tests ) );

use Data::Comparator qw(data_comparator);
use Data::Transformator;


if (!$disabled_tests->{1})
{
    my $tree
	= {
	   a => {
		 a1 => '-a1',
		 a2 => '-a2',
		},
	   b => [
		 '-b1',
		 '-b2',
		 '-b3',
		],
	   c => {
		 c1 => {
			c11 => '-c11',
		       },
		 c2 => {
			c21 => '-c21',
		       },
		},
	   d => {
		 d1 => {
			d11 => {
				d111 => '-d111',
			       },
		       },
		},
	   e => [
		 {
		  e1 => {
			 e11 => {
				 e111 => '-e111',
				},
			},
		 },
		 {
		  e2 => {
			 e21 => {
				 e211 => '-e211',
				},
			},
		 },
		 {
		  e3 => {
			 e31 => {
				 e311 => '-e311',
				},
			},
		 },
		],
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform1',
	     contents => $tree,
	     apply_identity_transformation => 1,
	     #      array_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/b2$| ? 0 : 1;
	     #      },
	     #      hash_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/c2| ? 0 : 1;
	     #      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($tree, $transformed_data);

    if ($differences->is_empty())
    {
	print "$0: 1: success\n";

	ok(1, '1: success');
    }
    else
    {
	print "$0: 1: failed\n";

	ok(0, '1: failed');
    }
}


if (!$disabled_tests->{2})
{
    my $tree
	= {
	   e => [
		 {
		  e1 => {
			 e11 => {
				 e111 => undef,
				},
			},
		 },
		 {
		  e2 => {
			 e21 => {
				 e211 => undef,
				},
			},
		 },
		 {
		  e3 => {
			 e31 => {
				 e311 => undef,
				},
			},
		 },
		],
	  };

    my $expected_data
	= {
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform2',
	     contents => $tree,
	     apply_identity_transformation => {
					       a => 1,
					      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 2: success\n";

	ok(1, '2: success');
    }
    else
    {
	print "$0: 2: failed\n";

	ok(0, '2: failed');
    }
}


if (!$disabled_tests->{3})
{
    my $tree
	= {
	   e => [
		 {
		  e1 => {
			},
		 },
		 {
		  e2 => {
			},
		 },
		 {
		  e3 => {
			},
		 },
		],
	  };

    my $expected_data
	= {
	   e => [
		 {
		  e1 => {
			},
		 },
		],
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform3',
	     contents => $tree,
	     apply_identity_transformation => {
					       e => [
						     1,
						    ],
					      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 3: success\n";

	ok(1, '3: success');
    }
    else
    {
	print "$0: 3: failed\n";

	ok(0, '3: failed');
    }
}


if (!$disabled_tests->{4})
{
    my $tree
	= {
	   e => [
		 {
		 },
		 {
		 },
		 {
		 },
		],
	  };

    # undefined result, do not rely on it

    my $expected_data
	= {
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform4',
	     contents => $tree,
	     apply_identity_transformation => {
					       e => [
						     {
						     },
						     {
						     },
						     {
						     },
						    ],
					      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 4: success\n";

	ok(1, '4: success');
    }
    else
    {
	print "$0: 4: failed\n";

	ok(0, '4: failed');
    }
}


if (!$disabled_tests->{5})
{
    my $tree
	= {
	   a1 => {
		  a1 => '-a11',
		  a2 => '-a12',
		 },
	   a2 => {
		  a1 => '-a21',
		  a2 => '-a22',
		 },
	   a3 => {
		  a1 => '-a31',
		  a2 => '-a32',
		 },
	   a4 => {
		  a1 => '-a41',
		  a2 => '-a42',
		 },
	   a5 => {
		  a1 => '-a51',
		  a2 => '-a52',
		 },
	  };

    my $expected_data
	= {
	   a1 => {
		  a2 => '-a12',
		 },
	   a2 => {
		  a2 => '-a22',
		 },
	   a3 => {
		  a2 => '-a32',
		 },
	   a4 => {
		  a2 => '-a42',
		 },
	   a5 => {
		  a2 => '-a52',
		 },
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => {
					       a1 => {
						      a2 => 1,
						     },
					       a2 => {
						      a2 => 1,
						     },
					       a3 => {
						      a2 => 1,
						     },
					       a4 => {
						      a2 => 1,
						     },
					       a5 => {
						      a2 => 1,
						     },
					      },
	     contents => $tree,
	     name => 'test_transform5',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 5: success\n";

	ok(1, '5: success');
    }
    else
    {
	print "$0: 5: failed\n";

	ok(0, '5: failed');
    }
}


if (!$disabled_tests->{6})
{
    my $tree
	= {
	   a1 => {
		  a2 => '-a12',
		 },
	   a2 => {
		  a2 => '-a22',
		 },
	   a3 => {
		  a2 => '-a32',
		 },
	   a4 => {
		  a2 => '-a42',
		 },
	   a5 => {
		  a2 => '-a52',
		 },
	  };

    my $expected_data
	= {
	   a1 => {
		  'a2' => '-a12'
		 },
	  };

    my $transformation
	= Data::Transformator->new
	    (
 	     apply_identity_transformation => {
					       a1 => 1,
					      },
	     contents => $tree,
	     name => 'test_transform6',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 6: success\n";

	ok(1, '6: success');
    }
    else
    {
	print "$0: 6: failed\n";

	ok(0, '6: failed');
    }
}


if (!$disabled_tests->{7})
{
    my $tree
	= {
	   a => {
		 a1 => '-a1',
		 a2 => '-a2',
		},
	   b => [
		 '-b1',
		 '-b2',
		 '-b3',
		],
	   c => {
		 c1 => {
			c11 => '-c11',
		       },
		 c2 => {
			c21 => '-c21',
		       },
		},
	   d => {
		 d1 => {
			d11 => {
				d111 => '-d111',
			       },
		       },
		},
	   e => [
		 {
		  e1 => {
			 e11 => {
				 e111 => '-e111',
				},
			},
		 },
		 {
		  e2 => {
			 e21 => {
				 e211 => '-e211',
				},
			},
		 },
		 {
		  e3 => {
			 e31 => {
				 e311 => '-e311',
				},
			},
		 },
		],
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform1',
	     contents => $tree,
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_array_to_hash('b', '->{hash_from_array}'),
	      Data::Transformator::_lib_transform_hash_to_array('c', '->{array_from_hash}'),
	     ],
	    );

    my $transformed_data = $transformation->transform();

    my $expected_data
	= {
	   'array_from_hash' => [
				 {
				  'c11' => '-c11'
				 },
				 {
				  'c21' => '-c21'
				 }
				],
	   'hash_from_array' => {
				 '0' => '-b1',
				 '1' => '-b2',
				 '2' => '-b3'
				}
	  };


#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 7: success\n";

	ok(1, '7: success');
    }
    else
    {
	print "$0: 7: failed\n";

	ok(0, '7: failed');
    }
}


if (!$disabled_tests->{8})
{
    my $tree
	= [
	   {
            'agent' => bless( {
			       'log' => {}
                              }, 'NTC::CommandGraph::Test' ),
            'aux' => {
		      'type' => 'label',
		      'label' => sub { "DUMMY" },
		      'graph_id' => 'goto_label_1',
		      'package' => 'NTC::CommandGraph::Test'
                     }
	   },
	   bless( {
                   'agent' => undef,
                   'aux' => {
			     'algorithm' => sub { "DUMMY" },
			     'graph_dependencies' => {
						      'goto_label_1' => 1
						     },
			     'graph_id' => 'goto_2'
                            }
		  }, 'NTC::CommandGraph::Test' ),
	   {
            'agent' => undef,
            'aux' => {
		      'graph_dependencies' => {
					       'goto_label_1' => 'label',
					       'goto_2' => 'command'
					      },
		      'type' => 'goto',
		      'label' => sub { "DUMMY" },
		      'graph_id' => 'goto_goto_1',
		      'package' => 'NTC::CommandGraph::Test'
                     }
	   }
	  ];

    $tree->[1]->{'agent'} = $tree->[0]->{'agent'};
    $tree->[2]->{'agent'} = $tree->[0]->{'agent'};

    my $expected_data
	= [
	   {
            'aux' => {
		      'graph_id' => 'goto_label_1',
                     },
	   },
	   {
            'aux' => {
		      'graph_dependencies' => {
					       'goto_label_1' => 1,
					      },
		      'graph_id' => 'goto_2',
                     },
	   },
	   {
            'aux' => {
		      'graph_dependencies' => {
					       'goto_label_1' => 'label',
					       'goto_2' => 'command',
					      },
		      'graph_id' => 'goto_goto_1',
                     },
	   },
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => [
					       {
						'aux' => 1,
					       },
					       {
						'aux' => 1,
					       },
					       {
						'aux' => 1,
					       },
					      ],
	     contents => $tree,
	     name => 'test_transform8',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 8: extract aux keys from a command graph\n";

	ok(1, '8: extract aux keys from a command graph');
    }
    else
    {
	print "$0: 8: extract aux keys from a command graph\n";

	ok(0, '8: extract aux keys from a command graph');
    }
}


if (!$disabled_tests->{9})
{
    my $tree
	= {
	   0 => {
		 a1 => {
			a2 => '-a12',
		       },
		 a2 => {
			a2 => '-a22',
		       },
		 a3 => {
			a2 => '-a32',
		       },
		 a4 => {
			a2 => '-a42',
		       },
		 a5 => {
			a2 => '-a52',
		       },
		},
	  };

    my $expected_data
	= [
	   {
            'a2' => '-a12'
	   },
	   {
            'a2' => '-a22'
	   },
	   {
            'a2' => '-a32'
	   },
	   {
            'a2' => '-a42'
	   },
	   {
            'a2' => '-a52'
	   }
	  ];

    my $transformation
	= Data::Transformator->new
	    (
# 	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform6',
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_hash_to_array('0', ''),
	     ],
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 9: success\n";

	ok(1, '9: success');
    }
    else
    {
	print "$0: 9: failed\n";

	ok(0, '9: failed');
    }
}


if (!$disabled_tests->{10})
{
    my $tree
	= {
	   0 => {
		 a1 => {
			a1 => '-a11',
			a2 => '-a12',
		       },
		 a2 => {
			a1 => '-a21',
			a2 => '-a22',
		       },
		 a3 => {
			a1 => '-a31',
			a2 => '-a32',
		       },
		 a4 => {
			a1 => '-a41',
			a2 => '-a42',
		       },
		 a5 => {
			a1 => '-a51',
			a2 => '-a52',
		       },
		},
	  };

    my $expected_data
	= [
	   {
            'a2' => '-a12'
	   },
	   {
            'a2' => '-a22'
	   },
	   {
            'a2' => '-a32'
	   },
	   {
            'a2' => '-a42'
	   },
	   {
            'a2' => '-a52'
	   }
	  ];

    my $transformation1
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     hash_filter =>
	     sub
	     {
		 my $context = shift;

		 my $component_key = shift;

		 my $component = shift;

		 my $path = $context->{path};

		 # never filter anything but the fourth entry

		 if ($path !~ m|^([^/]+/){3}([^/]+)|)
		 {
		     return 1;
		 }

		 # filter everything but something named 'a2'

		 if ($component_key eq 'a2')
		 {
		     return 1;
		 }
		 else
		 {
		     return 0;
		 }
	     },
	     name => 'test_transform7a',
	    );

    my $transformed_data1 = $transformation1->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data1);

    my $transformation2
	= Data::Transformator->new
	    (
	     name => 'test_transform7b',
	     source => $transformation1,
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_hash_to_array('0', ''),
	     ],
	    );

    my $transformed_data = $transformation2->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 10: success\n";

	ok(1, '10: success');
    }
    else
    {
	print "$0: 10: failed\n";

	ok(0, '10: failed');
    }
}


if (!$disabled_tests->{11})
{
    my $tree
	= {
	   e => [
		 {
		  e1 => {
			 e11 => {
				 e111 => undef,
				},
			},
		 },
		 {
		  e2 => {
			 e21 => {
				 e211 => undef,
				},
			},
		 },
		 {
		  e3 => {
			 e31 => {
				 e311 => undef,
				},
			},
		 },
		],
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform2',
	     contents => $tree,
	     apply_identity_transformation => 1,
	     #      array_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/b2$| ? 0 : 1;
	     #      },
	     #      hash_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/c2| ? 0 : 1;
	     #      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $tree);

    if ($differences->is_empty())
    {
	print "$0: 11: success\n";

	ok(1, '11: success');
    }
    else
    {
	print "$0: 11: failed\n";

	ok(0, '11: failed');
    }
}


if (!$disabled_tests->{12})
{
    my $tree
	= {
	   e => [
		 {
		  e1 => {
			},
		 },
		 {
		  e2 => {
			},
		 },
		 {
		  e3 => {
			},
		 },
		],
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform3',
	     contents => $tree,
	     apply_identity_transformation => 1,
	     #      array_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/b2$| ? 0 : 1;
	     #      },
	     #      hash_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/c2| ? 0 : 1;
	     #      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $tree);

    if ($differences->is_empty())
    {
	print "$0: 12: success\n";

	ok(1, '12: success');
    }
    else
    {
	print "$0: 12: failed\n";

	ok(0, '12: failed');
    }
}


if (!$disabled_tests->{13})
{
    my $tree
	= {
	   e => [
		 {
		 },
		 {
		 },
		 {
		 },
		],
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform4',
	     contents => $tree,
	     apply_identity_transformation => 1,
	     #      array_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/b2$| ? 0 : 1;
	     #      },
	     #      hash_filter =>
	     #      sub
	     #      {
	     # 	 $_[0]->{path} =~ m|/c2| ? 0 : 1;
	     #      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $tree);

    if ($differences->is_empty())
    {
	print "$0: 13: success\n";

	ok(1, '13: success');
    }
    else
    {
	print "$0: 13: failed\n";

	ok(0, '13: failed');
    }
}


if (!$disabled_tests->{14})
{
    my $tree
	= {
	   a1 => {
		  a1 => '-a11',
		  a2 => '-a12',
		 },
	   a2 => {
		  a1 => '-a21',
		  a2 => '-a22',
		 },
	   a3 => {
		  a1 => '-a31',
		  a2 => '-a32',
		 },
	   a4 => {
		  a1 => '-a41',
		  a2 => '-a42',
		 },
	   a5 => {
		  a1 => '-a51',
		  a2 => '-a52',
		 },
	  };

    my $expected_data
	= {
	   a1 => {
		  a2 => '-a12',
		 },
	   a2 => {
		  a2 => '-a22',
		 },
	   a3 => {
		  a2 => '-a32',
		 },
	   a4 => {
		  a2 => '-a42',
		 },
	   a5 => {
		  a2 => '-a52',
		 },
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     hash_filter =>
	     sub
	     {
		 my $context = shift;

		 my $component_key = shift;

		 my $component = shift;

		 my $path = $context->{path};

		 # never filter anything but the third entry

		 if ($path !~ m|^([^/]+/){2}([^/]+)|)
		 {
		     return 1;
		 }

		 # filter everything but something named 'a2'

		 if ($component_key eq 'a2')
		 {
		     return 1;
		 }
		 else
		 {
		     return 0;
		 }
	     },
	     name => 'test_transform5',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 14: success\n";

	ok(1, '14: success');
    }
    else
    {
	print "$0: 14: failed\n";

	ok(0, '14: failed');
    }
}


if (!$disabled_tests->{15})
{
    my $tree
	= {
	   0 => {
		 a1 => {
			a2 => '-a12',
		       },
		 a2 => {
			a2 => '-a22',
		       },
		 a3 => {
			a2 => '-a32',
		       },
		 a4 => {
			a2 => '-a42',
		       },
		 a5 => {
			a2 => '-a52',
		       },
		},
	  };

    my $expected_data
	= [
	   {
            'a2' => '-a12'
	   },
	   {
            'a2' => '-a22'
	   },
	   {
            'a2' => '-a32'
	   },
	   {
            'a2' => '-a42'
	   },
	   {
            'a2' => '-a52'
	   }
	  ];

    my $transformation
	= Data::Transformator->new
	    (
# 	     apply_identity_transformation => 1,
	     contents => $tree,
	     name => 'test_transform6',
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_hash_to_array('0', ''),
	     ],
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 15: success\n";

	ok(1, '15: success');
    }
    else
    {
	print "$0: 15: failed\n";

	ok(0, '15: failed');
    }
}


if (!$disabled_tests->{16})
{
    my $tree
	= {
	   0 => {
		 a1 => {
			a1 => '-a11',
			a2 => '-a12',
		       },
		 a2 => {
			a1 => '-a21',
			a2 => '-a22',
		       },
		 a3 => {
			a1 => '-a31',
			a2 => '-a32',
		       },
		 a4 => {
			a1 => '-a41',
			a2 => '-a42',
		       },
		 a5 => {
			a1 => '-a51',
			a2 => '-a52',
		       },
		},
	  };

    my $expected_data
	= [
	   {
            'a2' => '-a12'
	   },
	   {
            'a2' => '-a22'
	   },
	   {
            'a2' => '-a32'
	   },
	   {
            'a2' => '-a42'
	   },
	   {
            'a2' => '-a52'
	   }
	  ];

    my $transformation1
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     hash_filter =>
	     sub
	     {
		 my $context = shift;

		 my $component_key = shift;

		 my $component = shift;

		 my $path = $context->{path};

		 # never filter anything but the fourth entry

		 if ($path !~ m|^([^/]+/){3}([^/]+)|)
		 {
		     return 1;
		 }

		 # filter everything but something named 'a2'

		 if ($component_key eq 'a2')
		 {
		     return 1;
		 }
		 else
		 {
		     return 0;
		 }
	     },
	     name => 'test_transform7a',
	    );

    my $transformed_data1 = $transformation1->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data1);

    my $transformation2
	= Data::Transformator->new
	    (
	     name => 'test_transform7b',
	     source => $transformation1,
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_hash_to_array('0', ''),
	     ],
	    );

    my $transformed_data = $transformation2->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 16: success\n";

	ok(1, '16: success');
    }
    else
    {
	print "$0: 16: failed\n";

	ok(0, '16: failed');
    }
}


if (!$disabled_tests->{17})
{
    my $tree
	= [
	   {
            'agent' => bless( {
			       'log' => {}
                              }, 'NTC::CommandGraph::Test' ),
            'aux' => {
		      'type' => 'label',
		      'label' => sub { "DUMMY" },
		      'graph_id' => 'goto_label_1',
		      'package' => 'NTC::CommandGraph::Test'
                     }
	   },
	   bless( {
                   'agent' => undef,
                   'aux' => {
			     'algorithm' => sub { "DUMMY" },
			     'graph_dependencies' => {
						      'goto_label_1' => 1
						     },
			     'graph_id' => 'goto_2'
                            }
		  }, 'NTC::CommandGraph::Test' ),
	   {
            'agent' => undef,
            'aux' => {
		      'graph_dependencies' => {
					       'goto_label_1' => 'label',
					       'goto_2' => 'command'
					      },
		      'type' => 'goto',
		      'label' => sub { "DUMMY" },
		      'graph_id' => 'goto_goto_1',
		      'package' => 'NTC::CommandGraph::Test'
                     }
	   }
	  ];

    $tree->[1]->{'agent'} = $tree->[0]->{'agent'};
    $tree->[2]->{'agent'} = $tree->[0]->{'agent'};

    my $expected_data
	= [
	   {
            'agent' => {},
            'aux' => {
		      'graph_id' => 'goto_label_1'
                     }
	   },
	   {
            'agent' => {},
            'aux' => {
		      'graph_dependencies' => {
					       'goto_label_1' => 1
					      },
		      'graph_id' => 'goto_2'
                     }
	   },
	   {
            'agent' => {},
            'aux' => {
		      'graph_dependencies' => {
					       'goto_label_1' => 'label',
					       'goto_2' => 'command'
					      },
		      'graph_id' => 'goto_goto_1'
                     }
	   }
	  ];

    my $transformation
	= Data::Transformator->new
	    (
	     apply_identity_transformation => 1,
	     contents => $tree,
	     hash_filter =>
	     sub
	     {
		 my $context = shift;

		 my $component_key = shift;

		 my $component = shift;

		 my $path = $context->{path};

		 # never filter anything but the fourth entry

		 if ($path !~ m|^([^/]+/){3}([^/]+)$|)
		 {
		     return 1;
		 }

		 # filter everything but something named 'graph.*'

		 if ($component_key =~ m'graph.*')
		 {
		     return 1;
		 }
		 else
		 {
		     return 0;
		 }
	     },
	     name => 'test_transform8',
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 17: success\n";

	ok(1, '17: success');
    }
    else
    {
	print "$0: 17: failed\n";

	ok(0, '17: failed');
    }
}


if (!$disabled_tests->{18})
{
    my $tree
	= {
	   a => {
		 a1 => '-a1',
		 a2 => '-a2',
		},
	   b => [
		 '-b1',
		 '-b2',
		 '-b3',
		],
	   c => {
		 c1 => {
			c11 => '-c11',
		       },
		 c2 => {
			c21 => '-c21',
		       },
		},
	   d => {
		 d1 => {
			d11 => {
				d111 => '-d111',
			       },
		       },
		},
	   e => [
		 {
		  e1 => {
			 e11 => {
				 e111 => '-e111',
				},
			},
		 },
		 {
		  e2 => {
			 e21 => {
				 e211 => '-e211',
				},
			},
		 },
		 {
		  e3 => {
			 e31 => {
				 e311 => '-e311',
				},
			},
		 },
		],
	  };

    my $expected_data
	= {
	   a => {
		 a1 => '-a1',
		 a2 => '-a2',
		},
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'test_transform1',
	     contents => $tree,
	     apply_identity_transformation => {
					       a => 1,
					      },
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

    my $differences = data_comparator($transformed_data, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 18: success\n";

	ok(1, '18: success');
    }
    else
    {
	print "$0: 18: failed\n";

	ok(0, '18: failed');
    }
}


if (!$disabled_tests->{19})
{
    my $tree
	= {
	   1 => {
		 3 => '6',
		 8 => '11',
		},
	   2 => {
		 3 => '6',
		 8 => '11',
		},
	   3 => {
		 3 => '6',
		 8 => '11',
		},
	   4 => {
		 3 => '6',
		 8 => '11',
		},
	   5 => {
		 3 => '6',
		 8 => '11',
		},
	   12 => {
		  3 => '6',
		  8 => '11',
		 },
	  };

    my $expected_data
	= '0.1.3.6
0.1.8.11
0.2.3.6
0.2.8.11
0.3.3.6
0.3.8.11
0.4.3.6
0.4.8.11
0.5.3.6
0.5.8.11
0.12.3.6
0.12.8.11
';

    my $global_result = '';

    my $transformation
	= Data::Transformator->new
	    (
	     name => '0',
	     contents => $tree,
#	     apply_identity_transformation => 1,
	     sort => sub { $_[0] <=> $_[1] },
	     transformators =>
	     [
	      sub
	      {
		  my ($transform_data, $context, $contents) = @_;

# 		  print STDERR $context->{path}, "\n";

		  my $top = Data::Transformator::_context_get_current($context);

		  if ($top->{type} eq 'SCALAR')
		  {
		      $global_result .= $context->{path} . "\n";
		  }
	      },
	     ],
	    );

    my $transformed_data = $transformation->transform();

    $global_result =~ s|/|.|g;

    print $global_result . "\n";

    my $differences = data_comparator($global_result, $expected_data);

    if ($differences->is_empty())
    {
	print "$0: 19: success\n";

	ok(1, '19: success');
    }
    else
    {
	print "$0: 19: failed\n";

	ok(0, '19: failed');
    }
}


