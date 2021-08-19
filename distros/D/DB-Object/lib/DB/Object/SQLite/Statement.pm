# -*- perl -*-
##----------------------------------------------------------------------------
# Database Object Interface - ~/lib/DB/Object/SQLite/Statement.pm
# Version v0.300.1
# Copyright(c) 2019 DEGUEST Pte. Ltd.
# Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
# Created 2017/07/19
# Modified 2020/05/22
# 
##----------------------------------------------------------------------------
# This package's purpose is to automatically terminate the statement object and
# separate them from the connection object (DB::Object).
# Connection object last longer than statement objects
##----------------------------------------------------------------------------
package DB::Object::SQLite::Statement;
BEGIN
{
    use strict;
    use warnings;
    use DB::Object::SQLite;
    use DB::Object::Statement;
    use parent qw( DB::Object::SQLite DB::Object::Statement );
    our( $VERSION, $VERBOSE, $DEBUG );
    $VERSION    = 'v0.300.1';
    $VERBOSE    = 0;
    $DEBUG      = 0;
};

# Inherited from DB::Object::Statement
# sub bind_param

# sub commit is called by dbh, so it is in DB::Object::Postgres

# Customised for Postgres
sub distinct
{
    my $self = shift( @_ );
    my $what = shift( @_ );
    my $query = $self->{query} ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^\s*(\S+)\s+/ )[ 0 ] );
    # ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( SELECT );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be distinct:\n$query" ) );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DISTINCT|ALL)[[:blank:]]+/i );
    my $clause = defined( $what ) ? "DISTINCT ON ($what)" : "DISTINCT";
    
    $query =~ s/^([[:blank:]]*)($allowed)([[blank:]]+)/$1$2 $clause /;
    # my $sth = $self->prepare( $query ) ||
    # $self->{ 'query' } = $query;
    # saving parameters to bind later on must have been done previously
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

# Inherited from DB::Object
# sub dump

# Inherited from DB::Object::Statement
# sub execute

# Inherited from DB::Object::Statement
# sub executed

# Inherited from DB::Object::Statement
# sub fetchall_arrayref($@)

# Inherited from DB::Object::Statement
# sub fetchcol($;$)

# Inherited from DB::Object::Statement
# sub fetchhash(@)

# Inherited from DB::Object::Statement
# sub fetchrow(@)

# Inherited from DB::Object::Statement
# sub finish

# https://sqlite.org/lang_insert.html
# https://sqlite.org/lang_update.html
sub ignore
{
    my $self = shift( @_ );
    my $query = $self->{query} ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ] );
    # ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( INSERT UPDATE );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be ignored:\n$query" ) );
    }
    # Already done. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+OR[[:blank:]]+IGNORE[[:blank:]]+/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 OR IGNORE$3/;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

# Inherited from DB::Object::Statement
# sub join

# Inherited from DB::Object::Statement
# sub object

sub only
{
    return( shift->error( "SELECT | DELETE | UPDATE ONLY is not supported by SQLite." ) );
}

sub priority
{
    return( shift->error( "Priority is not supported in SQLite." ) );
}

# rollback is called using the dbh handler and is located in DB::Object::Postgres

# Inherited from DB::Object::Statement
# sub rows(@)

# Inherited from DB::Object::Statement
# sub undo

sub unprepared_statements
{
    my $self = shift( @_ );
    if( $self->{dbh}->{sth} )
    {
        return( $self->{dbh}->{sth}->{sqlite_unprepared_statements} );
    }
    return;
}

# Does nothing in SQLite. This is a Mysql feature
sub wait
{
    return( shift( @_ ) );
}

DESTROY
{
    # Do nothing but existing so it is handled by this package
    # print( STDERR "DESTROY'ing statement $self ($self->{ 'query' })\n" );
};

1;

__END__

=encoding utf-8

=head1 NAME

DB::Object::SQLite::Statement - SQLite Statement Object

=head1 SYNOPSIS

    use DB::Object::SQLite::Statement;
    my $this = DB::Object::SQLite::Statement->new || die( DB::Object::SQLite::Statement->error, "\n" );

=head1 VERSION

    v0.300.1

=head1 DESCRIPTION

This is a SQLite specific statement object class.

=head1 METHODS

=head2 distinct

Provided with an optional column and called upon a C<SELECT> query and this will modify the query to add the keyword C<DISTINCT>

    $sth->distinct;
    # produces SELECT DISTINCT....
    $sth->distinct( 'name' );
    # produces SELECT DISTINCT ON (name)....

See L<SQLite documentation for more information|https://sqlite.org/lang_select.html>

=head2 dump

This is inherited from L<DB::Object::Statement/dump>

=head2 ignore

This takes no argument and this will modify the queries of type C<insert>, or C<update> to add the keyword C<IGNORE>

    $sth->ignore;
    # produces INSERT IGNORE....

If called in void context, this will execute the prepare statement handler immediately.

It returns the newly created statement handler.

See L<SQLite documentation for more information|https://www.sqlite.org/lang_insert.html>

=head2 only

This returns an error as C<SELECT FROM ONLY> is not supported by SQLite and will return an error.

=head2 priority

This is unsupported under SQLite and if used returns an error.

=head2 unprepared_statements

This returns the natural SQLite statement property C<sqlite_unprepared_statements>, which provides the remaining unprepared statements in case where multiple statements were prepared.

See L<DBD::SQLite documentation for more information|DBD::SQLite>

=head2 wait

This is unsupported under SQLite and it will be silently ignore, returning the current object.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
