#/usr/bin/env perl -T

use lib qw(lib);
use Test::More tests => 48;
use Data::Dumper;
use warnings;
use strict;


use Catalyst::Request::Upload;
use Catalyst::Plugin::Upload::Audio::File;

ok( Catalyst::Request::Upload->can("length") );
ok( Catalyst::Request::Upload->can("bitrate") );
ok( Catalyst::Request::Upload->can("sample_rate") );
ok( Catalyst::Request::Upload->can("channels") );
ok( Catalyst::Request::Upload->can("title") );
ok( Catalyst::Request::Upload->can("artist") );
ok( Catalyst::Request::Upload->can("album") );
ok( Catalyst::Request::Upload->can("comment") );
ok( Catalyst::Request::Upload->can("genre") );
ok( Catalyst::Request::Upload->can("year") );
ok( Catalyst::Request::Upload->can("track") );
ok( Catalyst::Request::Upload->can("total") );

################################################################################
my $shared = {
        'track'         => 2,
        'total'         => 3,
        'genre'         => 'Rock',
        'artist'        => 'Artist',
        'album'         => 'Album',
        'comment'       => 'Comment',
        'title'         => 'Title',
        'year'          => '2005',
};

my $file_meta = {
    'flac' => {
        'bitrate'       => 91081,
        'channels'      => 1,
        'length'        => 4,
        'sample_rate'   => 8000,
        'filename'      => 'test.flac',

        },
    'mp3' => {
        'bitrate'       => 8,
        'channels'      => 1,
        'length'        => 4,
        'sample_rate'   => 8000,
        'filename'      => 'test.mp3',
        },
    'ogg' => {
        'bitrate'       => 28000,
        'channels'      => 1,
        'length'        => 0,
        'sample_rate'   => 8000,
        'filename'      => 'test.ogg',
        },
};
# Filetypes supported by Audio::File 'out of the box'
for ( qw/flac ogg mp3/ ) {
    # Love hashslice syntax :)
    @{$file_meta->{$_}}{keys %$shared} = values %$shared;
    &run_tests($_);
}

sub run_tests {
    my $type = shift;
    my $ul = &new_upload($type);

    foreach my $attr ( qw/length bitrate sample_rate
                channels title artist album
                comment genre year track total/ )
    {

        is( $ul->$attr, $file_meta->{$type}->{$attr},
            "test.$type, $attr value matches" );
    }
}

sub new_upload {
    my $type = shift;
    my $upload = Catalyst::Request::Upload->new();
    my $filename = "./t/test.$type";
    $upload->tempname($filename);
    $upload->filename($filename);
    $upload->size(-s $filename);

    $upload->type("audio/flac") if ($filename =~ /\.flac$/i);
    $upload->type("audio/mpeg3") if ($filename =~ /\.mp3/i);
    $upload->type("audio/ogg") if ($filename =~ /\.ogg/i);
    return $upload;
}

__END__
