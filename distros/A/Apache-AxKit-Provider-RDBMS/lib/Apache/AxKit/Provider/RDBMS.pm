package Apache::AxKit::Provider::RDBMS;

use strict;
use warnings;

our @ISA = qw( Apache::AxKit::Provider );

our $VERSION = '0.01';

# Preloaded methods go here.


## private methods
our $loadModule;

sub init {
    my $this = shift;
    my ( %p ) = @_;
    my $r = $this->{apache};
    
    my $adapter = $r->dir_config( "RDBMSCacheAdapter" );

    if( ! defined $adapter ) {
        $adapter = "Apache::AxKit::Provider::RDBMS::DBCacheAdapter::SQLite";
    }


    my $content_provider = $r->dir_config( "RDBMSContentProvider" );
    
    if( ! defined $content_provider ) {
        $content_provider = "Apache::AxKit::Provider::RDBMS::ContentProvider::SQL";
    }
    
    $this->$loadModule( $adapter );
    $this->$loadModule( $content_provider );
    
    $this->{cacheAdapter}   = $adapter->new( $this->{apache} );
    $this->{contentAdapter} = $content_provider->new( $this->{apache} );
    
    $this->{key} = $this->{apache}->location;
}

$loadModule = sub  {
    my $this   = shift;
    my $module = shift;
    
    $module =~ s/::/\//g;
    $module .= ".pm";
    
    require $module;
};

sub mtime {
    my $this = shift;
    return $this->{cacheAdapter}->mtime();
}


sub get_strref {
    my $this = shift;
    my $content;
    
    ## work-around axit-bug
    if( ! defined $this->{xml} ) {
        $this->{xml} = $this->{contentAdapter}->getContent();
    }

    $content = $this->{xml};
    
    return \$content;
}

sub key {
    return $_[0]->{key};
}

sub process {
    return 1;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Apache::AxKit::Provider::RDBMS - Perl extension AxKit 

=head1 SYNOPSIS

<Location /test.html>
    AxContentProvider Apache::AxKit::Provider::RDBMS
    AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSLT
    AxAddProcessor text/xsl test.xsl
    
    PerlSetVar DBIString "dbi:SQLite:dbname=/tmp/testsqllite"
    PerlSetVar DBIQuery "SELECT * FROM bla"
</Location>
		    
<Location /test2.html>
    AxContentProvider Apache::AxKit::Provider::RDBMS
    AxAddStyleMap text/xsl Apache::AxKit::Language::LibXSL
    AxAddProcessor text/xsl test.xsl
    
    PerlSetVar RDBMSCacheAdapter "Apache::AxKit::Provider::RDBMS::DBCacheAdapter::SQLite"
    PerlSetVar RDBMSContentProvider "Apache::AxKit::Provider::RDBMS::ContentProvider::MultiSQL"
    PerlSetVar DBIString "dbi:SQLite:dbname=/tmp/testsqllite"
    
    PerlAddVar DBIQuery "query1 => SELECT * FROM bla"
    PerlAddVar DBIQuery "query2 => SELECT * FROM bla"
    PerlAddVar DBIQuery "query3 => SELECT * FROM bla"
</Location>
				    

=head1 DESCRIPTION

Apache::AxKit::Provider::RDBMS is a custom axkit content provider which can
be used to provide XML-Content to AxKit-Framework and even use its highlevel
caching. The first release only support one Database namely SQLite but the
module is designed to be easily extensible for other databases the only thing
which has to be implemented is the DBCacheAdapter

Planned but not implemented for now:
* Native Support for following databases (MySQL) => DbCachedAd
* Generic Support using SQL-Statements for any SQL-Database 

=head2 usage

To configure the various databases can/need to set the following variables using 
PerlSetVar and/or PerlAddVar.

=over

=item RDBMSCacheAdapter: 

the cache-adapeter used. If not set it defaults to "Apache::AxKit::Provider::RDBMS::DBCacheAdapter::SQLite"

=item RDBMSContentProvider:

the really database content provider used. If not set defaults to "Apache::AxKit::Provider::RDBMS::ContentProvider::SQL"

=item DBIString:

the connection string used to connect to the database consult your DBD::*-manpage 
to find out how it should look like for your database

=item DBIQuery:

=over

=item PerlSetVar

You can use PerlSetVar in conjunction with A::A::P::RDBMS::ContentProvider::SQL to set the query
executed

=item PerlAddVar

You can use PerlAddVar in conjunction with A::A::P::RDBMS::ContentProvider::MultiSQL to set multiple queries.
The format passed in has to have the following look "queryname => SELECT .... "

=back

=back

=head2 The xml created by the provider

<!ELEMENT sql-results (sql-result+)>

<!ELEMENT sql-result ( row* )>

<!ATTLIST sql-result
                     name CDATA>

<!ELEMENT row (column+) >

<!ELEMENT column (#PCDATA)>

<!ATTLIST column
                 name CDATA>

=head1 SEE ALSO

=over

=item AxKit (http://axkit.org)

=item DBD::SQLite

=item DBI

=item Apache::DBI

=back

=head1 AUTHOR

Tom Schindl, <lt>tom.schindl@bestsolution.at<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Tom Schindl

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
