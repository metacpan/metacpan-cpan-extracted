#!/usr/bin/env perl
#------------------------------------------------------------------------------------------------------
# OBJET : Exemple d'utilisation de CTM::ReadEM : simple recuperation des services du BIM au format JSON
# APPLICATION : ControlM
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 20/07/2014
#------------------------------------------------------------------------------------------------------
# AIDE :
#   perldoc get_bim_services.pl
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

use warnings;
use strict;

use Getopt::Long;
use File::Basename qw/basename/;
use Try::Tiny;
use JSON;
use CTM::ReadEM 0.181, qw/:all/;

#----> ** fonctions **

sub usage() {
    return 'Aide : perldoc ' . basename($0);
}

#----> ** section principale **

my ($err, $session);

my %opts = (
    x => undef,
    h => undef,
    T => 'Pg',
    p => 5432,
    u => 'root',
    P => 'root',
    i => undef,
    t => 60,
    f => undef,
    V => undef,
);

Getopt::Long::Configure('bundling'); # case sensitive
GetOptions(
    'x=i' => \$opts{x},
    'h=s' => \$opts{h},
    'T=s' => \$opts{T},
    'p=i' => \$opts{p},
    'u=s' => \$opts{u},
    'P=s' => \$opts{P},
    'i=s' => \$opts{i},
    't=i' => \$opts{t},
    'f=s' => \$opts{f},
    'V' => \$opts{V},
    'help' => sub {
        print usage() . "\n";
        exit 0;
    }
) || die usage();

try {
    $session = CTM::ReadEM->new(
        version => $opts{x},
        DBMSType => $opts{T},
        DBMSAddress => $opts{h},
        DBMSPort => $opts{p},
        DBMSInstance => $opts{i},
        DBMSUser => $opts{u},
        DBMSPassword => $opts{P},
        DBMSTimeout => $opts{t},
        verbose => $opts{V}
    );
} catch {
    s/\n//g;
    die $_ . '. ' . usage();
};

$session->connect() || die $session->getError() . '. ' . usage();

my $servicesObj = $session->workOnCurrentBIMServices();

print "\n" if (defined $opts{V});

unless (defined ($err = $session->getError())) {
    if (defined $opts{f}) {
        $servicesObj->keepItemsWithAnd({
            service_name => sub {
                shift =~ $opts{f}
            }
        });
    }
    print JSON->new()->utf8()->pretty()->encode($servicesObj->getItems()) . "\n";
} else {
    die $err;
}

exit 0;

#-> END

__END__

=pod

=head1 NOM

get_bim_services.pl

=head1 SYNOPSIS

Exemple d utilisation de C<CTM::ReadEM> : simple recuperation des services du BIM au format JSON.

=head1 DEPENDANCES

C<Getopt::Long>, C<File::Basename>, C<Try::Tiny>, C<JSON>, C<CTM::ReadEM>

=head1 USAGE

./get_bim_services.pl
    -x <version de Control-M EM>
    -h <serveur>
    [-T <type de SGBD>]
    [-p <port>]
    -u <utilisateur>
    [-P <mot de passe>]
    -i <instance>
    [-t <timeout>]
    [-f <service_name - filtre : regexp>]
    [-V] (verbose)

Pour les valeurs par defaut, voir les valeurs de la table de hachage %opts depuis le code source de ce script.

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut
