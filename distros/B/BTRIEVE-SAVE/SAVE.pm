package BTRIEVE::SAVE;

use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DEBUG $TEST
	    );
$VERSION = '0.35';
$DEBUG = 0;

require Exporter;
require 5.004;

@ISA = qw(Exporter);
@EXPORT= qw();
@EXPORT_OK= qw();


# Preloaded methods go here.

####################################################################

# This is the constructor method that creates the BTRIEVE object. 
# It will attempt to set up info from the config file.

####################################################################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $config_file= shift ;
    my $file = shift ||undef;

    my $save_btr = {opt=>{}, array=>[]};
    $save_btr->{'opt'}{'config'}=$config_file;

    bless $save_btr, $class;
    if (-e $config_file) {
	$save_btr->config($config_file);
    } else {
	return $save_btr;
    }
    if (!$file) {return $save_btr};
    $save_btr->{'opt'}{'file'}=$file;


    $save_btr->_initbtrieve();
    return $save_btr;
}

###################################################################
# _initbtrieve() sets up config and filehandle
###################################################################
sub _initbtrieve {
    my $save_btr = shift;
    my $config_file = $save_btr->{'opt'}{'config'};
    $save_btr->{'opt'}{'increment'} = -1;

    my $file = $save_btr->{'opt'}{'file'};
    if (not(-e $file)) {carp "File \"$file\" doesn't exist"; return} 
    open (*file, $file);
    binmode *file;
    $save_btr->{'opt'}{'handle'}=\*file; #store filehandle in object
}

###################################################################
# config() looks for a config file which tells us where the
# offsets are in the fixed part of the record, their types and
# what to call them locally.
###################################################################

sub config {
    my $save_btr = shift;
    my $proto_rec = BTRIEVE::SAVE::REC->newconfig($save_btr->{'opt'}{'config'});
    $save_btr->{'opt'}{'proto_rec'} = $proto_rec;
} 

###################################################################
# parse_file() reads from a BTRIEVE SAVE file. Can do so 
# incrementally.
###################################################################
sub parse_file {
    my $save_btr = shift;
    my $increment = $save_btr->{'opt'}{'increment'}; #pick out increment from the object
    my $recordcount = 0;

    while ($increment==-1 or $recordcount<$increment) {
	my $curr_rec = $save_btr->next_rec;
	last unless $curr_rec;
	push @{$save_btr->{'array'}},$curr_rec;
	$recordcount++;
    } #end reading this record
    return $recordcount;
}

####################################################################

# Returns a new BTRIEVE::SAVE::REC based on the next bits.
# Returns undef if we have reached the end.

####################################################################
sub next_rec {
    my $save_btr=shift;
    my ($rec,$eor) = $save_btr->next_recbits;
    return undef if $eor eq "\cZ";
    return undef unless defined($rec);
    my $proto_rec = $save_btr->{'opt'}{'proto_rec'};
    my $curr_rec = $proto_rec->copy_struct();

    $curr_rec->parse_string($rec);
    return $curr_rec;
}

####################################################################

# Reads thru the handle looking for the bits forming the $rec
# and for the bits that should be $eor (end-of-record).
# Returns ($rec,$eor). $eor is undef if the read is at EOF.
# $eor is undef if we are at the DOS EOF ("\cZ") at the
# appropriate defined place.

####################################################################
sub next_recbits {
    my $save_btr = shift;
    my $handle = $save_btr->{'opt'}{'handle'};
    #need to use read to get the right bytes. Bummer.
    my $pos= tell($handle);
    my $info="";
    my $rc= read($handle,$info,14); #assumes that no record is more than 10 gigabytes
    return (undef,undef) unless $rc; #EOF...
    return (undef,"\cZ") if $info=~/^\cZ/;
    my ($length)= $info=~/^(\d+)[, ]/; #definition of btrieve save file format.
#error check here to see if $length is defined.
    seek($handle,$pos,0); #go back to where we were.
    my $rec="";
    $rc= read($handle,$rec,$length +length($length)+1); #definition of btrieve save file format.
    $rec = substr($rec,length($length)+1); #kills the \d+[, ], keeps the rest.
    my $eor="";
    $rc = read($handle,$eor,2); #skip over \r\n, or find \cZ
    return ($rec,$eor);
}
####################################################################
# openbtr() reads in a BTRIEVE SAVE file. It takes a hashref
# with key 'file' (name of the btrieve file). Increment 
# defines how many records to read in and is taken from the object.
####################################################################
sub openbtr {
    my $save_btr=shift;
    my $params=shift;
    my $file=$params->{'file'};
    if (not(-e $file)) {carp "File \"$file\" doesn't exist"; return} 
    my $totalrecord;
    $save_btr->{'opt'}{'increment'} 
         ||= $params->{'increment'}
         ||= 1;
    #store increment in the object, default is 1
    open (*file, $file);
    binmode *file;
    $save_btr->{'opt'}{'handle'}=\*file; #store filehandle in object
    
    print "read in $totalrecord records\n" if $DEBUG;
    if ($totalrecord==0) {$totalrecord="0 but true"}
    return $totalrecord;     
}

####################################################################
# closebtr() will close a file-handle that was opened with        
# openbtr()                                                      
####################################################################
sub closebtr {
    my $marc = shift;
    $marc->{'opt'}{'increment'}=0;
    if (not($marc->{'opt'}{'handle'})) {carp "There isn't a BTRIEVE SAVE file to close"; return}
    my $ok = close $marc->{'opt'}{'handle'};
    $marc->{'opt'}{'handle'}=undef;
    return $ok;
}

####################################################################
# nextbtr() will read in more records from a file that has      
# already been opened with openbtr(). the increment can be        
# adjusted if necessary by passing a new value as a parameter. the
# new records will be APPENDED to the BTRIEVE object              
####################################################################
sub nextbtr {
    my $save_btr=shift;
    my $increment=shift;
    my $totalrecord;
    if (not($save_btr->{'opt'}{'handle'})) {carp "There isn't a BTRIEVE SAVE file open"; return}
    if ($increment) {$save_btr->{'opt'}{'increment'}=$increment}

    $totalrecord = $save_btr->parse_file();
    
    return $totalrecord;
}
    
####################################################################
# output() actually writes the file with a string version of 
# $save_btr unless no file is given, in which case it returns the string
####################################################################
sub output {
    my $save_btr=shift;
    my $output = "";
    my $outfile = shift;


    $output = $save_btr->as_string();
    if ($outfile) {
	if ($outfile !~ /^>/) {carp "Don't forget to use > or >>: $!"}
	local(*OUT);
	open (OUT, "$outfile") || carp "Couldn't open file: $!";
        binmode OUT;
	print OUT $output;
	close OUT || carp "Couldn't close file: $!";
	return 1;
    }
      #if no filename was specified return the output so it can be grabbed
    else {
	return $output;
    }
}

    
####################################################################

# as_string() returns a string version of $save_btr. Handles packing the
# easily updateable version of %fixed.

####################################################################
sub as_string {
    my $output = "";
    my $save_btr=shift;

    for (@{$save_btr->{'array'}}) {
	my $data = $_->data;
	my $packed_rec = $_->counted_rec($data);
	$output .=$packed_rec;
    }
    $output .="\cZ";
    return $output;
}

####################################################################

# Takes an rdb filename, save filename, error file name, and config
# file name.  Also takes the field name for unindexed fixed info and
# var info, and strings to translate to tab and newline. Writes
# an rdb file with that information; warns and writes to the error file
# if there are problems in the data.

####################################################################

sub rdb_to_save {
    my $save_btr = shift;
    my ($rdb,$save,$errs,
	$zzname,$varname,$tabtrans,$rettrans) = @_;

    local *RDB;
    local *SAVE;
    local *ERRS;

    open RDB,"$rdb"   or die "Could not open $rdb:$!\n";
    binmode RDB;
    open SAVE,">$save" or die "Could not open $save:$!\n";
    binmode SAVE;
    open ERRS,">$errs" or die "Could not open $errs:$!\n";
    binmode ERRS;

    my $fieldnames = <RDB>;
    print ERRS $fieldnames;

    chomp $fieldnames;

    my  @rdbnames = split(/\t/,$fieldnames);

    my $proto_rec = $save_btr->{opt}{proto_rec};

    my @names = @{$proto_rec->{opt}{names}};

    my %fieldlen = (); #Gonna use this for lookup.
    my @fixed_defs = @{$proto_rec->{opt}{fixed_defs}};
    for (@fixed_defs) {
	$fieldlen{ $_->{name}} = $_->{len};
    }; 

    my $dashline = <RDB>;
    print ERRS $dashline;


REC:
    while (<RDB>) {
	chomp;
	next unless /\S/;
	my @fields= split(/\t/);

	my $var;
	my $rhfixed;
	my @fieldnames = @rdbnames;
	if ($#fields != $#rdbnames) {
	    warn "Paranoia 1: Number of fields do not match rdb spec at line $..\n";
	    print ERRS $_;
	    next REC;
	}
	my $err_skip =0;
   FIELD:
	while (@fields) {
	    my $field = shift @fields;
	    $field=~s/$tabtrans/\t/;
	    $field=~s/$rettrans/\n/;
	    my $name  = shift @fieldnames;

	    if ($name eq $zzname) {
		$rhfixed->{'ZZ'} = $field;
		next FIELD;
	    }
	    if ($name eq $varname) {
		$var = $field;
		next FIELD;
	    }
	    if ($fieldlen{$name} != length($field)) {
		warn "Paranoia 2: Lengths do not match for $name at line $..\n";
		print ERRS $_;
		next REC;
	    }
	    $rhfixed->{$name}=$field;
	}
	
	my $curr_rec = $proto_rec->copy_struct();
	@{$curr_rec->{values}} = ($rhfixed,\"",\$var);
	my $counted_rec = $curr_rec->counted_rec_hash();
	print SAVE $counted_rec;
    }
    
    print SAVE "\cZ";

    close RDB or carp "Could not close $rdb:$!\n";
    close ERRS or carp "Could not close $errs:$!\n";
    close SAVE or carp "Could not close $save:$!\n";
}

####################################################################

# Takes an rdb filename, save filename, error file name, and config
# file name.  Also takes the field name for unindexed fixed info and
# var info, and strings to translate to tab and newline. Writes
# a rdb file with that information; warns and writes to the error file
# if there are problems in the data.

####################################################################
sub save_to_rdb {
    my $save_btr = shift;
    my ($rdb,$save,$errs,
	$zzname,$varname,$tabtrans,$rettrans) = @_;

    local *RDB;
    local *ERRS;

    my $btr = BTRIEVE::SAVE->new($save_btr->{opt}{config},$save); 
    $btr->parse_file();
    my $proto_rec = $btr->{'opt'}{'proto_rec'};
    my @names = @{$proto_rec->{'opt'}{'names'}};
    my @rdbnames = @names;
    grep {$_ = $zzname if $_ eq 'ZZ'} @rdbnames;
    open RDB,">$rdb"  or die "Could not open $rdb for write: $!\n";
    binmode RDB;
    open ERRS,">$errs"  or die "Could not open $errs for write: $!\n";
    binmode ERRS;


    foreach my $name (@names) {
	print RDB "$name\t"; # in /rdb systems, deleting an extra column is trivial.
    }
    print RDB "$varname\n";
    
    for (@names) {
	my $name =$_;
	$name=~s/./-/g;
	print RDB $name."\t";
    }
    my $dashvar = $varname;
    $dashvar=~s/./-/g;
    print RDB $dashvar."\n";

REC:
    foreach my $rec (@{$btr->{array}}) {
	my $rdbline = "";
	foreach my $name (@names) {
	    my $field = $rec->{values}[0]{$name};
	    if ($field=~/$tabtrans|$rettrans/) {
		print ERRS $rec->counted_rec($rec->fixed.$rec->var);
		next REC;
	    }
	    $field =~s/\t/$tabtrans/g;
	    $field =~s/\n/$rettrans/g;
	    $rdbline .= $field."\t";
	}
	my $var = $rec->var();
	$var =~s/\t/$tabtrans/;
	$var =~s/\n/$rettrans/;
	$rdbline.= $var."\n";
	print RDB $rdbline;
    }
    close RDB or carp "Could not close $rdb:$!\n";
    print ERRS "\cZ";
    close ERRS or carp "Could not close $errs:$!\n";;
}

####################################################################

# BTRIEVE::SAVE::REC is responsible for internal representation of btrieve
# records. It knows enough to parse the %fixed information from
# a string and can generate string representations of data and 
# counted string.

####################################################################

package BTRIEVE::SAVE::REC;

use vars qw( %TYPEMAP %TYPE_SCALE $VERSION);
%TYPEMAP =    (Zstring => 'a', Integer => 'V', RAW => 'a');
%TYPE_SCALE = (Zstring => 1,  Integer => 0.25, RAW => 1  ); # Btrieve standard has byte counts.

$VERSION = '0.35';
####################################################################

# This roughly specifies what real recs know: a template to pack and
# unpack strings and a list of names for %fixed keys. The arrayref
# stores [$rhfixed,$rfixed,$rrest] information.

####################################################################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($ranames,$rtemplate,$packed_length,$rhfixed_defs) = @_;
    my $save_rec = {opt=>{names =>$ranames,template=>$rtemplate,
		      len=>$packed_length,fixed_defs=>$rhfixed_defs },
		values=>[]};
    return bless $save_rec,$class;
}

sub newconfig {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $handle = shift;
    local $/="\n";
    local(*F);
    open F,$handle or die "Could not open $handle:$!\n";
    binmode *F;
    my $fixed_length = 0;
    
    my $langname_preamble;
    my $lang_len;
    my $rhfixed_defs = [];
    while (<F>) {
	if (/langname/i) {
	    ($langname_preamble) =/^(.*)langname/i ;
	    $lang_len = length($langname_preamble) ;
	}
	($fixed_length) = /(\d+)/ if /Record Length/;
	if (/^\s+\d+/) {
	    my ($len,$type) = /^\s+\d+\s+\d+\s+\d+\s+(\d+)\s+(\S+)/o;
	    die "Type $type not understood" unless $TYPEMAP{$type};
	    my ($langname)  = /^.{$lang_len}(.*)/o;
	    $langname=~s/\W//og;
	    die '"ZZ" is a reserved fieldname\n' if $langname eq "ZZ";
	    push @{$rhfixed_defs},{len=>$len,type=>$type,name=>$langname};
	}
    }
    # We define the unmatched as "ZZ"



    my $template="";

    my $hashed_len = 0;
    for (@{$rhfixed_defs}) {
	$template.= $TYPEMAP{$_->{'type'}}.($_->{'len'}*$TYPE_SCALE{$_->{'type'}})." "; #works for ZString and Integer
	$hashed_len += $_->{'len'};					     
    }
    my $ZZ_len = $fixed_length-$hashed_len;
    die "Sum of field lengths exceeds fixed length by ".-$ZZ_len." bytes\n" if $ZZ_len < 0;
    push @{$rhfixed_defs},{len=>$ZZ_len,type=>"RAW",name=>"ZZ"};
    $template .= $TYPEMAP{'RAW'}.$ZZ_len;
    my @names = map {$_->{'name'} } @{$rhfixed_defs};
    # Templates with "a0" in them return empty strings, so ok 
    # to have $fixed_length= $hashed_len. Perl rules OK?

    $template=~s/(\D)1 /$1 /g;
    close F or die "Could not close config file:$!\n";
    return $class->new(\@names,$template,$fixed_length,$rhfixed_defs);
}

####################################################################

# All_index returns true iff the structure of the record implies that
# there are no extra bytes in the fixed portion that are not indexed.

####################################################################
sub all_indexed {
    my $save_rec = shift;
    my $rhfixed_defs = $save_rec->{'opt'}{'fixed_defs'};
    my $hashed_len = 0;
    for (@{$rhfixed_defs}) {
	$hashed_len += $_->{'len'};
    }
    return 1 if $hashed_len == $save_rec->{opt}{len};
    return 0;
}

####################################################################

# This produces a clone with the same structure but no data.

####################################################################
sub copy_struct {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my ($btr) = @_;

    my $save_rec = {opt=>$proto->{'opt'}, values=>[{},\"",\""]};

    return bless $save_rec,$class;
}

####################################################################

# This uses the {opt} information to fill in {values} from the string
# passed as a parameter.  {values} will look like
# [$rhfixed,$rfixed,$rrest].

####################################################################
sub parse_string {
    my $save_rec = shift;
    my $string = shift;
    my $fixed_len = $save_rec->{'opt'}{'len'};
#    my($fixed,$rest)= $string=~/^(.{$save_rec->{'opt'}{'len'}})(.*)/os;
    my $fixed= substr($string,0,$fixed_len);
    my $rest = substr($string,$fixed_len);

    my @fixed=unpack($save_rec->{'opt'}{'template'},$fixed);
    my %fixed;
    for (@{$save_rec->{'opt'}{'names'}}) {
	#remove warnings about use of undefined value.
        if ($_ eq 'ZZ' and !defined($fixed[0])) {
	   $fixed{$_} ='';
	   next;
	}
	$fixed{$_}= shift @fixed;
    }
    $save_rec->{'values'}=[\%fixed,\$fixed,\$rest]; 
}

####################################################################

# We know how to take a string and add the necessary appurtenances
# for appending to the on-file btrieve set of records.

####################################################################
sub counted_rec {
    my ($save_rec,$data) = @_;
    return length($data).",".$data."\015\012"; # octal def for x-platform.
}

####################################################################

# We know how to use our hash to create a string
# for appending to the on-file btrieve set of records.

####################################################################
sub counted_rec_hash {
    my ($save_rec) = @_;
    my $data = $save_rec->data();
    return $save_rec->counted_rec($data);
}

####################################################################

# Looks up the fixed string component of self.

####################################################################
sub fixed {
    my $save_rec = shift;
    if (@_) {
        ${$save_rec->{values}[1]} = shift;
    }
    return ${$save_rec->{values}[1]};
}


####################################################################

# Looks up the var string component of self.

####################################################################
sub var {
    my $save_rec = shift;
    if (@_) {
        ${$save_rec->{values}[2]} = shift;
    }
    return ${$save_rec->{values}[2]};
}

####################################################################

# We know how to produce data from the hashed fixed info.

####################################################################
sub data {
    my ($save_rec) = @_;

    my $rrest = $save_rec->{'values'}[2];
    my $fixed = $save_rec->fix_hash_to_string();
    return  $fixed.$$rrest;    
}

####################################################################

# We know how to produce a fixed string from the hashed fixed info.

####################################################################

sub fix_hash_to_string {
    my ($save_rec) = @_;

    my $rhfixed = $save_rec->{'values'}[0];
    my $template = $save_rec->{'opt'}{'template'};
    $rhfixed->{"ZZ"} = '' unless defined $rhfixed->{"ZZ"};
    my @values = ();
    # ?? do we want to use an array slice:
    # my %fixed = %$rhfixed;
    # my @names = @{$save_rec->{opt}{names}}
    # @values = @fixed{@names}??
    #
    for (@{$save_rec->{'opt'}{'names'}}) {
	push @values, $rhfixed->{$_};
    }
    return pack($template,@values);    
}
1;  # so the require or use succeeds

__END__


####################################################################
#                  D O C U M E N T A T I O N                       #
####################################################################

=pod

=head1 NAME

    BTRIEVE::SAVE - Perl extension to manipulate BTRIEVE SAVE records.

=head1 SYNOPSIS

    use BTRIEVE::SAVE
    my $btr = BTRIEVE::SAVE->new('cc057.std','cc057.dar');
    $btr->parse_file();
    my $recs = $btr->{'array'};
    for (@$recs) {
        my($rhfixed,$rfixed,$rvar)=@{$_->{values}};
        print $rhfixed->{'Title'}."\n";
    }
    

    
    # Often the first record is some kind of header.  Generally one
    # treats header records differently from those that follow. E.g.,
    # they often have counts of the following records that must be
    # adjusted if we are gonna kill or add records.  Here we leave it
    # alone.

    my $output = "";
    $header=shift @$recs;

    my $data = $header->fixed.$header->var;
    $output .= $header->counted_rec($data);
    
    foreach my $rec (@$recs) {
        my($rhfixed,$rfixed,$rvar)=@{$rec->{values}};
        $rhfixed->{'Title'} =~s/^\s*the/The/;
        $output .=$rec->counted_rec_hash();
    }
    $output .="\cZ"; # now $output is a legal Btrieve save record.
    # For large records, one may want to do everything incrementally.
    
    open OUT,">>cc057.das"
              or die "Could not open cc057.das for append: $!\n";
    binmode OUT;
    my $incbtr = BTRIEVE->new('cc057.std','cc057.dar');
    my $header = $incbtr->next_rec();
    my $data = $header->fixed.$header->var;
    print OUT $header->counted_rec($data);
    
    while (defined( my $rec=$incbtr->next_rec) ) {
        my($rhfixed,$rfixed,$rvar)=@{$rec->{values}};
        $rhfixed->{'Title'} =~s/^\s*the/The/;
        print OUT $rec->counted_rec_hash();
    }
    print OUT "\cZ";
    close OUT or die "Could not close cc057.das: $!\n";


=head1 DESCRIPTION

BTRIEVE::SAVE is a Perl 5 module for reading in, manipulating, and
outputting Pervasive's save file format for its Btrieve products.

BTRIEVE::SAVE uses BTRIEVE::SAVE::REC which abstracts an individual
record in the entire file.

You must have a config file for your save file: this allows
BTRIEVE::SAVE::REC to analyse the fixed parts and find the variable
parts of each BTRIEVE::SAVE record.
      

=head2 Downloading and Installing

=over 4

=item Download

Download the latest version from
http://www.cpan.org/modules/by-module/BTRIEVE. The module is provided
in standard CPAN distribution format. It will extract into a directory
BTRIEVE-version with any necessary subdirectories.  Change into the
BTRIEVE top directory.


=item Unix Install

    perl Makefile.PL
    make
    make test
    make install

=item Win9x/WinNT/Win2000 Install

    perl Makefile.PL
    perl test.pl
    perl install.pl

=item Test

Once you have installed BTRIEVE::SAVE, you can check if Perl can find
it. Change to some other directory and execute from the command line:

    perl -e "use BTRIEVE::SAVE"

If you do not get any response that means everything is OK! If you get
an error like I<Can't locate method "use" via package BTRIEVE::SAVE>
then Perl is not able to find BTRIEVE/SAVE.pm--double check that the
file copied it into the right place during the install.

=back

=head2 Todo

=over 4

=item *

Support for the other 12 documented btrieve data types.

=item *

Help for adding the names column in the config file.

=item *

More detailed warnings/sanity checks on the config file and save file.


=back


=head2 Notes

Please let us know if you run into any difficulties using
BTRIEVE::SAVE--we'd be happy to try to help. Also, please contact us
if you notice any bugs, or if you would like to suggest an
improvement/enhancement. Email addresses are listed at the bottom of
this page. Lane is probably the most interested in making this work, so 
may be your best initial bet.

=head2 BTRIEVE::SAVE::REC structure.

A save file record on disk looks like:

          __________________________________________
          |   Fixed,          | Fixed,   |           |
Count[, ] |   indexed.        | left-over|  Variable |\r\n
          |___________________|__________|___________|

The Count is the number of "boxed bytes" (excluding the count itself, the
following comma or space, and the final two bytes at the end). Count is 
an unpadded ascii integer, like "524".

Count is followed by either a comma or a space. BTRIEVE::SAVE::REC writes
a comma, but reads either comma or space.

The boxes are binary data. BTRIEVE::SAVE::REC will not interpret the
(fixed, left-over) or variable boxes, and will parse the (fixed,
indexed) data into a hash based on a template and names determined from
the config file.

The last two boxes may be empty; if the sum of the lengths is equal to the
fixed_length defined in the config file the (fixed, left-over) box will have no
bytes. Variable will be non-empty if and only if Count > fixed_length.

The number of bytes covered by the first two fields is equal to
fixed_length.  (In theory the (fixed, indexed) and (fixed, left-over)
could be intermixed, with possible overlaps.  Has anyone seen this?
Docs saying that Pervasive won't support this?)

The final two bytes are unix return and newline bytes.

A save file is a bunch of save file records concatenated with no
intervening bytes followed by "\cZ".


Each BTRIEVE::SAVE::REC has admin information in its {opt} key and
data in its {values} key.

  {opt} has keys:
    {fixed_defs} keys a ref to an array of hashes with keys:
      {len}      - length in bytes of the field
      {name}     - the user-defined name of that field, found from an
                   extra column in the config file. The config file
                   cannot use "ZZ" as a field name; one of the {name}s
                   is always set to "ZZ" to handle fixed length
                   information which is unaccounted for by btrieve's
                   keys.
      {type}     - Btrieve's idea of the type of that field.

     The array of hashes is in the order that the defining lines occur
     in the config file.

    {template} - pack template used for extracting values
    {names}    - ref to array of names as in fixed_defs. 
                 This is not strictly necessary.
    
    {len}      - total length of the fixed part of the record.  This
                 must be at least equal to the sum of the {len}'s in
                 the {fixed_defs}.

  {values} is a ref to an array
      [$rhfixed,$rfixed,$rvar]
  
      where $rhfixed is a ref to a hash with keys from the {opt}{names}
      and values the unpacked version of the btrieve-defined
      fixed portion of the record.
  
      "ZZ" will always be the last element in {names}; 

      $rhfixed->{'ZZ'} will include all the bytes of the btrieve fixed
      part of the record that are not accounted for by the config
      file. (This means it can be empty.)  $rfixed is a reference to
      the btrieve-defined fixed portion of the record and $rvar is a
      reference to the btrieve-defined variable portion of the record.

    Parsing and definitions of the {fixed_defs} appears to assume that
    all keys are consecutive and that any fixed-length information not
    accounted for by key defs occurs at the end. 

    If you come across non-consecutive keys in a -stat file, make up
    extra key fields to cover the missing parts. This will make
    BTRIEVE::SAVE::REC happy.

    If folk actually see these kinds of keys, please alert us.  We can
    document this as a limitation. (We also take patches....). We are
    also interested if folk find examples of overlapping key defs.


=head2 BTRIEVE::SAVE structure.

Each BTRIEVE::SAVE record has keys:

  {opt} with keys:
       {file}      - a file name that BTRIEVE::SAVE will read from.
       {handle}    - a stored filehandle that BTRIEVE::SAVE will use, 
		     based on the {file}
       {increment} - how many records to attempt to read at a time 
                     in parse_file().
       {proto_rec} - A BTRIEVE::SAVE::REC with empty {values}, used 
                     for filling in elements of BTRIEVE::SAVE->{array}.
       {config}    - The config file used to define the {proto_rec}
                     and all elements of the {array}

   {array} which is a ref to an array (0-based) of BTRIEVE::SAVE::RECs
           with structure determined by {opt}{proto_rec}.

=head1 METHODS

Here is a list of the methods in BTRIEVE::SAVE and ::REC that are available to you for reading in, manipulating and outputting BTRIEVE::SAVE data.

=head2 new(),newconfig()

    Creates a new BTRIEVE::SAVE object; also used for ::REC.

    $x = BTRIEVE::SAVE->new('cc057.std');
    $x = BTRIEVE::SAVE->new('cc057.std','cc057.dat');

    $rec = BTRIEVE::SAVE::REC->new($ranames,$rtemplate,
                                   $packed_length,$rhfixed_defs);
    $rec = BTRIEVE::SAVE::REC->newconfig('cc057.std');

BTRIEVE::SAVE has an optional I<config> file first parameter and an
optional I<file> parameter to create and populate the object with data
from a file. If a file is specified it will read in the entire
file. If you wish to read in only portions of the file see openbtr(),
nextbtr(), and closebtr() below or use next_rec() and 
BTRIEVE::SAVE::RECs directly.

BTRIEVE::SAVE::REC allows creation with defined state with new() and
also from a config file with newconfig(). See the last EXAMPLE below
for a definition of the format of the config file.


=head2 config()

Installs a prototypical BTRIEVE::SAVE::REC in the BTRIEVE::SAVE object
based on the contents of the config file.

     $x= BTRIEVE::SAVE->new();
     $x->config('cc057.std');

=head2 openbtr()

Openbtr sets up incremental reading for a BTRIEVE SAVE file. It
takes a hashref with key 'file' (name of the btrieve file). Increment
defines how many records to read in and is taken from the object or
defaulted to 1.

    $x = BTRIEVE::SAVE->new('cc057.std');
    $x->openbtr({file=>"cc057.dat",increment=>"2"});
    $x->openbtr({file=>"cc057.dat"});


=head2 nextbtr()

Once a file is open nextbtr() can be used to read in the next group of
records. The increment can be passed to change the amount of records
read in if necessary. An increment of -1 will read in the rest of the
file.

    $x->nextbtr();
    $x->nextbtr(10);
    $x->nextbtr(-1);

nextbtr() will return the amount of records read in. 

    $y=$x->nextbtr();
    print "$y more records read in!";

=head2 closebtr()

If you are finished reading in records from a file you should close it
immediately.

    $x->closebtr();


=head2 parse_file()

Parse_file reads in a file, possibly incrementally. It APPENDS the
record to the BTRIEVE::SAVE {array} field. It returns the number of
records read.

    $y=$x->parse_file();
    print "$y records read!\n";

=head2 next_rec()

Next_rec returns a new BTRIEVE::SAVE::REC record with the same
structure as {proto_rec} and {values} based on the bits in the next
record.  

   my $rec=$x->next_rec;

=head2 next_recbits()

Next_recbits returns the data in the next record on-disk. It side-effects the position
of the file pointer implied by the handle.

   my $string_rec = $x->next_recbits

=head2 output()

Output dumps all records in {array} to a file (if passed one) in
Btrieve's save file format.  It returns a string version of this if
there is no file passed.

   $x->output(">cc057.das");
   my $btr_save_string = $x->output();

=head2 as_string()

As_string returns a string version in Btrieve's save file format of {array}.

   my $btr_save_string = $x->as_string();	  

=head2 save_to_rdb()

Save_to_rdb takes an rdb filename, save filename, error file name, and
config file name.  Also takes the field name for unindexed fixed info
and var info, and strings to translate into from tab and newline
characters. Writes an rdb file using the save file and config
information; warns and writes to the rdb formatted error file if there
are problems in the data.

    $btr->save_to_rdb('f.rdb','f.sav','ferr.sav',
		           'ZZ','VAR','<TAB>','<RET>');

=head2 rdb_to_save()

Rdb_to_save takes an rdb filename, save filename, error file
name, and config file name.  Also takes the field name for unindexed
fixed info and var info, and strings to translate into tab and
newline characters. Writes an rdb file using the rdb file and config
information; warns and writes to the save formatted error file if there
are problems in the data.

    $btr->rdb_to_save('f.rdb','f.sav','ferr.rdb',
		           'ZZ','VAR','<TAB>','<RET>');

=head1 BTRIEVE::SAVE::REC METHODS


=head2 copy_struct()

Copy_struct takes a record and returns a new BTRIEVE::SAVE::REC with
empty {values} and the same {opt}s.

    my $new_rec=$rec->copy_struct();

=head2 parse_string()

Parse_string takes a string representation of a btrieve record (typically
from next_recbits) and returns a new record with the same {opt}s and
appropriate {values}. Parse_string makes sure that all optional fields (ZZ and
the var field) are initialised to empty strings if undefined.

    my $curr_rec=$rec->parse-string($string_rec);

=head2 counted_rec()

Counted_rec takes a string version of a record and returns a string
that can represent this on-disk in Btrieve's save file format.

    my $save_rec = $rec->counted_rec($string_rec);

=head2 counted_rec_hash()

Counted_rec_hash will take the hash and variable information in
{values} and return a legal string in Btrieve's save file format.

    my $save_rec = $rec->counted_rec_hash();

=head2 fixed()

Fixed will return a string representation of the fixed string
information in {values}.

   my $fix_string = $rec->fixed;

=head2 var()

Var will return a string representation of the var string information
in {values}.

   my $var_string = $rec->var;

=head2 data()

Data will return a string representation of a record using the hash
and variable information in {values}.

   my $data = $rec->data();

=head2 fix_hash_to_string()				   

Fix_hash_to_string returns the fixed part of a record based on its
hash {values}.  If you want to get access to the raw fixed part, use
fixed().

   my $fixed = $rec->fix_hash_to_string();


=head1 EXAMPLES

Here are a few examples to fire your imagination.

=over 2

=item * 

Input. This example will read in a tab-delimited file and output a
Btrieve save file. Last field is variable.

    #!/usr/bin/perl
    use BTRIEVE::SAVE; # ::REC comes along for the ride.
    my $proto_rec = BTRIEVE::SAVE::REC->newconfig("config.std"); 

    open F,"import.tab"    
               or die "Could not open import.tab for read: $!\n";
    open OUT,">output.dat" 
               or die "Could not open output.dat for write: $!\n";
    binmode OUT;
    while (<F>) {
	  chomp;
	  my @fields= split(/\t/);
	  my $var = pop @fields;
	  my $data = (join "",@fields).$var;
	  print OUT $proto_rec->counted_rec($data);
     }
     print OUT "\cZ";

     close F;
     close OUT;

=item *

Feeling paranoid? I know I am.

Let's say somebody comes to you with a large tab delimited file, a
BTRIEVE config file (forced on her by external software), and a
burning desire that her data become one with BTRIEVE.

And she added data to the file by hand over the last 3 years. And she
is not quite sure that she got the right lengths for the indexes.

Fortunately her tab-delimited file is in /rdb format so at least the
field names are available. She tells you that the last, very
important, field is variable length. The order of names in the rdb
file is different than that in the save file spec, and you won't write
a filter to fix that (go figure).

/Rdb files look like:

     Author	   Title                Opinion_of_AACR2
     ------	   ------               ----------------
     Fred	   Fred's holidays      Better than chocolate
     James	   James' elbows        Larger than several trucks

  See 
  http://www2.linuxjournal.com/lj-issues/issue67/3294.html 
  for details on /rdb which is a cool idea.

    $ grep '<VAR>\|<RET>' file.rdb |wc -l 
      0
    $ cat rdb_btr.pl
    #!/usr/bin/perl
    print "Usage: rdb_btr.pl <rdbfile><conf><savefile><error rdbfile>" 
            unless scalar @ARGV ==4;
    my ($rdb,$config,$save,$err) = @ARGV;
    my $btr = BTRIEVE::SAVE->new($config);
    $btr->rdb_to_save($rdb,$save,$err,
		           'ZZ','Opinion_of_AACR2','<TAB>','<RET>');
    
    $ rdb_btr.pl file.rdb file.std file.sav file.err
      Paranoia 2: Lengths do not match for Title at line 6.
      Paranoia 1: Number of fields do not match rdb spec at line 300.
    $ wc -l file.err
      4
    $ etbl file.err
    (Time passes as you edit the relevant lines' problems.)
    $ rdb_btr.pl file.err file.std file2.sav file2.err
    $ wc -l file2.err
      2
    $ perl -ne 'print unless /^\cZ$/' file.sav | cat - file2.sav > clean.sav

    *Whew*

=item *

Someone hands you a BTRIEVE file. Having paid the tax to Pervasive you
have a command line utility "butil" with many options, including
-load, -save, -stat and -clone.

You want to get the file out into /rdb tab-delimited form so you
only need -save and -stat.

    $ butil -save file.btr file.dat    
    $ butil -stat file.btr > file.std
    
    (Edit file.std to add an extra column thusly:)
    
    (Leave what's above here alone...)
    Record Length = 171 
    Record Length = <whatever you want the fixed length to be.>

    (...leave the next alone until the Key defs below.
    Some columns elided for space.)
    
    Key         Pos..     Type        Null V..    ACS
        Segment      Len..       Flags       Uniq..     
      0    1      1    4  Zstring         - .. 8   --
      1    1      5    4  Integer  MD     - .. 8   --
    
    (..and what's after alone.)
    
    
    Add an extra column:
    
    Key         Pos..    Type         Null V..    ACS
        Segment      Len..        Flags      Uniq..    Langname
      0    1      1    4  Zstring         --.. 8  --   Author
      1    1      5    4  Integer  MD     --.. 8  --   dbcn

    $ cat btr_rdb.pl
    #!/usr/bin/perl
    print "Usage: btr_rdb.pl <rdbfile><conf><savefile><error savefile>" 
            unless scalar @ARGV ==4;
    my ($rdb,$config,$save,$err) = @ARGV;
    my $btr = BTRIEVE::SAVE->new($config);
    $btr->save_to_rdb($rdb,$save,$err,
		           'ZZ','VAR','<TAB>','<RET>');

    $ rdb_btr.pl file.rdb file.std file.sav file.err
    $ wc file.err
      0       1       1 file.err
    $


=back

=head1 AUTHORS

Chuck Bearden cbearden@rice.edu

Bill Birthisel wcbirthisel@alum.mit.edu

Derek Lane dereklane@pobox.com

Charles McFadden chuck@vims.edu

Ed Summers esummers@odu.edu


=head1 SEE ALSO

perl(1), www.pervasive.com, "Btrieve Complete" by Jim Kyle
(Addison-Wesley 1995).

=head1 COPYRIGHT

Copyright (C) 2000, Bearden, Birthisel, Lane, McFadden, Summers.  All
rights reserved.  Copyright (C) 2000, Duke University, Lane. All
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Feb 15 2000.

=cut

