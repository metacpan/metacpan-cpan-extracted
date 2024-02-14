package At::Lexicon::com::atproto::repo 0.17 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use URI;
    use Carp;
    #
    class At::Lexicon::com::atproto::repo::strongRef 1 {
        field $type : param($type) //= ();    # record field
        field $uri : param;                   # at-uri
        field $cid : param;                   # cid
        ADJUST {
            $uri = URI->new($uri) unless builtin::blessed $uri;
        }

        # perlclass does not have :reader yet
        method uri {$uri}
        method cid {$cid}

        method _raw {
            +{ defined $type ? ( '$type' => $type ) : (), uri => $uri->as_string, cid => $cid };
        }
    };

    class At::Lexicon::com::atproto::repo::applyWrites::create 1 {
        field $type : param($type) = 'com.atproto.repo.applyWrites#create';    # record field
        field $collection : param;                                             # nsid, required
        field $rkey : param;                                                   # string, required, max length: 15
        field $value : param;                                                  # unknown
        ADJUST {
            Carp::confess 'rkey is too long'                       if length $rkey > 15;
            $value = At::_topkg( $value->{'$type'} )->new(%$value) if !builtin::blessed $value && defined $value->{'$type'};
        }

        # perlclass does not have :reader yet
        method collection {$collection}
        method rkey       {$rkey}
        method value      {$value}

        method _raw {
            +{ '$type' => $type, collection => $collection, rkey => $rkey, value => builtin::blessed $value ? $value->_raw : $value };
        }
    };

    class At::Lexicon::com::atproto::repo::applyWrites::update 1 {
        field $type : param($type) = 'com.atproto.repo.applyWrites#update';    # record field
        field $collection : param;                                             # nsid, required
        field $rkey : param;                                                   # string, required
        field $value : param;                                                  # unknown
        ADJUST {
            $value = At::_topkg( $value->{'$type'} )->new(%$value) if !builtin::blessed $value && defined $value->{'$type'};
        }

        # perlclass does not have :reader yet
        method collection {$collection}
        method rkey       {$rkey}
        method value      {$value}

        method _raw {
            +{ '$type' => $type, collection => $collection, rkey => $rkey, value => builtin::blessed $value ? $value->_raw : $value };
        }
    };

    class At::Lexicon::com::atproto::repo::applyWrites::delete 1 {
        field $type : param($type) = 'com.atproto.repo.applyWrites#delete';    # record field
        field $collection : param;                                             # nsid, required
        field $rkey : param;                                                   # string, required

        # perlclass does not have :reader yet
        method collection {$collection}
        method rkey       {$rkey}

        method _raw {
            +{ '$type' => $type, collection => $collection, rkey => $rkey };
        }
    };

    class At::Lexicon::com::atproto::repo::listRecords::record 1 {
        field $uri : param;                                                    # at-uri, required
        field $cid : param;                                                    # cid, required
        field $value : param;                                                  # unknown, required
        ADJUST {
            $uri   = URI->new($uri) unless builtin::blessed $uri;
            $value = At::_topkg( $value->{'$type'} )->new(%$value) if !builtin::blessed $value && defined $value->{'$type'};
        }

        # perlclass does not have :reader yet
        method uri   {$uri}
        method cid   {$cid}
        method value {$value}

        method _raw {
            +{ uri => $uri->as_string, cid => $cid, value => builtin::blessed $value ? $value->_raw : $value };
        }
    };
}
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::com::atproto::repo - Repository Related Classes

=head1 See Also

L<https://atproto.com/>

L<https://github.com/bluesky-social/atproto/blob/main/lexicons/com/atproto/repo/strongRef.json>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
