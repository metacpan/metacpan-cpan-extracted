#------------------------------------------------------------------------------------------------------
# OBJET : Introduction a la documentation des modules CTM::*.
# APPLICATION : Control-M
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 01/10/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM;

use strict;
use warnings;

use base qw/
    CTM::Base
/;

use CTM::ReadServer;
use CTM::ReadEM;

#----> ** variables de classe **

our $VERSION = 0.181;

#----> Perl BuiltIn

BEGIN {
    *AUTOLOAD = \&CTM::Base::AUTOLOAD;
}

1;

#-> END

__END__

=pod

=head1 NOM

CTM - Introduction a la documentation des modules C<CTM::*>.

=head1 SYNOPSIS

    use CTM::ReadEM;
    use CTM::ReadServer;

    my $ctmEmSession = CTM::ReadEM->new(
        version => 7,
        DBMSType => "Pg",
        DBMSAddress => "127.0.0.1",
        DBMSPort => 3306,
        DBMSInstance => "ctmem",
        DBMSUser => "root",
        DBMSPassword => "root"
    );

    my $ctmServerSession = CTM::ReadServer->new(
        version => 7,
        DBMSType => "Pg",
        DBMSAddress => "127.0.0.1",
        DBMSPort => 3306,
        DBMSInstance => "ctmserver",
        DBMSUser => "root",
        DBMSPassword => "root"
    );

=head1 DEPENDANCES DIRECTES

C<CTM::Base>

C<CTM::ReadEM>

C<CTM::ReadServer>

=head1 NOTES

Pour plus d'informations se referer a la POD des modules L<CTM::ReadEM> et L<CTM::ReadServer>.

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut