package AnnoCPAN::Feed;

$VERSION = '0.22';

use strict;
use warnings;
use XML::RSS;
use POSIX qw(strftime);

sub rss_channel {
    my ($self, %args) = @_;
    my $rss  = XML::RSS->new(version => '1.0');

    $rss->channel(
        link         => $args{link},
        title        => $args{title},
        description  => $args{description} || $args{title},
        dc => {
               date       => strftime('%Y-%m-%dT%H:%M:%S+00:00', gmtime),
               subject    => "Perl",
               creator    => 'itub@cpan.org',
               publisher  => 'itub@cpan.org',
               rights     => 
                    'Redistributable under the same terms as Perl itself',
               language   => 'en-us',
              },
        syn => {
                updatePeriod     => "daily",
                updateFrequency  => $args{updateFrequency} || 24,
                updateBase       => "1901-01-01T00:00+00:00",
               },
    );
    return $rss;
}

sub note_rss {
    my ($self, %args) = @_;

    my $rss = $self->rss_channel(%args);

    my $base = AnnoCPAN::Config->option('root_uri_abs');
    for my $note (@{$args{notes}}) {
        next unless $note->section;
        my $podver = $note->section->podver;
        $rss->add_item(
            title       => $note->pod->name,
            link        => sprintf("$base/~%s/%s/%s#note_%s",
                $podver->distver->pause_id, $podver->distver->distver, 
                $podver->path, $note->id),
            description => $note->html,
            dc => {
                creator  => ($note->user->username),
                date     => strftime('%Y-%m-%dT%H:%M:%S+00:00', 
                gmtime($note->time)),
            },
        );    

    }
    return $rss;
}

sub dist_rss {
    my ($self, %args) = @_;

    my $rss = $self->rss_channel(%args);

    my $base = AnnoCPAN::Config->option('root_uri_abs');
    for my $dist (@{$args{dists}}) {
        my $distver = $dist->latest_distver;
        my $desc = "<ul>\n";
        #printf "$dist - %s\n", $dist->name;
        for my $podver ($distver->podvers) {
            no warnings 'uninitialized';
            #print "\t*** $podver ***\n";
            #printf "\t$podver - %s - %s\n", $podver->name, $podver->description;
            $desc .= sprintf "<li>%s - %s</li>\n",
                $podver->name, $podver->description;
        }
        $desc .= "</ul>\n";
        $rss->add_item(
            title       => $dist->name,
            link        => sprintf("$base/dist/%s",
                $dist->name),
            description => $desc,
            dc => {
                creator  => $distver->pause_id,
                date     => strftime('%Y-%m-%dT%H:%M:%S+00:00', 
                    gmtime($dist->creation_time)),
            },
        );    

    }
    return $rss;
}

1;

