package Bio::ConnectDots::ConnectorQuery::Alias;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::Parser;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(target_name alias_name target_object);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

# legal formats:
# 1) old form -- HASH of alias => name
# 2) single alias string -- name AS alias -- which may include multiple aliases  AND'ed together
# 3) single Alias object
# 4) ARRAY of (1) alias strings and (2) Alias objects

sub parse {
  my($class,$aliases)=@_;
  my $parsed=[];
  my $parser=new Bio::ConnectDots::Parser;
  if ('HASH' eq ref $aliases) {
    while (my($alias_name,$target_name)=each %$aliases) {
      push(@$parsed,$class->new(-target_name=>$target_name,-alias_name=>$alias_name));
    }
  } elsif (!ref $aliases) {           # string
    push(@$parsed,$class->parse_string($aliases,$parser));
  } elsif (UNIVERSAL::isa($aliases,__PACKAGE__)) {
    push(@$parsed,$aliases);
  } elsif ('ARRAY' eq ref $aliases) {
    for my $alias (@$aliases) {
      if (!ref $alias) { 
	push(@$parsed,$class->parse_string($alias,$parser));
      } elsif (UNIVERSAL::isa($alias,__PACKAGE__)) {
	push(@$parsed,$alias);
      } else {
	$class->throw("llegal alias format ".value_as_string($alias).
		     ": must be string or alias object to appear in ARRAY format");
      }
    }
  } else {
    $class->throw("Unrecognized alias form ".value_as_string($aliases).
		 ": strange type! Not scalar, Alias object, ARRAY, or HASH");
  }
  wantarray? @$parsed: $parsed;
}
sub parse_string {
  my($class,$aliases,$parser)=@_;
  my $parsed=[];
  my $parsed_aliases=$parser->parse_aliases($aliases);
  if ($parsed_aliases) {
    for my $alias (@$parsed_aliases) {
      my($target_name,$alias_name)=@$alias{qw(target_name alias_name)};
      push(@$parsed, 
	   $class->new(-target_name=>$target_name,-alias_name=>$alias_name));
    }
  }
  wantarray? @$parsed: $parsed;
}
sub normalize { 
  my($self)=@_;
  # if only one attribute set, set other equal to it
  my($target_name,$alias_name)=$self->get(qw(-target_name -alias_name));
  unless ($target_name && $alias_name) {
    $target_name or $self->target_name($alias_name);
    $alias_name or $self->alias_name($target_name);
  }
  $self;
}
sub validate {
  my($self,$name2object,$version)=@_;
  my $target_name=$self->target_name;
	my $target_object;
	if($version) {
	  $target_object=$name2object->{$target_name}->{$version};
	} else {
		$target_object=$name2object->{$target_name};
	}
  $self->throw("Invalid alias ".$self->as_string. ": $target_name not found")
    unless $target_object;
  $self->target_object($target_object);
  $self;
}
sub type {
  my($self)=@_;
  my $class=blessed $self->target_object;
  my($type)=$class=~/::(\w+)$/;
  $type;
}
sub as_string {
  my($self)=@_;
  my $target_name=$self->target_name;
  my $alias_name=$self->alias_name;
  return "$target_name AS $alias_name";
}

1;

