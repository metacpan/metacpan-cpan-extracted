package TestSettings;
use strict;
use warnings;
use Amazon::DynamoDB;
use String::Random;


sub get_ddb {
    my %options = @_;
    my $ddb = Amazon::DynamoDB->new(
        implementation => 'Amazon::DynamoDB::LWP',
        version        => '20120810',
        access_key     => $ENV{AWS_ACCESS_KEY},
        secret_key     => $ENV{AWS_SECRET_KEY},
        host => 'dynamodb.us-east-1.amazonaws.com',
        scope => 'us-east-1/dynamodb/aws4_request',
        ssl => 1,
        debug_failures => 1,
        %options);
    return $ddb;
}

sub random_table_name {
    return 'table_test_' . String::Random::random_string('ccccccc');
}

1;
