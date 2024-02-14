package At::Lexicon::com::atproto::admin 0.17 {

    #~ https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/admin/defs.json
    use v5.38;
    use lib '../../../../../lib';
    no warnings 'experimental::class', 'experimental::builtin', 'experimental::try';    # Be quiet.
    use feature 'class', 'try';
    #
    class At::Lexicon::com::atproto::admin::statusAttr 1 {
        field $applied : param;
        field $ref : param //= ();

        # perlclass does not have :reader yet
        method applied {$applied}
        method ref     {$ref}

        method _raw() {
            +{ applied => \!!$applied, defined $ref ? ( ref => $ref ) : () };
        }
    };

    class At::Lexicon::com::atproto::admin::modEventView 1 {
        field $id : param;                      # int, required
        field $event : param;                   # union, required
        field $subject : param;                 # union, required
        field $subjectBlobCids : param;         # array, required
        field $createdBy : param;               # DID, required
        field $createdAt : param;               # Datetime, required
        field $creatorHandle : param //= ();    # string, required
        field $subjectHandle : param //= ();    # string, required
        ADJUST {
            #~ $event     = At::_topkg( $event->{'$type'} )->new(%$event)     if !builtin::blessed $event   && defined $event->{'$type'};
            use Carp;
            Carp::confess 'unknown event'
                unless $event->{'$type'} eq 'com.atproto.admin.defs#modEventTakedown' ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventReverseTakedown' ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventComment'         ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventReport'          ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventLabel'           ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventAcknowledge'     ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventEscalate'        ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventMute'            ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventEmail'           ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventResolveAppeal';
            $subject   = At::_topkg( $subject->{'$type'} )->new(%$subject) if !builtin::blessed $subject && defined $subject->{'$type'};
            $createdBy = At::Protocol::DID->new( uri => $createdBy )             unless builtin::blessed $createdBy;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method id              {$id}
        method event           {$event}
        method subject         {$subject}
        method subjectBlobCids {$subjectBlobCids}
        method createdBy       {$createdBy}
        method createdAt       {$createdAt}
        method creatorHandle   {$creatorHandle}
        method subjectHandle   {$creatorHandle}

        method _raw() {
            +{  id              => $id,
                event           => $event->_raw,
                subject         => $subject->_raw,
                subjectBlobCids => $subjectBlobCids,
                createdBy       => $createdBy->_raw,
                createdAt       => $createdAt->_raw,
                defined $creatorHandle ? ( creatorHandle => $creatorHandle ) : (), defined $subjectHandle ? ( subjectHandle => $subjectHandle ) : ()
            };
        }
    };

    class At::Lexicon::com::atproto::admin::modEventViewDetail 1 {
        field $id : param;              # int, required
        field $event : param;           # union, required
        field $subject : param;         # union, required
        field $subjectBlobs : param;    # array, required
        field $createdBy : param;       # DID, required
        field $createdAt : param;       # Datetime, required
        ADJUST {
            #~ $event        = At::_topkg( $event->{'$type'} )->new(%$event)     if !builtin::blessed $event   && defined $event->{'$type'};
            use Carp;
            Carp::confess 'unknown event'
                unless $event->{'$type'} eq 'com.atproto.admin.defs#modEventTakedown' ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventReverseTakedown' ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventComment'         ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventReport'          ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventLabel'           ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventAcknowledge'     ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventEscalate'        ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventMute'            ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventEmail'           ||
                $event->{'$type'} eq 'com.atproto.admin.defs#modEventResolveAppeal';
            $subject      = At::_topkg( $subject->{'$type'} )->new(%$subject) if !builtin::blessed $subject && defined $subject->{'$type'};
            $subjectBlobs = [ map { $_ = At::Lexicon::com::atproto::admin::blobView->new(%$_) unless builtin::blessed $_ } @$subjectBlobs ];
            $createdBy    = At::Protocol::DID->new( uri => $createdBy )             unless builtin::blessed $createdBy;
            $createdAt    = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method id           {$id}
        method event        {$event}
        method subject      {$subject}
        method subjectBlobs {$subjectBlobs}
        method createdBy    {$createdBy}
        method createdAt    {$createdAt}

        method _raw() {
            +{  id          => $id,
                event       => $event,
                subject     => $subject->_raw,
                subjectBlob => [ map { $_->_raw } @$subjectBlobs ],
                createdBy   => $createdBy->_raw,
                createdAt   => $createdAt->_raw
            };
        }
    };

    class At::Lexicon::com::atproto::admin::reportView 1 {
        field $id : param;                          # int, required
        field $reasonType : param;                  # ::com::atproto::moderation::reasonType, required
        field $comment : param           //= ();    # string, required
        field $subjectRepoHandle : param //= ();    # string
        field $subject : param;                     # union, required
        field $reportedBy : param;                  # DID, required
        field $createdAt : param;                   # Datetime, required
        field $resolvedByActionIds : param;         # array, required
        ADJUST {
            $reasonType = At::Lexicon::com::atproto::moderation::reasonType->new(%$reasonType) unless builtin::blessed $reasonType;
            $subject    = At::_topkg( $subject->{'$type'} )->new(%$subject) if !builtin::blessed $subject && defined $subject->{'$type'};
            $reportedBy = At::Protocol::DID->new( uri => $reportedBy )            unless builtin::blessed $reportedBy;
            $createdAt  = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method id                  {$id}
        method reasonType          {$reasonType}
        method comment             {$comment}
        method subjectRepoHandle   {$subjectRepoHandle}
        method subject             {$subject}
        method reportedBy          {$reportedBy}
        method createdAt           {$createdAt}
        method resolvedByActionIds {$resolvedByActionIds}

        method _raw() {
            +{  id         => $id,
                reasonType => $reasonType->_raw,
                comment    => $comment,
                defined $subjectRepoHandle ? ( subjectRepoHandle => $subjectRepoHandle ) : (),
                subject             => $subject->_raw,
                reportedBy          => $reportedBy->_raw,
                createdAt           => $createdAt->_raw,
                resolvedByActionIds => $resolvedByActionIds
            };
        }
    };

    class At::Lexicon::com::atproto::admin::subjectStatusView 1 {
        field $id : param;                          # int, required
        field $subject : param;                     # union, required
        field $subjectBlobCids : param   //= ();    # array
        field $subjectRepoHandle : param //= ();    # string
        field $updatedAt : param;                   # datetime, required
        field $createdAt : param;                   # datetime, required
        field $reviewState : param;                 # ::subjectReviewState, required
        field $comment : param        //= ();       # string
        field $muteUntil : param      //= ();       # datetime
        field $lastReviewedBy : param //= ();       # DID
        field $lastReviewedAt : param //= ();       # datetime
        field $lastReportedAt : param //= ();       # datetime
        field $takendown : param      //= ();       # bool
        field $suspendUntil : param   //= ();       # datetime
        ADJUST {
            $subject        = At::_topkg( $subject->{'$type'} )->new(%$subject) if !builtin::blessed $subject && defined $subject->{'$type'};
            $updatedAt      = At::Protocol::Timestamp->new( timestamp => $updatedAt ) unless builtin::blessed $updatedAt;
            $createdAt      = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $reviewState    = At::Lexicon::com::atproto::admin::subjectReviewState->new(%$reviewState) unless builtin::blessed $reviewState;
            $muteUntil      = At::Protocol::Timestamp->new( timestamp => $muteUntil ) if defined $muteUntil      && !builtin::blessed $muteUntil;
            $lastReviewedBy = At::Protocol::DID->new( uri => $lastReviewedBy )        if defined $lastReviewedBy && !builtin::blessed $lastReviewedBy;
            $lastReviewedAt = At::Protocol::Timestamp->new( timestamp => $lastReviewedAt )
                if defined $lastReviewedAt && !builtin::blessed $lastReviewedAt;
            $lastReportedAt = At::Protocol::Timestamp->new( timestamp => $lastReportedAt )
                if defined $lastReportedAt && !builtin::blessed $lastReportedAt;
            $suspendUntil = At::Protocol::Timestamp->new( timestamp => $suspendUntil ) if defined $suspendUntil && !builtin::blessed $suspendUntil;
        }

        # perlclass does not have :reader yet
        method id                {$id}
        method subject           {$subject}
        method subjectBlobCids   {$subjectBlobCids}
        method subjectRepoHandle {$subjectRepoHandle}
        method createdAt         {$createdAt}
        method reviewState       {$reviewState}
        method comment           {$comment}
        method muteUntil         {$muteUntil}
        method lastReviewedBy    {$lastReviewedBy}
        method lastReviewedAt    {$lastReviewedAt}
        method lastReportedAt    {$lastReportedAt}
        method takendown         {$takendown}
        method suspendUntil      {$suspendUntil}

        method _raw() {
            +{  id      => $id,
                subject => $subject->_raw,
                defined $subjectBlobCids   ? ( subjectBlobCids   => $subjectBlobCids )   : (),
                defined $subjectRepoHandle ? ( subjectRepoHandle => $subjectRepoHandle ) : (),
                updatedAt   => $updatedAt->_raw,
                createdAt   => $createdAt->_raw,
                reviewState => $reviewState->_raw,
                defined $comment        ? ( comment        => $comment ) : (), defined $muteUntil ? ( muteUntil => $muteUntil->_raw ) : (),
                defined $lastReviewedBy ? ( lastReviewedBy => $lastReviewedBy->_raw ) : (),
                defined $lastReviewedAt ? ( lastReviewedAt => $lastReviewedAt->_raw ) : (),
                defined $lastReportedAt ? ( lastReportedAt => $lastReportedAt->_raw ) : (), defined $takendown ? ( takendown => \!!$takendown ) : (),
                defined $suspendUntil   ? ( suspendUntil   => $suspendUntil->_raw )   : ()
            };
        }
    };

    class At::Lexicon::com::atproto::admin::reportViewDetail 1 {
        field $id : param;                      # int, required
        field $reasonType : param;              # ::reasonType, required
        field $comment : param //= ();          # string
        field $subject : param;                 # union, required
        field $subjectStatus : param //= ();    # ::com::atproto::admin::subjectStatusView
        field $reportedBy : param;              # DID, required
        field $createdAt : param;               # datetime, required
        field $resolvedByActions : param;       # array, required
        ADJUST {
            $reasonType    = At::Lexicon::com::atproto::moderation::reasonType->new(%$reasonType) unless builtin::blessed $reasonType;
            $subject       = At::_topkg( $subject->{'$type'} )->new(%$subject) if !builtin::blessed $subject && defined $subject->{'$type'};
            $subjectStatus = At::Lexicon::com::atproto::subjectStatusView->new(%$subjectStatus)
                if defined $subjectStatus && !builtin::blessed $subjectStatus;
            $reportedBy        = At::Protocol::DID->new( uri => $reportedBy )                             unless !builtin::blessed $reportedBy;
            $createdAt         = At::Protocol::Timestamp->new( timestamp => $createdAt )                  unless builtin::blessed $createdAt;
            $resolvedByActions = At::Lexicon::com::atproto::admin::modEventView->new(%$resolvedByActions) unless builtin::blessed $resolvedByActions;
        }

        # perlclass does not have :reader yet
        method id                {$id}
        method reasonType        {$reasonType}
        method comment           {$comment}
        method subject           {$subject}
        method subjectStatus     {$subjectStatus}
        method reportedBy        {$reportedBy}
        method createdAt         {$createdAt}
        method resolvedByActions {$resolvedByActions}

        method _raw() {
            +{  id         => $id,
                reasonType => $reasonType,
                defined $comment ? ( comment => $comment ) : (),
                subject => $subject->_raw,
                defined $subjectStatus ? ( subjectStatus => $subjectStatus->_raw ) : (),
                reportedBy        => $reportedBy->_raw,
                createdAt         => $createdAt->_raw,
                resolvedByActions => [ map { $_->_raw } @$resolvedByActions ]
            };
        }
    };

    class At::Lexicon::com::atproto::admin::repoView 1 {
        field $did : param;                       # DID, required
        field $handle : param;                    # Handle, required
        field $email : param;                     # string, required
        field $relatedRecords : param;            # array, required
        field $indexedAt : param;                 # datetime, required
        field $moderation : param;                # ::moderation, required
        field $invitedBy : param       //= ();    # ::com::atproto::server::inviteCode
        field $invitesDisabled : param //= ();    # bool
        field $inviteNote : param      //= ();    # string
        ADJUST {
            $did        = At::Protocol::DID->new( uri => $did )                           unless builtin::blessed $did;
            $handle     = At::Protocol::Handle->new( id => $handle )                      unless builtin::blessed $handle;
            $indexedAt  = At::Protocol::Timestamp->new( timestamp => $indexedAt )         unless builtin::blessed $indexedAt;
            $moderation = At::Lexicon::com::atproto::admin::moderation->new(%$moderation) unless builtin::blessed $moderation;
            $invitedBy  = At::Lexicon::com::atproto::server::inviteCode->new(%$invitedBy) if defined $invitedBy && !builtin::blessed $invitedBy;
        }

        # perlclass does not have :reader yet
        method did             {$did}
        method handle          {$handle}
        method email           {$email}
        method relatedRecords  {$relatedRecords}
        method indexedAt       {$indexedAt}
        method moderation      {$moderation}
        method invitedBy       {$invitedBy}
        method invitesDisabled {$invitesDisabled}
        method inviteNote      {$inviteNote}

        method _raw() {
            +{  did            => $did->_raw,
                handle         => $handle->_raw,
                email          => $email,
                relatedRecords => $relatedRecords,
                indexedAt      => $indexedAt->_raw,
                moderation     => $moderation->_raw,
                defined $invitedBy ? ( invitedBy => $invitedBy->_raw ) : (),
                defined $invitesDisabled ? ( invitesDisabled => \!!$invitesDisabled ) : (), defined $inviteNote ? ( inviteNote => $inviteNote ) : ()
            };
        }
    };

    class At::Lexicon::com::atproto::admin::repoViewDetail 1 {
        field $did : param;                        # DID, required
        field $handle : param;                     # Handle, required
        field $email : param //= ();               # string
        field $relatedRecords : param;             # array, required
        field $indexedAt : param;                  # datetime, required
        field $moderation : param;                 # ::moderationDetail, required
        field $labels : param           //= ();    # array
        field $invitedBy : param        //= ();    # ::com::atproto::server::inviteCode
        field $invites : param          //= ();    # array
        field $invitesDisabled : param  //= ();    # bool
        field $inviteNote : param       //= ();    # string
        field $emailConfirmedAt : param //= ();    # datetime
        ADJUST {
            $did              = At::Protocol::DID->new( uri => $did )                                 unless builtin::blessed $did;
            $handle           = At::Protocol::Handle->new( id => $handle )                            unless builtin::blessed $handle;
            $indexedAt        = At::Protocol::Timestamp->new( timestamp => $indexedAt )               unless builtin::blessed $indexedAt;
            $moderation       = At::Lexicon::com::atproto::admin::moderationDetail->new(%$moderation) unless builtin::blessed $moderation;
            $invitedBy        = At::Lexicon::com::atproto::server::inviteCode->new(%$invitedBy) if defined $invitedBy && !builtin::blessed $invitedBy;
            $invites          = [ map { At::Lexicon::com::atproto::server::inviteCode->new(%$_) } @$invites ] if defined $invites;
            $emailConfirmedAt = At::Protocol::Timestamp->new( timestamp => $emailConfirmedAt )
                if defined $emailConfirmedAt && !builtin::blessed $emailConfirmedAt;
        }

        # perlclass does not have :reader yet
        method did              {$did}
        method handle           {$handle}
        method email            {$email}
        method relatedRecords   {$relatedRecords}
        method indexedAt        {$indexedAt}
        method moderation       {$moderation}
        method labels           {$labels}
        method invitedBy        {$invitedBy}
        method invites          {$invites}
        method invitesDisabled  {$invitesDisabled}
        method inviteNote       {$inviteNote}
        method emailConfirmedAt {$emailConfirmedAt}

        method _raw() {
            +{  did    => $did->_raw,
                handle => $handle->_raw,
                defined $email ? ( email => $email ) : (),
                relatedRecords => $relatedRecords,
                indexedAt      => $indexedAt->_raw,
                moderation     => $moderation->_raw,
                defined $labels ? ( labels => [ map { $_->_raw } @$labels ] ) : (), defined $invitedBy ? ( invitedBy => $invitedBy->_raw ) : (),
                defined $invites          ? ( invites          => [ map { $_->_raw } @$invites ] ) : (),
                defined $invitesDisabled  ? ( invitesDisabled  => \!!$invitesDisabled )            : (),
                defined $emailConfirmedAt ? ( emailConfirmedAt => $emailConfirmedAt->_raw )        : ()
            };
        }
    };

    class At::Lexicon::com::atproto::admin::accountView 1 {
        field $did : param;                        # DID, required
        field $handle : param;                     # Handle, required
        field $email : param          //= ();      # string
        field $relatedRecords : param //= ();      # array
        field $indexedAt : param;                  # datetime, required
        field $invitedBy : param        //= ();    # ::com::atproto::server::inviteCode
        field $invites : param          //= ();    # array
        field $invitesDisabled : param  //= ();    # bool
        field $emailConfirmedAt : param //= ();    # datetime
        field $inviteNote : param       //= ();    # string
        ADJUST {
            $did            = At::Protocol::DID->new( uri => $did )      unless builtin::blessed $did;
            $handle         = At::Protocol::Handle->new( id => $handle ) unless builtin::blessed $handle;
            $relatedRecords = [ map { builtin::blessed $_ || !defined $_->{'$type'} ? $_ : At::_topkg( $_->{'$type'} )->new(%$_) } @$relatedRecords ]
                if defined $relatedRecords;
            $indexedAt        = At::Protocol::Timestamp->new( timestamp => $indexedAt ) unless builtin::blessed $indexedAt;
            $invitedBy        = At::Lexicon::com::atproto::server::inviteCode->new(%$invitedBy) if defined $invitedBy && !builtin::blessed $invitedBy;
            $invites          = [ map { At::Lexicon::com::atproto::server::inviteCode->new(%$_) } @$invites ] if defined $invites;
            $emailConfirmedAt = At::Protocol::Timestamp->new( timestamp => $emailConfirmedAt )
                if defined $emailConfirmedAt && !builtin::blessed $emailConfirmedAt;
        }

        # perlclass does not have :reader yet
        method did              {$did}
        method handle           {$handle}
        method email            {$email}
        method relatedRecords   {$relatedRecords}
        method indexedAt        {$indexedAt}
        method invitedBy        {$invitedBy}
        method invites          {$invites}
        method invitesDisabled  {$invitesDisabled}
        method emailConfirmedAt {$emailConfirmedAt}
        method inviteNote       {$inviteNote}

        method _raw() {
            +{  did    => $did->_raw,
                handle => $handle->_raw,
                defined $email          ? ( email          => $email )                                                           : (),
                defined $relatedRecords ? ( relatedRecords => [ map { builtin::blessed $_ ? $_->_raw : $_ } @$relatedRecords ] ) : (),
                indexedAt => $indexedAt->_raw,
                defined $invitedBy ? ( invitedBy => $invitedBy->_raw ) : (), defined $invites ? ( invites => [ map { $_->_raw } @$invites ] ) : (),
                defined $invitesDisabled  ? ( invitesDisabled  => \!!$invitesDisabled )     : (),
                defined $emailConfirmedAt ? ( emailConfirmedAt => $emailConfirmedAt->_raw ) : (),
                defined $inviteNote       ? ( inviteNote       => $inviteNote )             : ()
            };
        }
    };

    class At::Lexicon::com::atproto::admin::repoViewNotFound 1 {
        field $did : param;    # DID, required
        ADJUST {
            $did = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
        }

        # perlclass does not have :reader yet
        method did {$did}

        method _raw() {
            +{ did => $did->_raw };
        }
    };

    class At::Lexicon::com::atproto::admin::repoRef 1 {
        field $did : param;    # DID, required
        ADJUST {
            $did = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
        }

        # perlclass does not have :reader yet
        method did {$did}

        method _raw() {
            +{ did => $did->_raw };
        }
    };

    class At::Lexicon::com::atproto::admin::repoBlobRef 1 {
        field $did : param;                 # DID, required
        field $cid : param;                 # CID, required
        field $recordUri : param //= ();    # at-uri
        ADJUST {
            $did       = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
            $recordUri = URI->new($recordUri) if defined $recordUri && !builtin::blessed $recordUri;
        }

        # perlclass does not have :reader yet
        method did       {$did}
        method cid       {$cid}
        method recordUri {$recordUri}

        method _raw() {
            +{ did => $did->_raw, cid => $cid, defined $recordUri ? ( recordUri => $recordUri->as_string ) : () };
        }
    };

    class At::Lexicon::com::atproto::admin::recordView 1 {
        field $uri : param;           # at-uri, required
        field $cid : param;           # cid, required
        field $value : param;         # unknown, required
        field $blobCids : param;      # array, required
        field $indexedAt : param;     # datetime, required
        field $moderation : param;    # ::moderation, required
        field $repo : param;          # ::repoView, required
        ADJUST {
            $uri        = URI->new($uri)                                                  unless builtin::blessed $uri;
            $indexedAt  = At::Protocol::Timestamp->new( timestamp => $indexedAt )         unless builtin::blessed $indexedAt;
            $moderation = At::Lexicon::com::atproto::admin::moderation->new(%$moderation) unless builtin::blessed $moderation;
            $repo       = At::Lexicon::com::atproto::admin::repoView->new(%$repo)         unless builtin::blessed $repo;
        }

        # perlclass does not have :reader yet
        method uri        {$uri}
        method cid        {$cid}
        method value      {$value}
        method blobCids   {$blobCids}
        method indexedAt  {$indexedAt}
        method moderation {$moderation}
        method repo       {$repo}

        method _raw() {
            +{  uri        => $uri->as_string,
                cid        => $cid,
                value      => $value,
                blobCids   => $blobCids,
                indexedAt  => $indexedAt->_raw,
                moderation => $moderation->_raw,
                repo       => $repo->_raw
            };
        }
    };

    class At::Lexicon::com::atproto::admin::recordViewDetail 1 {
        field $uri : param;              # at-uri, required
        field $cid : param;              # cid, required
        field $value : param;            # unknown, required
        field $blobs : param;            # array, required
        field $labels : param //= ();    # array
        field $indexedAt : param;        # datetime, required
        field $moderation : param;       # ::moderationDetail, required
        field $repo : param;             # ::repoView, required
        ADJUST {
            $uri        = URI->new($uri) unless builtin::blessed $uri;
            $blobs      = [ map { $_ = At::Lexicon::com::atproto::admin::blobView->new(%$_) } @$blobs ];
            $labels     = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) } @$labels ] if defined $labels;
            $indexedAt  = At::Protocol::Timestamp->new( timestamp => $indexedAt )         unless builtin::blessed $indexedAt;
            $moderation = At::Lexicon::com::atproto::admin::moderation->new(%$moderation) unless builtin::blessed $moderation;
            $repo       = At::Lexicon::com::atproto::admin::repoView->new(%$repo)         unless builtin::blessed $repo;
        }

        # perlclass does not have :reader yet
        method uri        {$uri}
        method cid        {$cid}
        method value      {$value}
        method blobs      {$blobs}
        method labels     {$labels}
        method indexedAt  {$indexedAt}
        method moderation {$moderation}
        method repo       {$repo}

        method _raw() {
            +{  uri   => $uri->as_string,
                cid   => $cid,
                value => $value,
                blobs => [ map { $_->_raw } @$blobs ],
                defined $labels ? ( labels => [ map { $_->_raw } @$labels ] ) : (),
                indexedAt  => $indexedAt->_raw,
                moderation => $moderation->_raw,
                repo       => $repo->_raw
            };
        }
    };

    class At::Lexicon::com::atproto::admin::recordViewNotFound 1 {
        field $uri : param;    # at-uri, required
        ADJUST {
            $uri = URI->new($uri) unless builtin::blessed $uri;
        }

        # perlclass does not have :reader yet
        method uri {$uri}

        method _raw() {
            +{ uri => $uri->as_string };
        }
    };

    class At::Lexicon::com::atproto::admin::moderation 1 {
        field $currentAction : param //= ();    # ::actionViewCurrent
        ADJUST {
            $currentAction = At::Lexicon::com::atproto::admin::actionViewCurrent->new(%$currentAction)
                if defined $currentAction && !builtin::blessed $currentAction;
        }

        # perlclass does not have :reader yet
        method currentAction {$currentAction}

        method _raw() {
            +{ defined $currentAction ? ( currentAction => $currentAction->_raw ) : () };
        }
    };

    class At::Lexicon::com::atproto::admin::moderationDetail 1 {
        field $currentAction : param //= ();    # ::actionViewCurrent
        field $actions : param;                 # array, required
        field $reports : param;                 # array, required
        ADJUST {
            $currentAction = At::Lexicon::com::atproto::admin::actionViewCurrent->new(%$currentAction)
                if defined $currentAction && !builtin::blessed $currentAction;
            $actions = [ map { At::Lexicon::com::atproto::admin::actionView->new(%$_) } @$actions ];
            $reports = [ map { At::Lexicon::com::atproto::admin::reportView->new(%$_) } @$reports ];
        }

        # perlclass does not have :reader yet
        method currentAction {$currentAction}
        method actions       {$actions}
        method reports       {$reports}

        method _raw() {
            +{  defined $currentAction ? ( currentAction => $currentAction->_raw ) : (),
                actions => [ map { $_->_raw } @$actions ],
                reports => [ map { $_->_raw } @$reports ]
            };
        }
    };

    class At::Lexicon::com::atproto::admin::blobView 1 {
        field $cid : param;                  # cid, required
        field $mimeType : param;             # string, required
        field $size : param;                 # int, required
        field $createdAt : param;            # datetime, required
        field $details : param    //= ();    # union
        field $moderation : param //= ();    # ::moderation
        ADJUST {
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $details   = At::_topkg( $details->{'$type'} )->new(%$details)
                if defined $details && !builtin::blessed $details && defined $details->{'$type'};
            $moderation = At::Lexicon::com::atproto::admin::moderation->new(%$moderation) if defined $moderation && !builtin::blessed $moderation;
        }

        # perlclass does not have :reader yet
        method cid        {$cid}
        method mimeType   {$mimeType}
        method size       {$size}
        method createdAt  {$createdAt}
        method details    {$details}
        method moderation {$moderation}

        method _raw() {
            +{  cid       => $cid,
                mimeType  => $mimeType->_raw,
                size      => $size,
                createdAt => $createdAt->_raw,
                defined $details ? ( details => $details->_raw ) : (), defined $moderation ? ( moderation => $moderation->_raw ) : ()
            };
        }
    };

    class At::Lexicon::com::atproto::admin::imageDetails 1 {
        field $width : param;     # int, required
        field $height : param;    # int, required

        # perlclass does not have :reader yet
        method width  {$width}
        method height {$height}

        method _raw() {
            +{ witdh => $width, height => $height };
        }
    };

    class At::Lexicon::com::atproto::admin::videoDetails 1 {
        field $width : param;     # int, required
        field $height : param;    # int, required
        field $length : param;    # int, required

        # perlclass does not have :reader yet
        method width  {$width}
        method height {$height}
        method length {$length}

        method _raw() {
            +{ witdh => $width, height => $height, length => $length };
        }
    };

    class At::Lexicon::com::atproto::admin::communicationTemplateView 1 {
        field $id : param;                 # string, required
        field $name : param;               # string, required
        field $subject : param //= ();     # string
        field $contentMarkdown : param;    # string, required
        field $disabled : param;           # bool, required
        field $lastUpdatedBy : param;      # did, required
        field $createdAt : param;          # timestamp, required
        field $updatedAt : param;          # timestamp, required
        ADJUST {
            $lastUpdatedBy = At::Protocol::DID->new( uri => $lastUpdatedBy ) unless builtin::blessed $lastUpdatedBy;
            $createdAt     = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $updatedAt     = At::Protocol::Timestamp->new( timestamp => $updatedAt ) unless builtin::blessed $updatedAt;
        }

        # perlclass does not have :reader yet
        method id              {$id}
        method name            {$name}
        method subject         {$subject}
        method contentMarkdown {$contentMarkdown}
        method disabled        {$disabled}
        method lastUpdatedBy   {$lastUpdatedBy}
        method createdAt       {$createdAt}
        method updatedAt       {$updatedAt}

        method _raw() {
            +{  id   => $id,
                name => $name,
                defined $subject ? ( subject => $subject ) : (),
                contentMarkdown => $contentMarkdown,
                disabled        => \!!$disabled,
                lastUpdatedBy   => $lastUpdatedBy->_raw,
                createdAt       => $createdAt->_raw,
                updatedAt       => $updatedAt->_raw
            };
        }
    };
}
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::com::atproto::admin - Core Admin Classes

=head1 See Also

L<https://atproto.com/>

L<https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/admin/defs.json>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
