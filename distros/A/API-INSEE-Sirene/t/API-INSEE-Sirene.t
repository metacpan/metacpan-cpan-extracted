use strict;
use warnings;

use Test::More;
use HTTP::Request;

BEGIN { use_ok('API::INSEE::Sirene') };

use constant USE_HISTORIZED_FIELDS => 1;

my $sirene = API::INSEE::Sirene->new('fake_credential');

my @oks_custom_criteria = (
#   [ expected_result, field_name, value ... ],
    [ '(siret:"12345678901234"~ OR siret:*12345678901234*)',                'siret',          '12345678901234'                                 ],
    [ '(siret:"12345678901234"~ OR siret:*12345678901234*)',                'siret',          '12345678901234', USE_HISTORIZED_FIELDS          ],
    [ 'periode(nomUniteLegale:"foo"~ OR nomUniteLegale:*foo*)',             'nomUniteLegale', 'foo',            USE_HISTORIZED_FIELDS          ],
    [ 'periode(nomUniteLegale:"foo%26bar"~ OR nomUniteLegale:*foo%26bar*)', 'nomUniteLegale', 'foo&bar',        USE_HISTORIZED_FIELDS          ],
    [ 'periode(nomUniteLegale:foo)',                                        'nomUniteLegale', 'foo',            USE_HISTORIZED_FIELDS, 'exact' ],
    [ 'periode(nomUniteLegale:foo*)',                                       'nomUniteLegale', 'foo',            USE_HISTORIZED_FIELDS, 'begin' ],
    [ 'denominationUniteLegale:foo',                                        'nom',            'foo',            undef,                 'exact' ],
    [ 'denominationUniteLegale:bar*',                                       'nom',            'bar',            undef,                 'begin' ],
    [ 'denominationUniteLegale:foo%26bar',                                  'nom',            'foo&bar',        undef,                 'exact' ],
);

foreach (@oks_custom_criteria) {
    my ($expected, @args) = @{ $_ };
    ok($expected eq $sirene->getCustomCriteria(@args));
}

$sirene->setDebugMode(1);

my @oks_request_GET = (
    [ 'getLegalUnitBySIREN',     '123456789'      ],
    [ 'getEstablishmentBySIRET', '12345678901234' ],
);

foreach (@oks_request_GET) {
    my ($method, @args) = @{$_};

    can_ok($sirene, $method);
    my ($err, $request) = $sirene->$method(@args);
    ok(0 == $err);
    $request =~ s/^Sent request:\n//m;

    my $r = HTTP::Request->parse($request);

    ok($r->method eq 'GET');

    ok($r->uri =~ qr{/sire[nt]/\d{9,14}\?});
}

my @oks_request_POST = (
    [ 'getEstablishmentsByUsualName', 'foo' ],
    [ 'getEstablishmentsByName',      'foo' ],
);

=for doc

# q=((denominationUsuelle1UniteLegale%3A%22foo%22~+OR+denominationUsuelle1UniteLegale%3A*foo*))&date=2021-02-02&nombre=20
# q=((denominationUniteLegale%3A%22foo%22~+OR+denominationUniteLegale%3A*foo*))&date=2021-02-02&nombre=20

=cut

foreach (@oks_request_POST) {
    my ($method, @args) = @{$_};

    can_ok($sirene, $method);
    my ($err, $request) = $sirene->$method(@args);
    ok(0 == $err);
    $request =~ s/^Sent request:\n//m;

    my $r = HTTP::Request->parse($request);

    ok($r->method eq 'POST');

    ok($r->uri =~ qr{/siret$});

    my %param = ();
    foreach my $param (split '&', $r->content) {
        my ($key, $value) = split '=', $param;
        $param{$key} = $value;
    }

    ok(exists $param{'q'} && exists $param{'date'} && exists $param{'nombre'});
}

plan tests => 1 + (scalar @oks_custom_criteria) + (4 * scalar @oks_request_GET) + (5 * scalar @oks_request_POST);
