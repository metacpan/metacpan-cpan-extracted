package App::Mowyw::Datasource::DBI;
use strict;
use warnings;
use 5.008;
use Encode qw(decode); 
use DBI;
use Carp qw(confess);
use base 'App::Mowyw::Datasource';

sub new {
    my ($class, $opts) = @_;
    for (qw(dsn sql)) {
        if (!exists $opts->{$_} ){
            confess "DBI plugin needs the '$_:' option";
        }
    }
    my $self = bless { 
        OPTIONS => $opts, 
        ROW => undef, 
    }, $class;
    $self->_connect;
    $self->{sth} = $self->{dbh}->prepare($opts->{sql});
    return $self;
}

sub _connect {
    my ($self) = @_;
    $self->{dbh} = DBI->connect(
        $self->{OPTIONS}{dsn},
        $self->{OPTIONS}{username},
        $self->{OPTIONS}{password},
        { RaiseError => 1, AutoCommit => 1, },
    );
}

sub _fetchrow {
    my $self = shift;
    my $sth = $self->{sth};
    my $row = $sth->fetchrow_hashref;
    if ($row){
        my $encoding = $self->{OPTIONS}{encoding} || 'utf8';
        for (keys %$row){
            $row->{$_} = decode($encoding, $row->{$_}, 1);
        }
    }
    $self->{ROW} = $row;
}

sub is_exhausted { return !defined shift->{ROW}; }

sub next         { shift->_fetchrow(); }

sub get          { shift->{ROW}; }

sub reset        { my $self = shift; $self->{sth}->execute(); $self->_fetchrow; }

1;
