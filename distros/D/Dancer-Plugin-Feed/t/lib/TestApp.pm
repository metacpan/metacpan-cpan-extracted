#
# This file is part of Dancer-Plugin-Feed
#
# This software is copyright (c) 2013 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::Feed;

get '/feed' => sub {
    create_feed(
        title   => 'this is a test',
        entries => [ { title => 'first entry' } ],
    );
};

get '/feed/:format' => sub {
    create_feed(
        format  => params->{format},
        title   => 'TestApp with ' . params->{format},
        entries => _get_entries(),
    );
};

get '/other/feed/rss' => sub {
    create_rss_feed(
        title   => 'TestApp with rss',
        entries => _get_entries(),
    );
};

get '/other/feed/atom' => sub {
    create_atom_feed(
        title   => 'TestApp with atom',
        entries => _get_entries(),
    );
};

sub _get_entries {
    [map { { title => "entry $_" } } ( 1 .. 10 )];
}

1;
