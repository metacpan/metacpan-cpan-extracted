# NAME
CHI::Driver::MySQL - Use MySQL for cache storage

# SYNOPSIS
    use CHI;
    
    # Supply Data Source Name, defaults to C<dbi:mysql:dbname=test>.
    #
    my $cache = CHI->new( driver => 'MySQL', dsn => 'mysql://user:password@host:port/database' );

# DESCRIPTION
This driver uses a `chi_cache` table to store the cache. The table is created by the driver itself.


Encode is required for encoding as UTF-8 the value that is about to be stored in database

Mojo::mysql is required for connection to database

# AUTHOR
Adrian Crisan, <lt>adrian.crisan88@gmail.com<gt>
