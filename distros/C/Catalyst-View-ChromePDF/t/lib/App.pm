package App;

use strict;
use warnings;

use Catalyst;

use Test::Log::Dispatch;    # suppress stderr log

use namespace::autoclean;

__PACKAGE__->log( Test::Log::Dispatch->new );

__PACKAGE__->config(
    'View::TT' => {
        INCLUDE_PATH       => [ __PACKAGE__->path_to('root'), ],
        ENCODING           => 'utf-8',
        TIMER              => 0,
        TEMPLATE_EXTENSION => '.tt',
        ABSOLUTE           => 1,
        render_die         => 1
    },
);

__PACKAGE__->setup();

1;
