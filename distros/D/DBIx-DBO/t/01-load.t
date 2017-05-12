use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    if (eval "$Test::More::VERSION < 0.84") {
        diag "Test::More 0.84 is recommended, this is only $Test::More::VERSION!";
        unless (exists $::{note}) {
            eval q#
                sub Test::More::note {
                    local $Test::Builder::{_print_diag} = $Test::Builder::{_print};
                    Test::More->builder->diag(@_);
                }
                *note = \&Test::More::note;
            #;
            die $@ if $@;
        }
    }
	use_ok 'DBIx::DBO' or BAIL_OUT 'DBIx::DBO failed!';
}

diag "DBIx::DBO $DBIx::DBO::VERSION, Perl $], $^X";
note 'Available DBI drivers: '.join(', ', DBI->available_drivers);

ok $DBIx::DBO::Config{QuoteIdentifier}, 'QuoteIdentifier setting is ON by default';
import DBIx::DBO QuoteIdentifier => 123;
is $DBIx::DBO::Config{QuoteIdentifier}, 123, "Check 'QuoteIdentifier' import option";

DBIx::DBO->config(QuoteIdentifier => 456);
is +DBIx::DBO->config('QuoteIdentifier'), 456, 'Method DBIx::DBO->config';

DBIx::DBO->config(UseHandle => 'read-only');
is +DBIx::DBO->config('UseHandle'), 'read-only', 'UseHandle config setting';
DBIx::DBO->config(UseHandle => undef);

my $dbo = DBIx::DBO->new(undef, undef, {dbd => 'xxx'});
isa_ok $dbo, 'DBIx::DBO', '$dbo';

$dbo->config(UseHandle => 'read-write');
is $dbo->config('UseHandle'), 'read-write', 'Setting $dbo->config overrides DBIx::DBO->config';
is $dbo->config('QuoteIdentifier'), 456, '$dbo->config inherits from DBIx::DBO->config';

$dbo->config(QuoteIdentifier => 0);
is $dbo->{dbd_class}->_qi($dbo, undef, 'table', 'field'), 'table.field', 'Method $dbo->_qi';
is $dbo->{dbd_class}->_qi($dbo, undef, ''), '', 'Method $dbo->_qi (empty)';

eval { DBIx::DBO->config(UseHandle => 'invalid') };
ok $@ =~ /^Invalid value for the 'UseHandle' setting/, 'UseHandle config must be valid';

