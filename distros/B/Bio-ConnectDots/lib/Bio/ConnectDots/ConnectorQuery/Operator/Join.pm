package Bio::ConnectDots::ConnectorQuery::Operator::Join;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::ConnectorQuery::Operator;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator);

@AUTO_ATTRIBUTES=qw(join);
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw();
%DEFAULTS=();
Class::AutoClass::declare(__PACKAGE__);

1;
