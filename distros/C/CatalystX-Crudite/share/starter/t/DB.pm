package t::DB;

# Setup everything for mechanize tests and create a temporary in-memory DB for
# every separate test file so you can run tests in parallel without worrying
# about interference.
#
# See
# http://modernperlbooks.com/mt/2012/08/testing-catalyst-and-dbic-with-an-in-memory-database.html

use strict;
use warnings;
use Try::Tiny;
use DBICx::TestDatabase;
use <% dist_module %>;
use <% dist_module %>::Util::Primer qw(prime_database);
use Test::WWW::Mechanize::Catalyst '<% dist_module %>';
my $schema;
sub make_schema { $schema //= DBICx::TestDatabase->new(shift) }

sub install_test_database {
    my ($app, $schema) = @_;
    <% dist_module %>->model('DB')->schema($schema);

    # <% dist_module %>->log->disable('warn');
}

sub import {
    my $self        = shift;
    my $appname     = '<% dist_module %>';
    my $schema_name = "${appname}::Schema";
    my $schema      = make_schema($schema_name);
    install_test_database($appname, $schema);
    try {
        prime_database($schema);
    }
    catch {
        my $E = shift;
        BAIL_OUT("Fixture creation failed: $E");
    };
}
1;
