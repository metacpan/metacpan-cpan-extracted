#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb -w
#
# This is module is based on a module with the same name, implemented
# when working for Newtec Cy, located in Belgium,
# http://www.newtec.be/.
#

=head1 NAME

Data::Transformator - transform nested Perl data structures.

=head1 SYNOPSIS

   From one of the test cases:

    use Data::Transformator;

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

    use Data::Comparator qw(data_comparator);

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

=head1 DESCRIPTION

Data::Transformator allows to transform a nested perl data structure
-- the source data -- in a new nested perl data structure -- the
result data. The source nested data structure can contain perl hashes,
arrays and scalars, but should not be self-referential (if I remember
well, the existing protection against self-referential data structures
in the transformator engine is currently broken).

=head1 USE

Running a transformation can be done in two essentially different
ways:

=over 2

=item

extract data from an existing source : the transformation applies an
identity transformation (meaning copy the source structure to the
result), and during the process it uses selectors to select what data
from the source to copy to the result. The result automatically
inherits the structure from the source. This is called a selective
transformation.  Use the key 'apply_identity_transformation' to enable
this mode.

=item

copy data from source to result : the transformation must be told what
the exact structure of the result is, before the result data can be
inserted into the result. This is called a constructive
transformation.

=back

It is possible to combine the two above in a single run, but that is
currently not tested enough to be sure it works alright, so be very
careful with that.

To use Data::Transformator, you have to

=over 2

=item 1

Construct the transformation with appropriate options:

=over 2

=item

Give the transformation a name, the name describes the purpose and/or
activities for the transformation.

=item

Tell the transformation if you want it to run as a selective
transformation or not (option name
'apply_identity_transformation'). Transformations can always be used
as constructive transformations.

=item

Tell the transformation how to find the data source.

=over 2

=item

Or the data source is literal content (option name 'contents').

=item

Or the data source is an object that implements a '->generate()'
method (option name 'source'). Transformations implement themselves a
'->generate()' method such that transformations can be cascaded
easily.

=back

=item

Tell the transformation what to transform (selection) and how to
transform (generate result).  Data::Transformator uses code references
to generate results, of alternatively simpler things as explained
below.  Whenever a code reference is used, it is called with the
arguments (self, context, current_content).  Here, self is the
Data::Transformator object, context is an object that describes the
current context in the source data structure, current_content is the
generated result so far.  $context->{path} contains a string with the
path to the current element.  Compononents of the path are '/'
separated (unless overwritten with the constructor key 'separator').
This can be used for regular matching, and is especially handy using
'simple_transformators', see below.

Following keys are available to the constructor of
Data::Transformator:

=over 2

=item ->{simple_transformators}

Is an array of simple_transformators.  Each simple_transformator is a
hash with a 'matcher' key that contains a regular expression that is
matched with the path of the currently selected element.  If there is
a match, the selected subtree is put in the end result, under the
value of the 'key' element of the simple_transformator (creating a
hash in the result if necessary).  If there is no 'key' element in the
simple_transformator, a 'code' element is looked for, which is a code
reference.  The code is called to insert an appropriate result.

=item ->{transformators}

Is an array of transformators.  Each transformator is code reference
that gets called as usual.

=item ->{apply_identity_transformation}

Contains a nested perl data structure that reflects the structure of
the source data.  All data of the source that is selected by scalars
that evaluate to true in the content of apply_identity_transformation,
is inserted in the result.  This key is very handy for selecting a set
of small portions of data, if the structure of the source is known
beforehand.

=back

Take a look at existing examples, e.g. in the unit tests of the
transformation engine.

=back

=item 2

Call the '->transform()' method on the transformator.

=item 3

Use the result data that is returned by the '->transform()' method.

=back


=head1 The transformation library

There is a small transformation library embedded in the
Data::Transformator. This library currently allows to

=over 2

=item

transform an array to be found somewhere in the data source to a hash
in the result set.

=item

transform a hash to be found somewhere in the data source to an array
in the result set.

=back

The library generates closures that work on the source data.


=head1 BACKGROUND

For the interested reader, please follow these reasoning steps:

=over 2

=item 1

A database query of a relational database (using tables and nested
tabled) can always be written out in one of the XML query dialects.

=item 2

Following from point 1: a database query can be expressed as a
structured query.

=item 3

A structured query can be summarized as

=over 2

=item 1

a selection of data from a preexisting data source.

=item 2

a structural simplification of the selection.

=back

=item 4

Combining the above: a query can be defined as applying (1) a
selective transformation and (2) a constructive transformation in
sequence to a preexisting data source. This is called cascaded
transformations.

=back

=head1 BUGS

Does only work with scalars, hashes and arrays.  Support for
self-referential structures seems broken at the moment.

=head1 AUTHOR

Hugo Cornelis, hugo.cornelis@gmail.com

Copyright 2007 Hugo Cornelis.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Data::Merger(3), Data::Comparator(3), Clone(3)

=cut


package Data::Transformator;


use strict;
use Data::Dumper;


my $debug_enabled = '0';

my $debug_context = '0';

my $debug_identity_transform = '0';

my $debug_identity_transform2 = '0';

my $debug_identity_transform3 = '0';

my $separator = "/";


sub _apply_identity_transformation
{
    my $self = shift;

    my $context = shift;

    my $current = _context_get_current($context);

    my $result_current = _context_get_current_result($context);

    my $previous = _context_get_previous($context);

    my $result_previous = _context_get_previous_result($context);

    my $previous_type = $previous->{type};

    #! Do not change the order of the tests, it does harm, though it should
    #! not.  I do not know what is happening.

    # fill in constants

    if ($current->{type} eq 'SCALAR')
    {
	my $content = _context_get_current_content($context);

	# fill in the constant

	$result_current->{content} = $content;

	if ($debug_identity_transform)
	{
	    print STDERR "_apply_identity_transformation() for constant $content\n";

	    if ($debug_identity_transform2)
	    {
		print STDERR Data::Dumper::Dumper($result_current);
	    }
	}

    }

    # link items on stack by looking at the type of one level up

    # if the previous result is the root

    if ($previous_type eq 'ROOT')
    {
	# we do not have a result yet, get one by assigning (initialization)

	$result_previous->{content} = $result_current->{content};
    }
    elsif ($previous_type eq 'HASH')
    {
	my $previous_component_key = $previous->{component_key};

	$result_previous->{content}->{$previous_component_key}
	    = $result_current->{content};

	if ($debug_identity_transform2)
	{
	    my $component_key = $previous->{component_key};

	    my $content = $result_current->{content};

	    print STDERR "Default Transform : added to previous hash for key $component_key\n";
	    print STDERR Data::Dumper::Dumper($content);
	    print STDERR "Default Transform : results in\n";
	    print STDERR Data::Dumper::Dumper($result_previous);
	    print STDERR "Default Transform : end\n";
	}
    }
    elsif ($previous_type eq 'ARRAY')
    {
	push @{$result_previous->{content}}, $result_current->{content};

	if ($debug_identity_transform2)
	{
	    my $component_key = $previous->{component_key};

	    my $content = $result_current->{content};

	    print STDERR "Default Transform : added to previous array, item $component_key\n";
	    print STDERR Data::Dumper::Dumper($content);
	    print STDERR "Default Transform : results in\n";
	    print STDERR Data::Dumper::Dumper($result_previous);
	    print STDERR "Default Transform : end\n";
	}
    }
    else
    {
	if ($debug_identity_transform)
	{
	    print STDERR "_apply_identity_transformation(): Illegal context type $previous_type\n";

	    if ($debug_identity_transform2)
	    {
		print STDERR Data::Dumper::Dumper($context, $previous, $current);
	    }
	}
    }

    if ($debug_identity_transform3)
    {
	print STDERR "_apply_identity_transformation() main result is now\n", Dumper($context->{result});
    }
}


sub _apply_transformations
{
    my $self = shift;

    my $context = shift;

    my $component_key = shift;

    my $component = shift;

#     # if the default transformation is enabled (i.e. straight copy)

#     if ($self->{apply_identity_transformation})
#     {
# 	$self->_apply_identity_transformation($context);
#     }

    # if the component_key is defined

    #! note that component_keys are always defined for hashes and arrays, but
    #! not for scalars.  This is currently a bug.

    if (defined $component_key)
    {
	# apply user transformations

	$self->_apply_user_transformations($context, $component_key, $component, );
    }
}


sub _apply_user_transformations
{
    my $self = shift;

    my $context = shift;

    my $component_key = shift;

    my $component = shift;

    my $array = $context->{array};

    # simple regex transforms (based on sems_system module)

    if (exists $self->{simple_transformators})
    {

    SIMPLE_TRANSFORM:
	foreach my $transformator (@{$self->{simple_transformators}})
	{
	    my $matcher = $transformator->{matcher};

	    if ($context->{path} =~ m|$matcher|)
	    {
#		print STDERR "Calling transformator : $transformator->{name}\n";

		# a simple one-to-one mapping

		if (exists $transformator->{key})
		{
		    my $result_key = $transformator->{key};

		    #t why do I fetch the main result here ?
		    #t I should be fetching the current result ?

		    #t Perhaps I could use $result_key in an eval string
		    #t to allow nested results for simple transformators.

		    my $result = _context_get_main_result($context);

		    $result->{content}->{$result_key}
			= _context_get_current_content($context);
		}

		# possibly a one-to-many mapping

		elsif (exists $transformator->{code})
		{
		    my $code = $transformator->{code};

		    my $result = _context_get_main_result($context);

		    my $current_content
			= _context_get_current_content($context);

		    my $transformation_result
			= &$code($self, $context, $current_content, );

		    if ($transformation_result)
		    {
			#! expensive copy, can be replaced with a loop

			if (exists $result->{content}
			    && defined $result->{content})
			{
			    $result->{content}
				= {
				   %{$result->{content}},
				   %$transformation_result,
				  };
			}
			else
			{
			    $result->{content}
				= {
				   %$transformation_result,
				  };
			}
		    }
		}

		last SIMPLE_TRANSFORM;
	    }
	    else
	    {
#		print STDERR "$context->{path} does not match with $matcher\n";
	    }
	}
    }

    # general transformators

    if (exists $self->{transformators})
    {
	my $count = 0;

	foreach my $transformator (@{$self->{transformators}})
	{
	    $count++;

#	    print STDERR "Calling transformator $count\n"; #$transformator->{name}\n";

	    &$transformator($array->[$#$array], $context, $component);
	}
    }
}


sub _result_create
{
    my $default_result = shift;

    return {
	    content => $default_result,
	   };
}


sub _context_create
{
    my $base_path = shift;

    my $base_result = shift;

    my $separator = shift || "/";

    #t the root contains the complete result, the other entries in the
    #t array are sub results, which are to be covered by the root
    #t result.

    my $context
	= {
	   array => [
		     {
		      result => _result_create($base_result),
		      type => 'ROOT',
		     }
		    ],
	   path => $base_path,
	   separator => $separator,
	  };

    $context->{result} = $context->{array}->[0]->{result};

    return $context;
}


#
# Obtain a ref. containing info of the top element of the current context.
#

sub _context_get_current
{
    my $context = shift;

    my $array = $context->{array};

    my $current = $array->[$#$array];

    return $current;
}


#
# Obtain the original content of the top element of the current context.  The
# original content is taken from the original element.  Must be considered
# read-only, and for informational purposes only.  Do not embed it into the
# result, since if so, you are mixing the content of the original data
# structure with the resulting data structure, which is not the intent of this
# module.  Perhaps in the future this can be changed, to allow creation of
# simplified views on a complicated data structure.
#

sub _context_get_current_content
{
    return _context_get_current($_[0])->{content};
}


#
# Obtain information of the resulting content of the top element of the
# current context.  The actual content of the result can be found ->{content}.
#

sub _context_get_current_result
{
    return _context_get_current($_[0])->{result};
}


#
# Obtain information of the main content of the current context.  The actual
# content of the result can be found ->{content}.
#

sub _context_get_main_result
{
    return $_[0]->{result};
}


#
# Obtain a ref. containing info of the next-to-top element of the current
# context.
#

sub _context_get_previous
{
    my $context = shift;

    my $array = $context->{array};

    my $top_index = $#$array;

    if ($top_index > 0)
    {
	my $current = $array->[$#$array - 1];

	return $current;
    }
    else
    {
	return undef;
    }
}


#
# Obtain information of the next-to-top result of the context.  The actual
# content of the result can be found ->{content}.
#
# returns undef if there is no such item.
#

sub _context_get_previous_result
{
    my $previous = _context_get_previous($_[0]);

    if ($previous)
    {
	return $previous->{result};
    }
    else
    {
	return undef;
    }
}


sub _context_get_seen_info
{
    return($_[0]->{seen}->{$_[1]});
}


sub _context_has_seen
{
    return(exists $_[0]->{seen}->{$_[1]});
}


sub _context_matches
{
    #t we could do fancy things, e.g. if $_[1] is a 'context
    #t describing' hash, convert hash to string before comparing.

    return $_[0]->{path} =~ /$_[1]/;
}


sub _context_pop
{
    my $context = shift;

    my $separator = $context->{separator};

    pop @{$context->{array}};

    $context->{path} =~ s/^(.*[^\\])$separator.*/$1/;

    if ($debug_context)
    {
	print STDERR "($context->{path}) _context_pop()\n";
    }
}


sub _context_push
{
    my $context = shift;

    my $new = shift;

    my $separator = $context->{separator};

    $new->{result} = _result_create($new->{default_result});

    push @{$context->{array}}, $new;

    $context->{path} .= "${separator}__NONE__";

    if ($debug_context)
    {
	print STDERR "($context->{path}) _context_push(), default_result $new->{default_result}\n";
    }
}


sub _context_register_current
{
    my $context = shift;

    my $transform = shift;

    my $component_key = shift;

    my $component = shift;

    my $count = shift;

    my $separator = $context->{separator};

    my $array = $context->{array};

    #t actually I think I need an _context_unregister_current() sub
    #t that resets ->{string}, ->{display}, and possibly others.

#    print STDERR "($separator), $component, $component_key\n";

    if ($component_key)
    {
	$component_key =~ s|$separator|\\${separator}|g;
    }

    $array->[$#$array]->{current} = $count;
    $array->[$#$array]->{component_key}
	= defined $component_key ? $component_key : '__UNDEF__';
#    $array->[$#$array]->{string} = undef;
#    $array->[$#$array]->{type} = ref $component || 'SCALAR';
    $array->[$#$array]->{content} = $component;

    if ($debug_enabled)
    {
	print
	    STDERR
		" " x (2 * $#$array)
		    . "$array->[$#$array]->{type} : $array->[$#$array]->{component_key}\n";
    }

    $context->{path}
	=~ s|(.*[^\\]$separator).*|$1$array->[$#$array]->{component_key}|;

    if ($debug_context)
    {
	print STDERR "($context->{path}) [_context_register_current($array->[$#$array]->{component_key})]\n";
    }
}


sub _context_set_seen_info
{
    $_[0]->{seen}->{$_[1]} = $_[2];
}


sub _transform_any
{
    my $self = shift;

    my $context = shift;

    my $contents = shift;

    my $result;

    my $contents_output
	= defined $contents ? $contents : '__UNDEF__';

    #t The problem is as follows : the current is not pushed on the context,
    #t so we consult the wrong entry to compute the result.
    #t Second this result may only be computed if the default transform
    #t is enabled.

    if (_context_has_seen($context, $contents_output) && 0)
    {
	my $seen_info = _context_get_seen_info($context, $contents_output);

	if ($debug_context)
	{
	    print STDERR "For context $context->{path}, we have seen $contents_output, $seen_info\n";
	}

	$result = $seen_info;

	return $result;
    }

    _context_set_seen_info($context, $contents_output, $contents_output);

    local $_ = ref($contents);

    if (!$_)
    {
	# a constant.

	if ($debug_enabled)
	{
	    print STDERR "$self->{name} : Constant ($contents_output)\n";
	}

	$result = $self->_transform_constant($context, $contents);
    }
    else
    {
    BASE_TYPE:
	{
	    # an array.

	    /^ARRAY$/ and do
	    {
		if ($debug_enabled)
		{
		    print STDERR "$self->{name} : Array ($contents_output)\n";
		}

		$result = $self->_transform_array($context, $contents);

		last BASE_TYPE;
	    };

	    # a hash

	    /^HASH$/ and do
	    {
		if ($debug_enabled)
		{
		    print STDERR "$self->{name} : Hash ($contents_output)\n";
		}

		$result = $self->_transform_hash($context, $contents);

		last BASE_TYPE;
	    };

	    # an object.

	    if ($debug_enabled)
	    {
		print STDERR "$self->{name} : Object ($_)\n";
	    }

	    local $_ = $contents_output;

	OBJECT_TYPE:
	    {
		/=HASH/ and do
		{
		    if ($debug_enabled)
		    {
			print STDERR "$self->{name} : Object hash ($contents_output)\n";
		    }

		    $result = $self->_transform_hash($context, $contents);

		    last OBJECT_TYPE;
		};

		/=ARRAY/ and do
		{
		    if ($debug_enabled)
		    {
			print STDERR "$self->{name} : Object Array ($contents_output)\n";
		    }

		    $result = $self->_transform_array($context, $contents);

		    last OBJECT_TYPE;
		};

		#t implement.
		#t
		#t This is meant for easy extensibility.
		#t Probably it is the most convenient if we force the object to
		#t implement an agreed upon interface.
		#t
		#t use UNIVERSAL::isa() and perhaps UNIVERSAL::can() to check if
		#t the interface is implemented by the object.
		#t
		#t perform a default action for hashes and arrays if the object
		#t does not implement a suitable interface, allow the user to
		#t configure or change the default action.
		#t

		#$str .= $self->_formalize_object($context, $contents);
	    }
	}
    }

    my $current_result = _context_get_current_result($context);

    _context_set_seen_info($context, $contents_output, $current_result->{content});

    return($result);
}


sub _transform_array
{
    my $self = shift;

    my $context = shift;

    my $contents = shift;

    my $array = $context->{array};

    my $count = 0;

    my $result = [];

    _context_push(
		  $context,
		  {
#		   contents => $contents,
		   current => 0,
		   default_result => [], #$result,
		   component_key => '__NONE__',
		   size => scalar @$contents,
#		   recurse => 1,
#		   string => undef,
		   type => 'ARRAY',
		  },
		 );

    # if the default transformation is enabled (i.e. straight copy)

    if ($self->{apply_identity_transformation})
    {
	$self->_apply_identity_transformation($context);
    }

    # the sort is quite useless in this form : has no clue of nesting
    # of $contents.

    #t given an array of (sort(), <regex>) tuples, match <regex> with
    #t current component, if matches, apply associated sorting
    #t function.
    #t
    #t this is quite close to transformations too.

    #! note that this assumes that perl sort is order preserving.  The man page
    #! of perl sort says that it is 'stable' i.e. order preserving.

    foreach my $component (sort
			   {
			       defined $self->{sort}
				   ? &{$self->{sort}}
				       (
					$a,
					$b,
					$contents->{$a},
					$contents->{$b},
					$context,
				       )
					   : 0;
			   }
			   @$contents)
    {
	# compute the component key

	my $component_key = '[' . $count . ']';

	# register the name and count of current column

	_context_register_current
	    ($context,
	     $self,
	     $component_key,
	     $component,
	     $count);

	# increment count (before applying filters)

	$count++;

	#
	# array_filter return values :
	#
	# 0 : do not recurse.
	# 1 : do recurse.
	#

	my $filter_data = 1;

	if (exists $self->{array_filter})
	{
	    $filter_data = &{$self->{array_filter}}($context, $component);
	}

	next if $filter_data eq 0;

	# apply transformations

	$self->_apply_transformations($context, $component_key, $component);

	# transform content of array

	push @$result, $self->_transform_any($context, $component);
    }

    if (scalar @$contents eq 0)
    {
	# apply transformations

	$self->_apply_transformations($context, undef, undef,);
    }

    # remove this column

    _context_pop($context);

    return($result);
}


sub _transform_constant
{
    my $self = shift;

    my $context = shift;

    my $contents = shift;

    my $result = '';

    _context_push(
		  $context,
		  {
#		   contents => $contents,
		   current => 0,
		   default_result => '', #$result,
		   component_key => '__NONE__',
		   size => 1,
#		   recurse => 1,
#		   string => undef,
		   type => 'SCALAR',
		  },
		 );

    if ($debug_enabled)
    {
	print STDERR "    # register the name and count of current column\n";
    }

    # register the name and count of current column

    _context_register_current($context, $self, $contents, $contents, 0);

    # if the default transformation is enabled (i.e. straight copy)

    if ($self->{apply_identity_transformation})
    {
	$self->_apply_identity_transformation($context);
    }

    if (defined $contents)
    {
	$result .= $contents;
    }
    else
    {
	$result .= '__UNDEF__';
    }

    # apply transformations

    $self->_apply_transformations($context, $contents, $contents, );

    # remove this column

    _context_pop($context);

    return($result);
}


sub _transform_hash
{
    my $self = shift;

    my $context = shift;

    my $contents = shift;

    my $count = 0;

    my $result = {};

    _context_push(
		  $context,
		  {
#		   contents => $contents,
		   current => 0,
		   default_result => {}, #$result,
		   component_key => '__NONE__',
		   size => scalar keys %$contents,
#		   recurse => 1,
#		   string => undef,
		   type => 'HASH',
		  },
		 );

    # if the default transformation is enabled (i.e. straight copy)

    if ($self->{apply_identity_transformation})
    {
	$self->_apply_identity_transformation($context);
    }

    # the sort is quite useless in this form : has no clue of nesting
    # of $contents.

    #t given an array of (sort(), <regex>) tuples, match <regex> with
    #t current component, if matches, apply associated sorting
    #t function.
    #t
    #t this is quite close to transformations too.

    foreach my $component_key (sort
			       {
				   defined $self->{sort}
				       ? &{$self->{sort}}
					   (
					    $a,
					    $b,
					    $contents->{$a},
					    $contents->{$b},
					    $context,
					   )
					       : $a cmp $b;
			       }
			       keys %$contents)
    {
	my $component = $contents->{$component_key};

	# register name and count of current column

	_context_register_current($context, $self, $component_key, $component, $count);

	# increment count (before applying filters)

	$count++;

	#
	# hash_filter return values :
	#
	# 0 : do not recurse.
	# 1 : do recurse.
	#

	my $filter_data = 1;

	if (exists $self->{hash_filter})
	{
	    $filter_data
		= &{$self->{hash_filter}}($context, $component_key, $component);
	}

	next if $filter_data eq 0;

	# apply transformations

	$self->_apply_transformations($context, $component_key, $component);

	# transform component

	$result->{$component_key} = $self->_transform_any($context, $component);
    }

    if (scalar keys %$contents eq 0)
    {
	# apply transformations

	$self->_apply_transformations($context, undef, undef, );
    }

    # remove this column

    _context_pop($context);

    return($result);
}


#
# generate()
#
# Generate data resulting from this transformation.  This is particularly
# useful when cascading transformations.
#

sub generate
{
    my $self = shift;

    # we are being used in a transformation cascade of some sort

    return $self->transform();
}


sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = { @_ };

    bless ($self, $class);

    return $self;
}


sub transform
{
    my $self = shift;

    my $contents = shift;

    # construct data to be transformed

    my $data = $contents || $self->{contents};

    # if there is a cascade from a related object

    if (!$data
        && $self->{source})
    {
	# construct the data from the source

	my $source = $self->{source};

	$data = $source->generate();
    }

    # initialize the working context of the transformation

    my $context = _context_create($self->{name}, $self->{context_separator}, );

    # $self->{result} is a literal copy of the original, the
    # construction of this copy will probably be removed later on for
    # reasons of efficiency.

    $self->{result} = $self->_transform_any($context, $data);

    return $context->{result}->{content};
}


# small convenience library : common transforms of hashes and arrays.
#
# note that transformators simply copy the root of a sub-tree (with
# the sub-tree beneath), such that the filters applied to the sub-tree
# do not interfere anymore with the result.  This is currently a
# deliberate choice for (1) ease of implementation, (2) performance..

# transform an array with given name to a hash with hash_keys as the array
# indices.  Use an additional prefix to nest the result.

sub _lib_transform_array_to_hash
{
    my $array_name = shift;

    my $prefix = shift;

    if (!$prefix)
    {
	$prefix = '';
    }

    my $array_name_quoted = quotemeta $array_name;

    return
	sub
	{
	    my ($transform_data, $context, $contents) = @_;

#	    print STDERR $context->{path}, "\n";

	    # initialize library sub private variables

	    if ($context->{path} =~ m|[^/]/$array_name_quoted$|)
	    {
		my $result = _context_get_main_result($context);

		return;
	    }

	    if ($context->{path} =~ m|[^/]/$array_name_quoted/\[([0-9])*\]$|)
	    {
#		print STDERR "Setting result for $context->{path}\n";

		my $component = $1;

		my $result = _context_get_main_result($context);

		my $eval = 1;

		if ($eval)
		{
		    # $prefix is interpolated during compilation if this code,
		    # the other variables are interpolated during the eval.
		    #
		    # note the use of single and double quotes.

		    my $command
			#		    = '$result->{content}${prefix}->{$component} = undef;';
			= '#print STDERR Dumper($result, $component);
$result->{content}' . "$prefix" . '->{$component} = undef;';

		    eval $command;
		}
		else
		{
#		    print STDERR Dumper($result); print STDERR Dumper($component);
		    $result->{content}->{$component} = undef;
		}

		return;
	    }

	    if ($context->{path} =~ m|[^/]/$array_name_quoted/\[([0-9])*\]/[^/]+$|)
	    {
		my $component = $1;

		my $result = _context_get_main_result($context);

		my $eval = 1;

		if ($eval)
		{
		    # $prefix is interpolated during execution if this code,
		    # the other variables are interpolated during the eval.
		    #
		    # note the use of single and double quotes.

		    my $command
			#		    = '$result->{content}${prefix}->{$component} = _context_get_current_content($context);';
			= '#print STDERR Dumper($result, $component);
$result->{content}' . "$prefix" . '->{$component} = _context_get_current_content($context);';

		    eval $command;
		}
		else
		{
#		    print STDERR Dumper($result); print STDERR Dumper($component);
		    $result->{content}->{$component} = _context_get_current_content($context);
		}

		return;
	    }
	};
}


# transform the entries of a hash with given name to an array in the
# result.  The result is nested with a given prefix.

sub _lib_transform_hash_to_array
{
    my $hash_name = shift;

    my $prefix = shift;

    if (!$prefix)
    {
	$prefix = '';
    }

    my $hash_name_quoted = quotemeta $hash_name;

    return
	sub
	{
	    my ($transform_data, $context, $contents) = @_;

#	    print STDERR $context->{path}, "\n";

	    # initialize library sub private variables

	    if ($context->{path} =~ m|[^/]/$hash_name_quoted$|)
	    {
		my $result = _context_get_main_result($context);

		$result->{library}->{"_lib_transform_hash_to_array"} = 0;

		return;
	    }

	    if ($context->{path} =~ m|[^/]/$hash_name_quoted/([^/])*$|)
	    {
#		print STDERR "Setting result for $context->{path}\n";

		my $component_key = $1;

		my $result = _context_get_main_result($context);

		my $eval = 1;

		if ($eval)
		{
		    # $prefix is interpolated during execution of this code,
		    # the other variables are interpolated during the eval.
		    #
		    # note the use of single and double quotes.

		    my $command
			#		    = '$result->{content}${prefix}->{$component_key} = _context_get_current_content($context);';
			= '#print STDERR Dumper($result, $component_key);
$result->{content}' . "${prefix}->[$result->{library}->{_lib_transform_hash_to_array}]" . ' = $contents;';

		    eval $command;

#		    print STDERR Dumper($result, $component_key);
		}
		else
		{
#		    print STDERR Dumper($result);
		    $result->{content}->[$component_key] = $contents;
		}

		$result->{library}->{"_lib_transform_hash_to_array"} += 1;

		return;
	    }
	};
}


# test sub : test the functionality of Data::Transformator.

sub _main
{
    my $tree;
    my $tree1;

    $Data::Dumper::Sortkeys = 1;

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

#     my $config = do '/var/sems/sems.config';

    my $config = {};

    my $devices;

    $devices->{ANT_CTRL} =
    {
     type     => 'UserDefined',
     bus      => 'dummy',
     addr     => 0,
     equipm_url  => 'USS_MON+main',
     ok_function => { "USS_MON.ant_ctrl.ntcSeEqSxSwitchControl" => 0, },
    };

#     $devices = $config->{devices};

    my $transformation1
	= new Data::Transformator
	    (
	     name => 'tree-tester',
	     contents => $tree->{devices} ? $tree->{devices} : $tree,
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
	      _lib_transform_array_to_hash('b', '->{hash_from_array}'),
	      _lib_transform_hash_to_array('c', '->{array_from_hash}'),
	     ],
	    );

    my $result1 = $transformation1->transform();

    print Dumper($result1);

    my $b_entries_source = scalar @{$tree->{b}};
    my $b_entries_result = scalar keys %{$result1->{hash_from_array}};

    my $c_entries_source = scalar keys %{$tree->{c}};
    my $c_entries_result = scalar @{$result1->{array_from_hash}};

#    print "b entries source $b_entries_source =? b entries result $b_entries_result\n";
#    print "c entries source $c_entries_source =? c entries result $c_entries_result\n";

    my $transformation2
	= new Data::Transformator
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

		      my $result = _context_get_main_result($context);

		      $result->{content}->{$device}->{$function}
			  = _context_get_current_content($context);

		      return;
		  }

		  if ($context->{path} =~ m|^[^/]*/([^/]*)/([^/]*led[^/]*)$|)
		  {
		      my $device = $1;
		      my $led = $2;

		      my $result = _context_get_main_result($context);

		      $result->{content}->{$device}->{$led}
			  = _context_get_current_content($context);

		      return;
		  }

	      },
	     ],
	    );

#     my $result2 = $transformation2->transform();

#     print Dumper($result2);

}


1;


