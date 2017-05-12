package Dancer::SearchApp::Extractor::Audio;
use strict;
use Carp 'croak';
use Promises 'deferred';
#no warnings 'experimental';
#use feature 'signatures';
use MP3::Tag;
use POSIX 'strftime';
use HTML::Entities;

use vars qw($VERSION);
$VERSION = '0.06';

=head1 File types

This uses L<MP3::Tag> and thus likely only handles mp3 files.

=cut

sub examine {
    my( $class, %options ) = @_;
    my $info = $options{info};
    my $meta = $options{ meta };
    
    my $result = deferred;
    my $mime_type = $meta->{"Content-Type"};
    
    if( $mime_type =~ m!^audio/mpeg$! ) {
        my $mp3;
        my %res = (
            url    => $options{ url },
            file   => $options{ filename },
            folder => $options{ folder },
        );
        my $file = $options{ filename };
        
        # If we have a filename, use that
        if( $file ) {
            $mp3 = MP3::Tag->new("$file");
            
            my $ctime = (stat $file)[10];
            $res{ creation_date } = strftime('%Y-%m-%d %H:%M:%S', localtime($ctime));

        } elsif( $options{ content }) {
            # If we have in-memory content, just open a filehandle to it
            # This involves writing MP3::Tag::File::InMemory, which overrides
            # the ->filename and ->open method
            croak "In-memory handling is not yet supported, sorry";
        }
        
        if( $mp3) {

            # go go go
            my ($title, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();
            $res{ title } = $title || $file->basename;
            $res{ author } = $artist;
            $res{ language } = 'en'; # ...
            $res{ content } = encode_entities( join "-", $artist, $album, $track, $comment, $genre, $file->basename, 'mp3' );
            $res{ mime_type } = $mime_type;
            # We should also calculate the duration here, and some more information
            
            $result->resolve( \%res );
        } else {
            # Nothing found
            $result->resolve();
        }
    } else {
        $result->resolve();
    }
    
    $result->promise
}

1;