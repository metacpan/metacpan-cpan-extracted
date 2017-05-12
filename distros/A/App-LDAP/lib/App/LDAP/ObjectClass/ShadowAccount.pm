package App::LDAP::ObjectClass::ShadowAccount;

use Modern::Perl;

use Moose;

extends qw(App::LDAP::ObjectClass::Top);

has uid => (
    is       => "rw",
    isa      => "Str",
    required => 1,
);

has userPassword => (
    is  => "rw",
    isa => "Str",
);

has [qw( shadowLastChange
         shadowMin
         shadowMax
         shadowWarning
         shadowInactive
         shadowExpire
         shadowFlag )] => (
    is  => "rw",
    isa => "Num",
);

has description => (
    is  => "rw",
    isa => "Str",
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=pod

=head1 NAME

App::LDAP::ObjectClass::ShadowAccount - schema of shadowAccount

=head1 DEFINITION

    objectclass (
        1.3.6.1.1.1.2.1
        NAME 'shadowAccount'
        DESC 'Additional attributes for shadow passwords'
        SUP top
        AUXILIARY
        MUST uid
        MAY ( userPassword $ shadowLastChange $ shadowMin $
              shadowMax $ shadowWarning $ shadowInactive $
              shadowExpire $ shadowFlag $ description )
    )

=cut

