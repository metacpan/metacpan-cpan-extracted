package At::Lexicons::app::bsky::feed::post 0.02 {

    #~ https://github.com/bluesky-social/atproto/blob/main/lexicons/app/bsky/feed/post.json
    use v5.38;
    no warnings 'experimental::class';    # Be quiet.
    use feature 'class';
    #
    class At::Bluesky::Post 1 {
        field $text : param;
        field $createdAt : param;
        field $facets : param = ();
        field $reply : param  = ();
        field $langs : param  = ();
        field $labels : param = ();
        field $tags : param   = ();

=for todo
          "facets": {
            "type": "array",
            "items": { "type": "ref", "ref": "app.bsky.richtext.facet" }
          },
          "reply": { "type": "ref", "ref": "#replyRef" },
          "embed": {
            "type": "union",
            "refs": [
              "app.bsky.embed.images",
              "app.bsky.embed.external",
              "app.bsky.embed.record",
              "app.bsky.embed.recordWithMedia"
            ]
          },
          "langs": {
            "type": "array",
            "maxLength": 3,
            "items": { "type": "string", "format": "language" }
          },
          "labels": {
            "type": "union",
            "refs": ["com.atproto.label.defs#selfLabels"]
          },
          "tags": {
            "type": "array",
            "maxLength": 8,
            "items": { "type": "string", "maxLength": 640, "maxGraphemes": 64 },
            "description": "Additional non-inline tags describing this post."
          },
          "createdAt": { "type": "string", "format": "datetime" }
        }
=cut

        ADJUST {
            use bytes;
            use Carp qw[croak carp];
            croak 'createdAt must be a timestamp in ISO 8601 format' unless $createdAt    # cribbed from Regexp::Common::time
                =~ /^(?:(?=\d)(?:(?:\d{4})(?:-)(?:(?:(?=[01])(?:0[1-9]|1[012])))(?:-)(?:(?:(?=[0123])(?:0[1-9]|[12]\d|3[01]))))?(?:(?<=\d)[T_ ](?=\d))?(?:(?:(?:(?=[012])(?:[01]\d|2[0123])))(?::)(?:(?:[0-5]\d))(?::)(?:(?:(?=[0-6])(?:[0-5]\d|6[01]))(?:.\d+)?))?(?:(?:[-+](?:[01]\d|2[0-4])(?::?[0-5]\d)?|Z|GMT|UTC?|[ECMP][DS]T))?)$/;
            carp 'the At Protocol prefers time based on Zulu (Z)' unless $createdAt =~ /\dZ$/;
            croak 'text is too long. 3000 characters or 300 graphemes max' if bytes::length $text > 3000 || length $text > 300;
            croak 'langs must be an array of languages in CBP-47 format. For example: ["en-US", "fr"]. 3 languages max.'
                if defined $langs && ( ref $langs ne 'ARRAY' || scalar @$langs > 3 );
            if ( defined $tags ) {
                croak 'tags must be an array of strings. 8 tags max.' if ( ref $tags ne 'ARRAY' || scalar @$tags > 8 );
                croak 'tags must be strings of 640 characters or 64 graphemes max' if grep { bytes::length($_) > 640 || length($_) > 64 } @$tags;
            }
        }

        method raw {
            {   text      => $text,
                createdAt => $createdAt,
                ( defined $facets ? ( facets => $facets ) : () ), ( defined $langs ? ( langs => $langs ) : () ),
                ( defined $tags   ? ( tags   => $tags )   : () )
            }
        }
    }
};
1;
__END__
{
  "lexicon": 1,
  "id": "app.bsky.feed.post",
  "defs": {
    "main": {
      "type": "record",
      "key": "tid",
      "record": {
        "type": "object",
        "required": ["text", "createdAt"],
        "properties": {
          "text": { "type": "string", "maxLength": 3000, "maxGraphemes": 300 },
          "entities": {
            "type": "array",
            "description": "Deprecated: replaced by app.bsky.richtext.facet.",
            "items": { "type": "ref", "ref": "#entity" }
          },
          "facets": {
            "type": "array",
            "items": { "type": "ref", "ref": "app.bsky.richtext.facet" }
          },
          "reply": { "type": "ref", "ref": "#replyRef" },
          "embed": {
            "type": "union",
            "refs": [
              "app.bsky.embed.images",
              "app.bsky.embed.external",
              "app.bsky.embed.record",
              "app.bsky.embed.recordWithMedia"
            ]
          },
          "langs": {
            "type": "array",
            "maxLength": 3,
            "items": { "type": "string", "format": "language" }
          },
          "labels": {
            "type": "union",
            "refs": ["com.atproto.label.defs#selfLabels"]
          },
          "tags": {
            "type": "array",
            "maxLength": 8,
            "items": { "type": "string", "maxLength": 640, "maxGraphemes": 64 },
            "description": "Additional non-inline tags describing this post."
          },
          "createdAt": { "type": "string", "format": "datetime" }
        }
      }
    },
    "replyRef": {
      "type": "object",
      "required": ["root", "parent"],
      "properties": {
        "root": { "type": "ref", "ref": "com.atproto.repo.strongRef" },
        "parent": { "type": "ref", "ref": "com.atproto.repo.strongRef" }
      }
    },
