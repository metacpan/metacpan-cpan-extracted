use DBI;
use strict;

sub handle_error
{
    my ($state, $msg, $native) = @_;
    print qq{handle_error: \$state  is "$state".}, "\n";
    print qq{handle_error: \$msg    is "$msg".}, "\n";
    print qq{handle_error: \$native is "$native".}, "\n";
    return 0;

}
my $dbh = DBI->connect('dbi:ODBC:baugi','sa','easysoft',
                      {
                          #odbc_err_handler => \&handle_error,
});

eval {
   local $dbh->{PrintError} = 0;
   $dbh->do("drop procedure t_raiserror");
};

$dbh->do(<<'EOT');
CREATE PROCEDURE  t_raiserror (@p1 varchar(50), @p2 int output)
AS
set @p2=45;
raiserror ('An error was raised. Input was "%s".', 16, 1, @p1)
return 55
EOT

sub test()
{
   my $sth = $dbh->prepare("{? = call t_raiserror(?,?)}");

   my ($p1, $p2) = ('fred', undef);
   $sth->bind_param_inout(1, \my $retval, 4000);
   $sth->bind_param(2, $p1);
   $sth->bind_param_inout(3, \$p2, 32);
   $sth->execute();
   print qq/After execute:\n/;
   print "err=", $sth->err(), "\n";
   print "errstr=", $sth->errstr(), "\n";
   print "state=", DBI::neat($sth->state()), "\n";
   print qq{\$retval is $retval.}, "\n";
   print qq{\$p1     is $p1.}, "\n";
   print qq{\$p2     is $p2.}, "\n";
}

test();

$dbh->disconnect;

