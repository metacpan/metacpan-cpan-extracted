package t::Util;

use strict;
use warnings;
use DBI;
use File::Temp qw/tempfile/;
use base 'Exporter';
use Benchmark qw/:hireswallclock/;
use IO::Handle;

our @EXPORT = qw/capture cmpthese/;

sub new_dbh {
    my ($fh, $file) = tempfile;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$file",'','', {
        AutoCommit => 1,
        RaiseError => 1,
    });
    return $dbh;
}

sub setup_mysqld {
    eval { require Test::mysqld; 1 } or return;
    my $mysqld;
    if (my $json = $ENV{__TEST_DBIxTracer}) {
        eval { require JSON; 1 } or return;
        my $obj = JSON::decode_json($json);
        $mysqld = bless $obj, 'Test::mysqld';
    }
    else {
        $mysqld = Test::mysqld->new(my_cnf => {
            'skip-networking' => '',
        }) or return;
    }
    return $mysqld;
}

sub capture(&) {
    my ($code) = @_;

    my @logs;
    my $tracer = DBIx::Tracer->new(sub {
        my %args = @_;
        push @logs, \%args;
    });

    $code->();

    return @logs;
}

sub cmpthese {
    my $result = Benchmark::timethese(@_);
    for my $value (values %$result) {
        $value->[1] = $value->[2] = $value->[0];
    };
    Benchmark::cmpthese($result);
}

1;
