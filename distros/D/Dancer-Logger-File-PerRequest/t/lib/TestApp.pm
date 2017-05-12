package TestApp;

use Dancer ':syntax';

our $VERSION = '0.1';

use FindBin qw/$Bin/;
setting 'log' => 'debug';
setting 'log_path' => "$Bin/logs";
setting 'logfile_callback' => sub {
    return 'fayland_test_' . $$ . '.log';
};
setting 'logger' => "File::PerRequest";

get '/' => sub {
    debug "TEST DEBUG";
    'blabla';
};

true;
