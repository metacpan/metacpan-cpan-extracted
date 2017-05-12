
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => "Author testing disabled");
  }
}

use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing epslling" if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();
__DATA__
X509
API
AIA
Amann
Johanna
MPL
NSS
api
pem
CERT
DERSTRING
EC
PKIX
RSA
backend
cert
certUsageSSLServer
codebase
der
Firefox
md
notAfter
notBefore
selfsigned
sha
unix
CRL
CertList
PEMSTRING
CA
OCSP
SSL
TODO
certUsageAnyCA
certUsageEmailRecipient
certUsageEmailSigner
certUsageObjectSigner
certUsageProtectedObjectSigner
certUsageSSLCA
certUsageSSLClient
certUsageSSLServerWithStepUp
certUsageStatusResponder
certUsageUserCertImport
certUsageVerifyCA
dbnickname
db
oids
