#------------------------------------------------------------------------------------------------------
# OBJET : Module du constructeur CTM::ReadEM::WorkOnCurrentBIMServices()
# APPLICATION : Control-M EM + Batch Impact Manager (BIM)
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 22/05/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::ReadEM::WorkOnCurrentBIMServices
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::ReadEM::WorkOnCurrentBIMServices;

use strict;
use warnings;

use base qw/
    CTM::Base
    CTM::Base::SubClass
/;

use Sub::Name qw/
    subname
/;
use Carp qw/
    carp
/;
use String::Util qw/
    crunch
/;
use Hash::Util qw/
    unlock_hash
/;

#----> ** variables de classe **

our $VERSION = 0.181;

#----> ** methodes privees **

my $_getAllViaLogID = subname '_getAllViaLogID' => sub {
    my ($self, $sqlRequest, $logID) = @_;
    my $sth = $self->getParentClass()->_DBI()->prepare($sqlRequest . ' WHERE log_id IN (' . join(', ', ('?') x @{$logID}) . ')');
    $self->getParentClass()->_invokeVerbose((caller 0)[3], "\n" . $sth->{Statement} . "\n");
    if ($sth->execute(@{$logID})) {
        return 1, $sth->fetchall_hashref('log_id');
    } else {
        return 0, 0;
    }
};

#-> methodes liees aux services

my $_getFromRequest = sub {
    my ($self, $childSub, $sqlRequestSelectFrom, $errorType, $logID) = @_;
    $self->_tagAtWork;
    $self->unshiftError();
    if ($self->getParentClass()->isSessionSeemAlive()) {
        $logID = [keys %{$self->getItems()}] unless (ref $logID eq 'ARRAY');
        if (@{$logID}) {
            my ($situation, $hashRefPAlertsJobsForServices) = $self->$_getAllViaLogID($sqlRequestSelectFrom, $logID);
            if ($situation) {
                $self->_tagAtRest;
                return $hashRefPAlertsJobsForServices;
            } else {
                $self->_addError(CTM::Base::_myErrorMessage($childSub, 'erreur lors de la recuperation des ' . $errorType . " : la methode DBI 'execute()' a echouee : '" . $self->getParentClass()->_DBI()->errstr() . "'."));
            }
        } else {
            $self->_tagAtRest;
            return {};
        }
    } else {
        $self->_addError(CTM::Base::_myErrorMessage($childSub, "impossible de continuer car la connexion au SGBD n'est pas active."));
    }
    $self->_tagAtRest;
    return 0;
};

#----> ** methodes publiques **

#-> methodes liees aux services

sub resetAndRefresh {
    return shift->SUPER::_resetAndRefresh(CTM::Base::_currentBIMServicesWorkMethod);
}

sub getAlerts {
    my ($self, $logID) = @_;
    return $self->$_getFromRequest((caller 0)[3], 'SELECT * FROM bim_alert', 'alertes', $logID);
}

sub getProblematicsJobs {
    my ($self, $logID) = @_;
    return $self->$_getFromRequest((caller 0)[3], 'SELECT * FROM bim_prob_jobs', 'jobs en erreur', $logID);
}

#-> Perl BuiltIn

BEGIN {
    *AUTOLOAD = \&CTM::Base::AUTOLOAD;
}

sub DESTROY {
    unlock_hash(%{+shift});
}

#-> END

__END__

=pod

=head1 NOM

CTM::ReadEM::WorkOnCurrentBIMServices

=head1 SYNOPSIS

Module du constructeur C<CTM::ReadEM::WorkOnCurrentBIMServices()>.
Pour plus de details, voir la documention POD de C<CTM>.

=head1 DEPENDANCES DIRECTES

C<CTM::Base>

C<CTM::Base::SubClass>

C<Sub::Name>

C<String::Util>

C<Carp>

C<Hash::Util>

=head1 NOTES

Ce module est dedie au module C<CTM::ReadEM>.

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut
