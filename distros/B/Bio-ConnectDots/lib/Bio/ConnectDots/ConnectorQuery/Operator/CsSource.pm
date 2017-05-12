package Bio::ConnectDots::ConnectorQuery::Operator::CsSource;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Alias;
use Bio::ConnectDots::ConnectorQuery::Operator::Source;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator::Source);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

# Override default to return alias_name
sub columns {
  my($self)=@_;
  my $columns=[$self->out_column($self->source)];
  wantarray? @$columns: $columns;
}
# Override default
sub targets {
  my($self,$sql_alias)=@_;
  my $column=$self->out_column($self->source);
  my @targets=(qq($sql_alias.connector_id AS $column));
  wantarray? @targets: \@targets;
}
# Override default
sub sql_name {'connectdot';}
sub sql_alias {$_[0]->source->alias_name.'_CS'}

1;
