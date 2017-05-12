package TestApp;
use Moose;
use FindBin;
extends 'Catalyst';

# use Catalyst ( qw(-Log=error) );

__PACKAGE__->config(
        name => 'TestApp',
        home => "$FindBin::Bin",
        'View::ByCode' => {
            wrapper => 'xxx.pl',
            include => ['List::MoreUtil'],
        },
);

__PACKAGE__->setup();

1;
