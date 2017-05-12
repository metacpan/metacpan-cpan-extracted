package Catalyst::Plugin::DBIC::Schema::Profiler::DebugObj;

# $Id$

use strict;
use warnings;

use base qw/DBIx::Class::Storage::Statistics/;
use Time::HiRes qw/ tv_interval gettimeofday /;

sub new {
    my ( $pkg, %args ) = @_;

    bless \%args, $pkg;
}

sub txn_begin {
    my $self = shift;
    $self->{log}->debug("BEGIN\n");
}

sub txn_rollback {
    my $self = shift;
    $self->{log}->debug("ROLLBACK\n");
}

sub txn_commit {
    my $self = shift;
    $self->{log}->debug("COMMIT\n");
}

sub query_start {
    my $self = shift;
    my $sql  = shift;
    my @args = @_;

    my $binded_sql = $sql;
    $binded_sql =~ s(\?){ shift @args }eog;
    my $message = "Executing ... $binded_sql";
    $self->{log}->debug($message);
    $self->{start_time} = [gettimeofday];
}

sub query_end {
    my $self = shift;
    my $sql  = shift;
    my @args = @_;

    my $message = "Execution took "
        . tv_interval( $self->{start_time} )
        . " seconds.\n";
    $self->{log}->debug($message);
    $self->{start_time} = undef;
}

1;
