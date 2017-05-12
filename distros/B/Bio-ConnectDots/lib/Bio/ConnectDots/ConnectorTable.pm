package Bio::ConnectDots::ConnectorTable;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
#use lib "/users/ywang/temp";
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::ConnectorQuery;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(db db_id connectdots name column2cs query_type cs2version preview preview_limit);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(column2cs=>{},query_type=>'inner');
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $cd=$self->connectdots;
  $self->throw("Required parameter -name missing") unless $self->name;
  $self->throw("Required parameter -connectdots missing") unless $cd;
  my($drop,$create,$query,$cs_versions)=$args->get_args(qw(drop create query cs_version));
  Bio::ConnectDots::DB::ConnectorTable->drop($self) if $drop || $create;
	$self->preview($args->get_args('preview'));
	$self->preview_limit(500);

  # break versions into hash table
	if ($cs_versions) {
	  $cs_versions =~ s/\s//g; # remove white space
	  my %cs2version = split /[=,]/, $cs_versions;
	  $self->{cs2version} = \%cs2version;
	} else {
	  # fill in cs2version with lexicographically greater versions for each ConnectorSet
	  while(my ($csname,$cs_list) = each %{$self->connectdots->name2cs}) {
		my $version='';
		foreach my $v (keys %{$cs_list}) {
		  $version = $v if $v gt $version;
		}
		$self->{cs2version}->{$csname} = $version;
	  }
	}

  my $saved=Bio::ConnectDots::DB::ConnectorTable->get($self,$cd);
  if ($saved) {		    # copy relevant attributes from db object to self
	    $self->throw("ConnectorTable ".$self->name." already exists") if $query;
    $self->db_id($saved->db_id);
    $self->column2cs($saved->column2cs);
  }
  
  
  $self->query($query) if $query;
}

sub connectorsets {
  my($self)=@_;
  my @connectorsets=values %{$self->column2cs};
  wantarray? @connectorsets: \@connectorsets;
}
sub columns {
  my($self)=@_;
  my @columns=keys %{$self->column2cs};
  wantarray? @columns: \@columns;
}
sub put {
  my($self)=@_;
  Bio::ConnectDots::DB::ConnectorTable->put($self);
}

sub query {
  my($self,$args)=@_;
  if ($self->db_id) {
    $self->throw("Connectortable ".$self->name." already exists. Use -create to overwrite")
      unless $args->create;
    Bio::ConnectDots::DB::ConnectorTable->drop($self); 
  }
  my $query_type=$args->query_type || $self->DEFAULTS_ARGS->query_type;
  $self->throw("Unrecognized query type: $query_type") unless $query_type=~/inner|full|outer/i;
  $args->set_args(-connectortable=>$self);
  my $query=$query_type=~/inner/i?
    new Bio::ConnectDots::ConnectorQuery::Inner($args):
      new Bio::ConnectDots::ConnectorQuery::Outer($args);
  $query->execute;
  $self->put;
}

1;
