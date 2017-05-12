#------------------------------------------------------------------------------------------------------
# OBJET : Module du constructeur CTM::ReadEM::workOnAlarms()
# APPLICATION : Control-M EM + Global Alert Server (GAS)
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 27/05/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::ReadEM::WorkOnAlarms
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::ReadEM::WorkOnAlarms;

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
    return shift->SUPER::_resetAndRefresh(CTM::Base::_alarmsWorkMethod);
}

sub notice {
    return shift->SUPER::_setSerials((caller 0)[3], "UPDATE alarm SET handled = '1'", {
        'handled' => 1
    }, @_);
}

sub unnotice {
    return shift->SUPER::_setSerials((caller 0)[3], "UPDATE alarm SET handled = '0'", {
        'handled' => 0
    }, @_);
}

sub handle {
    return shift->SUPER::_setSerials((caller 0)[3], "UPDATE alarm SET handled = '2'", {
        'handled' => 2
    }, @_);
}

sub unhandle {
    return shift->SUPER::_setSerials((caller 0)[3], "UPDATE alarm SET handled = '1'", {
        'handled' => 1
    }, @_);
}

sub delete {
    return shift->SUPER::_setSerials((caller 0)[3], 'DELETE FROM alarm', {}, @_);
}

sub setSeverity {
    my ($self, $severity, $serialID) = @_;
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$obj->' . $subName, "'R' || 'U' || 'V'"))) unless ($severity eq 'R' || $severity eq 'U' || $severity eq 'V');
    return shift->SUPER::_setSerials($subName, "UPDATE alarm SET severity = '" . $severity . "'", {
        'severity' => $severity
    }, $serialID);
}

sub setNote {
    my ($self, $notes, $serialID) = @_;
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$obj->' . $subName, '$definedNote'))) unless (defined $notes);
    return shift->SUPER::_setSerials($subName, "UPDATE alarm SET notes = '" . $notes . "'", {
        'notes' => $notes
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

CTM::ReadEM::WorkOnAlarms

=head1 SYNOPSIS

Module du constructeur C<CTM::ReadEM::workOnAlarms()>.
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
