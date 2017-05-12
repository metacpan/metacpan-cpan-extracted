package Bio::ConnectDots::ConnectorQuery::Operator::CsRootConstraint;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Operator::CsSource;
use Bio::ConnectDots::ConnectorQuery::Operator::CsConstraint;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator::CsConstraint);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

# special case for query that contains cs constraint and no joins

sub generate {
  my($self)=@_;
  my($column)=$self->columns;
  my $targets="cd.connector_id AS $column";
  $self->SUPER::generate('DISTINCT',$targets);	# generate regular constraint query
}

1;
