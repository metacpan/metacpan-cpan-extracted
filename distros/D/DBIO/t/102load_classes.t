use strict;
use warnings;
use Test::More;

use DBIO::Test;

my $warnings;
eval {
    local $SIG{__WARN__} = sub { $warnings .= shift };
    package DBIO::Test::Schema;
    use base qw/DBIO::Schema/;
    # Load the deliberately-broken class explicitly rather than via a no-arg
    # Module::Find sweep of DBIO::Test::Schema::*. That namespace also holds
    # optional-OO variant schemas (::Moose, ::MooseSugar, ::Moo, ::MooCake)
    # which hard-require Moose / MooseX::NonMoose / Moo; a no-arg sweep would
    # die when those optional deps are absent (e.g. a CPAN Testers smoker),
    # aborting before the warn-on-non-result-class behaviour under test.
    __PACKAGE__->load_classes('NoSuchClass');
};
ok(!$@, 'load_classes does not die on a non-result class') or diag $@;
like($warnings, qr/Failed to load DBIO::Test::Schema::NoSuchClass. Can't find source_name method. Is DBIO::Test::Schema::NoSuchClass really a full DBIO result class?/, 'Warned about broken result class');

my $source_a = DBIO::Test::Schema->source('Artist');
isa_ok($source_a, 'DBIO::ResultSource::Table');
my $rset_a   = DBIO::Test::Schema->resultset('Artist');
isa_ok($rset_a, 'DBIO::ResultSet');

done_testing;
