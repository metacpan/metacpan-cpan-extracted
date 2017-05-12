use strict;
use warnings;
use Test::More;
use utf8;
use BusyBird::Input::Feed;
use File::Spec;

sub create_input {
    my ($image_max_num) = @_;
    return BusyBird::Input::Feed->new(
        use_favicon => 0,
        image_max_num => $image_max_num
    );
}

sub media_urls {
    my ($status) = @_;
    return map { $_->{media_url} } @{$status->{extended_entities}{media}};
}

note('test image_max_num option');

{
    my $input = create_input(0);
    my $got = $input->parse_file(File::Spec->catfile(".", "t", "samples", "googlejp.atom"));
    ok !defined($got->[0]{extended_entities}), "if image_max_num == 0, extended_entities field is not even defined";
}

{
    my $input = create_input(-1);
    my $got = $input->parse_file(File::Spec->catfile(".", "t", "samples", "googlejp.atom"));
    is_deeply(
        [media_urls($got->[0])],
        [
            'http://1.bp.blogspot.com/-eYSw5ZyZ7Ec/U7YgVYLF3TI/AAAAAAAAM_8/FPpTqUyesk0/s450/gochiphototop1.png',
            'http://1.bp.blogspot.com/-bp_kUa_Z8uQ/U7Yip34vN-I/AAAAAAAANAU/ktJQhMvf3BQ/s500/gochiprofile.png',
            'http://4.bp.blogspot.com/-pJkRMfPc2m4/U7Yi-Vm4pvI/AAAAAAAANAc/EbXv8oPCyBM/s100/genre_0011.png',
            'http://1.bp.blogspot.com/-EJnuABpYVqY/U7YjB2AfoYI/AAAAAAAANAk/wz3OxrrwlZU/s100/genre_0048.png',
            'http://1.bp.blogspot.com/-lR-VPQEb-v8/U7YjUF1BLiI/AAAAAAAANAw/2PlOEdnYoXI/s100/genre_0010.png',
            'http://1.bp.blogspot.com/-QrhWUXQRAJk/U7YjclIdHVI/AAAAAAAANA8/xNQNNMzV_h0/s100/genre_0032.png',
            'http://3.bp.blogspot.com/-AXjec7KPbC4/U7YlHzFYBsI/AAAAAAAANBM/XXSx9eWFgxI/s100/area_0000.png',
            'http://3.bp.blogspot.com/-sPVYs-QdRxY/U7YlHwlGO0I/AAAAAAAANBI/6HPnopyRI4Q/s100/area_0001.png',
            'http://2.bp.blogspot.com/-DQ2laU9ebl4/U7YlH9W2GcI/AAAAAAAANBQ/cZ7EQWz8d38/s100/area_0026.png',
            'http://1.bp.blogspot.com/-BwBgEe2Ik6k/U7YlIe-jSbI/AAAAAAAANBU/XJqLmS0hMfs/s100/area_0047.png',
            'http://feeds.feedburner.com/~r/GoogleJapanBlog/~4/RP_M-WXr_6I',
        ],
        'extract unlimited number of images'
    );

    $got = $input->parse_file(File::Spec->catfile(".", "t", "samples", "stackoverflow.atom"));
    ok !defined($got->[0]{extended_entities}), "extended_entities not defined because no <img> in the feed item";

    is_deeply(
        [media_urls($got->[22])],
        [
            "http://i.stack.imgur.com/QLLXP.png"
        ],
        "extract an image from stack overflow"
    );
}

done_testing;
