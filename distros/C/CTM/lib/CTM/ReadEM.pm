#------------------------------------------------------------------------------------------------------
# OBJET : Consultation de Control-M EM 6/7/8 via son SGBD
# APPLICATION : Control-M EM
# AUTEUR : Yoann Le Garff
# DATE DE CREATION : 17/03/2014
#------------------------------------------------------------------------------------------------------
# USAGE / AIDE
#   perldoc CTM::ReadEM
#------------------------------------------------------------------------------------------------------

#-> BEGIN

#----> ** initialisation **

package CTM::ReadEM;

use strict;
use warnings;

use base qw/
    CTM::Base
    CTM::Base::MainClass
/;

use Exporter::Easy (
    OK => [qw/
        $VERSION
        :ctmFunctions
        :sessionFunctions
        :allFunctions
        :all
        getStatusColorForService
        getSeverityForAlarms
        getSeverityForExceptionAlerts
        getExprForStatusColorForService
        getExprForSeverityForAlarms
        getExprForSeverityForExceptionAlerts
        getNbEMSessionsCreated
        getNbEMSessionsConnected
    /],
    TAGS => [
        ctmFunctions => [qw/
            getStatusColorForService
            getSeverityForAlarms
            getSeverityForExceptionAlerts
            getExprForStatusColorForService
            getExprForSeverityForAlarms
            getExprForSeverityForExceptionAlerts
        /],
        sessionFunctions => [qw/
            getNbEMSessionsCreated
            getNbEMSessionsConnected
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

use CTM::ReadEM::WorkOnCurrentBIMServices 0.18;
use CTM::ReadEM::WorkOnAlarms 0.18;
use CTM::ReadEM::WorkOnExceptionAlerts 0.18;

use Sub::Name qw/
    subname
/;
use Carp qw/
    croak
/;
use String::Util qw/
    crunch
/;
use List::MoreUtils qw/
    uniq
/;
use Hash::Util qw/
    lock_hash
    lock_value
    unlock_value
/;
use Date::Calc 6.0, qw/
    Date_to_Time
/;
use POSIX qw/
    strftime
/;

#----> ** variables de classe **

our $VERSION = 0.181;

my %_emSessionsState = (
    CTM::Base::_nbSessionsInstancedClassProperty => 0,
    CTM::Base::_nbSessionsConnectedClassProperty => 0
);

#----> ** fonctions privees (mais accessibles a l'utilisateur pour celles qui ne sont pas des references) **

sub _calculStartEndDayTimeInPosixTimestamp($$) {
    my ($time, $ctmDailyTime) = @_;
    if ($ctmDailyTime =~ /^(\+|\-)\d{4}$/) {
        my ($ctmDailyHour, $ctmDailyMin) = unpack '(a2)*', substr $ctmDailyTime, 1, 4;
        my ($minNow, $hoursNow, $dayNow, $monthNow, $yearNow) = split /\s+/, strftime('%M %H %d %m %Y', localtime $time);
        my ($previousDay, $previousDayMonth, $previousDayYear) = split /\s+/, strftime('%d %m %Y', localtime $time - 86400);
        my ($nextDay, $nextDayMonth, $nextDayYear) = split /\s+/, strftime('%d %m %Y', localtime $time + 86400);
        my %time;
        if ($hoursNow >= $ctmDailyHour && $minNow >= $ctmDailyMin) {
            $time{start} = Date_to_Time($yearNow, $monthNow, $dayNow, $ctmDailyHour, $ctmDailyMin, 00);
            $time{end} = Date_to_Time($nextDayYear, $nextDayMonth, $nextDay, $ctmDailyHour, $ctmDailyMin, 00);
        } else {
            $time{start} = Date_to_Time($previousDayYear, $previousDayMonth, $previousDay, $ctmDailyHour, $ctmDailyMin, 00);
            $time{end} = Date_to_Time($yearNow, $monthNow, $dayNow, $ctmDailyHour, $ctmDailyMin, 00);
        }
        unless (grep { ! defined } values %time) {
            if ($1 eq '-') {
                $_ += 86400 for (values %time);
            }
            return 1, $time{start}, $time{end};

        } else {
            return 0, 1;
        }
    }
    return 0, 0;
}

#----> ** fonctions publiques **

sub getStatusColorForService($) {
    my $statusTo = shift;
    $statusTo = $statusTo->{status_to} if (ref $statusTo eq 'HASH');
    if (defined $statusTo && $statusTo =~ /^\d+$/) {
        for ($statusTo) {
            $_ == 4 && return 'OK';
            $_ == 8 && return 'Completed OK';
            ($_ >= 16 && $_ < 128) && return 'Error';
            ($_ >= 128 && $_ < 256) && return 'Warning';
            ($_ >= 256) && return 'Completed Late';
        }
    }
    return 0;
}

sub getSeverityForAlarms($) {
    my $severity = shift;
    $severity = $severity->{severity} if (ref $severity eq 'HASH');
    if (defined $severity) {
        for ($severity) {
            $_ eq 'R' && return 'Regular';
            $_ eq 'U' && return 'Urgent';
            $_ eq 'V' && return 'Very Urgent';
        }
    }
    return 0;
}

sub getSeverityForExceptionAlerts($) {
    my $xSeverity = shift;
    $xSeverity = $xSeverity->{xseverity} if (ref $xSeverity eq 'HASH');
    if (defined $xSeverity && $xSeverity =~ /^\d+$/) {
        for ($xSeverity) {
            $_ == 3 && return 'Warning';
            $_ == 2 && return 'Error';
            $_ == 1 && return 'Severe';
        }
    }
    return 0;
}

sub getExprForStatusColorForService($) {
    my ($status, $subName) = (shift, (caller 0)[3]);
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage($subName, '$definedStatus'))) unless (defined $status);
    for ($status) {
        /^OK$/i && return sub {
            shift == 4
        };
        /^Completed OK$/i && return sub {
            shift == 8
        };
        /^Error$/i && return sub {
            $_[0] >= 16 && $_[0] < 128
        };
        /^Warning$/i && return sub {
            $_[0] >= 128 && $_[0] < 256
        };
        /^Completed Late$/i && return sub {
            shift > 256
        };
    }
    return sub {
        shift =~ //
    };
}

sub getExprForSeverityForAlarms($) {
    my ($severity, $subName) = (shift, (caller 0)[3]);
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage($subName, '$definedSeverity'))) unless (defined $severity);
    for ($severity) {
        /^Regular$/i && return sub {
            shift eq 'R'
        };
        /^Urgent$/i && return sub {
            shift eq 'U'
        };
        /^Very Urgent$/i && return sub {
            shift eq 'V'
        };
    }
    return sub {
        shift =~ //
    };
}

sub getExprForSeverityForExceptionAlerts($) {
    my ($severity, $subName) = (shift, (caller 0)[3]);
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage($subName, '$definedSeverity'))) unless (defined $severity);
    for ($severity) {
        /^Warning$/i && return sub {
            shift == 3
        };
        /^Error$/i  && return sub {
            shift == 2
        };
        /^Severe$/i  && return sub {
            shift == 1
        };
    }
    return sub {
        shift =~ //
    };
}

sub getNbEMSessionsCreated {
    return $_emSessionsState{CTM::Base::_nbSessionsInstancedClassProperty};
}

sub getNbEMSessionsConnected {
    return $_emSessionsState{CTM::Base::_nbSessionsConnectedClassProperty};
}

#----> ** methodes privees **

#-> constructeurs/destructeurs

my $_subClassConstructor = sub {
    my ($self, $subClassLastName, $baseMethod, %params) = @_;
    my $subSelf = {};
    $subSelf->{CTM::Base::_rootClassEMPrivate} = $self;
    $subSelf->{CTM::Base::_workingObjProperty} = 0;
    $subSelf->{CTM::Base::_errorsObjProperty} = [];
    $subSelf->{CTM::Base::_paramsObjProperty} = \%params;
    $subSelf->{CTM::Base::_subClassDatasObjProperty} = $self->$baseMethod(%params);
    return bless $subSelf, __PACKAGE__ . '::' . $subClassLastName;
};

#-> directement liees aux actions sur le SGBD

my $_getDatasCentersDownloadInfos = subname '_getDatasCentersDownloadInfos' => sub {
    my $self = shift;
    my $sth = $self->_DBI()->prepare(<<SQL);
SELECT d.data_center, d.netname, TO_CHAR(t.dt, 'YYYY/MM/DD HH:MI:SS') AS download_time_to_char, c.ctm_daily_time
FROM comm c, (
    SELECT data_center, MAX(download_time) AS dt
    FROM download
    GROUP by data_center
) t JOIN download d ON d.data_center = t.data_center AND t.dt = d.download_time
WHERE c.data_center = d.data_center
AND c.enabled = '1';
SQL
    $self->_invokeVerbose((caller 0)[3], "\n" . $sth->{Statement} . "\n");
    if ($sth->execute()) {
        my $hashRef = $sth->fetchall_hashref('data_center');
        for (values %{$hashRef}) {
            ($_->{active_net_table_name} = $_->{netname}) =~ s/[^\d]//g;
            $_->{active_net_table_name} = 'a' . $_->{active_net_table_name} . '_ajob';
        }
        return 1, $hashRef;
    } else {
        return 0, crunch($self->_DBI()->errstr());
    }
};

my $_getCurrentBIMServices = subname 'getCurrentBIMServices' => sub {
    my ($self, $datacenterInfos, $matching, $deleteFlag, $forLastNetName, $serviceStatus, $forDataCenters) = @_;
    if (%{$datacenterInfos}) {
        my $sqlRequest = <<SQL;
SELECT *, TO_CHAR(order_time, 'YYYY/MM/DD HH:MI:SS') AS order_time_to_char
FROM bim_log
WHERE log_id IN (
    SELECT MAX(log_id)
    FROM bim_log
    GROUP BY order_id
)
AND service_name LIKE ?
AND order_id IN (
SQL
        $sqlRequest .= join("\n    UNION\n", map { '    SELECT order_id FROM ' . $_->{active_net_table_name} . " WHERE appl_type = 'BIM'" . ($deleteFlag ? " AND delete_flag = '0'" : '') } values %{$datacenterInfos}) . "\n)\n";
        if ($forLastNetName) {
            $sqlRequest .= "AND active_net_name IN ('" . join("', '", map { $_->{netname} } values %{$datacenterInfos}) . "')\n";
        }
        if (ref $serviceStatus eq 'ARRAY' && @{$serviceStatus}) {
            $sqlRequest .= 'AND (' . join(' OR ', map {
                if ($_ eq 'OK') {
                    "status_to = '4'";
                } elsif ($_ eq 'Completed_OK') {
                    "status_to = '8'";
                } elsif ($_ eq 'Error') {
                    "(status_to >= '16' AND status_to < '128')";
                } elsif ($_ eq 'Warning') {
                    "(status_to >= '128' AND status_to < '256')";
                } elsif ($_ eq 'Completed_Late') {
                    "status_to >= '256'";
                }
            } uniq(@{$serviceStatus})) . ")\n";
        }
        my $forDataCentersProcess = ref $forDataCenters eq 'ARRAY' && @{$forDataCenters};
        my @forDataCentersUniq = $forDataCentersProcess ? uniq(@{$forDataCenters}) : ();
        if ($forDataCentersProcess) {
            $sqlRequest .= 'AND data_center IN (' . join(', ', ('?') x @forDataCentersUniq) . ")\n";
        }
        my $sth = $self->_DBI()->prepare($sqlRequest . "ORDER BY service_name;\n");
        $self->_invokeVerbose((caller 0)[3], "\n" . $sth->{Statement} . "\n");
        if ($sth->execute($matching, @forDataCentersUniq)) {
            return 1, $sth->fetchall_hashref('log_id');
        } else {
            return 0, crunch($sth->errstr());
        }
    }
    return 0, undef;
};

my $_getAlarms = subname 'getAlarms' => sub {
    my ($self, $matching, $severity, $timeSort) = @_;
    my $sqlRequest = <<SQL;
SELECT *, TO_CHAR(upd_time, 'YYYY/MM/DD HH:MI:SS') AS upd_time_to_char
FROM alarm
WHERE message LIKE ?
SQL
    if (ref $severity eq 'ARRAY' && @{$severity}) {
        $sqlRequest .= 'AND (' . join(' OR ', map {
            if ($_ eq 'Regular') {
                "severity = 'R'";
            } elsif ($_ eq 'Urgent') {
                "severity = 'U'";
            } elsif ($_ eq 'Very_Urgent') {
                "severity = 'V'";
            }
        } uniq(@{$severity})) . ")\n";
    }
    my $sth = $self->_DBI()->prepare($sqlRequest . 'ORDER BY upd_time ' . $timeSort . ";\n");
    $self->_invokeVerbose((caller 0)[3], "\n" . $sth->{Statement} . "\n");
    if ($sth->execute($matching)) {
        my $hashRef = $sth->fetchall_hashref('serial');
        return 1, $hashRef;
    } else {
        return 0, crunch($self->_DBI()->errstr());
    }
};

my $_getExceptionAlerts = subname 'getExceptionAlerts' => sub {
    my ($self, $matching, $severity, $timeSort) = @_;
    my $sqlRequest = <<SQL;
SELECT *, TO_CHAR(xtime, 'YYYY/MM/DD HH:MI:SS') AS xtime_to_char, TO_CHAR(xtime_of_last, 'YYYY/MM/DD HH:MI:SS') AS xtime_of_last_to_char
FROM exception_alerts
WHERE message LIKE ?
SQL
    if (ref $severity eq 'ARRAY' && @{$severity}) {
        $sqlRequest .= 'AND (' . join(' OR ', map {
            if ($_ eq 'Warning') {
                "xseverity = '3'";
            } elsif ($_ eq 'Error') {
                "xseverity = '2'";
            } elsif ($_ eq 'Severe') {
                "xseverity = '1'";
            }
        } uniq(@{$severity})) . ")\n";
    }
    my $sth = $self->_DBI()->prepare($sqlRequest . 'ORDER BY xtime ' . $timeSort . ";\n");
    $self->_invokeVerbose((caller 0)[3], "\n" . $sth->{Statement} . "\n");
    if ($sth->execute($matching)) {
        my $hashRef = $sth->fetchall_hashref('serial');
        return 1, $hashRef;
    } else {
        return 0, crunch($self->_DBI()->errstr());
    }
};

#----> ** methodes publiques **

#-> wrappers de constructeurs/destructeurs

sub new {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my $self = shift->SUPER::_new(@_);
    lock_hash(%{$self});
    $_emSessionsState{CTM::Base::_nbSessionsInstancedClassProperty}++;
    return $self;
}

*newSession = \&new;

sub connect {
    my $self = shift;
    unlock_value(%{$self}, CTM::Base::_DBIObjProperty);
    my $return = $self->SUPER::_connect(qw/
        download
        bim_log
        bim_prob_jobs
        bim_alert
        comm
        alarm
        exception_alerts
    /);
    lock_value(%{$self}, CTM::Base::_DBIObjProperty);
    $_emSessionsState{CTM::Base::_nbSessionsConnectedClassProperty}++ if ($self->isSessionSeemAlive());
    return $return;
}

*connectToDB = \&connect;

sub disconnect {
    my $self = shift;
    unlock_value(%{$self}, CTM::Base::_DBIObjProperty);
    my $return = $self->_disconnect();
    lock_value(%{$self}, CTM::Base::_DBIObjProperty);
    $_emSessionsState{CTM::Base::_nbSessionsConnectedClassProperty}-- unless ($self->isSessionSeemAlive());
    return $return;
}

*disconnectFromDB = \&disconnect;

#-> methodes liees aux services du BIM (BIM)

sub getCurrentBIMServices {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my ($self, %params) = @_;
    $self->unshiftError();
    if ($self->isSessionSeemAlive()) {
        my ($situation, $datacenterInfos) = $self->$_getDatasCentersDownloadInfos();
        if ($situation) {
            my $time = time;
            for my $datacenter (keys %{$datacenterInfos}) {
                ($situation, my $datacenterOdateStart, my $datacenterOdateEnd) = _calculStartEndDayTimeInPosixTimestamp($time, $datacenterInfos->{$datacenter}->{ctm_daily_time});
                if ($situation) {
                    if (defined (my $downloadTimeInTimestamp = Date_to_Time(split /[\/:\s]+/, $datacenterInfos->{$datacenter}->{download_time_to_char}))) {
                        delete $datacenterInfos->{$datacenter} unless ($downloadTimeInTimestamp >= $datacenterOdateStart && $downloadTimeInTimestamp <= $datacenterOdateEnd);
                    } else {
                        $self->_addError(CTM::Base::_myErrorMessage($subName, "le champ 'download_time_to_char' qui derive de la cle 'download_time' (DATETIME) via la fonction SQL TO_CHAR() (Control-M '" . $datacenterInfos->{$datacenter}->{service_name} . "') n'est pas correct ou n'est pas gere par le module. Il est possible que la base de donnees du Control-M EM soit corrompue ou que la version renseignee (version '" . $self->{_version} . "') ne soit pas correcte."));
                        return 0;
                    }
                } else {
                    if ($datacenterOdateStart) {
                        $self->_addError(CTM::Base::_myErrorMessage($subName, "une erreur a eu lieu lors de la generation du timestamp POSIX pour la date de debut et de fin de la derniere montee au plan."));
                    } else {
                        $self->_addError(CTM::Base::_myErrorMessage($subName, "le champ 'ctm_daily_time' du datacenter '" . $datacenterInfos->{$datacenter}->{data_center} . "' n'est pas correct " . '(=~ /^[\+\-]\d{4}$/).'));
                    }
                    return 0;
                }
            }
            ($situation, my $servicesDatas) = $self->$_getCurrentBIMServices($datacenterInfos, defined $params{matching} ? $params{matching} : '%', defined $params{handleDeletedJobs} ? $params{handleDeletedJobs} : 1, defined $params{forLastNetName} ? $params{forLastNetName} : 0, defined $params{forStatus} ? $params{forStatus} : 0, defined $params{forDataCenters} ? $params{forDataCenters} : 0);
            unless ($situation) {
                if (defined $servicesDatas) {
                    $self->_addError(CTM::Base::_myErrorMessage($subName, "erreur lors de la recuperation des services du BIM : la methode DBI 'execute()' a echoue : '" . $servicesDatas . "'."));
                    return 0;
                } else {
                    return {};
                }
            }
            return $servicesDatas;
        } else {
            $self->_addError(CTM::Base::_myErrorMessage($subName, "erreur lors de la recuperation des informations a propos des Control-M Server : la methode DBI 'execute()' a echoue : '" . $datacenterInfos . "'."));
        }
    } else {
       $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de continuer car la connexion au SGBD n'est pas active."));
    }
    return 0;
}

sub workOnCurrentBIMServices {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my $self = shift->$_subClassConstructor(CTM::Base::_currentBIMServicesModuleLastName, CTM::Base::_currentBIMServicesBaseMethod, @_);
    lock_hash(%{$self});
    return $self;
}

#-> methodes liees aux alarmes (GAS)

sub getAlarms {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my ($self, %params) = @_;
    $self->unshiftError();
    if ($self->isSessionSeemAlive()) {
        my ($situation, $alarmsData) = $self->$_getAlarms(defined $params{matching} ? $params{matching} : '%', defined $params{severity} ? $params{severity} : 0, defined $params{timeSort} && $params{timeSort} =~ /^(ASC|DESC)$/i ? $params{timeSort} : 'ASC');
        if ($situation) {
            return $alarmsData;
        } else {
            $self->_addError(CTM::Base::_myErrorMessage($subName, "erreur lors de la recuperation des informations a propos des exceptions : la methode DBI 'execute()' a echoue : '" . $alarmsData . "'."));
        }
    } else {
        $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de continuer car la connexion au SGBD n'est pas active."));
    }
    return 0;
}

sub workOnAlarms {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my $self = shift->$_subClassConstructor(CTM::Base::_alarmsModuleLastName, CTM::Base::_alarmsBaseMethod, @_);
    lock_hash(%{$self});
    return $self;
}

#-> methodes liees aux exceptions (CM)

sub getExceptionAlerts {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my ($self, %params) = @_;
    $self->unshiftError();
    if ($self->isSessionSeemAlive()) {
        my ($situation, $exceptionAlertsDatas) = $self->$_getExceptionAlerts(defined $params{matching} ? $params{matching} : '%', defined $params{severity} ? $params{severity} : 0, defined $params{timeSort} && $params{timeSort} =~ /^(ASC|DESC)$/i ? $params{timeSort} : 'ASC');
        if ($situation) {
            return $exceptionAlertsDatas;
        } else {
            $self->_addError(CTM::Base::_myErrorMessage($subName, "erreur lors de la recuperation des informations a propos des exceptions : la methode DBI 'execute()' a echoue : '" . $exceptionAlertsDatas . "'."));
        }
    } else {
        $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de continuer car la connexion au SGBD n'est pas active."));
    }
    return 0;
}

sub workOnExceptionAlerts {
    my $subName = (caller 0)[3];
    croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    my $self = shift->$_subClassConstructor(CTM::Base::_exceptionAlertsModuleLastName, CTM::Base::_exceptionAlertsBaseMethod, @_);
    lock_hash(%{$self});
    return $self;
}

#-> methodes liees aux composants (CM)

# sub getComponents {
    # my $subName = (caller 0)[3];
    # croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    # my ($self, %params) = @_;
    # $self->unshiftError();
    # if ($self->isSessionSeemAlive()) {
        # my ($situation, $exceptionAlertsDatas) = $self->$_getComponents());
        # if ($situation) {
            # return $exceptionAlertsDatas;
        # } else {
            # $self->_addError(CTM::Base::_myErrorMessage($subName, "erreur lors de la recuperation des informations a propos des composants : la methode DBI 'execute()' a echoue : '" . $exceptionAlertsDatas . "'."));
        # }
    # } else {
        # $self->_addError(CTM::Base::_myErrorMessage($subName, "impossible de continuer car la connexion au SGBD n'est pas active."));
    # }
    # return 0;
# }

# sub workOnComponents {
    # my $subName = (caller 0)[3];
    # croak(CTM::Base::_myErrorMessage($subName, CTM::Base::_myUsageMessage('$session->' . $subName, "'cle' => 'valeur'"))) unless (@_ % 2);
    # my $self = shift->$_subClassConstructor(CTM::Base::_componentsModuleLastName, CTM::Base::_componentsBaseMethod, @_);
    # lock_hash(%{$self});
    # return $self;
# }

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
    $self->disconnect();
    $_emSessionsState{CTM::Base::_nbSessionsInstancedClassProperty}--;
}

1;

#-> END

__END__

=pod

=head1 NOM

CTM::ReadEM - Consultation de Control-M EM 6/7/8 a travers son SGBD.

=head1 SYNOPSIS

    use CTM::ReadEM qw/:functions/;

    my $session = CTM::ReadEM->new(
        version => 7,
        DBMSType => "Pg",
        DBMSAddress => "127.0.0.1",
        DBMSPort => 3306,
        DBMSInstance => "ctmem",
        DBMSUser => "root",
        DBMSPassword => "root"
    );

    $session->connect() || die $session->getError();

    my $workOnServices = $session->workOnCurrentBIMServices();

    unless (defined ($err = $session->getError())) {
        $workOnServices->keepItemsWithAnd({
            service_name => sub {
                shift =~ /^SVC_HEADER_/
            }
        });
        print $_->{service_name} . " : " . getStatusColorForService($_) . "\n" for (values %{$workOnServices->getItems()});
    } else {
        die $err;
    }

=head1 DEPENDANCES DIRECTES

C<CTM::Base>

C<CTM::Base::MainClass>

C<CTM::ReadEM::workOnCurrentBIMServices>

C<CTM::ReadEM::WorkOnAlarms>

C<CTM::ReadEM::WorkOnExceptionAlerts>

C<Sub::Name>

C<Carp>

C<String::Util>

C<List::MoreUtils>

C<Hash::Util>

C<Exporter::Easy>

C<Date::Calc>

C<POSIX>

=head1 TAGS (C<CTM::ReadEM>)

=head2 :all

Importe C<$VERSION> et les fonctions publiques listees au lien suivant : L<"FONCTIONS PUBLIQUES (importables depuis CTM::ReadEM)">.

=head2 :allFunctions

Importe les fonctions publiques listees au lien suivant : L<"FONCTIONS PUBLIQUES (importables depuis CTM::ReadEM)">.

=head2 :sessionFunctions

Importe les fonctions publiques listees au lien suivant : L<"getNbSession*()">.

=head2 :ctmFunctions

Importe les fonctions publiques listees au lien suivant : L<"... liees a la generation ou au traduction d'informations en rapport avec BIM, GAS ou EA">.

=head1 METHODES PUBLIQUES (C<CTM::ReadEM>)

=head2 my $session = CTM::ReadEM->new()

Cette methode est le constructeur du module C<CTM::ReadEM>. C<CTM::ReadEM-E<gt>newSession()> est un equivalent.

    my $session = CTM::ReadEM->new(
        version => 7,
        DBMSType => "Pg",
        DBMSAddress => "127.0.0.1",
        DBMSPort => 3306,
        DBMSInstance => "ctmem",
        DBMSUser => "root",
        DBMSPassword => "root"
    );

la liste des parametres du constructeur sont listes au lien suivant : L<"PROPRIETES PUBLIQUES (CTM::ReadEM)">.

Pour information, le destructeur C<DESTROY()> est appele lorsque toutes les references a l'objet instancie ont ete detruites (C<undef $session;> par exemple).

Retourne toujours un objet.

=head2 $session->connect()

Permet de se connecter a la base du Control-M EM avec les parametres fournis au constructeur C<CTM::ReadEM-E<gt>new)>. C<CTM::ReadEM-E<gt>connectToDB()> est un equivalent.

    $session->connect() || die $session->getError();

Retourne 1 si la connexion a reussi sinon 0.

=head2 $session->disconnect()

Permet de se deconnecter de la base du Control-M EM mais elle n'apelle pas le destructeur C<DESTROY()>.  C<CTM::ReadEM-E<gt>disconnectFromDB()> est un equivalent.

    $session->disconnect() || warn $session->getError();

Retourne 1 si la connexion a reussi sinon 0.

=head2 $session->getCurrentBIMServices() - BIM

Retourne une reference de la table de hachage de la liste des services en cours dans le BIM.

    my $hashRef = $session->getCurrentBIMServices(
        matching => '%',
        forStatus => [qw/OK/]
    );

Un filtre est disponible avec le parametre "matching" (SQL C<LIKE> clause).

Le parametre "forLastNetName" accepte un booleen. Si il est vrai alors cette methode ne retournera que les services avec la derniere ODATE. Faux par defaut.

Le parametre "handleDeletedJobs" accepte un booleen. Si il est vrai alors cette methode ne retournera que les services (jobs de type "BIM") qui n'ont pas ete supprimes du plan. Vrai par defaut.

Le parametre "forStatus" doit etre une reference d'un tableau. Si c'est le cas, la methode ne retournera que les services avec les statuts renseignes (statuts valides (sensibles a la case) : "OK", "Completed_OK", "Completed_Late", "Warning", "Error") dans ce tableau.

Le parametre "forDataCenters" doit etre une reference d'un tableau. Si c'est le cas, la methode ne retournera que les services pour les datacenters renseignes.

La cle de cette table de hachage est "log_id".

Retourne 0 si la methode a echouee.

=head2 my $workOnServices = $session->workOnCurrentBIMServices() - (BIM)

Derive de la methode C<$session-E<gt>getCurrentBIMServices()>, elle "herite" donc de ses parametres.

    my $workOnServices = $session->workOnCurrentBIMServices(
        matching => 'A%'
    );

Retourne toujours un objet.

Fonctionne de la meme maniere que la methode C<$session-E<gt>getCurrentBIMServices()> mais elle est surtout le constructeur du module C<CTM::ReadEM::workOnCurrentBIMServices> qui met a disposition les methodes (BIM) suivantes :

=head3 $workOnServices->getParentClass()

Retourne l'objet (de la classe C<CTM::ReadEM>) via lequel C<$workOnServices> a ete instancie. Par exemple, ceci fonctionne :

    $workOnServices->getParentClass()->disconnect();

=head3 $workOnServices->getParams()

Retourne une reference de la table de hachage de la liste des parametres utilisateur de l'objet C<$workOnServices>.

=head3 $workOnServices->countItems()

Retourne le nombre de services pour l'objet C<$workOnServices>.

=head3 $workOnServices->getItems()

Retourne une reference de la table de hachage de la liste des services de l'objet C<$workOnServices>.

=head3 $workOnServices->resetAndRefresh()

Rafraichi l objet C<$workOnServices> avec les parametres passes lors de la creation de l'objet C<$workOnServices>.

Retourne 1 si le rafraichissement a fonctionne ou 0 si celui-ci a echoue.

=head3 $workOnServices->clone()

Retourne un clone complet de l'objet.

=head3 $workOnServices->keepItemsWithAnd({})

Retourne toujours un objet. L'objet retourne est le meme que celui sur lequel cette methode est invoquee.

    $workOnServices->keepItemsWithAnd({
        timestamp => getExprForStatusColorForService('OK')
    });

Cette methode permet de filtrer les items (de l'objet) a conserver en opposant a un ou plusieurs champs de chacuns des items une reference de fonction passee. Toutes les tests sur les champs doivent etre positifs pour que l'item soit conserve sur l'objet.

=head3 $workOnServices->keepItemsWithOr({})

Retourne toujours un objet. L'objet retourne est le meme que celui sur lequel cette methode est invoquee.

Cette methode permet de filtrer les items (de l'objet) a conserver en opposant a un ou plusieurs champs de chacuns des items une reference de fonction passee. Un test de champ minimum doit etre positif pour que l'item soit conserve sur l'objet.

=head3 $workOnServices->getProblematicsJobs()

Retourne une reference vers une table de hachage qui contient la liste des jobs Control-M problematiques pour chaque "log_id" (accepte une reference de tableau de "log_id" en parametre sinon utilise les "log_id" de l'objet).

Retourne 0 si la methode a echouee.

=head3 $workOnServices->getAlerts()

Retourne une reference vers une table de hachage qui contient la liste des alertes pour chaque "log_id" (accepte une reference de tableau de "log_id" en parametre sinon utilise les "log_id" de l'objet).

Retourne 0 si la methode a echouee.

=head2 $session->getAlarms() - (GAS)

Retourne une reference de la table de hachage de la liste des alarmes en cours dans le GAS.

    my $hashRef = $session->getAlarms(
        severity => 'Regular'
    );

Un filtre est disponible sur le message des alarmes avec le parametre "matching" (SQL C<LIKE> clause).

Le parametre "severity" doit etre une reference d'un tableau. Si c'est le cas, la methode ne retournera que les alarmes avec les pour les severites renseignees (severites valides (sensibles a la case) : "Regular", "Urgent", "Very_Urgent") dans ce tableau.

Le parametre "timeSort" : SQL C<ORDER BY> . Il trie les donnees renvoyees de maniere ascendante (SQL C<ASC> (insensible a la case)) ou descendante (SQL C<DESC> (insensible a la case)) sur la date de l'alerte.

La cle de cette table de hachage est "serial".

Retourne 0 si la methode a echouee.

=head2 my $workOnAlarms = $session->workOnAlarms() - (GAS)

Derive de la methode C<$session-E<gt>getAlarms()>, elle "herite" donc de ses parametres.

    my $workOnAlarms = $session->workOnAlarms(
        severity => 'Urgent'
    );

Retourne toujours un objet.

Fonctionne de la meme maniere que la methode C<$session-E<gt>getAlarms()> mais elle est surtout le constructeur du module C<CTM::ReadEM::WorkOnAlarms> qui met a disposition les methodes (GAS) suivantes :

=head3 $workOnAlarms->getParentClass()

Retourne l'objet (de la classe C<CTM::ReadEM>) via lequel C<$workOnAlarms> a ete instancie. Par exemple, ceci fonctionne :

    $workOnAlarms->getParentClass()->disconnect();

=head3 $workOnAlarms->getParams()

Retourne une reference de la table de hachage de la liste des parametres utilisateur de l'objet C<$workOnAlarms>.

=head3 $workOnAlarms->countItems()

Retourne le nombre d'alarmes pour l'objet C<$workOnAlarms>.

=head3 $workOnAlarms->getItems()

Retourne une reference de la table de hachage de la liste des alarmes de l'objet C<$workOnAlarms>.

=head3 $workOnAlarms->resetAndRefresh()

Rafraichi l objet C<$workOnAlarms> avec les parametres passes lors de la creation de l'objet C<$workOnAlarms>.

Retourne 1 si le rafraichissement a fonctionne ou 0 si celui-ci a echoue.

=head3 $workOnAlarms->clone()

Retourne un clone complet de l'objet.

=head3 $workOnAlarms->keepItemsWithAnd({})

Retourne toujours un objet. L'objet retourne est le meme que celui sur lequel cette methode est invoquee.

    $workOnAlarms->keepItemsWithAnd({
        severity => getExprForSeverityForAlarms('Regular')
    });

Cette methode permet de filtrer les items (de l'objet) a conserver en opposant a un ou plusieurs champs de chacuns des items une reference de fonction passee. Toutes les tests sur les champs doivent etre positifs pour que l'item soit conserve sur l'objet.

=head3 $workOnAlarms->keepItemsWithOr({})

Retourne toujours un objet. L'objet retourne est le meme que celui sur lequel cette methode est invoquee.

Cette methode permet de filtrer les items (de l'objet) a conserver en opposant a un ou plusieurs champs de chacuns des items une reference de fonction passee. Un test de champ minimum doit etre positif pour que l'item soit conserve sur l'objet.

=head3 $workOnAlarms->notice(\@array_ref_of_id)

Notifie la ou les alarmes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnAlarms->unnotice(\@array_ref_of_id)

Denotifie la ou les alarmes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnAlarms->handle(\@array_ref_of_id)

Prend en compte la ou les alarmes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnAlarms->unhandle(\@array_ref_of_id)

Annule la prise en compte du ou des alarmes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnAlarms->delete(\@array_ref_of_id)

Supprime la ou les alarmes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnAlarms->setSeverity($severity, \@array_ref_of_id)

Modifie la severite du ou des alarmes. Les valeurs possibles sont 'R' (Regular), 'U' (Urgent) et 'V' (Very Urgent).

    $workOnAlarms->setSeverity('R');

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnAlarms->setNote($note, \@array_ref_of_id)

La note de ou des alarmes est egale a C<$note>.

    $workOnAlarms->setNote('Ces alarmes sont prises en compte.');

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alarmes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head2 $session->getExceptionAlerts() - (EA)

Retourne une reference de la table de hachage de la liste des alertes en cours dans l'EA.

    my $hashRef = $session->getExceptionAlerts(
        severity => 'Severe'
    );

Un filtre est disponible sur le message des alertes avec le parametre "matching" (SQL C<LIKE> clause).

Le parametre "severity" doit etre une reference d'un tableau. Si c'est le cas, la methode ne retournera que les alertes avec les pour les severites renseignees (severites valides (sensibles a la case) : "Warning", "Error", "Severe") dans ce tableau.

Le parametre "timeSort" : SQL C<ORDER BY> . Il trie les donnees renvoyees de maniere ascendante (SQL C<ASC> (insensible a la case)) ou descendante (SQL C<DESC> (insensible a la case)) sur la date de l'alerte.

La cle de cette table de hachage est "serial".

Retourne 0 si la methode a echouee.

=head2 my $workOnExceptionAlerts = $session->workOnExceptionAlerts() - (EA)

Derive de la methode C<$session-E<gt>getExceptionAlerts()>, elle "herite" donc de ses parametres.

    my $workOnExceptionAlerts = $session->workOnExceptionAlerts(
        severity => 'Severe'
    );

Retourne toujours un objet.

Fonctionne de la meme maniere que la methode C<$session-E<gt>getExceptionAlerts()> mais elle est surtout le constructeur du module C<CTM::ReadEM::WorkOnExceptionAlerts> qui met a disposition les methodes (EA) suivantes :

=head3 $workOnExceptionAlerts->getParentClass()

Retourne l'objet (de la classe C<CTM::ReadEM>) via lequel C<$workOnExceptionAlerts> a ete instancie. Par exemple, ceci fonctionne :

    $workOnExceptionAlerts->getParentClass()->disconnect();

=head3 $workOnExceptionAlerts->getParams()

Retourne une reference de la table de hachage de la liste des parametres utilisateur de l'objet C<$workOnExceptionAlerts>.

=head3 $workOnExceptionAlerts->countItems()

Retourne le nombre d'alertes pour l'objet C<$workOnExceptionAlerts>.

=head3 $workOnExceptionAlerts->getItems()

Retourne une reference de la table de hachage de la liste des alertes de l'objet C<$workOnExceptionAlerts>.

=head3 $workOnExceptionAlerts->resetAndRefresh()

Rafraichi l objet C<$workOnExceptionAlerts> avec les parametres passes lors de la creation de l'objet C<$workOnExceptionAlerts>.

Retourne 1 si le rafraichissement a fonctionne ou 0 si celui-ci a echoue.

=head3 $workOnExceptionAlerts->clone()

Retourne un clone complet de l'objet.

=head3 $workOnExceptionAlerts->keepItemsWithAnd({})

Retourne toujours un objet. L'objet retourne est le meme que celui sur lequel cette methode est invoquee.

    $workOnExceptionAlerts->keepItemsWithAnd({
        severity => getExprForSeverityForExceptionAlerts('Severe')
    });

Cette methode permet de filtrer les items (de l'objet) a conserver en opposant a un ou plusieurs champs de chacuns des items une reference de fonction passee. Toutes les tests sur les champs doivent etre positifs pour que l'item soit conserve sur l'objet.

=head3 $workOnExceptionAlerts->keepItemsWithOr({})

Retourne toujours un objet. L'objet retourne est le meme que celui sur lequel cette methode est invoquee.

Cette methode permet de filtrer les items (de l'objet) a conserver en opposant a un ou plusieurs champs de chacuns des items une reference de fonction passee. Un test de champ minimum doit etre positif pour que l'item soit conserve sur l'objet.

=head3 $workOnExceptionAlerts->handle(\@array_ref_of_id)

Prend en compte la ou les alertes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alertes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnExceptionAlerts->unhandle(\@array_ref_of_id)

Annule la prise en compte d'une ou des alertes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alertes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnExceptionAlerts->detete(\@array_ref_of_id)

Supprime la ou les alertes.

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alertes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head3 $workOnExceptionAlerts->setNote($note, \@array_ref_of_id)

La note d'une ou des alertes est egale a C<$note>.

    $workOnExceptionAlerts->setNote('Ces alertes sont prises en compte.');

Une reference vers un tableau d'ID ('serial') peut etre passee (mais PAS obligatoire, dans quel cas la methode s'appliquera au elements attaches a l'objet en parametre afin de filtrer les alertes a traiter.

Retourne 1 si l'operation a fonctionnee sinon 0.

=head2 $session->isSessionAlive()

Verifie et retourne l'etat de la connexion au SGBD.

B<ATTENTION>, n'est pas fiable pour tous les types de SGBD (pour plus de details, voir http://search.cpan.org/dist/DBI/DBI.pm#ping et les implementation de cette methode dans les drivers utilises par DBI (par exemple, http://search.cpan.org/~turnstep/DBD-Pg-3.4.2/Pg.pm#ping)).

=head2 $session->isSessionSeemAlive()

Retourne l'etat (booleen) de la connexion a la base du Control-M EM telle qu'elle devrait etre.

=head1 PROPRIETES PUBLIQUES (C<CTM::ReadEM>)

=head2 $session->{DBMSType}

Type de SGBD du Control-M EM auquel se connecter.

Les valeurs acceptees sont "Pg", "Oracle", "mysql", "Sybase" et "ODBC". Pour une connexion a MS SQL Server, les drivers "Sybase" et "ODBC" fonctionnent.

=head2 $session->{DBMSAddress}

Adresse du SGBD du Control-M EM auquel se connecter.

=head2 $session->{DBMSPort}

Port du SGBD du Control-M EM auquel se connecter.

=head2 $session->{DBMSInstance}

Instance (ou base) du SGBD du Control-M EM auquel se connecter.

=head2 $session->{DBMSUser}

Utilisateur du SGBD du Control-M EM auquel se connecter.

=head2 $session->{DBMSPassword}

Mot de passe du SGBD du Control-M EM auquel se connecter.

=head2 $session->{$DBMSConnectTimeout}

Timeout (en seconde) de la tentavive de connexion au SGBD du Control-M EM.

La valeur 0 signifie qu aucun timeout ne sera applique.

B<ATTENTION>, cette propriete risque de ne pas fonctionner sous Windows (ou sur d'autres OS ne gerant pas les signaux UNIX).

=head2 $session->{verbose}

Active la verbose du module, affiche les requetes SQL executees sur STDERR.

Ce parametre accepte un booleen. Faux par defaut.

=head1 FONCTIONS PUBLIQUES (importables depuis C<CTM::ReadEM>)

=head2 getNbSession*()

=head3 getNbEMSessionsCreated()

Retourne le nombre d instances en cours pour le module C<CTM::ReadEM>.

=head3 getNbEMSessionsConnected()

Retourne le nombre d instances en cours et connectees a la base du Control-M EM pour le module C<CTM::ReadEM>.

=head2 ... liees a la generation ou au traduction d'informations en rapport avec BIM, GAS ou EA

=head3 getStatusColorForService() - (BIM)

Cette fonction permet de convertir le champ "status_to" de la table de hachage generee par la methode C<getCurrentBIMServices()> (et ses derives) en un statut lisible ("OK", "Completed OK", "Completed Late", "Warning", "Error").

Retourne 0 si la valeur du parametre fourni n'est pas reconnu.

=head3 getSeverityForAlarms() - (GAS)

Cette fonction permet de convertir le champ "status_to" de la table de hachage generee par la methode C<getAlarms()> (et ses derives) en un statut lisible ("Regular", "Urgent", "Very_Urgent").

Retourne 0 si la valeur du parametre fourni n'est pas reconnu.

=head3 getSeverityForExceptionAlerts() - (EA)

Cette fonction permet de convertir le champ "status_to" de la table de hachage generee par la methode C<getExceptionAlerts()> (et ses derives) en un statut lisible ("Warning", "Error", "Severe").

Retourne 0 si la valeur du parametre fourni n'est pas reconnu.

=head3 getExprForStatusColorForService() - (BIM)

Cette fonction converti les statuts "OK", "Completed OK", "Completed Late", "Warning", et "Error" (valeurs possibles en parametre) en une reference de fonction (pouvant notamment etre utilisee par les methodes keepItemsWithAnd() et keepItemsWithOr()).

Retourne une reference vers la fonction anonyme sub { shift =~ // } si le statut fourni est inconnu.

=head3 getExprForSeverityForAlarms() - (GAS)

Cette fonction converti les severites "Regular", "Urgent" et "Very_Urgent" (valeurs possibles en parametre) en une reference de fonction (pouvant notamment etre utilisee par les methodes keepItemsWithAnd() et keepItemsWithOr()).

Retourne une reference vers la fonction anonyme sub { shift =~ // } si la severite fourni est inconnu.

=head3 getExprForSeverityForExceptionAlerts() - (EA)

Cette fonction converti les severites "Warning", "Error" et "Severe" (valeurs possibles en parametre) en une reference de fonction (pouvant notamment etre utilisee par les methodes keepItemsWithAnd() et keepItemsWithOr()).

Retourne une reference vers la fonction anonyme sub { shift =~ // } si le severites fourni est inconnu.

=head1 METHODES PUBLIQUES (*)

=head2 $obj->getProperty($propertyName)

Retourne la valeur de la propriete C<$propertyName>.

    my $DBMSPassword = $session->getProperty('getProperty');

Leve une exception (C<carp()>) si celle-ci n'existe pas et retourne 0.

=head2 $obj->setPublicProperty($propertyName, $value)

Remplace la valeur de la propriete publique C<$propertyName> par C<$value>.

    if ($session->setPublicProperty('verbose', 1)) {
        print "Verbose activee.\n";
        $session->getCurrentBIMServices(); # affiche les requetes SQL utilisees sur STDERR

        $session->setPublicProperty('verbose', 0) && print "Verbose desactivee.\n";
        $session->getCurrentBIMServices(); # n'affiche rien sur STDERR
    }

Retourne 1 si la valeur de la propriete a ete modifiee.

Leve une exception (C<carp()>) si c'est une propriete privee ou si celle-ci n'existe pas et retourne 0.

=head2 $obj->getError($item)

Retourne l'erreur a l'element C<$item> (0 par defaut, donc la derniere erreur generee) du tableau de la reference reserve au stockage des erreurs.

    printf "Derniere erreur pour ma session : %s\n", $session->getError();
    printf "Derniere erreur sur mon objet BIM : %s\n", $workOnServices->getError();

Retourne C<undef> si il n'y a pas d'erreur ou si la derniere a ete decalee via la methode C<$obj-E<gt>unshiftError()>.

Une partie des erreurs sont gerees via le module Carp et ses deux fonctions C<croak> et C<carp> (notamment le fait de ne pas correctement utiliser les methodes/fonctions)).

=head2 $obj->getErrors()

Retourne la reference du tableau reserve au stockage des erreurs.

=head2 $obj->countErrors

Retourne le nombre d'erreurs generees (et non-decalee via la methode C<$obj-E<gt>unshiftError()>) pour l'objet C<$obj>.

=head2 $obj->unshiftError()

Decale la valeur de la derniere erreur et la remplace par C<undef>.

Retourne toujours 1.

Cette methode est appelee avant l'execution de la plupart des accesseurs/mutateurs.

=head2 $obj->clearErrors()

Nettoie toutes les erreurs.

Retourne toujours 1.

=head1 EXEMPLES

=head2 Initialiser une session

    use CTM::ReadEM qw/:functions/;

    my $session1 = CTM::ReadEM->new(
        version => 7,
        DBMSType => "Pg",
        DBMSAddress => "127.0.0.1",
        DBMSPort => 3306,
        DBMSInstance => "ctmem",
        DBMSUser => "root",
        DBMSPassword => "root"
    );

    print getNbEMSessionsCreated(); # affiche "1"

=head2 Recupere et affiche la liste des services actuellement en cours dans le BIM du Control-M EM

    # [...]

    $session->connect() || die $session->getError();

    my $servicesHashRef = $session->getCurrentBIMServices();

    unless (defined ($err = $session->getError())) {
        printf "%s : %s\n", $_->{service_name}, getStatusColorForService($_) for (values %{$servicesHashRef});
    } else {
        die $err;
    }

=head1 LEXIQUE

- I<CTM> : BMC Control-M.

- I<Control-M EM> : BMC Control-M Enterprise Manager.

- I<BIM> : BMC Batch Impact Manager.

- I<GAS> : BMC Global Alert Server.

- I<CM> : BMC Control-M Configuration Manager.


=head1 QUELQUES REMARQUES ...

- Ce module se base en partie sur l'heure du systeme qui le charge. Si celle ci est fausse, certains resultats le seront aussi.

- Ce module est surtout dedie a la consultation depuis Control-M EM et certains de ses composants mais certaines methodes permettant d'exploiter Control-M EM (par exemple les methodes C<handle()> ou C<delete()>). Cependant, ces actions ne seront pas forcement immediatement visibles depuis la GUI de Control-M EM.

- Les elements prefixes de "_" sont proteges ou prives et ne doivent pas etre manipules par l'utilisateur. Ces donnees sont "verouillees" via Hash::Util pour eviter toutes fausses manipulations.

- Certaines fonctions normalements privees sont disponibles pour l'utilisateur mais ne sont pas documentees et peuvent etre fatales (pas forcement de prototypage, pas de gestion des exceptions, etc, ...).

- "oldschool" pour le moment, les versions 0.21 et + de ces modules se baseront sur Moose.

=head1 LIENS

- Depot GitHub : http://github.com/le-garff-yoann/CTM

=head1 AUTEUR

Le Garff Yoann <pe.weeble@yahoo.fr>

=head1 LICENCE

Voir licence Perl.

=cut
