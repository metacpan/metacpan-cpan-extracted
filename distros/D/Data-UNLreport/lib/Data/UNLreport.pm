# This file contains package Data::UNLreport, along with a retinue of
# utility functions

#use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration:  use Data::UNLreport ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#
#our @EXPORT = qw( );

our $VERSION = '1.07';
our $ABSTRACT = 'Formats delimited column data into uniform column sizes';

# Patterns I will use to determine the data type of column data:
#
my $white = '\s+';      # White-space pattern (routine)
my $int_pattern = '^[-+]?\d+$';     # Integer pattern, optionally signed
my $dec_pattern = '^[-+]?\d+\.\d*$'; # Decimal Number pattern, signed (opt)
my $hex_pattern = '^[A-Fa-f0-9]+$'; # Hex number w/o the 0x prefix
my $zhx_pattern = '^0[xX][A-Fa-f0-9]+$'; # Hex number with 0x prefix

my $util;               # Will be a reference to _util object, to be
                        # used by both the UNLreport and UNLreport::Line
#
package Data::UNLreport;
  use overload
    '+'  => "UNL_add_line",
    '<<' => "UNL_add_parsed_line";

# Note: The methods for setting/retrieving the input and output
# delimiters are so identical, I can mimic code from Sam Tregar to
# create these methods by poking the symbol table.
#
BEGIN {
  # Temporarily turn off the 'strict' stricture for refs in this block
  # so that I can get away with Sam Tregar's little trick.
  #
  no strict 'refs';                 # As advised by Sam Tregar himself.
  my @attrs = qw(in_delim out_delim); # Create accessor-mutator 
                                      # methods named like attributes
  for my $attr (@attrs)
  {
    *$attr = sub  {
                    my $self = shift(@_);
                                # Use only first character of string
                    $self->{$attr} = substr((shift(@_)), 0, 1) if (@_);
                                # If specified b, it means blank
                    $self->{$attr} = ' ' if ($self->{$attr} eq 'b');
                    return $self->{$attr};
                  }
  }
}
$util = Data::UNLreport::_util->new();  # Create utility pseudo-object
                                        # before any UNLreport objects
                                        # are created.

sub new
{ # Create the object and parse the input/out delimiters as well
  #
  my $class = shift(@_);
  my $self = {};        # (Just a reference to an anonynmous hash)
  bless ($self, $class);

  # Some object initialization, with default values
  #
  $self->{in_delim}  = '|';     # Default delimiter for unl files
  $self->{out_delim} = '|';     # Reasonable for out to mimic in
  $self->{out_file} = "(STDOUT)";   # Default output file.
  $self->{fdesc}     = \*STDOUT; # Default output file descriptor.
  #$self->{in_split}  = '\|';    # Escape it, since | is a metacharacter
  $self->{n_lines} = 0;         # No lines parsed yet
  $self->{max_width}[0]    = 0; # Member arrays for column width
  $self->{max_decimals}[0] = 0; # comparisons.  THis is decimal places
  $self->{max_wholes}[0]   = 0; #  Whole parts of decimal numbers

  $self->{has_end_delim}   = 0; # Assume no delimiter at end of line
                                # Will likely revise this flag 
#
  # Now that the defaults have been set up, look at the parameters, if
  # any.
  #
  die "That is no hash!" if ( (@_ % 2) != 0);   # Odd count is BAD!

  my %params = @_;              # Copy paramater arry into private hash
                                # and start applying them.
  $self->in_delim($params{in_delim})
    if (defined ($params{in_delim}));
  $self->out_delim($params{out_delim})
    if (defined ($params{out_delim}));
  my $o_mode = defined ($params{mode}) ? $params{mode} : ">" ;
  $self->out_file($params{out_file}, $o_mode)
    if (defined ($params{out_file}));
  

  $self->{out_delim}  = $params{out_delim}
    if (defined ($params{out_delim}));

  return $self;                 # Setup all done.
}
#
# Methods for setting and retrieving some basic attrributes
# Methods in_delim() and out_delim() were already set up before new()
#
sub out_file
{
  my $self = shift(@_);

  # If output file name was given, use that; else, set a null string.
  # Note that a null string may have been sent. The code handles that
  # as well.
  #
  my $fpath = (@_) ? shift(@_) : "";    # File name: Given or wanted
  my $fmode = (@_) ? shift(@_) : ">";   # File mode: Given or default

  # Default output file name & descriptor are already set. Override?
  #
  if ($fpath)                   # If supplied the output file name
  {
    $self->{out_file} = $fpath; # Subject to change shortly

    open($self->{fdesc}, $fmode, $fpath)
      or die "Error <$!> trying to open <-$fpath-> in mode ($fmode)\n";
  }
  # If no name supplied - caller just wants the file name

  return $self->{out_file};
}

sub fdesc
{                               # No setting file descriptor!
  my $self = shift(@_);

  # If called prematurely, return 0 instread of the file descripter
  #
  return (defined($self->{fdesc}) ? $self->{fdesc} : 0);
}
#
# Method: UNLreport::has_end_delim()
# Sets or clears a flag to indicate if I want a terminating delimiter
# on each line, as befits a proper .unl file. Call with no parameter to
# just get the value of this flag.
#
# Parameters:
# - (Implicit) Ref to a UNLreort object (ie parsed file)
# - 1 for yes, 0 for no.  Omit to just get the value
#
sub has_end_delim
{
  my $self = shift(@_);
  $self->{has_end_delim} = shift(@_) if @_; # No param: Don't set
  return $self->{has_end_delim};
}
#-----------------------------------------------------------------------

# Method: chomp_delim() - Removes the delimiter character from the end
# of the input line, as many as appear there.
#
# Parameters:
# - (Implicit) Ref to a UNLreort object (ie parsed file)
# - The line itself, (Probably already chomped by the caller)
# Returns:
# - The same line, minus the delibiter(s) at the end of the line
#
sub chomp_delim
{
  my $self = shift(@_);
  my $rline = shift(@_);    # Get the line string
  chomp($rline);            #(Probably not necessary; just being thorough)

  # Plan: As long as we keep finding an input delimiter at the end of the
  # line (note the fairly ugly "while" condition), keep chopping it off
  #
  while (substr($rline, (length($rline) - 1), 1) eq $self->{in_delim})
  { chop($rline); }         #(Hey, there's still life in the chop function!)

  return($rline);
}
#-----------------------------------------------------------------------
#
# Method UNLreport::+ to add a raw line into the parsed-file list
#
sub UNL_add_line
{
  my $self     = shift(@_); # Ref to the UNLreport object
  my $one_line = shift(@_); # Get the actual line string to be appended
  $one_line = $self->chomp_delim($one_line);    # Lose trailing delimiters
  
  # Parse the line and calculate basic info about it.
  #
  my $p_line = Data::UNLreport::Line->new($one_line, $self);

  my $ok = $self << $p_line;     # Integrate parsed line to line list

  $self->{n_lines}++;   # Tally up line count
  return $self->{n_lines};
}
#
#-----------------------------------------------------------------------
# Method UNLreport::<< to add a parsed line into the parsed file list
# Parameters:
# o (Implicit) reference to the UNLreport file object
# o Reference to a parsed line object
#
sub UNL_add_parsed_line
{
  my ($self, $pline) = @_;
  my $cur_line = $self->{n_lines};  # Slot number to get the line
  my $n_cols = $pline->ncolumns();  # Column count for looping
  $self->{parsed_line}[$cur_line] = $pline; # Store line reference
                                            # Line is now integrated

  if ($pline->{has_delims})
  { $self->check_col_widths($cur_line); }
  # If no delimiter, I don't give a hoot about column width.

  return 1;         # Return success code
}
#
# Method: check_col_widths()
# For an already parsed line, run down trhe columns to set the width of
# the widest value in that column for whole file.
#
# Parameters:
# o (Implicit) Reference to the parsed file object
# o Row (or line) number
#
sub check_col_widths
{
  my ($pfile, $row) = @_;   # (Using $pfile instead of $self. Why?)

  # For each column, compare its width against the widest so far.
  # Similar check for decimal places if it has decimal places
  #
  my $col_wid   = 0;    # Column width
  my $col_whole = 0;    # Width of integer or integer part of a decimal
  my $col_dec   = 0;    # Width of decimal part of a float
  my $row_ref = $pfile->{parsed_line}[$row];    # Neater access to cols
   
  # For cleaner access to columns of the line, use this reference:
  #
  my $split_ref = $row_ref->{split_line};

  for (my $lc = 0; $lc < $row_ref->{columns}; $lc++)
  { # First make sure there is a column width to compare;
    # If not, start it with a zero width.
    #
    if (! defined($pfile->{max_width}[$lc]))
      { $pfile->{max_width}[$lc] = 0; }
    if (! defined($pfile->{max_wholes}[$lc]))
      { $pfile->{max_wholes}[$lc] = 0; }
    if (! defined($pfile->{max_decimals}[$lc]))
      { $pfile->{max_decimals}[$lc] = 0; }

    # Check for widest column. This is counted different ways for
    # string, integer and decimal.  Start by checking integer pattern
    #
    if ($split_ref->[$lc] =~ $int_pattern)
    {
      if ( ($col_wid = length($split_ref->[$lc]))
                     > $pfile->{max_width}[$lc])
      { # We have a new largest width for this column
        # as wll as a widest whole-number part for this column
        #
        $pfile->{max_width}[$lc]  = $col_wid;   # New widest width
        $pfile->{max_wholes}[$lc] = $col_wid;   # Widest whole number
      }
    }
#
    # Check for decimal/float pattern
    #
    elsif ($split_ref->[$lc] =~ $dec_pattern)
    { # If decimal, check for most decimal places and whole numbers
      #
      my ($whole_part, $decimal_part) = (0, 0);
      ($whole_part, $decimal_part) = split('\.', $split_ref->[$lc]);

      # If there is a + sign in there, it will not print with the
      # printf call but its presence my skew the column width, if it
      # happens to be the widest column alredy.  we want to lose it so
      # that the + does not get counted into the length.
      #
      if (substr($whole_part, 0, 1) eq '+') { $whole_part =~ s/^\+// ;}
      if ( ($col_whole = length($whole_part))
                       > $pfile->{max_wholes}[$lc])
      { $pfile->{max_wholes}[$lc] = $col_whole; }   # New widest whole

      if ( ( $col_dec = length($decimal_part))
                      > $pfile->{max_decimals}[$lc])
      {  $pfile->{max_decimals}[$lc] = $col_dec;}   # New widest decimal

      # Width of widest decimal, so far, is:
      # width of widest whole part
      # + width of widest decimal part
      # + 1 for the decimal point.
      # (Note: I am calculating and using $col_wid differently from the way
      # I use it for string and integer data.)
      #
      $col_wid = $pfile->{max_wholes}[$lc]
               + $pfile->{max_decimals}[$lc]
               + 1;  # What is total width of these maxima?
      if ($col_wid > $pfile->{max_width}[$lc])
      { $pfile->{max_width}[$lc] = $col_wid; }
    }
    else
    { # Neither decimal nor integer be: Must be a string
      # Much simpler width calculation - Just one simple comparison
      #
      if ( ($col_wid = length($split_ref->[$lc]))
                     > $pfile->{max_width}[$lc])
      { $pfile->{max_width}[$lc] = $col_wid; } # New widest this column
    }
  
  }
}
#
# Method print() - Print the beautified output
# Implicit parameter: [Reference to] the completely parsed file
sub print
{
  my $self = shift;
  my $lc;           # My usual loop counter

  for ($lc = 0; $lc < $self->{n_lines}; $lc++)
  {
    my $out_buf = "";                   # Buffer for output line
    my $col_buf = "";                   # Buffer to format 1 column
    my $cur_col;                        # Current column number within line
    my $cur_p_line = $self->{parsed_line}[$lc]; # ->Line object
    my $split_ref = $cur_p_line->{split_line};  # -> Array of cols
    if (! $cur_p_line->{has_delims})    # If line has no delimiters
    {
      #printf($self->{fdesc} "%s\n", $split_ref->[0]);
      $split_ref->[0] =~ s/\s+$//;      # Trim trailing white-spaces
      printf {$self->{fdesc}} ("%s\n", $split_ref->[0]);
                                        # Just print the line as is
      next;                             # and go the next parsed line
    }
    # Still here: then line has delimiters (majority of cases)
    #
    for ($cur_col = 0; $cur_col < $cur_p_line->{columns}; $cur_col++)
    {  # One column per round in this loop
      if ($cur_p_line->{type}[$cur_col] eq "s")
      {
        $col_buf = sprintf ("%-*s%s",
                            $self->{max_width}[$cur_col],
                            $split_ref->[$cur_col],
                            $self->{out_delim});
        $out_buf .= $col_buf;           # Concatenate column to line
      }
      else
      { # Else, it is a numeric type - either d or f. I won't even look
        # at that but at the widest column and most decimal places
        #
        if ($self->{max_decimals}[$cur_col] == 0)
        { # No row had any decimal places in this column.  Format
          # intger at widest width with [default] right justification
          #
          #printf($self->{fdesc} "%*d%s",
          $col_buf = sprintf ("%*d%s",
                              $self->{max_width}[$cur_col],
                              $split_ref->[$cur_col],
                              $self->{out_delim});
        }
        else
        { # If even 1 row had decimal places in this column, format
          # this column accordingly for all rows.
          #
          #printf("%*.*f%s",
          $col_buf = sprintf ("%*.*f%s",
                              $self->{max_width}[$cur_col],
                              $self->{max_decimals}[$cur_col],
                              $split_ref->[$cur_col],
                              $self->{out_delim});
        }
        $out_buf .= $col_buf;           # Concatenate column to line
      }
    }   # End loop for one row

    # Above loop filled an output line.  Now trim it off (just in case)
    # and print it.
    #
    $out_buf =~ s/\s+$//;      # Trim trailing white-spaces
    printf {$self->{fdesc}} ("%s\n", $out_buf);
  } # End loop for whole set of parsed lines
}   # End method print()
#
# package UNLreport::Line:
# "Private" class used by class UNLreport.  That class operates on
# a whole report.  UNLreport::Line operates on a single line structure.
#
package Data::UNLreport::Line;

# Constructor for 1 line-object.  Parameters:
# - The class (implicit)
# - The line (scalar) OR a reference to an array of scalars.
#   The scalar is more likely to be passed if the client is working
#   with ..unl data; the array reference is more likely if client is
#   fetching database data an passing it to this method.
# - A reference to the UNLreport object to which this line belongs
#
sub new
{
  my $class  = shift(@_);   # (Implicitly passed class name)
  my $one_line =  shift(@_);
  my $p_file = shift(@_);   # The UNLreport object reference
  my $self = {};            # Create new object
  bless ($self, $class);    # of this class
  $self->{split_line}[0] = "";  # Just to establish this field as array

  #my ($in_delim, $in_split) # Just get local copies of delimiters
  #  = ($p_file->{in_delim}, $p_file->{in_split});
  my $in_delim = $p_file->{in_delim}; # Just get local copy of in-delimiter
  $in_delim = qr/\|/ if ($in_delim eq "|");     # Avoid confusion cause by
                                                # this special character

  if (($in_delim eq 'b') || ($in_delim eq ' ')) # If input delimiter is
  {                                             # white space, use this
    $in_delim = qr/\s+/;                        # white-space pattern
  }
  if (ref($one_line) eq "ARRAY")    # If I received an array reference
  {                                 # copy the array into line object
    @{$self->{split_line}} = @{$one_line};          #  and set the
    $self->{columns} = @{$self->{split_line}};      # column count
    $self->{has_delims} = 1;        # Already separated - as good as
                                    # delimited.
  }
  else                      # Assume I got a scalar - a line
  {                         # More work: Split, check, repair, etc..
    chomp($one_line);
    $one_line =~ s/^\s+//;  # Trim leading spaces
    $one_line =~ s/\s+$//;  # Trim trailing spaces
    
    # If line has no delimiters, it is a blob-dump line, not to be
    # counted like a reguler UNL line.
    #
    $self->{has_delims} = 0;        # Initially assume line had no
    if ($one_line =~ $in_delim)     # delims, but if I find one,
      {$self->{has_delims} = 1;}    # correct the assumption ASAP
  
    if ($self->{has_delims})
    {
      # Split the line but keep trailing null fields.
      #
      @{$self->{split_line}} = split($in_delim, $one_line, -1);
      $util->repair_esc_delims(\@{$self->{split_line}}, $in_delim);
                                    # That is, undo overzealous splits
 # 
      # Now, is there a trailing delimiter in the original line? In a
      # .unl file, that is the last character of the line; there is no
      # field past that.  However, the split() function does not know
      # that and creates a bogus, null last field. I need to drop that
      # myself.
      # Also, if even one line has a final delimiter, flag whole file to
      # making sure there is one on every output line.
      #
      if (substr($one_line, (length($one_line) -1)) eq $in_delim)
      {
        $p_file->{has_end_delim} = 1;   # OK if this is set repeatedly
        pop @{$self->{split_line}};     # Lose the bogus last element
      }
      $self->{columns} = @{$self->{split_line}};    # Column count
    }
    else  # If line has no delimiters
    {
      $self->{split_line}[0] = $one_line;   # Copy the line unparsed
      $self->{columns} = 1;                 # Exactly 1 column
    }  
  } # End of line-splitting code

  # Regardless of whether I got the split record or had to split it
  # myself, tidy up fields by trimming leading & trailing spaces
  # Then track the size & formats of each field
  #
  for (my $nfield = 0;
       $nfield <= $#{$self->{split_line}};
       $nfield++)
  { 
    #$self->{split_line}[$nfield] =~ s/^\s+//;    # Trim leading #(No, dont)
    $self->{split_line}[$nfield] =~ s/\s+$//;    # Trim trailing

    # Now for the data types:
    # %d for integer
    # %f for decimal (float)
    # %s for anything else
    #
    if    ($self->{split_line}[$nfield] =~ $int_pattern)
      { $self->{type}[$nfield] = "d";}
    elsif ($self->{split_line}[$nfield] =~ $dec_pattern)
      { $self->{type}[$nfield] = "f"; }
    else
      {$self->{type}[$nfield] = "s";}

  }
  return $self;
}
#
sub ncolumns { my $self = shift(@_); return $self->{columns}; }

#
package Data::UNLreport::_util;

# Token constructor so that functions can be called like methods
#
sub new {my $self = {}; bless($self, $_[0]) ; return $self; }

# matches_meta(): Function to test if the given delimiter character is
#                 a known metacharacter.
# Returns 1 if it does match, 0 if it does not.
#
sub matches_meta
{
  shift(@_);                    # Don't need object reference; lose it
  my $delim_char = shift(@_);   # Get the parameter into a private var

  my $rval = 0;                 # Return value - Assume not a meta

  my $metachars = '|()[]{}^$*+?.';  # This is the list of metacharacters

  my $meta_length = length($metachars); # Loop limit

  for (my $lc = 0; $lc < $meta_length; $lc++)
  {
    if ($delim_char eq substr($metachars, $lc, 1)) {$rval = 1; last;}
  }

  return $rval;
}
#
# repair_esc_delims() - Scan up the array to look for columns that end
#   with an escape cahracter (\); this indicates that a delimiter was
#   intended to be part fo the scring and we hsould not have split it
#   up there.  We need to put back the delimiter and recombine the
#   split column with the following column.  The last column, the first
#   one I will check, cannot be recombined, of course.
#
# Parameters: (for now)
# - An array reference.
# - The delimiter to put back. 
#
sub repair_esc_delims
{
  shift(@_);                    # Don't need object reference; lose it
  my ($listref, $delim_p) = @_;

  for (my $lc = $#{$listref}; $lc >= 0; $lc--)
  {
    my $col_copy = $listref->[$lc]; # Copy to make code more readable
    my $col_length = length($col_copy) -1;  # O, length off by 1..

    # If column does not end in escape character(s), fuggeddaboudit!
    #
    next if ($col_copy !~ m/\\+$/);

    # AHA! Column does end in an escape. It may have been escaping a
    # delimiter in the original line.  Or it may itself be an escaped
    # escape.  How can I tell?  An odd number of \ clusters at end of
    # colum indicate an escape delimiter, requiring repair.  An even
    # number indicates escaped escape character.  Not my jurisdicion.
    #
    my $esc_count = $util->count_escapes($col_copy);
    next if (($esc_count % 2) == 0);    # Even number of esc; no problem

    # Odd number of escapes - need to effect repair of improper split.
    # o Put back the wrongly removed delimiter
    # o If this is not the last column in the array, append the succee-
    #   ding column to this one while splicing that succeeding column
    #   from the array.
    #
    $listref->[$lc] .= $delim_p;    # Putting back the delimiter
    if ($lc < $#{$listref})         # Cant splice after last element
    {
      $listref->[$lc] .=  splice(@{$listref}, $lc+1, 1);
    }
  } # End FOR (my $lc = $#{$listref}; $lc >= 0; $lc--)
}
#
# Function count_escapes: Counts contiguous escape characters at the
# end of the given string.
#
# Parameter:
# o The string
#
# Returns:
# o The number of consecutive escapes at end.
#
sub count_escapes
{
  shift(@_);                    # Don't need object reference; lose it
  my $instr = shift @_;

  my $len = length($instr) -1;
  my $lc = $len;        # Loop counter to start high, work down
  my $count = 0;        # Good place for a counter to start

  while (substr($instr, $lc--, 1) eq "\\") {($count++);}

  return $count;
}
#


1;
__END__

=pod

=head1 NAME

Data::UNLreport

=head1 ABSTRACT

Formats column-oriented data into uniform column sizes

=head1 SYNOPSIS

The UNLreport provides the following methods:

  use Data::UNLreport;
  my $report = Data::UNLreport->new ([in_delim  => '|'],
                                     [out_delim => '|'],
                                     [out_file  => "<file path>"]
                                     [mode      => ">" | ">>" ]
                                    );
  The defaults will be familiar enough to the Informix user:

=over 4

=item * in_delim defaults to the vertical bar ("pipe").

=item * out_delim defaults the same way.

=item * Output file defailts to STDOUT, which is ill advised if parsing
multiple files.

=item * Mode defaults to > - to overwrite the target file.

=back

  $report->in_delim([char]);    # Sets/returns input column separator

  $report->out_delim([char]);   # Sets/returns output column separator

  $report->out_file([file_path, [mode]] );  # Sets/returns output file
                                # Also sets the output mode - Overwrite
                                # or append

  $report->fdesc();             # Returns reference to file descriptor

  $report->has_end_delim(flag); # 1 for delimiter at end of each line,
                                # 0 to omit end-of-line delimiter
                                # Default: 0
  $lines_so_far = $report + $a_line; # Splits and adds this line to the
                                     # UNLreport object.
  $lines_so_far = $report + @values;# Adds this array - a line already
                                     # split - to the UNLreport object.
                                     # NOTE: Pass an array REFERENCE
                                     # Returns line tally so far.
  $report->print();             # Sends the data to the output file,
                                # with columns uniformly sized

=head1 DESCRIPTION

A detailed description of the module and methods follows.

All parameters to new() are optional.  They can be completely omitted
or set later.

The default value for in_delim is the vertical bar (AKA pipe), the
standard delimiter for files created with the Informix-SQL "unload"
command. You may substitute any other character eg. comma, colon,
period etc.  If you wish to specify a blank separator, use the
lower-case letter 'b' as your parameter.  Other than that b, we
obviously do not recommend using an alphanumeric character as a field
delimiter.  There is [currently] no method for specifying a pattern.

The default value for out_delim is copied from in_delim, whether using
the default in_delim or set in the new() method.  Or you can set it
using the out_delim() method. As with in_delim, do not use an alphanumeric
delimiter if you want your output to be readable. Also, the letter b will
be interpreted as a space (blank)

For methods in_delim(), out_delim(), and out_file(), supplying a
parameter sets the indicated attribute; omitting it returns the value
(Ye Olde accessor-mutator) of that attribute.  Thus, you can omit the
delimter parametes from the new() method and set them later.

Note that you can dynamically change the input column separator.  If
your data input is from different sources that use different column
separators e.g. one comma-separated file and one colon-separated file, you
can switch how the UNLreport object splits the line to follow the change.

On the other hand, the assumption is that all output is to be delimited
the same way.  Similarly, all output [from one UNLreport object] is targeted
to the same output file. The UNLreport object does not really care about the
output column separator or the output file until it is ready to generate the
output.  Hence, it is permissible but futile to call out_delim() (or
out_file()) to set these attributes more than once; only the final call
before output will have the intended effect, overwriting the work of any
previous call.

The default output file is, of course, STDOUT.  You can specify a path
here.  The default mode is '>' - to write the output as a new file,
overwriting any existing file by name name.  If that is not your
intention, use
  mode => ">>"
to append to an existing file.

You send a line to the report by using the overloaded + operator. You
may send it a line with the delimiters intact - as from an UNLOAD
command.  Or you can send it a REFERENCE to an array, as you would have
if you are doing SQL-FETCH commmands and want a neat report on the data.

=head1 EXPORT

No functions or variables are exported from this module at this time.

=head1 HISTORY

Original version; created by h2xs release 1.23 with options:
  -XAC
    -n
    UNLreport

=head1 BACKGROUND

This module is the next stage of a script that started life as a shell
script, beautify-unl.sh.  Its purpose was to straighten out the zig-zag
columns produces by the Informix SQL command UNLOAD.  Hence, the
default columns separator is the | character, both for splitting the
input columns as well as formatting the output lines. The first Perl
attempt was UNLreport.pm, which works was not CPAN-worthy.


=head1 SEE ALSO

The original shell script, which still works very well, can be found at
this URL:
http://www.iiug.org/software/archive/beautify-unl.shar

You may need to be a member of the IIUG to download this.

=head1 AUTHOR

Jacob Salomon, jakesalomon@yahoo.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jacob Salomon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
