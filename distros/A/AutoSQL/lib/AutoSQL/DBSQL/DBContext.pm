package AutoSQL::DBSQL::DBContext;
use strict;
use DBI;
use AutoCode::Root;
our @ISA=qw(AutoCode::Root);
use AutoCode::AccessorMaker ('$' => [qw(dbname host user pass port driver)]);

sub _initialize {
    my ($self, @args)=@_;
    my ($dbname, $host, $user, $pass, $driver, $port) =
        $self->_rearrange([qw(DBNAME HOST USER PASS DRIVER PORT)], @args);
    
    $self->host($host || 'localhost');
    $self->user($user || 'root');
    $self->pass($pass);
    $self->port($port);
    $self->driver($driver || 'mysql');
    $self->dbname($dbname);
}

sub prepare {
    my ($self, $sql)=@_;
    return $self->db_handle->prepare($sql);
}

sub db_handle {
    my $self = shift;
    
    if(! exists $self->{_db_handle} || @_){
        my $locator = shift || $self->_db_locator;
        my $user=$self->user;
        my $dbh;
        eval{$dbh=DBI->connect($locator, $user, $self->pass, {RaiseError=>1}) };
        $dbh || die <<END;
Could not connect by [$user] using [$locator] as a locator.
$DBI::errstr
END
        $self->{_current_locator}=$locator;
        $self->{_db_handle}=$dbh;
    }
    return $self->{_db_handle};
}

sub DESTROY {
    my $self=shift;
    $self->db_handle->disconnect;
    $self->{_db_handle}=undef;
}

sub _host_locator {
    my $self=shift;
    my $locator='dbi:'. $self->driver .':';
    foreach my $meth(qw(host port)){
        if(my $value=$self->$meth){ $locator .="$meth=$value;"; }
    }
    return $locator;
}

our %DBNAME_PARAM = (
    mysql => 'database=',
    Pg => 'dbname=',
    Oracle => ''
);

sub _db_locator {
    my $self=shift;
    my $locator=$self->_host_locator;
    $locator .= $DBNAME_PARAM{$self->driver} . $self->dbname;
    return $locator;
}


1;
