package DBIx::QueryByName::QueryPool;
use utf8;
use strict;
use warnings;
use DBIx::QueryByName::Logger qw(get_logger debug);

sub new {
    return bless( {}, $_[0] );
}

sub add_query {
    my ($self, %args) = @_;
    my $log     = get_logger();
    my $name    = $args{name}    || $log->logcroak("BUG: undefined query name");
    my $sql     = $args{sql}     || $log->logcroak("BUG: undefined query sql");
    my $session = $args{session} || $log->logcroak("BUG: undefined query session");
    my $params  = $args{params}  || $log->logcroak("BUG: undefined query parameters");
    my $result  = $args{result}  || $log->logcroak("BUG: undefined query result");
    my $retry   = $args{retry}   || $log->logcroak("BUG: undefined query retry");

    $log->logcroak("invalid query name: contain non alfanumeric characters ($name)")
        if ($name !~ /^[a-zA-Z0-9_]+$/);

    $log->logcroak("invalid query parameters: expecting an array reference: ".Dumper($params))
        if (ref $params ne 'ARRAY');

    foreach my $p (@{$params}) {
        $log->logcroak("invalid query parameter: contain undefined parameter: ".Dumper($params))
            if (!defined $p);

        $log->logcroak("invalid query parameter: contain non alfanumeric characters [$p]")
            if ($p !~ /^[a-zA-Z0-9\,_]+$/);
    }

    $result = lc $result;
    $log->logcroak("invalid result type: $result")
        if ($result !~ /^(sth|scalar|hashref|scalariterator|hashrefiterator)$/);

    $log->logcroak("invalid retry type: $result")
        if ($retry !~ /^(safe|never|always)$/);

    # TODO: validate the query's sql code
    # TODO: validate session
    #    my $session = $args{session} || $log->logcroak("BUG: undefined query session");

    debug "adding query $name to pool, under session $session";

    $self->{$name} = {
        sql     => $sql,
        session => $session,
        params  => $params,
        result  => $result,
        retry   => $retry,
    };

    return $self;
}

sub delete_queries {
    my ($self, $session) = @_;
    get_logger()->logcroak("BUG: undefined query session") unless defined $session;

    foreach my $name (keys %$self) {
        if (exists $self->{$name}->{session} && $self->{$name}->{session} eq $session) {
            delete $self->{$name};
            debug "removing query $name from pool, under session $session";
        }
    }
}

sub knows_query {
    my ($self, $name) = @_;
    get_logger()->logcroak("BUG: undefined query name") if (!defined $name);
    return (exists $self->{$name}) ? 1 : 0;
}

sub get_query {
    my ($self, $name) = @_;
    get_logger()->logcroak("BUG: undefined query name") if (!defined $name);
    get_logger()->logcroak("BUG: unknown query $name") if (!$self->knows_query($name));
    return ($self->{$name}->{session}, $self->{$name}->{sql}, $self->{$name}->{result}, @{$self->{$name}->{params}});
}

sub get_retry_attribute {
    my ($self, $name) = @_;
    get_logger()->logcroak("BUG: undefined query name") if (!defined $name);
    get_logger()->logcroak("BUG: unknown query $name") if (!$self->knows_query($name));
    return $self->{$name}->{retry};
}

1;

__END__

=head1 NAME

DBIx::QueryByName::QueryPool - Manages a pool of sql query descriptions

=head1 DESCRIPTION

An instance of DBIx::QueryByName::QueryPool stores the descriptions of
all the queries that can be executed with corresponding instances of
DBIx::QueryByName.

DO NOT USE DIRECTLY!

=head1 INTERFACE

This API is subject to change!

=over 4

=item C<< my $pool = DBIx::QueryByName::QueryPool->new(); >>

Instanciate DBIx::QueryByName::QueryPool.

=item C<< $pool->add_query(name => $name, sql => $sql, session => $session, result => $result, params => \@params); >>

Add a query to this pool.
C<$result> must be one of 'sth', 'scalar', 'hash', 'scalariterator', 'hashiterator'.
Example:

    $pool->add_query(name => 'get_user_adress',
                     sql => 'SELECT adress FROM adresses WHERE firstname=? AND lastname=?',
                     result => 'sth',
                     params => [ 'firstname', 'lastname' ],
                     session => 'name_of_db_connection',
                     retry => 'never',
                    );

=item C<< $pool->knows_query($name); >>

True if the pool already contains a query with that name. False otherwise.

=item C<< $pool->delete_queries($session); >>

Remove all the queries added under session C<$session>.

=item C<< my ($session,$sql,@params) = $pool->get_query($name); >>

Return the name of the database session, the sql code and the named parameters
of the query named C<$name>. Croak if no query with that name.

=item C<< my $retry = $pool->get_retry_attribute($name); >>

Return the retry attribute for this query, one of 'always', 'never' or 'safe'.

=back

=cut

