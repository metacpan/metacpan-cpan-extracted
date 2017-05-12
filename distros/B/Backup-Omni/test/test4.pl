use lib '../lib';
use Backup::Omni::Session::Results;

my $results = Backup::Omni::Session::Results->new(
    -session => '2013/01/28-1'
);

printf("session status:     %s\n", $results->status);
printf("number of errors:   %s\n", $results->number_of_errors);
printf("number of warnings: %s\n", $results->number_of_warnings);

