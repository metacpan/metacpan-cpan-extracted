use strict;
use utf8;
use Test::More;

use JSON;
use Encode;
use AnyEvent::Twitter;

my $config;

if (-f './xt/config.json') {
    open my $fh, '<', './xt/config.json' or die $!;
    $config = decode_json(join '', <$fh>);
    close $fh or die $!;
} else {
    plan skip_all => 'There is no setting file for testing';
}

my $screen_name = $config->{screen_name};

sub slurp ($) {
    my $filename = shift;
    open my $fh, '<:bytes', $filename or die $!;
    local $/;
    <$fh> 
}

my $image_1 = slurp 'xt/image-1.jpg';

subtest 'single file' => sub {
    my $ua = AnyEvent::Twitter->new(%$config);

    my $cv = AE::cv;

    $cv->begin;
    $ua->get('help/configuration', sub {
        my ($hdr, $res, $reason) = @_;
        note explain $res;
        is $res->{max_media_per_upload}, 1, 'keep watch on a allowed media counts';
        $cv->end;
    });

    {
        no utf8;
        $cv->begin;
        $ua->post('statuses/update_with_media',
            [
                status => 'いろはにほへと ' . rand,
                'media[]' => [ undef, 'filename', Content => $image_1 ],
            ], sub {
            my ($hdr, $res, $reason) = @_;
            is($res->{user}{screen_name}, $screen_name, "account/verify_credentials");
            note explain \@_;
            $cv->end;
        });
    }

    $cv->begin;
    $ua->post('statuses/update_with_media',
        [
            status => 'いろはにほへと ' . time,
            'media[]' => [ undef, 'filename', Content => $image_1 ],
        ], sub {
        my ($hdr, $res, $reason) = @_;
        is($res->{user}{screen_name}, $screen_name, "account/verify_credentials");
        note explain \@_;
        $cv->end;
    });

    $cv->recv;
};

subtest 'multiple files' => sub {
    plan skip_all => 'not allowed us to upload multiple files yet';
};

done_testing;
