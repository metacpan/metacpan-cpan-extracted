package Apache::AxKit::Provider::RDBMS::DBCacheAdapter::SQLite;

use base qw( Apache::AxKit::Provider::RDBMS::DBCacheAdapter );

use strict;

sub mtime {
    my $this = shift;
    
    my $DBIString = $this->{apache}->dir_config("DBIString");
    $DBIString =~ /=(.+)$/;
    
    return (stat($1))[9];
}

1;