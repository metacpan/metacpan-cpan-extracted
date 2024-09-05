# -*- perl -*-
##----------------------------------------------------------------------------
## Database Object Interface - ~/lib/DB/Object/Mysql/Statement.pm
## Version v0.300.2
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2017/07/19
## Modified 2024/09/04
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
#----------------------------------------------------------------------------
# DB/Object/Mysql/Statement.pm
# Version 0.3
# Copyright(c) 2019 Jacques Deguest
# Author: Jacques Deguest <jack@deguest.jp>
# Created 2017/07/19
# Modified 2019/06/17
# All rights reserved.
# 
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself.
#----------------------------------------------------------------------------
# This package's purpose is to automatically terminate the statement object and
# separate them from the connection object (DB::Object).
# Connection object last longer than statement objects
#----------------------------------------------------------------------------
package DB::Object::Mysql::Statement;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( DB::Object::Statement DB::Object::Mysql );
    use vars qw( $VERSION $DEBUG );
    our $DEBUG = 0;
    our $VERSION = 'v0.300.2';
};

use strict;
use warnings;

# Inherited from DB::Object::Statement
# sub bind_param

# sub commit is called by dbh, so it is in DB::Object::Postgres

# Customised for MySQL
sub distinct
{
    my $self = shift( @_ );
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
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DISTINCT|DISTINCTROW|ALL)[[:blank:]]+/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 DISTINCT /;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new ignored query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new ignored query:\n$query" ) );
    }
    return( $sth );
}

# Customised for MySQL
sub dump
{
    my $self  = shift( @_ );
    my $args  = @_ == 1 ? shift( @_ ) : { @_ };
    my $vsep  = ",";
    my $hsep  = "\n";
    my $width = 35;
    $self->_load_class( 'DateTime' ) || return( $self->pass_error );
    $self->_load_class( 'Module::Generic::File' ) || return( $self->pass_error );
    my $fh = Module::Generic::File->stdout() ||
        return( $self->pass_error( Module::Generic::File->error ) );
    $vsep  = $args->{vsep} if( exists( $args->{vsep} ) );
    $hsep  = $args->{hsep} if( exists( $args->{hsep} ) );
    $width = $args->{width} if( exists( $args->{width} ) );
    my @fields = ();
    # my @fields = @{$self->{sth}->FETCH( 'NAME' )};
    my $fields_ref = $self->{sth}->{NAME};
    if( defined( $fields_ref ) && ref( $fields_ref ) eq 'ARRAY' )
    {
        @fields = @$fields_ref;
    }
    else
    {
        return( $self->error( "No array reference of fields could be retrieved from statement '$self->{sth}'." ) );
    }
    return( $self->error( "No query to dump." ) ) if( !exists( $self->{sth} ) );
    if( exists( $args->{file} ) )
    {
        # new_file is inherited from Module::Generic and uses Module::Generic::File
        my $file = $self->new_file( $args->{file} ) || return( $self->pass_error );
        $fh = $file->open( '>', { binmode => 'utf8' }) || return( $self->error( "Unable to open file $file in write mode: $!" ) );
        my @header = sort{ $a <=> $b } @fields;
        my $date = DateTime->now;
        my $table = $self->{table};
        $fh->printf( "# Generated on %s for table $table\n", $date->strftime( '%c' ) );
        $fh->print( "# ", CORE::join( "\t", @header ), "\n" );
        my @data = ();
        while( @data = $self->fetchrow() )
        {
            $fh->print( CORE::join( "\t", @data ), "\n" );
        }
        $fh->close();
        $self->finish();
        return( $self );
    }
    elsif( exists( $args->{fh} ) )
    {
        if( !fileno( $args->{fh} ) )
        {
            return( $self->error( "The file descriptor provided does not seem to be valid (not open)" ) );
        }
        $fh = IO::File->new_from_fd( $args->{fh}, 'w' ) || return( $self->error( $! ) );
    }
    my $max    = 0;
    # foreach my $field ( keys( %$fields ) )
    foreach my $field ( @fields )
    {
        $max = length( $field ) if( length( $field ) > $max );
    }
    my $template = '';
    # foreach my $field ( sort{ $fields->{ $a } <=> $fields->{ $b } } keys( %$fields ) )
    foreach my $field ( @fields )
    {
        $template .= "$field" . ( '.' x ( $max - length( $field ) ) ) . ": %s\n";
    }
    $template .= "\n";
    my @data = ();
    while( @data = $self->fetchrow() )
    {
        $fh->printf( $template, @data );
    }
    $self->finish();
    return( $self );
}

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

sub ignore
{
    my $self = shift( @_ );
    my $query = $self->{query} ||
    return( $self->error( "No query to set as to be ignored." ) );
    
    my $type = uc( ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ] );
    # ALTER for table alteration statements (DB::Object::Tables
    my @allowed = qw( INSERT UPDATE ALTER );
    my $allowed = CORE::join( '|', @allowed );
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        return( $self->error( "You may not flag statement of type \U$type\E to be ignored:\n$query" ) );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)[[:blank:]]+/i );
    return( $self ) if( $type eq 'ALTER' && $query !~ /^[[:blank:]]*$type[[:blank:]]+TABLE[[:blank:]]+/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 IGNORE /;
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
    return( shift->error( "SELECT | DELETE | UPDATE ONLY is not supported by Mysql." ) );
}

sub priority
{
    my $self = shift( @_ );
    my $prio = shift( @_ );
    my $map  =
    {
    0    => 'LOW_PRIORITY',
    1    => 'HIGH_PRIORITY',
    };
    # Bad argument. Do not bother
    return( $self ) if( !exists( $map->{ $prio } ) );
    
    my $query = $self->{query} ||
    return( $self->error( "No query to set priority for was provided." ) );
    my $type = uc( ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ] );
    my @allowed = qw( DELETE INSERT REPLACE SELECT UPDATE );
    my $allowed = CORE::join( '|', @allowed );
    # Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not set priority on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^\s*(?:$allowed)\s+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)\s+/i );
    # SELECT with something else than HIGH_PRIORITY is incompatible, so do not bother to go further
    return( $self ) if( $prio != 1 && $type =~ /^(?:SELECT)$/i );
    return( $self ) if( $prio != 0 && $type =~ /^(?:DELETE|INSERT|REPLACE|UPDATE)$/i );
    
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 $map->{ $prio } /i;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new low priority query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new low priority query:\n$query" ) );
    }
    return( $sth );
}

# rollback is called using the dbh handler and is located in DB::Object::Postgres

# Inherited from DB::Object::Statement
# sub rows(@)

# Inherited from DB::Object::Statement
# sub undo

sub wait
{
    my $self = shift( @_ );
    my $query = $self->{query} ||
    return( $self->error( "No query to set as to be delayed." ) );
    my $type = ( $query =~ /^[[:blank:]]*(\S+)[[:blank:]]+/ )[ 0 ];
    my @allowed = qw( INSERT REPLACE );
    my $allowed = CORE::join( '|', @allowed );
    # Ignore if not allowed
    if( !scalar( grep{ /^$type$/i } @allowed ) )
    {
        $self->error( "You may not use wait (delayed query) on statement of type \U$type\E:\n$query" );
        return( $self );
    }
    # Incompatible. Do not bother going further
    return( $self ) if( $query =~ /^[[:blank:]]*(?:$allowed)[[:blank:]]+(?:DELAYED|LOW_PRIORITY|HIGH_PRIORITY)[[:blank:]]+/i );
    $query =~ s/^([[:blank:]]*)($allowed)([[:blank:]]+)/$1$2 DELAYED /i;
    my $sth = $self->_cache_this( $query ) ||
    return( $self->error( "Error while preparing new delayed query:\n$query" ) );
    if( !defined( wantarray() ) )
    {
        $sth->execute() ||
        return( $self->error( "Error while executing new delayed query:\n$query" ) );
    }
    return( $sth );
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

DB::Object::Mysql::Query - Statement Object for MySQL

=head1 SYNOPSIS

    use DB::Object::Mysql::Statement;
    my $this = DB::Object::Mysql::Statement->new || die( DB::Object::Mysql::Statement->error, "\n" );

=head1 VERSION

   v0.300.2

=head1 DESCRIPTION

This is a MySQL specific statement object.

=head1 METHODS

=head2 distinct

This takes no argument and this will modify the query to add the keyword C<DISTINCT>

    $sth->distinct;
    # produces SELECT DISTINCT....
    $sth->distinct( 'name' );
    # produces SELECT DISTINCT ON (name)....

If called in void context, this will execute the prepare statement handler immediately.

It returns the newly created statement handler.

See L<MySQL documentation for more information|https://dev.mysql.com/doc/refman/5.7/en/distinct-optimization.html>

=head2 dump

This will dump the result of the query to STDOUT or to a file if I<file> argument is provided, or if a filehandle is provided with I<fh>, it will be used to print out the data.

It takes also a I<vsep>, which defaults to a command and a I<hsep> which defaults to a new line.

It returns the current object.

=head2 ignore

This takes no argument and this will modify the queries of type C<alter>, C<insert>, C<update> to add the keyword C<IGNORE>

    $sth->ignore;
    # produces INSERT IGNORE....

If called in void context, this will execute the prepare statement handler immediately.

It returns the newly created statement handler.

See L<MySQL documentation for more information|https://dev.mysql.com/doc/refman/5.7/en/insert.html>

=head2 only

This returns an error as C<SELECT FROM ONLY> is not supported by MySQL.

=head2 priority

Provided with a priority integer that can be 0 or 1 with 0 being C<LOW_PRIORITY> and 1 being C<HIGH_PRIORITY> and this will adjust the query formatted to add the priority. This works only on Mysql drive though.

If used on queries other than C<DELETE>, C<INSERT>, C<REPLACE>, C<SELECT>, C<UPDATE> an error will be returned.

If called in void context, this will execute the newly create statement handler immediately.

It returns the newly create statement handler.

=head2 wait

    $sth->wait || die( $sth->error );

This takes no parameter and only works on queries of type C<INSERT> or C<UPDATE>. It will modify the previously prepared query to add the keyword C<DELAYED>

If called in void context, this will execute the prepare statement handler immediately.

It returns the newly created statement handler.

See L<MySQL documentation for more information|https://dev.mysql.com/doc/refman/5.6/en/insert-delayed.html>

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
