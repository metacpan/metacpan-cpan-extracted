#!/usr/local/bin/perl
# @(#)Functions.pm    1.12

package DBD::TSM::Functions;

use strict;
use warnings;
use Exporter;
use POSIX;
use Carp;

use File::Spec;

use constant DEBUG        => 0;
use constant DEBUG_LEVEL2 => 0;

our $VERSION = 0.12;

##
## Automatically replace during installation
##

use constant TSM_DSMADMC    => 'CHANGE_IT';
use constant TSM_DSMDIR     => 'CHANGE_IT';
use constant TSM_DSMCONFIG  => 'CHANGE_IT';
use Data::Dumper;

our @ISA    = qw(Exporter);
our @EXPORT = qw(tsm_connect tsm_data_sources tsm_execute);

# I do my best effort
sub tsm_choose_dsm_dir {
    if (exists $ENV{DSM_DIR}    and
        -d $ENV{DSM_DIR}        and
        exists $ENV{DSM_CONFIG} and
        -f $ENV{DSM_CONFIG}
        ) {
        my $dsm_config=(-f File::Spec->catfile($ENV{DSM_DIR},"dsm.sys"))?File::Spec->catfile($ENV{DSM_DIR},"dsm.sys"):
                                                                         File::Spec->catfile($ENV{DSM_CONFIG});
        DEBUG && carp "VAR: ", join(", ",$ENV{DSM_DIR}, File::Spec->catfile($ENV{DSM_DIR}, "dsmadmc"), $dsm_config), "\n";

        return ($ENV{DSM_DIR},
                File::Spec->catfile($ENV{DSM_DIR},"dsmadmc"),
                $dsm_config,
                );
    }
    if (-f TSM_DSMADMC   and
        -d TSM_DSMDIR    and
        -f TSM_DSMCONFIG
        ) {
        return (TSM_DSMDIR,TSM_DSMADMC,TSM_DSMCONFIG);
    }

    croak(__PACKAGE__,"->tsm_choose_dsm_dir: Cannot found DSM_DIR, DSMADMC, DSM_CONFIG\n");
    return; #Never here
}

sub _tsm_windows_cmd {
  my @cmd = @_;
  my $cmd;

  foreach my $elt (@cmd) {
    if ($elt =~ m/\s+/) {
      $elt = "\"$elt\"";
    }
    $cmd .= " $elt";
  }

  DEBUG && carp "DEBUG - _tsm_windows_cmd: $cmd\n";

  return $cmd;
}

sub tsm_connect {
    my ($dbh, $dbname, $user, $auth)=@_;

    DEBUG && print "DEBUG - ",__PACKAGE__,"->tsm_connect: ",Dumper(\@_);

    $dbname = uc($dbname);

    my ($dsm_dir, $dsmadmc) = tsm_choose_dsm_dir();
    $ENV{DSM_DIR}           = $ENV{DSM_DIR} || $dsm_dir;

    unless (tsm_data_sources($dbh, $dbname)) {
        $dbh->set_err(1,"Connect: Invalid dbname '$dbname'.");
        return;
    }

    @{$dbh->{tsm_connect}} = (
        $dsmadmc,
        "-servername=$dbname",
        "-id=$user",
        "-password=$auth",
    );

    my @cmd = (
        @{$dbh->{tsm_connect}},
        "-quiet",
        "query status",
    );

    DEBUG && carp "DEBUG:", __PACKAGE__, "->tsm_connect: ", Dumper(\@cmd);

    my $rc_dsmadmc = 0;
    if ($dbh->{tsm_pipe}) {
        my $dsmadmc_h;
        unless (open $dsmadmc_h, '-|', @cmd) {
            $dbh->set_err(1,"Connect: Invalid user id or password '$user/$auth': $rc_dsmadmc/$!.");
            return;
        }
        DEBUG && carp <$dsmadmc_h>;
        close $dsmadmc_h;        
        $rc_dsmadmc = WEXITSTATUS($?);
        DEBUG && carp "DEBUG:", __PACKAGE__, "->tsm_connect: rc=$?, text=$!, rcbis=$rc_dsmadmc";
    } else {
            my $cmd          = _tsm_windows_cmd(@cmd);
            my @query_status = qx($cmd);
            $rc_dsmadmc      = $?;
    }
    
    DEBUG && carp "DEBUG:", __PACKAGE__, "->tsm_connect: rc=", $rc_dsmadmc;

    if ($rc_dsmadmc) {
        $dbh->set_err(1,"Connect: Invalid user id or password '$user/$auth': $rc_dsmadmc/$!.");
        return;
    }

    return 1;
}

sub tsm_data_sources {
    my ($dbh,$data_source)=@_;

    my ($junk1, $junk2, $dsm_sys) = tsm_choose_dsm_dir();

    DEBUG && print "DEBUG - ",__PACKAGE__,"->tsm_data_sources: dsm.sys = $dsm_sys\n";

    unless (-r $dsm_sys) {
        $dbh->DBI::set_err(1,"data sources: could not read file '$dsm_sys'.");
        return;
    }

    my $fh;
    unless (open $fh, '<', $dsm_sys) {
        $dbh->DBI::set_err(1,"data sources: could not open file '$dsm_sys'.");
        return;
    }

    my %data_sources;
    local $_;
    while (<$fh>) {
        chomp;
        DEBUG_LEVEL2 && warn "DEBUG - ", __PACKAGE__,"->tsm_data_sources: ", $_;
        if (my ($server_name) = (m/^\s*[sS][eE]\w*\s+(\S+)/) ) {
            $data_sources{uc($server_name)}++;
        }
    }
    close $fh;

    DEBUG && print "DEBUG - ",__PACKAGE__,"->tsm_data_sources: ",Dumper(\%data_sources);

    if ($data_source) {
        if (exists $data_sources{$data_source}) {
            return 1;
        } else {
            $dbh->DBI::set_err(1,"data sources: could not find data source '$data_source'.");
            return;
        }
    }

    my @data_sources=keys(%data_sources);
    map {s/^/DBI:TSM:/} @data_sources;

    return (@data_sources);
}

sub tsm_execute {
    my ($sth, $statement)=@_;

    DEBUG && print "DEBUG - ",__PACKAGE__,"->tsm_execute: AutoCommit = ",$sth->FETCH('AutoCommit'),"\n";
    my @cmd=@{$sth->{Database}->{tsm_connect}};
    push(@cmd,'-itemcommit') if ($sth->FETCH('AutoCommit'));
    push(@cmd,'-noconfirm','-displaymode=list',$statement);

    DEBUG && print "DEBUG - ",__PACKAGE__,"->tsm_execute: command = \"",join('" "',@cmd),"\"\n";

    # A changer dès que possible pour supporter les grosses tables
    # Bidouille pour windows, à vérifier avec les dernières
    # versions de Perl Windows
    my ($rc_dsmadmc, @raw, $dsmadmc_h, $select_flag);
    if ($sth->{tsm_pipe}) {
      unless (open $dsmadmc_h, '-|', @cmd) {
        $sth->DBI::set_err(1,"Cannot open '@cmd'.\n");
        return;
      }
    } else {
      my $cmd = _tsm_windows_cmd(@cmd);
      unless (open($dsmadmc_h, "$cmd |")) {
        $sth->DBI::set_err(1,"Cannot open '@cmd'.\n");
        return;
      }
    }

    # On ne prend pas que les lignes intéressantes pour un select
    $select_flag++ if ($statement =~ m/select/i or $statement =~ m/^\s*[qQ][uUeErRyY]*\s+/);
    DEBUG && undef $select_flag;

    my $rc=0;
    my $errstr="";

    my (@data, @fields, %fields, $not_first_raw, @values, $begin_data);
    no warnings;

    DEBUG && warn "DEBUG: select_flag = $select_flag\n";

    local $_;
    LINE: while (<$dsmadmc_h>) {
        $errstr .= $_ if m/^[A-Z][A-Z][A-Z]\d\d\d\d[^I]/;

        # On prend tout si ce n'est pas un select
        if (!$select_flag) {
            push @raw, $_;
        }

        if (m/^ANS8002I\s+Highest\s+return\s+code\s+was\s+(-?\d+)./) {
            $rc = $1;
            last LINE;
        }

        # Pas besoin de traitement si ce n'est pas un select
        next LINE if (!$select_flag);

        # Tant que l'on a pas le début, on saute cette partie
        # Le jour ou on utilise dataonly => client ITSM > à 5.3
        # partout
        if (m/ANS8000I/) {
            $begin_data++;
            next LINE;
        }
        next LINE unless ($begin_data);
        # On saute les messages
        next LINE if (m/^\s*AN[SR]/);

        DEBUG && "DEBUG:Inside: $not_first_raw: $_\n";

        if ( my ($field, $value) = (m/\s*([^:]+):\s+(.*)/) ) {
            push @values, $value;

            # Bidouille liée au fait que l'on utilise le style
            # paragraphe (le seul pour avoir le nom des champs)
            next LINE if $not_first_raw;

            # On stocke les champs lors de la première ligne
            if (exists $fields{$field}) {
            # On vérifie le cas des champs dupliqués dans le cas
            # des jointures de table. On met un message
            # Marchait pas avant marche comme ca maintenant, à mettre
            # dans les bugs
                warn "Functions.pm: Duplicate field '$field' !!! Move to 'Dup_$field'.\n";
                $field = 'Dup_' . $field;

            }
            $fields{$field}++;
            push @fields, $field;
            next LINE;
        }

        # Fin d'un paragraphe
        if (m/^\s*$/ and @fields and @values) {
            DEBUG && warn "DEBUG:PARSE:", Dumper(\@fields, \@values);
            if (@values != @fields) {
                # On est dans l'auto debug pour avoir des remontées
                # d'erreur
                warn "Functions.pm: Bad number of values: ",
                     scalar(@values)," for", scalar(@fields),
                     " fields, request line number ", $not_first_raw+1, "\n";
                DEBUG && warn "DEBUG: ", Dumper(\@fields, \@values);
                next LINE;
            }
            $not_first_raw++; # C'est vrai à partir de maintenant

            # Pour pouvoir créer une référence anonyme, obligé
            # de faire une recopie full mémoire : bof mais pas d'autres
            # idées
            my @for_ref = @values;

            push @data, \@for_ref;
            # On réinitialise car on essaye de bosser en push
            @values = ();
        }
    }
    close $dsmadmc_h;
    $rc_dsmadmc = $?;

    # On continue à donner de l'info même en cas d'erreur
    # la partie rawdata peut aider à diagnostiquer la panne
    # Ca sautera un jour car bouffe de la place
    $sth->DBI::set_err($rc, $errstr) if ($rc);

    DEBUG && warn "DEBUG:Execute_data: ", Dumper(\@data, \@fields, \@raw);
    return (\@data, \@fields, \@raw);
}

1;
