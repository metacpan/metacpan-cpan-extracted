use lib 't';
use share;

plan tests => 20;

my $dbh = new_dbh {PrintError=>0};

throws_ok { DBIx::SecureCGI::DefineFunc(undef, '%s=%s') }
    qr/bad function name:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc(\'func', '%s=%s') }
    qr/bad function name:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('_func', '%s=%s') }
    qr/bad function name:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', undef) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', q{}) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', '%s') }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', '%s%s%s') }
    qr/bad function:/ms;
lives_ok { DBIx::SecureCGI::DefineFunc('func', '%s%s') }
    'define';
lives_ok { DBIx::SecureCGI::DefineFunc('func', '%s=%s') }
    'redefine';
throws_ok { DBIx::SecureCGI::DefineFunc('func', []) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', [qr//]) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', [qr//, '%s%s', undef]) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', [\qr//, '%s%s']) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', [undef, '%s%s']) }
    qr/bad function:/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', [q{}, '%s%s']) }
    qr/bad function:/ms;
lives_ok { DBIx::SecureCGI::DefineFunc('func', [qr//, '%s%s']) }
    'define ARRAYREF';
throws_ok { DBIx::SecureCGI::DefineFunc('func', undef) }
    qr/bad function/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', \q{}) }
    qr/bad function/ms;
throws_ok { DBIx::SecureCGI::DefineFunc('func', {}) }
    qr/bad function/ms;
lives_ok { DBIx::SecureCGI::DefineFunc('func', sub {}) }
    'define CODEREF';

done_testing();
