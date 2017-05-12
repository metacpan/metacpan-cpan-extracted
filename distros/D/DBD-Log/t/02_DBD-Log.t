use Test::More tests => 3;

use DBI;
use DBD::Log;
use IO::File;
use IO::Handle;

my $dbi = DBI->connect("DBI:Mock:database=test", "user", "pass");

unlink "test.log";
{ # test scope
  my $fh   = IO::File->new( ">test.log" );

  $dbi = DBD::Log->new( dbi => $dbi,
                        logFH => $fh,
                        dbiLogging => 1,
                      );

  $dbi->prepare("SELECT * FROM my_table");
  my $sth = $dbi->prepare("SELECT * FROM my_table WHERE id=?");
  $sth->execute(1);

  $fh->close;
}

{ # reading scope
  my $fh   = IO::File->new( "<test.log" );
  { my $line = <$fh>;

    is(substr($line, 11), "[prepare]\tSELECT * FROM my_table\n")
  };

  { my $line = <$fh>;
    ok($line =~ /prepare/);
  };

  { my $line = <$fh>;
    is(substr($line, 11), "SELECT * FROM my_table WHERE id=1\n")
  };

}

unlink "test.log";