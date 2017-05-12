package Catalyst::Model::DBIC::Schema::QueryLog;

use Moose;

our $VERSION = '0.10';

use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;

extends 'Catalyst::Model::DBIC::Schema';

with 'Catalyst::Component::InstancePerContext';
with 'MooseX::Emulate::Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/querylog _querylog_analyzer/);

sub querylog_analyzer {
    my $self = shift;
    
    unless ($self->_querylog_analyzer) {
        $self->_querylog_analyzer( new DBIx::Class::QueryLog::Analyzer({ querylog => $self->querylog }) );
    }
    
    return $self->_querylog_analyzer;
}

sub build_per_context_instance {
    my ($self, $c) = @_;
    
    if ( $Catalyst::Model::DBIC::Schema::VERSION >= 0.24 ) {
        warn "Catalyst::Model::DBIC::Schema::QueryLog is DEPERCATED for Catalyst::TraitFor::Model::DBIC::Schema::QueryLog\n";
    }
    
    my $schema = $self->schema;
    
    my $querylog = new DBIx::Class::QueryLog();
    $self->querylog($querylog);
    $self->_querylog_analyzer( undef );
    
    $schema->storage->debugobj( $querylog );
    $schema->storage->debug(1);
    
    return $self;
}

no Moose;

1; # End of Catalyst::Model::DBIC::Schema::QueryLog
__END__

=head1 NAME

Catalyst::Model::DBIC::Schema::QueryLog - (DEPERCATED) DBIx::Class::QueryLog Model Class

=head1 SYNOPSIS

  package MyApp::Model::FilmDB;
  use base qw/Catalyst::Model::DBIC::Schema::QueryLog/;

  __PACKAGE__->config(
      schema_class => 'MyApp::Schema::FilmDB',
      connect_info => [
                        "DBI:...",
                        "username",
                        "password",
                        {AutoCommit => 1}
                      ]
  );

=head1 DEPERCATED WARNING

If you are using lastest (>= 0.24) L<Catalyst::Model::DBIC::Schema>, please use L<Catalyst::TraitFor::Model::DBIC::Schema::QueryLog> instead.

=head1 DESCRIPTION

Generally, you should check the document of L<Catalyst::Model::DBIC::Schema>. this module extends it, and only provide extra two methods below.

=head1 METHODS

=over 4

=item querylog

an instance of L<DBIx::Class::QueryLog>.

=item querylog_analyzer

an instance of L<DBIx::Class::QueryLog::Analyzer>.

=back

=head1 EXAMPLE CODE

  <div class="featurebox">
    <h3>Query Log Report</h3>
    [% SET total = c.model('FilmDB').querylog.time_elapsed | format('%0.6f') %]
    <div>Total SQL Time: [% total | format('%0.6f') %] seconds</div>
    [% SET qcount = c.model('FilmDB').querylog.count %]
    <div>Total Queries: [% qcount %]</div>
    [% IF qcount %]
    <div>Avg Statement Time: [% (c.model('FilmDB').querylog.time_elapsed / qcount) | format('%0.6f') %] seconds.</div>
    <div>
     <table class="table1">
      <thead>
       <tr>
        <th colspan="3">5 Slowest Queries</th>
       </tr>
      </thead>
      <tbody>
       <tr>
        <th>Time</th>
        <th>%</th>
        <th>SQL</th>
       </tr>
       [% SET i = 0 %]
       [% FOREACH q = c.model('FilmDB').querylog_analyzer.get_sorted_queries %]
       <tr class="[% IF loop.count % 2 %]odd[% END %]">
        <th class="sub">[% q.time_elapsed | format('%0.6f') %]
        <td>[% ((q.time_elapsed / total ) * 100 ) | format('%i') %]%</td>
        <td>[% q.sql %] : ([% q.params.join(', ') %])</td>
       </th></tr>
       [% IF i == 5 %]
        [% LAST %]
       [% END %]
       [% SET i = i + 1 %]
       [% END %]
      </tbody>
     </table>
    </div>
    [% END %]
  </div>

OR

  my $total = sprintf('%0.6f', $c->model('DBIC')->querylog->time_elapsed);
  $c->log->debug("Total SQL Time: $total seconds");
  my $qcount = $c->model('DBIC')->querylog->count;
  if ($qcount) {
    $c->log->debug("Avg Statement Time: " . sprintf('%0.6f', $total / $qcount));
    my $i = 0;
    my $qs = $c->model('DBIC')->querylog_analyzer->get_sorted_queries();
    foreach my $q (@$qs) {
      my $q_total = sprintf('%0.6f', $q->time_elapsed);
      my $q_percent = sprintf('%0.6f', ( ($q->time_elapsed / $total) * 100 ));
      my $q_sql = $q->sql . ' : ' . join(', ', @{$q->params});
      $c->log->debug("SQL: $q_sql");
      $c->log->debug("Costs: $q_total, takes $q_percent");
      last if ($i == 5);
      $i++;
    }
  }

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>

L<DBIx::Class::QueryLog>

L<Catalyst::Component::InstancePerContext>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut