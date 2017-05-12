#------------------------------------------------------------------------------------------------------
# OBJET : Module du constructeur CTM::ReadEM::workOnComponents()
# APPLICATION : Control-M EM + Components (CM)
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 10/09/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::ReadEM::WorkOnComponents
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::ReadEM::WorkOnComponents;

use strict;
use warnings;

use base qw/
    CTM::Base
    CTM::Base::SubClass
/;

use Carp qw/
    carp
    croak
/;
use Hash::Util qw/
    unlock_hash
/;

#----> ** variables de classe **

our $VERSION = 0.181;

#----> ** methodes publiques **

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

CTM::ReadEM::WorkOnComponents

=head1 SYNOPSIS

Module du constructeur C<CTM::ReadEM::workOnComponents()>.
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
