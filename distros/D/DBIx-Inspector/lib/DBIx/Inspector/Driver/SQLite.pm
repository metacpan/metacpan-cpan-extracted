package DBIx::Inspector::Driver::SQLite;
use strict;
use warnings;
use utf8;
use base qw/DBIx::Inspector::Driver::Base/;

sub foreign_keys {
    my ($self, @args) = @_;

    local *DBD::SQLite::db::foreign_key_info = \&_dbd_sqlite_foreign_key_info_monkey_patch;
    return $self->SUPER::foreign_keys(@args);
}

sub table_infoall_arrayref {
    my $dbh = shift;
    my $sth = $dbh->table_info(@_) or return [];
    $dbh->selectall_arrayref( $sth, { Columns => {} } ) or [];
}

sub _dbd_sqlite_foreign_key_info_monkey_patch {
    my($dbh, $pkcat, $pkschem, $pktable, $fkcat, $fkschem, $fktable) = @_;

    my $sth = $dbh->table_info(undef, $fkschem, $fktable || '%', 'TABLE') or return;

    my @dbi_fk_info;
    while (my $table = $sth->fetchrow_hashref()) {
        next if $table->{TABLE_NAME} =~ /\Asqlite_/;
        next unless (!defined $fktable) || $fktable eq '%' || $fktable eq $table->{TABLE_NAME};

        local $dbh->{FetchHashKeyName} = 'NAME_lc';
        my $sth = $dbh->prepare(sprintf(q{PRAGMA foreign_key_list(%s)}, $dbh->quote($table->{TABLE_NAME}))) or die $dbh->errstr;
        $sth->execute();
        while (my $fk = $sth->fetchrow_hashref()) {
            next unless !defined($pktable) || $pktable eq '%' || $pktable eq $fk->{table};
            push @dbi_fk_info, +{
                PKTABLE_CAT => undef,
                PKTABLE_SCHEM => undef, # TODO
                PKTABLE_NAME  => $fk->{table},
                PKCOLUMN_NAME => $fk->{to},
                FSKTABLE_CAT  => $table->{TABLE_CAT},
                FKTABLE_SCHEM => $table->{TABLE_SCHEM},
                FKTABLE_NAME  => $table->{TABLE_NAME},
                FKCOLUMN_NAME => $fk->{from},
                KEY_SEQ       => $fk->{seq},
            };
        }
    }

    my @NAMES = qw(
        PKTABLE_CAT PKTABLE_SCHEM PKTABLE_NAME PKCOLUMN_NAME PK_NAME
        FKTABLE_CAT FKTABLE_SCHEM FKTABLE_NAME FKCOLUMN_NAME FK_NAME
        KEY_SEQ UPDATE_RULE DELETE_RULE DEFERRABILITY
    );
    my $sponge = DBI->connect('DBI:Sponge:', '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sponge_sth = $sponge->prepare("foreign_key_info", {
        rows => [map { [@{$_}{@NAMES}] } @dbi_fk_info],
        NUM_OF_FIELDS => scalar @NAMES,
        NAME => \@NAMES,
    }) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());
    $sponge_sth;
}

1;

