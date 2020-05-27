use Data::AnyXfer::Test::Kit;
use Data::AnyXfer::Elastic::Error ();
use Search::Elasticsearch::Error          ();

# TEST SETUP

my $error = Search::Elasticsearch::Error->new('Request');

# check these in case Search::Elasticsearch::Error is updated
like $error->{text}, qr/Unknown error/, 'error text ok';
like $error->{type}, qr/Request/,       'error type ok';
ok !$error->{vars}, 'error vars no set';
ok !@{ $error->{stack} }, 'error stack no set';

my $expected_message
    = qr/\QElasticsearch request error generated (Path: - ). Error: Unknown error\E/;

# TESTS

# testing croak
throws_ok { Data::AnyXfer::Elastic::Error->croak($error) }
$expected_message, 'croak error ok';

# testing carp
warning_like { Data::AnyXfer::Elastic::Error->carp($error) }
$expected_message, 'carp warning ok';

# normal $@ error
throws_ok { Data::AnyXfer::Elastic::Error->croak('Other Error') }
qr/Other Error/, 'normal error ok';


done_testing;
