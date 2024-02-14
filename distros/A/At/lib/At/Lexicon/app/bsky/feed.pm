package At::Lexicon::app::bsky::feed 0.17 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use Carp;
    use URI;

    class At::Lexicon::app::bsky::feed::postView {
        field $type : param($type) //= ();    # record field
        field $uri : param;                   # URI, required
        field $cid : param;                   # cid, required
        field $author : param;                # app.bsky.actor.defs#profileViewBasic, required
        field $record : param;                # unknown, required
        field $embed : param       //= ();    # union
        field $replyCount : param  //= ();    # int
        field $repostCount : param //= ();    # int
        field $likeCount : param   //= ();    # int
        field $indexedAt : param;             # datetime, required
        field $viewer : param     //= ();     # ::viewerState
        field $labels : param     //= ();     # array of com.atproto.label
        field $threadgate : param //= ();     # ::threadgateView
        ADJUST {
            $uri        = URI->new($uri)                                                 unless builtin::blessed $uri;
            $author     = At::Lexicon::app::bsky::actor::profileViewBasic->new(%$author) unless builtin::blessed $author;
            $record     = At::_topkg( $record->{'$type'} )->new(%$record) if !builtin::blessed $record && defined $record->{'$type'};
            $embed      = At::_topkg( $embed->{'$type'} )->new(%$embed)   if defined $embed && !builtin::blessed $embed && defined $embed->{'$type'};
            $indexedAt  = At::Protocol::Timestamp->new( timestamp => $indexedAt )  if !builtin::blessed $indexedAt;
            $viewer     = At::Lexicon::app::bsky::feed::viewerState->new(%$viewer) if defined $viewer && !builtin::blessed $viewer;
            $labels     = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) if !builtin::blessed $_ } @$labels ] if defined $labels;
            $threadgate = At::Lexicon::app::bsky::feed::threadgateView->new(%$threadgate) if defined $threadgate && !builtin::blessed $threadgate;
        }

        # perlclass does not have :reader yet
        method uri         {$uri}
        method cid         {$cid}
        method author      {$author}
        method record      {$record}
        method embed       {$embed}
        method replyCount  {$replyCount}
        method repostCount {$repostCount}
        method likeCount   {$likeCount}
        method indexedAt   {$indexedAt}
        method viewer      {$viewer}
        method labels      {$labels}
        method threadgate  {$threadgate}

        method _raw() {
            +{  defined $type ? ( '$type' => $type ) : (),
                uri    => $uri->as_string,
                cid    => $cid,
                author => $author->_raw,
                record => builtin::blessed $record ? $record->_raw : $record,
                defined $embed ? ( embed => builtin::blessed $embed ? $embed->_raw : $embed ) : (),
                replyCount  => $replyCount,
                repostCount => $repostCount,
                likeCount   => $likeCount,
                indexedAt   => $indexedAt->_raw,
                defined $viewer ? ( viewer => $viewer->_raw ) : (), defined $labels ? ( labels => [ map { $_->_raw } @$labels ] ) : (),
                defined $threadgate ? ( threadgate => $threadgate->_raw ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::feed::viewerState {
        field $repost : param        //= ();    # URI
        field $like : param          //= ();    # URI
        field $replyDisabled : param //= ();    # bool
        ADJUST {
            $repost        = URI->new($repost) if defined $repost        && !builtin::blessed $repost;
            $like          = URI->new($like)   if defined $like          && !builtin::blessed $like;
            $replyDisabled = !!$replyDisabled  if defined $replyDisabled && builtin::blessed $replyDisabled;
        }

        # perlclass does not have :reader yet
        method repost        {$repost}
        method like          {$like}
        method replyDisabled {$replyDisabled}

        method _raw() {
            +{  defined $repost        ? ( repost        => $repost->as_string ) : (),
                defined $like          ? ( like          => $like->as_string )   : (),
                defined $replyDisabled ? ( replyDisabled => \$replyDisabled )    : ()
            };
        }
    }

    class At::Lexicon::app::bsky::feed::feedViewPost {
        field $post : param;             # ::postView, required
        field $reply : param  //= ();    # ::replyRef
        field $reason : param //= ();    # union
        ADJUST {
            $post   = At::Lexicon::app::bsky::feed::postView->new(%$post) unless builtin::blessed $post;
            $reply  = At::Lexicon::app::bsky::feed::replyRef->new(%$reply) if defined $reply && !builtin::blessed $reply;
            $reason = At::_topkg( $reason->{'$type'} )->new(%$reason) if defined $reason && !builtin::blessed $reason && defined $reason->{'$type'};
        }

        # perlclass does not have :reader yet
        method post   {$post}
        method reply  {$reply}
        method reason {$reason}

        method _raw() {
            +{ post => $post->_raw, defined $reply ? ( reply => $reply->_raw ) : (), defined $reason ? ( reason => $reason->_raw ) : (), };
        }
    }

    class At::Lexicon::app::bsky::feed::replyRef {
        field $root : param;      # union, required
        field $parent : param;    # union, required
        ADJUST {
            $root   = At::_topkg( $root->{'$type'} )->new(%$root)     if !builtin::blessed $root   && defined $root->{'$type'};
            $parent = At::_topkg( $parent->{'$type'} )->new(%$parent) if !builtin::blessed $parent && defined $parent->{'$type'};
        }

        # perlclass does not have :reader yet
        method root   {$root}
        method parent {$parent}

        method _raw() {
            +{ root => $root->_raw, parent => $parent->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::reasonRepost {
        field $type : param($type);    # record field
        field $by : param;             # app.bsky.actor.defs#profileViewBasic, required
        field $indexedAt : param;      # datetime, required
        ADJUST {
            $by        = At::Lexicon::app::bsky::actor::profileViewBasic->new(%$by) if defined $by && !builtin::blessed $by;
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt )    if !builtin::blessed $indexedAt;
        }

        # perlclass does not have :reader yet
        method by        {$by}
        method indexedAt {$indexedAt}

        method _raw() {
            +{ '$type' => $type, by => $by->_raw, indexedAt => $indexedAt->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::threadViewPost {
        field $type : param($type);       # record field
        field $post : param;              # #postView, required
        field $parent : param  //= ();    # union
        field $replies : param //= ();    # array
        ADJUST {
            $post    = At::Lexicon::app::bsky::feed::postView->new(%$post) unless builtin::blessed $post;
            $parent  = At::_topkg( $parent->{'$type'} )->new(%$parent) if !builtin::blessed $parent && defined $parent->{'$type'};
            $replies = [ map { $_ = At::_topkg( $_->{'$type'} )->new(%$_) if !builtin::blessed $_ && defined $_->{'$type'}; } @$replies ]
                if defined $replies;
        }

        # perlclass does not have :reader yet
        method post    {$post}
        method parent  {$parent}
        method replies {$replies}

        method _raw() {
            +{  '$type' => $type,
                post    => $post->_raw,
                defined $parent  ? ( parent  => builtin::blessed $parent ? $parent->_raw : $parent ) : (),
                defined $replies ? ( replies => [ map { $_->_raw } @$replies ] )                     : ()
            };
        }
    }

    class At::Lexicon::app::bsky::feed::notFoundPost {
        field $type : param($type);    # record field
        field $uri : param;            # AT-URI, required
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

    class At::Lexicon::app::bsky::feed::blockedPost {
        field $type : param($type);    # record field
        field $uri : param;            # AT-URI, required
        field $blocked : param;        # bool, required
        field $author : param;         # ::blockedAuthor, required
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

    class At::Lexicon::app::bsky::feed::blockedAuthor {
        field $did : param;              # DID, required
        field $viewer : param //= ();    # ::viewerState
        ADJUST {
            $did    = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
            $viewer = At::Lexicon::app::bsky::actor::viewerState->new(%$viewer) if defined $viewer && !builtin::blessed $viewer;
        }

        # perlclass does not have :reader yet
        method did    {$did}
        method viewer {$viewer}

        method _raw() {
            +{ did => $did->_raw, defined $viewer ? ( viewer => $viewer->_raw ) : () };
        }
    }

    class At::Lexicon::app::bsky::feed::generatorView {
        field $type : param($type) //= ();          # record field
        field $uri : param;                         # URI, required
        field $cid : param;                         # CID, required
        field $did : param;                         # DID, required
        field $creator : param;                     # ::actor::profileView, required
        field $displayName : param;                 # string, required
        field $description : param       //= ();    # string, max len: 3000, max grapheme: 300
        field $descriptionFacets : param //= ();    # array
        field $avatar : param            //= ();    # string
        field $likeCount : param         //= ();    # int, min: 0
        field $viewer : param            //= ();    # ::generatorViewerState
        field $indexedAt : param;                   # datetime, required
        ADJUST {
            $uri     = URI->new($uri)                                             unless builtin::blessed $uri;
            $did     = At::Protocol::DID->new( uri => $did )                      unless builtin::blessed $did;
            $creator = At::Lexicon::app::bsky::actor::profileView->new(%$creator) unless builtin::blessed $creator;
            Carp::confess 'description is too long' if defined $description && ( length $description > 3000 || At::_glength($description) > 300 );
            $descriptionFacets = [ map { $_ = At::Lexicon::app::bsky::richtext::facet->new(%$_) unless builtin::blessed $_ } @$descriptionFacets ]
                if defined $descriptionFacets;
            Carp::confess 'likeCount is below zero' if defined $likeCount && $likeCount < 0;
            $viewer    = At::Lexicon::app::bsky::feed::generatorViewerState->new(%$viewer) if defined $viewer && !builtin::blessed $viewer;
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt ) unless builtin::blessed $indexedAt;
        }

        # perlclass does not have :reader yet
        method uri              {$uri}
        method cid              {$cid}
        method did              {$did}
        method creator          {$creator}
        method displayName      {$displayName}
        method description      {$description}
        method descrptionFacets {$descriptionFacets}
        method avatar           {$avatar}
        method likeCount        {$likeCount}
        method viewer           {$viewer}
        method indexedAt        {$indexedAt}

        method _raw() {
            +{  defined $type ? ( '$type' => $type ) : (),
                uri         => $uri->as_string,
                cid         => $cid,
                did         => $did->_raw,
                creator     => $creator->_raw,
                displayName => $displayName,
                defined $description       ? ( description       => $description )                             : (),
                defined $descriptionFacets ? ( descriptionFacets => [ map { $_->_raw } @$descriptionFacets ] ) : (),
                defined $avatar            ? ( avatar            => $avatar ) : (), defined $likeCount ? ( likeCount => $likeCount ) : (),
                defined $viewer            ? ( viewer            => $viewer->_raw ) : (), indexedAt => $indexedAt->_raw
            };
        }
    }

    class At::Lexicon::app::bsky::feed::generatorViewerState {
        field $like : param //= ();    # AT-URI
        ADJUST {
            $like = URI->new($like) if defined $like && !builtin::blessed $like;
        }

        # perlclass does not have :reader yet
        method like {$like}

        method _raw() {
            +{ defined $like ? ( like => $like->as_string ) : () };
        }
    }

    class At::Lexicon::app::bsky::feed::skeletonFeedPost {
        field $post : param;      # AT-URI, required
        field $reason : param;    # union
        ADJUST {
            $post   = URI->new($post)                                 if defined $post   && !builtin::blessed $post;
            $reason = At::_topkg( $reason->{'$type'} )->new(%$reason) if defined $reason && !builtin::blessed $reason && defined $reason->{'$type'};
        }

        # perlclass does not have :reader yet
        method post   {$post}
        method reason {$reason}

        method _raw() {
            +{ post => $post->as_string, defined $reason ? ( reason => $reason->_raw ) : () };
        }
    }

    class At::Lexicon::app::bsky::feed::skeletonReasonRepost {
        field $repost : param;    # AT-URI, required
        ADJUST {
            $repost = URI->new($repost) if defined $repost && !builtin::blessed $repost;
        }

        # perlclass does not have :reader yet
        method repost {$repost}

        method _raw() {
            +{ repost => $repost->as_string };
        }
    }

    class At::Lexicon::app::bsky::feed::threadgateView {
        field $uri : param    //= ();    # At-URI
        field $cid : param    //= ();    # CID
        field $record : param //= ();    # user defined
        field $lists : param  //= ();    # array of app.bsky.graph#listViewBasic
        ADJUST {
            $uri    = URI->new($uri)                                  if defined $uri              && !builtin::blessed $uri;
            $record = At::_topkg( $record->{'$type'} )->new(%$record) if !builtin::blessed $record && defined $record->{'$type'};
            $lists  = [ map { $_ = At::Lexicon::app::bsky::graph::listViewBasic->new(%$_) if !builtin::blessed $_ } @$lists ] if defined $lists;
        }

        # perlclass does not have :reader yet
        method uri    {$uri}
        method cid    {$cid}
        method record {$record}
        method lists  {$lists}

        method _raw() {
            +{  defined $uri    ? ( uri    => $uri->as_string )                                        : (),
                defined $cid    ? ( cid    => $cid )                                                   : (),
                defined $record ? ( record => ( builtin::blessed $record ? $record->_raw : $record ) ) : (),
                defined $lists  ? ( lists  => [ map { $_->_raw } @$lists ] )                           : ()
            };
        }
    }

    class At::Lexicon::app::bsky::feed::generator {
        field $did : param;                         # DID, required
        field $displayName : param;                 # string, required, max len: 240, max grapheme: 24
        field $description : param       //= ();    # string, max len: 3000, max grapheme: 300
        field $descriptionFacets : param //= ();    # array
        field $avatar : param            //= ();    # blob, max size: 1000000, png or jpeg
        field $labels : param            //= ();    # union
        field $createdAt : param;                   # datetime, required
        ADJUST {
            $did = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
            Carp::confess 'displayName is too long' if defined $displayName && ( length $displayName > 240  || At::_glength($displayName) > 24 );
            Carp::confess 'description is too long' if defined $description && ( length $description > 3000 || At::_glength($description) > 300 );
            $descriptionFacets = [ map { $_ = At::Lexicon::app::bsky::richtext::facet->new(%$_) unless builtin::blessed $_ } @$descriptionFacets ]
                if defined $descriptionFacets;
            Carp::confess 'avatar is too large' if defined $avatar && length $avatar > 1000000;
            $labels = [ map { $_ = At::Lexicon::com::atproto::label::selfLabels->new(%$_) unless builtin::blessed $_ } @$labels ] if defined $labels;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method did              {$did}
        method displayName      {$displayName}
        method description      {$description}
        method descriptinFacets {$descriptionFacets}
        method avatar           {$avatar}
        method labels           {$labels}
        method createdAt        {$createdAt}

        method _raw() {
            +{  did         => $did,
                displayName => $displayName,
                defined $description       ? ( description       => $description )       : (),
                defined $descriptionFacets ? ( descriptionFacets => $descriptionFacets ) : (), defined $avatar ? ( avatar => $avatar ) : (),
                defined $labels            ? ( labels            => [ map { $_->_raw } @$labels ] ) : (), createdAt => $createdAt->_raw
            };
        }
    }

    class At::Lexicon::app::bsky::feed::describeFeedGenerator::feed {
        field $uri : param;    # URI, required
        ADJUST { $uri = URI->new($uri) unless builtin::blessed $uri }

        # perlclass does not have :reader yet
        method uri    {$uri}
        method _raw() { +{ uri => $uri->as_string } }
    }

    class At::Lexicon::app::bsky::feed::describeFeedGenerator::links {
        field $privacyPolicy : param  //= ();    # string
        field $termsOfService : param //= ();    # string

        # perlclass does not have :reader yet
        method privacyPolicy {$privacyPolicy}
        method termsOfSerice {$termsOfService}

        method _raw() {
            +{  defined $privacyPolicy  ? ( privacyPolicy => $privacyPolicy )  : (),
                defined $termsOfService ? ( termsOfSerice => $termsOfService ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::feed::getLikes::like {
        field $indexedAt : param;    # datetime, required
        field $createdAt : param;    # datetime, required
        field $actor : param;        # ::actor::profileView, required
        ADJUST {
            $indexedAt = At::Protocol::Timestamp->new( timestamp => $indexedAt ) unless builtin::blessed $indexedAt;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $actor     = At::Lexicon::app::bsky::actor::profileView->new(%$actor) unless builtin::blessed $actor;
        }

        # perlclass does not have :reader yet
        method indexedAt {$indexedAt}
        method createdAt {$createdAt}
        method actor     {$actor}

        method _raw() {
            +{ indexedAt => $indexedAt->_raw, createdAt => $createdAt->_raw, actor => $actor->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::like {
        field $type : param($type) //= 'app.bsky.feed.like';    # record field
        field $subject : param;                                 # ::repo::strongRef, required
        field $createdAt : param;                               # datetime, required
        ADJUST {
            $subject   = At::Lexicon::com::atproto::repo::strongRef->new(%$subject) unless builtin::blessed $subject;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt )    unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method subject   {$subject}
        method createdAt {$createdAt}

        method _raw() {
            +{ '$type' => $type, subject => $subject->_raw, createdAt => $createdAt->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::post {
        field $type : param($type) //= 'app.bsky.feed.post';    # record field
        field $text : param;                                    # string, required, max 300 graphemes, max length 3000
        field $facets : param //= ();                           # array of app.bsky.richtext.facet
        field $reply : param  //= ();                           # #replyRef
        field $embed : param  //= ();                           # union
        field $langs : param  //= ();                           # array, 3 elements max
        field $labels : param //= ();                           # array of ::com::atproto::label::selfLabels
        field $tags : param   //= ();                           # array
        field $createdAt : param;                               # timestamp, required

        # Bluesky is returning this from time to time as of Dec. 14, 2023
        field $via : param //= ();                              # string

        # API is returning this but it's not in the lexicon as of Dec. 20th, 2023
        field $length : param //= ();                           # int
        ADJUST {
            Carp::confess 'text is too long' if length $text > 3000 || At::_glength($text) > 300;
            $facets = [ map { $_ = At::Lexicon::app::bsky::richtext::facet->new(%$_) unless builtin::blessed $_ } @$facets ] if defined $facets;
            $reply  = At::Lexicon::app::bsky::feed::post::replyRef->new(%$reply) if defined $reply && !builtin::blessed $reply;
            $embed  = At::_topkg( $embed->{'$type'} )->new(%$embed) if defined $embed && !builtin::blessed $embed && defined $embed->{'$type'};
            Carp::confess 'too many languages'                                    if defined $langs && scalar @$langs > 3;
            $labels = At::Lexicon::com::atproto::label::selfLabels->new(%$labels) if defined $labels && !builtin::blessed $labels;
            Carp::confess 'too many tags'   if defined $tags && scalar @$tags > 8;
            Carp::confess 'tag is too long' if defined $tags && grep { length $_ > 640 || At::_glength($_) > 64 } @$tags;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method text      {$text}
        method facets    {$facets}
        method reply     {$reply}
        method embed     {$embed}
        method langs     {$langs}
        method labels    {$labels}
        method tags      {$tags}
        method createdAt {$createdAt}

        method _raw() {
            +{  '$type' => $type,
                text    => $text,
                defined $facets ? ( facets => [ map { $_->_raw } @$facets ] ) : (), defined $reply ? ( reply => $reply->_raw )        : (),
                defined $embed  ? ( embed  => $embed->_raw )                  : (), defined $langs ? ( langs => $langs )              : (),
                defined $labels ? ( labels => $labels->_raw )                 : (), defined $tags  ? ( tags  => [ map {$_} @$tags ] ) : (),
                createdAt => $createdAt->_raw,
                defined $via ? ( via => $via ) : (), defined $length ? ( length => $length ) : ()
            };
        }
    }

    class At::Lexicon::app::bsky::feed::post::replyRef {
        field $root : param;      # ::repo::strongRef, required
        field $parent : param;    # ::repo::strongRef, required
        ADJUST {
            $root   = At::Lexicon::com::atproto::repo::strongRef->new(%$root)   unless builtin::blessed $root;
            $parent = At::Lexicon::com::atproto::repo::strongRef->new(%$parent) unless builtin::blessed $parent;
        }

        # perlclass does not have :reader yet
        method root   {$root}
        method parent {$parent}

        method _raw() {
            +{ root => $root->_raw, parent => $parent->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::repost {
        field $type : param($type) //= 'app.bsky.feed.repost';    # record field
        field $subject : param;                                   # ::repo::strongRef, required
        field $createdAt : param;                                 # datetime, required
        ADJUST {
            $subject   = At::Lexicon::com::atproto::repo::strongRef->new(%$subject) unless builtin::blessed $subject;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt )    unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method subject   {$subject}
        method createdAt {$createdAt}

        method _raw() {
            +{ '$type' => $type, subject => $subject->_raw, createdAt => $createdAt->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::threadgate {
        field $post : param;         # At-URI, required
        field $allow : param;        # array, union, max 5
        field $createdAt : param;    # datetime, required
        ADJUST {
            $post = URI->new($post) unless builtin::blessed $post;
            Carp::confess 'too many elements in allow' if defined $allow && scalar @$allow > 5;
            $allow = [ map { $_ = At::_topkg( $_->{'$type'} )->new(%$_) if !builtin::blessed $_ && defined $_->{'$type'} } @$allow ]
                if defined $allow;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method post      {$post}
        method allow     {$allow}
        method createdAt {$createdAt}

        method _raw() {
            +{ post => $post->as_string, defined $allow ? ( allow => [ map { $_->_raw } @$allow ] ) : (), createdAt => $createdAt->_raw };
        }
    }

    class At::Lexicon::app::bsky::feed::threadgate::mentionRule {
        field $type : param($type);    # record field

        method _raw() {
            +{ '$type' => $type };
        }
    }

    class At::Lexicon::app::bsky::feed::threadgate::followingRule {
        field $type : param($type);    # record field

        method _raw() {
            +{ '$type' => $type };
        }
    }

    class At::Lexicon::app::bsky::feed::threadgate::listRule {
        field $type : param($type);    # record field
        field $list : param;           # AT-URI, required
        ADJUST {
            $list = URI->new($list) unless builtin::blessed $list;
        }
        method list {$list}

        method _raw() {
            +{ '$type' => $type, list => $list->as_string };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::app::bsky::feed - Post Declarations

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
