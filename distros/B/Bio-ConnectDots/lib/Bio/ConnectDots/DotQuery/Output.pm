package Bio::ConnectDots::DotQuery::Output;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::Parser;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(_term output_name dotset);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw(term termlist column label cs label_id);
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->term or $self->term(new Bio::ConnectDots::DotQuery::Term);
}

# legal formats:
# 1) Old ConnectorTable format: ARRAY of [column,label] or HASH of output=>[column,label]
#    NOTE: Old ConnectorSet format NOT supported, because it conflicts with 
#    new ARRAY of output strings
# 2) single string -- label, label AS output, column.label, column.label AS output
#   may include multiple aliases  AND'ed together
# 3) single Output object
# 4) ARRAY of (1) output strings and (2) Output objects

sub parse {
  my($class,$outputs)=@_;
  my $parsed=[];
  my $parser=new Bio::ConnectDots::Parser;
  if (!ref $outputs) {                               # single string
    push(@$parsed,$class->parse_string($outputs,$parser));
  } elsif ('ARRAY' eq ref $outputs) {
    for my $output (@$outputs) {
      if (UNIVERSAL::isa($output,__PACKAGE__)) {     # Output object
	push(@$parsed,$output);
      } elsif (!ref($output)) {	                     # string
	push(@$parsed,$class->parse_string($output,$parser));
      } elsif ('ARRAY' eq ref $output) {             # old form: [column,label]
	my($column,$label)=@$output;
	push(@$parsed,$class->new(-column=>$column,-label=>$label));
      } else {
	$class->throw("llegal output format ".value_as_string($output).
		      ": must be string, Output object, or ARRAY to appear in ARRAY format");
      }
    }
  } elsif (UNIVERSAL::isa($outputs,__PACKAGE__)) { # single Output object
    push(@$parsed,$outputs);
  } elsif ('HASH' eq ref $outputs) { # old form HASH of output=>[column,label]
    while(my($output_name,$output)=each %$outputs) {
      	my($column,$label)=@$output;
	push(@$parsed,$class->new(-column=>$column,-label=>$label,-output_name=>$output_name));
      }
  } else {
    $class->throw("Unrecognized alias form ".value_as_string($outputs).
		 ": Strange type! Not scalar, Output object, ARRAY, or HASH");
  }
  wantarray? @$parsed: $parsed;
}
sub parse_string {
  my($class,$outputs,$parser)=@_;
  my $parsed=[];
  my $parsed_outputs=$parser->parse_outputs($outputs);
  if ($parsed_outputs) {
    for my $output (@$parsed_outputs) {
      my($termlist,$output_name)=@$output{qw(termlist output_name)};
      push(@$parsed, 
	   $class->new(-termlist=>$termlist,-output_name=>$output_name));
    }
  }
  wantarray? @$parsed: $parsed;
}
sub normalize {			# if no output_name, set it to label
  my($self)=@_;
  $self->term->normalize;
  $self->output_name($self->label) unless $self->output_name;
  $self;
}

# Does validation needed for both ConnectorSet and ConnectorTable inputs
# check labels and lookup label_ids
sub validate {
  my($self,$cs)=@_;
  my $label=$self->label;
  $self->throw("Invalid output ".$self->as_string.": must have label") unless $label;
  my $label_id=$cs->label2labelid->{$label};
  my $dotset=$cs->label2dotset->{$label};
  $self->throw("Label $label not valid for ConnectorSet ".$cs->name) unless $dotset;
  $self->cs($cs);
  $self->label_id($label_id);
  $self->dotset($dotset);
}

sub term {
  my $self=shift @_;
  my $term=@_? $self->_term($_[0]): $self->_term;
  $term or $term=$self->_term(new Bio::ConnectDots::DotQuery::Term);
  $term;
}
sub column {
  my $self=shift @_;
  my $column=@_? $self->term->column($_[0]): $self->term->column;
  $column;
}
sub cs {
  my $self=shift @_;
  my $cs=@_? $self->term->cs($_[0]): $self->term->cs;
  $cs;
}
sub cs_id {$_[0]->cs->db_id;}
sub cs_name {$_[0]->cs->name;}

sub label {
  my $self=shift @_;
  my $labels=@_? $self->term->labels([$_[0]]): $self->term->labels;
  $labels && $labels->[0];
}
sub label_id {
  my $self=shift @_;
  my $label_ids=@_? $self->term->label_ids([$_[0]]): $self->term->label_ids;
  $label_ids && $label_ids->[0];
}
sub termlist {
  my $self=shift @_;
  my $termlist=@_? $self->term->termlist($_[0]): $self->term->termlist;
  $termlist;
}

sub as_string {
  my($self)=@_;
  my($column,$label,$output_name)=$self->get(qw(column label output_name));
  join('.',$column,$label)." AS $output_name";
}

1;

