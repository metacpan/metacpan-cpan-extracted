package App::Twimap::Tweet;
use Moose;
use DateTime;
use DateTime::Format::Strptime;
use Email::Date::Format qw(email_date);
use HTML::Entities;
use Text::Wrap qw(wrap);

has 'data'        => ( is => 'ro', isa => 'HashRef', required => 1 );
has 'expand_urls' => ( is => 'ro', isa => 'Bool',    default  => 1 );
has 'oembed_urls' => ( is => 'ro', isa => 'Bool',    default  => 1 );

my $_parser = DateTime::Format::Strptime->new(
    pattern  => '%a %b %d %T %z %Y',
    locale   => 'en_GB',
    on_error => 'croak',
);

sub id {
    my $self  = shift;
    my $tweet = $self->data;
    return $tweet->{id_str};
}

sub in_reply_to_status_id {
    my $self  = shift;
    my $tweet = $self->data;
    return $tweet->{in_reply_to_status_id_str};
}

sub to_email {
    my $self  = shift;
    my $tweet = $self->data;

    my $tid = $self->id;

    my $epoch       = $_parser->parse_datetime( $tweet->{created_at} )->epoch;
    my $date        = email_date($epoch);
    my $name        = $tweet->{user}->{name};
    my $screen_name = $tweet->{user}->{screen_name};

    my $in_reply_to_status_id = $self->in_reply_to_status_id;
    my $in_reply_to
        = $in_reply_to_status_id
        ? "<$in_reply_to_status_id\@twitter>"
        : '';
    my $url = "https://twitter.com/$screen_name/status/$tid";
    my $text;
    if ( $tweet->{retweeted_status} ) {
        $text
            = 'RT @'
            . $tweet->{retweeted_status}->{user}->{screen_name} . ': '
            . $tweet->{retweeted_status}->{text};
    } else {
        $text = $tweet->{text};
    }

    my $subject        = $text;
    my $subject_offset = 0;
    my $text_offset    = 0;

    my $oembed = '';

    if ( $tweet->{entities} && $tweet->{entities}->{urls} ) {
        foreach my $entity ( @{ $tweet->{entities}->{urls} } ) {

            my $expanded_url = $entity->{expanded_url} || $entity->{url};
            next unless $expanded_url;
            $expanded_url = $self->expand_url($expanded_url)
                if $self->expand_urls;
            substr(
                $subject,
                $entity->{indices}->[0] + $subject_offset,
                $entity->{indices}->[1] - $entity->{indices}->[0]
            ) = $expanded_url;
            $subject_offset
                += length($expanded_url) - length( $entity->{url} );

            my $href = qq{<a href="$expanded_url">$expanded_url</a>};
            substr(
                $text,
                $entity->{indices}->[0] + $text_offset,
                $entity->{indices}->[1] - $entity->{indices}->[0]
            ) = $href;
            $text_offset += length($href) - length( $entity->{url} );

            if ( $self->oembed_urls ) {
                $oembed = $self->oembed_url($expanded_url) || '';
            }
        }
    }

    $subject =~ s{\n}{ }g;
    local ($Text::Wrap::break)   = qr/\s/;
    local ($Text::Wrap::columns) = 72;
    local ($Text::Wrap::huge)    = 'overflow';

    my $body_text = wrap( '', '', $subject ) . "\n\n$url";

    my $body_html
        = qq{$text\n<br/><br/>\n$oembed<br/><br/>\n\n<a href="$url">$url</a>};

    my $from = Email::Address->new( $name, "$screen_name\@twitter",
        "($screen_name)" );

    my @headers = (
        From         => $from,
        Subject      => decode_entities($subject),
        Date         => $date,
        'Message-Id' => "<$tid\@twitter>",
    );
    push @headers, 'In-Reply-To' => $in_reply_to if $in_reply_to;

    my @parts = (
        Email::MIME->create(
            attributes => {
                content_type => "text/plain",
                disposition  => "inline",
                charset      => "utf-8",

            },
            header_str => [ Date => $date ],
            body       => $body_text,
        ),
        Email::MIME->create(
            attributes => {
                content_type => "text/html",
                disposition  => "inline",
                charset      => "utf-8",

            },
            header_str => [ Date => $date ],
            body       => $body_html,
        ),
    );

    my $email = Email::MIME->create(
        attributes => {
            boundary     => '1317546824.2C8b2BC51.4794',
            content_type => "multipart/alternative",
            charset      => "utf-8",
        },
        header_str => \@headers,
        parts      => [@parts],
    );

    return $email;
}

sub expand_url {
    my ( $self, $url ) = @_;
    my $ua = LWP::UserAgent->new(
        env_proxy             => 1,
        timeout               => 5,
        max_size              => 2048,
        agent                 => "Twimap",
        requests_redirectable => [],
    );
    my $res = $ua->get($url);
    return $url unless $res->is_redirect;
    my $location = $res->header('Location');
    return $url unless defined $location;

    unless ( $location =~ /^http/ ) {
        my $uri = URI::WithBase->new( $location, $url )->abs;
        return $self->expand_url($uri);
    }
    return $self->expand_url($location);
}

sub oembed_url {
    my ( $self, $url ) = @_;

    my $consumer = Web::oEmbed::Common->new();
    $consumer->agent->timeout(5);

    #$consumer->set_embedly_api_key('0123ABCD0123ABCD0123ABCD');
    my $response = $consumer->embed($url);
    return $response->render if ($response);
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

App::Twimap::Tweet - Represent a Tweet and convert to email

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2011, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
