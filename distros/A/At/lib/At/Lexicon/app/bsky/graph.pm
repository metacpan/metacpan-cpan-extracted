package At::Lexicon::app::bsky::graph 0.18 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use Carp;
    use Path::Tiny;
    use URI;
    our @CARP_NOT;
    #
    class At::Lexicon::app::bsky::graph::listViewBasic {
        field $uri : param;               # at-uri, required
        field $purpose : param;           # enum(#listPurpose), required
        field $indexedAt : param = ();    # datetime
        field $avatar : param    = ();    # string
        field $viewer : param    = ();    # listViewerState
        field $cid : param;               # cid, required
        field $name : param;              # string, required, max len: 64, min len: 1
        ADJUST {
            $uri = URI->new($uri) unless builtin::blessed $uri;

            # modlist: A list of actors to apply an aggregate moderation action (mute/block) on.
            # curatelist: A list of actors used for curation purposes such as list feeds or interaction gating.
            Carp::croak 'unknown purpose: ' . $purpose
                unless $purpose eq 'app.bsky.graph.defs#modlist' || $purpose eq 'app.bsky.graph.defs#curatelist';
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt )       if defined $indexedAt && !builtin::blessed $indexedAt;
            $viewer    = At::Lexicon::app::bsky::graph::listViewerState->new(%$viewer) if defined $viewer    && !builtin::blessed $viewer;
            Carp::cluck q[name is too long; expected 64 characters or fewer] if length $name > 64;
            Carp::cluck q[name is too short; expected 1 characters or more]  if length $name < 1;
        }

        # perlclass does not have :reader yet
        method uri       {$uri}
        method purpose   {$purpose}
        method indexedAt {$indexedAt}
        method avatar    {$avatar}
        method viewer    {$viewer}
        method cid       {$cid}
        method name      {$name}

        method _raw() {
            +{  uri       => $uri->as_string,
                purpose   => $purpose->raw,
                indexedAt => $indexedAt->as_string,
                avatar    => $avatar,
                viewer    => $viewer->raw,
                cid       => $cid->as_string,
                name      => $name,
            };
        }
    }

    class At::Lexicon::app::bsky::graph::listView {
        field $type : param($type) //= ();        # record field
        field $viewer : param = ();               # #listViewerState
        field $uri : param;                       # at-uri, required
        field $indexedAt : param;                 # datetime, required
        field $avatar : param      = ();          # string
        field $description : param = ();          # string, max graphemes: 300, max length: 3000
        field $name : param;                      # string, required, max length: 64, min length: 1
        field $cid : param;                       # cid, required
        field $creator : param;                   # app.bsky.actor.defs#profileView, required
        field $descriptionFacets : param = ();    # array of app.bsky.richtext.facet
        field $purpose : param;                   # #listPurpose, required
        ADJUST {
            use bytes;
            $viewer    = At::Lexicon::app::bsky::graph::listViewerState->new(%$viewer) if defined $viewer && !builtin::blessed $viewer;
            $uri       = URI->new($uri)                                          unless builtin::blessed $uri;
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt ) unless builtin::blessed $indexedAt;
            Carp::cluck q[description is too long; expected 300 bytes or fewer]       if defined $description && bytes::length $description > 300;
            Carp::cluck q[description is too long; expected 3000 characters or fewer] if defined $description && length $description > 3000;
            Carp::cluck q[name is too long; expected 64 characters or fewer]          if length $name > 64;
            Carp::cluck q[name is too short; expected 1 characters or more]           if length $name < 1;
            $creator           = At::Lexicon::app::bsky::actor::profileView->new(%$creator) unless builtin::blessed $creator;
            $descriptionFacets = [ map { At::Lexicon::app::bsky::richtext::facet->new(%$_) } @$descriptionFacets ] if defined $descriptionFacets;
            Carp::croak 'unknown purpose: ' . $purpose
                unless $purpose eq 'app.bsky.graph.defs#modlist' || $purpose eq 'app.bsky.graph.defs#curatelist';
        }

        # perlclass does not have :reader yet
        method viewer            {$viewer}
        method uri               {$uri}
        method indexedAt         {$indexedAt}
        method avatar            {$avatar}
        method description       {$description}
        method name              {$name}
        method cid               {$cid}
        method creator           {$creator}
        method descriptionFacets {$descriptionFacets}
        method purpose           {$purpose}

        method _raw() {
            +{  defined $type ? ( '$type' => $type ) : (),
                viewer            => defined $viewer ? $viewer->_raw : undef,
                uri               => $uri->as_string,
                indexedAt         => $indexedAt->_raw,
                avatar            => defined $avatar      ? $avatar      : undef,
                description       => defined $description ? $description : undef,
                name              => $name,
                cid               => $cid,
                creator           => $creator->_raw,
                descriptionFacets => defined $descriptionFacets ? [ map { $_->_raw } @$descriptionFacets ] : undef,
                purpose           => $purpose
            };
        }
    }

    class At::Lexicon::app::bsky::graph::listItemView {
        field $subject : param;    # app.bsky.actor.defs#profileView, required
        field $uri : param;        # uri, required
        ADJUST {
            $subject = At::Lexicon::app::bsky::actor::profileView->new(%$subject) unless builtin::blessed $subject;
            $uri     = URI->new($uri)                                             unless builtin::blessed $uri;
        }

        # perlclass does not have :reader yet
        method subject {$subject}
        method uri     {$uri}

        method _raw() {
            +{ subject => $subject->_raw, uri => $uri->as_string };
        }
    }

    class At::Lexicon::app::bsky::graph::listViewerState {
        field $blocked : param = ();    # at-uri
        field $muted : param   = ();    # bool
        ADJUST {
            $blocked = URI->new($blocked) if defined $blocked && !builtin::blessed $blocked;
        }

        # perlclass does not have :reader yet
        method blocked {$blocked}
        method muted   {$muted}

        method _raw() {
            +{ blocked => defined $blocked ? $blocked->as_string : undef, muted => \!!$muted };
        }
    }

    # A declaration of a block.
    class At::Lexicon::app::bsky::graph::block {
        field $subject : param;      # did, required
        field $createdAt : param;    # datetime, required
        ADJUST {
            $subject   = At::Protocol::DID->new( uri => $subject )               unless builtin::blessed $subject;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method subject   {$subject}
        method createdAt {$createdAt}

        method _raw() {
            +{ '$type' => 'app.bsky.graph.block', subject => $subject->_raw, createdAt => $createdAt->_raw };
        }
    }

    # A declaration of a social follow.
    class At::Lexicon::app::bsky::graph::follow {    # key: tid
        field $createdAt : param;                    # datetime, required
        field $subject : param;                      # did, required
        ADJUST {
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $subject   = At::Protocol::DID->new( uri => $subject )               unless builtin::blessed $subject;
        }

        # perlclass does not have :reader yet
        method createdAt {$createdAt}
        method subject   {$subject}

        method _raw() {
            +{ '$type' => 'app.bsky.graph.follow', createdAt => $createdAt->_raw, subject => $subject->_raw };
        }
    }

    # A declaration of a list of actors.
    class At::Lexicon::app::bsky::graph::list {
        field $createdAt : param;                 # datetime, required
        field $descriptionFacets : param = ();    # array of app.bsky.richtext.facet
        field $labels : param            = ();    # union of selfLabels
        field $purpose : param;                   # #listPurpose, required
        field $name : param;                      # string, required, max length: 64, min length: 1
        field $description : param = ();          # string, max length: 3000, max graphemes: 300
        field $avatar : param      = ();          # blob, max size: 1000000, png or jpeg
        ADJUST {
            $avatar = path($avatar)->slurp_utf8 if defined $avatar && -f $avatar;
            Carp::confess 'avatar is more than 1000000 bytes' if defined $avatar && length $avatar > 1000000;
            $createdAt         = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $descriptionFacets = [ map { At::Lexicon::app::bsky::richtext::facet->new(%$_) } @$descriptionFacets ] if defined $descriptionFacets;
            $labels = At::Lexicon::com::atproto::label::selfLabel->new( values => $labels ) if defined $labels && !builtin::blessed $labels;
            Carp::croak 'unknown purpose: ' . $purpose
                unless $purpose eq 'app.bsky.graph.defs#modlist' || $purpose eq 'app.bsky.graph.defs#curatelist';
            Carp::cluck q[description is too long; expected 300 bytes or fewer]       if defined $description && bytes::length $description > 300;
            Carp::cluck q[description is too long; expected 3000 characters or fewer] if defined $description && length $description > 3000;
            Carp::cluck q[name is too long; expected 64 characters or fewer]          if length $name > 64;
            Carp::cluck q[name is too short; expected 1 characters or more]           if length $name < 1;
        }

        # perlclass does not have :reader yet
        method createdAt         {$createdAt}
        method descriptionFacets {$descriptionFacets}
        method labels            {$labels}
        method purpose           {$purpose}
        method name              {$name}
        method description       {$description}
        method avatar            {$avatar}

        method _raw() {
            +{  createdAt         => $createdAt->_raw,
                descriptionFacets => defined $descriptionFacets ? [ map { $_->_raw } @$descriptionFacets ] : undef,
                labels            => $labels->_raw,
                purpose           => $purpose->_raw,
                name              => $name,
                description       => defined $description ? $description : undef,
                avatar            => defined $avatar      ? $avatar      : undef
            };
        }
    }

    # An item under a declared list of actors.
    class At::Lexicon::app::bsky::graph::listitem {
        field $createdAt : param;    # datetime, required
        field $subject : param;      # did, required
        field $list : param;         # at-uri, required
        ADJUST {
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $subject   = At::Protocol::DID->new( uri => $subject )               unless builtin::blessed $subject;
            $list      = URI->new($list)                                         unless builtin::blessed $list;
        }

        # perlclass does not have :reader yet
        method createdAt {$createdAt}
        method subject   {$subject}
        method list      {$list}

        method _raw() {
            +{ createdAt => $createdAt->_raw, subject => $subject->_raw, list => $list->as_string };
        }
    }

    # A block of an entire list of actors.
    class At::Lexicon::app::bsky::graph::listblock {
        field $subject : param;      # did, required
        field $createdAt : param;    # datetime, required
        ADJUST {
            $subject   = At::Protocol::DID->new( uri => $subject )               unless builtin::blessed $subject;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method subject   {$subject}
        method createdAt {$createdAt}

        method _raw() {
            +{ subject => $subject->_raw, createdAt => $createdAt->_raw };
        }
    }

    # Indicates that a handle or DID could not be resolved
    class At::Lexicon::app::bsky::graph::notFoundActor {
        field $actor : param;       # at, required
        field $notFound : param;    # bool, required
        ADJUST {
            use URI;
            $actor    = URI->new( uri => $actor ) unless builtin::blessed $actor;
            $notFound = !!$notFound if builtin::blessed $notFound;
        }

        # perlclass does not have :reader yet
        method actor    {$actor}
        method notFound {$notFound}

        method _raw() {
            +{ actor => $actor->as_string, notFound => \!!$notFound };
        }
    }

    # Lists the bi-directional graph relationships between one actor (not indicated in the object),
    # and the target actors (the DID included in the object)
    class At::Lexicon::app::bsky::graph::relationship {
        field $did : param;                  # DID, required
        field $following : param  //= ();    # at-uri
        field $followedBy : param //= ();    # at-uri
        ADJUST {
            use URI;
            $did        = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
            $following  = URI->new( uri => $following )  if defined $following  && !builtin::blessed $following;
            $followedBy = URI->new( uri => $followedBy ) if defined $followedBy && !builtin::blessed $followedBy;
        }

        # perlclass does not have :reader yet
        method did        {$did}
        method following  {$following}
        method followedBy {$followedBy}

        method _raw() {
            +{  did => $did->_raw,
                defined $following ? ( following => $following->_raw ) : (), defined $followedBy ? ( followedBy => $followedBy->_raw ) : ()
            };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::app::bsky::graph - A reference to an social graph

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
