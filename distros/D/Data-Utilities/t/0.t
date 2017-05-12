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
	  };
}


use Test::More tests => (scalar ( grep { print "$_\n" ; !$_ } values %$disabled_tests ) );

use Data::Comparator qw(data_comparator);
use Data::Transformator;


if (!$disabled_tests->{1})
{
    my $tree;

#     $Data::Dumper::Sortkeys = 1;

    $tree
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
	= new Data::Transformator
	    (
	     name => 'tree-tester',
	     contents => $tree,
	     array_filter =>
	     sub
	     {
#		 my ($context, $component) = @_;

		 $_[0]->{path} =~ m|/b2$| ? 0 : 1;
	     },
	     hash_filter1 =>
	     sub
	     {
#		 my ($context, $hash_key, $hash) = @_;

		 $_[0]->{path} =~ m|/c2| ? 0 : 1;
	     },
	     transformators =>
	     [
	      Data::Transformator::_lib_transform_array_to_hash('b', '->{hash_from_array}'),
	      Data::Transformator::_lib_transform_hash_to_array('c', '->{array_from_hash}'),
	     ],
	    );

    my $transformed_data = $transformation->transform();

    use Data::Dumper;

    print Dumper($transformed_data);

#     my $b_entries_source = scalar @{$tree->{b}};
#     my $b_entries_result = scalar keys %{$transformed_data->{hash_from_array}};

#     my $c_entries_source = scalar keys %{$tree->{c}};
#     my $c_entries_result = scalar @{$transformed_data->{array_from_hash}};

#    print "b entries source $b_entries_source =? b entries result $b_entries_result\n";
#    print "c entries source $c_entries_source =? c entries result $c_entries_result\n";

    my $expected_differences
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
                                 '1' => '-b2',
                                 '0' => '-b1',
                                 '2' => '-b3'
				}
	  };

    my $differences = data_comparator($transformed_data, $expected_differences);

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
    my $devices;

    $devices->{ANT_CTRL}
	= {
	   type     => 'UserDefined',
	   bus      => 'dummy',
	   addr     => 0,
	   equipm_url  => 'USS_MON+main',
	   ok_function => { "USS_MON.ant_ctrl.ntcSeEqSxSwitchControl" => 0, },
	  };

    my $expected_differences
	= {
	   'ANT_CTRL' => {
			  'ok_function' => {
					    'USS_MON.ant_ctrl.ntcSeEqSxSwitchControl' => 0,
					   },
			 },
	  };

    my $transformation
	= Data::Transformator->new
	    (
	     name => 'devices',
	     contents => $devices,
	     transformators =>
	     [
# 	      _lib_transform_array_to_hash('b', '->{hash_from_array}'),
# 	      _lib_transform_hash_to_array('c', '->{array_from_hash}'),
	      sub
	      {
		  my ($transform_data, $context, $contents) = @_;

#		  print STDERR $context->{path}, "\n";

		  # retain functions and ok_function.

		  if ($context->{path} =~ m|^[^/]*/([^/]*)/([^/]*?function[^/]*?)$|)
		  {
		      my $device = $1;
		      my $function = $2;

		      my $result = Data::Transformator::_context_get_main_result($context);

		      $result->{content}->{$device}->{$function}
			  = Data::Transformator::_context_get_current_content($context);

		      return;
		  }

		  if ($context->{path} =~ m|^[^/]*/([^/]*)/([^/]*led[^/]*)$|)
		  {
		      my $device = $1;
		      my $led = $2;

		      my $result = Data::Transformator::_context_get_main_result($context);

		      $result->{content}->{$device}->{$led}
			  = Data::Transformator::_context_get_current_content($context);

		      return;
		  }

	      },
	     ],
	    );

    my $transformed_data = $transformation->transform();

#     use Data::Dumper;

#     print Dumper($transformed_data);

#     my $differences = data_comparator($devices, $transformed_data);

    my $differences = data_comparator($transformed_data, $expected_differences);

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


