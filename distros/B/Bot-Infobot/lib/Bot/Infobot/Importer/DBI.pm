package  Bot::Infobot::Importer::DBI;
use DBI;
use Carp qw(croak);    
use strict;

sub handle {
    return $_[0] =~ m!^dbi:!;
}

sub new {
    my $class = shift;

    my $dbi = DBI->connect( @_ ) || die "DB connection not made - $DBI::errstr\n";

    my $self = { dbh => $dbi, table_prefix => 't' };

    return bless $self, $class;
}

sub fetch {
    my ($self, $table, @keys) = @_;
    my $table_prefix = $self->{table_prefix};
    my $sql = "SELECT * FROM ${table_prefix}_${table}";
    if (@keys) {
        $sql .= " where key = ?";
    } 
    $self->{sth} = $self->do_db($sql, @keys);

    return $self->{sth};
}

sub rows {
    my $self = shift;
    croak "No statement set up" unless $self->{sth};
    return $self->{sth}->rows;

}



sub next {
    my $self = shift;
    return unless $self->{sth};
    my $return = $self->{sth}->fetchrow_hashref;
    return unless $return->{pkey};
    # munge pkey and pvalue to right names
    for (qw(key value)) {
        $return->{$_} = $return->{"p$_"};
        delete $return->{"p$_"};
    }
    return $return;
}

sub finish {
    my ($self) = @_;
    $self->{sth}->finish;
    delete $self->{sth};
}


sub do_db {
    my ($self, $sql, @values) = @_;
    my $sth = $self->{dbh}->prepare($sql);
    my $rv  = $sth->execute(@values);
    die "Error executing '$sql' : ".$self->{dbh}->errstr."\n" unless $rv;

    return $sth;
}


1;
