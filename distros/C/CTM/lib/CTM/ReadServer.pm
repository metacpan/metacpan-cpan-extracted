#------------------------------------------------------------------------------------------------------
# OBJET : Consultation de Control-M Server 6/7/8 via son SGBD
# APPLICATION : Control-M Server
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 01/10/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::ReadServer
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::ReadServer;

use strict;
use warnings;

use base qw/
    CTM::Base
    CTM::Base::MainClass
/;

use Exporter::Easy (
    OK => [qw/
        getNbServerSessionsCreated
        getNbServerSessionsConnected
    /],
    TAGS => [
        ctmFunctions => [qw/
        /],
        sessionFunctions => [qw/
            getNbServerSessionsCreated
            getNbServerSessionsConnected
        /],
        allFunctions => [qw/
            :ctmFunctions
            :sessionFunctions
        /],
        all => [qw/
            $VERSION
            :allFunctions
        /]
    ]
);

use Sub::Name qw/
    subname
/;
use Carp qw/
    croak
/;
use String::Util qw/
    crunch
/;
use Hash::Util qw/
    lock_hash
    lock_value
    unlock_value
/;

#----> ** variables de classe **

our $VERSION = 0.181;

my %_serverSessionsState = (
    CTM::Base::_nbSessionsInstancedClassProperty => 0,
    CTM::Base::_nbSessionsConnectedClassProperty => 0
);

#----> ** fonctions publiques **

sub getNbServerSessionsCreated {
    return $_serverSessionsState{CTM::Base::_nbSessionsInstancedClassProperty};
}

sub getNbServerSessionsConnected {
    return $_serverSessionsState{CTM::Base::_nbSessionsConnectedClassProperty};
}

#----> ** methodes publiques **

#-> wrappers de constructeurs/destructeurs

sub new {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my $self = shift->SUPER::_new(@_);
    lock_hash(%{$self});
    $_serverSessionsState{CTM::Base::_nbSessionsInstancedClassProperty}++;
    return $self;
}

*newSession = \&new;

#-> accesseurs/mutateurs

sub isSessionAlive {
    return shift->SUPER::_isSessionAlive();
}

sub isSessionSeemAlive {
    return shift->SUPER::_isSessionSeemAlive()
}

#-> Perl BuiltIn

BEGIN {
    *AUTOLOAD = \&CTM::Base::AUTOLOAD;
}

sub DESTROY {
    my $self = shift;
    # $self->disconnect();
    $_serverSessionsState{CTM::Base::_nbSessionsInstancedClassProperty}--;
}

1;

#-> END

__END__

=pod

=head1 NOM

CTM::ReadServer - Consultation de Control-M Server 6/7/8 via son SGBD.

=head1 SYNOPSIS

    A venir ...

=head1 DEPENDANCES DIRECTES

C<CTM::Base>

C<CTM::Base::MainClass>

C<Exporter::Easy>

C<Sub::Name>

C<Carp>

C<String::Util>

C<Hash::Util>

=head1 NOTES

Documentation a venir ...

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut