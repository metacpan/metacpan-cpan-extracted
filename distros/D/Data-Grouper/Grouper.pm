package Data::Grouper;

use strict;
#use vars qw($VERSION);

$Data::Grouper::VERSION = '0.06';


#
# Options
#
#   COLNAMES => [ name, name, ... ]
#   SORTCOLS => [ name, ... ]
#   AGGREGATES => [ colidx, colidx, ... ]
#   DATA => array of hashrefs or arrayrefs
#
#
# Note: The lastvals array's indexes correspond to the 
#       array indexes for SORTCOLS.  
#
sub new 
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   # set option defaults so they won't be undefined
   $self->{OUTER} = [];
   $self->{LASTVALS} = [];
   $self->{TOPLEVEL_AGGS} = {};
   $self->{OPTIONS} = {};
   
   #$self->{LASTADDED}  # we want this to be undefined at first

   # Set this to 0 to avoid extra work.  If somebody uses an
   # option that requires we compute aggregates, this will be
   # set to 1 later.
   #
   $self->{OPTIONS}->{USE_AGGREGATES} = 0;
   
   # load in options supplied to new()
   for (my $x = 0; $x <= $#_; $x += 2) 
   {
      my $opt = uc($_[$x]);
      
      defined($_[($x + 1)]) or die "grouper->new() called with odd number of option parameters - should be of the form option => value";
      $self->{OPTIONS}->{$opt} = $_[($x + 1)]; 
   }

   # automatically set this if necessary
   if (defined($self->{OPTIONS}->{AGGREGATES}) )
   {
      $self->{OPTIONS}->{USE_AGGREGATES} = 1;
   }
   
   bless($self);

   if (defined($self->{OPTIONS}->{DATA}))
   {
      $self->add_array($self->{OPTIONS}->{DATA});
   }

   return $self;
}

# DBI can return entire arrays with selectall_arrayref.  This
# function lets you just pass an array ref in instead of doing
# a while loop and calling add_row for each row.
#
sub add_array
{
   my ($self,$aref) = @_;
   for my $r (@{$aref}) 
   {
      if (ref($r) eq 'HASH')
      {
         $self->add_hash($r);
      }
      else
      {
         $self->add_row(@{$r});
      }
   }
}

#
# This adds a row to our dataset.
# This is pretty much the most important function in this
# module.
#
# This really should take a reference!!!!
#
sub add_row
{
   my ($self,@row) = @_;
   my $options = $self->{OPTIONS};
   my (%h);

   warn "You must define COLNAMES when using add_row or DATA with arrayrefs.\n"
      if not defined $options->{COLNAMES};
      
   # Turn @row into a hash
   @h{ @{ $options->{COLNAMES} } } = @row;

   $self->add_hash(\%h);
}

sub add_hash
{
   my ($self,$href) = @_;

   my $options = $self->{OPTIONS};
   my $sortcols = 1 + $#{ $options->{SORTCOLS} };

   # Automatically populate COLNAMES if it hasn't been done before
   if ($#{$options->{COLNAMES}} == -1)
   {
      @{$options->{COLNAMES}} = keys ( %{$href} );
   }


   # Create our own copy.  We don't want to modify someone
   # elses hash.
   my %h2 = %{$href};
   
   # apply format functions
   for my $fkey (keys(%{$options->{FORMAT}}))
   {
      my $fref = $options->{FORMAT}->{$fkey};
      $h2{$fkey} = &$fref($h2{$fkey});
   }
   
   # describe aref here   
   my $aref = $self->{OUTER};

   # Update top level aggregates
   if ($options->{USE_AGGREGATES} == 1)
   {
      for my $colname (@{$options->{AGGREGATES}})
      {
         my $val = $h2{$colname};
         $self->{TOPLEVEL_AGGS}->{"SUM_$colname"} += $val;
      }
   }   

   #
   # This loop iterates through the sort items, descending through 
   # the arrays of hashes until it gets to the leaf node where
   # this row belongs.  It then pushes the hash ref onto the
   # appropritate array.  Non-leaf arrays contain aggregate info.
   #
   # $i in this loop is an index into the SORTCOLS and LASTVALS arrays.   
   #
   
   for (my $i=0;$i<$sortcols;$i++)
   {  
      # Must figure out rowidx based on $i and COLNAMES
      my $colname = $options->{SORTCOLS}->[$i];

      warn "Item $colname in SORTCOLS does not correspond to COLNAMES.\n"
         if (!grep {$_ eq $colname} @{$options->{COLNAMES}});
         
      # If this is the first row, or it is a new value, create
      # new entries
      #
      # Comment from Sam Tregar-- use of 'ne' possibly inappropriate for
      # floating point data.  Provide an option here?
      #
      if (!defined($self->{LASTVALS}->[$i]) ||
          $self->{LASTVALS}->[$i] ne $h2{$colname}
         )
      {
 
         
         #
         # apply format functions to aggregates before moving on 
         # to new array
         # This needs to work for all the grouping levels after this... 
         # i.e., if $i=2 and $sortcols=4, we still have to format $i==3
         #
         if (defined($self->{LASTVALS}->[$i]))
         {
            $self->_format_tails($aref);         
         }

 
         # Add a new hash to the current array of hash refs
         # I copy this from the hash for this row as a shortcut to
         # give access to $colname, which is generally needed.  Also
         # other variables may be in @row, like IDs or something, that 
         # the author wants to use
         
         my %h3 = %h2;
         $h3{INNER} = [];
         push @{$aref}, \%h3;


         if ($options->{USE_AGGREGATES} == 1)
         {
            $self->_do_aggregates($aref,\%h2);
         }

         
         # Set aref, our array pointer, to the array of the 
         # next inner element
         $aref = $h3{INNER};

         # undefine all vals after this in order to
         # force new arrays to be generated
         $#{$self->{LASTVALS}} = $i;

         $self->{LASTVALS}->[$i] = $h2{$colname};
      }
      else
      {
         # this is the place to do totals....
         if ($options->{USE_AGGREGATES} == 1)
         {
            $self->_do_aggregates($aref,\%h2);
         }         

         #Move to inner array
         $aref = $aref->[-1]->{INNER};
      }
     
   }

   # We've found the right array, add the row
   push @{$aref},\%h2;
   $self->{LASTADDED} = $aref;
}

# Sometimes you will want to add some additional information
# to a row or a parent.  This function helps you do that.
#
# It takes these parameters:
#   *  Address (ar_loc)
#      This specifies which row you would like to add data to.  If you are
#      sorting on 3 columns, you would pass an array ref with between 1 and 3
#      values.  This would specify a non-innermost loop row.  This row would
#      then have the contents of the details parameter (below) added to its 
#      hash.
#
#   *  Details (hr_dtls)
#      This is a reference to a hash that will be added to the indicated
#      row, if it is found.
#
sub add_details
{
   my ($self,$ar_loc,$hr_dtls) = @_;

   # ar_loc contains basically an address
   my $colidx = 0;
   my $aref = $self->{OUTER};
   my $the_href;
   my $options = $self->{OPTIONS};
   
   for my $loc (@{$ar_loc})
   {
      my $found = 0;
      
      # look through rows for match
      for my $href (@{$aref})
      {
         my $colname = $options->{SORTCOLS}->[$colidx];
#         print "test ($loc) ($colname)<br>";
         if ($loc eq $href->{$colname})
         {
            $the_href = $href;
            $aref = $href->{INNER};
            $found = 1;
            last;
         }
      }
      
      # if it wasn't found return failure
      if (!$found) 
      { 
         #print "not found ($loc) !"; 
         return 0; 
      }
   
      $colidx++;
   }
   
   for my $k (keys (%{$hr_dtls}) )
   {
      $the_href->{$k} = $hr_dtls->{$k};
   }
   
   1;
}

sub get_details
{
}

#
#
# Returns the array ref you will need to pass to HTML::Template
#
# Computes any top level aggregates first though
#
sub get_data
{
   my ($self) = @_;
   $self->_format_tails($self->{OUTER});
   $self->{OUTER};
}

sub get_top_aggregates
{
   my ($self) = @_;
   my $options = $self->{OPTIONS};

   # possibly defer computation until here?

   # apply format functions
   # Does this make any sense?
   for my $fkey (keys(%{$options->{FORMAT}}))
   {
      my $fref = $options->{FORMAT}->{$fkey};
      $self->{TOPLEVEL_AGGS}->{$fkey} = &$fref($self->{TOPLEVEL_AGGS}->{$fkey});
   }

   $self->{TOPLEVEL_AGGS};
}

#
# Private functions
#


# _do_aggregates
#
# This helper function computes aggregates:
#
# SUM
# AVG
# COUNT
# MIN
# MAX
#
# $aref is an array reference into the structure we are building.
# $hr_row is a hash reference of the hash of the row we are adding.
#
sub _do_aggregates
{
   my ($self,$aref,$hr_row) = @_;
   my $href = $aref->[$#{$aref}];
   
   #
   # For each colidx in our list of columns to be summed,
   # add to its total
   #
   
   for my $colname (@{$self->{OPTIONS}->{AGGREGATES}})
   {
      my $val = $hr_row->{$colname};
      
      $href->{"SUM_$colname"} += $val;

      $href->{"COUNT_$colname"} ++;
      
      my $x = $href->{"MIN_$colname"};
      if (!defined( $x) || $val < $x)
      {
         $href->{"MIN_$colname"} = $val;
      }
      
      $x = $href->{"MAX_$colname"};
      if (!defined( $x) || $val > $x)
      {
         $href->{"MAX_$colname"} = $val;
      }
      
   }
   
   # Do the averages

}

#
# This code isn't very elegant.  I need to find a better
# way.
#
sub _format_tails
{
   my ($self,$aref2) = @_;         
   my $options = $self->{OPTIONS};
      
   while (defined($aref2) && defined($#{$aref2}>=0 && $aref2->[-1]->{INNER}))
   {   
      for my $fkey (keys(%{$options->{FORMAT}}))
      {
         my $fref = $options->{FORMAT}->{$fkey};
         my $href = $aref2->[-1];
         $href->{$fkey} = &$fref($href->{$fkey});
      }
      
      if ( $#{$aref2} >=0) 
      {
         $aref2 = $aref2->[-1]->{INNER};
      }
      else { undef $aref2; }
   }
}



1;
__END__

=head1 NAME

Data::Grouper - Perl module to aggregate data for use with template
modules.
 
=head1 SYNOPSIS


   my $grouper = new Data::Grouper(
                   COLNAMES => [ 'CATEGORY','SUBCAT','DESCR','PRICE'],
                   SORTCOLS => [ 'CATEGORY','SUBCAT' ]
                  );

   $sql = 'select category, subcat, description, price from order_items order by category, subcat';
   $aref = $dbh->selectall_arrayref($sql);
   $grouper->add_array($aref);

   $t = HTML::Template->new(filename=>'../foobar.htmlt');
   $t->param(OUTER=>$grouper->get_data());
   print $t->output;

Lazy?  Me too.  The DATA param can use only two calls:

   $sql = 'select category, subcat, description, price from order_items order by style, color';
   $aref = $dbh->selectall_arrayref($sql, {Slice=>{}});

   my $g = new Data::Grouper(DATA=>$aref,SORTCOLS=>['CATEGORY','SUBCAT']);

   $t = HTML::Template->new(filename=>'../foobar.htmlt');
   $t->param(OUTER=>$g->get_data());
   print $t->output;
   
And the fragment from the HTML::Template code:

   <TMPL_LOOP NAME=OUTER>
        <h1>Style: <TMPL_VAR NAME=CATEGORY></h1>
      <TMPL_LOOP NAME=INNER>
        <h2>Color: <TMPL_VAR NAME=SUBCAT> </h2>
          <table>
          <TMPL_LOOP NAME=INNER>          
            <tr><td> <TMPL_VAR NAME=DESCR></td><td><TMPL_VAR NAME=PRICE></td></tr>
          </TMPL_LOOP>
          </table>
      </TMPL_LOOP>
      <tr><td>&nbsp</td><td><TMPL_VAR NAME=SUM_PRICE></td></tr>
   </TMPL_LOOP>

This might produce output like:

  Toys
    Nerf Toys
      Nerf Dart Gun                  20.00
      Nerf Footbal                   30.00

                                     50.00
  Video Games
    X Box
      Gothic Something or Other      10.00
    Playstation 2
      Gran Turismo 3 A-Spec          15.00
      Grand Theft Auto 3             10.00
      
                                     35.00
                                     
This is not my most inspired example ever.  Except for the PS2 bits.

=head1 DESCRIPTION


This is a helper object for the various templating modules
that exist.  A key feature of any templating system is
the ability to deal with loops of data, for example
rows in a table.  Most systems will deal with nested
looping.  Data::Grouper takes the work out of
prepaing the data structures for nested loops.

Grouper will help you the most if you are writing reports
that have multiple layers of grouping with aggregate  values
but also need to display the detail rows.  An SQL select statement will 
get you one or the other of these features, but not both at
the same time.  And you still have to construct your data
structure for HTML::Template.  Grouper does it all.

=head1 METHODS

=head2 new()

Most of the behavior of grouper is determined by the parameters
passed to the constructor.

=over 4

=item *

COLNAMES - define column names for use with TMPL_VAR

Tell grouper the column names.
These are used when creating the hashes for HTML:Template.  COLNAMES
should contain the names of the hash values in the order the values
will appear in the rows passed to add_row().
So for the following code:

   COLNAMES => [ 'RESP_DESC','DUTY_ID', 'DUTY_DESC']

The hashes in the output structure will have keys RESP_DESC, 
DUTY_ID, and DUTY_DESC.  This allows them to be used in 
<TMPL_VAR> directives.

If you are using add_hash or add_array with an array of hash
references, you may omit COLNAMES.  If COLNAMES is omitted,
the keys of the first incoming hash will become the contents
of COLNAMES.  Keep in mind that these are case sensitive.

=item * 

AGGREGATES - Columns for which totals should be computed

This parameter gets a reference to an array of column names
to compute aggregate functions on.  Aggregate functions are
the same as you would find in SQL: sum, avg, min, max.

At every level of grouping, aggregate values will be provided.

Aggregate values are automatically given names based on the 
aggregate function and the column name.  Specifically, one of 
SUM_, MIN_, MAX_, or AVG_ is prepended to the column name.

Top level aggregates are contained in a hash obtainable with the
get_top_aggregates() function.

=item * 

SORTCOLS - Columns to group on

This parameter is a reference to an array of column names to
sort on.  The number of <TMPL_LOOPS> in your template
will be equal to the number of column names you indicate here.

The rows passed to grouper MUST BE SORTED on the columns
indicated in SORT_COLS.

=item *

DATA - Array ref of hash or array refs

If you are using selectall_arrayref and not modifying the data before
sending it to grouper, you can reduce your grouper code to two calls
by using the DATA parameter in the grouper->new() constructor:

   my $g = new Data::Grouper(DATA=>$aref,SORTCOLS=>['STYLE','COLOR']);
   $g->get_data();
   
This will often be your best approach.

=item *

FORMAT - Formatting Functions

 my $cr = sub { sprintf "\$%.2f", shift; };
 my $g = new Data::Grouper( 
                  FORMAT=> { 'Count'=>$cr, 'SUM_Count'=>$cr }
                  );

This parameter is a reference to a hash from column names (as
specified in COLNAMES) to formatting functions.  A formatting
function takes one parameter and returns the formatted value
of that parameter.  Such a function might be used, for 
example, to format money values.

=back 4

=head2 add_array

The add_array function adds multiple rows into the grouper
in one function call.  It takes one parameter, an array
reference.  This array can contain either hash references
or array references.  

Add_array is especially useful with DBI.  DBI can return 
entire arrays with selectall_arrayref.  This
function lets you just pass an array ref in instead of doing
a while loop and calling add_row (or add_hash) for each row.

   $aref = $dbh->selectall_arrayref($sql);
   $grouper->add_array($aref);

Just like add_row, add_array expects that the data is sorted
on the columns that are specified in SORTCOLS.

=head2 add_row

This takes a list of scalar values, which should correspond to the
entries in COLNAMES, and puts it in the correct 
place in the data structure.  Data in the successive calls to 
add_row is expected to be sorted on the columns specified in
SORTCOLS.

One reason to use add_row over add_array is if some transformation
happens between retrieving the data and populating the data
structure.

=head2 add_hash

This function is the hash-equivalent to add_row (above).  Add_hash
takes one parameter, a hash reference, which contains one 
row of data.  For example:

  $href = { COLOR=>'Red', Size=>'13', Style=>'Running' };
  add_hash ($href);

This would add one row of data to the grouper.  To add multiple
rows, for example if you had an array of hash refs from DBI,
you would use add_array().

The hash is assumed to contain the keys from COLNAMES.  If COLNAMES was not 
specified, the keys from the first hash passed to this function are used.  
Grouper makes its own copy of the hash ref to avoid modifying any data
that is passed in.

=head2 add_details

Sometimes you will want to add some additional information
to a row or a parent.  This function helps you do that.

I'm not certain this function is useful and will stay.

=head2 get_data

This function returns the array refernces required for
the call to HTML::Template's param() function.

=head2 get_top_aggregates

This function returns a reference to a hash containing top level aggregates
for the data.  Top level aggregates are contained in their own separate
hash since aggregates are normally one level up in the data structure from
the array containing their rows, but in the case of the top level, it is
impossible to go up one level.

Some top level aggregates may be best computed outside of Data::Grouper.
For example, while Grouper could maintain a count of total rows, if 
you were using add_array this statistic is just the size of the array,
which is computed much more efficiently as $#array.

Right now G::D computes top level aggregates if any aggregates are being
computed.  In the future there may be an option to disable computation
of top level aggregates.  Actually, they should probably be disabled by
default.

=head1 More Examples


Suppose you have a table of book data with columns genre, title.  You might
have this data:

 Non-Fiction, Techincal, Effective Perl, 25
 Non-Fiction, Technical, The C Programming Language, 20
 Non-Fiction, Techincal, Lex & Yacc, 20
 Non-Fiction, Philosophy, Book of Five Rings, 13
 Non-Fiction, Philosophy, Against Method, 30
 Fiction, Sci-Fi, Lord of the Rings,25
 Fiction, Sci-Fi, Foundation,15
 Fiction, Literary, Gravity's Rainbow,15
 
Say you want to display these, grouped by genre.  You need to build

 @data = [
   { FICTION=> Non-Fiction,
     INNER => [
       { GENRE => Technical,
         INNER => [  { TITLE=>Effective Perl, PRICE=>25},
                     { TITLE=>The C Programming Language, PRICE=>20 },
                     { TITLE=>Lex&Yacc, PRICE=>20 }
                  ]
       },
       { GENRE => Philosophy,
         INNER => [ {TITLE=>Book of Five Rings, PRICE=>13 },
                    {TITLE=>Against Method, PRICE=>30 }
                  ]
       }
     ]
   },
   { FICTION=> Fiction,
     INNER => [  
       { GENRE=> Sci-Fi,
         INNER => [ { TITLE=>Lord of the Rings, PRICE=>25 },
                    { TITLE=>Foundation, PRICE=>15 }
                  ]
       },
       { GENRE=> Literary,
         INNER => [ { TITLE=>Gravity's Rainbow, PRICE=>15 } ]
       }     
   }
 ];

and apply it to template

 <TMPL_LOOP NAME=OUTER>
 <h2><TMPL_VAR NAME=GENRE></h2>
   <TMPL_LOOP NAME=INNER>
     <TMPL_VAR NAME=TITLE> <br>
   </TMPL_LOOP>
   Average Price: <TMPL_VAR NAME=AVG_PRICE>
 </TMPL_LOOP>

to get

 Non-Fiction
   Technical
     Effective Perl
     The C Programming Language
     Lex & Yacc
     Average Price: 21.6
   Philosophy
    Book of Five Rings
    Against Method
    Average Price: 21.5
 Fiction
   Sci-Fi
     Lord of the Rings
     Foundation
   Literary
     Gravity's Rainbow
     
     
If you are getting your data from a database, you might do this:

 $sql = 'select fiction, genre, title from books order by fiction, genre';
 $aref = $dbh->selectall_arrayref($sql);
 $grouper->add_array($aref);

Grouper creates the array of hash refs, containing array refs with hash
refs that H::T requires.


=head1 FAQs

=head2 How is this different than GROUP BY in SQL?

SQL's group by facility allows grouping at only one level and
does not provide the underlying detail data.  Grouper is used
to provide summary details at multiple levels while still providing
the underlying data, all in a format you can use with HTML::Template.

=head1 AUTHOR

David Ferrance (dave@ferrance.com)

=head1 LICENSE

Data::Grouper - A module for using aggregating data for use with various Template modules.

Copyright (C) 2001,2002 David Ferrance (dave@ferrance.com).  All Rights Reserved. 

This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself. 

=cut


