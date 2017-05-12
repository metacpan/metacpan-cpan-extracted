package Catalyst::TraitFor::Model::DBIC::Schema::Caching;

use namespace::autoclean;
use Moose::Role;
use Carp::Clan '^Catalyst::Model::DBIC::Schema';
use MooseX::Types::Moose 'Int';
use Module::Runtime 'use_module';

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Schema::Caching - Query caching support for
Catalyst::Model::DBIC::Schema

=head1 SYNOPSIS

    __PACKAGE__->config({
        traits => ['Caching'],
        connect_info => 
            ['dbi:mysql:db', 'user', 'pass'],
    });

    $c->model('DB::Table')->search({ foo => 'bar' }, { cache_for => 18000 });

=head1 DESCRIPTION

Enable caching support using L<DBIx::Class::Cursor::Cached> and
L<Catalyst::Plugin::Cache>.

In order for this to work, L<Catalyst::Plugin::Cache> must be configured and
loaded. A possible configuration would look like this:

  <Plugin::Cache>
    <backend>       
      class Cache::FastMmap
      unlink_on_exit 1
      share_file /tmp/myapp_share
    </backend>
  </Plugin::Cache>

Then in your queries, set the C<cache_for> ResultSet attribute to the number of
seconds you want the query results to be cached for, eg.:

  $c->model('DB::Table')->search({ foo => 'bar' }, { cache_for => 18000 });

=head1 CONFIG PARAMETERS

=head2 caching

Turn caching on or off, you can use:

    $c->model('DB')->caching(0);

=cut

has caching => (is => 'rw', isa => Int, default => 1);

after setup => sub {
    my $self = shift;

    return if !$self->caching;

    $self->caching(0);

    my $cursor_class = $self->connect_info->{cursor_class}
        || 'DBIx::Class::Cursor::Cached';

    unless (eval { use_module($cursor_class) }) {
        carp "Caching disabled, cannot load cursor class"
            . " $cursor_class: $@";
        return;
    }

    unless ($cursor_class->can('clear_cache')) {
        carp "Caching disabled, cursor_class $cursor_class does not"
             . " support it.";
        return;
    }

    $self->connect_info->{cursor_class} = $cursor_class;
    $self->caching(1);
};

before ACCEPT_CONTEXT => sub {
    my ($self, $c) = @_;

    return $self unless 
        $self->caching;

    unless ($c->can('cache') && ref $c->cache) {
        $c->log->warn("DBIx::Class cursor caching disabled, you don't seem to"
            . " have a working Cache plugin.");
        $self->caching(0);
        $self->_reset_cursor_class;
        return $self;
    }

    if (ref $self->schema->default_resultset_attributes) {
        $self->schema->default_resultset_attributes->{cache_object} =
            $c->cache;
    } else {
        $self->schema->default_resultset_attributes({
            cache_object => $c->cache
        });
    }
};

=head1 SEE ALSO

L<Catalyst::Model::DBIC::Schema>, L<DBIx::Class>, L<Catalyst::Plugin::Cache>,
L<Cache::FastMmap>, L<DBIx::Class::Cursor::Cached>

=head1 AUTHOR

See L<Catalyst::Model::DBIC::Schema/AUTHOR> and
L<Catalyst::Model::DBIC::Schema/CONTRIBUTORS>.

=head1 COPYRIGHT

See L<Catalyst::Model::DBIC::Schema/COPYRIGHT>.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
