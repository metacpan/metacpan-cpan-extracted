package DBIx::TryAgain::st;

use strict;
use warnings;

our @ISA = 'DBI::st';

sub _should_try_again {
    my $self = shift;
    my $tried = $self->{private_dbix_try_again_tries} || 0;
    return 0 if $tried >= $self->{private_dbix_try_again_max_retries};
    for my $msg ( @{ $self->{private_dbix_try_again_on_messages} } ) {
        if ($self->errstr =~ $msg) {
            DBI->trace_msg("DBIx::TryAgain [$$] error string ".$self->errstr." matches $msg, will try again.\n");
            return 1;
        }
    }
    return 0;
}

sub _sleep {
    my $self = shift;
    my $init = shift;
    if ($init) {
        $self->{private_dbix_try_again_tries} = 0;
        $self->{private_dbix_try_again_slept} = [];
        return;
    }
    my $tried = $self->{private_dbix_try_again_tries};
    my $slept = $self->{private_dbix_try_again_slept};
    my $alg = $self->{private_dbix_try_again_algorithm};
    my $delay =
        $tried == 1 ? 1
      : $tried == 2 && $alg eq 'fibonacci' ? 1
      : $alg eq 'constant'    ? $slept->[-1]
      : $alg eq 'linear'      ? $slept->[-1] + 1
      : $alg eq 'exponential' ? $slept->[-1] * 2
      : $alg eq 'fibonacci'   ? $slept->[-1] + $slept->[-2]
      :                         die "unknown backoff algorithm : $alg";

    push @$slept, $delay;

    for ("DBIx::TryAgain [$$] sleeping $delay") {
        DBI->trace_msg($_);
        warn $_ if $self->{PrintError};
    }

    sleep $delay;
    return;
}

sub execute {
    my $self = shift;
    my $res = $self->SUPER::execute(@_);
    return $res if $res;
    $self->_sleep('init');
    $self->{private_dbix_try_again_tries} = 0;
    while ($self->_should_try_again) {
        $self->{private_dbix_try_again_tries}++;

        for ("DBIx::TryAgain [$$] execute attempt number ".$self->{private_dbix_try_again_tries}."\n") {
            DBI->trace_msg($_);
            warn $_ if $self->{PrintError};
        }

        $self->_sleep;
        $self->set_err(undef, undef);
        $res = $self->SUPER::execute(@_);
        return $res if $res;
    }
    return;
}

1;

