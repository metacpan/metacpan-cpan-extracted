use Data::AnyXfer::Test::Kit;

use Data::AnyXfer::Elastic::Logger;
use Data::AnyXfer::Elastic::Import::DataFile;

# PREPARATION

my $datafile = Data::AnyXfer::Elastic::Import::DataFile->read(
    file => file('t/data/employees.datafile') );

# TESTS

can_ok(
    'Data::AnyXfer::Elastic::Logger', qw/  debug   info
        notice  warning
        error   critical
        alert   emergency /
);

my $logger = Data::AnyXfer::Elastic::Logger->new(
    destination => 't/data/logs',
    screen      => 0,
);

ok $logger->critical(
    index_info => $datafile,
    text       => 'A critical error',
    ),
    'Logged a critical error';


is
    scalar keys %{$logger->_cache},
    1,
    'one instance of Log::Dispatch cached';


ok $logger->debug(
    index_info => $datafile,
    text       => 'Blah Blah Blah!',
    content    => [ 'error1', 'error2', 'error3' ],
    ),
    'Logged a debug message';

note 'check in the file that these have been logged';

my $file = Path::Class::file( 't/data/logs/' . $datafile->alias . '.log' );
my $string = $file->slurp;

ok $string =~ 'A critical error',
    'critical error logged successfully';

ok $string =~ 'Blah Blah Blah!',
    'debug message logged successfully';

ok $string =~ DateTime->now->ymd('-'),
    'date format logged correctly';


# delete the temporary file.
ok unlink $file, 'cleaned up file';

done_testing;

1;
