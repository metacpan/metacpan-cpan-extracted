#
#

=head1 NAME

Bio::DB::EasyArgv

=head1 SYNOPSIS

 <TODO>

=head1 DESCRIPTION

This is a lazy-but-easy way to get the dbcontext arguments. All you need to do 
is to invoke get_dbcontext_from_argv before using the standard Getopt. The below
options will be absorbed and removed from @ARGV.

db_file, host, dbname, dbuser, dbpass, driver

Now you can take the advantage of Perl's do method to execute a file as perl
script and get returned the last line of it. For your most accessed dbcontext
setting, you can have a filed named, say biosql.perlobj, with the content like

    use strict; # The ceiling line
    use Bio::DB::SimpleDBContext;
    use Bio::DB::BioDB;

    my $dbc = Bio::DB::SimpleDBContext->new(
        -driver => 'mysql',
        -dbname => 'ontology_biosql',
        -host => 'localhost',
        -user => 'root',
        -pass => ''
    );
    my $adaptor = Bio::DB::BioDB->new(
        -database => 'biosql',
        -dbcontext => $dbc
    );
    return $adaptor; # The floor line

In your command line, you just need to type like

perl clear_ontology.pl --db_file ontology_biosql.perlobj --ontology_name InterPro

rather than the classic verbose one.

=head1 AUTHOR

Juguang XIAO, juguang@tll.org.sg

=cut

package Bio::DB::EasyArgv;
use strict;
use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(get_biosql_db_from_argv);
use Bio::DB::SimpleDBContext;
use Bio::DB::BioDB;
use Getopt::Long;

sub get_biosql_db_from_argv {
    my ($db_file, $host, $user, $pass, $dbname, $driver)=
        (undef, 'localhost', 'root', undef, '', 'mysql');
    
    Getopt::Long::config('pass_through');
    &GetOptions(
        'db_file=s' => \$db_file,
        'host|dbhost=s' => \$host,
        'user|dbuser=s' => \$user,
        'pass|dbpass=s' => \$pass,
        'driver|dbdriver=s' => \$driver,
        'dbname=s' => \$dbname
    );
    my $db;
    if(defined $db_file){
        -e $db_file or die "$db_file is defined but does not exist\n";
        eval{$db=do($db_file)};
        $@ and die "$db_file is not a perlobj file\n";
       
    }elsif(defined $host and defined $user and defined $dbname){
        $db = Bio::DB::BioDB->new(
            -database => 'biosql',
            -dbcontext => Bio::DB::SimpleDBContext->new(
                -driver => $driver,
                -dbname => $dbname,
                -host => $host,
                -user => $user,
                -pass => $pass
            )
        );
    }else{
        die "Cannot get the db, due to the insufficient information\n";
    }
    return $db;
}

1;
