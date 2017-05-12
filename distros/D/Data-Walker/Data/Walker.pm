#---------------------------------------------------------------------------

package Data::Walker;

# Copyright (c) 1999,2000 John Nolan. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# You can run this file through either pod2text, pod2man or 
# pod2html to produce pretty documentation in text, manpage or 
# html file format (these utilities are part of the 
# Perl 5 distribution).

use Data::Dumper;
use overload;           # We will use overload::StrVal() 

use vars qw( $VERSION @ISA $AUTOLOAD @EXPORT %EXPORT_TAGS );
use vars qw( $WALKER %Config @Commands %Commands @ExportedCommands );

require Exporter;
@ISA = qw(Exporter);

@Commands         = qw/ls ll la all lla lal cd pwd 
                       print type cat dump show set walk cli/;
@ExportedCommands = (@Commands, qw/unwalk/);

@EXPORT_OK   = @ExportedCommands;
%EXPORT_TAGS = ( direct => [ @ExportedCommands ] );

push @Commands, qw/chdir/;    # chdir is not exported

use strict;

$VERSION = '1.05';
sub Version { $VERSION };


####################################################################
# ---{ B E G I N   P O D   D O C U M E N T A T I O N }--------------
#

=head1  NAME

B<Data::Walker> - A tool for navigating through Perl data structures

=head1 SYNOPSIS

Without any explicit objects:

  use Data::Walker;
  Data::Walker->cli( $data_structure );

Object-style invocation:

  use Data::Walker;
  my $w = new Data::Walker;
  $w->walk( $data_structure );
  $w->ls("-al");
  $w->pwd;
  $w->cli;

Importing methods into the current package:

  use Data::Walker qw(:direct);
  walk $data_structure;
  ls "-al";
  pwd;
  cli;

=head1 DESCRIPTION

This module allows you to "walk" an arbitrary Perl data 
structure in the same way that you can walk a directory tree 
from a UNIX command line.   It reuses familiar unix commands 
(such as "ls", "cd", "pwd") and applies these to data structures. 

It has a command-line interface which behaves like a UNIX shell.   
You can also use object-style sytax to invoke the CLI commands from 
outside the CLI.   Data::Walker objects are encapsulated, 
so that you can hop into and out of a CLI without losing state, 
and you can have several Data::Walker objects pointing at 
different structures. 

The main functions can also be imported and used directly 
from within the Perl debugger's CLI.  

=head1 INSTALLATION

To install this package, just into the directory which
you created by untarring the package, and type the following:

	perl Makefile.PL
	make test
	make
	make install

This will copy Walker.pm to your perl library directory for
use by all perl scripts.  You probably must be root to do this,
unless you have installed a personal copy of perl or you have
write access to a Perl lib directory.


=head1 USAGE

You open a command-line interface by invoking the cli() function. 

	use Data::Walker;
	Data::Walker->cli( $data_structure );

You can customize certain features, like so:

	use Data::Walker;
	$Data::Walker::Config{'skipdoublerefs'} = 0;
	Data::Walker->cli( $data_structure );

If you prefer to use object-style notation, then you 
can use this syntax to customize the settings.
You can invoke the walk() method directly, our you
can let the cli() method call walk() implicitly: 

	use Data::Walker;
	my $w1 = new Data::Walker;
	$w1->walk( $data_structure );
	$w1->cli;

	my $w2 = new Data::Walker;
	$w2->cli( $data_structure );

	my $w3 = new Data::Walker( 'skipdoublerefs' => 0 );
	$w3->walk( $data_structure );
	$w3->cli();
	
	$w3->showrecursion(0);
	$w3->cli();

You can also import most of the functions directly into 
the current package.  This is especially useful from within 
the debugger (see the example below).

	use Data::Walker qw(:direct);
	walk $data_structure;
	ls "-al";
	pwd;
	cli;

When you use the :direct pragma and invoke the walk() function,
a Data::Walker object is implicitly created, and is available 
as $Data::Walker::WALKER. 

Imagine a data structure like so:  

	my $s = {

        a => [ 10, 20, "thirty" ],
        b => {
                "w" => "forty",
                "x" => "fifty",
                "y" => 60,
                "z" => \70,
        },
        c => sub { print "I'm a data structure!\n"; },
        d => 80,
	};
	$s->{e} = \$s->{d};


Here is a sample CLI session examining this structure ('/>' is the prompt):


	/> 
	/> ls -l
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE                      
	d               scalar                    80
	e               SCALAR                    80
	/> cd a
	/->{a}> ls -al
	..              HASH                      (5)
	.               ARRAY                     (3)
	0               scalar                    10
	1               scalar                    20
	2               scalar                    'thirty'
	/->{a}> cd ../b
	/->{b}> ls -al
	..              HASH                      (5)
	.               HASH                      (4)
	w               scalar                    'forty'
	x               scalar                    'fifty'
	y               scalar                    60
	z               SCALAR                    70
	/->{b}> cd ..
	/> dump b
	dump--> 'b'
	$b = {
	  'x' => 'fifty',
	  'y' => 60,
	  'z' => \70,
	  'w' => 'forty'
	};
	/> ls -al
	..              HASH                      (5)
	.               HASH                      (5)
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE                      
	d               scalar                    80
	e               SCALAR                    80
	/> ! $cur->{d} += 3
	eval--> $cur->{d} += 3
	retv--> 83
	/> ls -al
	..              HASH                      (5)
	.               HASH                      (5)
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE                      
	d               scalar                    83
	e               SCALAR                    83
	/> 
	

Below is a sample debugger session examining this structure.

Note that the walk() function returns a reference to the "cursor",
which is itself a reference to whatever is the "current directory,"
so to speak.  The actual Data::Walker object iself is managed
implicitly, and is available as $Data::Walker::WALKER. 
When you are finished, you can undef this object directly, 
or use the unwalk() function, which does this for you. 
But if you saved a copy of the cursor, then you will need to 
undef this on your own. 


	(violet) ~/perl/walker/Data-Walker-0.18 > perl -d sample_db

	Loading DB routines from perl5db.pl version 1.0401
	Emacs support available.

	Enter h or `h h' for help.

	main::(sample:19):              d => 80,
	  DB<1> n
	main::(sample:22):      $s->{e}      = \$s->{d};
	  DB<1> n
	main::(sample:30):      1;
	  DB<1> use Data::Walker qw(:direct)

	  DB<2> $cur = walk $s

	  DB<3> pwd
	/
	  DB<4> ls
	a       b       c       d       e
	  DB<5> lal
	..              HASH                      (5)
	.               HASH                      (5)
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE
	d               scalar                    80
	e               SCALAR                    80
	  DB<6> cd a
	/->{a}        
	  DB<7> ll
	0               scalar                    10
	1               scalar                    20
	2               scalar                    'thirty'      
	  DB<8> cd '../b'
	/->{b}
	  DB<9> lal
	..              HASH                      (5)
	.               HASH                      (4)
	w               scalar                    'forty'
	x               scalar                    'fifty'
	y               scalar                    60
	z               SCALAR                    70       
	  DB<10> cd '..'
	/
	  DB<11> dump b
	dump--> 'b'
	$b = {
	  'x' => 'fifty',
	  'y' => 60,
	  'z' => \70,
	  'w' => 'forty'
	};                  
	  DB<12> ll
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE
	d               scalar                    80
	e               SCALAR                    80
	  DB<13> $$cur->{d} += 3

	  DB<14> ll
	a               ARRAY                     (3)
	b               HASH                      (4)
	c               CODE
	d               scalar                    83
	e               SCALAR                    83
	  DB<15>                   
	  DB<16> pwd
	/
	  DB<17> cli
	/> cd b
	/->{b}> ls -l
	w               scalar                    'forty'
	x               scalar                    'fifty'
	y               scalar                    60
	z               SCALAR                    70     
	/->{b}> print y
	60
	/->{b}> print x
	fifty
	/->{b}> exit

	  DB<18> pwd
	/->{b}
	  DB<19> ll
	w               scalar                    'forty'
	x               scalar                    'fifty'
	y               scalar                    60
	z               SCALAR                    70
	  DB<20> unwalk

	  DB<21> undef $cur

	  DB<22> 


The following commands are available from within the CLI.
With these commands, you can navigate around the data 
structure as if it were a directory tree.

	cd <target>          like UNIX cd
	ls                   like UNIX ls (also respects options -a, -l)
	print <target>       prints the item as a scalar
	dump <target>        invokes Data::Dumper
	set <key> <value>    set configuration variables
	show <key>           show configuration variables
	! or eval            eval arbitrary perl (careful!)
	help                 this help message
	help set             lists the available config variables


For each session (or object) the following items can be configured:

	rootname        (default:  '/'    )  displays the root node 
	refname         (default:  'ref'  )  displays embedded refs
	scalarname      (default: 'scalar')  displays simple scalars
	undefname       (default: 'undef' )  displays undefined scalars

	maxdepth        (default:   1 )  maximum dump-depth (Data::Dumper)
	indent          (default:   1 )  amount of indent (Data::Dumper)
	lscol1width     (default:  15 )  column widths for 'ls' displays
	lscol2width     (default:  25 )  column widths for 'ls' displays

	showrecursion   (default:   1 )  note recursion in the prompt
	showids         (default:   0 )  show ref id numbers in ls lists
	skipdoublerefs  (default:   1 )  hop over ref-to-refs during walks
	skipwarning     (default:   1 )  warn when hopping over ref-to-refs
	truncatescalars (default:  37 )  truncate scalars in 'ls' displays
	autoprint       (default:   1 )  print directory after chdir when not in CLI

	promptchar      (default:  '>')  customize the session prompt
	arrowshaft      (default:  '-')  ('-' in '->')
	arrowhead       (default:  '>')  ('>' in '->')

	curname         (default:  'cur'  )  how to refer to the cursor for evals
	parname         (default:  'par'  )  how to refer to the parent ref for evals


=head1 CHANGES

=over 4

=item * Version 1.05

	Patch to the test scripts for compatibility with 
	perl 5.8.0,  which stringifies references-to-references 
	differently.  In previous versions of perl, 
	references-to-references were stringified
	as 'SCALAR(0x???)', but perl 5.8.0 stringifies
	them as 'REF(0x???)'. 

	All versions of perl's 'ref' function return 
	'REF' for references-to-references. 

=item * Version 1.02-1.04

	Minor changes to installer tests.

=item * Version 1.01

	Minor changes to the documentation.
	Added walker_http.pl, which is a library for using 
	Data::Walker together with HTTP::Daemon to view objects 
	with a Web browser.  Two example scripts are also included. 

=item * Version 0.21

	Minor changes to the documentation

=item * Version 0.19-0.20

	Added new tests and updated the documentation.

=item * Version 0.18

	Completely separated the CLI loop, command-parsing regexes, 
	and the functions which implement the commands.  AUTOLOAD is now
	set up to handle any commands that the CLI can parse (except
	for eval() ).  

	By using the :direct pragma, you can now import AUTOLOADed functions 
	into the current package, so that you can easily invoke them 
	from the perl debugger.

=item * Version 0.16-0.17

	The Data::Walker objects are now fully encapsulated. 

	NOTE:  The walk() function has been separated into two functions, 
	namely walk() and cli(). The usage instructions have changed.  
	Please have a look.

=item * Version 0.15

	Reorganized the installation tests.  
	A few minor changes to the module itself.

=item * Version 0.13-0.14

	Moved some functionality from the CLI-loop
	into distinct functions.

=item * Version 0.12

	Blessed references to non-hashes are now handled correctly.
	Modified the output of "ls" commands (looks different).
	Added new options:  
	   showids, lscol2width, scalarname, undefname,
	   skipwarning
	Numerous internal changes.

=item * Version 0.11

	Fixed some misspellings in the help information.
	Modified the pretty-print format of scalars.
	Added some new comments to the source code.
	Various other small updates.

=back

=head1 THANKS

Thanks to Gurusamy Sarathy for writing Data::Dumper,
and to Dominique Dumont for writing Tk::ObjScanner.

Thanks to Matthew Persico for sending some ideas on 
how this module might be useful in the debugger. 

Thanks to Scott Lindsey for pointing out that this module
is useful for reading files created with the Storable module,
and for sending a sample script to do this. 

=head1 AUTHOR

John Nolan  jpnolan@sonic.net  1999,2000.
A copyright statment is contained within the source code itself. 

=cut                  


#---------------------------------------------------------------------------
# Default values - these can be overridden, either when an object
# is instantiated or during an interactive session.
#
%Config = (

	rootname        =>  '/' ,    # Any string
	refname         => 'ref',    # Any string
	curname         => 'cur',    # Any string
	parname         => 'par',    # Any string
	scalarname      => 'scalar', # Any string
	undefname       => 'undef',  # Any string

	maxdepth        =>   1  ,  # Any integer, gets passed right to Data::Dumper
	indent          =>   1  ,  # 1,2 or 3, gets passed right to Data::Dumper
	lscol1width     =>  13  ,  # Any integer 
	lscol2width     =>  25  ,  # Any integer 

	showrecursion   =>   1  ,  # Boolean
	showids         =>   0  ,  # Boolean
	skipdoublerefs  =>   1  ,  # Boolean
	skipwarning     =>   1  ,  # Boolean
	warning         =>   1  ,  # Boolean
	autoprint       =>  ''  ,  # Boolean

	truncatescalars =>  35  ,  # Truncate to how many chars; use 0 for no truncation

	promptchar      =>  '>' ,  # Any string
	arrowshaft      =>  '-' ,  # Any string
	arrowhead       =>  '>' ,  # Any string
);

$Config{arrow} = $Config{arrowshaft} . $Config{arrowhead}; 

# Make a list of all UNIX-like commands that we are going to export
#
#@Commands = qw( ls ll la all lla lal cd chdir pwd print type cat dump show set );
@Commands{@Commands} = @Commands;

#---------------------------------------------------------------------------
# Set up a new Data::Walker object
#
sub new {

	my $class = shift;
	my %ARGS  = @_;

	my $self = { (%Config) };

	bless $self,$class;

	foreach (keys %ARGS) {

		if (exists $Config{$_}) {

			$self->{$_} = $ARGS{$_};

		} else {

			print "$_ is not a configuration variable for $class.";
		} 
	}
	return $self;

} #End sub new


#---------------------------------------------------------------------------
# Undef the implicit Data::Walker object
#
sub unwalk { 

	undef($WALKER); 
}


#---------------------------------------------------------------------------
# Point a Data::Walker object at a given reference
#
sub walk {

	# This code handles both OO invocation as a method and
	# non-OO invocation
	#
	my $class = __PACKAGE__;
	my ($self,$ref);

	if (defined $_[0] and ref($_[0]) eq $class) {

		$self = shift;

	} else {

		$self = $WALKER = new Data::Walker;
	}

	$ref = shift;

	unless (defined $ref and ref $ref) {

		print "Parameter to walk is missing, undefined, or is not a reference";
		return 0;
	}

	$self->{namepath} = [$self->{rootname}];
	$self->{refpath}  = [$ref];
	$self->{cursor}   = $ref;

	$self->{prev_namepath} = [];
	$self->{prev_refpath}  = [];
	$self->{tmp_namepath}  = [];
	$self->{tmp_refpath}   = [];

	return \$self->{cursor};  # Return a ref to the cursor
}

#---------------------------------------------------------------------------
# Find out what a reference actually points to
#
sub reftype {

	my ($ref) = @_;

	return unless ref($ref);

	my($realpack, $realtype, $id) =
		(overload::StrVal($ref) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

	# For some reason, stringified version of a ref-to-ref gives a
	# type of "SCALAR" rather than "REF".  Go figure.
	#
	$realtype = 'REF' if $realtype eq 'SCALAR' and ref($$ref);

	wantarray ? return ($realtype,$realpack,$id) : return $realtype;

} #End sub reftype



#---------------------------------------------------------------------------
# Print out a short string describing the type of thing
# this reference is pointing to.   Follow ref-to-refs if necessary.
#
sub printref {

	my ($self,$ref,$recurse) = @_;

	$recurse = {} unless defined $recurse;

	my ($type, $value) = ("error: type is empty","error: value is empty");

	if (not defined $ref) {

		$type  = $self->{scalarname};
		$value = $self->{undefname};

	} elsif (ref $ref) {

		my ($reftype,$refpackage,$id) = reftype($ref);

		$type = $reftype;
		$type = $refpackage . "=" . $type if defined($refpackage) and $refpackage ne "";
		$type .= "($id)" if $self->{showids};

		if ($reftype eq "REF") {                                

			# If this is a ref-to-ref, then recurse until we find 
			# what it ultimately points to.  
			# But stop if we detect a reference loop.
			#
			if (exists $recurse->{$ref}) {

				my $hops = (scalar keys %$recurse) - $recurse->{$ref};
				$value = "(recurses in $hops " . ($hops > 1 ? "hops" : "hop") . ")";

			} else {

				$recurse->{$ref} = scalar keys(%$recurse);	
				my ($nexttype, $nextvalue, $nextid) = $self->printref($$ref,$recurse);
				$type  .= $self->{arrow} . $nexttype;
				$value = $nextvalue;
			}

		} else {

			$recurse = {};

			if ($reftype eq "HASH") {                           

				$value = "(" . scalar keys(%$ref) . ")";

			} elsif ($reftype eq "ARRAY") {                          

				$value = "(" . scalar @$ref . ")";

			} elsif ($reftype eq "SCALAR" and not defined($$ref) ) { 

				$value = $self->{undefname};

			} elsif ($reftype eq "SCALAR" and     defined $$ref  ) { 

				$value = $$ref;

			} else { 

				$value = "";   # We decline to displey other data types.  :)

			} #End if ($reftype eq ...) 

		} #End if ($reftype eq "REF") 


	} else {

		# It's not a reference, so it must actually be a scalar. 
		#
		$type  = $self->{scalarname};
		$value = $ref;

		if ($self->{truncatescalars} > 0 and length($ref) > $self->{truncatescalars} - 2) {

			$value = substr($ref,0,$self->{truncatescalars} - 5) . "..." ;
		}

		# Quote anything that's not a decimal value.
		#
		unless ($value =~ /^(?:0|-?[1-9]\d{0,8})$/) {

			$value = '\'' . $value . '\'';
		}

	} #End if (not defined $ref) -- elsif (ref $ref) 


	wantarray ? return ($type,$value) : return $type;

} #End sub printref 



#---------------------------------------------------------------------------
# This function is used for "chdir'ing" down a reference.
#
sub down {

	my ($self,$name,$ref,$recurse) = @_;

	# The hash $recurse contains elements only when
	# this function is called recursively.  This typically
	# happens when we are chdir'ing down ref-to-refs.
	#
	$recurse = {} unless defined $recurse;

	my $what_is_it = ref($ref) ? reftype($ref) .  " reference" : "scalar";

	unless ($what_is_it =~ /(ARRAY|HASH|REF)/) {

		print "'$name' is a $what_is_it, can't cd into it.\n" 
			if $self->{warning};
		$self->{cursor} = undef;  # The caller must handle this
		return;
	}

	$name = "{$name}" if reftype($self->{refpath}[-1]) eq "HASH";
	$name = "[$name]" if reftype($self->{refpath}[-1]) eq "ARRAY";

	push @{$self->{namepath}}, $name;
	push @{$self->{refpath}}, $ref;

	$self->{cursor} = $ref;    

	#------------------------------
	# If the 'skipdoublerefs' config value is set,
	# and if the reference itself refers to a reference, 
	# then skip it and go down further.  This is recursive, 
	# so we will keep skipping until we come to 
	# something which is not a ref-to-ref. 
	#
	# We need to watch out for reference loops. 
	# Keep track of already-seen references in %$recurse.
	# Pass $recurse to this function, recursively. 
	#
	if ($self->{skipdoublerefs} and ref($self->{cursor}) eq "REF") {

		# Remember that we have seen the current reference.
		$recurse->{$self->{cursor}} = scalar keys(%$recurse);	

		print "Skipping down ref-to-ref.\n" if $self->{skipwarning} and $self->{warning};

		if (exists $recurse->{ ${$self->{cursor}} }) {

			#------------------------------
			# If $recurse->{ ${$self->{cursor}} } exists, then we must have seen it before.  
			# This means we have detected a reference loop.
			#
			# The value of $recurse->{$self->{cursor}} is the number of reference-hops 
			# to the current reference, and the value of $recurse->{ ${$self->{cursor}} } 
			# the number of hops to ${$self->{cursor}}, which is a smaller number,
			# because we saw it before, on a previous hop. 
			#
			# To get the size of the reference loop, get the number of hops between them,
			# and add one hop (to count the final hop back to the beginning of the loop).
			#
			my $hops = 1 + $recurse->{$self->{cursor}} - $recurse->{ ${$self->{cursor}} };
			print 
				"Reference loop detected: $hops ". ($hops > 1 ? "hops" : "hop") . ".\n"
				if $self->{warning}
			;

		} else {

			$self->down( $self->{refname}, ${$self->{cursor}}, $recurse );

			#------------------------------
			# The call to the down() method in the previous line will fail
			# if the target happens to be a SCALAR or some other item which
			# we can't cd into.  In this case, we need to cd back up, 
			# until the current ref is no longer a ref-to-ref.
			#
			# The following lines of code will be executed one time 
			# for each *successful* previous call to the down() method, 
			# which is what we want.  We back out just like we came in.
			#
			if (ref($self->{cursor}) eq 'REF' and scalar @{$self->{refpath}} > 1) {

				print "Skipping up ref-to-ref.\n" 
					if $self->{skipwarning} and $self->{warning};
				$self->up();
			}

		} #End if (exists $recurse->{ ${$self->{cursor}} }) 

	} else {

		# Intentionally empty
		#
		# If 'skipdoublerefs' is not set, then we will be able to cd into
		# ref-to-refs and run ls from within them.

	} #End if ($self->{skipdoublerefs} and ref($self->{cursor}) eq "REF") 

	return $self->{cursor};

} #End sub down



#---------------------------------------------------------------------------
# This function is used for "chdir'ing" up a reference.
#
sub up {

	my ($self) = @_;

	return $self->{refpath}[0] if scalar @{$self->{refpath}} == 1;

	my $name = pop @{$self->{namepath}};
	           pop @{$self->{refpath}};

	# We don't need to watch out for recursion here, 
	# because we can only go back up the way we came down.  
	#
	if ($self->{skipdoublerefs} and $name eq $self->{refname} and $#{$self->{refpath}} > 0) {

		print "Skipping up ref-to-ref.\n" if $self->{skipwarning} and $self->{warning};
		$self->up();
	}
	$self->{cursor} = $self->{refpath}[-1];

	return $self->{cursor};

} #End sub up



#---------------------------------------------------------------------------
sub DESTROY {

	# Intentionally empty
}



#---------------------------------------------------------------------------
# This is used for setting configuration variables OR 
# for invoking UNIX-like shell functions 
#
sub AUTOLOAD {

	# Grab the name of the function we attempted to invoke
	#
	(my $func = $AUTOLOAD) =~ s/^.*:://;

	my $self;

	if (defined $_[0] and ref($_[0]) eq __PACKAGE__) {

		$self = shift;
		
	} elsif (defined $WALKER and ref($WALKER) eq __PACKAGE__) {

		$self = $WALKER;
		$self->{autoprint} = 1 if $self->{autoprint} eq "";

	} else {

		print "$func (AUTOLOAD): Use the walk() function to assign a target reference.\n";
		return "";
	}


	# This might be an invocation of a walker function...
	#
	if (exists $Commands{$func}) {

		unless (exists $self->{cursor} and ref $self->{cursor}) {

			print "$func (AUTOLOAD): No reference!  Please use walk() to initialize a reference to a data structure.\n";
			return "";
		}
		
		my $retval = $self->parse_command($func,@_);
		chomp $retval;  

		if ($self->{autoprint}) {

			print $retval;
			print $self->walker_pwd if $func =~ /(cd|chdir)/;
		}

		return $retval;


	# ...or it might be an attempt to set a configuration variable.
	#
	} else {

		my $msg = $self->walker_set($func,$_[0]);
		print $msg if ($msg);
		return $self->{$func};
	}

}

#---------------------------------------------------------------------------
# Check the values assigned to configuration variables,
# and accept them if they are OK. 
#
sub walker_set {

	my ($self,$key,$value) = @_;

	return "Attempt to assign to undefined key" 
		unless defined $key;
	return "Attempt to assign undefined value to key '" . lc($key) . "'" 
		unless defined $value;

	# Handle empty strings
	$value = '' if $value eq qq/''/ or $value eq q/""/;

	if ($value =~  /^".*"$/) {
		 $value =~ s/^"(.*)"$/$1/;

	} elsif ($value =~  /^'.*'$/) {
		      $value =~ s/^'(.*)'$/$1/;
	}

	my $msg = "";

	for ($key) {

		/(truncatescalars|lscol?width|maxdepth)/i
			and do { 
				my $key = $1;
				unless ($value =~ /\d+/ and $value >= 0) { 
					$msg = lc($key) . " must be a positive integer"; last; 
				}
				$self->{lc $key} = $value; 
				last; 
			};
		/indent/i
			and do { 
				unless ($value =~ /(1|2|3)/) { 
					$msg = "indent must be a either 1, 2 or 3"; last; 
				}
				$self->{indent} = $value; 
				last; 
			};
		/rootname/i
			and do { 
				$self->{rootname}         = $value; 
				$self->{namepath}[0]      = $value if defined $self->{namepath};
				$self->{prev_namepath}[0] = $value if defined $self->{prev_namepath};
				last; 
			};
		/^arrow$/i
			and do { 
				$msg = "Can't modify arrow directly.  Instead, modify arrowshaft and arrowhead";
				last;
			};

		# We check this here, so that we can handle exceptional strings beforehand
		#
		unless (exists $Config{$key}) {

			$msg = "No such config variable as '" . lc($key) . "'";
			return $msg;
		}

		# Otherwise, just accept whatever value. 
		#
		$self->{$key} = $value if exists $self->{$key};

	} #End for ($key) 

	$self->{arrow} = $self->{arrowshaft} . $self->{arrowhead};

	return $msg;

} #End sub walker_set


#---------------------------------------------------------------------------
# Implement chdir logic
#
sub walker_chdir {

	my ($self,$dirspec) = @_;
	my @temp_refpath    = ();
	my @temp_namepath   = ();

	$dirspec =~ s/^\s+//;  # Strip leading whitespace
	$dirspec =~ s/\s+$//;  # Strip trailing whitespace

	#------------------------------
	# Handle cd -
	#
	if ($dirspec =~ m#^\s*-\s*$#) {

		# Swap swap, fizz fizz.....
		#
		         @temp_namepath   =      @{$self->{namepath}};
		     @{$self->{namepath}} = @{$self->{prev_namepath}};
		@{$self->{prev_namepath}} =          @temp_namepath  ;

		         @temp_refpath   =       @{$self->{refpath}};
		     @{$self->{refpath}} =  @{$self->{prev_refpath}};
		@{$self->{prev_refpath}} =           @temp_refpath  ;

		# Use the last ref in the (now) current refpath
		#
		$self->{cursor} = $self->{refpath}[-1];

		return $self->{cursor};

	} else {

		# Remember our current paths into the structure, 
		# in case we have to abort for some reason.
		#
		@temp_refpath  = @{$self->{refpath}};
		@temp_namepath = @{$self->{namepath}};

	} #End if ($dirspec =~ m#^\s*-\s*$#) {

	#------------------------------
	# Handle dirspec's relative to the root
	#
	my $leading_slash = "";

	if ($dirspec =~ m#^/#) {

		# Set the paths back to the beginning
		$#{$self->{namepath}} = 0;
		$#{$self->{refpath}}  = 0;

		# Set cursor to the first item in the refpath
		$self->{cursor} = $self->{refpath}[0];

		# Strip any leading '/' chars from $dirspec
		#
		$dirspec =~ s#^/+##g;

		$leading_slash = '/';
	}

	#------------------------------
	# Handle all other dirspec's
	#
	my @dirs = split /\//, $dirspec;

	foreach (@dirs) {

		# The actual value of $self->{cursor} may be modified within this loop,
		# so we have to re-check it each time through
		#
		my ($reftype,$refpackage) = reftype($self->{cursor});

		my $dir = $_;

		if ($dir eq '.') {

			# Do nothing

		} elsif ($_ eq '..') {

			$self->up();

		} elsif ($reftype eq "REF") {

			unless ($_ eq $self->{refname}) {

				print "'$leading_slash$dirspec' does not exist.  " .
						"Type 'cd $self->{refname}' to descend into reference.\n"
					if $self->{warning};

				@{$self->{refpath}}  = @temp_refpath;
				@{$self->{namepath}} = @temp_namepath;
				$self->{cursor} = $self->{refpath}[-1];

				return $self->{cursor};
			}

			$self->down($dir, ${ $self->{cursor} });

		} elsif ($reftype eq "HASH") {

			unless (exists $self->{cursor}->{$dir}) {

				print "No such element as '$leading_slash$dirspec'.\n" if $self->{warning};

				@{$self->{refpath}}  = @temp_refpath;
				@{$self->{namepath}} = @temp_namepath;
				$self->{cursor} = $self->{refpath}[-1];

				return $self->{cursor};

			} else {

				$self->down($dir,$self->{cursor}->{$dir});
			}

		} elsif ($reftype eq "ARRAY") {

			unless ($dir =~ /^\d+$/ and scalar(@{ $self->{cursor} }) > $dir) {

				print "No such element as '$leading_slash$dirspec'.\n" if $self->{warning};
				@{$self->{refpath}}  = @temp_refpath;
				@{$self->{namepath}} = @temp_namepath;
				$self->{cursor} = $self->{refpath}[-1];

				return $self->{cursor};

			} else {

				$self->down($dir,$self->{cursor}->[$dir]);
			}

		} else {

			#------------------------------
			# If $self->{cursor} points to a SCALAR, CODE or something else, then the
			# 'cd' command is ignored within it.  We should never have chdir'ed
			# there in the first place, so this message will only be printed
			# if the author of this module has made an error.  ;) 
			#
			print "Don't know how to chdir from current directory ($reftype) into '$dirspec'.\n" 
				if $self->{warning};
			@{$self->{refpath}}  = @temp_refpath;
			@{$self->{namepath}} = @temp_namepath;
			$self->{cursor} = $self->{refpath}[-1];

		} #End if ($dir eq ...

		#------------------------------
		# If the calls to down() or up() have failed for some reason,
		# then return to wherever were to begin with. 
		# Don't even bother to parse the rest of the path,
		# just return immediately. 
		#
		if (not defined $self->{cursor}) {

			@{$self->{refpath}}  = @temp_refpath;
			@{$self->{namepath}} = @temp_namepath;
			$self->{cursor} = $self->{refpath}[-1];

			return $self->{cursor};
		}

	} #End foreach (@dirs) 


	# Looks like we successfully chdir'd from one place into another.
	# Save our previous location in the structure into the "prev_" variables.
	# The previous previous variables (meta-previous?) are now forgotton.
	#
	@{$self->{prev_refpath}}  = @temp_refpath;
	@{$self->{prev_namepath}} = @temp_namepath;

} #End sub walker_chdir


#---------------------------------------------------------------------------
# Implement "ls" formatting logic
#
sub walker_ls {

	my ($self,$option) = @_;
	my ($reftype,$refpackage) = reftype($self->{cursor});

	my $retval = "";

	if ($option =~ /l/) {

		my $dots = "";
		my $format = "%-$self->{lscol1width}s %-$self->{lscol2width}s %s\n";

		if ($option =~ /a/) {

			my ($type,$value);
	
			if (scalar @{$self->{namepath}} >  1) {
	
				($type,$value) = $self->printref($self->{refpath}[-2]);
				$dots .= sprintf( $format, '..', $type, $value );
				($type,$value) = $self->printref($self->{refpath}[-1]);

			} else {

				($type,$value) = $self->printref($self->{refpath}[-1]);
				$dots .= sprintf( $format, '..', $type, $value );
			}

			$dots .= sprintf( $format , '.', $type, $value );
		}

		if ($reftype eq "REF") {

			$retval .= $dots;
			my ($type,$value) = $self->printref(${ $self->{cursor} });
			$retval .= sprintf( $format, $self->{refname}, $type, $value );

		} elsif ($reftype eq "HASH") {

			$retval .= $dots;
			foreach (sort keys %{$self->{cursor}}) {

				my ($type,$value) = $self->printref($self->{cursor}->{$_});
				$retval .= sprintf( $format, $_, $type, $value );
			}

		} elsif ($reftype eq "ARRAY") {

			$retval .= $dots;
			my $i = 0;
			foreach (@{ $self->{cursor} }) {

				my ($type,$value) = $self->printref($_);
				$retval .= sprintf( $format, $i++, $type, $value );
			} 

		} else {

	 		$retval .= "Current ref is a ref to " . $reftype . 
				", don't know how to emulate ls -l in it.\n";
		}

	} else {

		my $dots = ($option =~ /a/) ? "..\t.\t" : "";

		if ($reftype eq "REF") {

			$retval .= $dots . $self->{refname} . "\n";

		} elsif ($reftype eq "HASH") {

			$retval .= $dots;
			foreach (sort keys %{ $self->{cursor} }) {

				$retval .= $_. "\t";
			}
			$retval .= "\n";

		} elsif ($reftype eq "ARRAY") {

			$retval .= $dots;
			my $i = 0;
			foreach (@{ $self->{cursor} }) {

				$retval .= $self->printref($_) . "\t";
			}

		} else {

			$retval .= "Current ref is a $reftype, don't know how to emulate ls in it.\n";
		}

	}

	return $retval;

} #End sub walker_ls


#---------------------------------------------------------------------------
# Implement "cat" formatting logic
#
sub walker_cat {

	my ($self,$target) = @_;
	my ($reftype,$refpackage) = reftype($self->{cursor});

	my $retval = "";

	# Prints "print--> "...
	$retval = "print$self->{arrowshaft}$self->{arrow} '" . $target . "'\n";
			
	if ($target eq ".") {

		$retval = $self->{cursor};

	} elsif ($target eq '..') {

		$retval = ${$self->{refpath}[-2]} if (scalar @{$self->{namepath}} >  1);
		$retval = ${$self->{refpath}[-1]} if (scalar @{$self->{namepath}} <= 1);

	} elsif ($reftype eq "HASH") {

		$retval = $self->{cursor}->{$target};

	} elsif ($reftype eq "ARRAY") {

		$retval = $self->{cursor}->[$target];

	} else {

		print "Current ref is a $reftype, don't know how to print from it."
			if $self->{warning};
	}

	return $retval;

} #End sub walker_cat


#---------------------------------------------------------------------------
# Print the current path
#
sub walker_pwd {

	my $self = shift;
	return join $self->{arrow},@{$self->{namepath}};
}


#---------------------------------------------------------------------------
# Invoke Data::Dumper::dump
#
sub walker_dump {

	my ($self,$target) = @_;
	my ($reftype,$refpackage) = reftype($self->{cursor});

	my $retval = "";

	# Pass config values directly to Data::Dumper
	#
	local $Data::Dumper::Indent   = $self->{indent};
	local $Data::Dumper::Maxdepth = $self->{maxdepth};

	# Prints "dump--> "...
	$retval .= "dump$self->{arrowshaft}$self->{arrow} '$target'\n";
			
	if ($target eq ".") {

		$retval .= Data::Dumper->Dump( [ $self->{cursor} ] );

	} elsif ($target eq '..') {

		$retval .= Data::Dumper->Dump([ $self->{refpath}[-2] ],[ $self->{namepath}[-2] ]) 
			if (scalar @{$self->{namepath}} >  1);
		$retval .= Data::Dumper->Dump([ $self->{refpath}[-1] ],[ $self->{namepath}[-1] ]) 
			if (scalar @{$self->{namepath}} <= 1);

	} elsif ($reftype eq "REF") {

		$retval .= Data::Dumper->Dump( [ ${$self->{cursor}} ], [ $target ] );

	} elsif ($reftype eq "HASH") {

		$retval .= Data::Dumper->Dump( [ $self->{cursor}->{$target} ], [ $target ] );

	} elsif ($reftype eq "ARRAY") {

		$retval .= Data::Dumper->Dump( [ $self->{cursor}->[$target] ], [ $target ] );

	} else {

		$retval .= "Current ref is a $reftype, don't know how to dump things from it."
			if $self->{warning};
	}

	return $retval;

} #End sub walker_dump



#---------------------------------------------------------------------------
# Format the CLI prompt (this is called after each command)
#
sub walker_getprompt {

	my $self = shift;

	#------------------------------
	# Take a copy of the namepath, because we are going to munge it
	#
	my @temp_namepath = @{ $self->{namepath} };

	my (%seen,%seen_twice);
	my $count = 1;

	for (my $i = 0; $i < scalar @{$self->{refpath}}; $i++) {

		# Check to see if we are seeing this ref for the *second* time.
		# If so, define it in the %seen_twice hash. 
		#
		if (
			exists $seen{ $self->{refpath}[$i] } 
			and 
			not exists $seen_twice{ $self->{refpath}[$i] } 
		) {

			$seen_twice{ $self->{refpath}[$i] } = $count++;
		}

		$seen{ $self->{refpath}[$i] } = 1;
	}

	for (my $i = 0; $i < scalar @{$self->{refpath}}; $i++) {

		$temp_namepath[$i] .= "-" . $seen_twice{ $self->{refpath}[$i] } . "-"
			if exists $seen_twice{ $self->{refpath}[$i] };
	}

	return sprintf  "%s$self->{promptchar} ", join $self->{arrow},@temp_namepath;

} #End sub walker_getprompt


#---------------------------------------------------------------------------
# Format help messages
#
sub walker_help {

	my ($self,$arg) = @_;
	my $retval = "";

	if (defined $arg and $arg =~ /show/) {

		($retval =<<"		EOM") =~ s/^\s+//gm;
		The following items can be configured
		(current value is in parenthesis):
	
		rootname        how the root node is displayed ("$$self{rootname}")
		refname         how embedded refs are listed ("$$self{refname}")
		scalarname      how simple scalars are listed ("$$self{scalarname}")
		undefname       how unefined scalars are listed ("$$self{undefname}")
		promptchar      customize the session prompt ("$$self{promptchar}")
		arrowshaft      first part of ref arrow ("$$self{arrowshaft}")
		arrowhead       last  part of ref arrow ("$$self{arrowhead}")
	
		maxdepth        maximum dump-depth (Data::Dumper) ($$self{maxdepth})
		indent          amount of indent (Data::Dumper) ($$self{indent})
		lscol1width     column widths for 'ls' displays ($$self{lscol1width})
		lscol2width     column widths for 'ls' displays ($$self{lscol2width})
	
		showrecursion   note recursion in the prompt ($$self{showrecursion})
		showids         show ref id numbers in ls lists ($$self{showids})
		skipdoublerefs  hop over ref-to-refs during walks ($$self{skipdoublerefs})
		skipwarning     warn when hopping over ref-to-refs ($$self{skipwarning})
		truncatescalars truncate scalars in 'ls' displays ($$self{truncatescalars})
	                	(use 0 for no truncation)

		type "show <configname>" to display a value
		type "set <configname> <value>" to assign a new value
		EOM

	} else {

		($retval =<<"		EOM") =~ s/^\s+//gsm;
		The following commands are supported:

		cd <target>          like UNIX cd
		ls                   like UNIX ls (also respects options -a, -l)
		print <target>       prints the item as a scalar
		dump <target>        invokes Data::Dumper
		set <key> <value>    set configuration variables
		show <key>           show configuration variables
		! or eval            eval arbitrary perl (careful!)
		help                 this help message
		help set             lists the availabe config variables
		EOM
	}

	return $retval;

} #End sub walker_help


#---------------------------------------------------------------------------
# Show the walker's config variables
#
sub walker_show {

	my ($self,$arg) = @_;
	my $retval = "";

	if (defined $arg and $arg ne "") {

		my $key = lc $arg;
		$key =~ s/^\s+//;
		$key =~ s/\s+$//;

		unless (exists $self->{$key}) {

			return "No such config variable as '$key'\n";
		}

		# Print out the variable key and value.
		# Quote anything that's not a decimal value.
		#
		if ($self->{$key} =~ /^(?:0|-?[1-9]\d{0,8})$/) {
			$retval = "$key = $self->{$key}\n";
		} else {
			$retval = "$key = '$self->{$key}'\n";
		}

	} else {

		foreach (sort { $a cmp $b } keys %Config) {

			# Print out the variable key and value.
			# Quote anything that's not a decimal value.
			#
			if ($self->{$_} =~ /^(?:0|-?[1-9]\d{0,8})$/) {
				$retval .= sprintf "%-15s = %s\n", lc($_), $self->{$_};
			} else {
				$retval .= sprintf "%-15s = '%s'\n", lc($_), $self->{$_};
			}
		}
	}

	return $retval;
}

#---------------------------------------------------------------------------
# Parse commands, either from the CLI or from an AUTOLOADed function.
# Dispatch to the proper internal methods.
#
sub parse_command {

	my $self = shift;
	my $cmd  = join ' ',@_;

	$cmd = '' unless defined $cmd;
	my $retval = "";

	#------------------------------------------------------------
	# Emulate the pwd command
	#
	if ($cmd =~ /^(pwd)$/) {

		$retval .=  $self->walker_pwd . "\n";

	#------------------------------------------------------------
	# Print the help blurb
	#
	} elsif ($cmd =~ /^\s*(help|h)\s*$/) {

		$retval .=  $self->walker_help;

	} elsif ($cmd =~ /^\s*help\s+(set|show)\s*$/) {

		$retval .=  $self->walker_help("show");

	#------------------------------------------------------------
	# Emulate cd
	#
	} elsif ($cmd =~ /^\s*(cd|chdir)\s+(.+)$/) {

		# Change directories, but don't print anything.
		# (walker_chdir returns a reference)
		#
		$self->walker_chdir($2);

	#------------------------------------------------------------
	# Emulate ls -l
	#
	} elsif ($cmd =~ /^\s*(lal|lla|all|ll\s+-?a|ls\s+-?al|ls\s+-?la|dir|ls\s+-?a\s+-?l|ls\s+-?l\s+-?a|la\s+-?l)\s*$/) {

		$retval .=  $self->walker_ls("la");
		
	} elsif ($cmd =~ /^\s*(ll|ls\s+-?l|ls\s+-?l)\s*$/) {

		$retval .=  $self->walker_ls("l");
		
	} elsif ($cmd =~ /^\s*(ls\s+-?a|la)\s*$/) {

		$retval .=  $self->walker_ls("a");

	} elsif ($cmd =~ /^\s*(l|ls)\s*$/) {

		$retval .=  $self->walker_ls("");

	#------------------------------------------------------------
	# Emulate cat 
	#
	} elsif ($cmd =~ /^\s*(cat|type|print|p)\s+(.+?)\s*$/) {

		$retval .=  $self->walker_cat($2) . "\n";

	#------------------------------------------------------------
	# Invoke dump
	#
	} elsif ($cmd =~ /^\s*(dump|d)\s+(.+?)\s*(\d*)$/) {

		$retval .=  $self->walker_dump($2);

	} elsif ($cmd =~ /^\s*(dump|d)\s*$/) {

		$retval .=  $self->walker_dump('.');

	#------------------------------------------------------------
	# Adjust config settings ("set indent 2")
	#
	} elsif ($cmd =~ /^\s*set\s+(\S+?)\s+(.+)$/i) {

		my ($key,$value) = (lc($1),$2);
		$value =~ s/^[=\s]*//;
		$value =~ s/[\s]*$//;

		my $msg = $self->walker_set($key,$value);
		$retval .=  "$msg.\n" if $msg;


	#------------------------------------------------------------
	# Show config settings  ("show indent" etc.)
	#
	} elsif ($cmd =~ /^\s*show(.*)$/i) {

		my $arg = defined($1) ? $1 : "";

		$retval .=  $self->walker_show($arg);

	} else {

		$retval .= "Ignoring command '$cmd', could not parse. (Type 'help' for help.)\n";
	}

	return $retval;

} #End sub parse_command


#---------------------------------------------------------------------------
# "Walk" a data structure.  This function implements the CLI.
#
sub cli {

	# This code handles both OO-invocation as a method and
	# non-OO invocation
	#
	my $class = __PACKAGE__;
	my ($self,$ref);

	if (defined $_[0] and $_[0] eq $class and defined $_[1] and ref $_[1]) {

		# cli() was invoked as a class method, 
		# so we create an object on the fly.  This object will 
		# be destroyed as soon as $self goes out of scope, 
		# which is at the end of this function.
		#
		$self = new($class);
		$ref  = $_[1];
		$self->walk($ref) or return;

	} elsif (defined $_[0] and ref $_[0] eq $class and defined $_[1] and ref $_[1])  {

		# cli() was invoked as a method on an object,
		# so we use this object.
		#
		($self,$ref) = @_;
		$self->walk($ref) or return;

	} elsif (ref $_[0] eq $class and defined $_[0]->{cursor})  {

		# cli() was entered on a Data::Walker object which already exists,
		# so we use that.
		#
		($self,$ref) = @_;

	} elsif (defined($WALKER) and ref($WALKER) eq __PACKAGE__) {

		# cli() was not invoked with any parameters, but there is an
		# implicit Data::Walker object, so we use that. 
		#
		$self = $WALKER;

	} else {

		print "cli:  No reference!";
		return;
	}

	printf "%s$self->{promptchar} ",join $self->{arrow},@{$self->{namepath}};

	#------------------------------------------------------------
	# Command loop.  We loop through here once for each command
	# that the user enters at the prompt.
	#
	COMMAND: while(<>) {

		chomp;
		next COMMAND unless /\S/;               # Ignore empty commands

		return if m/^\s*(q|qu|quit|ex|exi|exti|exit)\s*$/i;    # 50 ways to leave your CLI


		#------------------------------------------------------------
		# eval:  Take whatever the user typed in and eval it
		#
		if (s/^\s*(\!|eval)\s+//) {

			# prints "eval--> "...
			#
			print "eval$self->{arrowshaft}$self->{arrow} $_\n";

			# Let the user refer
			my ($par,$cur); 
			$par = $self->{refpath}->[-2] if scalar @{$self->{refpath}} >  1; 
			$par = $self->{refpath}->[-1] if scalar @{$self->{refpath}} == 1; 
			$cur = $self->{cursor};            

			s/\$$self->{curname}\b/\$cur/g;
			s/\$$self->{parname}\b/\$par/g;

			my $res = eval;
			$res = "undef" unless defined $res;

			# prints "retv--> "...
			#
			print "retv$self->{arrowshaft}$self->{arrow} $res\n";

		} else {

			print $self->parse_command($_);
		}

	} continue {  #continuing COMMAND: while(<>) {

		print $self->walker_getprompt;

	} #End COMMAND: while(<>) {

} #End sub cli


1;


