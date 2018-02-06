use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use DBI;

my $dsn = 'dbi:mysqlPPrawSjis:database=test';
# my $dsn = 'dbi:mysqlPP:database=test';
# my $dsn = 'dbi:mysql:database=test';

my $dbuser     = 'root';
my $dbpassword = '';
my $dbh;

print STDERR "Test $dsn\n";
print "on $^X $]\n\n";

eval {
    $dbh = DBI->connect(
        $dsn,
        $dbuser,
        $dbpassword,
        {
            'PrintError' => 0,
            'RaiseError' => 1,
            'AutoCommit' => 1,
        }
    );
};
if ($@) {
    die "Can't connect $dsn";
}

my $sth1;
my $sth2;
my $sth3;
my $sth4;
eval {
    $dbh->do(q{DROP TABLE IF EXISTS sjistest});
    $dbh->do(q{CREATE TABLE IF NOT EXISTS sjistest (id INT(4), c CHAR(40), code VARCHAR(4))});

    $sth1 = $dbh->prepare(q{INSERT INTO sjistest (id,c,code) VALUES (?,?,?)});
    $sth2 = $dbh->prepare(q{SELECT id,c,code FROM sjistest WHERE id=?});
    $sth3 = $dbh->prepare(q{DELETE FROM sjistest WHERE id=?});
    $sth4 = $dbh->prepare(q{SELECT id,c,code FROM sjistest WHERE c=?});
};
if ($@) {
    die "Can't prepare";
}

my @char = ();

for my $low (0x00..0xFF) {
    next if $low == 0x80;
    next if $low == 0xA0;
    next if $low == 0xFD;
    next if $low == 0xFE;
    next if $low == 0xFF;

    push @char, [ $low, $low ];
}

for my $high (0x81..0x9F, 0xE0..0xFC) {
    for my $low (0x40..0x7E, 0x80..0xFC) {
        push @char, [ $high, $low ];
    }
}

my $id = 1;
my $neq = 0;
open(LOG,'>mysql_sjistest.log') || die "Can't open file: mysql_sjistest.log";
for my $char (@char) {
    print STDERR "$id," unless $id % 100;

    my($high, $low) = @{$char};
    $_ = pack 'CC', $high, $low;
    printf LOG "%02X%02X\t$_", $high, $low;

    eval {
        $sth3->execute($id);
    };
    if ($@) {
        print LOG "\tDelete NG";
        print LOG "\n";
        next;
    }

    eval {
        $sth1->execute($id, $_, sprintf('%02X%02X',unpack('CC',$_)));
    };
    if ($@) {
        print LOG "\tInsert NG";
    }
    else {
        print LOG "\tInsert OK";
    }

    eval {
        $sth2->execute($id);
        while (my($id,$c,$code) = $sth2->fetchrow_array()) {

            # MySQL trim last space of string
            if ($_ eq (' ' x 2)) {
                if ($c ne '') {
                    die;
                }
            }
            else {
                if ($c ne $_) {
                    printf STDERR ("<$_(%02X%02X)> was stored as <$c(%02X%02X)> select by id.\n", unpack('CC',$_), unpack('CC',$c));
                    $neq++;
                }
                if ($code ne sprintf('%02X%02X',unpack('CC',$_))) {
                    print STDERR "<", sprintf('%02X%02X',unpack('CC',$_)), "> was stored as <$code> select by id.\n";
                    $neq++;
                }
            }
        }
    };
    if ($@) {
        print LOG "\tIDselect NG";
    }
    else {
        print LOG "\tIDselect OK";
    }

    eval {
        $sth4->execute($_);
        while (my($id,$c,$code) = $sth4->fetchrow_array()) {

            # MySQL trim last space of string
            if ($_ eq (' ' x 2)) {
                if ($c ne '') {
                    die;
                }
            }
            else {
                if ($c ne $_) {
                    printf STDERR ("<$_(%02X%02X)> was stored as <$c(%02X%02X)> select by character\n", unpack('CC',$_), unpack('CC',$c));
                    $neq++;
                }
                if ($code ne sprintf('%02X%02X',unpack('CC',$_))) {
                    print STDERR "<", sprintf('%02X%02X',unpack('CC',$_)), "> was stored as <$code> select by character\n";
                    $neq++;
                }
            }
        }
    };
    if ($@) {
        print LOG "\tSelect NG";
    }
    else {
        print LOG "\tSelect OK";
    }

    eval {
        $sth3->execute($id);
    };
    if ($@) {
        print LOG "\tDelete NG";
    }
    else {
        print LOG "\tDelete OK";
    }

    print LOG "\n";
    $id++;
}
close(LOG);

if ($neq == 0) {
    print STDERR "\n\nTEXT data type can handle all code point of ShiftJIS.\n";
}

END {
    if (defined $dbh) {
        $dbh->disconnect();
    }
    print STDERR "See result file: mysql_sjistest.log\n";
}

__END__
