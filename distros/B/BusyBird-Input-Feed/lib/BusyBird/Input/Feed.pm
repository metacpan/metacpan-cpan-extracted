package BusyBird::Input::Feed;
use strict;
use warnings;
use XML::FeedPP;
use DateTime::Format::ISO8601;
use BusyBird::DateTime::Format;
use DateTime;
use Try::Tiny;
use Carp;
use WWW::Favicon ();
use LWP::UserAgent;
use URI;

our $VERSION = "0.05";

our @CARP_NOT = qw(Try::Tiny XML::FeedPP);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        use_favicon => defined($args{use_favicon}) ? $args{use_favicon} : 1,
        favicon_detector => WWW::Favicon->new,
        user_agent => defined($args{user_agent}) ? $args{user_agent} : do {
            my $ua = LWP::UserAgent->new;
            $ua->env_proxy;
            $ua->timeout(30);
            $ua->agent("BusyBird::Inpu::Feed-$VERSION");  ## some Web sites ban LWP::UserAgent's default UserAgent...
            $ua;
        },
        image_max_num => defined($args{image_max_num}) ? $args{image_max_num} : 3,
    }, $class;

    ## Note that WWW::Favicon#ua accessor method is not documented (as of version 0.03001)
    $self->{favicon_detector}->ua($self->{user_agent});
    
    return $self;
}

sub _get_url_head_and_dir {
    my ($url_raw) = @_;
    return (undef, undef) if not defined $url_raw;
    my $url = URI->new($url_raw);
    my $scheme = $url->scheme;
    my $authority = $url->authority;
    return (undef, undef) if !$scheme || !$authority;
    my $url_head = "$scheme://$authority";
    my $url_dir;
    my $path = $url->path;
    if($path =~ m{^(.*/)}i) {
        $url_dir = $1;
    }else {
        $url_dir = "/";
    }
    return ($url_head, $url_dir);
}

sub _extract_image_urls {
    my ($self, $feed_item) = @_;
    return () if $self->{image_max_num} == 0;
    my $content = $feed_item->description;
    return () if !defined($content);
    my ($url_head, $url_dir) = _get_url_head_and_dir($feed_item->link);
    my @urls = ();
    while(($self->{image_max_num} < 0 || @urls < $self->{image_max_num})
          && $content =~ m{<\s*img\s+[^>]*src\s*=\s*(['"])([^>]+?)\1[^>]*>}ig) {
        my $url = URI->new($2);
        if(!$url->scheme) {
            ## Only "path" segment is in the src attribute.
            next if !defined($url_head) || !defined($url_dir);
            if(substr("$url", 0, 1) eq "/") {
                $url = "$url_head$url";
            }else {
                $url = "$url_head$url_dir$url";
            }
        }
        push @urls, "$url";
    }
    return @urls;
}

sub _get_home_url {
    my ($self, $feed, $statuses) = @_;
    my $home_url = $feed->link;
    return $home_url if defined $home_url;
    
    foreach my $status (@$statuses) {
        $home_url = $status->{busybird}{status_permalink} if defined($status->{busybird});
        return $home_url if defined $home_url;
    }
    return undef;
}

sub _get_favicon_url {
    my ($self, $feed, $statuses) = @_;
    return try {
        my $home_url = $self->_get_home_url($feed, $statuses);
        return undef if not defined $home_url;
        my $favicon_url = $self->{favicon_detector}->detect($home_url);
        return undef if not defined $favicon_url;
        my $res = $self->{user_agent}->get($favicon_url);
        return undef if !$res->is_success;
        my $type = $res->header('Content-Type');
        return undef if defined($type) && $type !~ /^image/i;
        return $favicon_url;
    };
}

sub _make_timestamp_datetime {
    my ($self, $timestamp_str) = @_;
    return undef if not defined $timestamp_str;
    if($timestamp_str =~ /^\d+$/) {
        return DateTime->from_epoch(epoch => $timestamp_str, time_zone => '+0000');
    }
    my $datetime = try { DateTime::Format::ISO8601->parse_datetime($timestamp_str) };
    return $datetime if defined $datetime;
    return BusyBird::DateTime::Format->parse_datetime($timestamp_str);
}

sub _make_status_from_item {
    my ($self, $feed_title, $feed_item) = @_;
    my $created_at_dt = $self->_make_timestamp_datetime($feed_item->pubDate);
    my $status = {
        text => $feed_item->title,
        busybird => { status_permalink => $feed_item->link },
        created_at => ($created_at_dt ? BusyBird::DateTime::Format->format_datetime($created_at_dt) : undef ),
        user => { screen_name => $feed_title },
    };
    my $guid = $feed_item->guid;
    my $item_id;
    if(defined $guid) {
        $item_id = $guid;
        $status->{busybird}{original}{id} = $guid;
    }else {
        $item_id = $feed_item->link;
    }
    if(defined($created_at_dt) && defined($item_id)) {
        $status->{id} = $created_at_dt->epoch . '|' . $item_id;
    }elsif(defined($item_id)) {
        $status->{id} = $item_id;
    }
    my @image_urls = $self->_extract_image_urls($feed_item);
    if(@image_urls) {
        $status->{extended_entities}{media} = [map { +{ media_url => $_, indices => [0,0] } } @image_urls];
    }
    return $status;
}

sub _make_statuses_from_feed {
    my ($self, $feed) = @_;
    my $feed_title = $feed->title;
    my $statuses = [ map { $self->_make_status_from_item($feed_title, $_) } $feed->get_item ];
    return $statuses if !$self->{use_favicon};
    my $favicon_url = $self->_get_favicon_url($feed, $statuses);
    return $statuses if not defined $favicon_url;
    $_->{user}{profile_image_url} = $favicon_url foreach @$statuses;
    return $statuses;
}

sub _parse_with_feedpp {
    my ($self, $feed_source, $feed_type) = @_;
    return $self->_make_statuses_from_feed(XML::FeedPP->new(
        $feed_source, -type => $feed_type,
        utf8_flag => 1, xml_deref => 1, lwp_useragent => $self->{user_agent},

        ## FeedPP and TreePP mess up with User-Agent. It's pretty annoying.
        user_agent => scalar($self->{user_agent}->agent),
    ));
}

sub parse_string {
    my ($self, $string) = @_;
    return $self->_parse_with_feedpp($string, "string");
}

*parse = *parse_string;

sub parse_file {
    my ($self, $filename) = @_;
    return $self->_parse_with_feedpp($filename, "file");
}

sub parse_url {
    my ($self, $url) = @_;
    return $self->_parse_with_feedpp($url, "url");
}

*parse_uri = *parse_url;

1;
__END__

=pod

=head1 NAME

BusyBird::Input::Feed - input BusyBird statuses from RSS/Atom feed

=head1 SYNOPSIS

    use BusyBird;
    use BusyBird::Input::Feed;
    
    my $input = BusyBird::Input::Feed->new;
    
    my $statuses = $input->parse($feed_xml);
    timeline("feed")->add($statuses);
    
    $statuses = $input->parse_file("feed.atom");
    timeline("feed")->add($statuses);
    
    $statuses = $input->parse_url('https://metacpan.org/feed/recent?f=');
    timeline("feed")->add($statuses);

=head1 DESCRIPTION

L<BusyBird::Input::Feed> converts RSS and Atom feeds into L<BusyBird> status objects.

For convenience, an executable script L<busybird_input_feed> is bundled in this distribution.

=head1 CLASS METHODS

=head2 $input = BusyBird::Input::Feed->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<use_favicon> => BOOL (optional, default: true)

If true (or omitted or C<undef>), it tries to use the favicon of the Web site providing the feed
as the statuses' icons.

If it's defined and false, it won't use favicon.

=item C<user_agent> => L<LWP::UserAgent> object (optional)

L<LWP::UserAgent> object for fetching documents.

=item C<image_max_num> => INT (optional, default: 3)

The maximum number of image URLs extracted from the feed item.

If set to 0, it extracts no images. If set to a negative value, it extracts all image URLs from the feed item.

The extracted image URLs are stored as Twitter Entities in the status's C<extended_entities> field,
so that L<BusyBird> will render them.
See L<BusyBird::Manual::Status/extended_entities.media> for detail.

=back

=head1 OBJECT METHODS

=head2 $statuses = $input->parse($feed_xml_string)

=head2 $statuses = $input->parse_string($feed_xml_string)

Convert the given C<$feed_xml_string> into L<BusyBird> C<$statuses>.
C<parse()> method is an alias for C<parse_string()>.

C<$feed_xml_string> is the XML data to be parsed.
It must be a string encoded in UTF-8.

Return value C<$statuses> is an array-ref of L<BusyBird> status objects.

If C<$feed_xml_string> is invalid, it croaks.

=head2 $statuses = $input->parse_file($feed_xml_filename)

Same as C<parse_string()> except C<parse_file()> reads the file named C<$feed_xml_filename> and converts its content.

=head2 $statuses = $input->parse_url($feed_xml_url)

=head2 $statuses = $input->parse_uri($feed_xml_url)

Same as C<parse_string()> except C<parse_url()> downloads the feed XML from C<$feed_xml_url> and converts its content.

C<parse_uri()> method is an alias for C<parse_url()>.

=head1 EXAMPLE

The example below uses L<Parallel::ForkManager> to parallelize C<parse_url()> method of L<BusyBird::Input::Feed>.
It greatly reduces the total time to download a lot of RSS/Atom feeds.

    use strict;
    use warnings;
    use Parallel::ForkManager;
    use BusyBird::Input::Feed;
    use open qw(:std :encoding(utf8));
    
    my @feeds = (
        'https://metacpan.org/feed/recent?f=',
        'http://www.perl.com/pub/atom.xml',
        'https://github.com/perl-users-jp/perl-users.jp-htdocs/commits/master.atom',
    );
    my $MAX_PROCESSES = 10;
    my $pm = Parallel::ForkManager->new($MAX_PROCESSES);
    my $input = BusyBird::Input::Feed->new;
    
    my @statuses = ();
    
    $pm->run_on_finish(sub {
        my ($pid, $exitcode, $id, $signal, $coredump, $statuses) = @_;
        push @statuses, @$statuses;
    });
    
    foreach my $feed (@feeds) {
        $pm->start and next;
        warn "Start loading $feed\n";
        my $statuses = $input->parse_url($feed);
        warn "End loading $feed\n";
        $pm->finish(0, $statuses);
    }
    $pm->wait_all_children;
    
    foreach my $status (@statuses) {
        print "$status->{user}{screen_name}: $status->{text}\n";
    }


=head1 SEE ALSO

=over

=item *

L<BusyBird>

=item *

L<BusyBird::Manual::Status>

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/BusyBird-Input-Feed>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/BusyBird-Input-Feed/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=BusyBird-Input-Feed>.
Please send email to C<bug-BusyBird-Input-Feed at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

