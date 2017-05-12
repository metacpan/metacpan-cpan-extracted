use strict;
use warnings;

package App::Rssfilter::Feed::Storage::Tester;

use Test::Most;

use App::Rssfilter::Feed::Storage;
use File::Temp;
use Path::Class;
use Mojo::DOM;
use Moo;

has feed_storage => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        App::Rssfilter::Feed::Storage->new(
            path => $self->group_name,
            name  => $self->feed_name,
        );
    },
);

has group_name => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        $self->tempdir;
    },
);

has feed_name => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        ( my $feed_name = $self->tempfile->basename ) =~ s/ [.] rss \z //xms;
        return $feed_name;
    },
);

has tempdir => (
    is => 'ro',
    default => sub {
        File::Temp->newdir;
    },
);

has tempfile => (
    is => 'lazy',
    default => sub {
        my ( $self ) = @_;
        File::Temp->new( DIR => $self->tempdir, SUFFIX => '.rss' );
    },
);

around tempfile => sub {
    my ( $orig, @args ) = @_;
    my $temp = $orig->( @args );
    $temp->close;
    Path::Class::File->new( $temp->filename );
};

1;
