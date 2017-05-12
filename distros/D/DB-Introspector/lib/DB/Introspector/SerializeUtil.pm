package DB::Introspector::SerializeUtil;

use strict;
use Storable qw( nstore_fd fd_retrieve );


sub serialize {
    my $class = shift;
    my $introspector = shift;
    my $fh = shift || *STDOUT;

    my $dbh = $introspector->dbh;
    $introspector->_clear_dbh;

    my %storage_hash;
    $storage_hash{dbname} = _dbh_id($dbh);
    $storage_hash{introspector} = $introspector;

    nstore_fd(\%storage_hash, $fh);

    $introspector->_set_dbh($dbh);
}

sub serialize_to_file {
    my $class = shift;
    my $introspector = shift;
    my $filename = shift; 

    my $fh = new IO::File( ">$filename" )
        || die($!);
    $class->serialize($introspector, $fh);
}


sub deserialize {
    my $class = shift;
    my $fh = shift;
    my $dbh = shift || die("\$class->deserialize(\$fh, \$dbh) requires a dbh");

    my $storage_ref = fd_retrieve($fh);
    if( $storage_ref->{dbname} ne _dbh_id($dbh) ) {
        die("DBName in handle: ", _dbh_id($dbh), " 
            doesn't match dbname in serialized: ",
            $storage_ref->{dbname});
    } 

    my $introspector = $storage_ref->{introspector};
    $introspector->_set_dbh($dbh);
    return $introspector;
}


sub deserialize_from_file {
    my $class = shift;
    my $filename = shift;
    my $dbh = shift;

    my $fh = new IO::File($filename) || die($!);
    my $introspector = $class->deserialize($fh, $dbh);
    $fh->close;
    return $introspector;
}

sub _dbh_id {
    my $dbh = shift;
    return join(',', $dbh->{Name}, $dbh->{Username});
}

1;
