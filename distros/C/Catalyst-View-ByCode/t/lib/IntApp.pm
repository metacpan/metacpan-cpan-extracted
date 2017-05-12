package IntApp;

use Moose;
extends 'Catalyst';

# use Catalyst::Runtime '5.80';
# use FindBin;

use Catalyst; # ( qw(-Log=error) );

__PACKAGE__->config(
        name => 'IntApp',
        default_view => 'ByCode',
        home => "$FindBin::Bin",
        'View::ByCode' => {
            wrapper  => 'wrap_template.pl',
        },
);

__PACKAGE__->setup();

1;
