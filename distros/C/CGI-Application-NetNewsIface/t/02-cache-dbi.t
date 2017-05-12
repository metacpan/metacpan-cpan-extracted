#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");

use CGI::Application::NetNewsIface::Test::MockNNTP;
use CGI::Application::NetNewsIface::Test::Data1;

use DBI;

use CGI::Application::NetNewsIface::Cache::DBI;
use CGI::Application::NetNewsIface;

my $db_file = File::Spec->catfile("t", "data", "testdb.sqlite");
my $dsn = "dbi:SQLite:dbname=$db_file";

sub create_db
{
    unlink($db_file);

    my $app = CGI::Application::NetNewsIface->new(
        PARAMS => {
            'nntp_server' => "nntp.shlomifish.org",
            'articles_per_page' => 10,
            'dsn' => $dsn,
        },
    );
    $app->init_cache__sqlite();
}

sub normalize_thread
{
    my ($thread, $coords) = @_;
    my $f;

    $f = sub {
        my $sub = shift;
        return { 'idx' => $sub->{idx},
            (exists($sub->{subs}) ?
                ('subs' => [ map { $f->($_); } @{$sub->{'subs'}} ]) :
                ()
            )
        };
    };
    return [$f->($thread), $coords];
}

{
    local $Net::NNTP::groups = Data1::get_groups();
    {
        my $nntp = Net::NNTP->new("nntp.shlomifish.org");
        create_db();
        my $cache = CGI::Application::NetNewsIface::Cache::DBI->new(
            {
                'nntp' => $nntp,
                'dsn' => $dsn,
            },
        );
        # TEST
        ok ($cache, "Cache was initialized");
    }
    {
        my $nntp = Net::NNTP->new("nntp.shlomifish.org");
        create_db();
        my $cache = CGI::Application::NetNewsIface::Cache::DBI->new(
            {
                'nntp' => $nntp,
                'dsn' => $dsn,
            },
        );
        # TEST
        is ($cache->select("perl.qa"), 0, "select() worked");
    }
    {
        my $nntp = Net::NNTP->new("nntp.shlomifish.org");
        create_db();
        my $cache = CGI::Application::NetNewsIface::Cache::DBI->new(
            {
                'nntp' => $nntp,
                'dsn' => $dsn,
            },
        );
        # TEST
        is ($cache->select("perl.qa"), 0, "select() worked");
        # TEST
        is ($cache->get_index_of_id(
            "44439745.6060604\@modperlcookbook.org"
            ),
            11,
            "get_index_of_id() - 1"
        );
        # TEST
        is ($cache->get_index_of_id(
            "20060418012117.GA6582\@yi.org",
            ),
            16,
            "get_index_of_id() - 2"
        );
        # TEST
        is ($cache->get_index_of_id(
            "20060418073833.GB1833\@klangraum"
            ),
            25,
            "Existence of the article with the last index"
        );
        # TEST
        is ($cache->select("perl.advocacy"), 0,
            "select(\"perl.advocacy\") worked");
        # TEST
        is ($cache->get_index_of_id(
            "FE10499CE029B841A9DAAF12E5A52A1B011D9094\@XCH-NW-3V1.nw.nos.boeing.com",
            ),
            2,
            "get_index_of_id() in perl.advocacy - 1"
        );
        # TEST
        is ($cache->get_index_of_id(
            "x7d5g44iyg.fsf\@mail.sysarch.com",
            ),
            4,
            "get_index_of_id() in perl.advocacy - 2"
        );
        # TEST
        is ($cache->select("perl.qa"), 0,
            "select(\"perl.qa\") worked");
        # TEST
        is ($cache->_get_parent(5),
            4,
            "_get_parent() - 1",
        );
        # TEST
        is ($cache->_get_parent(16),
            13,
            "_get_parent() - 2",
        );
        # TEST
        is ($cache->_get_parent(1),
            0,
            "_get_parent() - 3",
        );

        {
            my ($thread, $coords) = $cache->get_thread(2);
            # TEST
            is_deeply (normalize_thread($thread, $coords),
                [
                    # The thread
                    {
                        'idx' => 1,
                        'subs' =>
                        [
                            {
                                'idx' => 2,
                                'subs' =>
                                [
                                    {
                                        'idx' => 3,
                                    }
                                ],
                            },
                        ],
                    },
                    # The coords
                    [0],
                ],
                "get_thread() - Try 1",
            );
            # TEST
            is ($thread->{'subject'},
               "Generator for Modules-Installing Makefiles",
               "Top-level thread item has data",
            );
        }
    }
}
1;

