package DBIx::PgLink::Adapter::Roles::CheckWhereClause;

use Moose::Role;
use DBIx::PgLink::Logger;

use SQL::Statement;

has 'check_where_parser' => (is=>'ro', isa=>'SQL::Parser', lazy=>1, 
  default=>sub{ SQL::Parser->new('ANSI', {PrintError=>0, RaiseError=>1}) } 
);

after 'check_where_condition' => sub {
  my ($self, $where) = @_;
  eval { $self->check_where_parser->parse('SELECT 1 FROM dummy ' . $where) };
  if ($@) {
    (my $msg = $@) =~ s/SELECT 1 FROM dummy //g;
    $msg =~ s/^\s+//;
    $msg =~ s/\s+$//;
    trace_msg('ERROR', "Check of WHERE clause fails: $msg");
  }
};

1;

