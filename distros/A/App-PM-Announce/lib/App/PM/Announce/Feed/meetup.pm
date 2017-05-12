package App::PM::Announce::Feed::meetup;

use warnings;
use strict;

use Moose;
extends 'App::PM::Announce::Feed';

use File::Temp;

has venue => qw/is ro/;

sub fetch_image {
    my $self = shift;
    my $image = shift;

    {
        my $uri = $image;
        my $response = $self->agent->get( $uri );
        $self->logger->debug( "Fetching image at $uri" );
        die "Unable to fetch image at $uri" unless $response->is_success;
        die "File at $uri doesn't seem to be an image" unless my ($extension) = $response->header( 'Content-Type' ) =~ m/image\/(.*)/;
#        $extension = "jpg";
        my $image = File::Temp->new( UNLINK => 0, SUFFIX => ".$extension" );
        $self->logger->debug( "Saving image to $image" );
        print $image $response->decoded_content;
        close $image or warn $!;
        $self->logger->debug( "Saved " . -s "$image" );
        return $image;
    }
}

sub announce {
    my $self = shift;
    my %event = @_;

    my $username = $self->username;
    my $password = $self->password;
    my $uri = $self->uri;
    my $venue = $event{venue} || $self->venue;
    my $datetime = $event{datetime};

    $self->get("http://www.meetup.com/login/");

    $self->logger->debug( "Login as $username / $password" );

    $self->submit_form(
        fields => {
            email => $username,
            password => $password,
        },
        form_number => 1,
        button => 'submitButton',
    );

    die "Wasn't logged in" unless $self->content =~ m/Your Meetup Groups/;

    my %optional;
    my ($image, $temporary_image);
    if ($image = $event{image}) {

        if ($image =~ m/^https?:\/\//) {
            $image = $self->fetch_image( $image );
            $temporary_image = 1;
        }
        
        $optional{attachfile} = $image.'';
        $self->logger->debug( "Attaching $image" );
    }

    $self->get($uri);

    my $hour12 = $datetime->hour;
    $hour12 -= 12 if $hour12 > 12;
    $hour12 = 12 unless $hour12;
    $self->submit_form(
        fields => {
            title => $self->format( \%event => 'title' ),
            description => $self->format( \%event => 'description' ),
            venueId => $venue,
            origId => $venue,
            'event.day' => $datetime->day,
            'event.month' => $datetime->month,
            'event.year' => $datetime->year,
            'event.hour12' => $hour12,
            'event.minute' => $datetime->minute,
            'event.ampm' => $datetime->hour >= 12 ? 'PM' : 'AM',
            %optional,
        },
        form_number => 1,
        button => 'submit_next',
    );

    unlink $image or warn "Couldn't unlink $image: $!" if $temporary_image;

    my $tree = $self->tree;

    die "Unable to parse HTML" unless $tree;

    my $a = $tree->look_down( _tag => 'a', sub { $_[0]->as_text =~ m/Or, go straight to this Meetup's page/ } );

    die "Not sure if discussion was posted (couldn't find success link)" unless $a;

    my $href = $a->attr( 'href' );

    my $meetup_link = URI->new( $href );
    $meetup_link->query( undef );

    $self->logger->debug( "Submitted to meetup at $uri" );

    return { meetup_link => $meetup_link };
}

1;
