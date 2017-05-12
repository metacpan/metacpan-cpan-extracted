package Bio::ConnectDots::DotQuery::CsMixin;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::DotQuery::Output;
use Bio::ConnectDots::DotQuery::Constraint;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(cs);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $input=$self->input;
  my $version = $args->get_args('cs_version');

  if(!$version) {
  	foreach my $ver (keys %{$self->connectdots->name2cs->{$input}}) {
  	  $version = $ver if $ver gt $version;
  	}
  }
  
  my $cs=$self->connectdots->name2cs->{$input}->{$version};
  $self->throw("Invalid -input: must be ConnectorSet name") unless $cs;
  $self->cs($cs);
}
sub cs_id {$_[0]->cs->db_id;}
sub cs_name {$_[0]->cs->name;}
sub label2labelid {$_[0]->cs->label2labelid;}

# outputs must have label, no column; label must be valid for input ConnectorSet
sub validate_outputs {
  my($self)=@_;
  my $cs=$self->cs;
  for my $output (@{$self->outputs}) {
    $self->throw("Invalid output ".$output->as_string.
		 ": ConnectorSet outputs cannot have column") if $output->column;
    $output->validate($cs);

		# add outputs to alias2info
  	my $alias = $output->output_name;
    my $cs_id = $cs->db_id;
    my $label_id = $output->{_term}->{label_ids}->[0];
    my $dotset = $output->dotset;
    $self->{dottable}->{alias2info}->{$alias}->{dotset}= $dotset;
		$self->{dottable}->{alias2info}->{$alias}->{label_id} = $label_id;
		$self->{dottable}->{alias2info}->{$alias}->{cs_id} = $cs->db_id;    
  }
}
# constraint-terms must have labels, no column
# labels must be valid for input ConnectorSet (handled by Term::validate)
sub validate_constraints {
  my($self)=@_;
  my $cs=$self->cs;
  for my $constraint (@{$self->constraints}) {
    my $term=$constraint->term;
    $self->throw("Invalid constraint ".$constraint->as_string.
		 ": ConnectorSet constraints cannot have column") if $term->column;
    $term->validate($cs);
  }
}

1;

