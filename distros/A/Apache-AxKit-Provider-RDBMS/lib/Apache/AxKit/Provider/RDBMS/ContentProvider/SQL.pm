package Apache::AxKit::Provider::RDBMS::ContentProvider::SQL;

use base qw( Apache::AxKit::Provider::RDBMS::ContentProvider );
use DBI;
use strict;

sub getContent {
    my $this = shift;
    my $dbiString    = $this->{apache}->dir_config("DBIString");
    my $dbiUser      = $this->{apache}->dir_config("DBIUser");
    my $dbiPwd       = $this->{apache}->dir_config("DBIPwd");
    my $sqlStatement = $this->{apache}->dir_config("DBIQuery");
    
    my $dbh = DBI->connect($dbiString, $dbiUser, $dbiPwd);
    
    my $xml = "<?xml version='1.0'?>";
    
    my $sth = $dbh->prepare( $sqlStatement );
    $sth->execute();
    
    my $rows = $sth->fetchall_arrayref( {} );
    my $row;
    
    $xml .= "<sql-results>\n";
    $xml .= "<sql-result name='default'>";
    
    foreach( @{ $rows }  ) {
        $row = $_;
        $xml .= "\n<row>\n";
        
        foreach( keys %{ $row } ) {
            $xml .= "<column name='$_'>".$row->{$_}."</column>\n";
        }
        
        $xml .= "</row>";
    }
    
    $xml .= "</sql-result>\n";
    $xml .= "</sql-results>";
    
    return $xml;
}

return 1;