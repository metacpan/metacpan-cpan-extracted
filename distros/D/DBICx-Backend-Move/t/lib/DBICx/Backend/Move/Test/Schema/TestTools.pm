package DBICx::Backend::Move::Test::Schema::TestTools;

# inspired by Test::Fixture::DBIC::Schema

use strict;
use warnings;

# get rid of a few warnings with older module versions
BEGIN {
        use Class::C3;
        use MRO::Compat;
        $DBD::SQLite::sqlite_version; # fix "used only once" warning
}

use DBICx::Backend::Move::Test::Schema;
use Test::Fixture::DBIC::Schema qw/construct_fixture/;

=head1 NAME

CLT::Schema::TestTools - Set up database for unit testing



=head1 SYNOPSIS

    use DBICx::Backend::Move::Test::Schema::TestTools;

    my $error = DBICx::Backend::Move::Test::Schema::TestTools::setup_db('t/fixtures/db.yml', 'dbi:SQLite:dbname=t/from.sqlite');
    die $error if $error;

=head1 SUBROUTINES

=head2 setup_db

Set up a database and fill it with values from the fixture file.

@param string - path to fixture file

@return success - 0
@return error   - error string

=cut

sub setup_db {
        my ($fixture, $dsn) = @_;

        return "No such file: $fixture" unless -e $fixture;

        my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
        unlink $tmpfname; # ignore errors, they will be reported when deploy fails

        my $schema = DBICx::Backend::Move::Test::Schema->connect($dsn);
        $schema->deploy;
        construct_fixture( schema  => $schema, fixture => $fixture );
        return 0;
}

1;
