#===============================================
package Banal::Utils::Data;

use 5.006;
use utf8;
use strict;
use warnings;
no  warnings qw(uninitialized);

require Exporter;

our @ISA 		= qw(Exporter);
our @EXPORT_OK 	= qw(   banal_get_data 
						flatten_complex_data_to_list 
						flatten_complex_data_to_list_with_options
					);
use Carp;
use Data::Dumper;
use Banal::Utils::String 	qw(trim);
use Banal::Utils::Array 	qw(array1_starts_with_array2);




##############################################################################"
# PUBLIC (exportable) FUNCTIONS
##############################################################################"


#----------------------------------
# Function, not a method!
#----------------------------------
sub banal_get_data {
	my $args								= {@_};
	my $opts								= $args->{options} || {};
	my $search_upwards_while_not_defined	= $opts->{search_upwards_while_not_defined};

	
	
	# This is where the MAGIC happens. For a full list of options, see the function "normalize_data_root_and_keys()".
	my ($root, @keys) 						= _normalize_data_root_and_keys (@_);		
			
	# The data root should have been defined by now. 
	return unless ($root); 
	
	# All this for nothing? 	
	return $root if (scalar(@keys)  < 1);

	# The reason for the below loop is to allow outer level 'variables' to be used when the variable is not defined at the proper (inner) level.
	# Very handy for CONFIGURATION handling scenarios.
	my $key		= pop @keys;
	while (scalar(@keys) >= 0) {
		my $value= _banal_basic_get_data_via_key_list(data=>$root, keys=>[@keys, $key]);	
		return $value if defined($value);	
		
		# Continue searching upwards if we are allowed to do so. Return otherwise.
		return unless $search_upwards_while_not_defined;
			
		pop @keys;
	}
	return;
}



#-----------------------------------------------
# FUNCTION (not a method).
#-----------------------------------------------
sub flatten_complex_data_to_list {
	return flatten_complex_data_to_list_with_options (data=>[@_], on_ArrayRef=>'flatten',  on_HashRef=>'flatten', on_ScalarRef=>'flatten');
}


#-----------------------------------------------
# FUNCTION (not a method).
#-----------------------------------------------
sub flatten_complex_data_to_list_with_options {
	my $opts 			= {@_};
	my $data			= $opts->{data};
	my $on_ArrayRef		= $opts->{on_ArrayRef}	|| 'flatten';
	my $on_HashRef		= $opts->{on_HashRef}	|| 'flatten';
	my $on_ScalarRef	= $opts->{on_ScalarRef}	|| 'flatten';
	my @list			= ();
	
	foreach my $datum (@$data) {
		if 		((reftype($datum) eq 'ARRAY') 	&& ($on_ArrayRef 	=~ /^flatten|dereference$/io)){
				push @list, flatten_complex_data_to_list_with_options(data=>$datum);
				next;
		}elsif ((reftype($datum) eq 'HASH') 	&& ($on_HashRef 	=~ /^flatten|dereference$/io)){
				push @list, flatten_complex_data_to_list_with_options(data=>[%$datum]);
				next;
		}elsif 	((reftype($datum) eq 'SCALAR') 	&& ($on_ScalarRef 	=~ /^flatten|dereference$/io)){
				push @list, flatten_complex_data_to_list_with_options(data=>[$$datum]);;
				next;

		}else {
				push @list, $datum;
				next;			
		}
		
	}
	return @list;
}


#*******************************************************************
# PRIVATE (non-exported) FUNCTIONS
#*******************************************************************
 
#----------------------------------
sub _is_absolute_data_key_reference {
	return ((scalar(@_)  > 0) && !$_[0]);		
}

#----------------------------------
sub _normalize_data_root_and_keys {
	my $args								= {@_};
	my $keys								= $args->{keys}				|| $args->{key}				|| $args->{path} 	|| [];
	my $data								= $args->{data};	
	my $context								= $args->{context}			|| [];	
	my $opts								= $args->{options}			|| {};
	my $separator							= $opts->{path_separator} 	|| $opts->{separator} 		|| '/'; 
	my $remove_extra_separators				= defined($opts->{remove_extra_separators})				? $opts->{remove_extra_separators} 				: 1;
	my $remove_leading_separator			= defined($opts->{remove_leading_separator})			? $opts->{remove_leading_separator} 			: 0;
	my $remove_trailing_separator			= defined($opts->{remove_trailing_separator})			? $opts->{remove_trailing_separator} 			: $remove_extra_separators;
	my $remove_empty_segments				= defined($opts->{remove_empty_segments})				? $opts->{remove_empty_segments} 				: 0;
	my $try_avoiding_repeated_segments		= defined($opts->{try_avoiding_repeated_segments})		? $opts->{try_avoiding_repeated_segments} 		: 0;		
	my $lc									= $opts->{lower_case} 		|| $opts->{lc}	|| 0;
	my $trim								= $opts->{trim}				|| 0;
	
	my $mroot								= undef;	# Yeah, 'undef' by default.
	my $relevant_keys						= [];
	my @accumulated_segs					= ();	
	my $use_path_semantics;	
	
	{
		no warnings;
		$use_path_semantics				=	(defined($opts->{path}) && (($keys eq $opts->{path}) || ($keys == $opts->{path})))	? 	1 	: $opts->{use_path_semantics};
	}
		
	# Flatten all context and key segments (which are potentially a mix of path segment strings)
	$keys = flatten_complex_data_to_list_with_options(data=>[$data, $context, $keys], on_HashRef=>'keep');
	
	# If we've got a HASH reference given as a key (or context) segment, that's our root. Otherwise, build the relevant thingy (relative to the root).
	foreach my $key (reverse @$keys) {
		if (reftype($key) eq 'HASH') {
			$mroot = $key;
			last;
		}else {
			unshift @$relevant_keys, $key;
		}
	}
	
	# Flatten all context and key segments (which are potentially a mix of path segment strings)
	while ( scalar(@$relevant_keys)) {
		my $key			= pop @$relevant_keys;			
		my @segs		= flatten_complex_data_to_list_with_options(data=>[$key], on_HashRef=>'keep');
		
		# If it's an empty ARRAY, just ignore, and pass on to the next one.
		next unless (scalar(@segs));
		
		# Do we have much to do, anyway?  
		if ($use_path_semantics)	 {
			my $path 	= join($separator, @segs);
				
			$path 		=~ s/${separator}+/${separator}/	if ($remove_extra_separators);
			$path 		=~ s/^${separator}// 				if ($remove_leading_separator);			# If you ask for this, you won't be able to detect absolute paths.
		  	$path 		=~ s/${separator}$//				if ($remove_trailing_separator);
			  		
			@segs 		= split /$separator/, $path;
		}
		
		# Lowercase and trim if required.
		@segs			= [map {lc($_)} 	@segs]	if ($lc); 		# Segments are all automatically lowercased, if asked for it.
		@segs			= [map {trim($_)} 	@segs]	if ($trim); 	# Segments are all automatically trimmed, if asked for.
		
		my @prepend_segs	= @segs;
		if($try_avoiding_repeated_segments) {
			@prepend_segs	= ();
			while (scalar(@segs)) {
				if (array1_starts_with_array2([@accumulated_segs], [@segs])) {
					last;
				}
				
				my $s = shift @segs;
				push @prepend_segs, $s;
			}
		}
		
		@accumulated_segs	= (@prepend_segs, @accumulated_segs);
		
		last if (_is_absolute_data_key_reference(@accumulated_segs));
	}
	
	
	# Remove empty segments if we are asked for  it.
	# If you ask for this, you won't be able to detect absolute paths later on (normally, we have already done the detection for you, though)
	@accumulated_segs			= grep (/^\s*$/i,	@accumulated_segs) if ($remove_empty_segments);					
	
	# Here's a little something: We insert the root to the begining of the array.
	unshift @accumulated_segs, $mroot;
	 
	return wantarray ? @accumulated_segs : [@accumulated_segs];
}

#----------------------------------
# Function, not a method!
# 	Allows to get a data element within a deep structure composed of possibly complex data types (HASH, ARRAY, ...)
#   Example:
#		_banal_basic_get_data_via_key_list (data=>$h, keys=>["employee[23]", "department", "name"])
#
# 	In this example, we are assuming that the initial data ($h) is a HASH that has a key called 'employee' which refers to an ARRAY of hashes, ....
#----------------------------------
sub _banal_basic_get_data_via_key_list {
	my $args				= {@_};
	my $data				= $args->{data};
	my $keys				= $args->{keys};
	my @segments			= @$keys;
	
  	foreach my $segment (@segments) {
	  	next unless $segment;
	  	
	  	my $element = $segment;
	  	my $index;
	  	
	    if($element =~ /^([^\[]*)\[(\d+)\]$/) {
	      $element = $1;
	      $index   = $2;
	    }
	    else {
	      $index = undef;
	    }
	 
	  	# We're on a SCALAR. Fishy, since we have got a key segment, too.
	 	unless(reftype($data)) {
	 		return;  
	 	}
	 	
	 	# We're on a SCALAR Reference. Fishy, since we have got a key segment, too.
	 	if(reftype($data) eq "SCALAR") {
	  		return;
	 	}
	 		
	 		
	 	# We're on an ARRAY.
	    if(reftype($data) eq "ARRAY") {
	    	if (defined ($index) && !defined($element)) {
	    		if(exists $data->[$index]) {
	          		$data = $data->[$index];
	          		next;
	        	}
	        	else {
	          		croak "No element with index $index!\n";
	        	}
	    	}elsif (!defined($element)) {
	    		return $data
	    	}
	      	return;
	    }
	    
	    
	 	# We're on a HASH.
	 	if(reftype($data) eq "HASH") {
	 		
	 		# the entire segment (even if it matches the array indexing pattern!)
	 		if (exists $data->{$segment}) {
	 			$data = $data->{$segment};		# this way, we are able to retreive weird hash values with keys that actually match our array indexing.
	      		next;
	    	}
	 		
	 		# Now, we are on the normal route.
	 		if (! exists $data->{$element}) {
	      		return;
	    	}
	    	if(reftype($data->{$element}) eq "ARRAY") {
	     		if(! defined($index) ) {
	        		#croak "$element is an array but you didn't specify an index to access it!\n";
	        		$data = $data->{$element};
	        		next;
	      		}
	      		else {
	        		if(exists $data->{$element}->[$index]) {
	          			$data = $data->{$element}->[$index];
	         			 next;
	        		}
	        		else {
	          			croak "$element doesn't have an element with index $index!\n";
	          			return;
	        		}
	      		}
	    	}
	   		 else {
	      		$data = $data->{$element};
	    	}
	 	}
	}
	 
	return $data;
}


1;


__END__

=head1 NAME

Banal::Utils::Data - Totally banal and trivial utilities for accessing and maniupulating data in various structures.


=head1 SYNOPSIS

    use Banal::Utils::Data qw(banal_get_data);
    
    ...

=head1 EXPORT

None by default.

=head1 EXPORT_OK



=head1 SUBROUTINES / FUNCTIONS

=head2 banal_get_data(data=>$data, keys=>$keys, ....)

Allows to get a data element within a deep structure composed of possibly complex data types (HASH, ARRAY, ...)
   
Example:
	my $name = banal_get_data (data=>$h, keys=>["employee[23]", "department", "name"], ...)

In this example, we are assuming that the initial data ($h) is a HASH that has a key called 'employee' which refers to an ARRAY of hashes, ....

=head3 NAMED ARGUMENTS

=head4 data	-- reference to the structure holding the data tree. Typically a HASH reference.
 
=head4 keys	-- An array of keys (or a SCALAR that gives a single key or a path, depending on the semantics) that will be used to navigate down the tree. 

For array indexes, just use the usual Perl array access syntax.

You can basically throw anything here (ARRAY reference, SCALAR, etc), and it will probably be interpreted the way you expect it to be (basically flattenned into a list of keys). 
Even a HASH reference may occur somewhere in there, in which case the last such reference will be taken to be the data-root.

Under normal circumstances, each element in the passed array is taken to be a single individual key (eventually enriched by an array access syntax mentioned above).
However, it is possible to force "path semantics" for the interpretation of these, in which case it is possible to use path like notation (similar to that of a POSIX file-system) for each one of the array items
that will first be joined together (with a given separator, by default '/') and then resplit on the same separator so that it is possible to mix and match SCALAR and ARRAY path segments.

Please see the 'use_path_semantics' OPTION or the 'path' argument for ways of activating path semantics.

=head4 path  -- A SCALAR (or a reference to an ARRAY of SCALARS, or any complex structure for that matter) that will be interpreted as an access "path"

You can use 'path' instead of 'keys' to automatically enforce path semantics without having to turn on the 'use_path_semantics' option.

Examples:

	path => "employee[23]/department/name"
	
or an equivalently:
 
	path => ["employee[23]/department", "name"]
	
or even:

	path => [["employee[23]/department"], "name"]


=head4 context	-- Similar semantics to 'keys' (or 'path', if path semantics are in force). In practice, it will just be prepended to 'keys' or 'path' (whichever is being used).

It sets a context under which the keys (or path) can be interpreted. In many ways, it is similar to the 'current working directory' in Unix shells.

Note that, it is posible to also throw in a HASH reference in there, in which case the last such reference will be taken to be the data-root. 
Also note that, the same mechanism is possible thru 'keys' or 'path' as well and the last such HASH reference will win (for setting the data-root).

In fact, even the 'data' argument is handled in this very fashion, being prepended before the 'context'.

Here's the relevant code snippet that tells it all in a concise fashion:

	my $relevant_keys						= [];

	# Flatten all context and key segments (which are potentially a mix of path segment strings)
	$keys = flatten_complex_data_to_list_with_options(data=>[$data, $context, $keys], on_HashRef=>'keep');
	
	# If we've got a HASH reference given as a key (or context) segment, that's our root. Otherwise, build the relevant thingy (relative to the root).
	foreach my $key (reverse @$keys) {
		if (reftype($key) eq 'HASH') {
			$mroot = $key;
			last;
		}else {
			unshift @$relevant_keys, $key;
		}
	}
 
In the above snippet, the function call to 'flatten_complex_data_to_list_with_options()' does pretty much what you would expect, flattening an arbitratily complex data structure onto a single flat list.
Only the HASH references, if any, are kept untouched. Further below, we find out if there were indeed any, and use the last such reference as our data-root. The key segments occuring earlier than that, if any,
will be effectively ignored.

=head4 options  -- A reference to a HASH, givng a set of options that effect the way stuff is processed, given below on its own heading (OPTIONS)


=head3 OPTIONS	-- options => {...}

=head4 use_path_semantics	-- Boolean (0 | 1)

Force the usage of 'path semantics' (or not) as explained above under the descriptions of the arguments 'keys' and 'path'.

=head4 path_separator | separator	-- the path separator to be used in 'path semantics' mode. Default is forward slash ('/').

=head4 remove_extra_separators		-- Boolean (0 | 1) that determines whether or not superfulous repeating path separators will be removed. Default is TRUE.  

=head4 remove_leading_separator		-- Boolean (0 | 1) that determines whether or not the leading path separator, if persent, will be removed. Default is FALSE.

Be careful here, as turning this ON will make it impossible to detect absolute path references.  

=head4 remove_trailing_separator	-- Boolean (0 | 1) that determines whether or not the leading path separator, if persent, will be removed. Default is set to the value of 'remove_extra_separators'.
	
=head4 remove_empty_segments		-- Boolean (0 | 1) that determines whether or not empty segments, if persent, will be removed. Default is FALSE.

Be careful here, as turning this ON will make it impossible to detect absolute path references, as the first segmebt in an absolute path reference will appear to be an empty segment.  

=head4 try_avoiding_repeated_segments		-- Boolean (0 | 1) that determines whether or not we will try to eliminate repeating segments. Default is FALSE.

=head4 lower_case | lc				-- Boolean (0 | 1) that determines whether or not we will force lower-case on keys (and anything that serves as a key, such as contexts). Default is FALSE.			

=head4 trim							-- Boolean (0 | 1) that determines whether or not we will trim white space on key segments (and anything that serves as a key segment, such as those coming from contexts). Default is FALSE.

Note that when using 'path semantics', this will also have the effect of trimming white space around path separators.


=head2 flatten_complex_data_to_list(@_)

Flattens out a possibly deep structure composed of possibly complex data types (HASH, ARRAY, SCALAR, ...)
   
Tries very hard to flatten out everything it encounters.

=head3 NAMED ARGUMENTS

=head4 data	-- reference to the structure holding the data tree. Typically a HASH reference.
 

=head2 flatten_complex_data_to_list_with_options(data=>$data, ...)

Flattens out a possibly deep structure composed of possibly complex data types (HASH, ARRAY, SCALAR, ...)
   
Tries to flatten out items it encounters only as hard as it has been asked for.

=head3 NAMED ARGUMENTS

=head4 data				-- reference to the structure holding the data. Typically an ARRAY reference, but any reference or scalar is accepted.

=head4 on_ArrayRef		-- Indicates what to do when an ARRAY reference is encountered. Possible values are 'flatten' or 'keep'. default is 'flatten'.

=head4 on_HashRef		-- Indicates what to do when an HASH reference is encountered. Possible values are 'flatten' or 'keep'. default is 'flatten'.

=head4 on_ScalarRef		-- Indicates what to do when an SCALAR reference is encountered. Possible values are 'flatten' or 'keep'. default is 'flatten'.

 
=head1 AUTHOR

"aulusoy", C<< <"dev (at) ulusoy.name"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-banal-utils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Banal-Utils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Banal::Utils::Data


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Banal-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Banal-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Banal-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Banal-Utils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 "aulusoy".

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Banal::Utils::Data


