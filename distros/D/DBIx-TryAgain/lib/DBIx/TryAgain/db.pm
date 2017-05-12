package DBIx::TryAgain::db;
use strict;
use warnings;

our @ISA = 'DBI::db';

our %defaults = (
    private_dbix_try_again_algorithm => 'fibonacci', # or exponential or linear or constant
    private_dbix_try_again_max_retries => 5,
    private_dbix_try_again_on_messages => [ qr/database is locked/i ],
);

sub try_again_algorithm {
    my $self = shift;
    my $attr = 'private_dbix_try_again_algorithm';
    return $self->{$attr} || $defaults{$attr} unless @_;
    $self->{$attr} = shift;
}

sub try_again_max_retries {
    my $self = shift;
    my $attr = 'private_dbix_try_again_max_retries';
    return $self->{$attr} || $defaults{$attr} unless @_;
    $self->{$attr} = shift;
}

sub try_again_on_messages  {
    my $self = shift;
    my $attr = 'private_dbix_try_again_on_messages';
    return $self->{$attr} || $defaults{$attr} unless @_;
    die "messages should be an array ref" if ref($_[0]) ne 'ARRAY';
    $self->{$attr} = shift;
}

sub try_again_on_prepare  {
    my $self = shift;
    my $attr = 'private_dbix_try_again_on_prepare';
    return $self->{$attr} || $defaults{$attr} unless @_;
    $self->{$attr} = shift;
}

sub _should_try_again {
    my $self = shift;
    return unless $self->try_again_on_prepare;
    return $self->DBIx::TryAgain::st::_should_try_again(@_);
}

sub _sleep {
    return shift->DBIx::TryAgain::st::_sleep(@_);
}

sub prepare {
    my $self = shift;
    my @args = @_;

    for (keys %defaults) {
        $self->{$_} = $defaults{$_} unless defined($self->{$_});
    }

    my $sth = $self->SUPER::prepare(@args);

    if ($self->try_again_on_prepare) {
        $self->_sleep('init');
        $self->{private_dbix_try_again_tries} = 0;
    }

    while (!$sth && $self->_should_try_again) {
        $self->{private_dbix_try_again_tries}++;

        for ("DBIx::TryAgain [$$] prepare attempt number ".$self->{private_dbix_try_again_tries}."\n") {
            DBI->trace_msg($_);
            warn $_ if $self->{PrintError};
        }

        $self->_sleep;
        $self->set_err(undef, undef);
        $sth = $self->SUPER::prepare(@args);
    }

    return unless $sth;
    $sth->{$_} = $self->{$_} for keys %defaults;
    return $sth;
}


1;

