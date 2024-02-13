package At::Lexicon::com::atproto::label 0.16 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    use Carp;

    class At::Lexicon::com::atproto::label {
        field $src : param;           # DID, required
        field $uri : param;           # URI, required
        field $cid : param //= ();    # CID
        field $val : param;           # string, required, maxlen: 128
        field $neg : param //= ();    # bool
        field $cts : param;           # datetime, required
        ADJUST {
            $src = At::Protocol::DID->new( uri => $src ) unless builtin::blessed $src;
            $uri = URI->new($uri)                        unless builtin::blessed $uri;
            Carp::confess 'val is too long' if length $val > 128;
            $neg = !!$neg if defined $neg && builtin::blessed $neg;
            $cts = At::Protocol::Timestamp->new( timestamp => $cts ) unless builtin::blessed $cts;
        }

        # perlclass does not have :reader yet
        method src {$src}
        method uri {$uri}
        method cid {$cid}
        method val {$val}
        method neg {$neg}
        method cts {$cts}

        method _raw() {
            +{  src => $src->_raw,
                uri => $uri->as_string,
                defined $cid ? ( cid => $cid ) : (),
                val => $val,
                defined $neg ? ( neg => \$neg ) : (), cts => $cts->_raw
            };
        }
    }

    class At::Lexicon::com::atproto::label::selfLabels {
        field $type : param($type) //= ();    # record field
        field $values : param;                # array, required
        ADJUST {
            Carp::croak 'too many labels; max 10' if scalar @$values > 10;
            $values = [ map { $_ = At::Lexicon::com::atproto::label::selfLabel->new( val => $_ ) unless builtin::blessed $_ } @$values ];
        }

        # perlclass does not have :reader yet
        method values {$values}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), values => [ map { $_->_raw } @$values ] };
        }
    }

    class At::Lexicon::com::atproto::label::selfLabel {
        field $type : param($type) //= ();    # record field
        field $val : param;                   # string, required, maxlen: 128
        ADJUST {
            Carp::confess q'val is too long' if length $val > 128;
        }

        # perlclass does not have :reader yet
        method val {$val}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), val => $val };
        }
    }

    class At::Lexicon::com::atproto::label::subscribeLabels::labels {
        field $type : param($type) //= ();    # record field
        field $seq : param;                   # int, required
        field $labels : param;                # array, required
        ADJUST {
            $labels = [ map { $_ = At::Lexicon::com::atproto::label->new(%$_) unless builtin::blessed $_ } @$labels ];
        }

        # perlclass does not have :reader yet
        method seq    {$seq}
        method lables {$labels}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), seq => $seq, labels => [ map { $_->_raw } @$labels ] };
        }
    }

    class At::Lexicon::com::atproto::label::subscribeLabels::info {
        field $type : param($type) //= ();    # record field
        field $name : param;                  # string, required
        field $message : param //= ();        # string
        ADJUST {
            Carp::confess 'unknown name' unless grep { $name eq $_ } qw[OutdatedCursor];
        }

        # perlclass does not have :reader yet
        method name    {$name}
        method message {$message}

        method _raw() {
            +{ defined $type ? ( '$type' => $type ) : (), name => $name, defined $message ? ( message => $message ) : () };
        }
    }
};
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::com::atproto::label - Metadata tag on an atproto resource (eg, repo or record).

=head1 Properties

=over

=item C<cid> - optional

CID specifying the specific version of 'uri' resource this label applies to.

=item C<cts> - required

Timestamp when this label was created.

=item C<neg> - optional

If true, this is a negation label, overwriting a previous label.

=item C<src> - required

DID of the actor who created this label.

=item C<uri> - required

AT URI of the record, repository (account), or other resource that this label applies to.

=item C<val> - required

The short string name of the value or type of this label.

=back

=head1 See Also

https://atproto.com/

https://en.wikipedia.org/wiki/Bluesky_(social_network)

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords atproto eg

=cut
