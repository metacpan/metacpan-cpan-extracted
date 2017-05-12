package Bio::ConnectDots::DotQuery::CtMixin;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::DotQuery::Output;
use Bio::ConnectDots::DotQuery::Constraint;
@ISA = qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(ct);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $input=$self->input;
  my $ct=$self->connectdots->name2ct->{$input};
  $self->throw("Invalid -input: must be ConnectorTable name") unless $ct;
  $self->ct($ct);
}

# outputs must have column & label
# column must be valid for input ConnectorTable
# label must be valid for ConnectorSet associated with column (handled by Output::validate)
sub validate_outputs {
  my($self)=@_;
  my $ct=$self->ct;
  my $column2cs=$ct->column2cs;
  for my $output (@{$self->outputs}) {
    my($column,$label)=$output->get(qw(column label));
    $self->throw("Invalid output ".$output->as_string.
		 ": ConnectorTable outputs must have column") unless $column;
    my $cs=$column2cs->{$column};
    $self->throw("Column $column not valid for ConnectorTable ".$self->input) unless $cs;
    $output->validate($cs);
		
		# add outputs to alias2info
  	my $alias = $output->output_name;
		my $cs = $output->{_term}->{cs};
    my $cs_id = $cs->db_id;
    my $label_id = $output->{_term}->{label_ids}->[0];
    my $dotset = $output->dotset;
    $self->{dottable}->{alias2info}->{$alias}->{dotset}= $dotset;
		$self->{dottable}->{alias2info}->{$alias}->{label_id} = $label_id;
		$self->{dottable}->{alias2info}->{$alias}->{cs_id} = $cs->db_id;
  }
}
# constraint-terms must have columns & labels
# column must be valid for input ConnectorTable
# label must be valid for ConnectorSet associated with column (handled by Term::validate)
sub validate_constraints {
  my($self)=@_;
  my $ct=$self->ct;
  my $column2cs=$ct->column2cs;
  for my $constraint (@{$self->constraints}) {
    my $term=$constraint->term;
    my $column=$term->column;
    $self->throw("Invalid constraint ".$constraint->as_string.
		 ": ConnectorTable constraints must have column") unless $column;
    my $cs=$column2cs->{$column};
    $self->throw("Column $column not valid for ConnectorTable ".$self->input) unless $cs;
    $term->validate($cs);
  }
}

1;

