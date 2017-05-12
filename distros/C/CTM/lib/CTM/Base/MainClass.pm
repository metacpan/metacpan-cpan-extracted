#------------------------------------------------------------------------------------------------------
# OBJET : "Classe abstraite" des modules CTM::ReadEM et CTM::ReadServer
# APPLICATION : Control-M
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 01/10/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::Base::MainClass
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::Base::MainClass;

use strict;
use warnings;

use base qw/
    CTM::Base
/;

use Carp qw/
    carp
    croak
/;
use String::Util qw/
    hascontent
    crunch
/;
use Scalar::Util qw/
    blessed
/;
use POSIX qw/
    :signal_h
/;
use Try::Tiny;
use Perl::OSType qw/
    is_os_type
/;
use DBI;

#----> ** variables de classe **

our $VERSION = 0.181;

#----> ** methodes privees **

#-> wrappers methodes DBI

my $_doesTablesExists = sub {
    my ($self, @tablesName) = @_;
    my @inexistingSQLTables;
    for (@tablesName) {
        my $sth = $self->_DBI()->table_info(undef, 'public', $_, 'TABLE');
        if ($sth->execute()) {
            push @inexistingSQLTables, $_ unless ($sth->fetchrow_array());
        } else {
            return 0, crunch($self->_DBI()->errstr());
        }
    }
    return 1, \@inexistingSQLTables;
};

#----> ** methodes protegees **

#-> constructeurs/destructeurs

sub _new {
    my ($class, %params) = @_;
    my $subName = (caller 0)[3];
    if (caller->isa(__PACKAGE__)) {
        my $self = {};
        if (defined $params{version} && defined $params{DBMSType} && defined $params{DBMSAddress} && defined $params{DBMSPort} && defined $params{DBMSInstance} && defined $params{DBMSUser}) {
            $self->{_version} = $params{version};
            $self->{DBMSType} = $params{DBMSType};
            $self->{DBMSAddress} = $params{DBMSAddress};
            $self->{DBMSPort} = $params{DBMSPort};
            $self->{DBMSInstance} = $params{DBMSInstance};
            $self->{DBMSUser} = $params{DBMSUser};
            $self->{DBMSPassword} = exists $params{DBMSPassword} ? $params{DBMSPassword} : undef;
            $self->{DBMSConnectTimeout} = $params{DBMSConnectTimeout} || 0;
            $self->{CTM::Base::_verboseObjProperty} = $params{CTM::Base::_verboseObjProperty} || 0;
        } else {
            croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage($subName, "<un ou plusieurs parametres obligatoires n'ont pas ete renseignes>")));
        }
        $self->{CTM::Base::_workingObjProperty} = 0;
        $self->{CTM::Base::_errorsObjProperty} = [];
        $self->{CTM::Base::_DBIObjProperty} = undef;
        $self->{CTM::Base::_sessionIsConnectedObjProperty} = 0;
        $class = ref $class || $class;
        return bless $self, $class;
    } else {
        carp(_myErrorMessage($subName, "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
};

sub _connect {
    my ($subName, $self, @tablesToTest) = ((caller 0)[3], @_);
    if (caller->isa(__PACKAGE__)) {
        $self->unshiftError();
        if (defined $self->{_version} && $self->{_version} =~ /^[678]$/ && defined $self->{DBMSType} && $self->{DBMSType} =~ /^(Pg|Oracle|mysql|Sybase|ODBC)$/ && hascontent($self->{DBMSAddress}) && defined $self->{DBMSPort} && $self->{DBMSPort} =~ /^\d+$/ && $self->{DBMSPort} >= 0 && $self->{DBMSPort} <= 65535 && defined hascontent($self->{DBMSInstance}) && hascontent($self->{DBMSUser}) && defined $self->{DBMSConnectTimeout} && $self->{DBMSConnectTimeout} =~ /^\d+$/) {
            unless ($self->isSessionSeemAlive()) {
                if (eval 'require DBD::' . $self->{DBMSType}) {
                    my $myOSIsUnix = is_os_type('Unix', 'dragonfly');
                    my $ALRMDieSub = sub {
                        die "'DBI' : impossible de se connecter (timeout atteint) a la base '" . $self->{DBMSType} . ", instance '" .  $self->{DBMSInstance} . "' du serveur '" .  $self->{DBMSType} . "'.";
                    };
                    my $oldaction;
                    if ($myOSIsUnix) {
                        my $mask = POSIX::SigSet->new(SIGALRM);
                        my $action = POSIX::SigAction->new(
                            \&$ALRMDieSub,
                            $mask
                        );
                        $oldaction = POSIX::SigAction->new();
                        sigaction(SIGALRM, $action, $oldaction);
                    } else {
                        local $SIG{ALRM} = \&$ALRMDieSub;
                    }
                    try {
                        my $connectionString = 'dbi:' . $self->{DBMSType};
                        if ($self->{DBMSType} eq 'ODBC') {
                            $connectionString .= ':driver={SQL Server};server=' . $self->{DBMSAddress} . ',' . $self->{DBMSPort} . ';database=' . $self->{DBMSInstance};
                        } else {
                            $connectionString .= ':host=' . $self->{DBMSAddress} . ';database=' . $self->{DBMSInstance} . ';port=' . $self->{DBMSPort};
                        }
                        alarm $self->{DBMSConnectTimeout};
                        $self->{CTM::Base::_DBIObjProperty} = DBI->connect(
                            $connectionString,
                            $self->{DBMSUser},
                            $self->{DBMSPassword},
                            {
                                RaiseError => 0,
                                PrintError => 0,
                                AutoCommit => 1
                            }
                        );
                        $self->_addError(CTM::Base::_myErrorMessage($subName, "'DBI' : '" . crunch($DBI::errstr) . "'.")) if (defined $DBI::errstr);
                    } catch {
                        $self->_addError(CTM::Base::_myErrorMessage($subName, $_));
                    } finally {
                        alarm 0;
                        sigaction(SIGALRM, $oldaction) if ($myOSIsUnix);
                    };
                    unless (defined $self->getError()) {
                        my ($situation, $inexistingSQLTables) = $self->$_doesTablesExists(@tablesToTest);
                        if ($situation) {
                            unless (@{$inexistingSQLTables}) {
                                $self->_tagSessionAsConnected();
                                return 1;
                            } else {
                                $self->_addError(CTM::Base::_myErrorMessage($subName, "la connexion au SGBD est etablie mais il manque une ou plusieurs tables ('" . join("', '", @{$inexistingSQLTables}) . "') qui sont requises ."));
                            }
                        } else {
                            $self->_addError(CTM::Base::_myErrorMessage($subName, "la connexion est etablie mais la methode DBI 'execute()' a echouee : '" . $inexistingSQLTables . "'."));
                        }
                    }
                } else {
                    $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de charger le module 'DBD::" . $self->{DBMSType} . "' : '" . crunch($@) . "'. Les drivers disponibles sont '" . $self->_DBI()->available_drivers() . "'."));
                }
            } else {
                $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de se connecter car cette instance est deja connectee."));
            }
        } else {
            croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage($subName, "<un ou plusieurs parametres ne sont pas valides>")));
        }
    } else {
        carp(_myErrorMessage($subName, "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
};

sub _disconnect {
    my ($self, $subName) = (shift, (caller 0)[3]);
    if (caller->isa(__PACKAGE__)) {
        $self->unshiftError();
        if ($self->isSessionSeemAlive()) {
            if ($self->_DBI()->disconnect()) {
                $self->_tagSessionAsDisconnected();
                return 1;
            } else {
                $self->_addError(CTM::Base::_myErrorMessage($subName, 'DBI : ' . crunch($self->_DBI()->errstr())));
            }
        } else {
            $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de clore la connexion car cette instance n'est pas connectee."));
        }
    } else {
        carp(_myErrorMessage($subName, "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
};

#-> accesseurs/mutateurs

sub _DBI {
    my ($self, $property, $value) = @_;
    if (caller->isa(__PACKAGE__)) {
        return $self->{CTM::Base::_DBIObjProperty}
    } else {
        carp(_myErrorMessage((caller 0)[3], "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
}

sub _tagSessionAsConnected {
    my ($self, $property, $value) = @_;
    if (caller->isa(__PACKAGE__)) {
        return $self->_setObjProperty(CTM::Base::_sessionIsConnectedObjProperty, 1);
    } else {
        carp(_myErrorMessage((caller 0)[3], "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
}

sub _tagSessionAsDisconnected {
    my ($self, $property, $value) = @_;
    if (caller->isa(__PACKAGE__)) {
        return $self->_setObjProperty(CTM::Base::_sessionIsConnectedObjProperty, 0);
    } else {
        carp(_myErrorMessage((caller 0)[3], "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
}

sub _isSessionAlive {
    my ($self, $subName) = (shift, (caller 0)[3]);
    if (caller->isa(__PACKAGE__)) {
        $self->unshiftError();
        if ($self->isSessionSeemAlive()) {
            return $self->_DBI()->ping();
        } else {
            $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de tester l'etat de la connexion au SGBD car celle ci n'est pas active."));
        }
    } else {
        carp(_myErrorMessage($subName, "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
}

sub _isSessionSeemAlive {
    my $self = shift;
    if (caller->isa(__PACKAGE__)) {
        return blessed($self->_DBI()) && $self->_DBI()->isa('DBI::db') && $self->{CTM::Base::_sessionIsConnectedObjProperty};
    } else {
        carp(_myErrorMessage((caller 0)[3], "tentative d'utilisation d'une methode protegee."));
    }
    return 0;
}

#-> Perl BuiltIn

BEGIN {
    *AUTOLOAD = \&CTM::Base::AUTOLOAD;
}

1;

#-> END

__END__

=pod

=head1 NOM

CTM::Base::MainClass

=head1 SYNOPSIS

"Classe abstraite" des modules C<CTM::ReadEM> et C<CTM::ReadServer>.

Pour plus de details, voir la documention POD de C<CTM>.

=head1 DEPENDANCES DIRECTES

C<CTM::Base>

C<Carp>

C<String::Util>

C<Scalar::Util>

C<Try::Tiny>

C<Perl::OSType>

C<DBI>

C<DBD::?>

=head1 NOTES

Ce module est dedie aux modules C<CTM::ReadEM> et C<CTM::ReadServer>.

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut
