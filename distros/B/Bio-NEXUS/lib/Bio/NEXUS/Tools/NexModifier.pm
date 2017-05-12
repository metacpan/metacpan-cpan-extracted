#!/usr/bin/perl -w
package Bio::NEXUS::Tools::NexModifier;
#######################################################################
# Bio::NEXUS::Tools::NexModifier.pm
#######################################################################
# Author: Chengzhi Liang, Weigang Qiu, Eugene Melamud, Peter Yang
# $Id: NexModifier.pm,v 1.2 2008/06/16 19:53:41 astoltzfus Exp $

# This script provides a set of functions for manipulating NEXUS files
# eg, select/exclude/rename OTUs, select character columns in OTUs
# select/exclude subtree, select/reroot tree

use strict;
use Pod::Usage;
use Carp;
use Data::Dumper;
use Bio::NEXUS; our $VERSION = $Bio::NEXUS::VERSION;

$Data::Dumper::Maxdepth=3;

=head2 new

 Title   : new
 Usage   : NA
 Function: create a new modifier object
 Returns : NA
 Args    : NA

=cut
sub new {
   my $self = shift;
   my $inp_data = $_[0];
   $inp_data = [@_] if (ref($inp_data) ne 'ARRAY') ;

   #print Dumper $inp_data;
   my $object_data = {
      'parameters' => [
	 'version' 			=> 1.0,	
	 'help' 			=> undef,	
	 'input_file'			=> 'test.nex',	
	 'output_file'			=> 'temp.nex',	
	 'rename_otus'			=> undef,	
	 'rename_otus_file'  	=> undef,	
	 'restrict_blocks'		=> undef,	
	 'restrict_otus'		=> undef,	
	 'restrict_subtree'		=> undef,	
	 'restrict_tree' 		=> undef,	
	 'restrict_column' 		=> undef,	
	 'restrict_set' 		=> undef,	
	 'exclude_blocks'		=> undef,	
	 'exclude_otus'			=> undef,	
	 'exclude_subtree' 		=> undef,	
	 'exclude_column' 		=> undef,	
	 'exclude_set' 			=> undef,	
	 'root'	 			=> undef,	
	 'addtree' 			=> undef,	
	 'make_sets_by_file'		=> undef,	
	 'make_sets_by_inode'		=> undef,	
	 'make_sets_by_otu'		=> undef,	
	 'make_sets_by_clade'		=> undef,	
	 'make_sets_by_union'		=> undef,	
	 'make_sets_by_difference'	=> undef,	
	 'make_sets_by_charstate'	=> undef,	
	 'make_sets_by_cladeconsensus'	=> undef,	
	 'make_sets_by_difference'	=> undef,	
	 'remove_sets' 			=> undef,	
     'list_sets' 			=> undef,	
     'rewrite' 			=> undef,	
     'return_nexus_obj'		=> 1,
     ],
     'data'=> {

     },
 };

 for (my $i=0; $i < scalar @$inp_data; $i = $i+2) {
     $inp_data->[$i] =~s/^-//;
 }
 
$object_data->{'parameters'} = $inp_data;
 
 bless($object_data,$self);
 return $object_data;

}

=head2 modify

 Title   : modify
 Usage   : NA
 Function: alter object
 Returns : NA
 Args    : NA

=cut

sub modify {
    my $self            = shift;
    my $options 	       = $self->{parameters};
    my %options_as_hash = @{$options};

   my $infile = $options_as_hash{input_file};

   unless ($infile) {die "Usage: nextool.pl <infile> [outfile] [command [options]]\n";}

   if ($infile eq "-v") {
      die "nextool.pl \$Revision: 1.2 $\n"; 
   }
   if ($infile eq "-h" || $infile eq '--help') {
      pod2usage(-exitval => 0, -verbose => 1);
   }

   my $outfile = $options_as_hash{output_file};

###if ($outfile eq "-") {$outfile = \*STDOUT;}
   if ($outfile =~ /(^-$|^STDOUT$)/) {$outfile = \*STDOUT;}
   my $command;
   my $value;

   my @test = @{$options};

   my $nexus = new Bio::NEXUS($infile);

   if (! $outfile || $options_as_hash{"rewrite"}) { 
       $nexus = new Bio::NEXUS($infile, 1);
       $nexus->write($outfile||"temp.nex", 1);
       return $nexus;
   }
   #print Dumper $nexus;

   for(my $i=0; $i < scalar @test ; $i = $i+2 ) { 
       my $runtime_options = { $test[$i] => $test[$i+1] };
       #print "$test[$i], i=$i\n";

       ### Rename options
       $nexus = rename_otus_file($nexus,$runtime_options->{rename_otus_file} ) if $runtime_options->{rename_otus_file};
       $nexus = $nexus->rename_otus($runtime_options->{rename_otus}) if $runtime_options->{rename_otus};

       ### Restrict options
       $nexus = selectbyblock($nexus, $runtime_options->{restrict_blocks}) if $runtime_options->{restrict_blocks};
       $nexus = $nexus->select_otus($runtime_options->{restrict_otus}) if $runtime_options->{restrict_otus};
       $nexus = selectbyinode($nexus, $runtime_options->{restrict_subtree}) if $runtime_options->{restrict_subtree};
       $nexus = selectbytree($nexus, $runtime_options->{restrict_tree}) if $runtime_options->{restrict_tree};
       $nexus = selectbycolumn($nexus,1, $runtime_options->{restrict_column}) if $runtime_options->{restrict_column};
       $nexus = selectbysets($nexus,1, $runtime_options->{restrict_set}) if $runtime_options->{restrict_set};

      ### Exclude options
      $nexus = exclude_blocks($nexus, $runtime_options->{exclude_blocks}) if $runtime_options->{exclude_blocks};
      $nexus = $nexus->exclude_otus($runtime_options->{exclude_otus}) if $runtime_options->{exclude_otus};
      $nexus = exclude_subtree($nexus, $runtime_options->{exclude_subtree}) if $runtime_options->{exclude_subtree};
      $nexus = selectbycolumn($nexus,0, $runtime_options->{exclude_column}) if $runtime_options->{exclude_column};
      $nexus = selectbysets($nexus,0, $runtime_options->{exclude_set}) if $runtime_options->{exclude_set};

      ### Reroot options
      $nexus = reroottree($nexus, $runtime_options->{reroottree}) if $runtime_options->{reroottree};

      ### Addtree options
      &addtree($nexus,$runtime_options->{add_tree}) if $runtime_options->{addtree};

      ### Sets options
      $nexus = setsbyfile($nexus, $runtime_options->{make_sets_by_file}) if $runtime_options->{make_sets_by_file}; 
      $nexus = setsbyinode($nexus,$runtime_options->{make_sets_by_inode} ) if $runtime_options->{make_sets_by_inode}; 
      $nexus = setsbyotus($nexus, $runtime_options->{make_sets_by_otu}) if $runtime_options->{make_sets_by_otu}; 
      $nexus = setsbyclade($nexus, $runtime_options->{make_sets_by_clade}) if $runtime_options->{make_sets_by_clade}; 
      $nexus = setsbyunion($nexus, $runtime_options->{make_sets_by_union}) if $runtime_options->{make_sets_by_union}; 
      $nexus = setsbydifference($nexus, $runtime_options->{make_sets_by_difference}) if $runtime_options->{make_sets_by_difference};
      $nexus = setsbycharstate($nexus,$runtime_options->{make_sets_by_charstate}) if $runtime_options->{make_sets_by_charstate}; 
      $nexus = setsbycladeconsensus($nexus,$runtime_options->{make_sets_by_cladeconsensus} ) if $runtime_options->{make_sets_by_cladeconsensus}; 
      #die "Expecting command that looks like 'makesets <bymode> <arguments>', where bymode is one of: file, inode, otu, clade, union, difference, charstate, cladeconsensus\n";
      $nexus = removesets($nexus,$runtime_options->{remove_sets}) if $runtime_options->{remove_sets};
      $nexus = renamesets($nexus,$runtime_options->{rename_sets}) if $runtime_options->{rename_sets};
      if ($runtime_options->{listsets}) {
          file_overwrite_warning($infile, $outfile, 'listsets', 0);
          listsets($nexus, $outfile, $runtime_options->{listsets});
      }
      if ($runtime_options->{listsetnames}) {
          file_overwrite_warning($infile, $outfile,'listsetnames' , 0);
          listsetnames($nexus, $outfile);
      }
  }

  $nexus->write($outfile);
  return $nexus if $options_as_hash{return_nexus_obj};
}


######### SUBROUTINES #########################


=head2 rename_otus

 Title   : rename_otus
 Usage   : NA
 Function: assigns new labels to OTUs
 Returns : NA
 Args    : NA

=cut

sub rename_otus {
   my ($nexus, $transfile) = @_;
   open(FILE, "<$transfile") or die "ERROR: Can\'t open $transfile\n";
   my @lines = <FILE>;
   my $lines = "@lines";
   my %translation = (split(/\s+/, $lines));
   return $nexus->rename_otus(\%translation);
}

=head2 selectbyblock

 Title   : selectbyblock
 Usage   : NA
 Function: select a subset of blocks
 Returns : NA
 Args    : NA

=cut

sub selectbyblock {
   my ($nexus, @blocks) = @_;
   return $nexus->select_blocks(\@blocks);
}

=head2 selectbyotu

 Title   : selectbyotu
 Usage   : NA
 Function: select subset of OTUs by labels
 Returns : NA
 Args    : NA

=cut
#  
sub selectbyotu {
   my ($nexus, $mode, @args) = @_;
   die "need otu names" unless (@args);
   my @otus;
   if ($args[0] eq '-f') { # input from file
      my $file = $args[1];
      open(FILE, $file) or carp "File $file not found\n";
      my @lines = <FILE>;
      @otus = split /\s+/, "@lines";
      close(FILE);
   }
   else {   # input from command line separated by space
      my $list = join( " ", @args ); 
      $list = unquote( $list ); 
      $list =~ s/^\s+|\s+$//g; 
      @otus = split( /[,\s]\s*/, $list ); 
   }
   if ( $mode == 1 ) { # select mode 
      return $nexus->select_otus(\@otus); 
   }
   else { # exclude mode 
      return $nexus->exclude_otus(\@otus); 
   }
}

=head2 selectbytree

 Title   : selectbytree
 Usage   : NA
 Function: select a tree
 Returns : NA
 Args    : NA

=cut

sub selectbytree {
   my ($nexus, $treename) = @_;
   ($treename) or die "ERROR: Need to specify a tree to be selected\n";
   return $nexus->select_tree($treename);
}

=head2 selectbyinode

 Title   : selectbyinode
 Usage   : NA
 Function: select a subtree by specifying its root internal node
 Returns : NA
 Args    : NA

=cut
# 
sub selectbyinode {
   my ($nexus, $nodename, $treename) = @_;
   $nodename or die "ERROR: Need to specify an internal node for subtree\n";

   return $nexus->select_subtree($nodename, $treename);
}

=head2 selectbycolumn

 Title   : selectbycolumn
 Usage   : NA
 Function: select ($command=1) or exclude ($command=0) specified column list or file with list
 Returns : NA
 Args    : NA

=cut
# arguments (column numbers) can be of form: 
# 1) 1-3 4 5 6-10 or 1-3, 4  5, 6-10
# 2) -f <file name> contains numbers in format as examplified in 1)  
sub selectbycolumn {
   my ($nexus, $command, @args) = @_;
   my $args = "@args";
   $args =~ s/title\s*=\s*(\w+)//i;    
   my $title = $1;
#    my $block = $nexus->get_block("characters", $title);

   die "need column numbers" unless $args;

   my $columns;
   if ($args =~ /-f (\S+)/) { # input from file
      my $file = $1;
      $columns = do{ local(@ARGV, $/) = $file; <>};
      $columns =~ s/\n/ /g;
   }else {   # input from command line separated by comma or space
      $columns = $args;
   }

   my @columns = @{ &parse_number($columns) };
   if ($command) {
      return $nexus->select_chars(\@columns, $title);
   }else {
      return $nexus->exclude_chars(\@columns, $title);
   }
}

=head2 selectbysets

 Title   : selectbysets
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub selectbysets {
   my ($nexus, $mode, @setnames) = @_;    
   my @otus;
   die "Provide set names as arguments\n" unless (@setnames);
   for my $setname (@setnames) {
      push(@otus, @{ $nexus->get_block('sets')->get_taxset($setname) } );
   }

   if ( $mode == 1 ) { # "select" mode 
      return $nexus->select_otus(\@otus); 
   } else { # "exclude" mode 
      return $nexus->exclude_otus(\@otus); 
   }
}

=head2 parse_number

 Title   : parse_number
 Usage   : NA
 Function: parse numbers in format "1-3, 4 6 8-10"
 Returns : NA
 Args    : NA

=cut
# 
sub parse_number {
   my $s = unquote( shift );

   if (! $s =~ /^\s*(\d+(-\d+)?)([,\s]\s*\d+(-\d+)?)*\s*$/ ) { 
      die "Invalid number format.  Use 1 or 1-3 or 1, 3, 5-8 or 1 3 5 6-10.\n"; 
   } 
   $s =~ s/^\s+|\s+$//g;
   $s =~ s/,?\s+/,/g;  # use ',' as separator
   my @cols = split(/,/, $s);

   my @arr;
   foreach my $item (@cols) {
      if ($item =~ /-/) { # eg 1-3
	 $item =~ /([0-9]+)\s*-\s*([0-9]+)/;
	 for (my $i = $1; $i <= $2; $i++) { push ( @arr, $i-1 ); }
      } elsif ($item =~ /^\d+$/) { # eg 4
	 push ( @arr, $item-1 );
      } elsif ($item) {
	 die "non-number was used for column number\n";
      }
   }

   @arr = sort {$a<=>$b} @arr;
   return \@arr;
}

=head2 unquote

 Title   : unquote
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub unquote { 
   my $string = shift; 
   $string =~ s/^ *'(.*)' *$/$1/;
   $string =~ s/^ *"(.*)" *$/$1/;
   return( $string ); 
}

=head2 exclude_blocks

 Title   : exclude_blocks
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub exclude_blocks {
   my ($nexus, @blocks) = @_;
   return $nexus->exclude_blocks(\@blocks);
}

=head2 exclude_subtree

 Title   : exclude_subtree
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub exclude_subtree {
   my ($nexus, $subtree) = @_;
   return $nexus->exclude_subtree($subtree);
}

=head2 reroottree

 Title   : reroottree
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub reroottree {
   my ($nexus, $outgroup, $root_position, $treename) = @_;
   if ( $nexus->get_block('trees')->get_tree('$root_position') ) { #in case no root position is supplied, but a tree name is
      ($root_position, $treename) = (undef, $root_position);
   }
   return $nexus->reroot($outgroup, $root_position, $treename);
}

=head2 addtree

 Title   : addtree
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub addtree {
   my ($nexus,$treeFile,$treeName) = @_;

   if ( !$treeName ) { ($treeName = (split("/",$treeFile))[-1]) =~ s/(.*)\..*/$1/; }

   if ( -f $treeFile ) {
      open(TF,"<$treeFile") || warn("ERROR: could not open $treeFile. No tree data will appear in NEXUS file.");

      my ($treeString);
      while(<TF>) {
	 s/\s*//go;
	 $treeString .= $_;
      }

      close(TF);

      $treeString =~ s/(.*);$/$1/; #remove semicolon from end of $treeString, if there is one.

      #$treeString must be formatted like this in order to work w/ Bio::NEXUS::TreesBlock::new -
      #      tree  $treeName = $treeString
      #the following manipulations ensure we end up w/ such a string to pass to create_block
      $treeString =~ s/^tree(.*)$/$1/;
      unless ( $treeString =~ m/^$treeName=/ ) {
	 $treeString = $treeName . " = " . $treeString;
      }
      $treeString = "tree " . $treeString;

      print STDERR "tree string:\n$treeString\n";
      $nexus->add_block( $nexus->create_block('trees',$treeString, 1) );
   } else {
      die("Tree file: \"$treeFile\" not found or could not be read");
   }
}

=head2 setsbyfile

 Title   : setsbyfile
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbyfile {
   my ($nexus, @setfiles) = @_;
   my $sets;

   for my $setfile (@setfiles) {
      open (SF, "<$setfile") || die ("Could not open set file $setfile.\n\n");
      while (<SF>) {
	 chomp;
	 push (@{$$sets{$setfile}}, $_);
      }
      close (SF);
   }
   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 setsbyinode

 Title   : setsbyinode
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbyinode {
   my ($nexus, @inodenames) = @_;
   my $sets;

   for my $inodename (@inodenames) {
      unless ($nexus->get_block('trees')->get_tree()->find($inodename)) {
	 die "User-provided inode <$inodename> is not the name of an inode in this NEXUS file\nCommand aborted\n\n";
      }
      my $subtree = $nexus->select_subtree($inodename);
      my $otus = $subtree->get_otus();
      $$sets{$inodename} = $otus;
   }
   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 setsbyclade

 Title   : setsbyclade
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbyclade {
   my ($nexus, @clade_elements) = @_;
   my ($sets, $treename);# $treename is currently a dummy variable, but we should implement it

   unless (validate_otus($nexus, [@clade_elements])) {die "User-provided OTUs failed validation against TAXA Block\n\n"}

   while (scalar(@clade_elements) > 0) {
      my ($otu1, $otu2) = splice(@clade_elements, 0, 2);
      unless (defined $otu2) {die "You have supplied an odd number of OTU's.  This mode requires pairs.\n\n"}
      $otu1 = $nexus->get_block('trees')->get_tree($treename)->find($otu1);
      $otu2 = $nexus->get_block('trees')->get_tree($treename)->find($otu2);
      my $inode_name = $otu1 -> mrca($otu2, $treename) -> name();
      my $otus = $nexus->select_subtree($inode_name)->get_otus();
      $$sets{$inode_name} = $otus;
   }

   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 setsbyotus

 Title   : setsbyotus
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbyotus {
   my ($nexus, @otuargs) = @_;
   my $otuargs = join(" ", @otuargs);
   my $sets;

   my @setsandelements = $otuargs =~ /\s*([^=]+)\s*=\s*\[\s*([^\]]+)\s*\]/g;

   while (@setsandelements) {
      $$sets{shift(@setsandelements)} = [split(/\s/, splice(@setsandelements, 1, 1))];
   }

   my $validation = 1;
   for my $users_otus (values %$sets) {
      $validation = validate_otus($nexus, $users_otus);
   }

   unless ($validation == 1) {die "User-defined sets failed validation against TAXA Block\n\n"}

   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 setsbyunion

 Title   : setsbyunion
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbyunion {
   my ($nexus, @setargs) = @_;
   my $setargs = join(" ", @setargs);
   my $sets = $nexus -> get_block('sets') -> get_taxsets();

   my @setsandelements = $setargs =~ /\s*(\b[^=]+\b)\s*=\s*\[\s*([^\]]+)\s*\]/g;
   while (@setsandelements) {
      my ($newsetname, @subsets) = (shift(@setsandelements), split(/(?:\s+|\s*\+\s*)/, shift(@setsandelements)));
      my @otus;
      for my $subset (@subsets) {
	 push(@otus, @{$nexus -> get_block('sets') -> get_taxset($subset)});
      }
      $$sets{$newsetname} = [@otus];
   }

   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 setsbydifference

 Title   : setsbydifference
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbydifference {
   my ($nexus, @setargs) = @_;
   my $setargs = join(" ", @setargs);
   my $sets = $nexus -> get_block('sets') -> get_taxsets();
#    print Dumper ($sets);

   @setargs = $setargs =~ /\s*([^=\s]+)\s*=\s*\[\s*([^-\s\]]+)\s*-\s*([^-\s\]]+)\s*\]/g;
   my (@difference_set_names, @minuend_set_names, @subtrahend_set_names);
   while (@setargs) {
      push(@difference_set_names, shift (@setargs));
      push(@minuend_set_names, shift (@setargs));
      push(@subtrahend_set_names, shift (@setargs));
   }

   for (my $i = 0; $i < @difference_set_names; $i++) {
      $$sets{$difference_set_names[$i]} = [@{$$sets{$minuend_set_names[$i]}}];
      for (my $j = 0; $j < @{$$sets{ $difference_set_names[$i] }}; $j++ ) {
	 for my $subtrahendOTU ( @{$$sets{ $subtrahend_set_names[$i] }} ) {
	    if ( ${$$sets{ $difference_set_names[$i] }}[$j] eq $subtrahendOTU) {
	       splice ( @{$$sets{ $difference_set_names[$i] }}, $j, 1);
	    }
	 }
      }
   }

   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 setsbycharstate

 Title   : setsbycharstate
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbycharstate {
   my ($nexus, @char_args) = @_;
   my ($proposed_sets, $title) = &parse_charstate_args(@char_args);
   my ($sets, @column_labels);
   my $block = $nexus->get_block("characters", $title);

   my $character_labels = $block->get_charlabels;
   my $seq_length = $block->get_nchar;
   my %char_matrix = %{$block->get_otuset->get_otu_sequences};
   if ($character_labels && @$character_labels) { 
      @column_labels = @$character_labels; 
   } elsif ($seq_length) {
      for (1 .. $seq_length) {push @column_labels, $_;}
   }
   my %column_indices;
   for (my $i = 0; $i < @column_labels; $i++) {
      $column_indices{$column_labels[$i]} = $i;
   }
   foreach my $proposed_setname (keys %{$proposed_sets}){
      while (@{$$proposed_sets{$proposed_setname}} > 0 ) {
	 my ($column_label, $query_value) = splice(@{$$proposed_sets{$proposed_setname}}, 0, 2);
	 foreach my $otu (keys %char_matrix) {
	    my $locus_value = substr($char_matrix{$otu},$column_indices{$column_label},1);
	    if ($query_value =~ m/$locus_value/) {
	       push (@{$$sets{$proposed_setname}}, $otu);
	    }
	 }
      }
   }

   &add_or_create_set ($nexus, $sets);
   return $nexus;
}

=head2 parse_charstate_args

 Title   : parse_charstate_args
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub parse_charstate_args {
   my $char_args = join (" ", @_);
   $char_args =~ m/title\s*=\s*(\w+)/i;    
   my $title = $1;                                                # store the captured title name, if one was provided
   my $num_title_matches = $char_args =~ s/title\s*=\s*\w+//g;    # make sure the user only referred to one title (to prevent ambiguity)
   if ($num_title_matches > 1 ) {die ("Too many 'title' arguments--please reference only one Characters Block\n\n")}
   # the following line matches each set as defined by the user and stores it in the @proposed_sets array
   # basically, it looks for bracket pairs that look like foo[bar], 
   # which may or may not be preceded by a set name declaration ('set_name = ')
   my @proposed_sets = $char_args =~ m/(?:[-\w]+\s*=\s*)?\s*[-\w]+\s*\[[^\]]+\]\s*/g;
   my %proposed_sets;
   for my $proposed_set (@proposed_sets) {                     # for each of the matches made above
      my $set_name;
      if ($proposed_set =~ m/^\s*([^\s\[\]]+)\s*=/) {            # if a name declaration was matched
	 $set_name = $1;                                        # use that as the set name
	 $proposed_set =~ s/^\s*[^\s\[\]]+\s*=\s*//;            # then, get rid of that portion of the array element
      } else {                                                # otherwise, make up a unique set name by joining the column label and locus value(s)
	 $set_name = join("", ($proposed_set =~ m/[^"\s\[\]]/g));
      }
      my ($column_label, $locus_value);
      while ($proposed_set =~ m/[^"\s]/) {                    # as long as $proposed_set contains more than spaces and quotes
	 ($column_label) = $proposed_set =~ m/[^"\s\[]+/;    # match the column label
	 $proposed_set =~ m/\[([^\]]+)\]/;                    # and match the locus value(s)
	 $locus_value = $1;
	 $locus_value =~ s/[\s,]//g;                            # get rid of any spaces or commas the user may have separated the locus values with
	 push (@{$proposed_sets{$set_name}}, $column_label, $locus_value); # push the column label and locus value(s) onto this sets array in the set hash
	 $proposed_set =~ s/^[^\]]*\]//;                        # destroy the evidence
      }
   }
   return (\%proposed_sets, $title);
}

=head2 setsbycladeconsensus

 Title   : setsbycladeconsensus
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub setsbycladeconsensus {
   my ($nexus, @args) = @_;
   my $consensus_sets = {};
   my $treename;
   my $args = join(' ', @args);
   $args =~ m/title\s*=\s*(\w+)/i;
   my $title = $1;
   if ($title) {$args =~ s/\s*title\s*=\s*\w+\s*//i;}
   if ($args =~ /(\w+)/) {$treename = $1;}
   my $char_block = $nexus->get_block("characters", $title);
   my %otunames_sequences = %{$char_block->get_otuset->get_otu_sequences};
   my $tree = $nexus->get_block('trees')->get_tree($treename)->clone();
   my $rootnode = $tree->get_rootnode();
   &set_consensus_seqs($rootnode, \%otunames_sequences);
   ($rootnode, $consensus_sets) = &simplify_tree($rootnode, $consensus_sets);
   $tree->set_name("nonredundant" . $tree->name());
   $nexus->get_block('trees')->add_tree($tree);
   &add_or_create_set ($nexus, $consensus_sets);
   return $nexus;
}

=head2 set_consensus_seqs

 Title   : set_consensus_seqs
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub set_consensus_seqs {
   my ($node, $otus_seqs) = @_;
   my @children = @{ $node->children() };
   for my $child (@children) {
      if ( $child->is_otu() ) {
	 $child->set_seq(${$otus_seqs}{$child->name()});
	 if ( ! $node->get_seq() || ( $node->get_seq() eq $child->get_seq() ) ) {
	    $node->set_seq($child->get_seq());
	 } else {
	    $node->set_seq('NO_CONSENSUS');
	 }
      } else {
	 &set_consensus_seqs($child, $otus_seqs);
	 if ( ! $node->get_seq() || ( $node->get_seq() eq $child->get_seq() ) ) {
	    $node->set_seq($child->get_seq());
	 } else {
	    $node->set_seq('NO_CONSENSUS');
	 }
      }
   }
}

=head2 simplify_tree

 Title   : simplify_tree
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub simplify_tree {
   my ($node, $consensus_sets) = @_;
   my $setname;
   if ($node->get_seq() ne 'NO_CONSENSUS' && ! $node->is_otu() ) {
      my @otu_descendents = @{ $node->get_otus() };
      $setname = $otu_descendents[0]->name() . "_GROUP";
      ${ $consensus_sets }{$setname} = [];
      for my $descendent (@otu_descendents) {
	 push(@{${$consensus_sets }{$setname}}, $descendent->name());
      }
      my $newlength = $node->distance($otu_descendents[0]) + $node->length();
      my $parent = $node->get_parent();
      my $siblings = $node->get_siblings();
      $parent->set_children($siblings);
      $parent->adopt($otu_descendents[0],0);
      $otu_descendents[0]->set_length($newlength);
   } else {
      for my $child (@{ $node->children() }) {
	 simplify_tree($child, $consensus_sets);
      }
   }
   return ($node, $consensus_sets);
}

=head2 validate_otus

 Title   : validate_otus
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub validate_otus { #Verifies that user-specified OTU names are taxlabels in the TAXA block
   my ($nexus, $users_otus) = @_;
   my $validation = 1;
   for my $users_otu (@$users_otus) {
      unless (defined ($nexus->get_block('taxa')->is_taxon($users_otu, 1))) {
	 $validation = 0;
      }
   }
   return $validation;
}

=head2 add_or_create_set

 Title   : add_or_create_set
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub add_or_create_set {
   my ($nexus, $sets) = @_;
   my $setsblock;
   if ($nexus -> get_block('Sets')) {
      $nexus -> get_block('Sets') -> add_taxsets($sets);
   } else {
      $setsblock = Bio::NEXUS::SetsBlock -> new('Sets');
      $setsblock -> set_taxsets($sets);
      $nexus -> add_block($setsblock);
   }
   return $nexus;
}

=head2 removesets

 Title   : removesets
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub removesets {
   my ($nexus, @usersets) = @_;
   my $failure = 0;
   my $sets_to_remove;
   my $setsblock = get_setsblock_if_setsblock($nexus);
   my $taxsets = $setsblock->get_taxsets();
   unless (scalar(keys %$taxsets) > 0) {die "The SETS Block is already empty\n\n";}

   if ($usersets[0] =~ /^-p$/i) {
      shift @usersets;
      for my $userset (@usersets) {
	 my $match = 0;
	 TAXSET:        for my $taxset (keys %$taxsets) {
	    if ($taxset =~ /^$userset$/) {
	       push(@$sets_to_remove, $taxset);
	       $match = 1;
	       next TAXSET;
	    }
	 }
	 if ($match == 0) {
	    warn "<$userset> does not match any sets in this NEXUS file\n";
	    $failure = 1;
	 }
      }
   } else {
      for (my $i=0; $i < scalar(@usersets); $i++) {
	 if ($$taxsets{$usersets[$i]}) {
	    push (@$sets_to_remove, $usersets[$i]);
	 } else { 
	    warn "<$usersets[$i]> is not the name of a set in this NEXUS file.\n";
	    $failure = 1;
	 }
      }
   }
   die "Command aborted\n\n" if $failure == 1;
   $nexus->get_block('sets')->delete_taxsets(@$sets_to_remove);
   return $nexus;
}

=head2 swap_children

 Title   : swap_children
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub renamesets {
   my ($nexus, @old_and_new) = @_;
   my $setsblock = get_setsblock_if_setsblock($nexus);
   $setsblock->rename_taxsets(@old_and_new);
   return $nexus;
}

=head2 listsets

 Title   : listsets
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub listsets {
   my ($nexus, $outfile, @sets_to_list) = @_;
   my $setsblock = get_setsblock_if_setsblock($nexus);
   if (@sets_to_list > 0) {
      my $fh = open_filehandle($outfile);
      for (@sets_to_list) {
	 my @otus = @{ $setsblock->get_taxset($_) };
	 if (@otus == 0) {
	    warn("$_ = []    Possible error: Set is empty or does not exist\n\n");
	 } elsif (@otus > 0) {
	    print $fh "$_ = [@otus]\n\n";
	 }
      }
   } else {
      $setsblock->print_all_taxsets($outfile);
   }
}

=head2 listsetnames

 Title   : listsetnames
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub listsetnames {
   my ($nexus, $outfile) = @_;
   my $setsblock = get_setsblock_if_setsblock($nexus);
   my @setnames = @{ $setsblock->get_taxset_names() };
   my $fh = open_filehandle($outfile);
   print $fh "@setnames\n";
}

=head2 open_filehandle

 Title   : open_filehandle
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub open_filehandle {
   my ($fh) = @_;
   if ($fh eq "-" || $fh eq \*STDOUT) {return \*STDOUT}
   else {open(FH, ">$fh") || die "Could not open $fh for writing\n\n"}
   return \*FH;
}

=head2 get_setsblock_if_setsblock

 Title   : get_setsblock_if_setsblock
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub get_setsblock_if_setsblock {
   my ($nexus) = @_;
   my $setsblock;
   unless ($setsblock = $nexus->get_block('sets')){die "This NEXUS file does not contain a SETS Block\n\n"}
   return $setsblock;
}

=head2 file_overwrite_warning

 Title   : file_overwrite_warning
 Usage   : NA
 Function: NA
 Returns : NA
 Args    : NA

=cut
sub file_overwrite_warning {
   my ($infile, $outfile, $command, $silentmode) = @_;
   if ($silentmode == 1) {return 1}
   if ($infile eq $outfile) {
      warn("Do you really want to overwrite NEXUS file $infile with the $command output?\n");
      if (<STDIN> =~ /y/) {
	 return 1;
      } else { die("Command aborted\n\n")}
   } else { return 1;}
}

################# POD Documentation ##################

__END__

#################### START POD DOCUMENTATION ##########################

=head1 NAME

Bio::NEXUS::Tools::Modifier - NEXUS file content modifier ( exclude/select/rename options on OTUs).

=head1 SYNOPSIS

nextool.pl <input_file> [output_file] [COMMAND [arguments]]

if outfile is not specified, just read input file and output to temp.nex

Commands:

    rewrite
    rename_otus <translation_file>
    reroot <outgroup_node_name> [tree_name]
    select blocks <block1 block2 ...>
    select OTU <OTU_1 OTU_2 ...> or <-f filename>
    select tree <tree_name>
    select subtree <inode_number> [tree_name] 
    select column <columns> or <-f filename>
    exclude blocks <block1 block2 ...>
    exclude OTU <otu1 otu2 ...>
    exclude subtree <inode> [treename]
    exclude column <columns> or <-f filename>
    makesets byfile <file1> [file2 file3 ...]
    makesets byinode <inode1> [inode2 inode3 ...]
    makesets byclade <OTU1> <OTU2> [OTU3 OTU4 ...]
	Square brackets are required syntax in this command:
    makesets byotus <set1>=[<OTU1 OTU2 ...>] <set2>=[<OTU3 OTU4 ...>] ...
	Square brackets are required in this command:
    makesets byunion <set1>=[<setA + setB ...>] <set2>=[<setA + setC ...>] ...
	Square brackets are required in this command:
    makesets bydifference <set1>=[<setA - setB>] <set2>=[<setA - setC>] ...
	Square brackets around 'state' argument are required in this command:
    makesets bycharstate [title=char_block_title] [set1=]"<sequence_or_intron_position>[<state>]" [set2=...]
    makesets bycladeconsensus [title=char_block_title]
    removesets <set1 set2 ...>
    listsets [set1 set2 ...]
    listsetnames
    renamesets oldname1 newname1 [oldname2 newname2 ...]


=head1 COMMANDS

=head2 rewrite

Writes the contents of <input_file> to <output_file>.  This is used to standardize the 
format of the file.  this is the default program action if <outfile> is not specified, the output file will be temp.nex

=head2 rename_otus <translation_file>

Renames OTUs in taxa, characters and trees blocks according to translation_file. Each line of translation_file contains the old name, separated by whitespace, then the new name.

=head2 reroot <outgroup_node_name> [tree_name]

reroot the tree of tree_name (optional-- the first tree in trees block if not specified) with outgroup_node_name as the new outgroup

=head2 select blocks <block1 block2 ...>

Select block given in list

=head2 select OTU <OTU_1 OTU_2 ...> or <-f filename>

Selects OTUs given in list. Changes taxa block, characters block and trees block.

=head2 select tree <tree_name>

Selects one tree given the tree name. Changes taxa/characters blocks to match.

=head2 select subtree <inode_number> [tree_name] 

Selects subtree given the tree name and the internal node number. Changes taxa/characters blocks to match.

=head2 select column <columns> or <-f filename>

Selects a number of columns from character lists to get a new set of character lists (for a new Bio::NEXUS file). eg, "1-3, 5 8, 10-15" (comma or space can be used to separate numbers)

=head2 exclude blocks <block1 block2 ...>

Remove blocks from file

=head2 exclude OTU <otu1 otu2 ...>

Remove OTUs from file

=head2 exclude subtree <inode> [treename]

Remove subtree rooted with 'inode' in 'treename' or the first tree if 'treename' is not specified

=head2 exclude column <columns> or <-f filename>

Remove a number of columns from character lists to get a new set of character lists (for a new Bio::NEXUS file). eg, "1-3, 5 8, 10-15" (comma or space can be used to separate numbers)

=head2     makesets byfile <file1> [file2 file3 ...]

Add sets based on OTU's listed in simple text files.  Sets take names of files; OTU's should be newline-delimited in the text files.

=head2 makesets byinode <inode1> [inode2 inode3 ...]

Add sets based on ancestral internal nodes and their children

=head2 makesets byclade <OTU1> <OTU2> [OTU3 OTU4 ...]

Add sets by finding the children of the most recent common ancestor (mrca) of OTU1 and OTU2 pairs

=head2 makesets byotus <set1>=[<OTU1 OTU2 ...>] <set2>=[<OTU3 OTU4 ...>] ...

Add sets by specifying setnames and OTU's each set is to contain.  Syntax is setname=[<OTU LIST>]

=head2 makesets byunion <set1>=[<setA + setB ...>] <set2>=[<setA + setC ...>] ...

Add sets by specifying setnames and which existing sets contain the OTUs the new set will comprise.  Syntax is setname=[<SET LIST>]

=head2 makesets bydifference <set1>=[<setA - setB>] <set2>=[<setA - setC>] ...

Add sets by specifying setnames and which existing sets contain the OTUs that will be used in defining the new sets.

=head2 makesets bycharstate [title=char_block_title] [set1=]"<sequence_or_intron_position>[<state>]" [set2=...]

Add sets by specifying setnames and which existing sets contain the OTUs that will be used in defining the new sets.

=head2 makesets bycladeconsensus [title=char_block_title]

Add sets by finding clades that have a consensus sequence at all loci, and creating one set for each group of "otu synonyms"

=head2 removesets [-p] set1 set2 ...

Delete sets from NEXUS file.  Will empty SETS Block but not remove it from file. '-p' switch allows you to specify regular expression patterns ('set\d*' will delete all sets of the form set<number>.)  QUOTATION MARKS AROUND PATTERNS IS STRONGLY RECOMMENDED.

=head2 listsets

Print sets (all sets by default, otherwise those provided by user) to output file, or standard out of STDOUT or - is used as output filename

=head2 listsetnames

Print setnames to output file, or standard out if STDOUT or - is used as output filename

=head2 renamesets oldname1 newname1 [oldname2 newname2 ...]

Rename sets by space-delimited <oldname newname> pairs

=head1 DESCRIPTION

B<This program> provides several services in the manipulation of NEXUS files (selecting specific OTUs or tree nodes, combining files, renaming OTUs, etc.

=head1 VERSION

$Revision: 1.2 $

=head1 REQUIRES

Bio::NEXUS

=head1 AUTHOR

Chengzhi Liang <liangc@umbi.umd.edu>
Peter Yang <pyang@rice.edu>
Tom Hladish <hladish@umbi.umd.edu>

=cut

##################### End ##########################
