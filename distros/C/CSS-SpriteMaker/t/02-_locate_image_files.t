use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('CSS::SpriteMaker');

my $SpriteMaker = CSS::SpriteMaker->new(
    source_dir => 'sample_icons',
    target_file => 'sample_sprite.png'
);

{
    my $ra_expected = [
        {
          'parentdir' => 'sample_icons',
          'name' => 'apple.png',
          'pathname' => 'sample_icons/apple.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'banknote.png',
          'pathname' => 'sample_icons/banknote.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'bubble.png',
          'pathname' => 'sample_icons/bubble.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'bulb.png',
          'pathname' => 'sample_icons/bulb.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'calendar@.png',
          'pathname' => 'sample_icons/calendar@.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'camera.png',
          'pathname' => 'sample_icons/camera.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'clip.png',
          'pathname' => 'sample_icons/clip.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'clock.png',
          'pathname' => 'sample_icons/clock.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'cloud.png',
          'pathname' => 'sample_icons/cloud.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'cup.png',
          'pathname' => 'sample_icons/cup.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'data.png',
          'pathname' => 'sample_icons/data.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'diamond.png',
          'pathname' => 'sample_icons/diamond.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'display.png',
          'pathname' => 'sample_icons/display.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'eye.png',
          'pathname' => 'sample_icons/eye.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'fire.png',
          'pathname' => 'sample_icons/fire.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'food.png',
          'pathname' => 'sample_icons/food.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'heart.png',
          'pathname' => 'sample_icons/heart.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'key.png',
          'pathname' => 'sample_icons/key.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'lab.png',
          'pathname' => 'sample_icons/lab.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'like.png',
          'pathname' => 'sample_icons/like.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'location.png',
          'pathname' => 'sample_icons/location.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'lock.png',
          'pathname' => 'sample_icons/lock.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'mail.png',
          'pathname' => 'sample_icons/mail.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'megaphone.png',
          'pathname' => 'sample_icons/megaphone.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'music.png',
          'pathname' => 'sample_icons/music.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'news.png',
          'pathname' => 'sample_icons/news.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'note.png',
          'pathname' => 'sample_icons/note.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'paperplane.png',
          'pathname' => 'sample_icons/paperplane.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'params.png',
          'pathname' => 'sample_icons/params.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'pen.png',
          'pathname' => 'sample_icons/pen.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'phone.png',
          'pathname' => 'sample_icons/phone.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'photo.png',
          'pathname' => 'sample_icons/photo.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'search.png',
          'pathname' => 'sample_icons/search.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'settings.png',
          'pathname' => 'sample_icons/settings.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'shop.png',
          'pathname' => 'sample_icons/shop.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'sound.png',
          'pathname' => 'sample_icons/sound.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'stack.png',
          'pathname' => 'sample_icons/stack.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'star.png',
          'pathname' => 'sample_icons/star.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'study.png',
          'pathname' => 'sample_icons/study.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 't-shirt.png',
          'pathname' => 'sample_icons/t-shirt.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'tag.png',
          'pathname' => 'sample_icons/tag.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'trash.png',
          'pathname' => 'sample_icons/trash.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'truck.png',
          'pathname' => 'sample_icons/truck.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'tv.png',
          'pathname' => 'sample_icons/tv.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'user.png',
          'pathname' => 'sample_icons/user.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'vallet.png',
          'pathname' => 'sample_icons/vallet.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'video.png',
          'pathname' => 'sample_icons/video.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'vynil.png',
          'pathname' => 'sample_icons/vynil.png'
        },
        {
          'parentdir' => 'sample_icons',
          'name' => 'world.png',
          'pathname' => 'sample_icons/world.png'
        }
    ];

    my $ra_result = $SpriteMaker->_locate_image_files('sample_icons');
    my %result = map { $_->{name} => $_ } @$ra_result;
    my %expected = map { $_->{name} => $_ } @$ra_expected;

    is_deeply(\%result, \%expected, 
        'expected result on one non-empty directory'
    );
}

{
    my $ra_result = $SpriteMaker->_locate_image_files(
        'sample_icons/vynil.png'
    );
    my $ra_expected = [
        {
          'parentdir' => 'sample_icons/',
          'name' => 'vynil.png',
          'pathname' => 'sample_icons/vynil.png'
        },
    ];

    my %result = map { $_->{name} => $_ } @$ra_result;
    my %expected = map { $_->{name} => $_ } @$ra_expected;

    is_deeply(\%result, \%expected, 
        'expected result on one existing file'
    );
}

done_testing();
