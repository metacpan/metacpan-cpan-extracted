use strict;
use Date::Simple;
use Acme::MomoiroClover::Z;
use Test::More tests => 7;
use Test::Exception;

my $momoclo_chan = Acme::MomoiroClover::Z->new;

throws_ok {
    Acme::MomoiroClover->new;
} qr/obsolete/, 'not found yet';

is scalar($momoclo_chan->members),             11, " members(undef) retrieved all";
is scalar($momoclo_chan->members('active')),    5, " members('active')";
is scalar($momoclo_chan->members('graduate')),  6, " members('graduate')";
is scalar($momoclo_chan->members(Date::Simple->new('2011-04-09'))), 6, " members('date_simple_object')";

{
    no warnings 'redefine';
    *Date::Simple::today = sub {
        Date::Simple->new('2011-04-09');
    };
    ok (Acme::MomoiroClover->new), 'can create';
    throws_ok {
        Acme::MomoiroClover::Z->new;
    } qr/not found yet/, 'not found yet';

}

