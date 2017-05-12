package Class::GAPI 	  ;
$VERSION = '1.1'    	  ;
use strict 	          ; 

#
# GAPI, Generic API. This is a foundation class with loads 
# of automation built in. It is probably slow, but you get  
# lots of handy tricks with it. 
#

sub new {
	my $class = shift 		  ;

	my %self 				  ; # This has to be 2 lines. 
	%self = @_ if scalar(@_)    	  ; # Don't Change it.   
 
	my $obj = bless(\%self, $class) ; # I gotta be me

	while(my ($key, $val) = each %self) { 
		delete($self{$key})  ; 
		my $block = join "", ('$obj->', "$key", '($val) ;') ; # Autoload recieved properties    
		eval($block)    ;  
	}

	foreach(eval(join "", ('@', $class, '::Default_Properties'))) {
		unless (defined $obj->{$_}) {
			my $block = join "", ('$obj->', "$_", '() ;') ; # Autoload Default Properties    
			eval($block)  ;  
		}
	}

	foreach(eval(join "", ('@', $class, '::Children'))) {

		my $namespace = $_        ;

		if ($namespace =~ /^Class\:\:GAPI\:\:/) {
			$_ = 'Class::GAPI' 		   	 ; # Stub Class  
			$namespace =~ s/^Class\:\:GAPI\:\:// ; 
		} elsif ($namespace =~ /^Class\:\:List\:\:/) {
			$_ = 'Class::List' 				 ; # Stub List  
			$namespace =~ s/^Class\:\:List\:\:// 	 ; 
		} else {
			$namespace =~ s/^.*\:\:// 		       ; # Named Class
		}   
		unless (defined $obj->{$namespace}) {
			my $block = join "", ($_, '->new();')      ; # Named Class Constructor     
			$obj->{$namespace} = eval($block) ;
		}
	}

	eval('$obj->_init() ;') ; # sub _init is reserved against autoloading 
	return $obj             ; 
}

#######################################################################
#######################################################################

#######################################################################
#######################################################################

sub AUTOLOAD {  
	my $self = shift      ;
	my $argument = undef  ; # Whatever is passed to the function 
	my @tree 		    ; # FQ namespace to parse 
	my $functioname       ; # Name of function we are replacing.  
	my $namespace         ; # The local namespace of the function  
	our $AUTOLOAD	    ; # Gift from Perl 

	$argument = shift @_ if scalar(@_)   ; 
	@tree = split(/\:\:/, $AUTOLOAD)     ;  
	$functioname = pop @tree 		 ; 
	$namespace = pop @tree    		 ;

	# warn("AUTOLOAD\,$functioname\,$namespace\,$argument") ; 

	return if $AUTOLOAD =~ /::DESTROY$/        ; # Destruction requires no action  
	return undef if $functioname eq $namespace ; # Avoid recursion  
	return undef if $functioname eq '_init'    ; # _init is reserved for user defined init.   

	if (defined $argument) {  # Set the property and return a pointer
		$self->{$functioname} = $argument ; 
		return (as_ptr($self->{$functioname})) ; # Yep even scalars are returned as pointers
	} 
	else {  # Initialize property and Return the value 
		unless (exists $self->{$functioname}) { $self->{$functioname} = undef ; } 
		return $self->{$functioname} ; 
	}
}

sub as_ptr { unless(ref $_[0]) { return \$_[0] ; } else { return $_[0] ; } } # 

sub sprout {
	my $self = shift     ; 
	my $newclass = shift ; 
	$self->{$newclass} = Class::GAPI->new() ; 
	return $self->{$newclass} ;  
}

sub clone {	# Make a recursive copy of self, provided that subordinates also have "clone" functions 
	my $self = shift         ;
	my $class = ref($self)   ;
	my $twin = $class->new() ; 
	while(my ($key, $val) = each %$self) {
		if (! ref($self->{$key})) {
			$twin->{$key} = $val ; 
		} elsif(is_blessed($self->{$key})) {
			my $block = ('$twin->{$key} = $val->clone();') ; 
			eval($block) ;
		} else {
			$twin->{$key} = $val ; # try and pass unblessed references  
		}
	} 
	return $twin    ; 
}

sub load {  # Broadcast namespace down the tree.    
	my $self = shift ; 
	my @libs = @_    ; 
	foreach (@libs) {      
		my $block = join '', ('use ', $_, ';')   ; 
		eval($block) 				     ;
	}
	while(my ($key, $val) = each %$self) {
		if (is_blessed($val)) { 
			my $block = '$val->load(@libs);'   ; 
			eval($block) 			     ;
		}
	} 
}

sub is_blessed { # Object detection.  
	my $val = shift ; 
	if (ref($val)) {
		foreach('SCALAR','ARRAY','HASH','CODE','GLOB','REF','LVALUE','IO::Handle') {
			if ($val =~ $_ ) { return 0 ; }
		}
		return 1 ; 
	} 
	return 0 ; 
}  

sub overlay {  # Convert a hash into a series of function calls.
	my $self = shift 		          ;
	return undef if  scalar(@_) % 2   ;
	my %pairs = @_ 			    ;
 
	while(my ($k, $v) = each %pairs) {
		my $block = join "", ( '$self->', $k, '(', '$v', ');' ) ;
		eval($block)          	 	    ;
		if ($@) {
			my $class = ref($self) 		    ; 
			warn ("$class is executing $block and throwing:\n $@\n XXXXXXXXXXXXXXXXXXX") ;
		}	
	} 
	return $self ; 
}

sub warn_self { # pass ($self $string) to warn ($self $string 1) to intercept warn data. 
	my $self = shift       ; 
	my $id = shift 	     ; 
	my $class = ref($self) ; 
	my $cstring = "\n$id object $self in $class" ; # Class info  
	while(my ($k, $v) = each %$self) { $cstring .= "\n  $k\-\>$v" ; }
	unless (scalar(@_)) { warn $cstring ; } 
	else { return $cstring ; } 
}

1 ;

############### CODE ENDS HERE ############################## 

=head1 NAME

Class::GAPI - Generic API, Base class with autoloaded methods, stub objects, cloning etc. 

=head1 SYNOPSIS

	package Guppy ;

	use Class::GAPI			; # All of its cool stuff 
	our @ISA = qw(Class::GAPI)	; # is now in our namespace

	our @Children = qw(Class::GAPI::Fin Class::List::Eyeballs CGI)	; # Autoconstruct Subordinates
	our @Default_Properties = qw(scaly small sushi)				; # Call at constructor time

	use strict ;
 
	sub _init { # Last stage of initialization
		  my $self = shift ; 
		  $self->fillet(1) if defined $self->{'sushi'}; # sushi exists but is undefined
     		return 1;
	}
	1 ;

	package Petstore ; 
	use Guppy        ; 
	my $pet = Guppy->new(color => 'orange', price => '.50', small => 1, -sushi => 1) ; # envoke these functions
	$pet->Eyeballs->[0] = "left"	; # Access a special list subclass
	$pet->Eyeballs->[1] = "right"	; # 
	$pet->Fin->dorsal("polkadot")	; # Access a subordinate Class::GAPI object
	$pet->Fin->tail("orange")	; #   

=head1 DESCRIPTION

This is a foundation class. It is intended to be inhertied and used as a framework for other 
objects. This module features autoloaded methods (set+get as one method), three styles of 
initialization, tools for handling stub objects, and cloning. It is particularly well suited 
to handling record list type structures, deeply nested trees and those on-the-fly data structures
that give Perl a reputation as being a language of line noise.  GAPI breaks a few rules and 
create a few others. Overall it just makes coding complex nested data structures a heck of a lot 
easier.  

=head1 AUTOLOADED METHODS

Probably the most used part of this module is the autoloaded methods. One can access them from 
a few places. First by constructing the widget with a hash  

	my $pet = Guppy->new(foo => "bar") ; 

This is the same as saying: 

	my $pet = Guppy->new() ;
	$pet->foo("bar")       ;

which is the same thing as saying: 

	my $pet = Guppy->new() ;
	$pet->{'foo'} = 'bar'  ; 

So all methods are autoloaded. A side effect is that typo'd function calls 
generally will not cause a crash, but rather quitely create an additional 
property. This can also be viewed as a feature, in that you can call nonexistant 
functions in GAPI objects, thereby allowing you to write you code a bit more top-down 
and it will be more tolerable of things you haven't added yet. 

All autoloaded methods add properties, never deleting them. To undefine something 
call it as a hash.  (the variable "_init" is reserved and does not autoload, 
you'll see why later)  

	undef $pet->{'foo'}  ; # no foo for you 
	delete $pet->{'foo'} ; # de-exist foo.  

Passing a hash or array to a function returns a reference to the respective type, as does just 
calling an empty function on a property that contains a hash or array.  And they may be constructed 
on the fly. So you can:  

	my $hashref = $pet->magician(tophat => 'bunny') ;

But don't do this. Forget I mentioned it. Instead use the sprout() function 
which is GAPI for creating GAPI based subclasses. sprout()ed classes will 
then also support autoloaded methods and other GAPI functions. 
 
	$pet->sprout('magician', tophat => 'bunny')        ; # $pet->{'magician'} is now a Class::GAPI object

	my $wascallywabit = $pet->magician->tophat()       ; # get the rabbit  
	$pet->magician->tophat('dove') 			   ; # replace it with a dove   

Now, back to the constructor:

	my $pet = Guppy->new(foo => "bar") ; 

This does not just set $pet->{'foo'} to "bar", it invoke the function 'foo' on "bar", and 
the autoloaded function is what does the set/get. So it is important to note that one can preempt 
this behavior simply by defining a function as follows: 

	sub foo { 
		my $self = shift ; 
		my $bar = shift  ; 
		print "a guppy walks into a $bar and says: Ouch.\n" ;
	} 

=head1 OBJECT INITIALIZATION

Class::GAPI has three stages of initialization at constructor time. The first which we just 
discussed is by calling passed arguments as functions. The second is by evaluating two class 
wide predefined arrays. They are: 

	our @Default_Properties = qw(scaly small sushi) ; # execute some functions during new()
	our @Children = qw(Class::GAPI::Fin Class::List::Eyeballs) ; # make some branches on our tree 

@Default_Properties is easy. Anything named here is called just as if it was passed as an 
option with an undefined value. So the example above is the same as: 

	my $pet = Guppy->new(scaly => undef, small => undef, sushi => undef) ;

@Default_Properties is not used that often, in that the other Initialization stages can 
do more than @Default_Properties. It is handy from time to time when you want to add 
something complicated to the objects initialization and don't need to pass any special 
arguments. (Like I said, rarely used) It is also trumped by any same-named passed option 
pair from stage 1. So you you can define this as a hail marry for any function that should 
be run at constructor time, even if the caller doesn't send an option pair.   

@Children is a list of subordinate objects to call ->new() on at constructor time. This allows 
Class::GAPI based objects to include other classes in a sem-codeless fashion. Just "use" something 
and stick it in Children, and you will get one built. (No options will be passed, but it will 
built.) So for example you can do this: 

	package Guppy ; 

	use CGI                    ;
	use Class::GAPI            ; 
	our @ISA = qw(Class::GAPI) ;  
	our @Children = qw(CGI)    ;
	1 ;  

Which will then allow you to do this: 

	my $pet = Guppy->new()      ; 
	my $SwimTowardstheLight = $pet->CGI->param("fishhook") ; # Extract CGI parameter "fishhook" 
 
Class::GAPI will always use the right-most namespace fragment as the option in the option => value pair. (This may 
cause a namespace conflict from time to time, in those cases just use the third stage _init instead.) So for example: 

	package SpyGuppy	   ; 
	use Crypt::CBC             ; # block handler
	use Crypt::DES             ; # Encryption Algorythm. 
	use Class::GAPI            ; 
	our @ISA = qw(Class::GAPI) ;  
	our @Children = qw(Crypt::CBC Crypt::DES) ;
	1 ;

and then do: 

	my $pet = SpyGuppy->new()	; 
	$pet->CBC->something()		;
	$pet->DES->somethingelse()	; 

@Children also conveiniently has 2 special class names. Class::GAPI::Foo, and Class::List::Foo. In 
this case "Foo" can be anything you like, and will correspondingly be used to create a 
sprout()ed object. Note that Class::GAPI::Foo is a a sprouted hash, while Class::List::Foo 
is a sprouted array. This is very convenient for making lists of objects. The technique below can be used 
to quickly create a variety of styles of record manager classes. 


	package Guppy::School	; 
	use Guppy		; 
	our @ISA = qw(Guppy)	; # We are derived from a Guppy, which is derived from a GAPI  
	our @Children = qw(Class::List::School) ; # $self->{'School'} is now an array

	sub doSpawn { # Add a new Guppy Object
		my $self = shift 			 ;	 
		my $fish = Guppy->new() 	 ; 
		push @{$self->School()}, $fish ; 
	}

	sub fishNet { # Get a specific Guppy object 
		my $self = shift    		 ; 
		my $n = shift       		 ; 
		my $fish = $self->School->[$n] ;
		return($fish) 	  		 ;   
	}
	1 ;

The third stage of initialization is by defining a local &_init subroutine. This gets called after everything else. So if one desires to 
do something with passed variables after the class is blessed, this is where to do it. If you call an autoloaded function here, it takes place 
after autoloaded functions from ->new(), and Default_Properties. So you do have access to data passed or processed during invokation. 

passed at invokation:  

	package Guppy		; 
	use Class::GAPI		; 
	our @ISA = (Class::GAPI);
	use strict		; 
 
	sub _init {
		my $self = shift ; 
		$self->chopchopchop() if $self->sushi() && $self->filet() ; 
	}
	1 ; 

	package PetShop ; 
	use Guppy       ; 

	my $pet = Guppy->new(-sushi => 0, -filet => undef) ; 
	my $lunch = Guppy->new(-sushi => 1, -filet => 1)   ;
 

In this case the execution of method chopchopchop would occur 
in the case of lunch but not in the case of pet. 

=head1 OTHER FUNCTIONS

Cloning is supported for Class::GAPI objects and any subordinate objects based on Class::GAPI
or that Inherit Class::GAPI. This includes Class::List objects. This is function is eval()d, so it 
will not crash if you have other stuff in their, just don't expect that other stuff copy. 

	my $twin = $pet->clone(); # Make the FDA nervous 

The overlay() function allows one to execute a block of functions by passing hash.  This is equivilant 
to what happens when constructed with new(). This is typically usefull when you want to copy a hash 
into several objects as you might in a record table:

	package Guppy::School	; 
	use Guppy		; 
	our @ISA = qw(Guppy)	; # We are derived from a Guppy, which is derived from a GAPI  
	our @Children = qw(Class::List::School) ; # $self->{'School'} is now an array

	sub doSpawn { # Add a new Guppy Object
		my $self = shift		;
		my $fish = Guppy->new(@_)	; # Pass options pairs to the new fish 
		push @{$self->School()}, $fish  ; 
	}

	sub fishGrow { # Add a block of options like so: fishGrow(2, foo => 'bar') ;  
		my $self = shift		; 
		my $n = shift			; 
		$self->School->[$n]->overlay(@_); 
		return($fish)			;   
	}
	1 ;

The warn_self() function is pretty much what it sounds like. You can call it at any level with 
a tree of nested GAPI and it will produce a table of the object as a warning. Obviously this 
handy for debugging: 

	$self->warn_self() ;
	$self->Foo->Bar->warn_self() ; 

=head1 NOTES

It is worth noting that GAPI uses a lot of eval() calls. So it is fairly slow. Also special 
care should be given to using this module in CGI because of that. You should probably 
read the code and understand how the constructor works before even considering using this 
thing in cgi code. Consider yourself warned.  

This was written on an Win32 box running cygwin and Activestate, and it works on both with Perl 5.8. 
I expect it should work with anything later than 5.6.1, but It hasn't been tested. 

Autoloaded methods tend to cause silent failure modes. Essentially typos that would have 
normally crashed perl will often just end up creating a dangling property somewhere. 
Use $self->warn_self() to take snapshots of objects if something is not getting properly 
populated. If you see two similarly named properties, you've found the culprit. 

No animals were harmed in the development of this module. 

=head1 AUTHOR

Matthew Sibley 
matt@itoperators.com

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2005 Crosswire Industries Inc.  (http://www.itoperators.com) 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut 

