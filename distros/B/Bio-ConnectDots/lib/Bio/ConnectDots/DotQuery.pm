package Bio::ConnectDots::DotQuery;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
#use lib "/users/ywang/temp";
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::Dot;
use Bio::ConnectDots::DotQuery::Output;
use Bio::ConnectDots::DotQuery::Constraint;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(input dottable outputs constraints name2output);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
%DEFAULTS=(name2output=>{});
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->throw("Required parameter -input missing") unless $self->input;
  $self->throw("Required parameter -outputs missing") unless $self->outputs;
}

sub connectdots {$_[0]->dottable->connectdots;}
sub name {$_[0]->dottable->name;}
sub db {$_[0]->dottable->db;}

sub execute {
  my($self)=@_;
  $self->parse;			# parse syntax
  $self->normalize;		# normalize syntax
  $self->validate;		# do semantic checks
  $self->db_execute;		# really execute -- implemented in subclasses
}
sub parse {
  my($self)=@_;
  $self->parse_outputs;
  $self->parse_constraints;
}
sub normalize {
  my($self)=@_;
  $self->normalize_outputs;
  $self->normalize_constraints;
}
sub validate {
  my($self)=@_;
  $self->validate_outputs;	# implemented in subclass mixins
  $self->validate_constraints;	# implemented in subclass mixins
}
sub parse_outputs {
  my($self)=@_;
  my $outputs=parse Bio::ConnectDots::DotQuery::Output($self->outputs);
  $self->outputs($outputs);
}
sub normalize_outputs {
  my($self)=@_;
  my $outputs=$self->outputs;
  my $normalized=[];
  @$normalized=map {$_->normalize} @$outputs;
  $self->outputs($normalized);
  my $name2output=$self->name2output;
  for my $output (@$normalized) {
    my $output_name=$output->output_name;
    $self->throw("Duplicate output: $output") if $name2output->{$output_name};
     $name2output->{$output_name}=$output;
  }  
}
sub parse_constraints {
  my($self)=@_;
  my $constraints=parse Bio::ConnectDots::DotQuery::Constraint($self->constraints);
  $self->constraints($constraints);
}
sub normalize_constraints {
  my($self)=@_;
  my $constraints=$self->constraints;
  my $normalized=[];
  @$normalized=map {$_->normalize} @$constraints;
  $self->constraints($normalized);
}

# 'utility' method used in all subclasses
# generate core where classes for constraint
sub constraint_where {
  my($self,$constraint,$cs_id,$cd)=@_;
  my @where;
  push(@where,"$cd.connectorset_id=$cs_id");
  my $label_ids=$constraint->label_ids;
  # if $label_ids is empty, the label was '*' -- matches all ids
  if (@$label_ids==1) {
    push(@where,"$cd.label_id=".$label_ids->[0]);
  } elsif (@$label_ids>1) {
    push(@where,"$cd.label_id IN (".join(",",@$label_ids).")");
  }
  my($op,$constants)=($constraint->op,$constraint->constants);
  my $db=$self->db;
  my @constants=map {$db->quote_dot($_)} @$constants;
  if ($op=~/IN/) {		# IN or NOT IN
    push(@where,"$cd.id $op (".join(",",@constants).")");
  } elsif ($op ne 'EXISTS') {	# EXISTS has no constants -- needs no SQL condition
				# should only be 1 constant by now -- see Constraint::normalize
    push(@where,"$cd.id $op ".$db->quote($constants->[0]));
  }
  wantarray? @where: \@where;
}

# Removes entries from a table that are subsets of other rows on one identifier
# usage: remove_subsets( <table name>, <key name> )
sub remove_subsets {
	my ($self, $dbh, $TABLE, $key_name, $output_cols) = @_;
	
	# setup translation hash and assign key index
	my $key_index;
	for(my $i=0; $i<@$output_cols; $i++) {
		$key_index = $i if $key_name eq $output_cols->[$i];
	}

	my $iterator = $dbh->prepare("SELECT DISTINCT * FROM $TABLE ORDER BY $key_name");
	$iterator->execute();
	my @list;
	my @delete;
	my $old_key;
	my $key_index=0;
	while (my @cols = $iterator->fetchrow_array()) {
		my $key = $cols[$key_index];
		if($key ne $old_key) { # reset lists
			@list = undef;
			$old_key = $key;
		}
		# remove subset entries on image_id
	
		if (@list) { # update list to exclude subsets
			my $add_it = 1;
			for(my $i=0; $i<=$#list; $i++) {
				next unless $list[$i];
				if ($self->subset(\@cols, $list[$i]) ) { # skip this row if it's a subset
					$add_it = 0;
					push @delete, \@cols;
					last;
				}
				if ($self->subset($list[$i], \@cols)) { # remove entries that are subset of present
					push @delete, $list[$i];
					$list[$i] = '';
				} 
			}
			push @list, \@cols if $add_it; # add non subset rows 
		}
		else { push @list, \@cols; }
	}
	
	### delete rows from table
	foreach my $cols (@delete) {
		next unless $cols; # ignore empty rows in the list
		my $sql = "DELETE FROM $TABLE WHERE";
		for(my $i=0; $i<@$output_cols; $i++) {
			$sql .= " AND" if $i>0;
			if($cols->[$i]) {
				$sql .=  " $output_cols->[$i]='$cols->[$i]'";
			}
			else {
				$sql .=  " $output_cols->[$i] IS NULL";
			}
		}
		$dbh->do($sql);
	}
}

### returns true if first is a subset of second, false otherwise
sub subset {
	my ($self, $first, $second) = @_; # pointers to the two lists to compare
	return 0 if @{$first} > @{$second};
	for (my $i=0; $i<@{$second}; $i++) {
		return 0 if !$second->[$i] && $first->[$i];  # 0 1
		return 0 if $first->[$i] && $second->[$i] && $first->[$i] ne $second->[$i];  # 1 != 1
	}
	return 1;
}




1;
