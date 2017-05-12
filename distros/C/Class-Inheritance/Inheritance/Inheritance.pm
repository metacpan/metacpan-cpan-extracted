#!/usury/bin/perl

### This module is intended to find out who the parents and children are
### for a given function in a given class. 

package Class::Inheritance;
use strict qw(vars subs);
use Data::Dumper;

use vars qw{$VERSION};

BEGIN {
    $VERSION = '0.03';
}
#--------------------------------

sub new {
    my $class = shift; 
    my $hash = {};  
    $hash->{'debug'} = 0;
    $hash->{'format'} = 'none';
    bless $hash, $class; 
    return ($hash);
}

#---------------------------------------
sub debug {
    my $self = shift;
    my $value = shift;

    if ($value =~ /increase/i) {$self->{'debug'}++;}
    elsif ($value =~ /decrease/i) {$self->{'debug'}--;}
    elsif ($value =~ /on/i) {$value = 1;}
    elsif ($value =~ /off/i) {$value = 0;}
    elsif ($value =~ /no/i) {$value = 1;}
    elsif ($value =~ /yes/i) {$value = 1;}

    if ($value < 1) {$value = 0;}

    $self->{'debug'} = $value;

}

#-----------------------------------------------
## Accepted values are 'simple' or 'none';

sub format {
    my $self = shift;
    my %Args = @_;

    if ($self->{'debug'}) { print "format args:\n"; print Dumper(\%Args); }

      ### Get the class and method we are looking for.
    $self->{'format'} = $Args{'type'} || 'none';

}

#----------------------------------------------
# Finds the nearest parent that has the function you want.

sub source {
    my $self = shift;
    my %Args = @_;

    if ($self->{'debug'}) { print "source args:\n"; print Dumper(\%Args); }

      ### Get the class and method we are looking for.     
    my $class = $Args{'class'} || $Args{'package'} || '';
    my $package = $Args{'package'} || $Args{'class'} || '';
    my $method = $Args{'function'} || $Args{'method'} || '';
    my $first_call = 1; 
    if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

    my $temp = $self->sources('class'=>$class, 'method'=>$method, 'depth'=>1, 'package'=>$package, 'first_call'=>0);

       ### If we aren't called first, then don't reformat. 
    if ($first_call < 1) {return($temp);}

    if ($self->{'format'} eq 'simple') {
	if ($temp eq '') {$temp = "<NOT DEFINED>";}
	$temp = "Source for method '$method' in class '$class' is: $temp\n";
      }

    return($temp);
}

#-------------------------------------

  ## This function lists the order in which we grab functions from a given
  ## class and its parents. 
  ## This method seems to be reliable all the time.
sub tree {
    my $self = shift;
    my %Args = @_;

    if ($self->{'debug'}) { print "tree args:\n"; print Dumper(\%Args); }

       ### Get the class and method we are looking for.
    my $class = $Args{'class'} || $Args{'package'} || '';
       ## If we define the package, it means a package contains more than
       ## one class.
    my $package = $Args{'package'} || $class || '';
    my $package_copy = $package;
    $package_copy =~ s/\:\:/\//g;

    my $first_call = 1;
    if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

    my $return_type = $Args{'return_type'} || 'string';

    my $dump = $Args{'dump'} || 0;
    my $first_call = 1;
    if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

       ### We have 3 different types of stuff we return. 
     my $tree_string = "";

       ### require this package (which is the class itself 99% of the time). 
       ### if used was already used, it won't hurt anything.
       ### It a package wasn't given then $package = $class.

     eval {require "$package_copy\.pm";};
     if ($@) {
	 print "ERROR: can't require '$package_copy' in tree() 1.\n"; 
	 if ($self->{'debug'} > 1) { print "$@\n"; }
	 return('');
     }

       ## Get the parents I inherit functions from. 
     my (@isa) = @{"main::$class\::ISA"}; 

      ### If in debug mode, print out isas.
     if ($self->{'debug'} > 1) {
	 my (@isa2) = @{"main::$class\::ISA"};
	 my (@isa3) = @{"main::$package\::ISA"};
	 print "tree class '$class' isa: ", Dumper(\@isa2), "\n"; 
	 print "tree package '$package' isa: ", Dumper(\@isa3), "\n";
     }

       ### If in debug mode, print out packages in main.
     if ($self->{'debug'} > 1) { 
	 my (@Keys) = keys %{"main::"};  
	 (@Keys) = grep($_ =~ /\:\:/, @Keys);
	 print "tree: available packages are:\n", Dumper(\@Keys), "\n"; 
     }

       ### Foreach class, load it and analyze it. 
       ### We assume the class has a corresponding package.
     for my $new_class (@isa) {
	 eval {require "$new_class\.pm";};
	 if ($@) {
	     print "ERROR: can't require '$new_class' in tree() 2.\n"; 
	     if ($self->{'debug'} > 1) { print "$@\n"; }
	     return('');
	 }
	   ## Get the classes I inherit recursively. 
	   ## From this point on, we always use string. 
	   ## We only don't use string in the original call. 
	 my $temp2 = $self->tree('class'=>$new_class, 'return_type'=>'string', 'first_call'=>0); 
	 if ($temp2 ne '') {$temp2 .= ' ';}
	 ## The tree equals this class and the recrusive call.
	 $tree_string .= "$new_class $temp2";
     }

     $tree_string =~ s/  +/ /g;

     if ($self->{'debug'} > 1) { print "tree tree_string: $tree_string\n"; }
     if ($self->{'debug'} > 1) { print "tree return_type: $return_type\n"; }

     my (@List) = split(/ /, $tree_string);
     (@List) = grep($_ =~ /[a-z0-9\_]/i, @List);
     my $no2 = 0;
       ### If a hash return_type, return a hash.
     if ($return_type eq 'hash') {
	 my $ref_hash = {};
	 foreach my $Item (@List) {
	     my $item_hash = {};
	     my $main_ref = \%{"main::"};
	     $item_hash->{'ref'} = $main_ref->{"$class\::"};
	     $item_hash->{'no'} = $no2;
	     $no2++;
	     $ref_hash->{'$Item'} = $item_hash;

	 }
	 if ($dump) {return(Dumper($ref_hash));}
	 else {return($ref_hash);}
     }
     elsif ($return_type eq 'list') {
	 my $ref_array = [];
	 foreach my $Item (@List) { push(@$ref_array, $Item); }
	 if ($dump) {return(Dumper($ref_array));}        
	 else {return($ref_array);}
     }

       ### If are not the first call, return it to avoid format. 
    if ($first_call < 1) {return ($tree_string);}
    
       ### Otherwise, if formatted, print it. 
    if ($self->{'format'} eq 'simple') {
        if ($tree_string eq '') {$tree_string = "<DOES NOT EXIST>";}
        $tree_string = "Tree for the class '$class' is: $tree_string\n";
    }

     return($tree_string);
 }

 #---------------

   ### Returns those classes which have the function.
   ### This method is reliable. It stores the
   ### ref to the function. 

   ### This will return either a string, array, or hash. 
   ### The hash values will be other hashes. 

sub sources {
     my $self = shift;
     my %Args = @_;

     if ($self->{'debug'}) { print "sources args:\n"; print Dumper(\%Args); }

       ### Get the class and method we are looking for.
     my $class = $Args{'class'} || $Args{'package'} || '';
       ## If we define the package, it means a package contains more than 
       ## one class.
     my $package = $Args{'package'} || $class || '';
     my $method = $Args{'function'} || $Args{'method'} || '';
     my $return_type = $Args{'return_type'} || 'string';
     my $depth = $Args{'depth'} || 0;
     my $depth = shift || 0;
     if ($depth < 1) {$depth = 0;}

     my $first_call = 1;
     if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

       ## My Parents I inherit from.
     my $tree_list = $self->tree('class'=>$class, 'package'=>$package,'first_call'=>0);
     if ($self->{'debug'}) { print "sources tree: $tree_list\n"; }
     my (@items) = split(/ +/, $tree_list);

     my $method_name = [];
     my $previous_code = "";

	 ### Record my class if I actually have the function.
         ### We should make a subroutine for this. 
     eval {
	 my $temp_obj = new $class;
	 ### Can I execute this function?
	 my $ref_type = ref($temp_obj->can($method));
	 ## Does it return a code ref which points to the code?
	 ## It yes, then record.
	 if ($ref_type eq "CODE") {
	     my $code1 = $temp_obj->can($method);
	     my $string1 = "$code1";
	     $previous_code = $string1;
	     push(@$method_name, $class); 
	 }
     };

     for my $class (@items) {
	   ## Dangerous thing which could bomb us. Eval it later.

	 eval {require "$class\.pm";};
	 if ($@) {
	     print "ERROR: can't require '$class' in sources.\n";
	     if ($self->{'debug'} > 1) { print "$@\n"; }
	     return('');
	 }

	   ## Get the names of the items in this class.          

	 my @keys = keys %{"main::$class\::"};

	## We want to grab only the key that matches the function.
	 my (@match) = grep($_ eq $method, @keys);
	 my $length = @match;

	    ## If the function exists, if the class can execute ths function,
	    ## and the return value is CODE
            ## Remember to make a subroutine to eval creating a new object.
	 if (grep($_ eq $method, keys %{"main::$class\::"}))  {
	     my $temp_obj = new $class;
	       ## If the reference eq CODE?
	     my $ref_type = ref($temp_obj->can($method));
	     if ($ref_type eq "CODE") {
		   ## Get the the ref to where it points. 
		   ## The key thing here is, we don't want to record
		   ## this unless it is different from the previous parent.
		   ## We are only interested in the root parents where the
		   ## function comes from and not parents who inherited the
		   ## function.
		 my $code1 = $temp_obj->can($method);
		 my $string1 = "$code1";
		 if ($string1 ne $previous_code) {
		     $previous_code = $string1;
		     push(@$method_name, $class);
		 }
		 @{$method_name}->[-1] = $class;
	     }
	 }    
     }

       ### Make a list of the parents who have this function who are the
       ### original source of the function. List in order. 

 #    print "returning result for sources: $class, $method, $return_type, $depth from the list: @$method_name\n";
     my $Result = $self->method_return_type('return_type'=>$return_type, 'list'=>$method_name, 'method'=>$method, 'depth'=>$depth,'first_call'=>0);

       ### If are not the first call, return it to avoid format.
     if ($first_call < 1) {return ($Result);}

       ### Otherwise, if formatted, print it.
     if ($self->{'format'} eq 'simple') {
	 if ($Result eq '') {$Result = "<DOES NOT EXIST>";}
	 $Result = "Sources for the method '$method' in class '$class' are: $Result\n";
     }

     return($Result); 
 }


#-------------------------
   ## All classes that inherited a method from a given class.
#   All the children who could inherit a method from this class. 
#   Four cases and modifiers:
#       a. This class is in the tree. 
#       b. This class is the first entry in the tree. 
#       c. This class is a source of the method and is in the tree. 
#       d. This class is the first source of the method and it is in the tree.

sub tree_children {
    my $self = shift;
    my %Args = @_;

    if ($self->{'debug'}) { print "tree_children args:\n";print Dumper(\%Args);}

       ### Get the class and method we are looking for.
    my $class = $Args{'class'} || $Args{'package'} || '';
    my $return_type = $Args{'return_type'} || 'string';
    my $method = $Args{'method'} || $Args{'function'} || '';
    my $source_type = $Args{'source_type'} || '';
    my $tree_position = $Args{'tree_position'} || 'any';

    my $first_call = 1;
    if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

      ### Get all the classes that have this function. 
    my $trees = $self->trees_all('method'=>$method, 'first_call'=>0);

      ### Now filter it out. We always assume it passes. 
      ### Make pass false if there is a problem.  
    my $trees_filtered = {};
    for my $class_name (keys %$trees) {
        my $pass  = 1;

	my $list = $trees->{$class_name};
            #### Get some stats on this class.  
        my $source = $self->source('method'=>$method, 'class'=>$class_name, 'first_call'=>0);
        my $sources = $self->sources('method'=>$method, 'class'=>$class_name, 'return_type'=>'list', 'first_call'=>0);
        my $tree =  $self->tree('class'=>$class_name, 'return_type'=>'list', 'first_call'=>0);

          ## If we are not the original source, then false. 
	if ($source_type eq 'first') { if ($source ne $class) {$pass = 0;}}
          ## If we are suppose to be any source, otherwise pass = 0.
        if ($source_type eq 'any') {
	    if (!(grep($_ eq $class, @$source))) {$pass = 0;}
	}

          ## If we are suppose to be the first in tree, and are not, pass = 0.
	if ($tree_position eq 'first') { 
	    if ($tree->[0] ne $class) {  $pass = 0;}
	}
          ## If we are suppose to be anywhere in the tree, otherwise pass = 0.
        else  {
            if (!(grep($_ eq $class, @$tree))) {$pass = 0;}
        }

          ## If we passed, add it. 
        if ($pass == 1) {$trees_filtered->{$class_name} = $tree;}

	if ($self->{'debug'} ) { 
            print "tree_children: $class $class_name: $source_type, $tree_position\n";
	    print "tree_children tree: @$tree\n";
            print "tree_children source: $source\n";
            print "tree_children sources: @$sources\n";

	}

    }

       ### If are not the first call, return it to avoid format.
    if ($first_call < 1) {return ($trees_filtered);}

       ### Otherwise, if formatted, print it.
    if ($self->{'format'} eq 'simple') {
        my $dump =  Dumper($trees_filtered);
        my $string = "Children trees for the method '$method' in the class '$class' are: \n$dump\n";
        return($string);
    }


    return($trees_filtered);
 }

 #-------------------------------------------------------
   ## Makes a list of subclasses given a class. 
   ## If none is defined, starts at 'main::'. 
   ## Return either a string list or a list. 
   ## This only looks at currently loaded packages. 
   ## You must preload the packages you use here. 
sub subclasses {
     my $self = shift;
     my %Args = @_;

     if ($self->{'debug'}) { print "subclasses args:\n"; print Dumper(\%Args); }

       ### Get the class and method we are looking for.
     my $class = $Args{'class'} || $Args{'package'} || 'main::';
     if (!($class =~ /^main\:\:/)) { $class = "main::$class";}
     if (!($class =~ /\:\:$/)) { $class = "$class\:\:";}
     my $return_type = $Args{'return_type'} || 'string';
     my $clean = $Args{'clean'} || 1;

     my $first_call = 1;
     if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

     my $list = "";

     my (@Keys) = sort keys %{$class};
     (@Keys) = grep($_ =~ /\:\:/, @Keys);
	### We don't want to go in an infnite loop. 
     (@Keys) = grep(!($_ =~ /^main\:\:/), @Keys);

        ### Do the recursive call. 
     foreach my $Item (@Keys) {
	 my $temp = $self->subclasses('class'=>"$class$Item", 'clean'=>0, 'first_call'=>0);
	 $list .= " $class$Item $temp";
     }

       ### Clean only happens at the original call. 
     if ($clean > 0) {
	 $list =~ s/main\:\://g;
	 $list =~ s/\:\: / /g;
	 $list =~ s/\:\:$//g;
     }

	 ## List only gets used at the original call. 
     if ($return_type eq 'list') {
	 my (@List) = split(/ +/, $list);
	 (@List) = grep($_ =~ /[a-z0-9\_]/i, @List);
	 return(\@List);
     }

       ### If are not the first call, return it to avoid format.
     if ($first_call < 1) {return ($list);}

       ### Otherwise, if formatted, print it.
     if ($self->{'format'} eq 'simple') {
	 if ($list eq '') {$list = "<DOES NOT EXIST>";}
         $class =~ s/^main\:\://;
         $class =~ s/\::$//g;
	 $list = "Subclasses for the class '$class' is: $list\n";
     }

     return($list);

 }
 #-------------------------------------------

   ## Goes through all packages in main:: and their subclasses. 
   ## If the name of the class is not in the returned value from 
   ## "$self->sources", then it isn't a source. Otherwise it is. 
   ## Note: If someone mucked with the refs, you could end up in situations
   ## where two classes are considered the source because they both point
   ## two function that was not inherited by either class but was manually
   ## set. We should make a check that makes sure all the sources are unique
   ## pointers. 
   ## Use subclasses, 
sub source_all {
     my $self = shift;
     my %Args = @_;

     if ($self->{'debug'}) { print "sources args:\n"; print Dumper(\%Args); }

     my $method = $Args{'function'} || $Args{'method'} || '';
     my $return_type = $Args{'return_type'} || 'string';
     my $first_call = 1;
     if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

     my $classes = $self->subclasses('return_type'=>'list', 'first_call'=>0);

     my $Sources = {};

     foreach my $class (@$classes) {
	 my (@keys) = keys %{"main::$class\::"};
	    ## If the method and the new method exist in package, 
	    ## create a new object, and if it has the method
	    ## with a ref of "CODE", then see whose its parent is. 
	 if (grep($_ eq $method, @keys) && grep($_ eq 'new', @keys)) {
	     my $result = eval {
		   ### Record my class if I actually have the function.
		 my $temp_obj = new $class;
		   ### Can I execute this function?
		 my $ref_type = ref($temp_obj->can($method));
		   ## Does it return a code ref which points to the code?
		   ## It yes, then record.
		 if ($ref_type eq "CODE") {
		     my $sources = $self->sources('package'=>$class, 'method'=>$method, 'class'=>$class, 'return_type'=>'list', 'first_call'=>0);
		       ### If I am a source, then record it. 
		     if (grep($_ eq $class, @$sources)) {
			 $Sources->{$class} = {};
			 my $temp = $temp_obj->can($method);
			 $Sources->{$class}->{'code'} = "$temp";
#                         print "test $class $method $temp @$sources\n";  
		     }
		 }
	     };
	     if (($@) & ($self->{'debug'})) { print "DEBUG source_all $class: $@\n";}
	 }
     }
     if ($self->{'debug'}> 1) { print "source_all Sources:", Dumper($Sources), "\n";}

	 ### Now we got the stuff, just format it for a return.
     if ($return_type eq 'hash') {return($Sources);}
     elsif ($return_type eq 'list') {
	 my $Array = [];
	 foreach my $Key (sort keys %$Sources) {push(@$Array, $Key);}
#         print "test", Dumper($Array);
	 return($Array);
     }

     my $String = "";
     foreach my $Key (sort keys %$Sources) {$String .= " $Key";}
     $String =~ s/^ +//;

       ### If are not the first call, return it to avoid format.
     if ($first_call < 1) {return ($String);}

       ### Otherwise, if formatted, print it.
     if ($self->{'format'} eq 'simple') {
	 if ($String eq '') {$String = "<DOES NOT EXIST>";}
	 $String = "All sources for the method '$method' are: $String\n";
     }

     return($String);
 }

 #---------------------------------------------------------------
   ## All classes that have this function and their trees. 
   ## This starts at 'main::'. 
   ## Use subclasses, tree_children. 
   ## Get all the sources, and then build the trees from there. 
   ## After you get all the sources, use tree_children. 

   ## This has to return a hash because there are different trees. 
   ## It doesn't make any sense to return a string or list. 

   ## This list will get huge with multiple inherited classes. 
sub trees_all {
     my $self = shift;
     my %Args = @_;

     if ($self->{'debug'}) { print "trees_all args:\n"; print Dumper(\%Args); }

     my $method = $Args{'function'} || $Args{'method'} || '';
     my $return_type = $Args{'return_type'} || 'string';
     my $any = $Args{'any'} || 0;
     my $complete = $Args{'complete'} || 'sources_only';
     my $return_type = $Args{'return_type'} || 'string';
     my $first_call = 1;
     if (exists $Args{'first_call'}) {$first_call = $Args{'first_call'}}

     my $classes = $self->subclasses('return_type'=>'list', 'first_call'=>0);
     my $trees = {};

       ## We need to load all the modules. 
       ## Make a first pass to get the modules are interested in. 
     my $classes_filtered  = [];
     foreach my $class (sort @$classes) {
	 my (@keys) = keys %{"main::$class\::"};
           ### If it doesn't have the new function, skip it. 
	 if (grep($_ eq 'new', @keys)) {  push(@$classes_filtered, $class); }
     }

        ### This will load all the parent modules. 
        ### This is a hack. inefficient. 
     foreach my $class (@$classes_filtered) {
	 $self->sources('class'=>$class, 'method'=>$method,'return_type'=>'list', 'first_call'=>0);
     }
  
       ### Now, redo class_filtered. 
     my $classes = $self->subclasses('return_type'=>'list', 'first_call'=>0);
     my $classes_filtered  = [];
     foreach my $class (sort @$classes) {
         my (@keys) = sort keys %{"main::$class\::"};
           ### If it doesn't have the new function, skip it.
         if (grep($_ eq 'new', @keys)) {push(@$classes_filtered, $class); }
#         else {print "skipped $class\n"; }
     }

     foreach my $class (@$classes_filtered) {
	 if ($self->function_in_isa('class'=>$class, 'method'=>$method)) {
	     if ($complete eq 'source_only') {
		 my $temp = $self->sources('class'=>$class, 'method'=>$method, 'return_type'=>$return_type, 'first_call'=>0);
		 $trees->{$class} = $temp;
	     } 
	     else {
		 my $temp = $self->tree('class'=>$class, 'return_type'=>$return_type, 'first_call'=>0);
		 $trees->{$class} = $temp;
	     }
	 }
     }

       ### If are not the first call, return it to avoid format.
     if ($first_call < 1) {return ($trees);}

       ### Otherwise, if formatted, print it.
     if ($self->{'format'} eq 'simple') {
         my $dump =  Dumper($trees);
         my $string = "All trees for method '$method' are: \n$dump\n";
         return($string);
     }

     return($trees);
 }

 #-----------------------------------
   ## This will go through all the isas of a class and see if a function
   ## exists in any of its parents. 
sub function_in_isa {
     my $self = shift;
     my %Args = @_;

     if ($self->{'debug'}) { print "function_in_isa args:\n"; print Dumper(\%Args); }

     my $method = $Args{'function'} || $Args{'method'} || '';
     my $class = $Args{'class'} || $Args{'package'} || '';

       ### Get the tree
     my $tree =  $self->tree('class'=>$class, 'return_type'=>'list', 'first_call'=>0);
       ### Get all the sources for this method.
     my $sources = $self->source_all('method'=>$method,'return_type'=>'list', 'first_call'=>0);

     if ($self->{'debug'} > 1) { print "function_in_isa '$method' trees: @$tree\n";}
     if ($self->{'debug'} > 1) { print "function_in_isa '$method' sources: @$sources\n";}

      ### Grep to see if any of these sources exists in my tree.
      ## This is a very complicated grep. 
      ## This calulates the intersection. 
      ## Notice how there are two different $_ in the one-liner. 
      ## If you don't know what you are doing, this grep can be bad. 
     my $temp = "";
#     print "test1: $class, $method, @$sources, @$tree\n";

     if (grep((($temp = $_) || (1)) && (grep($_ eq $temp, @$sources)), @$tree)) 
       {return (1);}

       ### However, if we don't inherit, check to see if we actually have
       ### the function. 
     my $ref_type = '';
     my (@keys) = sort keys %{"main::$class\::"};
     if (grep($_ eq $method, @keys)) {  
	 eval {
	     my $temp_obj = new $class;
	     $ref_type = ref($temp_obj->can($method));
	 };
	 if ($ref_type eq "CODE") {  return(1); }
     }
 
    return(0);
}

#--------------------------------------------------------------------

  ## This formats the returned list. 
  ## We use this repeatedly for other methods. 
  ## You shouldn't have to execute this method yourself.
sub method_return_type {
    my $self = shift;
    my %Args = @_;

    if ($self->{'debug'}) 
      { print "method_return_type args:\n"; print Dumper(\%Args); }

    my $list = $Args{'list'} || [];
    my $method = $Args{'method'} || $Args{'function'} || '';
    my $return_type = $Args{'return_type'} || 'string';
    my $depth = $Args{'depth'} || 0;
    my $depth = shift || 0;
    if ($depth < 1) {$depth = 0;}

    my $tree_matches = $list->[0];
    my $no = 1;
    if ($depth < 1) {$depth = @$list;}
    while ($no < $depth) {
	my $value = $list->[$no];
        if (length($value) > 0) { $tree_matches .= " $value"; }
        $no++;
    } 

    my (@List) = split(/ /, $tree_matches);
    (@List) = grep($_ =~ /[a-z0-9\_]/i, @List);
    my $no2 = 0;
       ### If a hash return_type, return a hash. 
    if ($return_type eq 'hash') {
	my $ref_hash = {};
        foreach my $Item (@List) {
	    my $temp_obj = new $Item;
              ## If the reference eq CODE?
	    my $ref_type = ref($temp_obj->can($method));
	    if ($ref_type eq "CODE") {
		my $item_hash = {};
		$item_hash->{'code'} = $temp_obj->can($method); 
                $item_hash->{'no'} = $no2;
		$no2++;
                $ref_hash->{'$Item'} = $item_hash;
	    }
	}
	return($ref_hash);
    }
       ### It we want an array, just return the array.
    elsif ($return_type eq 'list') {
        my $ref_array = [];
        foreach my $Item (@List) {
            my $temp_obj = new $Item;
            ## If the reference eq CODE?
            my $ref_type = ref($temp_obj->can($method));
            if ($ref_type eq "CODE") { push(@$ref_array, $Item);}
        }
	return($ref_array);
    }

    return($tree_matches);
}

#------------------------------------------------------------------
  ## Must always return true.
1;

__END__

=pod

=head1 NAME

Class::Inheritance - get and set inheritance values for a class.

=head1 SYNOPSIS


  use Class::Inheritance;
  my $ci = new Class::Inheritance;
  $ci->format('type'=>'simple');

    # Example class and method. Change to the class and method you want.
  my $class = 'CGI';
  my $method = 'param';

  print $ci->source('class'=>$class, 'method'=>$method); 
  print $ci->tree('class'=>$class); 
  print $ci->sources('class'=>$class, 'method'=>$method); 
  print $ci->tree_children('class'=>$class, 'method'=>$method,);
  print $ci->subclasses('class'=>$class);
  print $ci->source_all('method'=>$method);
  print $ci->trees_all('method'=>$method);
  print $ci->tree_children('class'=>$class, 'method'=>$method);

    ### Do not use these methods. 
  $ci->function_in_isa('class'=>$class, 'method'=>$method);
  $ci->method_return_type(method'=>$method, list=>[]);

=head1 DESCRIPTION

  Class::Inheritance tries to get all the information you would ever 
  need regarding inheritance and multiple inheritance for classes. 
  The main focus of the module is to ask "From which class did this
  method come from?".

  NOTE: You MUST have the classes loaded in order for them to be 
  searched. In the future, there will be options for it to scan all 
  modules loaded on your system -- but it does not do it yet. 

  The current state of Class::Inheritance is alpha-quality material. 
  The code is going to be ripped apart and redone, but the basic
  methods should remain. It most likely will take heavy use of 
  Class::Inspector in the future. 

  Setting values for classes is not implemented yet. 

=head1 TERMS AND OPTIONS

    Options common to most methods. 

  1. "return_type" can have the values "", "list", or "string". 
       Default "string".
  2. "class" is the name of the class in question. Also, defaults
     to "package" if defined. 
  3. "package" contains the class you are looking for. Most of the 
      time you do not need to specify this. Defaults to "class".  

    Options for the object. 

  1. "debug" will turn off and on the debug levels. 
  2. "format" has the options of "" or "simple". "simple" returns
     a string ready for printing. 


=head1 METHODS

=head2 source

   Returns the name of the class which this method came from. Only 
   searches loaded classes.

=head2 tree

  This returns the inheritance tree for a class. Only searches
  loaded classes.

=head sources

  Returns all the classes in the inheritance tree of a classes has
  this method defined. This does not include classes which inherited
  the method. Only searches loaded classes.

=head2 tree_children
  
  Returns the classes which inherit a method from a class. Only 
  searches loaded classes. 

=head2 subclasses

  Returns all the loaded subclasses for a class. 

=head2 source_all

  Returns all the sources for a method from the loaded classes. 
  This will search all loaded classes. Any class that has this
  method defined (not inherited) should be in this list. 

=head2 trees_all

  Returns all the trees of classes which contain a method. Only 
  searches loaded classes. 

=head1 AUTHOR

        Mark Nielsen
        articles@tcu-inc.com
        http://tcu-inc.com/

=head1 COPYRIGHT

Copyright (c) 2004 Mark Nielsen. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

