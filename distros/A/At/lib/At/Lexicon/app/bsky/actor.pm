package At::Lexicon::app::bsky::actor 0.15 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use Carp;
    use URI;
    use Path::Tiny;
    #
    class At::Lexicon::app::bsky::actor::profileViewBasic {
        field $did : param;                   # string, did, required
        field $handle : param;                # string, handle, required
        field $displayName : param //= ();    # string
        field $avatar : param      //= ();    # string
        field $viewer : param      //= ();    # ::viewerState
        field $labels : param      //= ();    # array of com.atproto.label.defs#label
        ADJUST {
            $did    = At::Protocol::DID->new( uri => $did )      unless builtin::blessed $did;
            $handle = At::Protocol::Handle->new( id => $handle ) unless builtin::blessed $handle;
            Carp::cluck q[displayName is too long] if defined $displayName && ( length $displayName > 640 || At::_glength($displayName) > 64 );
            $viewer = At::Lexicon::app::bsky::actor::viewerState->new(%$viewer) if defined $viewer && !builtin::blessed $viewer;
            $labels = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) unless builtin::blessed $_ } @$labels ] if defined $labels;
        }

        # perlclass does not have :reader yet
        method did         {$did}
        method handle      {$handle}
        method displayName {$displayName}
        method avatar      {$avatar}
        method viewer      {$viewer}
        method labels      {$labels}

        method _raw() {
            +{  did    => $did->_raw,
                handle => $handle->_raw,
                defined $displayName ? ( displayName => $displayName )  : (), defined $avatar ? ( avatar => $avatar )                       : (),
                defined $viewer      ? ( viewer      => $viewer->_raw ) : (), defined $labels ? ( labels => [ map { $_->_raw } @$labels ] ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::actor::profileView {
        field $did : param;                   # string, did, required
        field $handle : param;                # string, handle, required
        field $displayName : param //= ();    # string, 64 grapheme, 640 len
        field $description : param //= ();    # string, 256 grapheme, 2560 len
        field $avatar : param      //= ();    # string
        field $indexedAt : param   //= ();    # datetime
        field $viewer : param      //= ();    # viewState
        field $labels : param      //= ();    # array of labels
        ADJUST {
            $did    = At::Protocol::DID->new( uri => $did ) if defined $did && !builtin::blessed $did;
            $handle = At::Protocol::Handle->new( id => $handle ) unless builtin::blessed $handle;
            Carp::cluck q[displayName is too long] if defined $displayName && length $displayName > 64;
            Carp::cluck q[description is too long] if defined $description && ( length $description > 256 || At::_glength($description) > 2560 );
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt ) if defined $indexedAt && !builtin::blessed $indexedAt;
            $labels    = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) unless builtin::blessed $_ } @$labels ] if defined $labels;
            $viewer    = At::Lexicon::app::bsky::actor::viewerState->new(%$viewer) if defined $viewer && !builtin::blessed $viewer;
        }

        # perlclass does not have :reader yet
        method did         {$did}
        method handle      {$handle}
        method displayName {$displayName}
        method description {$description}
        method avatar      {$avatar}
        method indexedAt   {$indexedAt}
        method viewer      {$viewer}
        method labels      {$labels}

        method _raw() {
            +{  did    => $did->_raw,
                handle => $handle->_raw,
                defined $displayName ? ( displayName => $displayName )  : (), defined $description ? ( description => $description )             : (),
                defined $avatar      ? ( avatar      => $avatar )       : (), defined $indexedAt   ? ( indexedAt   => $indexedAt->_raw )         : (),
                defined $viewer      ? ( viewer      => $viewer->_raw ) : (), defined $labels      ? ( labels => [ map { $_->_raw } @$labels ] ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::actor::profileViewDetailed {
        field $did : param;                      # string, did, required
        field $handle : param;                   # handle, required
        field $displayName : param    //= ();    # string, len 640 max, grapheme 64 max
        field $description : param    //= ();    # string, len 2560 max, grapheme 256 max
        field $avatar : param         //= ();    # string
        field $banner : param         //= ();    # string
        field $followersCount : param //= ();    # int
        field $followsCount : param   //= ();    # int
        field $postsCount : param     //= ();    # int
        field $indexedAt : param      //= ();    # datetime
        field $viewer : param         //= ();    # viewerState
        field $labels : param         //= ();    # array of lables
        ADJUST {
            $did    = At::Protocol::DID->new( uri => $did )      unless builtin::blessed $did;
            $handle = At::Protocol::Handle->new( id => $handle ) unless builtin::blessed $handle;
            Carp::cluck q[displayName is too long] if defined $displayName && ( length $displayName > 64  || At::_glength($displayName) > 640 );
            Carp::cluck q[description is too long] if defined $description && ( length $description > 256 || At::_glength($description) > 2560 );
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt )   if defined $indexedAt && !builtin::blessed $indexedAt;
            $viewer    = At::Lexicon::app::bsky::actor::viewerState->new(%$viewer) if defined $viewer    && !builtin::blessed $viewer;
            $labels    = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) unless builtin::blessed $_ } @$labels ] if defined $labels;
        }

        # perlclass does not have :reader yet
        method did            {$did}
        method handle         {$handle}
        method displayName    {$displayName}
        method description    {$description}
        method avatar         {$avatar}
        method banner         {$banner}
        method followersCount {$followersCount}
        method followsCount   {$followsCount}
        method postsCount     {$postsCount}
        method indexedAt      {$indexedAt}
        method viewer         {$viewer}
        method labels         {$labels}

        method _raw() {
            +{  did    => $did->_raw,
                handle => $handle->_raw,
                defined $displayName    ? ( displayName    => $displayName )    : (), defined $description  ? ( description  => $description )  : (),
                defined $avatar         ? ( avatar         => $avatar )         : (), defined $banner       ? ( banner       => $banner )       : (),
                defined $followersCount ? ( followersCount => $followersCount ) : (), defined $followsCount ? ( followsCount => $followsCount ) : (),
                defined $postsCount     ? ( postsCount     => $postsCount )     : (), defined $indexedAt    ? ( indexedAt => $indexedAt->_raw ) : (),
                defined $viewer ? ( viewer => +{ %{ $viewer->_raw } } ) : (), defined $labels ? ( labels => [ map { $_->_raw } @$labels ] )     : ()
            };
        }
    }

    class At::Lexicon::app::bsky::actor::viewerState {
        field $muted : param          //= ();    # bool
        field $mutedByList : param    //= ();    # app.bsky.graph.defs#listViewBasic
        field $blockedBy : param      //= ();    # bool
        field $blocking : param       //= ();    # at-uri
        field $blockingByList : param //= ();    # app.bsky.graph.defs#listViewBasic
        field $following : param      //= ();    # at-uri
        field $followedBy : param     //= ();    # at-uri
        ADJUST {
            $muted       = !!$muted                                                         if defined $muted       && builtin::blessed $muted;
            $mutedByList = At::Lexicon::app::bsky::graph::listViewBasic->new(%$mutedByList) if defined $mutedByList && !builtin::blessed $mutedByList;
            $blockedBy   = !!$blockedBy                                                     if defined $blockedBy   && builtin::blessed $blockedBy;
            $blocking    = URI->new($blocking)                                              if defined $blocking    && !builtin::blessed $blocking;
            $blockingByList = At::Lexicon::app::bsky::graph::listViewBasic->new(%$blockingByList)
                if defined $blockingByList && !builtin::blessed $blockingByList;
            $following  = URI->new($following)  if defined $following  && !builtin::blessed $following;
            $followedBy = URI->new($followedBy) if defined $followedBy && !builtin::blessed $followedBy;
        }

        # perlclass does not have :reader yet
        method muted          {$muted}
        method mutedByList    {$mutedByList}
        method blockedBy      {$blockedBy}
        method blocking       {$blocking}
        method blockingByList {$blockingByList}
        method following      {$following}
        method followedBy     {$followedBy}

        method _raw() {
            +{  defined $muted          ? ( muted          => \$muted )                : (),
                defined $mutedByList    ? ( mutedByList    => $mutedByList->_raw )     : (),
                defined $blockedBy      ? ( blockedBy      => \$blockedBy )            : (),
                defined $blocking       ? ( blocking       => $blocking->as_string )   : (),
                defined $blockingByList ? ( blockingByList => $blockingByList->_raw )  : (),
                defined $following      ? ( following      => $following->as_string )  : (),
                defined $followedBy     ? ( followedBy     => $followedBy->as_string ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::actor::preferences {
        field $items : param //= ();    # array of unions
        ADJUST {
            $items = [ map { At::_topkg( $_->{'$type'} )->new(%$_) if !builtin::blessed $_ && defined $_->{'$type'}; } @$items ] if defined $items;
        }

        # perlclass does not have :reader yet
        method items {$items}

        method _raw() {
            +[ map { $_->_raw } @$items ];
        }
    }

    class At::Lexicon::app::bsky::actor::adultContentPref {
        field $type : param($type);    # record field
        field $enabled : param;        # bool, required, false by default
        ADJUST {
            $enabled = !!$enabled if builtin::blessed $enabled;
        }

        # perlclass does not have :reader yet
        method enabled {$enabled}

        method _raw() {
            +{ '$type' => $type, enabled => \$enabled };
        }
    }

    class At::Lexicon::app::bsky::actor::contentLabelPref {
        field $type : param($type);    # record field
        field $label : param;          # string, required
        field $visibility : param;     # string, union
        ADJUST {
            Carp::carp q[unknown value for visibility] unless grep { $visibility eq $_ } qw[show warn hide];
        }

        # perlclass does not have :reader yet
        method label      {$label}
        method visibility {$visibility}

        method _raw() {
            +{ '$type' => $type, label => $label, visibility => $visibility };
        }
    }

    class At::Lexicon::app::bsky::actor::savedFeedsPref {
        field $type : param($type);    # record field
        field $pinned : param;         # array, at-uri, required
        field $saved : param;          # array, at-uri, required
        ADJUST {
            $pinned = [ map { $_ = URI->new($_) unless builtin::blessed $_ } @$pinned ];
            $saved  = [ map { $_ = URI->new($_) unless builtin::blessed $_ } @$saved ];
        }

        # perlclass does not have :reader yet
        method pinned {$pinned}
        method saved  {$saved}

        method _raw() {
            +{ '$type' => $type, pinned => [ map { $_->as_string } @$pinned ], saved => [ map { $_->as_string } @$saved ] };
        }
    }

    class At::Lexicon::app::bsky::actor::personalDetailsPref {
        field $type : param($type);         # record field
        field $birthDate : param //= ();    # datetime
        ADJUST {
            $birthDate = At::Protocol::Timestamp->new( timestamp => $birthDate ) unless builtin::blessed $birthDate;
        }

        # perlclass does not have :reader yet
        method birthDate {$birthDate}

        method _raw() {
            +{ '$type' => $type, birthDate => $birthDate->_raw };
        }
    }

    class At::Lexicon::app::bsky::actor::feedViewPref {
        field $type : param($type);                       # record field
        field $feed : param;                              # string, required
        field $hideReplies : param             //= ();    # bool
        field $hideRepliesByUnfollowed : param //= ();    # bool
        field $hideRepliesByLikeCount : param  //= ();    # int
        field $hideReposts : param             //= ();    # bool
        field $hideQuotePosts : param          //= ();    # bool
        ADJUST {
            $hideReplies             = !!$hideReplies             if defined $hideReplies             && builtin::blessed $hideReplies;
            $hideRepliesByUnfollowed = !!$hideRepliesByUnfollowed if defined $hideRepliesByUnfollowed && builtin::blessed $hideRepliesByUnfollowed;
            $hideReposts             = !!$hideReposts             if defined $hideReposts             && builtin::blessed $hideReposts;
            $hideQuotePosts          = !!$hideQuotePosts          if defined $hideQuotePosts          && builtin::blessed $hideQuotePosts;
        }

        # perlclass does not have :reader yet
        method feed                    {$feed}
        method hideReplies             {$hideReplies}
        method hideRepliesByUnfollowed {$hideRepliesByUnfollowed}
        method hideRepliesByLikeCount  {$hideRepliesByLikeCount}
        method hideReposts             {$hideReposts}
        method hideQuotePosts          {$hideQuotePosts}

        method _raw() {
            +{  '$type' => $type,
                feed    => $feed,
                defined $hideReplies             ? ( hideReplies             => \$hideReplies )             : (),
                defined $hideRepliesByUnfollowed ? ( hideRepliesByUnfollowed => \$hideRepliesByUnfollowed ) : (),
                defined $hideRepliesByLikeCount  ? ( hideRepliesByLikeCount  => $hideRepliesByLikeCount )   : (),
                defined $hideReposts ? ( hideReposts => \$hideReposts ) : (), defined $hideQuotePosts ? ( hideQuotePosts => \$hideQuotePosts ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::actor::threadViewPref {
        field $type : param($type);                       # record field
        field $sort : param                    //= ();    # string, enum
        field $prioritizeFollowedUsers : param //= ();    # bool
        ADJUST {
            Carp::cluck q[unknown value for sort] if defined $sort && !grep { $sort eq $_ } qw[oldest newest most-likes random];
            $prioritizeFollowedUsers = !!$prioritizeFollowedUsers if defined $prioritizeFollowedUsers && builtin::blessed $prioritizeFollowedUsers;
        }

        # perlclass does not have :reader yet
        method sort                    {$sort}
        method prioritizeFollowedUsers {$prioritizeFollowedUsers}

        method _raw() {
            +{  '$type' => $type,
                defined $sort                    ? ( sort                    => $sort )                     : (),
                defined $prioritizeFollowedUsers ? ( prioritizeFollowedUsers => \$prioritizeFollowedUsers ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::actor::interestsPref {
        field $type : param($type);    # record field
        field $tags : param;           # array requiredm
        ADJUST {
            Carp::cluck q[too many tags; 100 max] if scalar @$tags > 100;
            grep { Carp::cluck q[tag "] . $_ . q[" is too long] if length $_ > 640 || At::_glength($_) > 64; } @$tags;
        }

        # perlclass does not have :reader yet
        method tags {$tags}

        method _raw() {
            +{ '$type' => $type, tags => $tags };
        }
    }

    # A declaration of a profile.
    class At::Lexicon::app::bsky::actor::profile {
        field $displayName : param //= ();    # string, 64 graphemes max, 640 bytes max
        field $description : param //= ();    # string, 256 graphemes max, 2560 bytes max
        field $avatar : param      //= ();    # blob, 1000000 bytes max, png or jpeg
        field $banner : param      //= ();    # blob, 1000000 bytes max, png or jpeg
        field $labels : param      //= ();    # union (why?) of selfLabels
        ADJUST {
            Carp::confess 'displayName is too long' if defined $displayName && ( length $displayName > 640  || At::_glength($displayName) > 64 );
            Carp::confess 'description is too long' if defined $description && ( length $description > 2560 || At::_glength($description) > 256 );
            $avatar = path($avatar)->slurp_utf8     if defined $avatar && -f $avatar;
            Carp::confess 'avatar is more than 1000000 bytes'                               if defined $avatar && length $avatar > 1000000;
            $banner = path($banner)->slurp_utf8                                             if defined $banner && -f $banner;
            Carp::confess 'banner is more than 1000000 bytes'                               if defined $banner && length $banner > 1000000;
            $labels = At::Lexicon::com::atproto::label::selfLabel->new( values => $labels ) if defined $labels && !builtin::blessed $labels;
        }

        # perlclass does not have :reader yet
        method displayName {$displayName}
        method description {$description}
        method avatar      {$avatar}
        method banner      {$banner}
        method labels      {$labels}

        method _raw() {
            +{  '$type' => 'app.bsky.actor.profile',
                defined $displayName ? ( displayName => $displayName )  : (), defined $description ? ( description => $description ) : (),
                defined $avatar      ? ( avatar      => $avatar )       : (), defined $banner      ? ( banner      => $banner )      : (),
                defined $labels      ? ( labels      => $labels->_raw ) : ()
            };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::app::bsky::actor - A reference to an actor in the network

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
