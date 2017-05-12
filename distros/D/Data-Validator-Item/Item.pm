package Data::Validator::Item;

=head1 NAME

Data::Validator::Item	Factory Class to validate data items

=head1 DESCRIPTION

This is an attempt to create an object which will permit semi-automatic verification of a data value.

=head1 SYNOPSIS

 use Data::Validator::Item;
 my $item = Data::Validator::Item->new(); #Create a new Data::Validator::Item, called $item.

 #Set values
	$item->name('fred');
	$item->values([1,2,3]); 	or 	$item->values(\@array);
	$item->missing('*'); 	or 	$item->missing(''); #undef is unlikely to be sensible!
	$item->min(0);  $item->max(100);
	$item->verify($reference_to_subroutine); #Used in the $item->validate() function
	$item->transform($reference_to_subroutine); #Used in the $item->put() function

 #Get values
	my $name = $item->name();
	my @values = $item->values();
	my $missing = $item->missing();
	etc...

#Use it..
	$item->validate(); #Returns 1 for success, 0 for failure
	$item->error(); #Returns the correct error message
	$item->put();

=head1 USAGE

Many people work with data organised as records, each containing
(potentially many) variables. It is often necessary to process files
of such records, and to test every variable within every record to ensure that
each one is valid. I do this before putting data from very large flat files into my databases.
For each variable I had a need to define specific, sometimes complex rules for validity,
then implement them, and check them. This is what Data::Validator::Item is for.

Note carefully that Data::Validator::Item handles only one scalar vlaue at a time. This
value could come from a file, a database, an array, a hash or your granny's parrot.
Data::Validator::Item doesn't care.

I use Data::Validator::Item as follows. I create one for every named variable in my
data file. In many real applications most of this setup can be done by looping
over a list of variable names, creating many Data::Validator::Items each named for
the corresponding variable. Common features, like missing values, and names
can be set in this loop. Specifics, like values(), min(), max(), verify() and so on
can be set individually. I then create a hash to hold all of the Data::Validator::Items for
a particular data source, The keys of this hash are the names of the variables,
and the values are the Data:Validators themselves.
Y.M.M.V.

=head1 ROLE

A Data::Validator::Item exists (almost) solely to create two functions - validate() and put().
They make it easy to apply complex tests for 'validity' to data.

Typically you will set up many of these, one per variable, once at the start
of a program, and you then use them to validate() and put() each individual item of data.
Data::Validator::Item neither knows nor cares where the data comes from, you just feed data
items to the correct ->validate() and ->put() one at at time, and they get checked.

There is no useful way to check the values of a variable depending on the values
of another variable in the same record. This is a different problem, one which could
be approached with Data::Validator::Record, if it existed. Feel free to write it. I hope to
get around to this in 2003.

=head2 PROBLEM ADDRESSED

A fairly common problem in my work is the following:
I get a data file, which has been created, often using Excel or Access. It is
riddled with errors, because it wasn't checked at all during data
entry. (I'm a *very* good data entry person, and I make about
1 mistake per 100 data items.)

Before I can use it I need to check the actual values in the data file.
Typically my clients don't know exactly what the legitimate values are for
each variable. For example a variable called 'sex' is supposed to be 0 or 1,
(female or male) and there are actually 140 '2's in the data set. On enquiry,
it turns out that 2 is the missing value for that variable. (Of course for
other variables in the data set the missing value might be '3', or '8' or
'-' or '*' or just blank).

I need to check every individual value in every record in a file,
against the values it is supposed to have, and I also often need to
change a variable, so that I can stuff it into a database. Clearly these two
tasks are closely related, and so I wrote a module which can do both,
if you want. Let me have your views on this decision.

=cut

#use stuff
use strict;
use Carp;

#Package globals
our $VERSION = '0.75';
my $Debugging = 0;

=head1 PUBLIC FUNCTIONS

=head2 new()

The new() function initialises a blank Data::Validator::Item with all of it's contents set
explicitly to undef.

C<< my $item = Data::Validator::Item->new(); >>

=cut

#Initiate the Data::Validator::Item
sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
        my $self  = {};
#Documentation only
		$self->{NAME}		= undef; # Name of the variable or whatever, not currently used
#Used for validation
		$self->{MIN}		= undef; # Numerically (or alphabetically) smallest value
		$self->{MAX}		= undef; # Numerically (or alphabetically) largest value
		$self->{MATCH}	= undef; # Reference to a function matching a regex
		$self->{VALUES}	= undef; # Reference to an array of all possible values
		$self->{VERIFY}	= undef; # Reference to a function capable of verifying variable e.g. dates
		$self->{LOOKUP}	= undef; # Reference to a DBI Satement handle to do lookup on possible values
#Used for validation and transformation
		$self->{MISSING}	= undef; # Missing value, accepted as a valid value, and transformed to undef in put()
#Used for transformation only
		$self->{TRANSFORM}= undef; # Reference to a function capable of transforming variable for output
#Used for reporting on errors - Overwritten every time validate() is called
		$self->{ERROR}	= undef; # Error message from last failed validation
        bless ($self, $class);
        return $self;
    } #End of subroutine new

=head2 zap()

The zap() function re-initialises an existing Data::Validator::Item with all of it's contents reset
explicitly back to undef. This is used in some of the test scripts, but may not have many other uses.

C<< $item->zap(); >>

=cut

sub zap {
        my $self = shift;
		$self->{NAME}		= undef;
		$self->{MIN}		= undef;
		$self->{MAX}		= undef;
		$self->{MATCH}	= undef;
		$self->{VALUES}	= undef;
		$self->{VERIFY}	= undef;
		$self->{LOOKUP}	= undef;
		$self->{MISSING}	= undef;
		$self->{TRANSFORM}= undef;
		$self->{ERROR}	= undef;
        return $self;
} #End of subroutine zap

=head1 put() and validate()

These two functions are what Data::Validator::Item is meant to create.
validate() checks a scalar to see if it is acceptable.
put() is used to transform a scalar for otuput

=head2 validate()

validate() takes a scalar, and tests it, using all of the tests which you have
chosen to put into the particular Data::Validator::Item. It returns success (1)
or failure(0) if at least one test fails.

C<< $item->validate($datum); >>

It also sets an appropriate error message as

C<< $item->error(); >>

1 means the item was either ok (passed all tests) *or* the missing value, in other words, acceptable...
0 means that the item failed at least one test. Note that you can't get at how many tests an item
failed, and that the error message relates only to the first test failed by an item.

Do B<not> ignore these return codes when using this module.

=cut

sub validate {
	my $self = shift;
	my $datum = shift;

	$self->error(undef);

#Tests placed in approximate order of cost!

	if (defined($self->missing()) && ($datum eq $self->missing())) {
	$self->error("$datum is missing");
	return 1;};
#It's missing - return validated, and move on

	unless (defined($datum)) {
	$self->error("$datum is undefined");
	return 0};
#It's undefined -  complain! It shouldn't be.

	if (defined($self->min()) && ($datum < $self->min())) {
	$self->error("$datum is too small");
	return 0;};

	if (defined($self->max()) && ($datum > $self->max())) {
	$self->error("$datum is too big");
	return 0;};
#Too big or too small

	if (defined($self->match())){
		my $match = $self->match();
		if ($datum !~ /$match/){
		$self->error("$datum doesn't match the regex");
		return 0;}
	return 1;} # if defined $self->match()
#Doesn't match the regex supplied

	if (defined($self->values())) {
		my %hash = %{ $self->values()};
		unless (exists $hash{$datum}) {
			$self->error("$datum is not in the list of values");
			return 0;};
	};
# Not in the approved list of values

	if (defined($self->verify())) {
		my $coderef = $self->verify();
		unless (&$coderef($datum)) {
			$self->error("$datum is not verified");
			return 0};
	};
#Not confirmed by verification subroutine

return 1;
# All is well
} #End of subroutine validate

=head2 put()

put() returns the data value,

=over 4

=item *

or the transformed data value by the transform() function provided by you,

=item *

or undef, if the data value was the missing() value.

=back

=cut

sub put {
	my $self = shift;
	my $datum = shift;

	if (defined($self->missing()) && ($datum eq $self->missing())) {return undef;};
	# It's missing
	if (defined($self->transform())) {
		# It needs to be transformed, and it's not missing
		my $coderef =  $self->transform();
		$datum =&$coderef($datum);
		return $datum;
		}
	#Just pass it through
    return $datum;
    } #End of subroutine put

=head1 Get and Set functions

Data::Validator::Item implements a policy to decide on the acceptability or otherwise
of  scalar value, and to transform this value for output. The B<Set> functions
allow you to define the policy. These functions require an argument. These
functions are most likely to be used when creating a Data::Validator::Item.

The corresponding B<Get> functions are intended for use B<only> within the
Data::Validator::Item, when creating the put() and validate() functions. These are the
no argument functions.

=head2 name()

name() sets or gets the name of the Data:Validator - I use this just to remind me, and
I usually set it to the name of the variable. This doesn't get used anywhere else - it's just
icing, but it sure makes debugging easier.

C<< $item->name("Item"); >>

=cut

sub name {
        my $self = shift;
        if (@_) { $self->{NAME} = shift }
        return $self->{NAME};
    } #End of subroutine name

=head2 error()

error() sets or gets the last error message.

=cut

sub error {
	my $self = shift;
        if (@_) { $self->{ERROR} = shift }
        return $self->{ERROR};
	} #end of subroutine error

=head2 missing()

missing() gets  or sets the missing value for a Data::Validator::Item. This does matter, because
missing values are acceptable to validate(), and because put() changes missing values to undef.
This is used by *both* put() and validate(). If you don't understand why missing values are
*acceptable* you need to think harder about the problem we're solving here.
Would you like missing() to accept several alternative missing values? Let me know...

C<< $item->missing(""); >>
C<< $item->missing('*'); >>

=cut

sub missing {
        my $self = shift;
        if (@_) { $self->{MISSING} = shift }
        return $self->{MISSING};
    } #End of subroutine missing

=head2 min()/max()

min() and max() get and set the lower and upper limits for a Data::Validator::Item. These are
used by validate() to check whether a value is greater than or less than a limit. These could
be used for character data, but really make more sense for numeric values. Note that I
don't really understand how min and max work for character data yet. Note also that perl
may occasionally require you to tell it that a variable is numeric. (try adding 0 to it if this
problem arises).

C<< $item->min(-5) >>
or
C<< $item->max(42) >>

=cut

sub min {
        my $self = shift;
        if (@_) { $self->{MIN} = shift }
        return $self->{MIN};
    } #End of subroutine min

sub max {
        my $self = shift;
        if (@_) { $self->{MAX} = shift }
        return $self->{MAX};
    } #End of subroutine max

=head2 match()

match() sets or gets a Perl regular expression. If you know the syntax of these
you can do clever stuff. Bear in mind that the validate function uses it internally like this

	my $match = $self->match();
		if ($datum !~ /$match/)

If this means nothing to you, just use it like these examples -

C<< $item->('r') >>
C<< $item->('dog') >>

=cut

sub match {
my $self = shift;
        if (@_) {
	my $regex = shift;
	if (_is_valid_pattern($regex)) { #Is it a valid regex?
		$self->{MATCH} = $regex;
		return $self->{MATCH};
		}
	}# If @_
        return $self->{MATCH};
} #End of subroutine match

=head2 transform()

transform() sets or gets a reference to a subroutine, a reference of type CODE. This
is used by put() to change the value of a variable. This is very flexible, and has covered
all of my needs so far.

C<< $item->transform(\&test) >>

=cut

sub transform {
        my $self = shift;
        if (@_) {
	my $ref = shift;

	if (_ref_check($ref,'CODE')) { # Is it a CODEREF??
			$self->{TRANSFORM} = $ref;
			return $self->{TRANSFORM};
		}
	} # if(@_)
return $self->{TRANSFORM};
}  #End of subroutine transform

=head2 verify()

verify() sets or gets a reference to a subroutine, a reference of type CODE. This is
used by validate() to check if a variable complies with certain rules. This is the most
complicated method of testing a value but it can be very useful in some circumstances.
Remember there isn't any built in way to use the value of  *another* variable from the
same record in this subroutine.

C<< $item->verify(\&test); >>

=cut

sub verify {
        my $self = shift;
	if (@_) {
	my $ref = shift;
	if (_ref_check($ref,'CODE')) { # Is it a CODEREF??
			$self->{VERIFY} = $ref;
			return $self->{VERIFY};
		}
	} # if(@_)
return $self->{VERIFY};
} #End of subroutine verify

=head2 values()

values() sets or gets an array reference containing all of the possible values of a variable.
This is used by validate() to check if a variable has one of a list of values. The array reference gets
turned into a hash internally so that I can use exists(), but in Perl 5.8 and up exists() works for arrays.
I chose to initialise this using array references because the syntax is easy -

C<< $item->values([0,1,2,3,4]); >>
or
C<< $item->values(\@array); >>

=cut

sub values {
        my $self = shift;
        if (@_) {
	my $ref = shift;
	if (_ref_check($ref,'ARRAY')) { # Is it an ARRAY reference??			$self->{TRANSFORM} = $ref;
			my %hash;
			grep { ! $hash{$_} ++ } @$ref; #Perl Cookbook Recipe 4.6 Thanks!
			$self->{VALUES} = \%hash;
		        return $self->{VALUES};
		}
	  } # if(@_)
  return $self->{VALUES};
} #End of subroutine values

=head1 PRIVATE FUNCTIONS

=head2 _ref_check()

_ref_check() is a private subroutine which looks to see if a reference refers to what you expect. Don't
use it. Note that this produces a number of warnings during testing. you're meant to see these warnings!

=cut

sub _ref_check {
my ($test,$should_be) = @_;
#Why doesn't this get called with self as it's first argument?

my $ref = ref($test);

unless ($ref eq $should_be) {
	if (length($ref) > 0) {
				carp ("\n>> $test isn't a reference to an array, but rather a reference to a ".$ref."\n")
				}
				else
				{
				carp ("\n>> $test isn't an array reference at all, but a SCALAR\n")
				}# if (defined($refref))
		return 0;
		} # unless ($ref eq $should_be)
return 1;
} #End of subrotuine _ref_check

=head2 _is_valid_pattern()

_is_valid_pattern is a private function used internally to check if a supplied regex is valid.
It comes from Tom Christiansen and Nathan Torkington 'The Perl CookBook' Recipe 6.11.
Thanks! More details at L<< http://www.oreilly.com/catalog/cookbook/ >>

=cut

sub _is_valid_pattern {
	my $pat = shift;

	return eval { "" =~ /$pat/; 1 } || 0;
} #End of subroutine _is_valid_pattern

return 1; #Required for all modules

=head1 KNOWN BUGS

min() and max() don't really work for non-numeric values, arguably they should!

=head1 AUTHOR

Anthony Staines <Anthony.Staines@ucd.ie>

=head1 VERSION

Version 0.7 first public (alpha) release

=head1 TO DO

This is an alpha release. I am actively seeking feedback on the user interface.
Please let me know  what you think.

The validate and put functions are called a lot - several hundred thousand times
in my applications. The program spends most of it's time executing these. (Confirmed
by profiling). I will implement an eval based version of these, and see if it is faster - it should be!

Try anthony.staines@ucd.ie with your comments

=head1 SEE ALSO

L<perl>.

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2002 by Anthony Staines. This program is free software;
you can redistribute it and/or modify it under the terms of the Perl Artistic License or the
GNU General Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to the Free Software Foundation, Inc.,
675 Mass Ave, Cambridge, MA 02139, USA.

=head1 Long Example

Please let me know if you feel that this example is B<not> appropriate here.
This example is heavily edited and won't compile - If you want the original ask me.
at C<< anthony.staines@ucd.ie >>

 #Load_Births.pl
 #
 # Copyright (c) 2002 Anthony Staines. All rights reserved.
 # This program is free software; you can redistribute it and/or
 # modify it under the same terms as Perl itself.

 #use things...

 use Data::Validator::Item; #My verification function factory


 #Open the data file - we use STDIN (redirected to a file)

 #Read the header - first line of file - a comma seperated list of variable names

 my @fields = @{read_header()};
 my $fields = join(", ",@fields); #List of field names for DBI INSERT

 my @values = ('?') x scalar(@fields);
 my $values = join(", ", @values); #Same number of question marks...

 #Setup the data dictionary
 my %dictionary = %{Births_setup()};

 # Hash to store rejected variables
 my %errors;

 #Set up and prepare the SQL and the $sth
 if ($entering) {
	$sql = "INSERT INTO $table ($fields) VALUES ($values)";
	$sth = $dbh->prepare($sql); #Putting this outside the loop reduces execution time significantly
 } # if $entering

 while (<>) { #This reads the input file, line by line
	my @output; my $index = 0; my $error = 0; my $error_msg='';

	$csv->parse($_);
	my @data = $csv->fields();

	foreach my $datum (@data) {

	# B< Validate >
		if ($dictionary{$fields[$index]}->validate($datum)!=1) {
			$error_msg = "\t Line ".$line." ".$fields[$index]."-".$datum;
			$errors{$error_msg} = 1; #Fill the hash of error messages for later printing
			$error = 1;
		} #if validate() returns invalid

	# B< Put >
		#if required, and no errors occurred
		if ($entering && !$error) {
		push @output, $dictionary{$fields[$index]}->put($datum);
		} #If entering data

		$index++;
	} # foreach $datum in @data

 	$line++; #Increment the  line counter for error reporting, note that lines beginning with the comment character will be included
 } #End of while (<>)


 print join("\n",sort(keys(%errors)))."\n"; # Produces a list of rejected values

 exit(1);

 #
 # Read_header First line in data files must contain a list of field names.
 #
 sub read_header {
 defined(my $header = <>) #First line in STDIN
	or die("Error accessing STDIN - $!\n");

 $csv->parse($header)
	or die("Error parsing the header of the input file - $!\n");

 my @fields = $csv->fields()
	or die("Error retrieving contents of parsed header - Should never happen - $!\n");

 foreach my $field (@fields) {
	$field = lc($field);
	}

 return \@fields;
 } #End of subroutine read_header

 #
 # B< Births_setup >
 #
 sub Births_setup {

 my @variables = ('AGE_MAT','AGE_MAT_OBS','HOSP_NO','YEAR_RECORD','CASE_NO','INST_NO',
			'DAY_BIRTH','MONTH_BIRTH','YEAR_BIRTH','YEAR_BIRTH_OBS',
			[snip]
			'ENT_NO','CO_REG','REGSTAMP','AGE_MARRIAGE','DURATION_MARRIAGE','ADJ_PREV_LIVE_BTHS');

 my %dictionary;

 #Write the boring bits of dictionary
 foreach my $variable (@variables) {
	my $code = 'my $'.lc($variable).'= Data::Validator::Item->new();' ;
	$code .= '$dictionary{'.lc($variable).'} = $'.lc($variable).';';
	$code .= '$'.lc($variable).'->name("'.lc($variable).'");';
	$code .= '$'.lc($variable).'->missing(\'\');';
	eval($code);
	print "\$@ was $@\n" if $@;
 }

 #Each entry in the dictionary looks like this -
 # my $age_mat=Data::Validator::Item->new();	#Set up the Data::Validator::Item called age_mat
 #  $dictionary{age_mat}=$age_mat;		#Add it to the $dictionary hash
 #  $age_mat->name('age_mat');			#Set the name attribute of the $age_mat
 #  $age_mat->missing('');				#Set the missing attribute of the $age_mat
 #

 #Subroutines used for verification/transformation
 my $sex_coderef = sub{
	my $datum = shift;
	my %transform = (
		1 => 'M',
		2 => 'F',
		3 => 'U',
		);
 return $transform{$datum}
 };

 my $day_coderef = sub {
	my $datum = shift;
	if ($datum =~  /0+-$/){return 1};
	if ($datum > 00 || $datum < 32) {return 1;}
 return 0;
 };

 my $month_coderef = sub {
	my $datum = shift;
	if ($datum =~  /0+-$/){return 1};
	if ($datum > 00 || $datum < 12) {return 1;}
 return 0;
 };

   #
   # This is where the specific rules are set for each variable
   # This lot shoudl give you a fair idea of how this module can be used
  #

  # AGE_MAT
  $dictionary{age_mat}->missing('99');
  $dictionary{age_mat}->min(13);
  $dictionary{age_mat}->max(52);
  # AGE_MAT_OBS
  $dictionary{age_mat_obs}->missing('99');
  $dictionary{age_mat_obs}->min(13);
  $dictionary{age_mat_obs}->max(52);
  # YEAR_RECORD
  $dictionary{year_record}->values([$year]);
  # SEX
  $dictionary{sex}->values([1,2,3]);
  $dictionary{sex}->transform($sex_coderef);
  # WEIGHT
  $dictionary{weight}->missing('9999');
  $dictionary{weight}->min(200);
  $dictionary{weight}->max(6500);
  [snip]
  # PD_GEST
  $dictionary{pd_gest}->missing('99');
  $dictionary{pd_gest}->min(16);
  $dictionary{pd_gest}->max(46);
  [snip]
  # DAY_BIRTH_MOTHER
  #$dictionary{day_birth_mother}->();
  $dictionary{day_birth_mother}->missing('99');
  $dictionary{day_birth_mother}->verify($day_coderef);
  # MONTH_BIRTH_MOTHER
  $dictionary{month_birth_mother}->missing('99');
  $dictionary{month_birth_mother}->verify($month_coderef);
  # YEAR_BIRTH_MOTHER
  $dictionary{year_birth_mother}->missing('9999');
  $dictionary{year_birth_mother}->min($min_year);
  $dictionary{year_birth_mother}->max($max_year);
  [snip]

  return \%dictionary; # this hash is the objective of this whole subroutine
  }# End of Births_setup

=cut
