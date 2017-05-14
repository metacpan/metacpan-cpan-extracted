#!/usr/local/bin/perl -w
# cvs id: $Id: create_genex_class.pl,v 1.31 2001/02/06 19:06:24 jes Exp $ 

use strict;
use Carp;
# use blib;
use Data::Dumper;
use Cwd;

use constant COLUMN_FILE => 'column2name';

# import the fkey constants
use lib '..';
use Bio::Genex::Fkey qw(:FKEY);

# this assumes the script is run in the top level Genex dir
my $MODULES = cwd();

#
# Process the command line options
#
my $USAGE = qq[$0 --target=dbtable [--pkey=col_name] [--support=sup_dbtable1 --support=sup_dbtable2]\n];
die $USAGE unless scalar @ARGV > 0;

use Getopt::Long;
my ($target,$PKEY,@controlled,@support);
# we'll use this for printing a timestamp
my $arguments = join(' ', @ARGV);

GetOptions('target=s' => \$target,
	   'support=s@' => \@support,
	   'controlled=s@' => \@controlled,
	   'directory=s' => \$MODULES,
	   'pkey=s' => \$PKEY,
	  );
die "Must set --target\n$USAGE" unless defined $target;

# some other useful variables
my $module_name = $target;
my $full_module_name = 'Bio::Genex::' . $module_name;
my $module_name_lc = lc($module_name);
my $time = localtime;

print STDERR "Using target: $target";
if (scalar @support) {
  print STDERR ", with supporting tables: \n";
  foreach (@support) { 
      print STDERR "   $_\n";
  }
} else {
    print STDERR ", no supporting tables\n";
}

my (%FILES,%FKEYS,$file);
foreach $module_name ($target, @support) {
  $file = $MODULES . "/$module_name/" . COLUMN_FILE; 
  open(IN,$file) or die "couldn't open $file for input";
  my @lines = <IN>;
  $FILES{$module_name} = \@lines;
}

########################################
#
# Next, go through the table files and find all foreign keys
#
foreach $file (keys %FILES) {
  # parse the table definition file for foreign keys
  my $line = 0;
  foreach (@{$FILES{$file}}) {
    $line++;

    #
    # NOTE: This assumes that all fkeys end in '_fk'
    #
    next unless /\w+_fk\b|LINKING/;		# find fkeys

    # tease out the four pieces we need
    my ($column_name,$table,$foreign_pkey,$fkey_type) = 
                       /\'
                           ([^\']+)	 # name
                        \'
                        \s+=>\s+         # separator
                        \'
                           [^\']+        # full name
                        \',
                        \s*\#            # comment intro
                           \s+([\w_]+)   # foreign table name
                           \s+([\w_]+)   # primary key of foreign table
                           \s+([\w_]+)   # comment text
                       /x; 
    die "No fkey_type defined: $_" unless defined $fkey_type;

    # %FKEYS hash:
    #   keys are table names
    #
    # Example: 
    #   Referring table: Chromosome (support)
    #   Referred to table: Species  (target)
    # 	 'Chromosome' => ARRAY(0x1037caa4)
    # 	    0  Bio::Genex::Fkey=HASH(0x1037caec)
    # 	       'fkey_name' => 'spc_fk'
    # 	       'fkey_type' => 'MANY_TO_ONE'
    # 	       'pkey_name' => 'spc_pk'
    # 	       'table_name' => 'Species'
    # 	 'Species' => ARRAY(0x1037cb04)
    # 	    0  Bio::Genex::Fkey=HASH(0x1037caf8)
    # 	       'fkey_name' => 'chromosome_fk'
    # 	       'fkey_type' => 'ONE_TO_MANY'
    # 	       'pkey_name' => 'spc_fk'
    # 	       'table_name' => 'Chromosome'
    #
    #   values are array refs of Bio::Genex::Fkey objects
    #      'table_name'  => table referenced by fkey
    #      'fkey_type'   => required fkey_type
    #      'fkey_name'   => the name of the column in the referring table
    #      'pkey_name'   => the name of the column in the refered to table
    #                       (for OTM keys it will not be a pkey...)

    # process any comments
    if ($fkey_type eq FKEY_MTO) {
      # process a many-to-one fkey:
      #    this type of fkey is like a reverse pointer to an
      #    array of objects, we need prevent attribute
      #    generation for the keyname, and instead put an
      #    attribute in the refered table. We do this by 
      #    manually entering a new fkey of type 'OTM', 
      #    one-to-many, to indicate we entered it.
      #
      
      # create a new key to point at this table 
      # ***only if it is the target table ***
      if ($table eq $target) {
	my $newkey = lc($file) . '_fk';
	my $fkey_obj = Bio::Genex::Fkey->new('table_name'=>$file,
					'fkey_name'=>$newkey,
					'pkey_name'=>$column_name,
					'fkey_type'=>FKEY_OTM);
	push(@{$FKEYS{$table}}, $fkey_obj);
      }
    } elsif ($fkey_type eq FKEY_LINK) {
      # process a linking_table fkey:
      #    linking_table fkeys are used to represent a many-to-many
      #    relationship between two DB tables, as such it always
      #    occurs in pairs. Like MTO fkeys, it acts like a reverse
      #    pointer to an array of objects, and we will manually
      #    entering a new fkey of type one-to-many_link in the referred to
      #    table. But, we also need to keep a record of it because it
      #    also acts like an FKEY fkey.
      #
      #    if we had the following relation:
      #
      #         A <=== B ===> C
      #
      #    in which B was a linking table between A and C, B would
      #    have two linking_table fkeys: a_fk and c_fk. We would need
      #    to add a OTM fkey, b_fk, in both A and C so that when b_fk
      #    is accessed through an object of either C or A it will
      #    return a list of B objects, but when a_fk is accessed
      #    through a B object it returns a single A object, and
      #    likewise when c_fk is accessed through a B object, it
      #    returns a single C object.


      # create a new key to point at this table 
      # ***only if it is the target table ***
      if ($table eq $target) {
	my $newkey = lc($file) . '_fk';
	my $fkey_obj = Bio::Genex::Fkey->new('table_name'=>$file,
					'fkey_name'=>$newkey,
					'pkey_name'=>$column_name,
					'fkey_type'=>FKEY_OTM_LINK);
	push(@{$FKEYS{$table}}, $fkey_obj);
      }
    } elsif ($fkey_type eq FKEY_LT) {
      # process a lookup table fkey:
      #    this type of fkey is similar to a many-to-one 
      #    fkey. However the API will *never* retrieve
      #    an object of this type, instead it retrieves a matrix
      #    of values, that represent the list of objects. It 
      #    is used in only two places in the schema: {AM,AL}_Spots.
      #
      #    We manually enter a new fkey of type 'ONE_TO_MANY_LT', 
      #    into the referred to table
      
      # create a new key to point at this table 
      # ***only if it is the target table ***
      if ($table eq $target) {
	my $newkey = lc($file) . '_fk';
	my $fkey_obj = Bio::Genex::Fkey->new('table_name'=>$file,
					'fkey_name'=>$newkey,
					'pkey_name'=>$column_name,
					'fkey_type'=> FKEY_OTM_LT);
	push(@{$FKEYS{$table}}, $fkey_obj);
      }
    }
    # enter the fkey into this table with fkey_type
    my $fkey_obj = Bio::Genex::Fkey->new('table_name'=>$table,
				    'fkey_name'=>$column_name,
				    'pkey_name'=>$foreign_pkey,
				    'fkey_type'=> $fkey_type);
    push(@{$FKEYS{$file}}, $fkey_obj);
  }
}

# this gives us a named block for a goto
MODULE: {
  $module_name = $target;
}

########################################
#
# Make the Module and its constiuent files
#

# first we make sure we have a directory
my $dir = $MODULES . "/$module_name";
unless (-e $dir) {
  mkdir($dir,0775) or die "couldn't create directory $dir";
}

#then a Makefile.PL
$file = $dir . '/Makefile.PL';
unless (-f $file) {
  open(OUT,">$file") or die "Couldn't open $file";

  # start a section with variable expansion *enabled*
  print OUT <<"EOT";
WriteMakefile(
    'NAME'	=> '$full_module_name',
    'VERSION_FROM' => '../Genex.pm', # finds \$VERSION
);
EOT
  close(OUT);
}

# then we need a module file
$file = $dir . '/' . $module_name . '.pm';
open(OUT,">$file") or die "Couldn't open $file";

########################################
#
# Now we parse the target's table definition file and grab *all* columns
#
my (@attributes,$full_name,$name,$line,$fkey_type);
$line = 0;
my %column2name;
my %name2column;
foreach (@{$FILES{$module_name}}) {
  $line++;
  next if /^\s+$/;		# skip whitespace only lines
  
  # pull out the two pieces we want
  ($name,$full_name) = 
            /\'
                ([^\']+)	 # name in quotes
             \'
             \s+=>\s+      # separator
             \'
                ([^\']+)   # full name in quotes
             \',
            /x; 
  
  die "Bad line: $_ " unless defined $name and defined $full_name;
  $column2name{$name} = $full_name;
  $name2column{$full_name} = $name;
  
  # check if primary key
  if ($full_name eq 'Accession Number') {
    if (defined $PKEY) {
      unless ($name eq $PKEY) {
	die "--pkey: $PKEY differs from Accession Number: $name in $file";
      }
    } else {
      $PKEY = $name;      
    }
  }
  push(@attributes,$name);
}
# need to have a primary key unless we're a linking table
my $IS_LINKING_TABLE = 0;

# @link_fkeys holds the two linking fkey objects
my @link_fkeys;
unless (defined $PKEY) {
  # check if linking foreign key
  @link_fkeys = grep {$_->fkey_type() eq FKEY_LINK} @{$FKEYS{$module_name}};
  if (scalar @link_fkeys) {
    $IS_LINKING_TABLE = 1;
    print STDERR "  Processing linking table for: ", 
      join(' and ', map {$_->table_name} @link_fkeys), "\n";
  } else {
    die "No primary key located";
  }
}

# @non_pkey_attributes is used in creating the automatic POD documentation
my @non_pkey_attributes;
if ($IS_LINKING_TABLE) {
  @non_pkey_attributes = grep {$_ ne $link_fkeys[0]->fkey_name &&
				 $_ ne $link_fkeys[1]->fkey_name
			       } @attributes;
} else {
  @non_pkey_attributes = grep {$_ ne $PKEY} @attributes;
}

#
# process any OTM or LT fkeys. We'll use @lt_fkeys and @otm_fkeys later 
#   for filling in the code for fetch(), and for adding to the 
#   attributes() call. We need to keep them in separate arrays for now
#   because they are handled differently by fetch()

# we also build up a helper list of @fkey_fkeys, @link_fkeys and set
# flags for the existence of the different fkey types, so that later
# in the pod docs we can easily switch of docs that don't apply a
# given class
#

#####
##### This is where we need to add the OO fkey methods
#####
#####
#####

my @link_oo_fkeys;
my $HAS_LINK_FKEYS = 0;
my @otm_fkeys;
my $HAS_OTM_FKEYS = 0;
my @otm_link_fkeys;
my $HAS_OTM_LINK_FKEYS = 0;
my $lt_fkey_name;
my @otm_lt_fkeys;
my $HAS_LT_FKEY = 0;
my @lt_fkeys;
my $HAS_OTM_LT_FKEY = 0;
my @fkey_fkeys;
my $HAS_FKEY_FKEYS = 0;
my $HAS_MTO_FKEYS = 0;
my @mto_fkeys;
my $HAS_FOREIGN_KEYS = 0;
my ($TABLE2PKEY_KEY,$TABLE2PKEY_VALUE);
my @FKEY_LIST;
my %FKEY_OBJ2RAW;
for my $fkey (@{$FKEYS{$module_name}}) {
  my $ref;
  my @fkeys;
  my $new_name = $fkey->fkey_name();
  if ($new_name !~ /_fk$/) {
    $new_name .= '_obj';
  } else {
    $new_name =~ s/_fk$/_obj/;
  }
  $FKEY_OBJ2RAW{$new_name} = $fkey->fkey_name();
  if ($fkey->fkey_type() eq FKEY_OTM) {
    $HAS_OTM_FKEYS = 1;
    $HAS_FOREIGN_KEYS = 1;

    # we make a copy of the fkey for the new OO method.  We change the
    # name of the OO fkey by substiting '_obj' as a suffix instead of
    # the '_fk' suffix of the original. We set the type to be
    # FKEY_OTM_OO
    my $oo_fkey = $fkey->new();
    $oo_fkey->fkey_name($new_name);
    $oo_fkey->fkey_type(FKEY_OTM_OO);

    push(@fkeys,$oo_fkey,$fkey);
    $ref = \@otm_fkeys;
  } elsif ($fkey->fkey_type() eq FKEY_OTM_LT) {
    $HAS_OTM_LT_FKEY = 1;
    $HAS_FOREIGN_KEYS = 1;

    # we make a copy of the fkey for the new OO method.  We change the
    # name of the OO fkey by substiting '_obj' as a suffix instead of
    # the '_fk' suffix of the original. We set the type to be
    # FKEY_OTM_LT_OO
    my $oo_fkey = $fkey->new();
    $oo_fkey->fkey_name($new_name);
    $oo_fkey->fkey_type(FKEY_OTM_LT_OO);

    $ref = \@otm_lt_fkeys;
    push(@fkeys,$oo_fkey,$fkey);
  } elsif ($fkey->fkey_type() eq FKEY_OTM_LINK) {
    $HAS_OTM_LINK_FKEYS = 1;
    $HAS_FOREIGN_KEYS = 1;

    # we make a copy of the fkey for the new OO method.  We change the
    # name of the OO fkey by substiting '_obj' as a suffix instead of
    # the '_fk' suffix of the original. We set the type to be
    # FKEY_OTM_LINK_OO
    my $oo_fkey = $fkey->new();
    $oo_fkey->fkey_name($new_name);
    $oo_fkey->fkey_type(FKEY_OTM_LINK_OO);

    push(@fkeys,$oo_fkey,$fkey);
    $ref = \@otm_link_fkeys;
  } elsif ($fkey->fkey_type() eq FKEY_FKEY) {
    $HAS_FKEY_FKEYS = 1;
    $HAS_FOREIGN_KEYS = 1;

    # we change the name of the original fkey by substiting '_obj' as a
    # suffix instead of '_fk'. We change the type to be FKEY_OO
    $fkey->fkey_name($new_name);
    $fkey->fkey_type(FKEY_FKEY_OO);

    # this puts the new OO function on the fkey list
    # the old name is already in @attributes, but won't be listed 
    # as an fkey
    $ref = \@fkey_fkeys;
    push(@fkeys,$fkey);
  } elsif ($fkey->fkey_type() eq FKEY_LINK) {
    $HAS_LINK_FKEYS = 1;
    $HAS_FOREIGN_KEYS = 1;

    # we make a copy of the fkey for the new OO method.  We change the
    # name of the OO fkey by substiting '_obj' as a suffix instead of
    # the '_fk' suffix of the original. We set the type to be
    # FKEY_LINK_OO
    my $oo_fkey = $fkey->new();
    $oo_fkey->fkey_name($new_name);
    $oo_fkey->fkey_type(FKEY_LINK_OO);

    # we already have the link fkeys in @link_fkeys, so we create
    # another list just for the new ones, @link_oo_fkeys we do not
    # include $fkey, in the @FKEYS_LIST, as the raw LINK fkeys are
    # retrieved as normal column lookups
    push(@fkeys,$oo_fkey);
    $ref = \@link_oo_fkeys;
  } elsif ($fkey->fkey_type() eq FKEY_LT) {
    $HAS_LT_FKEY = 1;
    $HAS_FOREIGN_KEYS = 1;

    # BAD MOJO: this needs to go away, so that get_matrix() can
    # by used by all OTM fkeys
    $lt_fkey_name = $fkey->fkey_name();

    # we change the name of the original fkey by substiting '_obj' as a
    # suffix instead of '_fk'. We change the type to be FKEY_LT_OO
    $fkey->fkey_name($new_name);
    $fkey->fkey_type(FKEY_LT_OO);

    # this puts the new OO function on the fkey list
    # the old name is already in @attributes, but won't be listed 
    # as an fkey
    $ref = \@lt_fkeys;
    push(@fkeys,$fkey);

  } elsif ($fkey->fkey_type() eq FKEY_MTO) {
    $HAS_MTO_FKEYS = 1;
    $HAS_FOREIGN_KEYS = 1;

    # we change the name of the original fkey by substiting '_obj' as a
    # suffix instead of '_fk'. We change the type to be FKEY_MTO_OO
    $fkey->fkey_name($new_name);
    $fkey->fkey_type(FKEY_MTO_OO);

    # this puts the new OO function on the fkey list
    # the old name is already in @attributes, but won't be listed 
    # as an fkey
    $ref = \@mto_fkeys;
    push(@fkeys,$fkey);
  } else {
    # how did we get here???
    die "Fkey of unknown type: ", $fkey->fkey_type();
  }
  # add the fkey to a type specific list, and the general list
  push(@{$ref},@fkeys);
  push(@FKEY_LIST,@fkeys);
  @fkeys = ();			# empty out the list for the next fkey
}
close(IN);

#
# quote_list(@list)
#   returns a string with each value of @list quoted and comma separated
#
sub quote_list {
  return "\'" . join("\', \'",@_) . "\'";
}

# _qw is a string with each value quoted and comma separated
my $column_names_qw = quote_list(@attributes);

###
### I think there's a better way to do this, so that it can be
###  extended to any OTM fkeys as well 
###
# this will get used by get_matrix()
my $column_names_no_lt_qw;
if ($HAS_LT_FKEY) {
  my @tmp;
  foreach (@attributes) {
    push(@tmp,$_) unless $_ eq $lt_fkey_name;
  }
  $column_names_no_lt_qw = quote_list(@tmp);
}

#
# Ok. hold on to your seats. the rest of this code is perl
#   HERE statements of two types:
#     1) print OUT <<"EOT"; -- this prints out verbatim text
#          to the filehandle OUT *with* variable interpolation
#
#     2) print OUT <<'EOT'; -- this prints out verbatim text
#          to the filehandle OUT *without* variable interpolation
#
#   between the HERE statements are sprinkled bits of loop and
#   conditional code to customize each module a little bit
#   
# A colorizing editor like XEmacs and cperl-mode is highly recommended
# for viewing the rest of the file.
#

# start a section with variable expansion *enabled*
print OUT <<"EOT";
##############################
#
# $full_module_name
#
# created on $time by $0 $arguments
#
# cvs id: \$Id: create_genex_class.pl,v 1.31 2001/02/06 19:06:24 jes Exp $ 
#
##############################
package $full_module_name;

use strict;
use POSIX 'strftime';
use Carp;
use DBI;
use IO::File;
use Bio::Genex::DBUtils qw(:CREATE
		      :ASSERT
		      fetch_last_id
		     );
# import the fkey constants and undefined
use Bio::Genex qw(undefined);
use Bio::Genex::Fkey qw(:FKEY);

EOT

#
# Interlude to add any extra 'use' pragmas for fkeys that we have.
#

foreach my $fkey (@FKEY_LIST) {
#  print OUT 'use Bio::Genex::' . ucfirst($fkey->table_name()), ";\n";
}


# start a section with variable expansion *enabled*
print OUT <<"EOT";
use Class::ObjectTemplate::DB 0.21;

use vars qw(\$VERSION \@ISA \@EXPORT \@EXPORT_OK \$FKEYS \$COLUMN2NAME \$NAME2COLUMN \$COLUMN_NAMES \%_CACHE \$USE_CACHE \$LIMIT \$FKEY_OBJ2RAW \$TABLE2PKEY);

require Exporter;

\@ISA = qw(Class::ObjectTemplate::DB Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
\@EXPORT_OK = qw();

BEGIN {
EOT

#
# Interlude to add any class variables
#

# we use Data::Dumper to print out the variables in one swoop
# setting Terse=1 means it doesn't print out variable names
$Data::Dumper::Terse = 1;

print OUT '  $USE_CACHE = 1;', "\n\n";

print OUT '  %_CACHE = ();', "\n\n";

print OUT '  $COLUMN_NAMES = ', Data::Dumper->Dump([\@attributes]), ";\n";

# we make an anonymous hash ref were the keys are the fkey names
# and the values are the Bio::Genex::Fkey objects by iterating over
# the list of Fkey objects in @FKEY_LIST using map();
my $fkeys_ref = { map {$_->fkey_name(), $_} @FKEY_LIST };

# now use Data::Dumper to print out the entire hash ref
print OUT ' $FKEYS = ', Data::Dumper->Dump([$fkeys_ref]), ";\n";

my $LINK1_FKEY_NAME;
my $LINK2_FKEY_NAME;
if (scalar @link_fkeys) {
  # The %TABLE2PKEY hash tells us what column of the linking table
  # should act as the primary key, when called by a given class.
  #
  # For example, the following linking table:
  #    'GroupLink' => HASH(0x1ad6d28)
  #     'gs_fk' => HASH(0x1906234)
  #        'column_name' => 'gs_pk'
  #        'fkey_type' => 'LINKING_TABLE'
  #        'tablename' => 'GroupSec'
  #     'us_fk' => HASH(0x1ac3884)
  #        'column_name' => 'us_pk'
  #        'fkey_type' => 'LINKING_TABLE'
  #        'tablename' => 'UserSec'
  #
  # would have the following %TABLE2PKEY hash:
  #   $TABLE2PKEY{UserSec} = 'gs_fk';
  #   $TABLE2PKEY{GroupSec} = 'us_fk';
  #
  
  # we set these up for convenience
  my $fkey1 = $link_fkeys[0];
  my $fkey2 = $link_fkeys[1];
  $LINK1_FKEY_NAME = $fkey1->fkey_name();
  $LINK2_FKEY_NAME = $fkey2->fkey_name();

  # these are for the POD documentation later on
  $TABLE2PKEY_KEY = $fkey1->table_name();
  $TABLE2PKEY_VALUE = $fkey2->fkey_name();

  my $t2p_ref;
  $t2p_ref->{$fkey1->table_name} = $fkey2->fkey_name();
  $t2p_ref->{$fkey2->table_name} = $fkey1->fkey_name();
  # this is for the module file
  print OUT '  $TABLE2PKEY = ', Data::Dumper->Dump([$t2p_ref]), ";\n";
}
print OUT "\n";			# separate the sections from each other

# print out the %column2name and %name2column table
print OUT '  $COLUMN2NAME  = ', Data::Dumper->Dump([\%column2name]), ";\n";
print OUT '  $NAME2COLUMN  = ', Data::Dumper->Dump([\%name2column]), ";\n";
print OUT '  $FKEY_OBJ2RAW = ', Data::Dumper->Dump([\%FKEY_OBJ2RAW]), ";\n";
print OUT "}\n\n";		# end of BEGIN{}

#
# Now we set up the two attributes lists, @no_delayed_fetch, and @attr_list
#

# set up attributes where lookup is not enabled
my @no_delayed_fetch = ('fetched', 'fetch_all', 'fetched_attr', 'id');

# add the linking table specific methods 
push(@no_delayed_fetch,'pkey_link') if $IS_LINKING_TABLE;

# _qw is a string with each value quoted and comma separated
my $no_delayed_fetch_qw = quote_list(@no_delayed_fetch);

# set up attributes where lookup *is* enabled
my @attr_list = @attributes;

#
# each element of @otm_fkeys is a Bio::Genex::Fkey object, we only want 
#   the names of the fkeys, so we use map to iterate over each element
#   returning only the names, and push the result on @attr_list
#
if ($HAS_FKEY_FKEYS) {
  push(@attr_list, map {$_->fkey_name} @fkey_fkeys);
}
if ($HAS_OTM_FKEYS) {
  push(@attr_list, map {$_->fkey_name} @otm_fkeys);
}
if ($HAS_OTM_LINK_FKEYS) {
  push(@attr_list, map {$_->fkey_name} @otm_link_fkeys);
}
if ($HAS_LINK_FKEYS) {
  push(@attr_list, map {$_->fkey_name} @link_oo_fkeys);
}
if ($HAS_OTM_LT_FKEY) {
  push(@attr_list, map {$_->fkey_name} @otm_lt_fkeys);
}
if ($HAS_LT_FKEY) {
  push(@attr_list, map {$_->fkey_name} @lt_fkeys);
}
if ($HAS_MTO_FKEYS) {
  push(@attr_list, map {$_->fkey_name} @mto_fkeys);
}
# _qw is a string with each value quoted and comma separated
my $attr_list_qw = quote_list(@attr_list);

# start a section with variable expansion *enabled*
print OUT <<"EOT";

attributes (no_lookup=>[$no_delayed_fetch_qw], lookup=>[$attr_list_qw]);

sub table_name {return \'$module_name\';} # probably unnecessary

sub fkeys {return \$FKEYS;}

sub column2name {return \$COLUMN2NAME;}

sub name2column {return \$NAME2COLUMN;}

sub fkey_obj2raw {return \$FKEY_OBJ2RAW;}

sub column_names {return \$COLUMN_NAMES;}

EOT

if ($IS_LINKING_TABLE) {
  print OUT <<"EOT";
sub table2pkey { return \$TABLE2PKEY; }

sub linking_table { return 1; }

sub pkey_name {
  my \$self = shift;
  my \$name;
  
  # have we been called as a class method, or an instance method
  if (not ref(\$self)) {
    # class method invocation requires table name
    my \$ref_table = shift;
    die "${full_module_name}::pkey_name: Must specify a table argument" 
      unless defined \$ref_table;
    # just in case we're given a class name
    \$ref_table =~ s/Bio::Genex:://;
    \$name = \$TABLE2PKEY->{\$ref_table};
    die "${full_module_name}::pkey_name: table \$ref_table not in TABLE2PKEY" 
      unless defined \$name;
  } else {
    # instance method requires pkey_link
    \$name = \$self->get_attribute('pkey_link');
    die "$ {full_module_name}::pkey_name: must set the 'pkey_link' attribute for linking tables classes" unless defined \$name;
  }
  return \$name;
}
EOT
} else {
  print OUT "sub pkey_name {return \'$PKEY\';}\n\n";
  print OUT "sub linking_table {return 0;}\n";
}

if (scalar @controlled) {
  my $vocab_string = join(' ',@controlled);
  # start a section with *no* variable expansion
  print OUT <<"EOT";

sub get_terms {
  return map {\$_->term_string} shift->get_all_objects();
}
sub get_vocabs {
  return qw($vocab_string);
}
EOT
}

# start a section with variable expansion *enabled*
unless ($IS_LINKING_TABLE) {
  print OUT <<"EOT";
sub insert_db {
  my (\$self,\$dbh) = \@_;
  assert_dbh(\$dbh);

  # iterate over the fields and add them to the INSERT
  my \%values;
  foreach my \$col (\@{\$COLUMN_NAMES}) {
    no strict 'refs';

    # we don't want Bio::Genex::undefined() to get called
    next unless defined \$self->get_attribute(\$col);

    \$values{\$col} = \$self->\$col();
  }

  # don't store a primary key
  delete \$values{'$PKEY'};

  if (grep {\$_ eq 'last_updated'} \@{\$COLUMN_NAMES}) {
    # we set the 'last_updated' field ourselves
    my \$timeformat = '\%r \%A \%B \%d \%Y'; 
    \$values{last_updated} = strftime(\$timeformat, localtime);
  }

  # execute the INSERT
  my \$sql = create_insert_sql(\$dbh,'$module_name',\\\%values);
  \$dbh->do(\$sql);
  
  # on error
  if (\$dbh->err) {
    warn "$ {full_module_name}::insert_db: SQL=<\$sql>, DBI=<\$DBI::errstr>";
    return undef;
  }
  my \$pkey = fetch_last_id(\$dbh,'$module_name');
  \$self->id(\$pkey);
  \$self->$PKEY(\$pkey);
  return \$pkey;
}

sub update_db {
  my (\$self,\$dbh) = \@_;
  assert_dbh(\$dbh);
  die "$ {full_module_name}::update_db: object not in DB"
    unless defined \$self->id() && defined \$self->$PKEY();

  # we must pre-fetch all the attributes 
  \$self->fetch();

  # iterate over the fields and add them to the INSERT
  my \%values;
  foreach my \$col (\@{\$COLUMN_NAMES}) {
    no strict 'refs';

    # we don't want Bio::Genex::undefined() to get called
    next unless defined \$self->get_attribute(\$col);

    \$values{\$col} = \$self->\$col();
  }

  if (grep {\$_ eq 'last_updated'} \@{\$COLUMN_NAMES}) {
    # we set the 'last_updated' field ourselves
    my \$timeformat = '\%r \%A \%B \%d \%Y'; 
    \$values{last_updated} = strftime(\$timeformat, localtime);
  }

  # execute the UPDATE
  my \$WHERE = '$PKEY=' . \$dbh->quote(\$self->$PKEY());
  my \$sql = create_update_sql(\$dbh,
			      TABLE=>'$module_name',
			      SET=>\\\%values,
			      WHERE=>\$WHERE);
  \$dbh->do(\$sql);

  # on error
  if (\$dbh->err) {
    warn "$ {full_module_name}::update_db: SQL=<\$sql>, DBI=<\$DBI::errstr>";
    return undef;
  }
  return 1;
}
EOT
}


# start a section with *no* variable expansion
print OUT <<'EOT';
#
# a workhorse function for retrieving ALL objects of a class
#
sub get_all_objects {
  my ($class) = shift;
  my @objects;
  my $COLUMN2FETCH;
  my $VALUE2FETCH;
  my $pkey_name;
  my $has_args = 0;
EOT

if ($IS_LINKING_TABLE) {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

  # we are a linking table so the pkey_link must be set
  # that means the first element of \@ids must be the string
  # 'pkey_link' and the second must be the value
  die "$ {full_module_name}::get_objects: must set 'pkey_link' for linking class" 
    unless ref(\$_[0]) eq 'HASH' && exists \$_[0]->{pkey_link};
  {
    # we were called with an anonymous hash as the first parameter
    # grab it and parse the parameter => value pairs
    my \$hashref = shift;
    \$pkey_name = \$hashref->{pkey_link};
EOT

} else {
  # start a section with *no* variable expansion
  print OUT <<'EOT';
  $pkey_name = $class->pkey_name();
  if (ref($_[0]) eq 'HASH') {
    # we were called with an anonymous hash as the first parameter
    # grab it and parse the parameter => value pairs
    my $hashref = shift;
EOT
}

# start a section with variable expansion *enabled*
print OUT <<"EOT";
    \$has_args = 1;
    \$COLUMN2FETCH =  \$hashref->{column} if exists \$hashref->{column};
    \$VALUE2FETCH =  \$hashref->{value} if exists \$hashref->{value};
    die "$ {full_module_name}::get_all_objects: Must define both 'column' and 'value'" 
      if ((defined \$VALUE2FETCH) && not (defined \$COLUMN2FETCH)) || 
          ((defined \$COLUMN2FETCH) && not (defined \$VALUE2FETCH));
  }

  my \@ids;

  # using class methods seems indirect, but it deals
  # properly with inheritance
  my \$FROM = [\$class->table_name()];

  # we fetch *all* columns, so that we can populate the new objects
  my \$COLUMNS = ['*'];

  my \$dbh = Bio::Genex::current_connection();
  my \@args = (COLUMNS=>\$COLUMNS, FROM=>\$FROM);
  if (defined \$COLUMN2FETCH) {
    my \$where =  "\$COLUMN2FETCH = ". \$dbh->quote(\$VALUE2FETCH);
    push(\@args,WHERE=>\$where);
  }
  push(\@args,LIMIT=>\$LIMIT) if defined \$LIMIT;
  my \$sql = create_select_sql(\$dbh,\@args);
  my \$sth = \$dbh->prepare(\$sql) 
    or die "$ {full_module_name}::get_all_objects:\\nSQL=<\$sql>,\\nDBI=<\$DBI::errstr>";
  \$sth->execute() 
    or die "$ {full_module_name}::get_all_objects:\\nSQL=<\$sql>,\\nDBI=<\$DBI::errstr>";

  # if there were no objects, return. decide whether to return an 
  # empty list or an empty arrayref using wantarray
  unless (\$sth->rows()) {
    return () if wantarray;
    return []; # if not wantarray
  }

  # we use the 'NAME' attribute of the statement handle to get the
  # list of columns that were fetched.
  my \@column_names = \@{\$sth->{NAME}};
  my \$rows = \$sth->fetchall_arrayref();
  die "$ {full_module_name}::get_all_objects:\\nSQL=<\$sql>,\\nDBI=<\$DBI::errstr>" 
    if \$sth->err;
  foreach my \$col_ref (\@{\$rows}) {
    # we create a blank object, and populate it with data ourselves
    my \$obj = \$class->new();

    # %fetched_attrs is used to track which attributes have
    # already been retrieved from the DB, so that Bio::Genex::undefined
    # doesn't try to fetch them a second time if their value is undef
    my %fetched_attrs;
    for (my \$i=0;\$i < scalar \@column_names; \$i++) {
      no strict 'refs';
      my \$col = \$column_names[\$i];
      \$obj->\$col(\$col_ref->[\$i]);

      # record the column as fetched
      \$fetched_attrs{\$col}++;
    }
    # store the record of the fetched columns
    \$obj->fetched_attr(\\\%fetched_attrs);
    \$obj->fetched(1);

EOT
if ($IS_LINKING_TABLE) {
  # start a section with *no* variable expansion
  print OUT <<'EOT';
    # we are a linking table so the pkey_link attr must be set
    $obj->set_attribute('pkey_link',$pkey_name);

EOT
}
    # start a section with variable expansion *enabled
    print OUT <<'EOT';
    # now we set the id so that delayed-fetching will work for
    # the OO attributes
    $obj->id($obj->get_attribute("$pkey_name"));
    push(@objects,$obj);
  }
  $sth->finish();

  # decide whether to return a list or an arrayref using wantarray
  return @objects if wantarray;
  return \@objects; # if not wantarray
}

EOT

# start a section with variable expansion *enabled*
print OUT <<"EOT";
#
# a workhorse function for retrieving multiple objects of a class
#
sub get_objects {
  my (\$class) = shift;
  my \@objects;
EOT
if ($IS_LINKING_TABLE) {
  print OUT <<"EOT";		# start a section with variable expansion *enabled*
  my \$pkey_name;

  # we are a linking table so the pkey_link must be set
  # that means the first element of \@ids must be the string
  # 'pkey_link' and the second must be the value
  die "$ {full_module_name}::get_objects: must set 'pkey_link' for linking class" 
    unless (ref(\$_[0]) eq 'HASH') && exists \$_[0]->{pkey_link};
  if (ref(\$_[0]) eq 'HASH') {
    # we were called with an anonymous hash as the first parameter
    # grab it and parse the parameter => value pairs
    my \$hashref = shift;
    \$pkey_name = \$hashref->{pkey_link};
  }
EOT
} 

# start a section with variable expansion *enabled*
print OUT <<"EOT";
  if (ref(\$_[0]) eq 'HASH' || scalar \@_ == 0) {
    croak("$ {full_module_name}::get_objects called with no ID's, perhaps you meant to use $ {full_module_name}::get_all_objects\n");
  } 
  my \@ids = \@_;
  my \$obj;
  foreach (\@ids) {
    if (\$USE_CACHE && exists \$_CACHE{\$_}) {
	\$obj = \$_CACHE{\$_};	# use it if it's in the cache
    } else {
	my \@args = (id=>\$_);
EOT

if ($IS_LINKING_TABLE) {
  # start a section with *no* variable expansion
  print OUT <<'EOT';
    push(@args,'pkey_link'=>$pkey_name);
EOT
}

# start a section with *no* variable expansion
print OUT <<'EOT';
	$obj = $class->new(@args);

	# if the id was bad, $obj will be undefined
	next unless defined $obj;
	$_CACHE{$_} = $obj if $USE_CACHE; # stick it in the cache for later
    }
    push(@objects, $obj);
  }
  # decide whether to return a list or an arrayref using wantarray
  return @objects if wantarray;
  return \@objects; # if not wantarray
}

EOT

if ($HAS_LT_FKEY) {
  # Lookup table classes need to return a matrix of values

  # start a section with variable expansion *enabled*
  print OUT <<"EOT";
#
# Lookup table classes need the ability to return themselves as an
# array of hash refs.
#
sub get_matrix {
  my (\$class,\@args) = \@_;

  my \%args = (FROM=>['$module_name']);
  if (scalar \@args == 1 && ref(\$args[0]) ne 'ARRAY') {
    # fetch all spots from a single array, without restriction
   \$args{WHERE} = "$lt_fkey_name = '\$args[0]'";
   \$args{COLUMNS} = [$column_names_no_lt_qw];
                  
  } else {
    # fetch spots with restriction
    my \$WHERE;
    my \@column_names = \@{\$class->column_names()};
    foreach my \$arg (\@args) {
      die "Not an array ref: \$arg" unless ref(\$arg) eq 'ARRAY';

      # now check that the column is valid using a regexp
      die "Bad column name: \$arg->[0]" 
        unless grep {\$_ eq \$arg->[0]} \@column_names;

      \$WHERE .= ' AND ' if defined \$WHERE;
      my \$list = join(", ", \@{\$arg->[1]});
      \$WHERE .= " \$arg->[0] IN (\$list) ";
    }
    \$args{WHERE} = \$WHERE;
    \$args{COLUMNS} = [$column_names_qw];
  }

  \$args{LIMIT} = \$LIMIT if defined \$LIMIT;
  # create_select_sql() now needs a database handle
  my \$dbh = Bio::Genex::current_connection();
  my \$sql = create_select_sql(\$dbh,\%args);

  my \$sth = \$dbh->prepare(\$sql) || die "$ {full_module_name}::get_matrix: \$DBI::errstr";
  \$sth->execute() || die "$ {full_module_name}::get_matrix: \$DBI::errstr";

  # if we didn't retrieve any rows, return an empty arrayref
  return [] unless \$sth->rows();
  my \@objects;
  push(\@objects,\$args{COLUMNS}); # add a header for legibility

  while (my \@vals = \$sth->fetchrow_array()) {
    # we have to make the copy, otherwise we reuse the address
    die "$ {full_module_name}::get_matrix: \$DBI::errstr" if \$sth->err;
    push(\@objects,\\\@vals);
  }
  \$sth->finish();
  return \\\@objects;
}

EOT

} # end of get_matrix method for lookup table classes

# start a section with variable expansion *enabled*
print OUT <<"EOT";

# ObjectTemplate automagically creates a new() method for us 
# that method invokes \$self->initialize() after first setting all 
# parameters specified in invocation
sub initialize {
  my \$self = shift;

  # we only need to be concerned with caching and id verification
  # if the user has specified and 'id'.
  my \$id = \$self->get_attribute('id');
  if (defined \$id) {
    # 
    # executive decision: if it's in the cache, use it without
    # checking that the parameters are the same
    return \$_CACHE{\$id} if \$USE_CACHE && 
      defined \$id &&
      exists \$_CACHE{\$id};
  
    # 
    # The object is not in the cache, so now we check whether we've
    # been given a valid id
    #
EOT

if ($IS_LINKING_TABLE) {
# start a section with *no* variable expansion
print OUT <<"EOT";
    die "$ {full_module_name}::initialize: Must set 'pkey_link' when calling new() with an id" 
      unless defined \$self->get_attribute('pkey_link');
EOT
} 
# start a section with *no* variable expansion
print OUT <<"EOT";
    my \$pkey_name = \$self->pkey_name();
    my \$dbh = Bio::Genex::current_connection();
    my \$FROM = [\$self->table_name()];
    my \$COLUMNS = [\$pkey_name];
    my \@args = (COLUMNS=>\$COLUMNS, FROM=>\$FROM, 
  		WHERE=> \$pkey_name . " = '\$id'");
    my \$sql = create_select_sql(\$dbh,\@args);
    my \$count = scalar \@{\$dbh->selectall_arrayref(\$sql)};
    die "$ {full_module_name}::initialize: \$DBI::errstr" if \$dbh->err;
  
    # if there was a problem, return an error to new(), so that 
    # new will return undef to the calling function
    if (\$count < 1) {
      warn("$ {full_module_name}::initialize: no DB entries for id: \$id");
      return -1 unless \$count > 0;
    }
  }

  #
  # now that we know we have a valid id, we can resume initialization
  #

  # we need to initialize these for Bio::Genex::undefined() to work
  \$self->fetched(0);		# we have not retrieved data via fetch
  \$self->fetched_attr({});	# no attr's have been delayed_fetched

  # actually get the object's data if we've been told to
  if (defined \$self->get_attribute('fetch_all')) {
    die "Can\'t use 'fetch_all' without setting 'id'" unless defined \$id;
    \$self->fetch();
  }
}

sub fetch {
  my (\$self) = \@_;

  # recursion in this is bad
  return if \$self->fetched();

  # can't fetch without a primary key to lookup the data
  my \$pkey = \$self->get_attribute('id');
  die "Must define an id for fetch"  unless defined \$pkey;

  # we don't want to get into loops in Bio::Genex::undefined()
  \$self->fetched(1);

  my \$dbh = Bio::Genex::current_connection();

  # we make these method calls instead of hardcoding the values
  # for the purpose of inheritance
  assert_table_defined(\$dbh,\$self->table_name());
  my \$sql = create_select_sql(\$dbh,
                    COLUMNS=>[$column_names_qw],
                    FROM=>[\$self->table_name()],
                    WHERE=>\$self->pkey_name() . " = '\$pkey'",
                              );
  my \$sth = \$dbh->prepare(\$sql) || die "$ {full_module_name}::initialize: \$DBI::errstr";
  \$sth->execute() || die "$ {full_module_name}::initialize: \$DBI::errstr";

  # sanity check to see if bogus id
  my \$ref = \$sth->fetchrow_hashref();
  die "$module_name: ", \$self->pkey_name(), " \$pkey, not in DB"
    unless defined \$ref;

  while (my (\$key,\$val) = each \%{\$ref}) {
    # no use for storing undef, since all attributes 
    # start as undef
    next unless defined \$val;

    # we only want to set attributes that do not already exist
    # for example, we are called by update_db(), we don't want to force
    # users to call fetch() before modifying the object's attributes
    next if defined \$self->get_attribute(\$key);

    { # we use this to temporarily relax the strict pragma
      # to use symbolic references
      no strict 'refs';
      \$self->\$key(\$val);
    } # back to our regularily scheduled strictness
  }
  \$sth->finish();
}

EOT

my $LINKING = '';
$LINKING = 'linking' if $IS_LINKING_TABLE;

print OUT <<"EOT";

=head1 NAME

$full_module_name - Methods for processing data from the GeneX DB
$LINKING table: $module_name

=head1 SYNOPSIS

  use $full_module_name;

EOT
if ($IS_LINKING_TABLE) {
  print OUT <<"EOT";
  # instantiating a linking table instance
  my \$$module_name = $full_module_name->new(id=>47,pkey_link=>'$LINK1_FKEY_NAME');
  # or 
  my \$$module_name = $full_module_name->new(id=>47,pkey_link=>'$LINK2_FKEY_NAME');
EOT
} else {
print OUT <<"EOT";
  # instantiating an instance
  my \$$module_name = $full_module_name->new(id=>47);
EOT
}
print OUT <<"EOT";

  # retrieve data from the DB for all columns
  \$$module_name->fetch();

EOT
if ($IS_LINKING_TABLE) {
print OUT <<"EOT";
  # creating an instance, without pre-fetching all columns
  my \$$module_name = new $full_module_name(id=>47,
                                              'pkey_link'=>'$attributes[0]');

  # creating an instance with pre-fetched data
  my \$$module_name = new $full_module_name(id=>47, 
                                            'fetch_all'=>1,
                                            'pkey_link'=>'$attributes[0]');

  # retrieving multiple instances via primary keys
  my \@objects = $full_module_name->get_objects('pkey_link'=>'$attributes[0]',
                                                  23,57,98);

EOT
} else {
print OUT <<"EOT";
  # creating an instance, without pre-fetching all columns
  my \$$module_name = new $full_module_name(id=>47);

  # creating an instance with pre-fetched data
  my \$$module_name = new $full_module_name(id=>47, 'fetch_all'=>1);

  # retrieving multiple instances via primary keys
  my \@objects = $full_module_name->get_objects(23,57,98)

EOT
}
print OUT <<"EOT";

  # retrieving all instances from a table
  my \@objects = $full_module_name->get_all_objects();

  # retrieving the primary key for an object, generically
  my \$primary_key = \$$module_name->id();

EOT
if ($IS_LINKING_TABLE) {
  print OUT "  \# retrieving other DB column attributes\n";
  foreach (map {$_->fkey_name} @link_fkeys) {
    print OUT "  my \$${_}_val = \$$module_name->$_();\n";
    print OUT "  \$$module_name->$_(\$value);\n\n";
  }
} else {
  print OUT "  # or specifically\n";
  print OUT "  my \$${PKEY}_val = \$$module_name->$PKEY();\n\n";
  print OUT "  \# retreving other DB column attributes\n";
}

foreach (@non_pkey_attributes) {
  print OUT "  my \$$_", "_val = \$$module_name->$_();\n";
  print OUT "  \$$module_name->$_(\$value);\n\n";
}

print OUT <<"EOT";

=head1 DESCRIPTION

Each Genex class has a one to one correspondence with a GeneX DB table
of the same name (I<i.e.> the corresponding table for $full_module_name is
$module_name).

EOT
if ($IS_LINKING_TABLE) {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

B<NOTE>: Class $full_module_name is linking table class. This means
that it represents a table in the Genex DB which has no primary
key. Instead, there are two foreign keys that can be used to lookup a
value from the database. In $full_module_name, those two columns are
'$attributes[0]' and '$attributes[0]'. When an instance of
$full_module_name is instantiated, either via C<new()> or
C<get_objects(\@id_list)>, the 'C<pkey_link>' parameter must be
specified as one of these two values, otherwise, an error will result.

EOT
} 

# start a section with variable expansion *enabled*
print OUT <<"EOT";

Most applications will first create an instance of $full_module_name
and then fetch the data for the object from the DB by invoking
C<fetch()>. However, in cases where you may only be accessing a single
value from an object the built-in L<delayed fetch|/DELAYED_FETCH>
mechanism can be used. All objects are created without pre-fetching
any data from the DB. Whenever an attribute of the object is accessed
via a getter method, the data for that attribute will be fetched from
the DB if it has not already been. Delayed fetching happens
transparently without the user needing to enable or disable any
features. 

Since data is not be fetched from the DB I<until> it is accessed by
the calling application, it could presumably save a lot of access time
for large complicated objects when only a few attribute values are
needed.

=head1 ATTRIBUTES

There are three different types of attributes which instances of
$full_module_name can access: I<raw> foreign key attributes,
Obect-Oriented foreign key attributes, and simple column attributes.

=over 4 

=item Raw Foreign Keys Attributes

=item Object Oriented Foreign Key Attributes

This mode presents foreign key attributes in a special way, with all
non-foreign key attributes presented normally. Foreign keys are first
retrieved from the DB, and then objects of the appropriate classes are
created and stored in slots. This mode is useful for applications that
want to process information from the DB because it automates looking
up information.

Specifying the 'C<recursive_fetch>' parameter when calling C<new()>,
modifies the behavior of this mode. The value given specifies the
number of levels deep that fetch will be invoked on sub-objects
created.

=item Simple Column Attributes

=back



=head1 CLASS VARIABLES

Class $full_module_name defines the following utility variables for assisting
programmers to access the $module_name table.

=over 4

=item \$$ {full_module_name}::LIMIT

If defined, \$LIMIT will set a limit on any select statements that can
return multiple instances of this class (for example C<get_objects()>
or any call to a C<ONE_TO_MANY> or C<LOOKUP_TABLE> foreign key
accessor method).


=item \$$ {full_module_name}::USE_CACHE

This variable controls whether the class will cache any objects
created in calls to C<new()>. Objects are cached by primary key. The
caching is very simple, and no effort is made to track whether
different invocations of C<new()> are being made for an object with
the same primary key value, but with different options set. If you
desire to reinstantiate an object with a different set of parameters,
you would need to undefine C<\$USE_CACHE> first.


=back


B<WARNING>: variables other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

=head1 DELAYED FETCH

It is possible to retrieve only the subset of attributes one chooses
by simply creating an object instance and then calling the appropriate
getter function. The object will automatically fetch the value from
the DB when requested. This can potentially save time for large
complicated objects. This triggers a separate DB query for each
attribute that is accessed, whereas calling C<fetch()> will retrieve
all fields of the object with a single query.

For example:

  my \$$module_name = $full_module_name->new(id=>47);
  my \$val = \$$module_name->$attributes[0]();

The attribute\'s value is then cached in the object so any further calls
to that attribute\'s getter method do not trigger a DB query.

B<NOTE>: Methods may still return C<undef> if their value in
the DB is C<NULL>.


=head1 CLASS METHODS

The following methods can all be called without first having an
instance of the class via the $full_module_name->methodname() syntax.

=over 4

=item new(%args)

new() accepts the following arguments:

=over 4

=item id 

Numeric or string value. The value of the primary key for looking up
the object in the DB.

EOT

if ($IS_LINKING_TABLE) {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

=item pkey_link

For linking tables this specifies which of the two possible values
should be used as the primary key to fetch an instance from the
DB. For class $full_module_name, 'C<pkey_link>' can be either 'C<$LINK1_FKEY_NAME>' or 'C<$LINK2_FKEY_NAME>'.

=back


=item table2pkey()

For linking table classes, this method returns a hash table (not a
hashref) that defines the fkey access map. Linking tables have no
class-wide primary key, instead the column which is used to fetch rows
from the DB is determined on a per-instance basis depending on which
of the two linked-to tables is accessing the data. For example, in
$full_module_name if a method in class C<$TABLE2PKEY_KEY> invokes its
foreign key accessor function, the column '$TABLE2PKEY_VALUE' will be
used to fetch values from the DB.

=item linking_table()

Used by generic functions to determine if a specified class is a
linking table class. For $full_module_name it returns 1, since it I<is>
a linking table class.

EOT

#
# pkey_name() is an instance method of linking table classes
#

} else {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";
=back

=item linking_table()

Used by generic functions to determine if a specified class is a
linking table class. For $full_module_name it returns 0, since it is
I<not> a linking table class.

=item pkey_name()

This method returns the name of the column which is used as the
primary key for this DB table. This method only exists for non-linking
table classes, and for $full_module_name it returns the value '$PKEY';

EOT

}

# start a section with variable expansion *enabled*
print OUT <<"EOT";

=item table_name()

Returns the name of the DB table represented by this class. For
$full_module_name it returns '$module_name';

=item column2name()

This method returns a hashref that translates DB column names into
human readable format.

=item name2column()

This method returns a hashref that is a reverse lookup table to
translate the human readable version of a DB column name back into the
column_name. This is useful for preparing table output in CGI scripts:

EOT
# start a section with *no* variable expansion
print OUT <<'EOT';

    %column2name = %{$class->column2name()};
    if (exists $column2name{$_}) {
      push(@column_copy,$column2name{$_});
    }
    
    # now that we've translated the names, we sort them
    @column_copy = sort @column_copy;
    
    # make a header element. 
    push(@rows,th(\@column_copy));

EOT
# start a section with variable expansion *enabled*
print OUT <<"EOT";

=item fkeys()

This method returns a hashref that holds all the foreign key entries
for the $module_name table.

=item column_names()

This method returns an array ref which holds the names of all the
columns in table $module_name.

EOT
# start a section with *no* variable expansion
print OUT <<'EOT';

    # first retrieve the data from the DB
    $object = $full_module_name->new(id=>$id);
    $object->fetch();

    # now extract the data from the object
    foreach (@{$class->column_names}) {
    # we use this to temporarily relax the strict pragma
    # to use symbolic references
      no strict 'refs';
      $tmp_values{$_} = $object->$_;

    # back to our regularily scheduled strictness
    }

EOT
if ($HAS_LT_FKEY) {
  # start a section with *no* variable expansion
  print OUT <<'EOT';

=item get_matrix($id)

=item get_matrix([$col_name=>[@allowed_list], [$other_col=>[@list]]])

For efficiency reasons, lookup table classes, like $full_module_name
need to be able to return their data in a matrix of values, and not a
list of objects. 

The simple form is called with a single parameter, $id, that specifies
the the value of the C<LOOKUP_TABLE> foreign key to use in DB query.

The more complex interface allows a user to restrict the values
returned by $column_names and a @list of allowed values that that
column may have. Multiple $column_name/@list pairs may be specified
and the restrictions will all be AND\'ed together in the SQL WHERE
clause.


EOT
}

if ($IS_LINKING_TABLE) {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

=item get_objects({pkey_link=>'$attributes[0]'}, \@id_list)

=item get_all_objects()

=item get_objects({column=>'col_name',value=>'val'})

This method is used to retrieve multiple instances of class
$full_module_name simultaneously. For linking tables, there are three
different ways to invoke this method.

By passing in an C<\@id_list>, get_objects() uses each element of the
list as a primary key for the $module_name table and returns a single
instance for each entry. This form of the method requires a hash
reference as the first argument. The hash must have the 'C<pkey_link>'
key defined.

B<WARNING>: Passing incorrect id values to C<get_objects()> will cause
a warning from C<$ {full_module_name}::initialize()>. Objects will be
created for other correct id values in the list.

B<ERROR>: When using the \@id_list form of this method with a linking
table, the 'C<pkey_list>' attribute B<must> be specified, otherwise an
error will result. This is because linking tables have two possible
columns to lookup from.

By passing a hash reference that contains the 'column' and 'name'
keys, the method will return all objects from the DB whose that have
the specified value in the specified column.

B<NOTE>: When passing a hash reference with the 'column' and 'value'
keys specified, it is not necessary to specify the 'C<pkey_link>'
attribute.

EOT

} else {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

=item insert_db(\$dbh)

This method inserts the data for the object into the database
specified by the DB handle \$dbh. To use this method, create a blank
object with C<new()>, set the attributes that you want, and then call
C<insert_db()>.

  my \$dbh = Bio::Genex::current_connection(USER=>\$SU_USERNAME,
                                      PASSWORD=>\$SU_PASSWORD);
  my $module_name = $full_module_name->new();
  $module_name->$attributes[1]('some_value');
  $module_name->insert_db(\$dbh);

B<NOTE:> You must log into the DB with a user/password that has INSERT
priveleges in the DB, otherwise you will get a DBI error.

B<WARNING:> C<fetch()> will I<not> be called, so if you are using this
method to insert a copy of an existing DB object, then it is up to you
to call C<fetch()>, otherwise, only the attributes that are currently
set in the object will be inserted.

=item update_db(\$dbh)

This method update the data for an object already in the database
specified by the DB handle \$dbh. To use this method, fetch an
object from the DB, change the attributes that you want, and then call
C<update_db()>.

  my \$dbh = Bio::Genex::current_connection(USER=>\$SU_USERNAME,
                                      PASSWORD=>\$SU_PASSWORD);
  my $module_name = $full_module_name->new(id=>43);
  $module_name->$attributes[1]('some_value');
  $module_name->update_db(\$dbh);

B<NOTE:> You must log into the DB with a user/password that has INSERT
priveleges in the DB, otherwise you will get a DBI error.

B<NOTE:> Any modification of the primary key value will be discarded
('$attributes[0]' for module $full_module_name).

=item get_objects(\@id_list)

=item get_all_objects()

=item get_objects({column=>'col_name',value=>'val'})

This method is used to retrieve multiple instances of class $full_module_name
simultaneously. There are three different ways to invoke this method.

By passing in an C<\@id_list>, get_objects() uses each element of the
list as a primary key for the $module_name table and returns a single
instance for each entry.

B<WARNING>: Passing incorrect id values to C<get_objects()> will cause
a warning from C<$ {full_module_name}::initialize()>. Objects will be
created for other correct id values in the list.

C<get_all_objects()> returns an instance for every entry in the table.

By passing an anonymous hash reference that contains the 'column' and
'name' keys, the method will return all objects from the DB whose that
have the specified value in the specified column.

EOT

}
# start a section with variable expansion *enabled*
print OUT <<"EOT";

=back



B<NOTE>: All objects must have the 'id' parameter set before attempting
to use C<fetch()> or any of the objects getter functions.

=head1 INSTANCE METHODS

The following methods can only be called by first having valid
instance of class $full_module_name.

=over 4


=item fetch()

This method triggers a DB query to retrieve B<ALL> columns from the DB
associated with this object.

EOT


# start a section with *no* variable expansion
print OUT <<'EOT';

=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

EOT

if ($HAS_FOREIGN_KEYS) {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

=head1 FOREIGN KEY ACCESSOR METHODS

There are two major categories of foreign key accessor methods:
I<Object Oriented> foreign key methods, and I<raw> foreign key
methods. 

Each foreign key column in the table is represented by B<two> methods,
one OO method and one raw method. The raw method enables fethcing the
exact numeric or string values stored in the DB. The OO method creates
objects of the class the fkey column refers to. The idea is that if
only the numeric fkey value is desired, the raw fkey method can be
used. If it is necessary to get attributes from the table referred to
by the fkey column, then the OO method should be invoked, and the
necessary methods on that object can be queried.

The names of the raw fkey methods is the same as the fkey columns in
the DB table they represent (all fkey columns end in the suffix
'_fk'). The OO methods have the same names as the column they
represent, with the difference that they have the suffix '_obj'
instead of '_fk'.

So for example, in class Bio::Genex::ArrayMeasurement the
'C<primary_es_fk>' column is represented by two methods, the raw
method C<primary_es_fk()>, and the OO method C<primary_es_obj>.

The following foreign key accessors are defined for class
$full_module_name:

=over 4

EOT

  foreach my $fkey (@FKEY_LIST) {
    next if $fkey->fkey_name() =~ /_obj$/;
    my $fkey_name = $fkey->fkey_name();
    my $oo_fkey_name = $fkey->fkey_name();
    $oo_fkey_name =~ s/_fk$/_obj/;
    my $fkey_type = $fkey->fkey_type();
    my $table_name = $fkey->table_name();
    my $class = "Bio::Genex::$table_name";

    if ($fkey_type eq FKEY_OTM ||
	$fkey_type eq FKEY_OTM_LINK ||
	$fkey_type eq FKEY_OTM_LT
       ) {
      # start a section with variable expansion *enabled*
      print OUT <<"EOT";

=item \@id_list = $fkey_name()

=item \@obj_list = $oo_fkey_name()

This is an attribute of type $fkey_type and refers to class
L<$class>. The raw accessor method, C<$fkey_name()> returns a list of
foreign key ids. The OO accessor method, C<$oo_fkey_name()> returns a
list of objects of class $class.

EOT
    } else {
      # start a section with variable expansion *enabled*
      print OUT <<"EOT";

=item \$id = $fkey_name()

=item \$obj = $oo_fkey_name()

This is an attribute of type $fkey_type and refers to class
L<$full_module_name>. The raw accessor method, C<$fkey_name()>
returns a single foreign key id. The OO accessor method,
C<$oo_fkey_name()> returns a single object of class $class.

EOT
    }
  }

  # start a section with *no* variable expansion
  print OUT <<'EOT';

=back



Every foreign key in a DB table belongs to a certain class of foreign
keys. Each type of foreign key confers a different behavior on the
class that contains it. The classifications used in Genex.pm are:

=over 4

=item *

MANY_TO_ONE

If a class contains a foreign key of this type it will not be visible
to the API of that class, but instead it confers a special method to
the class that it references. 

For example, the Chromosome table has a MANY_TO_ONE foreign key,
spc_fk, that refers to the species table. Class L<Bio::Genex::Chromosome>, has
it\'s normal C<spc_fk()> attribute method, but no special foreign key
accessor method. However, class L<Bio::Genex::Species> is given a special
foreign key accessor method, C<chromosome_fk()> of type
ONE_TO_MANY. When invoked, this method returns a list of objects of
class L<Bio::Genex::Species>.

=item *

ONE_TO_MANY

The inverse of type MANY_TO_ONE. It is not an attribute inherent to a
given foreign key in any DB table, but instead is created by the
existence of a MANY_TO_ONE foreign key in another table. See the above
discussion about MANY_TO_ONE foreign keys.

=item *

LOOKUP_TABLE

This type of key is similar to type ONE_TO_MANY. However, However the
API will I<never> retrieve an object of this type. Instead it
retrieves a matrix of values, that represent the list of objects. It
is used in only two places in the API: L<Bio::Genex::ArrayMeasurement> and
L<Bio::Genex::ArrayLayout> classes with the C<am_spots()> and C<al_spots()>
accessor functions.

=item *

LINKING_TABLE

Foreign keys of this type appear in tables without primary keys. The
foreign keys are each of type LINKING_TABLE, and when invoked return
an object of the class referred to by the foreign key.

=item *

FKEY

A generic foreign key with no special properties. When invoked it returns
an object of the class referred to by the foreign key.

=back



EOT

}

# start a section with variable expansion *enabled*
print OUT <<"EOT";

=head1 ATTRIBUTE METHODS

These are the setter and getter methods for attributes in class
$full_module_name.

B<NOTE>: To use the getter methods, you may either invoke the
C<fetch()> method to retrieve all the values for an object, or else
rely on L<delayed fetching|/DELAYED_FETCH> to retrieve the attributes
as needed.

=over 4

EOT
if ($IS_LINKING_TABLE) {
  print OUT <<"EOT";

=item id()

C<id()> is a special attribute method that is common to all the Genex
classes. This method returns the primary key of the given
instance. Class $full_module_name is a linking table and therefore it
can I<two> possible columns that represent the 'id'
('C<$LINK1_FKEY_NAME>' and 'C<$LINK2_FKEY_NAME>'). When an instance of
class $full_module_name is created using either C<new()> or
C<get_objects(\@id_list)> the 'C<pkey_link>' attribute must specified
as one of the two possible values.

The C<id()> method can be useful in writing generic methods because it
avoids having to know the name of the primary key column.

=item $attributes[0]()

=item $attributes[0](\$value)

Methods for the $attributes[0] attribute. This attribute is the first
possible value for the 'C<pkey_link>' attribute at object creation
time.

=item $attributes[1]()

=item $attributes[1](\$value)

Methods for the $attributes[1] attribute. This attribute is the second
possible value for the 'C<pkey_link>' attribute at object creation
time.

EOT

} else {
  print OUT <<"EOT";

=item id()

C<id()> is a special attribute method that is common to all the Genex
classes. This method returns the primary key of the given instance
(and for class $full_module_name it is synonomous with the
C<$attributes[0]()>method). The C<id()> method can be useful in writing
generic methods because it avoids having to know the name of the
primary key column. 

=item $attributes[0]()

This is the primary key attribute for $full_module_name. It has no setter method. 

EOT

}
foreach (@non_pkey_attributes) {
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";

=item \$value = $_();

=item $_(\$value);

Methods for the $_ attribute.

EOT

}

# start a section with variable expansion *enabled*
print OUT <<"EOT";

=back



B<WARNING>: methods other than those listed here are for internal use
only and are subject to change without notice. Use them at your own
risk.

=head1 IMPLEMENTATION DETAILS

These classes are automatically generated by the
create_genex_classes.pl script.  Each class is a subclass of the
Class::ObjectTemplate::DB class (which is in turn a subclass of
Class::ObjectTemplate written by Sriram Srinivasan, described in
I<Advanced Perl Programming>, and modified by Jason
Stewart). ObjectTemplate implements automatic class creation in perl
(there exist other options such as C<Class::Struct> and
C<Class::MethodMaker> by Damian Conway) via an C<attributes()> method
call at class creation time.

=head1 BUGS

Please send bug reports to genex\@ncgr.org

=head1 LAST UPDATED

on $time by $0 $arguments

=head1 AUTHOR

Jason E. Stewart (jes\@ncgr.org)

=head1 SEE ALSO

perl(1).

=cut

EOT

foreach my $vocab_name (@controlled) {
  my $full_vocab_name = 'Bio::Genex::' . $vocab_name;

  # start a section with variable expansion *enabled*
  print OUT <<"EOT";
##############################
#
# $full_vocab_name
#
##############################
package $full_vocab_name;

use strict;
use vars qw(\@ISA);

\@ISA = qw(Bio::Genex::ControlledVocab);

sub table_name {return '$vocab_name';}

EOT

}

#
# End the module by returning a true value
#
print OUT "1;\n";
close(OUT);


#
# Print out a regression test
#
TEST: {
  my $file = $MODULES . "/t/$module_name.t";
  last if -f $file;

  open(OUT,">$file") or die "Couldn't open $file";

  my $uc_module_name = uc($module_name);
  # start a section with variable expansion *enabled*
  print OUT <<"EOT";
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Spotter.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { \$| = 1; print "1..2\\n"; }
END {print "not ok 1\\n" unless \$loaded;}
use Carp;
use lib 't';

# use TestDB qw(\$TEST_$uc_module_name \$TEST_$uc_module_name\_DESCRIPTION);
use $full_module_name;
use Bio::Genex;
\$loaded = 1;
my \$i = 1;
print "ok ", \$i++, "\\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# testing a random attribute
my \$p = $full_module_name->new();
\$p->description(555);
if (\$p->description() == 555){
  print "ok ", \$i++, "\\n";
} else {
  print "not ok ", \$i++, "\\n";
}

EOT

  #
  # We add more test for controlled vocabulary tables
  #
  foreach my $vocab_name (@controlled) {
    my $full_vocab_name = 'Bio::Genex::' . $vocab_name;

    # start a section with variable expansion *enabled*
    print OUT <<"EOT";
# testing a random attribute for $vocab_name
my \$p = $full_vocab_name->new();
\$p->description(555);
if (\$p->description() == 555){
  print "ok ", \$i++, "\\n";
} else {
  print "not ok ", \$i++, "\\n";
}

EOT
  }

  # start a section with variable expansion *enabled*
  print OUT <<"EOT";
__END__
# no info in DB yet


# test fetch
\$p = $full_module_name->new(id=>\$TEST_$uc_module_name);
\$p->fetch();
if (\$p->description() eq \$TEST_$uc_module_name\_DESCRIPTION){
  print "ok ", \$i++, "\\n";
} else {
  print "not ok ", \$i++, "\\n";
}

# test delayed_fetch
\$p = $full_module_name->new(id=>\$TEST_$uc_module_name);
if (not defined \$p->get_attribute('description')){
  print "ok ", \$i++, "\\n";
} else {
  print "not ok ", \$i++, "\\n";
}

if (\$p->description() eq \$TEST_$uc_module_name\_DESCRIPTION){
  print "ok ", \$i++, "\\n";
} else {
  print "not ok ", \$i++, "\\n";
}

EOT

  close(OUT);
}

1;
