use strict;
use warnings;

package App::Rssfilter::Feed::Storage::Test::FetchersBehaveSensibleWhenUnderlyingFileNotPresent;

use Test::Routine;
use Test::More;
use Mojo::DOM;
use namespace::autoclean;
use Method::Signatures;

requires 'feed_storage';
requires 'tempfile';
requires 'tempdir';

test fetchers_behave_sensible_when_underlying_file_not_present => method {
    $self->tempfile->remove;

    is(
        $self->feed_storage->last_modified,
        'Thu, 01 Jan 1970 00:00:00 GMT',
        'last_modified returns the epoch when its underlying file is not available'
    );

    is(
        $self->feed_storage->load_existing,
        Mojo::DOM->new(''),
        'load_existing returns an empty Mojo::DOM instance when the underlying file is not available'
    );

    $self->tempdir->rmtree(0); # 0 -> not verbose and old File::Path::rmtree behaviour
    $self->feed_storage->save_feed( Mojo::DOM->new( '<make>noise, a phone call</make>' ) );
    is(
        $self->tempfile->slurp,
        '<make>noise, a phone call</make>',
        'save_feed creates a directory if it doesn\'t exist'
    );
};

1;
