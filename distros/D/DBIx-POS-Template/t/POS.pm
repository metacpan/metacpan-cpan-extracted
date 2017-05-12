package POS;
#~ use lib 'lib';
use DBIx::POS::Template;

sub new {shift; DBIx::POS::Template->instance(__FILE__, @_);}

=pod

=encoding utf8

=name тест тест

=sql

  select * from {% $tables{foo} %}; -- тест тест

=name тест2

=sql

  select * from {% $tables{foo2} %}; -- тест2

=cut

1;