package Catalyst::TraitFor::Model::DBIC::Schema::QueryLog;
our $VERSION = '0.03';

# ABSTRACT: L<DBIx::Class::QueryLog> support for L<Catalyst::Model::DBIC::Schema>

use namespace::autoclean;
use Moose::Role;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use DBIx::Class::QueryLog;
use DBIx::Class::QueryLog::Analyzer;

with 'Catalyst::Component::InstancePerContext';

has 'querylog' => (
    is  => 'rw',
    isa => 'DBIx::Class::QueryLog',
);
has 'querylog_args' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);
has 'querylog_analyzer' => (
    is         => 'rw',
    isa        => 'DBIx::Class::QueryLog::Analyzer',
    lazy_build => 1
);

sub _build_querylog_analyzer {
    my $self = shift;

    return DBIx::Class::QueryLog::Analyzer->new(
        { querylog => $self->querylog } );
}

sub build_per_context_instance {
    my ( $self, $c ) = @_;

    my $schema = $self->schema;

    my $querylog_args = $self->querylog_args;
    my $querylog      = DBIx::Class::QueryLog->new($querylog_args);
    $self->querylog($querylog);
    $self->clear_querylog_analyzer;

    $schema->storage->debugobj($querylog);
    $schema->storage->debug(1);

    return $self;
}

1;
__END__

=pod

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::QueryLog - L<DBIx::Class::QueryLog> support for L<Catalyst::Model::DBIC::Schema>

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use base qw/Catalyst::Model::DBIC::Schema/;
    
    __PACKAGE__->config({
        traits => ['QueryLog'],
        connect_info => 
            ['dbi:mysql:master', 'user', 'pass'],
    });

    # or
    __PACKAGE__->config({
        traits => ['QueryLog'],
        connect_info => 
            ['dbi:mysql:master', 'user', 'pass'],
        querylog_args => {
            passthrough => 1,
        },
    });

=head1 DESCRIPTION

check L<Catalyst::Model::DBIC::Schema> for more details

Enable L<DBIx::Class::QueryLog> support for L<Catalyst::Model::DBIC::Schema>.

=head2 METHODS

=over 4

=item querylog

an instance of L<DBIx::Class::QueryLog>.

=item querylog_analyzer

an instance of L<DBIx::Class::QueryLog::Analyzer>.

=item querylog_args

passed to DBIx::Class::QueryLog->new;

=back

=head2 EXAMPLE CODE

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

=head2 SEE ALSO

L<Catalyst::Model::DBIC::Schema>

L<DBIx::Class::QueryLog>

L<Catalyst::Component::InstancePerContext>

=head1 AUTHOR

  Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut
