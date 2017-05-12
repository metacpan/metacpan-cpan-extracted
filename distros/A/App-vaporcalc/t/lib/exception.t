use Test::Modern;

use App::vaporcalc::Exception;

my $err = exception {; App::vaporcalc::Exception->throw('foo bar!') };
isa_ok $err, 'App::vaporcalc::Exception';
ok $err->message eq 'foo bar!', 'message ok';
like "$err", qr/foo bar!/, 'stringification ok';

done_testing
