use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";

use CSV::LINQ;

my @tests = ();
my($PASS, $FAIL, $T) = (0, 0, 0);

sub ok {
    my($cond, $name) = @_;
    $T++;
    if ($cond) { $PASS++; print "ok $T - $name\n" }
    else { $FAIL++; print "not ok $T - $name\n" }
}

sub is {
    my($got, $exp, $name) = @_;
    $T++;
    if (defined $got && defined $exp && $got eq $exp) {
        $PASS++; print "ok $T - $name\n";
    }
    else {
        $FAIL++; print "not ok $T - $name\n";
        print "# got: " . (defined $got ? $got : '(undef)') . "\n";
        print "# exp: " . (defined $exp ? $exp : '(undef)') . "\n";
    }
}

sub _tmpdir {
    return $ENV{TEMP} || $ENV{TMP} || '/tmp';
}

sub make_csv {
    my $f = _tmpdir() . "/csv_linq_$$" . "_" . $T . ".csv";
    open(MCSV, ">$f") or die "Cannot create $f: $!";
    print MCSV "name,age,city\n";
    print MCSV "Alice,30,Tokyo\n";
    print MCSV "Bob,25,Osaka\n";
    print MCSV "Carol,35,Tokyo\n";
    close(MCSV);
    return $f;
}

# FromCSV: basic read
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->ToArray();
    unlink $f;
    is(scalar(@r), 3, 'FromCSV basic count');
};
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->ToArray();
    unlink $f;
    is($r[0]{name}, 'Alice', 'FromCSV first name');
};
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->ToArray();
    unlink $f;
    is($r[0]{age}, 30, 'FromCSV first age');
};
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->ToArray();
    unlink $f;
    is($r[2]{city}, 'Tokyo', 'FromCSV last city');
};

# FromCSV + Where
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')->ToArray();
    unlink $f;
    is(scalar(@r), 2, 'FromCSV+Where count');
};
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')->ToArray();
    unlink $f;
    is($r[0]{name}, 'Alice', 'FromCSV+Where first name');
};
push @tests, sub {
    my $f = make_csv();
    my @r = CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')->ToArray();
    unlink $f;
    is($r[1]{name}, 'Carol', 'FromCSV+Where second name');
};

# ToCSV: line count
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')->ToCSV($out);
    open(RD, $out) or die "Cannot open $out: $!";
    my @lines = <RD>; close(RD);
    unlink $f; unlink $out;
    is(scalar(@lines), 3, 'ToCSV line count header+2');
};

# ToCSV: header line (sort keys default)
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')->ToCSV($out);
    open(RD, $out) or die;
    my $hdr = <RD>; close(RD);
    unlink $f; unlink $out;
    $hdr =~ s/\r?\n\z//;
    is($hdr, 'age,city,name', 'ToCSV default sort header');
};

# ToCSV with headers option
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')
        ->ToCSV($out, headers => [qw(name city age)]);
    open(RD, $out) or die;
    my $hdr = <RD>; close(RD);
    unlink $f; unlink $out;
    $hdr =~ s/\r?\n\z//;
    is($hdr, 'name,city,age', 'ToCSV headers order');
};

# ToCSV with headers: data values
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')
        ->ToCSV($out, headers => [qw(name city age)]);
    open(RD, $out) or die;
    my @lines = <RD>; close(RD);
    unlink $f; unlink $out;
    $lines[1] =~ s/\r?\n\z//;
    is($lines[1], 'Alice,Tokyo,30', 'ToCSV headers data values');
};

# ToCSV with label_order alias (header)
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')
        ->ToCSV($out, label_order => [qw(city name age)]);
    open(RD, $out) or die;
    my $hdr = <RD>; close(RD);
    unlink $f; unlink $out;
    $hdr =~ s/\r?\n\z//;
    is($hdr, 'city,name,age', 'ToCSV label_order header');
};

# ToCSV with label_order alias (data)
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->Where(city => 'Tokyo')
        ->ToCSV($out, label_order => [qw(city name age)]);
    open(RD, $out) or die;
    my @lines = <RD>; close(RD);
    unlink $f; unlink $out;
    $lines[1] =~ s/\r?\n\z//;
    is($lines[1], 'Tokyo,Alice,30', 'ToCSV label_order data values');
};

# ToCSV: round-trip
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->ToCSV($out, headers => [qw(name age city)]);
    my @r = CSV::LINQ->FromCSV($out)->Where(city => 'Tokyo')->ToArray();
    unlink $f; unlink $out;
    is(scalar(@r), 2, 'ToCSV round-trip count');
};
push @tests, sub {
    my $f = make_csv();
    my $out = _tmpdir() . "/csv_linq_out_$$" . "_" . $T . ".csv";
    CSV::LINQ->FromCSV($f)->ToCSV($out, headers => [qw(name age city)]);
    my @r = CSV::LINQ->FromCSV($out)->Where(city => 'Tokyo')->ToArray();
    unlink $f; unlink $out;
    is($r[0]{name}, 'Alice', 'ToCSV round-trip first name');
};

# TSV support (sep => "\t")
push @tests, sub {
    my $f = _tmpdir() . "/csv_linq_tsv_$$" . "_" . $T . ".tsv";
    open(MTSV, ">$f") or die;
    print MTSV "name\tage\tcity\n";
    print MTSV "Alice\t30\tTokyo\n";
    print MTSV "Bob\t25\tOsaka\n";
    close(MTSV);
    my @r = CSV::LINQ->FromCSV($f, sep => "\t")->ToArray();
    unlink $f;
    is(scalar(@r), 2, 'TSV count');
};
push @tests, sub {
    my $f = _tmpdir() . "/csv_linq_tsv_$$" . "_" . $T . ".tsv";
    open(MTSV, ">$f") or die;
    print MTSV "name\tage\tcity\n";
    print MTSV "Alice\t30\tTokyo\n";
    print MTSV "Bob\t25\tOsaka\n";
    close(MTSV);
    my @r = CSV::LINQ->FromCSV($f, sep => "\t")->ToArray();
    unlink $f;
    is($r[0]{name}, 'Alice', 'TSV first name');
};
push @tests, sub {
    my $f = _tmpdir() . "/csv_linq_tsv_$$" . "_" . $T . ".tsv";
    open(MTSV, ">$f") or die;
    print MTSV "name\tage\tcity\n";
    print MTSV "Alice\t30\tTokyo\n";
    print MTSV "Bob\t25\tOsaka\n";
    close(MTSV);
    my @r = CSV::LINQ->FromCSV($f, sep => "\t")->ToArray();
    unlink $f;
    is($r[1]{city}, 'Osaka', 'TSV second city');
};

# Quoted fields with comma
push @tests, sub {
    my $f = _tmpdir() . "/csv_linq_q_$$" . "_" . $T . ".csv";
    open(MQ, ">$f") or die;
    print MQ "name,note\n";
    print MQ "Alice,\"hello, world\"\n";
    print MQ "Bob,normal\n";
    close(MQ);
    my @r = CSV::LINQ->FromCSV($f)->ToArray();
    unlink $f;
    is($r[0]{note}, 'hello, world', 'FromCSV quoted comma');
};

# Concurrent FromCSV (Join)
push @tests, sub {
    my $f1 = _tmpdir() . "/csv_linq_c1_$$" . "_" . $T . ".csv";
    my $f2 = _tmpdir() . "/csv_linq_c2_$$" . "_" . $T . ".csv";
    open(MC1, ">$f1") or die;
    print MC1 "id,name\n1,Alice\n2,Bob\n";
    close(MC1);
    open(MC2, ">$f2") or die;
    print MC2 "id,city\n1,Tokyo\n2,Osaka\n";
    close(MC2);
    my @r = CSV::LINQ->FromCSV($f1)->Join(
        CSV::LINQ->FromCSV($f2),
        sub { $_[0]{id} }, sub { $_[0]{id} },
        sub { { name => $_[0]{name}, city => $_[1]{city} } }
    )->ToArray();
    unlink $f1; unlink $f2;
    is(scalar(@r), 2, 'concurrent FromCSV Join count');
};
push @tests, sub {
    my $f1 = _tmpdir() . "/csv_linq_c1_$$" . "_" . $T . ".csv";
    my $f2 = _tmpdir() . "/csv_linq_c2_$$" . "_" . $T . ".csv";
    open(MC1, ">$f1") or die;
    print MC1 "id,name\n1,Alice\n2,Bob\n";
    close(MC1);
    open(MC2, ">$f2") or die;
    print MC2 "id,city\n1,Tokyo\n2,Osaka\n";
    close(MC2);
    my @r = CSV::LINQ->FromCSV($f1)->Join(
        CSV::LINQ->FromCSV($f2),
        sub { $_[0]{id} }, sub { $_[0]{id} },
        sub { { name => $_[0]{name}, city => $_[1]{city} } }
    )->ToArray();
    unlink $f1; unlink $f2;
    is($r[0]{name}, 'Alice', 'concurrent FromCSV Join first name');
};
push @tests, sub {
    my $f1 = _tmpdir() . "/csv_linq_c1_$$" . "_" . $T . ".csv";
    my $f2 = _tmpdir() . "/csv_linq_c2_$$" . "_" . $T . ".csv";
    open(MC1, ">$f1") or die;
    print MC1 "id,name\n1,Alice\n2,Bob\n";
    close(MC1);
    open(MC2, ">$f2") or die;
    print MC2 "id,city\n1,Tokyo\n2,Osaka\n";
    close(MC2);
    my @r = CSV::LINQ->FromCSV($f1)->Join(
        CSV::LINQ->FromCSV($f2),
        sub { $_[0]{id} }, sub { $_[0]{id} },
        sub { { name => $_[0]{name}, city => $_[1]{city} } }
    )->ToArray();
    unlink $f1; unlink $f2;
    is($r[1]{city}, 'Osaka', 'concurrent FromCSV Join second city');
};

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
exit($FAIL ? 1 : 0);
