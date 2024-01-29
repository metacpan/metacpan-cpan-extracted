package At::Lexicon::app::bsky::richtext 0.15 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use Carp;
    #
    class At::Lexicon::app::bsky::richtext::facet {
        field $type : param($type) //= ();    # record field
        field $features : param;              # array of union, required
        field $index : param;                 # ::byteSlice, required
        ADJUST {
            $index = At::Lexicon::app::bsky::richtext::facet::byteSlice->new(%$index) if defined $index && !builtin::blessed $index;
            $features
                = [ map { $_ = At::_topkg( $_->{'$type'} )->new(%$_) if defined $_ && !builtin::blessed $_ && defined $_->{'$type'}; } @$features ];
        }

        # perlclass does not have :reader yet
        method features {$features}
        method index    {$index}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), features => [ map { $_->_raw } @$features ], index => $index->_raw };
        }
    }

    # A facet feature for actor mentions.
    class At::Lexicon::app::bsky::richtext::facet::mention {
        field $type : param($type);    # record field
        field $did : param;            # did, required
        ADJUST {
            $did = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
        }

        # perlclass does not have :reader yet
        method did {$did}

        method _raw() {
            +{ '$type' => $type, did => $did->_raw };
        }
    }

    # A facet feature for links.
    class At::Lexicon::app::bsky::richtext::facet::link {
        field $type : param($type);    # record field
        field $uri : param;            # uri, required
        ADJUST {
            $uri = URI->new($uri) unless builtin::blessed $uri;
        }

        # perlclass does not have :reader yet
        method uri {$uri}

        method _raw() {
            +{ '$type' => $type, uri => $uri->as_string };
        }
    }

    # A hashtag.
    class At::Lexicon::app::bsky::richtext::facet::tag {
        field $type : param($type);    # record field
        field $tag : param;            # string, required, max 640 graphemes, max 64 characters
        ADJUST {
            Carp::confess 'tag is too long' if length $tag > 640 || At::_glength($tag) > 64;
        }

        # perlclass does not have :reader yet
        method tag {$tag}

        method _raw() {
            +{ '$type' => $type, tag => $tag };
        }
    }

    # A text segment. Start is inclusive, end is exclusive. Indices are for utf8-encoded strings.
    class At::Lexicon::app::bsky::richtext::facet::byteSlice {
        field $type : param($type) //= ();    # record field
        field $byteEnd : param;               # int, required, minimum: 0
        field $byteStart : param;             # int, required, minimum: 0
        ADJUST {
            Carp::confess 'byteEnd must be greater than 0'   if $byteEnd < 0;
            Carp::confess 'byteStart must be greater than 0' if $byteStart < 0;
        }

        # perlclass does not have :reader yet
        method byteEnd   {$byteEnd}
        method byteStart {$byteStart}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), byteEnd => $byteEnd, byteStart => $byteStart };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::app::bsky::richtext - Richtext and Facet classes

=head1 See Also

https://atproto.com/

https://en.wikipedia.org/wiki/Bluesky_(social_network)

https://en.m.wikipedia.org/wiki/Social_graph

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
