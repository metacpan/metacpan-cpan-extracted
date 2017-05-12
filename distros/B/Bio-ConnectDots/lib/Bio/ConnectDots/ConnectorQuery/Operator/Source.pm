package Bio::ConnectDots::ConnectorQuery::Operator::Source;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS %DEFAULTS);
use strict;
use Class::AutoClass;
use Bio::ConnectDots::Util;
use Bio::ConnectDots::ConnectorQuery::Alias;
use Bio::ConnectDots::ConnectorQuery::Operator;
@ISA = qw(Bio::ConnectDots::ConnectorQuery::Operator);

@AUTO_ATTRIBUTES=qw();
%SYNONYMS=();
@OTHER_ATTRIBUTES=qw(source);
%DEFAULTS=(cs_sql_aliases=>[]);
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
}
sub execute {}			# override default method

sub source {
  my $self=shift @_;
  my $included_aliases=@_? $self->included_aliases([$_[0]]): $self->included_aliases;
  $included_aliases and $included_aliases->[0];
}
sub name {$_[0]->source->target_name;}

1;
