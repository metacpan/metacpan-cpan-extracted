#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More;
use Encode qw(decode encode);

use File::Temp qw(tempfile tempdir);
use File::Spec::Functions qw(catfile);
use File::Path qw(remove_tree);

BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    eval {
        require DBI;
        require DBD::SQLite;
    };

    if ($@) {
        plan skip_all => "DBD::SQLite isn't installed properly";
    } else {
        plan tests => 12;
    }

    use_ok 'AnyEvent';
    use_ok 'AnyEvent::ForkObject';
    use_ok 'AnyEvent::Tools', 'async_repeat';
}

sub rand_str();

our $tmp_dir = tempdir;
END { remove_tree $tmp_dir if $tmp_dir and -d $tmp_dir };

my $cv = condvar AnyEvent;
my $fo = new AnyEvent::ForkObject;

my $db_file = catfile $tmp_dir, 'db.sqlite';

my $dbh;
$fo->do(
    method  => 'connect',
    module  => 'DBI',
    args    => [ "dbi:SQLite:dbname=$db_file", '', '', { RaiseError => 1 } ],
    cb      => sub {
        my ($s, $db) = @_;
        $dbh = $db;
        ok $s eq 'ok', 'DBI connected';
        $dbh->do(q{
            CREATE TABLE tbl
            (
                id      INTEGER PRIMARY KEY AUTOINCREMENT,
                txt     TEXT NOT NULL
            )
        }, sub {
            my ($s, $res) = @_;
            diag explain \@_ unless ok $s eq 'ok', 'Table "tbl" was created';

            my $count = 0;
            my $ok = 1;
            for (1 .. 50) {
                $dbh->do('INSERT INTO tbl (txt) VALUES (?)', undef, rand_str,
                    sub {
                        my ($s, $res) = @_;
                        unless ($s eq 'ok') {
                            diag explain \@_;
                            $ok = 0;
                        }

                        if (++$count == 50) {
                            ok $ok, '50 records were inserted';

                            $dbh->selectall_arrayref(
                                'SELECT * FROM tbl', { Slice => {} },
                                sub {
                                    my ($s, $res) = @_;
                                    ok $s eq 'ok', 'SELECT was done';
                                    ok @$res == 50, 'Fetched all rows';
                                    ok 'HASH' eq ref $res->[0],
                                        'Slice works properly';

                                    $cv->send;
                                }
                            );

                        }
                    }
                );

            }

        });
    }
);

$cv->recv;

$cv = condvar AnyEvent;
$dbh->prepare('SELECT * FROM tbl', sub {
    my ($s, $sth) = @_;
    ok $s eq 'ok', 'Prepare statement';
    $sth->execute(sub {
        my ($s, $rv) = @_;
        ok $s eq 'ok', 'Execute statement';

        my $ok = 1;
        async_repeat 50, sub {
            my ($guard, $index, $first, $last) = @_;

            $sth->fetchrow_hashref(sub {
                undef $guard;
                my ($s, $row) = @_;
                $ok = 0 unless $s eq 'ok';
                $ok = 0 unless 'HASH' eq ref $row;
                $ok = 0 unless $row->{id} == $index + 1;

                if ($last) {
                    ok $ok, 'All data fetched';
                    undef $sth;
                    undef $dbh;
                    my $t;
                    $t = AE::timer 0.5, 0 => sub {
                        undef $t;
                        $cv->send;
                    }
                }
            });

        };

    });
});

$cv->recv;


sub rand_str()
{
    my $letters = q!qwertyuiopasdfghjkl;'][zxcvbnm,./йцукенгшщзхъфывапролджэ!;
    my $str = '';
    $str .= substr $letters, int(rand length $letters), 1 for 0 .. 3 + rand 100;
    return $str;
}
