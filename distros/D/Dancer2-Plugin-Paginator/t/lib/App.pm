package t::lib::App;

use Dancer2;
use Dancer2::Plugin::Paginator;

get '/config' => sub {
    my $paginator = paginator(
        curr     => 5,
        items    => 100,
        base_url => '/foo/bar',
    );

    to_json { %{$paginator} };
};

get '/custom' => sub {
    my $paginator = paginator(
        frame_size => 3,
        page_size  => 7,
        curr       => 5,
        items      => 100,
        base_url   => '/foo/bar',
    );

    to_json { %{$paginator} };
};

1;

