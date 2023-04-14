
# Data::Ref


Walk a referenced arbitrary data structure and provide the reference to access values

When working with deeply nested complex data structures, it can be quite difficult to determine just what the key is for any value.

A Data::Ref module will traverse the data, printing the values and the keys used to access them.

Currently the only module available is for JSON

  Data::Ref::JSON

# Manual Installation

- perl Makefile.PL
- make
- make test
- make install

If you are on a windows box you should use 'nmake' rather than 'make'.

# Usage

## setDebugLevel
      For procedural use.

      Call as setDebugLevel($i);

      A value of 0 disables debugging output (default)

## walk
     Walk the data structure and print the string required to access it

     This can be used as an object or a procedure

### As Procedure
     use Data::Ref::JSON qw(walk);

     my %tc = (

	 'HL01-01' => {
	     'HL02-01' => [
		 'element 0',
		 'element 1',
		 'element 2'
	      ]
	 },

	 'HL01-02' => {
	     'HL02-01' => {
		 K4 => 'this is key 4',
		 K5 => 'this is key 5',
		 K6 => 'this is key 6'
	     }
	      }

      );

     walk(\%tc);

### As Object
     use Data::Ref::JSON;

     my %tc = (

	 'HL01-01' => {
	     'HL02-01' => [
		 'element 0',
		 'element 1',
		 'element 2'
	      ]
	 },

	 'HL01-02' => {
	     'HL02-01' => {
		 K4 => 'this is key 4',
		 K5 => 'this is key 5',
		 K6 => 'this is key 6'
	     }
	      }

      );

     my $dr = Data::Ref::JSON->new (
       {
	  DEBUG   => 0,
	  DATA	  => \%tc
       }
     );

     $dr->walk;

## new
     Given an arbitrary data structure, create a new object that can then be traversed by walk().

     walk() will print all values and the string used to access them

     Given the following structure:

      (

	 'HL01-01' => {
	     'HL02-01' => [
		 'element 0',
		 'element 1',
		 'element 2'
	      ]
	 },

	 'HL01-02' => {
	     'HL02-01' => {
		 K4 => 'this is key 4',
		 K5 => 'this is key 5',
		 K6 => 'this is key 6'
	     }
	      }

      );


     This would be the output:

     i:v, 0:element 0
     refStr: VAR->{'HL01-01'}{'HL02-01'}[0]
     i:v, 1:element 1
     refStr: VAR->{'HL01-01'}{'HL02-01'}[1]
     i:v, 2:element 2
     refStr: VAR->{'HL01-01'}{'HL02-01'}[2]
     k:v, 'K4':'this is key 4'
     refStr: VAR->{'HL01-02'}{'HL02-01'}{'K4'}
     k:v, 'K5':'this is key 5'
     refStr: VAR->{'HL01-02'}{'HL02-01'}{'K5'}
     k:v, 'K6':'this is key 6'
     refStr: VAR->{'HL01-02'}{'HL02-01'}{'K6'}

     Where
       i = position in array
	    k = hash key
	    v = value
	    refStr = the string used to access the value

# Demo Scripts

Some scripts to demonstrate usage

## dro.pl

Demonstrates using the object interface with an included test file.

This script reads in a Perl file that contains a Perl hash variable, and walks the structure

Use `./dro.pl --help` for options.

```bash
>  ./dro.pl
i:v, 0:element 0
refStr: VAR->{'HL01-01'}{'HL02-01'}[0]
i:v, 1:element 1
refStr: VAR->{'HL01-01'}{'HL02-01'}[1]
i:v, 2:element 2
refStr: VAR->{'HL01-01'}{'HL02-01'}[2]
k:v, 'K4':'this is key 4'
refStr: VAR->{'HL01-02'}{'HL02-01'}{'K4'}
k:v, 'K5':'this is key 5'
refStr: VAR->{'HL01-02'}{'HL02-01'}{'K5'}
k:v, 'K6':'this is key 6'
refStr: VAR->{'HL01-02'}{'HL02-01'}{'K6'}
```

## drp.pl

Similar to `dro.pl`, but uses the procedural interface.

## drj.pl

Similar to `dr[op].pl`, but this file reads in a JSON file, parses it, then walks the tree.

```bash
>  ./drj.pl
k:v, 'id':'1001'
refStr: VAR->[0]{'batters'}{'batter'}[0]{'id'}
k:v, 'type':'Regular'
...
k:v, 'type':'donut'
refStr: VAR->[2]{'type'}
```


