#------------------------------------------------------------------------------------------------------
# OBJET : Test pour CTM::ReadEM. Instanciation de la classe CTM::ReadEM
# APPLICATION : Control-M
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 20/07/2014
#------------------------------------------------------------------------------------------------------
# AIDE :
#   perldoc 01init.t
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#---> ** initialisation **

use strict;
use warnings;

use Test::More tests => 6;

use Scalar::Util qw/
    blessed
/;

#---> ** section principale **

my ($emSession, $serverSession);

my %params = (
    version => 7,
    DBMSType => 'Pg',
    DBMSAddress => '127.0.0.1',
    DBMSPort => 5432,
    DBMSInstance => 'ctmem',
    DBMSUser => 'root',
    DBMSPassword => 'root'
);

BEGIN {
    use_ok('CTM::ReadEM', ':allFunctions');
    use_ok('CTM::ReadServer', ':allFunctions');
}

eval {
    $emSession = CTM::ReadEM->new(%params);
};

ok( ! $@ && blessed($emSession) eq 'CTM::ReadEM' , 'eval { CTM::ReadEM->new(%params) }; ! $@ && blessed($emSession) eq \'CTM::ReadEM\';');
ok(getNbEMSessionsCreated() == 1, 'getNbEMSessionsCreated() == 1;');

eval {
    $serverSession = CTM::ReadServer->new(%params);
};

ok( ! $@ && blessed($serverSession) eq 'CTM::ReadServer', 'eval { CTM::ReadServer->new(%params) }; ! $@ && blessed($serverSession) eq \'CTM::ReadServer\';');
ok(getNbServerSessionsCreated() == 1, 'getNbServerSessionsCreated() == 1;');

#-> END

__END__

=pod

=head1 NOM

01init.t

=head1 SYNOPSIS

Test pour C<CTM::ReadEM>. Instanciation de la classe C<CTM::ReadEM>.

=head1 DEPENDANCES

C<Test::More>, C<CTM::ReadEM>

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut