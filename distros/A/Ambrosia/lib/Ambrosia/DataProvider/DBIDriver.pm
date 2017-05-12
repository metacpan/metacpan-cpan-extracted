package Ambrosia::DataProvider::DBIDriver;
use strict;
use warnings;
use Carp;

use DBI;

use Ambrosia::core::Nil;
use Ambrosia::Utils::Container;
use Ambrosia::error::Exceptions;

use Ambrosia::Meta;
class abstract
{
    extends => [qw/Ambrosia::DataProvider::BaseDriver/],
    private => [qw/
        user
        password
        engine_params
        additional_params
        additional_action
        __sth
    /]
};

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->_cache ||= new Ambrosia::Utils::Container;
}

our $VERSION = 0.010;

sub reset
{
    my $self = shift;
    if ( $self->__sth )
    {
        $self->__sth->finish;
        $self->__sth = undef;
    }
    $self->SUPER::reset();
    return $self;
}

sub _name :Abstract :Protected {}

sub _connection_params
{
    my $self = shift;
    return 'dbi:'
        . $self->_name()
        . ':' . ($self->engine_params
                 || ('database=' . $self->schema
                 . ($self->host ? ';host=' . $self->host : '')
                 . ($self->port ? ';port=' . $self->port : '')));
}

sub open_connection
{
    my $self = shift;

    $self->close_connection;

    $self->_handler = DBI->connect (
            $self->_connection_params(),
            $self->user, $self->password,
            ($self->additional_params || {})
        )
        or throw Ambrosia::core::Exception(DBI->errstr);

    if ( defined $self->additional_action && ref $self->additional_action eq 'CODE' )
    {
        $self->additional_action->($self->_handler);
    }
    $self->begin_transaction();
    return $self->_handler;
}

sub close_connection
{
    my $self = shift;

    if ( defined $self->_handler )
    {
        if ( $self->__sth )
        {
            $self->__sth->finish;
            $self->__sth = undef;
        }
        $self->_handler->disconnect;
        $self->_handler = undef;
        $self->_cache = new Ambrosia::core::Nil();
        1;
    }
}
################################################################################

sub begin_transaction
{
    $_[0]->_cache ||= new Ambrosia::Utils::Container;
    return $_[0];
}

sub save_transaction
{
    my $self = shift;
    defined $self->_handler and ($self->_handler->{AutoCommit} or $self->_handler->commit or die $self->_handler->errstr);
    return $self;
}

sub cancel_transaction
{
    my $self = shift;

    $self->_cache = new Ambrosia::core::Nil();
    if ( defined $self->_handler )
    {
        eval
        {
            $self->_handler->{AutoCommit} or $self->_handler->rollback or die $self->_handler->errstr;
        };
        if ( $@ )
        {
            throw Ambrosia::error::Exception 'ERROR: at ' . __PACKAGE__ . ' in ' . caller() . ' [' . $@ . ']';
        }
    }
    return $self;
}

#!!TODO!! must return hash (cannot save "additional_action")
sub STORABLE_freeze
{
    my ($self, $cloning) = @_;
    return if $cloning;         # Regular default serialization
    return 'empty';
}

#!!TODO!! must recive hash and create new object
sub STORABLE_thaw
{
    my ($self, $cloning) = @_;
    return;
}

sub DESTROY
{
    my $self = shift;

    if ( $self && $self->__sth )
    {
        $self->__sth->finish;
        $self->__sth = undef;
    }
}

################################################################################
sub _make_limit :Protected
{
    return '';
}

sub _make_query
{
    my $self = shift;

    if ( $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SELECT] )
    {
        return $self->_make_select . ' '
            . _make_limit($self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::LIMIT]);
    }
    elsif ( $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::INSERT] )
    {
        return $self->_make_insert;
    }
    elsif ( $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::UPDATE] )
    {
        return $self->_make_update;
    }
    elsif ( $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::DELETE] )
    {
        return $self->_make_delete;
    }
}

sub execute
{
    my $self = shift;

    my $sql = '';
    eval
    {
        if ( $sql = $self->_make_query() )
        {
            $self->__sth = $self->handler()->prepare_cached($sql);
            $self->__sth->execute(@_);
        }
        else
        {
            die (ref($self) . ': cannot create SQL.');
        }
    };
    if ( $@ )
    {
        throw Ambrosia::error::Exception 'Error: query=' . $sql . "\n\t[@_]\n"
            . ($self->_handler ? $self->_handler->errstr : '');
    }
}

sub next
{
    my $self = shift;

    unless ( $self->__sth )
    {
        $self->__select->execute(@_);
    }

    my $r;
    unless ( $r = $self->__sth->fetchrow_hashref() )
    {
        $self->__sth->finish if $self->__sth;
        $self->__sth = undef;
        return;
    }
    return $r;
}

sub count
{
    my $self = shift;

    $self->__sth->finish if $self->__sth; #На всякий случай
    $self->__sth = undef;

    local $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SELECT];
    local $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::WHAT];
    local $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::UNIQ];
    local $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::NO_QUOTE];
    local $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::LIMIT];

    my $res = $self->__select()->what('count(*) AS numRows')->no_quote(1)->next();

    $self->__sth->finish if $self->__sth;
    $self->__sth = undef;

    return $res->{numRows};
}

sub __select
{
    my $self = shift;
    $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SELECT] = 'SELECT ' . join ' ', @_;
    return $self;
}

sub insert
{
    my $self = shift;
    $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::INSERT] = 'INSERT ' . (shift || '');
    return $self;
}

sub last_insert_id
{
    my $self = shift;
    return $self->handler->last_insert_id(@_);
}

sub delete
{
    my $self = shift;
    $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::DELETE] = 'DELETE ';
    return $self;
}

sub update
{
    my $self = shift;
    $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::UPDATE] = 'UPDATE ' . (shift || '');
    return $self;
}

sub _make_join
{
    my $self = shift;

    my $stJoin = {
        what   => '',
        source => '',
        where  => '',
    };

    if ( my $j = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::JOIN] )
    {
        my $dbh = $self->handler();

        my $prevStJoin = $j->[1]->_make_join();
        my $q = $j->[1]->_cql_query;

        if ( $q->[&Ambrosia::DataProvider::BaseDriver::WHAT] && scalar @{$q->[&Ambrosia::DataProvider::BaseDriver::WHAT]} )
        {
            if ( $q->[&Ambrosia::DataProvider::BaseDriver::NO_QUOTE] )
            {
                $stJoin->{what} = ',' . CORE::join ',', @{$q->[&Ambrosia::DataProvider::BaseDriver::WHAT]};
            }
            else
            {
                my $type = join '_', grep defined $_, @{$q->[&Ambrosia::DataProvider::BaseDriver::SOURCE]};
                my $qType = $dbh->quote_identifier(@{$q->[&Ambrosia::DataProvider::BaseDriver::SOURCE]}) . '.';
                $stJoin->{what} = ',' . $qType . CORE::join ',' . $qType, map { $dbh->quote_identifier($_) . ' AS ' . $type . '_' . $_ } @{$q->[&Ambrosia::DataProvider::BaseDriver::WHAT]};
            }
            $stJoin->{what} .= $prevStJoin->{what};
        }

        $stJoin->{source} = ' ' . $j->[0] . ' JOIN ' . $dbh->quote_identifier(@{$q->[&Ambrosia::DataProvider::BaseDriver::SOURCE]})
            . ' ON ('
            . CORE::join(' AND ', map {
                    $dbh->quote_identifier($_->[0]) . $_->[1] . $dbh->quote_identifier($_->[2])
                } @{$q->[&Ambrosia::DataProvider::BaseDriver::ON]})
            . ')';

        $stJoin->{source} .= $prevStJoin->{source};

        $stJoin->{where} = ' AND ' . $self->_make_where($dbh->quote_identifier(@{$q->[&Ambrosia::DataProvider::BaseDriver::SOURCE]}), $q->[&Ambrosia::DataProvider::BaseDriver::PREDICATE]) if $q->[&Ambrosia::DataProvider::BaseDriver::PREDICATE];
        $stJoin->{where} .= $prevStJoin->{where};
    }
    return $stJoin;
}

sub __what
{
    my $dbh = shift;
    my $source = shift;
    my $distinct = shift;
    my $fields = shift;
    my $noQuote = shift;

    if ( $fields && scalar @$fields )
    {
        if ( $noQuote )
        {
            return $distinct . CORE::join ',', @$fields;
        }
        else
        {
            my $type = join '_', grep defined $_, @$source;

            my $qType = $dbh->quote_identifier(@$source) . '.';
            return $distinct . $qType . CORE::join ",$qType", map { $dbh->quote_identifier($_) . ' AS ' . $type . '_' . $_ } @$fields;
        }
    }
    else
    {
        my $qType = $dbh->quote_identifier(@$source);
        return $distinct . $qType . '.* ';
    }
}

sub _make_what
{
    my $self = shift;

    if ( my $uniq = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::UNIQ] )
    {
        return __what($self->handler, $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE], ' DISTINCT ', $uniq, $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::NO_QUOTE]);
    }
    else
    {
        return __what($self->handler, $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE], '', $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::WHAT], $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::NO_QUOTE]);
    }
}

sub _make_select
{
    my $self = shift;
    my $res;
    if ( $res = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SELECT] )
    {
        my $dbh = $self->handler;

        my $stJoin = $self->_make_join();
        $res .= $self->_make_what();

        $res .= $stJoin->{what};

        $res .= ' FROM ' . $dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]});
        $res .= $stJoin->{source};

        $res .= ' WHERE ' . $self->_make_where($dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]}), $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE]) if $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE];
        $res .= $stJoin->{where};
        $res .= ' ORDER BY ' . join ',', @{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::ORDER_BY]} if $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::ORDER_BY];
    }
    return $res;
}

sub __cond_op
{
    my $dbh = shift;
    my $type = shift;
    my $f = shift;
    my $op = shift;
    my $v = shift;

    if ( ref $v eq 'ARRAY' )
    {
        return '(' . CORE::join(' OR ', map { __cond_op($dbh, $type, $f, $op, $_ ) } @$v) . ')';
    }
    else
    {
        unless ( $f =~ /[^a-zA-Z0-9_]/so )
        {
            $f = $dbh->quote_identifier($f);
        }
        return ($f ? ($type.$f . ' ') : '') . $op . (defined $v ? (' ' . $dbh->quote($v)) : '');
    }
}

sub __cond
{
    my $dbh = shift;
    my $type = shift;
    my $f = shift;
    if ( ref $f eq 'ARRAY' )
    {
        return '(' . CORE::join(' OR ', map { __cond_op($dbh, $type, @$_) } ($f, @_)) . ')';
    }
    else
    {
        return __cond_op($dbh, $type, $f, @_);
    }
}

sub _make_where
{
    my $self = shift;
    my $type = shift() . '.';
    my $dbh = $self->handler;
    return CORE::join(' AND ', map { __cond($dbh, $type, @$_) } @{+shift});
}

sub _make_insert
{
    my $self = shift;
    my $res;
    if ( $res = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::INSERT] )
    {
        my $dbh = $self->handler;
        my @fields = @{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::WHAT]};
        $res .= ' INTO ' . $dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]});
        $res .= ' (' . CORE::join(',', map {$dbh->quote_identifier($_)} @fields) . ')';
        $res .= ' VALUES(' . CORE::join(',', ('?') x scalar @fields) . ')';
    }
    return $res;
}

sub _make_delete
{
    my $self = shift;
    my $res;
    if ( $res = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::DELETE] )
    {
        my $dbh = $self->handler;
        $res .= ' FROM ' . $dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]});
        $res .= ' WHERE ' . $self->_make_where($dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]}), $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE]) if $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE];
    }
    return $res;
}

sub _make_update
{
    my $self = shift;
    my $res;
    if ( $res = $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::UPDATE] )
    {
        my $dbh = $self->handler;
        $res .= ' ' . $dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]});
        $res .= ' SET ' . CORE::join(',', map {$dbh->quote_identifier($_) . '=?'} @{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::WHAT]});
        $res .= ' WHERE ' . $self->_make_where($dbh->quote_identifier(@{$self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::SOURCE]}), $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE]) if $self->_cql_query->[&Ambrosia::DataProvider::BaseDriver::PREDICATE];
    }
    return $res;
}


1;

__END__

=head1 NAME

Ambrosia::DataProvider::DBIDriver - an abstract class that realize L<Ambrosia::DataProvider::BaseDriver> and provide connection to data bases throw DBI.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::DataProvider::DBIDriver> is an abstract class that realize L<Ambrosia::DataProvider::BaseDriver> and provide connection to data bases throw DBI.

For more information see:

=over

=item L<Ambrosia::DataProvider::Engine::DB::mysql>

=item L<Ambrosia::DataProvider::Engine::DB::pg>

=back

=head1 PUBLIC METHODS

=head2 open_connection

Opens a connection. Returns handler.

=head2 close_connection

Closes a connection and clears a cache.

=head2 begin_transaction

Begins a transaction.

=head2 save_transaction

Saves a transaction.

=head2 cancel_transaction

Canceled a transaction (rollback) and clear cache.

=head2 reset

Converts an object to its initial state.

=head2 execute

Executes a request. Use for C<insert>, C<update>, C<delete>.

=head2 next

Returns a next record from data source.

=head2 count

Returns a number of rows in data source with specific condition.

=head2 insert

Prepares an object for insert data into source.

=head2 last_insert_id

Returns a last inserted id.

=head2 delete

Prepares an object for delete record from source.

=head2 update

Prepares an object for update record in source.

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
