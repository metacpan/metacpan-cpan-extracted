package CGI::Uploader::Test;
use Test::More;
use Carp;
use base 'Exporter';
use strict;

# These vars are package-scope so we can call them in the END block.
use vars (qw/@EXPORT 
$DBH $drv $created_up_table $created_test_table
/);

@EXPORT = (qw/
    &setup 
    &read_file
    &test_gen_transform 
/);

=head2 setup

 my ($DBH,$drv) = setup();

Set up empty database tables for testing and return a database handle. 

Runs some Test::More Tests.

Dies if there is a problem.

=cut 

sub setup {
    my %p = @_;

    use vars qw($dsn $user $password);
    my $file ='t/cgi-uploader.config';
    my $return;
    unless ($return = do $file) {
        warn "couldn't parse $file: $@" if $@;
        warn "couldn't do $file: $!"    unless defined $return;
        warn "couldn't run $file"       unless $return;
    }

    # For SQLite
 	 unlink <t/test.db>;

    ok($return, 'loading configuration');
    $DBH =  DBI->connect($dsn,$user,$password);
    ok($DBH,'connecting to database'), 

    # create uploads table
    $drv = $DBH->{Driver}->{Name};

    if ($drv eq 'SQLite') {
        # diag "testing with SQLite version: " .$DBH->selectrow_array("SELECT sqlite_version()");
    }

    if (not $p{skip_create_uploader_table}) {
        ok(open(IN, "<create_uploader_table.".$drv.".sql"), 'opening SQL create file');
        my $sql = join "\n", (<IN>);
        $created_up_table = $DBH->do($sql);
        ok($created_up_table, 'creating uploads table');
    }

    ok(open(IN, "<t/create_test_table.sql"), 'opening SQL create test table file');
    my $item_tbl_sql = join "\n", (<IN>);

    # Fix mysql non-standard quoting
    $item_tbl_sql =~ s/"/`/gs if ($drv eq 'mysql');

    $created_test_table = $DBH->do($item_tbl_sql);
    ok($created_test_table, 'creating test table') || croak;

    return ($DBH,$drv);

}

=head2 read_file

my $file_contents_as_one_line = read_file('file.txt');

Slurp a file, like File::Slurp;

=cut

sub read_file {
    my $file = shift;
    local( $/, *FH );
    open( FH, $file ) or croak "failed to open file: $file: $!\n";
    my $text = <FH>;
    return $text;
}

# A trivial transform method for testing
sub test_gen_transform {
    my $self = shift;
    my $path = shift;
    my $file_contents = read_file($path);
    $file_contents =~ s/test/generated/;
    # remove possible leading "t/"
    $path =~ s?^t/??;
    my $new_path = "t/$path".'.gen';
    open(OUT, ">$new_path")  || croak "can't open $new_path";
    print OUT $file_contents;
    close(OUT);
    return $new_path;
}



# We use an end block to clean up even if the script dies.
 END {
 	unlink <t/uploads/*>;
 	if ($DBH) {
        # For SQLite, just delete the whole database file. :)
        if ($drv eq 'SQLite') {
            $DBH->disconnect;
 	        unlink <t/test.db>;
        }
        else {
            if ($created_up_table) {
                $DBH->do("DROP SEQUENCE upload_id_seq") if ($drv eq 'Pg');
                $DBH->do("DROP TABLE uploads");
            }
            if ($created_test_table) {
                $DBH->do('DROP TABLE cgi_uploader_test');
            }
        }
        $DBH->disconnect;
 	}
 };

1;

