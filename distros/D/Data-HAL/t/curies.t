use strictures;
use Test::More import => [qw(done_testing is ok)];
use Data::HAL qw();
use File::Slurp qw(read_file);

my $hal = Data::HAL->from_json(scalar read_file 't/exampleWithMultipleNestedSubresources.json');
my @expanded_curies = map { $_->relation->uri->as_string } @{ $hal->links };
ok grep { 'https://example.com/apidocs/ns/parent' eq $_ } @expanded_curies;
ok grep { 'https://example.com/apidocs/ns/users' eq $_ } @expanded_curies;

is $hal->embedded->[0]->relation->uri->as_string, 'https://example.com/apidocs/ns/user';
is $hal->embedded->[1]->relation->uri->as_string, 'https://example.com/apidocs/ns/user';
is $hal->embedded->[0]->embedded->[0]->relation->uri->as_string, 'https://example.com/apidocs/phone/cell';

done_testing;
