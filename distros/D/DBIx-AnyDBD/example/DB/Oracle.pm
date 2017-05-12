# $Id: Oracle.pm,v 1.1 2001/08/02 16:32:22 matt Exp $

package Example::DB::Oracle;

use strict;

sub _init
{
    my $self = shift;

    $self->get_dbh->{LongReadLen} = $self->config_value('LongReadLen') || ( 2**16 - 1 );
    $self->get_dbh->{LongTruncOk} = 1;

    # Since the default date picture format for a given Oracle database
    # cannot be known in advance, its best to set it to something
    # consistent and easy to deal with.
    $self->do_sql( sql => q|ALTER SESSION SET NLS_DATE_FORMAT = 'YYYYMMDDHH24MISS'| );
}

sub sql_date
{
    my $self = shift;
    my $time = localtime( shift || time );

    return $time->strftime('%Y%m%d%H%M%S');
}

sub _prepare_and_execute
{
    my $self = shift;
#    ::Utils::check_params( @_,
#				   mandatory => ['sql'],
#				   optional => [ qw( begin limit bind ) ],
#				 );
    my %p = @_;

    my @bind = exists $p{bind} ? ( ref $p{bind} ? @{ $p{bind} } : $p{bind} ) : ();

    my $sth;
    eval
    {
	$sth = $self->get_dbh->prepare_cached( $p{sql} );
	$sth->execute(@bind);
    };
    if ($@)
    {
	Example::Exception::SQL->throw( -text => $@,
					       -sql => $p{sql},
					       -bind => \@bind );
    }

    return $sth;
}

sub _outer_join_operator
{
    return '(+)=';
}

sub get_next_pk
{
    my $self = shift;

#    ::Utils::check_params( @_,
#				   mandatory => [ qw( table ) ],
#				 );
    my %p = @_;

    my $id = $self->get_one_row( sql => "SELECT $p{table}_seq.NEXTVAL FROM DUAL" );

    $self->{last_id} = $id;

    return $id;
}

sub last_id
{
    my $self = shift;

    return delete $self->{last_id};
}

1;
