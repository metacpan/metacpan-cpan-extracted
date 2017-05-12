package Apache::AxKit::Provider::RDBMS::ContentProvider::MultiSQL;

use base qw( Apache::AxKit::Provider::RDBMS::ContentProvider );
use DBI;
use strict;

sub getContent {
    my $this = shift;
    my $dbiString    = $this->{apache}->dir_config("DBIString");
    my $dbiUser      = $this->{apache}->dir_config("DBIUser");
    my $dbiPwd       = $this->{apache}->dir_config("DBIPwd");
    my @sqlStatements = $this->{apache}->dir_config->get("DBIQuery");
    
    my $dbh = DBI->connect($dbiString, $dbiUser, $dbiPwd);
    
    my $xml = "<?xml version='1.0'?>";
    my $sqlStatement;
    my $sth;
    my $rows;
    my $row;
        
    $xml .= "<sql-results>";
    
    foreach $sqlStatement ( @sqlStatements ) {
        $sqlStatement =~ s/(\w+) => //;
        
        $sth = $dbh->prepare( $sqlStatement );
        $sth->execute();
    
        $rows = $sth->fetchall_arrayref( {} );
        $row;
    
        $xml .= "\n<sql-result name='$1'>\n";
    
        foreach( @{ $rows }  ) {
            $row = $_;
            $xml .= "\n<row>\n";
        
            foreach( keys %{ $row } ) {
                $xml .= "<column name='$_'>".$row->{$_}."</column>\n";
            }
        
            $xml .= "</row>";
        }
    
        $xml .= "</sql-result>\n";
    }

    $xml .= "</sql-results>";
        
    return $xml;
}

return 1;