use strict;
use lib 'lib';
use Test::More;
use Data::Processor;

my $timespecfactor = {
    d => 24*3600,
    m => 60,
    s => 1,
    h => 3600
};

my $transformer = {
    timespec => sub {
        my $msg = shift;
        sub {
            if (shift =~ /^(\d+)([dmsh]?)$/){
                return ($1 * $timespecfactor->{($2 || 's')});
            }
            die {msg=>$msg};
        }
    }
};

my $schema = {
    history => {
        transformer => $transformer->{timespec}(
            'specify timeout in seconds or append d,m,h to the number'),
    },
    '\d' => {
        regex => 1,        
        transformer => $transformer->{timespec}(
            'specify timeout in seconds or append d,m,h to the number'),
        validator => sub {
             return "expected a number" unless shift =~ /^\d+$/;
             return undef;
        }
    },
};

my $data = {
    history => '1h',
    '3' => '1m',
};

my $validator = Data::Processor->new($schema);
my $error_collection = $validator->validate($data, verbose=>1);
is (scalar @{$error_collection->{errors}},0,"No Errors Found");
is ($data->{history} ,3600, 'transformed "1h" into "3600"');
is ($data->{3} , 60, 'transformed "1m" into "60"');

$data = {
    history => 'regards, your error :-)',
};
$error_collection = $validator->validate($data);

is ($data->{history} , 'regards, your error :-)',
    'Could not transform "regards, your error :-)"');
like ($error_collection->{errors}[0]->{message}
    , qr/^error transforming 'history': specify/,
    'error from failed transform starts with "error transforming \'history\': specify"');


done_testing;
