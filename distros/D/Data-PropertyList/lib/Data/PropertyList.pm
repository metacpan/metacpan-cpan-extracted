### Data::PropertyList - Convert arbitrary objects to/from strings.

### Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 1998-12-17 Minor doc cleanup; added makefile and tests for distribution.
  # 1998-10-05 Tweaked output spacing for single-line string arrays.
  # 1998-10-05 Switched from use of String::Escape::add to direct hash access.
  # 1998-07-23 Conventionalized POD, switched to yyyy.mm_dd version numbering.
  # 1998-08-23 On further consideration, this really did belong in Data::*.
  # 1998-06-11 Improved support for <<HERE strings.
  # 1998-05-07 Fixed problem with reading "0 = ..." lines in hashes.
  # 1998-03-03 Replaced $r->class with ref($r) -Simon
  # 1998-02-28 Initialized _parse_multiline $value to '' to run clean under -w.
  # 1998-02-25 Version 1.00 - String::PropertyList
  # 1998-02-25 Moved to String:: and @EXPORT_OK for CPAN distribution - jeremy
  # 1998-01-28 Fixed variable name typo in _parse_array.
  # 1998-01-11 Added rudimentary support for comments: full-line comments only
  # 1998-01-02 Renamed package Data::PropertyList to Text::PropertyList -Simon
  # 1997-12-08 Removed package Data::Types, use UNIVERSAL::isa instead. -Piglet
  # 1997-11-19 Added loopback handling to astext; now Supress as XREF TO 
  # 1997-10-28 Updated to use new Text::Escape interface.
  # 1997-10-21 Documentation cleanup.
  # 1997-08-17 Moved string escape/unescape code into new Text::Escape. -Simon
  # 1997-01-2? New fromDictionary parser -Eric
  # 1997-01-14 New asDictionary function provides closer match to NeXT style.
  # 1997-01-11 Cloned & cleaned for Inetics; moved I/O to file.pm. V3.0 -Simon
  # 1996-10-29 Added append flag and trailing \n to write. -Piglet
  # 1996-08-06 Partial fix for blessed data; treat as basic type. V2.05 -Simon
  # 1996-07-13 Cleaned up flow, fixed headers.
  # 1996-06-25 Wrote &write. V2.04 -EJ
  # 1996-06-23 Converted from Perl 4 library to Perl 5 package. V2.03
  # 1996-06-18 Iterative line parsing replaces raw recursion. V2.02
  # 1996-06-15 Clean start with support for nested data structures. V2.01
  # 1996-05-26 Support for =<< multiline values.
  # 1996-05-08 Parse key-value pairs into a flat hash. Version 1. -Simon

package Data::PropertyList;

require 5.003;
use strict;

use vars qw( $VERSION @ISA @EXPORT_OK );
$VERSION = 1998.12_17;

use Exporter;
push @ISA, qw( Exporter );
push @EXPORT_OK, qw( astext fromtext );

use vars qw( $Separator );
$Separator = '.';

use String::Escape qw( qprintable unprintable );
$String::Escape::Escapes{'astext'} = \&astext;
$String::Escape::Escapes{'fromtext'} = \&fromtext;

### Writer

use vars qw( %DRefs %Supress $CurrentDRef $CurrentDepth );
use vars qw( $Indent $ShowClasses $ShowDRefs $Multiline $MaxItems );

# $string = astext($value_or_reference);
# $string = astext($value_or_reference, %options);
  # Write out an object graph in NeXT property list format 
  # Numerous variables are localized, then we recurse.
sub astext {
  my $target = shift;
  my %options = @_;

  # Options
  local $CurrentDRef = '';  
  local $CurrentDepth = 0;  
  
  local $Indent = 2;
  
  local $ShowClasses = $options{'-classes'} if (exists $options{'-classes'} );  
  local $ShowDRefs = $options{'-drefs'}     if (exists $options{'-drefs'} );  
  local $Multiline = $options{'-multiline'} if (exists $options{'-multiline'});  
  local $MaxItems = $options{'-maxitems'} if (exists $options{'-maxitems'});  
  
  # Working scope for this invokation of astext.
  local %DRefs = ();
  local %Supress = ();
  
  _astext( $target )
}

# $string = _astext($referenceorvalue);
sub _astext {
  my $target = shift;
  
  # Write out an "UNDEFINED" comment to signal undefined values;
  return '/* UNDEFINED */' if (not defined $target);
  
  # Write out escaped version of non-reference (string or number) values.
  if ( ! ref($target) ) {
    if ( $Multiline and $target =~ /\n.*?\n/ ) { 
      return "<<END_OF_TEXT_DELIMITER\n" . 
	     $target . ($target =~ /\n\Z/ ?'':"\n") . 
	     "  END_OF_TEXT_DELIMITER";
    } else {
      return qprintable( $target );
    }
  }
  
  # If this is a reference an item written out elsewhere, write an XREF comment
  return '/* CROSS-REFERENCE TO ' . 
  	( length($DRefs{$target}) ? $DRefs{$target} : 'ROOT' ) .' */'
		      if ( exists $DRefs{$target} and $Supress{$target} );
  
  # Store a relative DRef from the root to here, if we haven't already
  $DRefs{$target} = $CurrentDRef if ( not exists $DRefs{$target});
  
  # We're going to show this item, so don't show it again in the future
  $Supress{$target} ++ ;
  
  # Variable to hold the stringified form of $target.
  my $result = '';
  
  # Write out DRef if $ShowDRefs is set
  $result .= "/* DREF $CurrentDRef */ "
				      if ($ShowDRefs and length $CurrentDRef);
  
  # Any DRefs after this point are separated by dots.
  local $CurrentDRef = $CurrentDRef . $Separator if ( length $CurrentDRef );
  
  # Write out class of item if it's blessed and $ShowClasses is set
  $result .= "/* CLASS " . ref($target) . " */ " if ($ShowClasses and 
      ref($target) and (ref($target) !~ /\A(ARRAY|HASH|SCALAR|REF|CODE)\Z/));
  
  if ( UNIVERSAL::isa($target, 'HASH') ) {
    my $key;
    foreach $key (sort keys %{$target}) {
      my $value = $target->{$key};
      next unless (ref $value);
      $DRefs{$value} = $CurrentDRef . $key unless ( exists $DRefs{$value} );
      $Supress{$value} ++;
    }
    $result .=  "{" if ($CurrentDepth);
    $result .= "\n" if ($result); 
    $CurrentDepth ++;
    foreach $key (sort keys %{$target}) {
      $result .= ' ' x ( ($CurrentDepth - 1) * $Indent);
      local $CurrentDRef = $CurrentDRef . $key;
      $Supress{$target->{$key}} -- if ( ref $target->{$key} );
      $result .= _astext($key) . ' = ' . _astext($target->{$key}) .";\n";
    }
    $CurrentDepth --;
    $result .= ' 'x(($CurrentDepth-1) * $Indent) . "}" if ($CurrentDepth);
    return $result;
  } 
  
  elsif ( UNIVERSAL::isa($target, 'ARRAY') ) {
    my $key;
    # If $MaxItems is set and there are fewer than that many non-ref items
    my $one_line = ( $MaxItems and $#{$target} <= $MaxItems );
    foreach $key (0 .. $#{$target}) {
      my $value = $target->[$key];
      next unless (ref $value);
      $one_line = 0;
      $DRefs{$value} = $CurrentDRef . $key unless ( exists $DRefs{$value} );
      $Supress{$value} ++;
    }
    my $joiner = ( $one_line ) ? " " : "\n";
    $result .=  "(" if ( $CurrentDepth );
    $result .= $joiner if ( $result ); 
    $CurrentDepth ++;
    foreach $key (0 .. $#{$target}) {
      $result .= $one_line ? '' : ' ' x ( ($CurrentDepth - 1) * $Indent);
      local $CurrentDRef = $CurrentDRef . $key;
      $Supress{$target->[$key]} -- if ( ref $target->[$key] );
      $result .= _astext($target->[$key]) . "," . $joiner;
    }
    $CurrentDepth --;
    $result .= ( ! $one_line ? ' 'x(($CurrentDepth-1) * $Indent) : '' ) . ")"
    						 if ( $CurrentDepth );
    return $result;
  }
  
  elsif (UNIVERSAL::isa($target, 'REF') or UNIVERSAL::isa($target, 'SCALAR')) {
    $result .= '/* REFERENCE */ ';
    local $CurrentDepth = $CurrentDepth + 1;
    local $CurrentDRef = $CurrentDRef . 0;
    $result .= _astext($$target);
    return $result;
  }
  
  # Otherwise it's some unsupported kind of reference; just "" stringify it
  return "/* REFERENCE TO $target */";
}

### Reader

use vars qw( @TextLines $LineNumber $Source );

# $datastructure = fromtext($string);
# $datastructure = fromtext($string, %options);
  # reconstruct an object graph from a NeXT property list.
sub fromtext ($%) {
  my $dictionary_text = shift;
  my %options = @_;
  
  local @TextLines = split("\n", $dictionary_text);
  local $LineNumber = 0;
  local $Source = $options{'-source'} || '';
  
  if ( $options{'-scalar'} ) {
    return _parse_value( _get_line() . "\000", "\000" );
  } elsif ( $options{'-array'} ) {
    return _parse_array();
  } else {
    return _parse_hash();
  }
}

# _parse_error( $message );
sub _parse_error {
  my $message = shift;
  warn 'PropertyList error, ' . $message . 
      ' at line ' . $LineNumber . ( $Source ? ' in ' . $Source : '' ) ."\n";
}

# $text = _get_line;
sub _get_line {
  $LineNumber++;
  shift(@TextLines);
}

# $hash_ref = _parse_hash();
sub _parse_hash {
  my $hash = {};
  my ($key, $value, $current_line);
  
  while (@TextLines) {
    $current_line = _get_line();
    
    # Ignore comments
    $current_line =~ s#\Q/*\E.*?\Q*/\E##g;
    
    # Ignore blank lines
    next if ( $current_line =~ /^\s*$/ );
    
    # If we hit a closing brace, we're done with this hash
    last if ( $current_line =~ /^\s*\}[,;]/o ); 
    
    # Extract key and equals sign.
    if ( $current_line =~ s/^\s*\"(([^\"\\]|\\.)+)\"//o ) {
      $key = unprintable( $1 );
    } elsif ( $current_line =~ s/^\s*(\S+)//o ) {
      $key = unprintable( $1 );
    } else {
      _parse_error("Key not found");
      last;
    }
    
    $current_line =~ s/^\s*=\s*//o or _parse_error("= not found");
    
    # Extract value
    $value = _parse_value( $current_line, ';' );
    
    next unless (defined $key);
    
    $hash->{$key} = $value;
  }
  
  return $hash;
}

# $array_ref = _parse_array();
sub _parse_array {
  my $array = [];
  my ($value, $current_line);
  
  while (@TextLines) {
    $current_line = _get_line();
    
    # Ignore comments
    $current_line =~ s#\Q/*\E.*?\Q*/\E##g;
    
    # Ignore blank lines
    next if ( $current_line =~ /^\s*$/ );
    
    # If we hit a closing paren, we're done with this hash
    last if ( $current_line =~ /^\s*\)[,;]/o );
    
    # Extract value
    $value = _parse_value( $current_line, ',' );
    
    push( @$array, $value);
    
    next;
  }
  
  return $array;
}

# $string = _parse_multiline($ender);
sub _parse_multiline {
  my $ender = shift;
  
  my $value = '';
  my $current_line;
  
  while (@TextLines) {
    $current_line = _get_line();
    last if ($current_line =~ /^\s*\Q$ender\E[\;\,]?\s*$/);
    $value .= $current_line . "\n";
  }
  return $value;
}

# $value = _parse_value( $value, $terminator );
  # Extracts a quoted or unquoted string, an array, hash, or a multiline string
sub _parse_value {
  my $current_line = shift;
  my $end_value = shift;
  
  if ( $current_line =~ /^\s*\"(([^\"\\]|\\.)*)\"\Q$end_value\E\s*/ ) {
    # Extract quoted value
    return unprintable( $1 );
  } elsif ( $current_line =~ /^\s*(\S+?)\Q$end_value\E\s*/ ) {
    # Extract unquoted value
    return unprintable( $1 );
  } elsif ( $current_line =~ /^\s*(\/\*.*?\*\/)\s*\Q$end_value\E\s*/ ) {
    # Extract comment
    return undef;
  } elsif ( $current_line =~ /^\s*\{/o ) {
    return _parse_hash();
  } elsif ( $current_line =~ /^\s*\(/o ) {
    return _parse_array();
  } elsif ( $current_line =~ /^\s*\<\<(\w+)(?:\Q$end_value\E)?/o ) {
    return _parse_multiline($1);
  } else {
    _parse_error("value not found in '$current_line' - $end_value");
  }
}

1;

__END__

=head1 NAME

Data::PropertyList - Convert arbitrary objects to/from strings

=head1 SYNOPSIS

  use Data::PropertyList qw(astext fromtext);
  
  $hash_ref = { 'items' => [ 7 .. 11 ], 'key' => 'value' };
  $string = astext($hash_ref);
  # ...
  $hash_ref = fromtext($string);
  print $hash_ref->{'items'}[0];
  
  $array_ref = [ 1, { 'key' => 'value' }, 'Omega' ];
  $string = astext($array_ref);
  # ...
  $array_ref = fromtext($string, '-array'=>1 );
  print $array_ref->[1]{'key'};

=head1 DESCRIPTION

Data::Propertylist provides functions that turn data structures with nested references into NeXT's Property List text format and back again. 

You may find this useful for saving and loading application information in text files, or perhaps for generating error messages while debugging.

=over 4 

=item astext( $reference ) : $propertylist_string;

Writes out a nested Perl data structure in NeXT property list format.

=item fromtext( $propertylist_string ) : $hash_ref

=item fromtext( $propertylist_string, '-array'=>1 ) : $array_ref

Reconstructs a Perl data structure of nested references and scalars from a NeXT property list. Use the -array flag if the string encodes an array rather than a hash.

=back

=head2 The Property List Format

I<The below is excerpted from a draft of the NeXT PropertyList(5) man page:>

A property list organizes data into named values and lists
of values.  Property lists are used by the NEXTSTEP user
defaults system (among other things).  

In simple terms, a property list contains strings, binary
data, arrays of items, and dictionaries.  These four kinds
of items can be combined in various ways, as described
below.

A string is enclosed in double quotation marks; for example,
"This is a string." (The period is included in this string.)
The quotation marks can be omitted if the string is composed
strictly of alphanumeric characters and contains no white
space (numbers are handled as strings in property lists). 
Though the property list format uses ASCII for strings, note
that NEXTSTEP uses Unicode.  You may see strings containing
unreadable sequences of ASCII characters; these are used to
represent Unicode characters.  

Binary data is enclosed in angle brackets and encoded in
hexadecimal ASCII; for example, <0fbd777 1c2735ae>.  Spaces
are ignored.

An array is enclosed in parentheses, with the elements
separated by commas; for example, ("San Francisco", "New
York", "London").  The items don't all have to be of the
same type (for example, all strings) - but they normally
should be.  Arrays can contain strings, binary data, other
arrays, or dictionaries.

A dictionary is enclosed in curly braces, and contains a
list of keys with their values.  Each key-value pair ends
with a semicolon.  Here's a sample dictionary: { user =
maryg; "error string" = "core dump"; code = <fead0007>; }.
(Note the omission of quotation marks for single-word
alphanumeric strings.) Values don't all have to be the same
type, since their types are usually defined by whatever pro-
gram uses them (in this example, the program using the dic-
tionary knows that user is a string and code is binary
data).  Dictionaries can contain strings, binary data,
arrays, and other dictionaries.

Below is a sample of a more complex property list, taken
from a user's defaults system (see defaults(1)).  The pro-
perty list itself is a dictionary with keys "Clock,"
"NSGlobalDomain," and so on; each value is also a diction-
ary, which contains the individual defaults.

    {
	Clock = {ClockStyle = 3; };
	NSGlobalDomain = {24HourClock = Yes; Language = English; };
	NeXT1 = {Keymap = /NextLibrary/Keyboards/NeXTUSA; };
	Viewer = {NSBrowserColumnWidth = 145; "NSWindow Frame 
    Preferences" = "5 197 395 309 "; };
	Workspace = {SelectedTabIndex = 0; WindowOrigin = "-75.000000"; };
	pbs = {};
    }

I<Please note that the above documentation is incomplete, and that the current implementation does not support all of the features discussed above.>

=head1 EXAMPLE

Here's an example of a PropertyList-encoded data structure:

  my $produce_info = {
    'red' =>     { 'fruit' => [ { 'name' => 'apples', 
				  'source' => 'Washington' } ],
		  'tubers' => [ { 'name' => 'potatoes', 
				  'source' => 'Idaho' } ] },
    'orange' =>  { 'fruit' => [ { 'name' => 'oranges', 
				  'source' => 'Florida' } ] }
  };
  print astext( $produce_info);

Examine STDOUT, et voila!

  orange = { 
    fruit = ( 
      { 
	name = oranges;
	source = Florida;
      },
    );
  };
  red = { 
    fruit = ( 
      { 
	name = apples;
	source = Washington;
      },
    );
    tubers = ( 
      { 
	name = potatoes;
	source = Washington;
      },
    );
  };


=head1 PREREQUISITES AND INSTALLATION

This package requires the String::Escape module. It should run on any standard Perl 5 installation.

To install this package, download and unpack the distribution archive from
http://www.evoscript.com/dist/ and execute the standard "perl Makefile.PL", 
"make test", "make install" sequence.


=head1 STATUS AND SUPPORT

This release of Data::PropertyList is intended for public review and feedback. 
It has been tested in several environments and used in commercial production, 
but it should be considered "alpha" pending that feedback and fixes for some of 
the below bugs.

  Name            DSLI  Description
  --------------  ----  ---------------------------------------------
  Data::
  ::PropertyList  adpf  Convert arbitrary objects to/from strings

Further information and support for this module is available at E<lt>www.evoscript.comE<gt>.

Please report bugs or other problems to E<lt>bugs@evoscript.comE<gt>.

The following changes are in progress or under consideration:

=over 4

=item Better Whitespace Parsing

Code is currently picky about parsing whitespace, and stilted about printing it. In particular, a newline is required after each item in an array or hash.

=item Restore Classes During Parsing

The class of blessed objects is indicated in C</* ... */> comments embedded in the output, but are not yet restored when reading.

=item Restore Circular References During Parsing

Circular references are indicated in C</* ... */> comments embedded in the output, but are not yet restored when reading.

=item NeXT Binary Format

Doesn't currently parse or write NeXT's <FFFF> binary format.

=back

=head1 SEE ALSO

Similar to PropertyList.pm by Markus Felten <markus@arlac.rhein-main.de>.

The packages Data::Dumper and FreezeThaw (available from CPAN) also stream and destream data structures. 

=head1 AUTHORS AND COPYRIGHT

Copyright 1996, 1997, 1998 Evolution Online Systems, Inc.

You may use this software for free under the terms of the Artistic License

Contributors: 
M. Simon Cavalletto C<E<lt>simonm@evolution.comE<gt>>,
Eleanor J. Evans C<E<lt>piglet@evolution.comE<gt>>,
Jeremy G. Bishop C<E<lt>jeremy@evolution.comE<gt>>,
Eric Schneider C<E<lt>roark@evolution.comE<gt>>

=cut
