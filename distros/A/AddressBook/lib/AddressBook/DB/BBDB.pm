package AddressBook::DB::BBDB;

use strict;
use vars qw(@ISA %EXPORTER);
use Carp;

@ISA = qw(AddressBook);

my $quoted_string_pat =<<'END';
"                      # First a quote
([^\"\\]*              # Doesn't contain a \ or "
 (?:
   \\.[^\"\\]*         # A backslash an any char and not another
                       # backslash or quote
 )*                    # as many of these as we like
)
"                      # And the final quote
END

my $int_or_list=<<END;
(?:                                      # Either just a plain
   \\d+                                  # integer
 |                                       # OR
   \\(                                   # A list of (
       \\d+(?:\\ \\d+)*                  # space separated plain integers
   \\)                                   # followed by a closing )
     |                                   # OR
   \\(                                   # A list of (
       (?: $quoted_string_pat            # space separated
          (?:\\ | \\) )?                 # quoted strings followed by
       )*                                # a closing )
)
END

my $nil_or_string_pat = <<END;
(?:nil|$quoted_string_pat)
END

my $aka_pat = <<END;
(?:nil|                          # Might be nil
\\(                              # Starts with an open (
 (?:
  $quoted_string_pat             # And a quoted string
  (?:\\ | \\) )?                 # followed by a space or )
 )+                              # at least one
)
END

my $single_phone_pat = <<END;
\\[
 (?:$quoted_string_pat)          # The type of phone
\\ (
    (?:$quoted_string_pat)       # An international number is quoted
   |                             # BUT
    ([\\d\\ ]+)                  # An american number is a list of integers
  )
\\]
END

my $phone_pat = <<END;
(?:nil|                          # Might be nil
\\(                              # Starts with an open (
 (?:
  $single_phone_pat              # And a single phone pattern
  (?:\\ | \\) )?                 # followed by a space or )
 )+                              # at least one
)
END

my $single_address_pat = <<END;
\\[                                # The opening [
 $quoted_string_pat \\             # The six address fields
 $quoted_string_pat \\             # The six address fields
 $quoted_string_pat \\             # The six address fields
 $quoted_string_pat \\             # The six address fields
 $quoted_string_pat \\             # The six address fields
 $quoted_string_pat \\             # The six address fields
 ($int_or_list)                    # followed by the zip code
\\]                                # The closing ]
END

my $address_pat = <<END;
(?:nil|                          # Might be nil
\\(                              # Starts with an open (
 (?:
  $single_address_pat            # And a single address pattern
  (?:\\ | \\) )?                 # followed by a space or )
 )+                              # at least one
)
END

my $net_pat =<<END;
(?:nil|                          # Might be nil
\\(                              # Starts with an open (
 (?:
  $quoted_string_pat             # And a quoted string
  (?:\\ | \\) )?                 # followed by a space or )
 )+                              # at least one
)
END

my $lisp_symbol_pat = '[\w\-]+';

my $alist_pat = <<END;
   (
     \\(                         # An instance of an Alist - open (
     ($lisp_symbol_pat)          # A lisp Symbol
     \\ \\. \\                   # followed by space . space
     $quoted_string_pat          # followed by a quoted string
     \\)\\ ?                     # and a closed ) and maybe a space
   )                             # at least one of these
END

my $notes_pat = <<END;
(?:$nil_or_string_pat|           # Might be nil or just a string
\\(                              # An open (
   $alist_pat+                   # and at least one Alist
\\)                              # And a closed )
)
END

my $bbdb_entry_pat = <<END;
\\[                              # Opening vector [
$nil_or_string_pat   \\          # First name
$nil_or_string_pat   \\          # Last name
($aka_pat) \\                    # Also Known As
$nil_or_string_pat   \\          # Company name
($phone_pat) \\                  # Phone list
($address_pat) \\                # Address list
($net_pat)   \\                  # Net names list
($notes_pat) \\                  # Notes Alist
(?:nil\\ *)+                     # Always nil as far as I can tell
\\]                              # Closing vector ]
END

########################################################################
# I added some ()s inside the patterns above, to make it possible to 
# break out the sub fields of a bbdb record.  Once consequence of this 
# is to make it very difficult to figure out at what position the top
# level fields are, so the subroutine _figure_out_indices does exactly
# that.  It uses the sample data below, and searches the fields that are 
# matched by the $bbdb_entry_pat pattern above.  The results are stored
# in the %field_index hash so we can reference them by name, and perhaps
# change the ()s in the patterns above without breaking everything.
########################################################################

my @field_names = 
qw (first last aka company phone address net notes);
my %field_names;
@field_names{@field_names} = (0..$#field_names);

my $sample_data = <<END;
["first" "last" ("aka") "company" (["phone with integer" 123 456 789] ["phone with quotes" "123-456-789"]) (["address" "street1" "street2" "street3" "city" "state" ("zip")]) ("net") ((notes . "data")) nil]
END

my %field_index;
sub _figure_out_indices {
  my @fields = ($sample_data =~ m/^$bbdb_entry_pat$/ox);
  my @names = @field_names;
  my $i;
  for ($i=0; $i < @fields; $i++) {
    if ($fields[$i] =~ $names[0]) {
      $field_index{shift @names} = $i;
      last unless @names;
    }
  }
}
_figure_out_indices();

########################################################################

sub un_escape {
  my $s = shift;
  $s =~ s/\\(.)/$1/g;               # should just be " or \
  return $s;
}

########################################################################

sub decode {
  my ($self,$str) = @_;
  my @fields = ();
  unless (@fields = ($str =~ m/^$bbdb_entry_pat$/ox)) {
    if ($BBDB::debug) {
      my $pat = '';
      my @subpats = (
		     [ '\[', 'opening ['],
		     [ $nil_or_string_pat, 'First name'],
		     [ $nil_or_string_pat, 'Last name'],
		     [ $aka_pat, 'Also known as'],
		     [ $nil_or_string_pat, 'Company name'],
		     [ $phone_pat, 'Phone'],
		     [ $address_pat, 'Address'],
		     [ $net_pat, 'Net names' ],
		     [ $notes_pat, 'Notes'],
		     [ 'nil', 'Last nil'],
		     [ '\]', 'closing ]']
		    );
      my $i;
      foreach $i (@subpats) {
	$pat .= $i->[0];
	printf STDERR "No match at %s\n", $i->[1] and last unless
	  $str =~ m/^$pat/x;
	$pat .= '\ ' unless $i->[0] eq '\[' or $i->[0] eq 'nil' ;
      }
    }
    return undef;
  }


  my $i;
  local($_);

  foreach $i (@field_names) {
    $fields[$field_index{$i}] = ''
      if (!defined $fields[$field_index{$i}] or 
	  $fields[$field_index{$i}] eq 'nil');
  }

  my @aka = split(/$quoted_string_pat/ox,$fields[$field_index{aka}]);
  #    print "AKA=\n<",join(">\n<",@aka),">\nEND AKA\n";
  my $aka = [];
  for ($i=0; $i < @aka - 1; $i+=2) {
    push @$aka, un_escape($aka[$i+1]);
  }

  my @phone = split(/$single_phone_pat/ox,$fields[$field_index{phone}]);
  #    print "PHONE=\n<",join(">\n<",@phone),">\nEND PHONE\n";
  my $phone = [];
    for ($i=0; $i < @phone - 1; $i+=5) {
      push @$phone,[
		    un_escape($phone[$i+1]),
		     un_escape(defined $phone[$i+3] ? 
			       $phone[$i+3] : $phone[$i+4])
		   ];
    }

  my @address = split(/$single_address_pat/ox,$fields[$field_index{address}]);
  #    print "ADDRESS=\n<",join(">\n<",@address),">\nEND ADDRESS\n";
  my $address = [];
    for ($i=0; $i < @address - 1; $i+=9) {
      my $zip = $address[$i+7];
      $zip =~ s/^\((.*)\)$/$1/;   # remove ()
      if (defined $address[$i+8]) {  # we have quoted strings
	my @zip = split(/$quoted_string_pat/ox,$zip);
	#   print "ZIP = \n<",join(">\n<",@zip),">\nEND ZIP\n";
	$zip = join('',@zip);
      }
      push @$address,[
		      un_escape($address[$i+1]),
		      un_escape($address[$i+2]),
		      un_escape($address[$i+3]),
		      un_escape($address[$i+4]),
		      un_escape($address[$i+5]),
		      un_escape($address[$i+6]),
		      $zip
		     ];
    }

  my @net = split(/$quoted_string_pat/ox,$fields[$field_index{net}]);
  #    print "NET=\n<",join(">\n<",@net),">\nEND NET\n";
  my $net = [];
  for ($i=0; $i < @net - 1; $i+=2) {
    push @$net, un_escape($net[$i+1]);
  }


  my @notes = split(/$alist_pat/ox,$fields[$field_index{notes}]);
  #    print "NOTES=\n<",join(">\n<",@notes),">\nEND NOTES\n";
  my $notes = [];
  for ($i=0; $i < @notes - 1; $i+=4) {
    push @$notes, [
		   $notes[$i+2],
		   un_escape($notes[$i+3])
		  ]
  }

  $self->{'data'} =  [
	  un_escape($fields[$field_index{first}]),
	  un_escape($fields[$field_index{last}]),
	  $aka,
	  un_escape($fields[$field_index{company}]),
	  $phone,
	  $address,
	  $net,
	  $notes
	 ];
  return 1;
}

########################################################################

sub quoted_stringify {               # escape \ and " in a string
  my $s = shift;                     # and return it surrounded by
  $s =~ s/(\\|")/\\$1/g;             # quotes
  return "\"$s\"";
}

sub nil_or_string {                  # return nil if empty string
  return 'nil' if $_[0] eq '';       # otherwise quote it
  return quoted_stringify(@_);
}

sub nil_or_list {                    # return nil if empty string
  return 'nil' if $_[0] eq '';       # otherwise quote it and add ()s
  return '(' . quoted_stringify(@_) . ')' ;
}

########################################################################

sub encode {
  my $self = shift;
  my ($first, $last, $aka, $company, 
      $phone, $address, $net, $notes) = @{$self->{'data'}};
  my ($i,@result,$s);
  push @result,nil_or_string($first);
  push @result,nil_or_string($last);

  if (@$aka) {
    my @aka;
    foreach $i (@$aka) {
      push @aka, quoted_stringify($i);
    }
    push @result, "(@aka)";
  } else {
    push @result, 'nil';
  }

  push @result,nil_or_string($company);

  if (@$phone) {
    my @phone;
    foreach $i (@$phone) {
      my $number;
      if ( $i->[1] =~ m/^\D?(\d{3})\D(\d{3})\D+(\d{4})\D?(\d*)$/ ) {
	$number = "$1 $2 $3 ";
	$number .= $4 ? $4 : '0';
      } else {
	$number = quoted_stringify($i->[1]);
      }
      push @phone,"[" . quoted_stringify($i->[0]) . " $number]";
      ;
    }
    push @result, "(@phone)";
  } else {
    push @result, 'nil';
  }
  if (@$address) {
    my @address;
    foreach $i (@$address) {
      my $zip = $i->[6];
      if ($zip =~ m/^(\d{5})\D?(\d{4})?$/) {
	$zip = $1;
	if ($2) {
	  $zip = "($zip $2)";
	}
      } elsif ($zip =~ m/^(\S+) (\S+)$/) {
	$zip = "(\"$1\" \"$2\")";
      } else {
	$zip = quoted_stringify($zip);
      }
      local($_);
      my @fields = map {quoted_stringify($_)} @$i[0..5];
      push @address, "[@fields $zip]";
    }
    push @result, "(@address)";
  } else {
    push @result, 'nil';
  }

  if (@$net) {
    my @net;
    foreach $i (@$net) {
      push @net, quoted_stringify($i);
    }
    push @result, "(@net)";
  } else {
    push @result, 'nil';
  }

  if ($notes) {
    my @notes;
    foreach $i (@$notes) {
      push @notes, "(" . $i->[0] . " . " . quoted_stringify($i->[1]) . ")";
    }
    push @result, "(@notes)";
  } else {
    push @result, 'nil';
  }
  return "[@result nil]";
}

########################################################################

sub find {
  my $self = shift;
  my $field = shift;
  my $find  = shift;

}

########################################################################

sub part {
  my ($self,$name,$data) = @_;
  my $result;
  if ($name eq 'all') {
    $result = $self->{data};
    $self->{data} = $data if @_ == 3;
  } else {
    croak "No such field $name" unless exists $field_names{$name};
    $result = $self->{data}->[$field_names{$name}];
    $self->{data}->[$field_names{$name}] = $data if @_ == 3;
  }
  return $result;
}

########################################################################

sub note_names {
  my $self = shift;
  my $notes = $self->part('notes');
  return () unless @$notes;
  local ($_);
  my @fields = map { $_->[0] } @$notes;
  return @fields;
}

sub simple {
  my ($file,$bbdb) = @_;
  local ($_);
  if (@_ == 1) {		#we're reading
    open(INFILE,$file) or croak "Error opening file: $!";
    <INFILE>;
    $_ = <INFILE>; s/\(([^)])\)/$1/;
    #@extra_fields = split(/\s+/, $_);
    my $count = 0;
    my @results;
    while (<INFILE>) {
      print STDERR "Read: $_" if $BBDB::debug;
      $count++;
      chomp;
      #    print STDERR "$count ";
      $bbdb = new BBDB();
      if ($bbdb->decode($_)) {
	push @results,$bbdb;
      } else {
	print STDERR "No match at record $count in $file\nData = $_\n";
      }
    }
    close INFILE;
    return \@results;
  } else {                   # we're writing
    open(OUTFILE,">$file") or croak "Error opening file for writing: $!";
    my $rec;
    my ($notes,@notes,%notes);
    foreach $rec (@$bbdb) {
      @notes{note_names($rec)} = 1;
    }
    local($_);
    @notes = grep !/^(creation-date|timestamp|notes)$/, keys %notes;
    print OUTFILE ";;; file-version: 3\n";
    print OUTFILE ";;; user-fields: ";
    print OUTFILE "(",join(' ',@notes),")" if @notes;
    print OUTFILE "\n";
    foreach $rec (@$bbdb) {
      print OUTFILE $rec->encode,"\n";
    }
    close OUTFILE;
  }
}

1;

__END__

=head1 NAME

bbdb - Perl extension for reading and writing bbdb files

=head1 SYNOPSIS

  use BBDB;
  my $x = new BBDB();
  $x->decode($string);
  my $str = $x->encode();
  # At this point, subject to the BUGS below
  # $str is the same as $string

  my $allR = BBDB::simple('/home/henry/.bbdb');
  map { print $_->part('first')} @$allR;   # print out all the first names


=head1 DESCRIPTION


=head2 Data Format

The following is the data layout for a BBDB record.  I have created a
sample record with my own data.  Each field is just separated by a
space.  I have added comments to the right

 ["Henry"                             The first name - a string
 "Laxen"                              The last name - a string
 ("Henry, Enrique")                   Also Known As - comma separated list
 "Elegant Solution"                   Business name - a string
 (["home" 415 789 1159 0]             Phone number field - US style
  ["fax" 415 789 1156 0]              Phone number field - US style
  ["mazatlan" "011-5269-164195"]      Phone number field - International style
 )
 (["mailing" "PMB 141"                Address field - There are 3 fields for
   "524 San Anselmo Ave." ""           for the street address, then one each
   "San Anselmo" "CA" (94960 2614)"     for City, State, and Zip Code
  ]
  ["mazatlan" "Reino de Navarra #757" Address field - Note that there is no
   "Frac. El Cid" ""                   field for Country.  That is unfortunate
   "Mazatlan" "Sinaloa, Mexico"        The zip code field is quoted if its
   ("CP" "82110")                      not an integer
  ]
  )
 ("nadine.and.henry@pobox.com"        The net addresses - a list of strings
  "maztravel@maztravel.com")
 ((creation-date . "1999-09-02")      The notes field - a list of alists
  (timestamp . "1999-10-17")
  (notes . "Always split aces and eights")
  (birthday "6/15")
 )
 nil                                  The cache vector - always nil
 ]

After this is decoded it will be returned as a reference to a BBDB
object.  The internal structure of the BBDB object mimics the lisp
structure of the BBDB string.  It consists of a reference to an array
with 9 elements The Data::Dumper output of the above BBDB string would
just replaces all of the ()s with []s.  It can be accessed by using
the C<$bbdb->part('all')> method.

=head2 Methods

=over 4

=item new()

called whenever you want to create a new BBDB object.  
       my $bbdb = new BBDB();

=item part(name [value])

Called to get or set all or part of a BBDB object.  The parts of the
object are: 

       all first last aka company phone address net notes

any other value in the name argument results in death.  Some of these
parts, namely phone, address, net, and notes have an internal
structure and are returned as references to arrays.  The others are
returned just as strings.  The optional second argument sets the part
of this BBDB object to the value you provided.  There is no
consistency checking at this point, so be sure the value you are
setting this to is correct.

 my $first = $bbdb->part('first');    # get the value of the first field
 $bbdb->part('last','Laxen');         # set the value of the last field
 my $everything = $bbdb->part('all'); # get the whole record

=item BBDB::simple(file_name,[array_ref_of_bbdb])

This is a "simple" interface for reading or writing an entire BBDB
file. If called with one argument, it returns a reference to an array of BBDB
objects.  Each object contains the data from the file.  Thus the
number of BBDB entries equals C<scalar(@$bbdb)> if you use:

       $bbdb = BBDB::simple('/home/henry/.bbdb');

If called with two arguments, the first is the filename to create, and
the second is a reference to an array of BBDB objects, such as was
returned in the one argument version.  The objects are scanned for
unique user defined fields, which are written out as the 2nd line in
the BBDB file, and then the individual records are written out.

=item decode(string)

Takes a string as written in a BBDB file of a single BBDB record
and decodes it into its PERL representation.  Returns undef if
it couldn't decode the record for some reason, otherwise returns
true.  

       $bbdb->decode($entry);

=item encode()

This is the inverse of decode.  Takes an internal PERL version of
a BBDB records and returns a string which is a lisp version of the
data that BBDB understands.  There are some ambiguities, noted in
BUGS below.

       my $string = $bbdb->encode();


=back

=head2 Debugging

If you find that some records in your BBDB file are failing to be
recognized, trying setting C<$BBDB::debug = 1;> to turn on debugging.
We will then print out to STDERR the first field of the record that we
were unable to recognize.  Very handy for complicated BBDB records.

=head1 AUTHOR

Henry Laxen <nadine.and.henry@pobox.com>
http://www.maztravel.com/perl

=head1 SEE ALSO

BBDB texinfo documentation

=cut


=head1 BUGS

Phone numbers and zip codes may be converted from strings to integers
if they are decoded and encoded.  This should not affect the operation
of BBDB.  Also a null last name is converted from "" to nil, which
also doesn't hurt anything.

You might ask why I use arrays instead of hashes to encode the data in
the BBDB file.  The answer is that order matters in the bbdb file, and
order isn't well defined in hashes.  Also, if you use hashes, at least
in the simple minded way, you can easily find yourself with legitimate
duplicate keys.


=cut

