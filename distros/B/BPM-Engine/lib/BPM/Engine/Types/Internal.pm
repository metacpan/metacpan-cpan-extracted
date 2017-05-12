package BPM::Engine::Types::Internal;
BEGIN {
    $BPM::Engine::Types::Internal::VERSION   = '0.01';
    $BPM::Engine::Types::Internal::AUTHORITY = 'cpan:SITETECH';
    }
## no critic (RequireTidyCode)
use strict;
use warnings;

use MooseX::Types -declare => [qw/
    LibXMLDoc
    Exception
    ConnectInfo
    /];

use MooseX::Types::Moose qw/
    Str HashRef CodeRef Object
    /;

subtype LibXMLDoc,
    as      Object,
    where   { $_->isa('XML::LibXML::Document') },
    message { "Object isn't a XML::LibXML::Document" };

subtype Exception,
    as      Object,
    where   { $_->isa('BPM::Engine::Exception') },
    message { "Object isn't an Exception" };

subtype ConnectInfo,
    as      HashRef,
    where   { exists $_->{dsn} || exists $_->{dbh_maker} },
    message { 'Does not look like a valid connect_info' };

coerce ConnectInfo,
    from Str,      via(\&_coerce_connect_info_from_str),
    from CodeRef,  via { +{ dbh_maker => $_ } };

sub _coerce_connect_info_from_str {
    +{ dsn => $_, user => '', password => '' }
    }

1;
__END__