package Catalyst::View::XML::Feed;
use Moose;
extends 'Catalyst::View';
use XML::Feed;
use Scalar::Util ();
use namespace::autoclean;

our $VERSION = '0.09';

has default_format => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'RSS 1.0',
    documentation => 'The default format for a feed, when the format cannot otherwise be determined.  Acceptable values are: "Atom", "RSS 0.91", "RSS 1.0", "RSS 2.0".',
);
has xml_feed_attributes => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    default  => sub {
        [ qw(id title link description modified base tagline
             author language copyright generator self_link)
        ]
    },
);
has xml_feed_entry_attributes => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
    default  => sub {
        [ qw(id title content link modified issued base summary category tags author) ]
    },
);

sub render {
    my ($self, $c, $feed) = @_;

    $feed = $self->_make_feed_recognizable($feed);

    return $self->_render($feed);
}

sub process {
    my ($self, $c) = @_;
    my $feed = $c->stash->{feed};

    if (defined $feed) {
        $feed = $self->_make_feed_recognizable($feed);
        $c->res->content_type( $self->_content_type_for_feed($feed) );
        $c->res->body( $self->_render($feed) );
        return 1;

    } else {
        $c->log->error("No 'feed' value was found in the stash.");
        return 0;
    }
}

# You need to run the feed through _make_feed_recognizable() first.
sub _render {
    my ($self, $feed) = @_;
    return undef unless $feed;

    # Plain string.
    if (! ref $feed) {
        return $feed;

    # Common RSS/Atom objects...
    } elsif ($feed->can('as_xml')) {
        return $feed->as_xml();
    } elsif ($feed->can('as_string')) {
        return $feed->as_string();
    }

    return undef;
}

# Returns one of the common RSS or Atom modules, or a string.
sub _make_feed_recognizable {
    my ($self, $feed) = @_;

    # XML in a string? pass through
    if (! ref $feed) {
        return $feed;

    # Common Atom/RSS module? pass through
    } elsif (Scalar::Util::blessed($feed)) {
        for my $module (('XML::Feed', 'XML::RSS', 'XML::Atom::SimpleFeed',
                         'XML::Atom::Feed', 'XML::Atom::Syndication::Feed'))
        {
            if ($feed->isa($module)) {
                return $feed;
            }
        }
    }

    return $feed unless Scalar::Util::blessed($feed) || ref $feed eq 'HASH';

    # Otherwise, let's convert it to an XML::Feed.

    my $format = Scalar::Util::blessed($feed) && $feed->can('format')
        ? $feed->format
        : (defined $feed->{format} ? $feed->{format} : $self->default_format);
    my @format;
    if (ref $format) {
        # Docs for this say format should be a string ('RSS 2.0'), but
        # format can also be XML::Feed style ('RSS', version => '2.0')
        # since all other attributes are like XML::Feed
        @format = ref $format eq 'ARRAY'
            ? @$format
            : %$format;
    } else {
        @format = split /\s+/, $format;
    }
    if (scalar(@format) > 1) {
        splice @format, 1, 0, 'version';
    }

    my $xf_feed = XML::Feed->new(@format);

    my @entries;
    # Set feed attributes, get entries.
    if (Scalar::Util::blessed($feed)) {
        for my $key (@{ $self->xml_feed_attributes }) {
            if ($feed->can($key)) {
                $xf_feed->$key( $feed->$key() );
            }
        }
        if ($feed->can('entries')) {
            # Allow for feed->entries to return either array or arrayref.
            @entries = ($feed->entries);
            if (scalar(@entries) == 1 && ref($entries[0]) eq 'ARRAY' && ! Scalar::Util::blessed($entries[0])) {
                @entries = @{ $entries[0] };
            }
        }
    } else {
        for my $key (@{ $self->xml_feed_attributes }) {
            if (exists $feed->{$key}) {
                $xf_feed->$key( $feed->{$key} );
            }
        }
    }
    unless (@entries) {
        @entries = exists $feed->{entries} ? @{ $feed->{entries} } : ();
    }

    # Create the entries.
    for my $entry (@entries) {
        my $xf_entry = XML::Feed::Entry->new($format[0]);

        if (Scalar::Util::blessed($entry)) {
            for my $key (@{ $self->xml_feed_entry_attributes }) {
                if ($entry->can($key)) {
                    $xf_entry->$key( $entry->$key() );
                }
            }
        } else {
            for my $key (@{ $self->xml_feed_entry_attributes }) {
                if (exists $entry->{$key}) {
                    $xf_entry->$key( $entry->{$key} );
                }
            }
        }
        $xf_feed->add_entry($xf_entry);
    }

    return $xf_feed;
}

# You need to run the feed through _make_feed_recognizable() first.
sub _content_type_for_feed {
    my ($self, $feed) = @_;

    # Plain string.
    if (! ref $feed) {
        return 'text/xml';

    # Objects...
    } elsif ($feed->isa('XML::Feed')) {
        if ($feed->format && lc($feed->format) =~ /atom/i) {
            return 'application/atom+xml';
        } elsif ($feed->format && lc($feed->format) =~ /rss/i) {
            return 'application/rss+xml';
        } else {
            return 'text/xml';
        }

    } elsif ($feed->isa('XML::RSS')) {
        return 'application/rss+xml';

    } elsif ($feed->isa('XML::Atom::SimpleFeed')) {
        return 'application/atom+xml';

    } elsif ($feed->isa('XML::Atom::Feed')) {
        return 'application/atom+xml';

    } elsif ($feed->isa('XML::Atom::Syndication::Feed')) {
        return 'application/atom+xml';

    } else {
        return 'text/xml';
    }
}

=head1 NAME

Catalyst::View::XML::Feed - Catalyst view for RSS, Atom, or other XML feeds

=head1 SYNOPSIS

Create your view, e.g. lib/MyApp/View/Feed.pm

  package MyApp::View::Feed;
  use base qw( Catalyst::View::XML::Feed );
  1;

In a controller, set the C<feed> stash variable and forward to your view:

  sub rss : Local {
      my ($self, $c) = @_;
      $c->stash->{feed} = $feed_obj_or_data;
      $c->forward('View::Feed');
  }


=head1 DESCRIPTION

Catalyst::View::XML::Feed is a hassle-free way to serve an RSS, Atom, or other XML feed from your L<Catalyst> application.

Your controller should put feed data into C<< $c->stash->{feed} >>.

=head1 DATA FORMATS

The value in C<< $c->stash->{feed} >> can be an object from any of the
popular L<RSS or Atom classes|/"XML::Feed">,
a L<plain Perl data structure|/"Plain Perl data">,
L<arbitrary custom objects|/"Arbitrary custom objects">, or an 
L<xml string|/"Plain text">.

=head2 Plain Perl data

  $c->stash->{feed} = {
      format      => 'RSS 1.0',
      id          => $c->req->base,
      title       => 'My Great Site',
      description => 'Kitten pictures for the masses',
      link        => $c->req->base,
      modified    => DateTime->now,

      entries => [
          {
              id       => $c->uri_for('rss', 'kitten_post')->as_string,
              link     => $c->uri_for('rss', 'kitten_post')->as_string,
              title    => 'First post!',
              modified => DateTime->now,
              content  => 'This is my first post!',
          },
          # ... more entries.
      ],
  };

=over 4

=item Keys for feed

The C<feed> hash can take any of the following keys.  They are identical
to those supported by L<XML::Feed>.  See L<XML::Feed> for more details.

I<Note>: Depending on the feed format you choose, different subsets of
attributes might be required.  As such, it is recommended that you run the
generated XML through a validator such as L<http://validator.w3.org/feed/>
to ensure you included all necessary information.

=over 4

=item format

Can be any of: "Atom", "RSS 0.91", "RSS 1.0", "RSS 2.0"

=item id

=item title

=item link

=item description

=item modified

This should be a L<DateTime> object.

=item base

=item tagline

=item author

=item language

=item copyright

=item generator

=item self_link

=item entries

An array ref of L<entries|/"Keys for entries">.

=back 

=item Keys for entries

The C<entries> array contains any number of hashrefs, each representing
an entry in the feed. Each can contain any of the following keys.
They are identical to those of L<XML::Feed::Entry>.  See L<XML::Feed::Entry> 
for details.

I<Note>: Depending on the feed format you choose, different subsets of
attributes might be required.  As such, it is recommended that you run the
generated XML through a validator such as L<http://validator.w3.org/feed/>
to ensure you included all necessary information.

=over 4

=item id

=item title

=item content

=item link

=item modified

This should be a L<DateTime> object.

=item issued

This should be a L<DateTime> object.

=item base

=item summary

=item category

=item tags

=item author

=back 

=back

=head2 Arbitrary custom objects

If you have custom objects that you would like to turn into feed entries,
this can be done similar to L<plain Perl data structures|/"Plain Perl data">.

For example, if we have a C<DB::BlogPost> L<DBIx::Class> model, we can do the 
following:

  $c->stash->{feed} = {
      format      => 'Atom',
      id          => $c->req->base,
      title       => 'My Great Site',
      description => 'Kitten pictures for the masses',
      link        => $c->req->base,
      modified    => DateTime->now,

      entries => [ $c->model('DB::BlogPost')->all() ],
  };

The view will go through the L<keys for entries|/"Keys for entries"> fields
and, if possible, call a method of the same name on your entry object
(e.g. C<< $your_entry->title(); $your_entry->modified(); >>) to get that
value for the XML.

Any missing fields are simply skipped.

If your class's method names do not match up to the C<entries> keys,
you can simply alias them by wrapping with another method.  For example, if your
C<DB::BlogPost> has a C<post_title> field which should be the title
for the feed entry, you can add this to BlogPost.pm:

  sub title { $_[0]->post_title }

=head2 XML::Feed

An L<XML::Feed> object.

  $c->stash->{feed} = $xml_feed_obj;

=head2 XML::RSS

An L<XML::RSS> object.

  $c->stash->{feed} = $xml_rss_obj;

=head2 XML::Atom::SimpleFeed

An L<XML::Atom::SimpleFeed> object.

  $c->stash->{feed} = $xml_atom_simplefeed_obj;

=head2 XML::Atom::Feed

An L<XML::Atom::Feed> object.

  $c->stash->{feed} = $xml_atom_feed_obj;

=head2 XML::Atom::Syndication::Feed

An L<XML::Atom::Syndication::Feed> object.

  $c->stash->{feed} = $xml_atom_syndication_feed_obj;

=head2 Plain text

If none of the formats mentioned above are suitable, you may also 
provide a string containing the XML data.

  $c->stash->{feed} = $xml_string;

=head1 SOURCE REPOSITORY

L<http://github.com/mstratman/Catalyst-View-XML-Feed>

=head1 AUTHOR

Mark A. Stratman E<lt>stratman@gmail.comE<gt>

=head1 CONTRIBUTORS

Thomas Doran (t0m)

=head1 COPYRIGHT & LICENSE

Copyright 2011 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
