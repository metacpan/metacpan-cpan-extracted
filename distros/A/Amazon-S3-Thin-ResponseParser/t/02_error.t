use strict;
use warnings;
use Test::More;
use Amazon::S3::Thin::ResponseParser;

my $response_parser = Amazon::S3::Thin::ResponseParser->new();

my ($contents, $error) = $response_parser->list_objects(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>NoSuchKey</Code>
  <Message>The resource you requested does not exist</Message>
  <Resource>/mybucket/myfoto.jpg</Resource>
  <RequestId>4442587FB7D0A2F9</RequestId>
</Error>
XML
is $contents, undef;
is_deeply $error, {
    code       => 'NoSuchKey',
    message    => 'The resource you requested does not exist',
    resource   => '/mybucket/myfoto.jpg',
    request_id => '4442587FB7D0A2F9',
};

done_testing;