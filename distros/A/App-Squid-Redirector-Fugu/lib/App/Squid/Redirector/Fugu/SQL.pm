use strict;
use warnings;

package App::Squid::Redirector::Fugu::SQL;

sub new {
    my $class = shift;
    return bless({}, $class);
}

sub run {
    my($self, $query, $fn) = @_;
    
    my $sth = $self->{dbh}->prepare($query);
    $sth->execute();
    
    # function will receive sth as param
    &$fn($sth);
    
    $sth->finish();
}

sub set_dbh {
    my($self, $dbh) = @_;    
    $self->{dbh} = $dbh;
}

sub set_logger {
    my($self, $logger) = @_;    
    $self->{logger} = $logger;
}

1;
