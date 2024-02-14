package At::Lexicon::com::atproto::server 0.17 {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin';    # Be quiet.
    use feature 'class';
    #
    class At::Lexicon::com::atproto::server::inviteCode {
        field $type : param($type) //= ();    # record field
        field $code : param;                  # string, required
        field $available : param;             # int, required
        field $disabled : param;              # bool, required
        field $forAccount : param;            # string, required
        field $createdBy : param;             # string, required
        field $createdAt : param;             # datetime, required
        field $uses : param;                  # array, required
        ADJUST {
            $disabled  = !!$disabled if builtin::blessed $disabled;
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
            $uses      = [ map { $_ = At::Lexicon::com::atproto::server::inviteCodeUse->new(%$_) unless builtin::blessed $_ } @$uses ];
        }

        # perlclass does not have :reader yet
        method code       {$code}
        method available  {$available}
        method disabled   {$disabled}
        method forAccount {$forAccount}
        method createdBy  {$createdBy}
        method createdAt  {$createdAt}
        method uses       {$uses}

        method _raw {
            +{  defined $type ? ( '$type' => $type ) : (),
                code       => $code,
                available  => \$available,
                disabled   => $disabled,
                forAccount => $forAccount,
                createdBy  => $createdBy,
                uses       => [ map { $_->_raw } @$uses ]
            };
        }
    };

    class At::Lexicon::com::atproto::server::inviteCodeUse {
        field $type : param($type) //= ();    # record field
        field $usedBy : param;                # DID, required
        field $usedAt : param;                # datetime, required
        ADJUST {
            $usedBy = At::Protocol::DID->new( uri => $usedBy )             unless builtin::blessed $usedBy;
            $usedAt = At::Protocol::Timestamp->new( timestamp => $usedAt ) unless builtin::blessed $usedAt;
        }

        # perlclass does not have :reader yet
        method usedBy {$usedBy}
        method usedAt {$usedAt}

        method _raw {
            +{ defined $type ? ( '$type' => $type ) : (), usedBy => $usedBy->_raw, usedAt => $usedAt->_raw };
        }
    };

    class At::Lexicon::com::atproto::server::createInviteCodes::accountCodes {
        field $type : param($type) //= ();    # record field
        field $account : param;               # string, required
        field $codes : param;                 # array, required

        # perlclass does not have :reader yet
        method account {$account}
        method codes   {$codes}

        method _raw {
            +{ defined $type ? ( '$type' => $type ) : (), account => $account, codes => $codes };
        }
    };

    class At::Lexicon::com::atproto::server::createAppPassword::appPassword {
        field $type : param($type) //= ();    # record field
        field $name : param;                  # string, required
        field $password : param;              # string, required
        field $createdAt : param;             # datetime, required
        ADJUST {
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method name      {$name}
        method password  {$password}
        method createdAt {$createdAt}

        method _raw {
            +{ defined $type ? ( '$type' => $type ) : (), name => $name, password => $password, createdAt => $createdAt->_raw };
        }
    };

    class At::Lexicon::com::atproto::server::describeServer::links {
        field $type : param($type)    //= ();    # record field
        field $privacyPolicy : param  //= ();    # string
        field $termsOfService : param //= ();    # string

        # perlclass does not have :reader yet
        method privacyPolicy  {$privacyPolicy}
        method termsOfService {$termsOfService}

        method _raw {
            +{  defined $type           ? ( '$type'        => $type )           : (),
                defined $privacyPolicy  ? ( privacyPolicy  => $privacyPolicy )  : (),
                defined $termsOfService ? ( termsOfService => $termsOfService ) : ()
            };
        }
    };

    class At::Lexicon::com::atproto::server::listAppPasswords::appPassword {
        field $type : param($type) //= ();    # record field
        field $name : param;                  # string, required
        field $createdAt : param;             # datetime, required
        ADJUST {
            $createdAt = At::Protocol::Timestamp->new( timestamp => $createdAt ) unless builtin::blessed $createdAt;
        }

        # perlclass does not have :reader yet
        method name      {$name}
        method createdAt {$createdAt}

        method _raw {
            +{ defined $type ? ( '$type' => $type ) : (), name => $name, createdAt => $createdAt->_raw };
        }
    };
}
1;
__END__

=encoding utf-8

=head1 NAME

At::Lexicon::com::atproto::server - Server Related Classes

=head1 See Also

L<https://atproto.com/>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
