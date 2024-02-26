package At::Lexicon::com::atproto::sync 0.18 {
    use v5.38;
    use lib '../../../../../lib';
    no warnings 'experimental::class', 'experimental::builtin', 'experimental::try';    # Be quiet.
    use feature 'class', 'try';
    #
    class At::Lexicon::com::atproto::sync::repo 1 {
        field $did : param;     # did, required
        field $head : param;    # cid, required
        field $rev : param;     # string, required
        ADJUST {
            $did = At::Protocol::DID->new( uri => $did ) unless builtin::blessed $did;
        }

        # perlclass does not have :reader yet
        method did  {$did}
        method head {$head}
        method rev  {$rev}

        method _raw() {
            +{ did => $did->_raw, head => $head, rev => $rev };
        }
    };

    class At::Lexicon::com::atproto::sync::commit 1 {
        field $type : param($type);    # field type
        field $seq : param;            # int, required
        field $rebase : param;         # bool, required
        field $tooBig : param;         # bool, required
        field $repo : param;           # did, required
        field $commit : param;         # cid-link, required
        field $prev : param //= ();    # cid-link
        field $rev : param;            # string, required
        field $since : param;          # string, required
        field $blocks : param;         # bytes, required
        field $ops : param;            # array, required
        field $blobs : param;          # array, required
        field $time : param;           # timestamp, required
        ADJUST {
            $repo = At::Protocol::DID->new( uri => $repo ) unless builtin::blessed $repo;
            $ops  = [ map { $_ = At::Lexicon::com::atproto::sync::repoOp->new(%$_) unless builtin::blessed $_ } @$ops ];
            $time = At::Protocol::Timestamp->new( timestamp => $time ) unless builtin::blessed $time;
        }

        # perlclass does not have :reader yet
        method seq    {$seq}
        method rebase {$rebase}
        method tooBig {$tooBig}
        method repo   {$repo}
        method commit {$commit}
        method prev   {$prev}
        method rev    {$rev}
        method since  {$since}
        method blocks {$blocks}
        method ops    {$ops}
        method blobs  {$blobs}
        method time   {$time}

        method _raw() {
            +{  '$type' => $type,
                seq     => $seq,
                rebase  => \!!$rebase,
                tooBig  => \!!$tooBig,
                repo    => $repo->_raw,
                commit  => $commit,
                defined $prev ? ( prev => $prev ) : (),
                rev    => $rev,
                since  => $since,
                blocks => $blocks,
                ops    => [ map { $_->_raw } @$ops ],
                blobs  => $blobs,
                time   => $time->_raw
            };
        }
    };

    class At::Lexicon::com::atproto::sync::handle 1 {
        field $type : param($type);    # field type
        field $seq : param;            # int, required
        field $did : param;            # did, required
        field $handle : param;         # handle, required
        field $time : param;           # timestamp, required
        ADJUST {
            $did    = At::Protocol::DID->new( uri => $did )              unless builtin::blessed $did;
            $handle = At::Protocol::Handle->new( id => $handle )         unless builtin::blessed $handle;
            $time   = At::Protocol::Timestamp->new( timestamp => $time ) unless builtin::blessed $time;
        }

        # perlclass does not have :reader yet
        method seq    {$seq}
        method did    {$did}
        method handle {$handle}
        method time   {$time}

        method _raw() {
            +{ '$type' => $type, seq => $seq, did => $did->_raw, handle => $handle->_raw, time => $time->_raw };
        }
    };

    class At::Lexicon::com::atproto::sync::migrate 1 {
        field $type : param($type);    # field type
        field $seq : param;            # int, required
        field $did : param;            # did, required
        field $migrateTo : param;      # string, required
        field $time : param;           # timestamp, required
        ADJUST {
            $did  = At::Protocol::DID->new( uri => $did )              unless builtin::blessed $did;
            $time = At::Protocol::Timestamp->new( timestamp => $time ) unless builtin::blessed $time;
        }

        # perlclass does not have :reader yet
        method seq       {$seq}
        method did       {$did}
        method migrateTo {$migrateTo}
        method time      {$time}

        method _raw() {
            +{ '$type' => $type, seq => $seq, did => $did->_raw, migrateTo => $migrateTo, time => $time->_raw };
        }
    };

    class At::Lexicon::com::atproto::sync::tombstone 1 {
        field $type : param($type);    # field type
        field $seq : param;            # int, required
        field $did : param;            # did, required
        field $time : param;           # timestamp, required
        ADJUST {
            $did  = At::Protocol::DID->new( uri => $did )              unless builtin::blessed $did;
            $time = At::Protocol::Timestamp->new( timestamp => $time ) unless builtin::blessed $time;
        }

        # perlclass does not have :reader yet
        method seq  {$seq}
        method did  {$did}
        method time {$time}

        method _raw() {
            +{ '$type' => $type, seq => $seq, did => $did->_raw, time => $time->_raw };
        }
    };

    class At::Lexicon::com::atproto::sync::info 1 {
        field $type : param($type);       # field type
        field $name : param;              # string enum, required
        field $message : param //= ();    # string
        ADJUST {
            use Carp;
            Carp::confess 'unknown name' unless $name eq 'OutdatedCursor';
        }

        # perlclass does not have :reader yet
        method name    {$name}
        method message {$message}

        method _raw() {
            +{ '$type' => $type, name => $name, defined $message ? ( message => $message ) : () };
        }
    };

    class At::Lexicon::com::atproto::sync::repoOp 1 {
        field $type : param($type);    # field type
        field $action : param;         # string enum, required
        field $path : param;           # string, required
        field $cid : param;            # cid-link, required
        ADJUST {
            use Carp;
            Carp::confess 'unknown name' unless $action eq 'create' || $action eq 'update' || $action eq 'delete';
        }

        # perlclass does not have :reader yet
        method action {$action}
        method path   {$path}
        method cid    {$cid}

        method _raw() {
            +{ '$type' => $type, action => $action, path => $path, cid => $cid };
        }
    };
}
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::com::atproto::sync - Service Syncronization Classes

=head1 See Also

L<https://atproto.com/>

L<https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/sync/listRepos.json>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=begin stopwords

unwelcoming

=end stopwords

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
