package Bio::ConnectDots::ConnectorQuery::Operator::CtSource;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Alias;
use Bio::ConnectDots::ConnectorQuery::Operator::Source;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator::Source);

@AUTO_ATTRIBUTES=qw(_out_columns);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

# Override default to return 'original' columns names
sub columns {
  my($self)=@_;
  my $columns=$self->source->target_object->columns;
  wantarray? @$columns: $columns;
}

# Override default to convert input names to output form
sub out_columns {
  my($self)=@_;
  my $columns=$self->_out_columns;
  unless ($columns) {
    my $ct_alias=$self->source;
    $columns=[];
    @$columns=map {$self->out_column($ct_alias,$_)} @{$self->columns};
    $self->_out_columns($columns);
  }
  wantarray? @$columns: $columns;
}

# Override default to return 'original' column name
sub term_column {
  my($self,$term)=@_;
  $term->column;
}
# Override default to convert 'original' column names into output form
sub targets {
  my($self,$sql_alias)=@_;
  my $ct_alias=$self->source;
  my @targets=map {qq($sql_alias.$_ AS ).$self->out_column($ct_alias,$_)} @{$self->columns};
  wantarray? @targets: \@targets;
}
sub sql_alias {$_[0]->source->alias_name.'_CT'}

1;
