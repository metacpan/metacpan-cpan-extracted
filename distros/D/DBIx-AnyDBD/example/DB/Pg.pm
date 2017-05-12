# $Id: Pg.pm,v 1.1 2001/08/02 16:32:22 matt Exp $

package Example::DB::Pg;

sub _init
{
    my $self = shift;

    $self->do_sql( sql => q|SET DATESTYLE = 'ISO'| );
}

sub _prepare_and_execute
{
    my $self = shift;
#    ::Utils::check_params( @_,
#				   mandatory => ['sql'],
#				   optional => [ qw( begin limit bind ) ],
#				 );
    my %p = @_;

    if ( $p{limit} ) {
	$p{sql} .= " LIMIT $p{limit}";
	$p{sql} .= " OFFSET $p{begin}" if $p{begin};
    }

    my @bind = exists $p{bind} ? ( ref $p{bind} ? @{ $p{bind} } : $p{bind} ) : ();

    my $sth;
    eval {
	$sth = $self->get_dbh->prepare_cached( $p{sql} );
	$sth->execute(@bind);
    };
    if ($@) {
	Example::Exception::SQL->throw( -text => $@,
					       -sql => $p{sql},
					       -bind => \@bind );
    }

    return $sth;
}

sub _outer_join
{
    die "Cannot do outer joins in Postgres.  This method needs to be hand coded for Postgres.";
}

sub get_next_pk
{
    my $self = shift;

#    ::Utils::check_params( @_,
#				   mandatory => [ qw( table ) ],
#				 );
    my %p = @_;

    my $id = $self->get_one_row( sql => "SELECT NEXTVAL('$p{table}_seq')" );

    $self->{last_id} = $id;

    return $id;
}

sub last_id
{
    my $self = shift;

    return delete $self->{last_id};
}

1;
