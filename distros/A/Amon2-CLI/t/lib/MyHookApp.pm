package MyHookApp;
use strict;
use warnings;
use parent qw/Amon2/;

__PACKAGE__->load_plugins(
    'CLI' => {
        base => 'MyApp::CLI',
        before_run => sub {
            my ($c, $arg) = @_;
            print "before_run!\n";
        },
        after_run => sub {
            my ($c, $arg) = @_;
            print "after_run!";
        },
    },
);

1;
