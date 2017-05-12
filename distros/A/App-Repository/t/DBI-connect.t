#!/usr/local/bin/perl -w

use App::Options (
    options => [qw(dbdriver dbclass dbhost dbname dbuser dbpass)],
    option => {
        dbclass  => { default => "App::Repository::MySQL", },
        dbdriver => { default => "mysql", },
        dbhost   => { default => "localhost", },
        dbname   => { default => "test", },
        dbuser   => { default => "", },
        dbpass   => { default => "", },
    },
);

use Test::More qw(no_plan);
use lib "../App-Context/lib";
use lib "../../App-Context/lib";
use lib "lib";
use lib "../lib";

use_ok("App");
use_ok("App::Repository");
use strict;

if (!$App::options{dbuser}) {
    ok(1, "No dbuser given. Tests assumed OK. (add dbuser=xxx and dbpass=yyy to app.conf in 't' directory)");
    exit(0);
}

#$App::DEBUG = 6;

{
    my $context = App->context(
        %App::options,
        conf_file => "",
        conf => {
            Repository => {
                default => {
                    class => $App::options{dbclass},
                },
            },
        },
    );
    my $rep = $context->repository();
    #print "REP: $rep\n";
    #foreach (sort keys %$rep) {
    #    printf "%-24s => %s\n", $_, $rep->{$_};
    #}
    #print "%INC:\n";
    #foreach (sort keys %INC) {
    #    printf "%-24s => %s\n", $_, $INC{$_};
    #}
    ok(defined $rep, "constructor ok");
    isa_ok($rep, "App::Repository", "right class");
    ok($rep->{name} eq "default", "name ok");
    ok($rep->_is_connected(), "connected [yes]");
    isa_ok($rep->{dbh}, "DBI::db", "dbh");
    ok($rep->_disconnect(), "disconnect OK");
    ok(!$rep->_is_connected(), "connected [no]");
    ok(! defined $rep->{dbh}, "dbh undefed");
    ok($rep->_connect(), "reconnected");
    ok($rep->_is_connected(), "connected [yes]");
    ok(defined $rep->{dbh}, "dbh defined");
}

use_ok("App::Repository::MySQL");

{
    #$App::aspect = 1;
    # get a repository (no need for config file)
    my $rep = App::Repository::MySQL->new("test2",
        dbdriver => $App::options{dbdriver},
        dbhost => $App::options{dbhost},
        dbname => $App::options{dbname},
        dbuser => $App::options{dbuser},
        dbpass => $App::options{dbpass},
    );
    ok(defined $rep, "constructor ok");
    isa_ok($rep, "App::Repository::DBI", "right class");
    ok($rep->{name} eq "test2", "name ok");
    isa_ok($rep->{dbh}, "DBI::db", "dbh");
    ok($rep->_is_connected(), "connected [yes]");
    ok($rep->_disconnect(), "disconnect OK");
    ok(!$rep->_is_connected(), "connected [no]");
    ok(! defined $rep->{dbh}, "dbh undefed");
}

exit 0;

