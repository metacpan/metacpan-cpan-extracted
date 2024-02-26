package At::Lexicon::app::bsky::actor 0.18 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use Carp;
    use Path::Tiny;

    class At::Lexicon::app::bsky::embed::recordWithMedia {
        field $type : param($type) //= ();    # record field
        field $record : param;                # ::embed::record, required
        field $media : param;                 # union, required
        ADJUST {
            $record = At::Lexicon::app::bsky::embed::record->new(%$record) unless builtin::blessed $record;
            $media  = At::_topkg( $media->{'$type'} )->new(%$media) if !builtin::blessed $media && defined $media->{'$type'};
        }

        # perlclass does not have :reader yet
        method record {$record}
        method media  {$media}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), record => $record->_raw, media => $media->_raw };
        }
    }

    class At::Lexicon::app::bsky::embed::recordWithMedia::view {
        field $type : param($type);    # record field
        field $record : param;         # app.bsky.embed.record#view, required
        field $media : param;          # union, required
        ADJUST {
            $record = At::Lexicon::app::bsky::embed::record::view->new(%$record) unless builtin::blessed $record;
            $media  = At::_topkg( $media->{'$type'} )->new(%$media) if !builtin::blessed $media && defined $media->{'$type'};
        }

        # perlclass does not have :reader yet
        method record {$record}
        method media  {$media}

        method _raw() {
            +{ '$type' => $type, record => $record->_raw, media => $media->_raw };
        }
    }

    class At::Lexicon::app::bsky::embed::images {
        field $type : param($type);    # record field
        field $images : param;         # array, required, max 4
        ADJUST {
            Carp::confess 'too many images; 4 max' if scalar @$images > 4;
            $images = [ map { At::Lexicon::app::bsky::embed::images::image->new(%$_) unless builtin::blessed $_ } @$images ];
        }

        # perlclass does not have :reader yet
        method images {$images}

        method _raw() {
            +{ '$type' => $type, images => [ map { $_->_raw } @$images ] };
        }
    }

    class At::Lexicon::app::bsky::embed::images::image {
        field $type : param($type) //= ();    # record field
        field $image : param;                 # blob, required, 1000000 bytes max
        field $alt : param;                   # string, required
        field $aspectRatio : param //= ();    # ::aspectRatio
        ADJUST {
            $image = path($image)->slurp_utf8                if -f $image;
            Carp::confess 'image is more than 1000000 bytes' if length $image > 1000000;
            $aspectRatio = At::Lexicon::app::bsky::embed::images::aspectRatio->new(%$aspectRatio)
                if defined $aspectRatio && !builtin::blessed $aspectRatio;
        }

        # perlclass does not have :reader yet
        method image       {$image}
        method alt         {$alt}
        method aspectRatio {$aspectRatio}

        method _raw() {
            +{  defined $type ? ( '$type' => $type ) : (),
                image => $image,
                alt   => $alt,
                defined $aspectRatio ? ( aspectRatio => $aspectRatio->_raw ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::embed::images::aspectRatio {
        field $width : param;     # int, required
        field $height : param;    # int, required

        # perlclass does not have :reader yet
        method width  {$width}
        method height {$height}

        method _raw() {
            +{ width => $width, height => $height };
        }
    }

    class At::Lexicon::app::bsky::embed::images::view {
        field $type : param($type);    # record field
        field $images : param;         # array, required, max 4
        ADJUST {
            Carp::confess 'too many images; 4 max' if scalar @$images > 4;
            $images = [ map { At::Lexicon::app::bsky::embed::images::viewImage->new(%$_) unless builtin::blessed $_ } @$images ];
        }

        # perlclass does not have :reader yet
        method images {$images}

        method _raw() {
            +{ '$type' => $type, images => [ map { $_->_raw } @$images ] };
        }
    }

    class At::Lexicon::app::bsky::embed::images::viewImage {
        field $thumb : param;                 # string, required
        field $fullsize : param;              # string, required
        field $alt : param;                   # string, required
        field $aspectRatio : param //= ();    # ::aspectRatio
        ADJUST {
            $aspectRatio = At::Lexicon::app::bsky::embed::images::aspectRatio->new(%$aspectRatio)
                if defined $aspectRatio &&
                !builtin::blessed $aspectRatio
        }

        # perlclass does not have :reader yet
        method thumb       {$thumb}
        method fullsize    {$fullsize}
        method alt         {$alt}
        method aspectRatio {$aspectRatio}

        method _raw() {
            +{ thumb => $thumb, fullsize => $fullsize, alt => $alt, defined $aspectRatio ? ( aspectRatio => $aspectRatio->_raw ) : () };
        }
    }

    class At::Lexicon::app::bsky::embed::external {
        field $type : param($type);    # record field
        field $external : param;       # ::external
        ADJUST {
            $external = At::Lexicon::app::bsky::embed::external::external->new(%$external) unless builtin::blessed $external;
        }

        # perlclass does not have :reader yet
        method external {$external}

        method _raw() {
            +{ '$type' => $type, external => $external->_raw };
        }
    }

    class At::Lexicon::app::bsky::embed::external::external {
        field $type : param($type) //= ();    # record field
        field $uri : param;                   # URI, required
        field $title : param;                 # string, required
        field $description : param;           # string, required
        field $thumb : param //= ();          # blob, 1000000 bytes max

        # being returned by bsky for https://justingarrison.com/blog/2023-12-30-amazons-silent-sacking/ but not in lexicon as of Dec. 29th, 2023
        field $url : param //= ();            # URI
        ADJUST {
            $uri   = URI->new($uri) unless builtin::blessed $uri;
            $thumb = path($thumb)->slurp_utf8 if defined $thumb && -f $thumb;
            Carp::confess 'thumb is more than 1000000 bytes' if defined $thumb && length $thumb > 1000000;
        }

        # perlclass does not have :reader yet
        method uri         {$uri}
        method title       {$title}
        method description {$description}
        method thumb       {$thumb}

        method _raw() {
            +{  defined $type ? ( '$type' => $type ) : (),
                uri         => $uri->as_string,
                title       => $title,
                description => $description,
                defined $thumb ? ( thumb => $thumb ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::embed::external::view {
        field $type : param($type);    # record field
        field $external : param;       # array, required, max 4
        ADJUST {
            $external = At::Lexicon::app::bsky::embed::external::viewExternal->new(%$external) unless builtin::blessed $external;
        }

        # perlclass does not have :reader yet
        method external {$external}

        method _raw() {
            +{ '$type' => $type, external => $external->_raw };
        }
    }

    class At::Lexicon::app::bsky::embed::external::viewExternal {
        field $uri : param;             # URI, required
        field $title : param;           # string, required
        field $description : param;     # string, required
        field $thumb : param //= ();    # string
        ADJUST {
            $uri = URI->new($uri) unless builtin::blessed $uri;
        }

        # perlclass does not have :reader yet
        method uri         {$uri}
        method title       {$title}
        method description {$description}
        method thumb       {$thumb}

        method _raw() {
            +{ uri => $uri->as_string, title => $title, description => $description, defined $thumb ? ( thumb => $thumb ) : () };
        }
    }

    class At::Lexicon::app::bsky::embed::record {
        field $type : param($type);    # record field
        field $record : param;         # com.atproto.repo.strongRef, required
        ADJUST {
            $record = At::Lexicon::com::atproto::repo::strongRef->new(%$record) unless builtin::blessed $record;
        }

        # perlclass does not have :reader yet
        method record {$record}

        method _raw() {
            +{ '$type' => $type, record => $record->_raw };
        }
    }

    class At::Lexicon::app::bsky::embed::record::view {
        field $type : param($type) //= ();    # record field
        field $record : param;                # union, required
        ADJUST {
            $record = At::_topkg( $record->{'$type'} )->new(%$record) if !builtin::blessed $record && defined $record->{'$type'};
        }

        # perlclass does not have :reader yet
        method record {$record}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), record => $record->_raw };
        }
    }

    class At::Lexicon::app::bsky::embed::record::viewRecord {
        field $type : param($type);      # record field
        field $uri : param;              # URI, required
        field $cid : param;              # CID, required
        field $author : param;           # app.bsky.actor.defs#profileViewBasic, required
        field $value : param;            # unknown, required
        field $labels : param //= ();    # array of com.atproto.label.defs#label
        field $embeds : param //= ();    # array of unions...
        field $indexedAt : param;        # datetime, required
        ADJUST {
            $uri    = URI->new($uri)                                                 unless builtin::blessed $uri;
            $author = At::Lexicon::app::bsky::actor::profileViewBasic->new(%$author) unless builtin::blessed $author;
            $value  = At::_topkg( $value->{'$type'} )->new(%$value) if !builtin::blessed $value && defined $value->{'$type'};
            $labels = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) unless builtin::blessed $_ } @$labels ] if defined $labels;
            $embeds = [ map { $_ = At::_topkg( $_->{'$type'} )->new(%$_) if !builtin::blessed $_ && defined $_->{'$type'} } @$embeds ]
                if defined $embeds;
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt ) unless builtin::blessed $indexedAt;
        }

        # perlclass does not have :reader yet
        method uri       {$uri}
        method cid       {$cid}
        method author    {$author}
        method value     {$value}
        method labels    {$labels}
        method embeds    {$embeds}
        method indexedAt {$indexedAt}

        method _raw() {
            +{  '$type' => $type,
                uri     => $uri,
                cid     => $cid,
                author  => $author->_raw,
                value   => builtin::blessed $value ? $value->_raw : $value,
                defined $labels ? ( labels => [ map { $_ = $_->_raw if builtin::blessed $_; } @$labels ] ) : (),
                defined $embeds ? ( embeds => [ map { $_ = $_->_raw if builtin::blessed $_; } @$embeds ] ) : (), indexedAt => $indexedAt->_raw
            };
        }
    }

    class At::Lexicon::app::bsky::embed::record::viewNotFound {
        field $type : param($type);    # record field
        field $uri : param;            # URI, required
        field $notFound : param;       # bool, required
        ADJUST {
            $uri      = URI->new($uri) unless builtin::blessed $uri;
            $notFound = !!$notFound if builtin::blessed $notFound;
        }

        # perlclass does not have :reader yet
        method uri      {$uri}
        method notFound {$notFound}

        method _raw() {
            +{ '$type' => $type, uri => $uri->as_string, notFound => \$notFound };
        }
    }

    class At::Lexicon::app::bsky::embed::record::viewBlocked {
        field $type : param($type);    # record field
        field $uri : param;            # URI, required
        field $blocked : param;        # bool, required
        field $author : param;         # app.bsky.feed.defs#blockedAuthor, required
        ADJUST {
            $uri     = URI->new($uri) unless builtin::blessed $uri;
            $blocked = !!$blocked if builtin::blessed $blocked;
            $author  = At::Lexicon::app::bsky::feed::blockedAuthor->new(%$author) unless builtin::blessed $author;
        }

        # perlclass does not have :reader yet
        method uri     {$uri}
        method blocked {$blocked}
        method author  {$author}

        method _raw() {
            +{ '$type' => $type, uri => $uri->as_string, blocked => \$blocked, author => $author->_raw };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::app::bsky::embed - A representation of embedded content

=head1 See Also

https://atproto.com/

https://en.wikipedia.org/wiki/Bluesky_(social_network)

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
