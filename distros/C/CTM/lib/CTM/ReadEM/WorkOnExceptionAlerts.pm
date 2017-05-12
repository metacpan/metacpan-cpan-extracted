#------------------------------------------------------------------------------------------------------
# OBJET : Module du constructeur CTM::ReadEM::workOnExceptionAlerts()
# APPLICATION : Control-M EM + Configuration Manager Alarms (CM)
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 27/05/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::ReadEM::WorkOnExceptionAlerts
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::ReadEM::WorkOnExceptionAlerts;

use strict;
use warnings;

use base qw/
    CTM::Base
    CTM::Base::SubClass
/;

use Carp qw/
    croak
/;
use Hash::Util qw/
    unlock_hash
/;

#----> ** variables de classe **

our $VERSION = 0.181;

#----> ** methodes publiques **

sub resetAndRefresh {
    return shift->SUPER::_resetAndRefresh(CTM::Base::_exceptionAlertsWorkMethod);
}

sub handle {
    return shift->SUPER::_setSerials((caller 0)[3], "UPDATE exception_alerts SET status = '2'", {
        'status' => 2
    },  @_);
}

sub unhandle {
    return shift->SUPER::_setSerials((caller 0)[3], "UPDATE exception_alerts SET status = '1'", {
        'status' => 1
    }, @_);
}

sub detete {
    return shift->SUPER::_setSerials((caller 0)[3], 'DELETE FROM exception_alerts', {}, @_);
}

sub setNote {
    my ($self, $note, $serialID) = @_;
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$obj->' . $subName, '$definedNote'))) unless (defined $note);
    return shift->SUPER::_setSerials($subName, "UPDATE exception_alerts SET note = '" . $note . "'", {
        'note' => $note
    }, $serialID);
}

#-> Perl BuiltIn

BEGIN {
    *AUTOLOAD = \&CTM::Base::AUTOLOAD;
}

sub DESTROY {
    unlock_hash(%{+shift});
}

1;

#-> END

__END__

=pod

=head1 NOM

CTM::ReadEM::WorkOnExceptionAlerts

=head1 SYNOPSIS

Module du constructeur C<CTM::ReadEM::workOnExceptionAlerts()>.
Pour plus de details, voir la documention POD de C<CTM>.

=head1 DEPENDANCES DIRECTES

C<CTM::Base>

C<CTM::Base::SubClass>

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
