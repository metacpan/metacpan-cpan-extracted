use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_fh );

# Need to have an explicit plan in order for the sub-testing to work right.
#XXX Figure out how to use subtests for that.
my $pre_fork_tests = 14;
plan tests => $pre_fork_tests + 2;

use_ok( 'DBM::Deep' );

{
    my ($fh, $filename) = new_fh();

    # Create the datafile to be used
    {
        my $db = DBM::Deep->new( $filename );
        $db->{hash} = { foo => [ 'a' .. 'c' ] };
    }

    {
        open(my $fh, '<', $filename) || die("Can't open '$filename' for reading: $!\n");

        # test if we can open and read a db using its filehandle

        my $db;
        ok( ($db = DBM::Deep->new( fh => $fh )), "open db in filehandle" );
        ok( $db->{hash}{foo}[1] eq 'b', "and get at stuff in the database" );
        throws_ok {
            $db->{foo} = 1;
        } qr/Cannot write to a readonly filehandle/, "Can't write to a read-only filehandle";
        ok( !$db->exists( 'foo' ), "foo doesn't exist" );

        throws_ok {
            delete $db->{foo};
        } qr/Cannot write to a readonly filehandle/, "Can't delete from a read-only filehandle";

        throws_ok {
            %$db = ();
        } qr/Cannot write to a readonly filehandle/, "Can't clear from a read-only filehandle";

        SKIP: {
            skip( "No inode tests on Win32", 1 )
                if ( $^O eq 'MSWin32' || $^O eq 'cygwin' );
            my $db_obj = $db->_get_self;
            ok( $db_obj->_engine->storage->{inode}, "The inode has been set" );
        }

        close($fh);
    }
}

# now the same, but with an offset into the file.  Use the database that's
# embedded in the test for the DATA filehandle.  First, find the database ...
{
    my ($fh,$filename) = new_fh();

    print $fh "#!$^X\n";
    print $fh <<"__END_FH__";
my \$t = $pre_fork_tests;

print "not " unless eval { require DBM::Deep };
print "ok ", ++\$t, " - use DBM::Deep\n";

my \$db = DBM::Deep->new({
    fh => *DATA,
});
print "not " unless \$db->{x} eq 'b';
print "ok ", ++\$t, " - and get at stuff in the database\n";
__END_FH__

    # The exec below prevents END blocks from doing this.
    (my $esc_dir = $t::common::dir) =~ s/(.)/sprintf "\\x{%x}", ord $1/egg;
    print $fh <<__END_FH_AGAIN__;
use File::Path 'rmtree';
rmtree "$esc_dir"; 
__END_FH_AGAIN__

    print $fh "__DATA__\n";
    close $fh;

    my $offset = do {
        open my $fh, '<', $filename;
        while(my $line = <$fh>) {
            last if($line =~ /^__DATA__/);
        }
        tell($fh);
    };

    {
        my $db = DBM::Deep->new({
            file        => $filename,
            file_offset => $offset,
            #XXX For some reason, this is needed to make the test pass. Figure
            #XXX out why later.
            locking => 0,
        });

        $db->{x} = 'b';
        is( $db->{x}, 'b', 'and it was stored' );
    }

    {
        open my $fh, '<', $filename;
        my $db = DBM::Deep->new({
            fh          => $fh,
            file_offset => $offset,
        });

        is($db->{x}, 'b', "and get at stuff in the database");

        ok( !$db->exists( 'foo' ), "foo doesn't exist yet" );
        throws_ok {
            $db->{foo} = 1;
        } qr/Cannot write to a readonly filehandle/, "Can't write to a read-only filehandle";
        ok( !$db->exists( 'foo' ), "foo still doesn't exist" );

        is( $db->{x}, 'b' );
    }

    exec( "$^X -Iblib/lib $filename" );
}
