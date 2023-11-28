package At::Lexicons::app::bsky::richtext::facet 0.02 {

    #~ https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/richtext/facet.json
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    #
    class At::Bluesky::Facet 1 {
        field $index : param;
        field $features : param;
        field $mention : param   = ();
        field $link : param      = ();
        field $tag : param       = ();
        field $byteSlice : param = ();
        ADJUST {
            use Carp qw[croak carp];
            $link = At::Bluesky::Facet::link->new( uri => $link ) if defined $link && !builtin::blessed $link;
            $tag  = At::Bluesky::Facet::tag->new( tag => $tag )   if defined $tag  && !builtin::blessed $tag;
        };

        method raw {
            {   index    => $index,
                features => $features,
                mention  => $mention,
                ( defined $link      ? ( link      => $link->raw )      : () ), ( defined $tag ? ( tag => $tag->raw ) : () ),
                ( defined $byteSlice ? ( byteSlice => $byteSlice->raw ) : () )
            }
        }
    };

    class At::Bluesky::Facet::link {
        field $uri : param;
        ADJUST {
            use URI;
            $uri = URI->new($uri) unless builtin::blessed $uri;
        };

        method raw {
            { uri => $uri->as_string }
        }
    }

    class At::Bluesky::Facet::tag {
        field $tag : param;
        ADJUST {
            use bytes;
            use Carp qw[croak carp];
            croak 'tag must be a string of 640 characters or 64 graphemes max' if bytes::length($tag) > 640 || length($tag) > 64;
        };

        method raw {
            { tag => $tag }
        }
    }

    class At::Bluesky::Facet::byteSlice {
        field $byteStart : param;
        field $byteEnd : param;
        ADJUST {
            use Carp qw[croak carp];
            croak 'byteStart must be 0 or above' unless $byteStart >= 0;
            croak 'byteEnd must be 0 or above'   unless $byteEnd >= 0;
        };

        method raw {
            { byteStart => $byteStart, byteEnd => $byteEnd }
        }
    }
}
1;
__END__
{
  "lexicon": 1,
  "id": "app.bsky.richtext.facet",
  "defs": {
    "main": {
      "type": "object",
      "required": ["index", "features"],
      "properties": {
        "index": { "type": "ref", "ref": "#byteSlice" },
        "features": {
          "type": "array",
          "items": { "type": "union", "refs": ["#mention", "#link", "#tag"] }
        }
      }
    },
    "mention": {
      "type": "object",
      "description": "A facet feature for actor mentions.",
      "required": ["did"],
      "properties": {
        "did": { "type": "string", "format": "did" }
      }
    },
    "link": {
      "type": "object",
      "description": "A facet feature for links.",
      "required": ["uri"],
      "properties": {
        "uri": { "type": "string", "format": "uri" }
      }
    },
    "tag": {
      "type": "object",
      "description": "A hashtag.",
      "required": ["tag"],
      "properties": {
        "tag": { "type": "string", "maxLength": 640, "maxGraphemes": 64 }
      }
    },
    "byteSlice": {
      "type": "object",
      "description": "A text segment. Start is inclusive, end is exclusive. Indices are for utf8-encoded strings.",
      "required": ["byteStart", "byteEnd"],
      "properties": {
        "byteStart": { "type": "integer", "minimum": 0 },
        "byteEnd": { "type": "integer", "minimum": 0 }
      }
    }
  }
}
