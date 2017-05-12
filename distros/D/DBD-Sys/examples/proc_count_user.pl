#proc_count_user.pl
# 	- Displays question for the user (username or * as wildcard for all) and lists the number
#       - of processes for the selected or each user found.
#       - Alexander Breibach, 2009-10-10

use DBI;
use Getopt::Long;
use Text::TabularDisplay;

my @opt_uid = ();    # setting the option blank, so the SQL statement runs for all users.

my $dbh = DBI->connect("DBI:Sys:");

my %options = ( "uid=i{,}" => \@opt_uid );

if ( GetOptions(%options) )    # "=" means required, "i" means integer
{
    @opt_uid = split( m/,/, join( ',', @opt_uid ) );
    my $more_clause = '';

    if (@opt_uid)
    {
        $more_clause = " AND procs.uid IN(" . join( ',', map { "'$_'" } @opt_uid ) . ")";
    }

    my $st =
      $dbh->prepare(   "SELECT username, COUNT(procs.uid) as process_ct "
                     . "FROM procs, pwent "
                     . "WHERE procs.uid=pwent.uid $more_clause "
                     . "GROUP BY username" );

    my $num = $st->execute();

    my $table = Text::TabularDisplay->new( qw(Username Processes));
    $table->add(@row)
        while (@row = $st->fetchrow);
    print $table->render . "\n";

}    # GetOpt succeed, else failed
