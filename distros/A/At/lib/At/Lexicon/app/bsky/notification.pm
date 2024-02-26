package At::Lexicon::app::bsky::notification 0.18 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use bytes;
    our @CARP_NOT;
    #
    # from app.bsky.notification.listNotifications
    class At::Lexicon::app::bsky::notification {
        field $uri : param;       # at-url, required
        field $cid : param;       # cid, required
        field $author : param;    # app.bsky.actor.defs#profileView, required

        # Expected values are 'like', 'repost', 'follow', 'mention', 'reply', and 'quote'.
        field $reason : param;                  # string, enum, required
        field $reasonSubject : param //= ();    # at-uri
        field $record : param;                  # unknown in spec, required
        field $isRead : param;                  # bool, required
        field $indexedAt : param;               # datetime, required
        field $labels : param //= ();           # array of com.atproto.label.defs#label
        ADJUST {
            use Carp;
            $indexedAt     = At::Protocol::Timestamp->new( timestamp => $indexedAt ) unless builtin::blessed $indexedAt;
            $uri           = URI->new($uri)                                          unless builtin::blessed $uri;
            $reasonSubject = URI->new($reasonSubject)                                unless builtin::blessed $reasonSubject;
            Carp::cluck q[reason is an unknown value] unless grep { $reason eq $_ } qw[like repost follow mention reply quote];
            $labels = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) unless builtin::blessed $_ } @$labels ] if defined $labels;
            $author = At::Lexicon::app::bsky::actor::profileView->new(%$author) unless builtin::blessed $author;
        }

        # perlclass does not have :reader yet
        method indexedAt     {$indexedAt}
        method record        {$record}
        method uri           {$uri}
        method reasonSubject {$reasonSubject}
        method reason        {$reason}
        method labels        {$labels}
        method cid           {$cid}
        method author        {$author}
        method isRead        {$isRead}

        method _raw() {
            +{  indexedAt     => $indexedAt->_raw,
                record        => $record,
                uri           => $uri->as_string,
                reasonSubject => $reasonSubject->as_string,
                reason        => $reason,
                labels        => [ map { $_->_raw } @$labels ],
                cid           => $cid,
                author        => $author->_raw,
                isRead        => \!!$isRead,
            };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::app::bsky::notification - Notification

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
