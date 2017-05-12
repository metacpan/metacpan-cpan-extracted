use strict;
use warnings;

package App::Rssfilter::Feed::Storage::Test::LoadExistingTakesContentFromFile;

use Test::Routine;
use Test::More;
use Mojo::DOM;
use namespace::autoclean;
use Method::Signatures;

requires 'feed_storage';
requires 'tempfile';

test load_existing_takes_content_from_file => method {
    $self->tempfile->spew('<surprise>your favourite bean</surprise>');

    is(
        $self->feed_storage->load_existing,
        Mojo::DOM->new('<surprise>your favourite bean</surprise>'),
        'load_existing returns DOM representation of existing content if filname refers to a existing file'
    );
};

1;
