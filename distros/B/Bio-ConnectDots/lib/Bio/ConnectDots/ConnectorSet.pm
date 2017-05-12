package Bio::ConnectDots::ConnectorSet;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::DB::ConnectorSet;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(name file cs_version ftp ftp_files saved_file db db_id 
		    label2dotset label2labelid dots_hash input_fh 
		    _current _instances label_annotations source_version source_date download_date comment);

@OTHER_ATTRIBUTES=qw(dotsets labels);
%SYNONYMS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  return if $self->db_id;	       # already fetched
  my $module=$args->module;
  if ($module) {		# dynamically load subclass
    my $module_file="Bio/ConnectDots/ConnectorSet/$module.pm";
    require $module_file;
    bless $self,ref($self)."::$module";
  }
  return unless $self->db;
  my $label2dotset=$self->label2dotset || $self->label2dotset({});
  my $label2labelid=$self->label2labelid || $self->label2labelid({});
  my $saved=Bio::ConnectDots::DB::ConnectorSet->get($self);
  my @newlabels;
  if ($saved) {
    $self->db_id($saved->db_id);
    $self->saved_file($saved->file); # so application can catch duplicate loads
    # compare in-memory vs. saved dotsets
    my $saved_l2d=$saved->label2dotset;
    my $saved_l2i=$saved->label2labelid;
    while(my($label,$dotset)=each %$label2dotset) {
      my $saved_dotset=$saved_l2d->{$label};
      push(@newlabels,$label), next unless $saved_dotset;
      $self->throw("In-memory and saved ConnectorSets use label $label for two different DotSets: ".$dotset->name." vs. ".$saved_dotset->name) unless $dotset->name eq $saved_dotset->name;
      $dotset->db_id($saved_dotset->db_id);
      $label2labelid->{$label}=$saved_l2i->{$label};
    }
  } else {			# everything is new
    @newlabels=$self->labels;
  }
  Bio::ConnectDots::DB::ConnectorSet->put($self,@newlabels); # store new information

  # open file if provided
  $self->open_file if $self->file;
}
sub instances {
  my $self= shift;
  my $instances=$self->_instances || $self->_instances([]);
  push(@$instances,@_) if @_;
  wantarray? @$instances: $instances;
}
# normalize parameters to hash -- create DotSet objects
sub dotsets {
  my $self=shift;
  my $label2dotset=$self->label2dotset || $self->label2dotset({});
  if (@_) {
    my @dotsets=_flatten(@_);
    my $name2dotset={};
    for my $dotset (@dotsets) {
      unless ('HASH' eq ref $dotset) {
		$dotset=$self->_fix_dotset($dotset,$name2dotset);
		my $label=$dotset->name;
		$self->throw("Two DotSets have same label: $label") if $label2dotset->{$label};
		$label2dotset->{$label}=$dotset;
      } else {			# hash: label=>name or DotSet
	my $hash=$dotset;
	while(my($label,$dotset)=each %$hash) {
	  $dotset=$self->_fix_dotset($dotset,$name2dotset);
	  $self->throw("Two DotSets have same label: $label") if $label2dotset->{$label};
	  $label2dotset->{$label}=$dotset;
	}
      }
    }
  }
  my @dotsets=uniq(values %$label2dotset);
  wantarray? @dotsets: \@dotsets;
}
sub _fix_dotset {
  my($self,$dotset,$name2dotset)=@_;
  $self->throw("Unrecognized parameter to dotsets: $dotset") 
    unless !ref $dotset || UNIVERSAL::isa($dotset,'Bio::ConnectDots::DotSet');
  if (!ref $dotset) {	        # scalar: should be DotSet name
    my $name=$dotset;
    $dotset=$name2dotset->{$name} || 
      ($name2dotset->{$name}=new Bio::ConnectDots::DotSet(-name=>$name,-db=>$self->db));
  } else {			# already DotSet object -- just test for duplicates
    my $name=$dotset->name;
    $self->throw("Two DotSets have same name") 
      if $name2dotset->{$name} && $name2dotset->{$name} != $dotset;
    $name2dotset->{$name}=$dotset;
  }
  $dotset;
}	  
sub labels {
  my $self=shift;
  my @labels=_flatten(@_);
  my @results;
  if (@labels) {
    my $label2dotset=$self->label2dotset;
    @results=grep {exists $label2dotset->{$_}} @labels;
  } else {
    @results=keys %{$self->label2dotset};
  }
  wantarray? @results: \@results;
}
sub put {
  my($self,$connector)=@_;
  $self->instances($connector);
  $connector;
}
sub open_file {
  my($self,$file)=@_;
  $file or $file=$self->file;
  $self->throw("Attempting to open file, but file is not set") unless $file;
  my $input_fh;
  open($input_fh,"< $file") or $self->throw("open of $file failed: $!");
  $self->input_fh($input_fh);
}
sub parse_file {
  my $self=shift;
  unless ($self->input_fh) {
    my $file=shift or $self->file;
    $self->throw("Cannot parse file: no file provided");
    $self->open_file($file);
  }
  while ($self->parse_entry) {
    my $connector=new Bio::ConnectDots::Connector(-connectorset=>$self);
    $self->put($connector);
    $self->dots_hash(undef);
  }
}
sub load_file {
  my($self,$load_save,$load_chunksize)=@_;
  my $db=$self->db;
  $self->throw("Cannot load file: ConnectorSet has no database") unless $db;
  $self->throw("Cannot load file: database not connected") unless $db->is_connected;
  $self->throw("Cannot load file: database does not exist") unless $db->exists;
  unless ($self->input_fh) {
    my $file=shift or $self->file;
    $self->throw("Cannot load file: no file provided");
    $self->open_file($file);
  }
  my $connectorset_id=$self->db_id;
  my $label2dotset=$self->label2dotset;
  my $label2labelid=$self->label2labelid;
  $db->load_init($self->name,$load_save,$load_chunksize);
  my $connector_id=1;
  while ($self->parse_entry) {
    my $dots_hash=$self->dots_hash;
    while(my($label,$ids)=each %$dots_hash) {
      my $dotset_id=$label2dotset->{$label}->db_id;
      my $label_id=$label2labelid->{$label};
      for my $id (@$ids) {
        $db->load_row($connector_id,$connectorset_id,$id,$dotset_id,$label_id);
      }
    }
    $connector_id++;
    $self->dots_hash(undef);
  }
  $db->load_finish;
}
sub parse_entry {
  my($self)=@_;
  $self->throw("parse_enrty() Not implemented: must be implemented in subclass");
}
sub have_dots {
  my $dots_hash=$_[0]->dots_hash;
  $dots_hash and %$dots_hash? 1: undef;
}
sub put_dot {
  my($self,$label,$value)=@_;
  return unless length($value)>0;	# skip empty strings
  my $dots_hash=$self->dots_hash || $self->dots_hash({});
  my $list=$dots_hash->{$label} || ($dots_hash->{$label}=[]);
  push(@$list,$value);
  $list;
}

sub _flatten {map {'ARRAY' eq ref $_? @$_: $_} @_;}

1;

__END__

=head1 NAME

Bio::ConnectDots::ConnectorSet -- 'connect-the-dots'

=head1 SYNOPSIS

  use Bio::ConnectDots::DB;
  use Bio::ConnectDots::ConnectorSet;

  my $db=new Bio::ConnectDots::DB(-database=>'test',
                                       -host=>'servername',
                                       -user=>'username',
                                       -password=>'secret');
  my $connectorset=new Bio::ConnectDots::ConnectorSet(
                     -name=>'LocusLink',
                     -module=>'LocusLink',
                     -db=>$db,
                     -file=>'LL_tmpl',
                     -dotsets=>['LocusLink','UniGene','Organism',
                               {'PreferedSymbol'=>'Gene Symbol','Alias Symbol'=>'Gene Symbol','Hugo'=>'Gene Name'}]
									    );
  $connectorset->load_file;

=head1 DESCRIPTION

This class represents a data source, such as LocusLink, that contain
connection information for 'connect-the-dots'.

=head1 AUTHOR - David Burdick, Nat Goodman

Email dburdick@systemsbiology.org, natg@shore.net

=head1 COPYRIGHT

Copyright (c) 2005 Institute for Systems Biology (ISB). All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 APPENDIX

The rest of the documentation describes the methods.

=head2 Constructors

 Title   : new
 Usage   : $connector_set=new Bio::ConnectDots::ConnectorSet(
                            -name=>'LocusLink',
                            -module=>'LocusLink',
                            -db=>$db,
                            -file=>'LL_tmpl',
                            -dotsets=>['LocusLink','UniGene','Organism',
                                      {'PreferedSymbol'=>'Gene Symbol','Alias Symbol'=>'Gene Symbol',
                                       'Hugo'=>'Gene Name'}]
                             );
 Function: Create ConnectorSet object, typically for parsing and loading a file
           into the database

 Args    : -name => name of ConnectorSet
           -module => subclass module to be loaded. The '.pm' for this module must
              be in a directory Bio/ConnectDots/ConnectorSet beneath one of
              your PERL5LIBs
           -db => Bio::ConnectDots::DB object connected to database
           -file => name of file to be loaded
           -dotsets => ARRAY of DotSet names or HASH of label=>name. In the first
              case, ie, if no label is given, the name is used as the label

           -load_save => controls whether load files are saved after use.  Helpful
              for debugging
              default - files not saved
              'all' -- files are saved
              'last' -- only last file is saved
           -load_chunksize => number of Dots loaded at a time.  Tuning parameter.
              default 100000

           The following arguments are set internally:

           -db_id => database id for ConnectorSet object
           -saved_file => name of file loaded when object created

 Returns : Object whose class is a subclass of Bio::ConnectDots::ConnectorSet
          determined by -module

=head2 Methods to operate on files and add connectors to collection

 Title   : load_file
 Usage   : $connectorset->load_file;
 Function: Parse entries and load into database
 Returns : Nothing

 Title   : parse_file
 Usage   : $connectorset->parse_file;
 Function: Parse entries into 'instance' objects and store in object
 Returns : Nothing

 Title   : put_dot
 Usage   : $connectorset->put_dot('Hugo','CASP7')
 Function: Add a dot to the 'current' Connector. Used in parse_entry methods
 Args    : label of DotSet
           Dot value, ie, an actual identifier
 Returns : ARRAY of values for the label

=cut
