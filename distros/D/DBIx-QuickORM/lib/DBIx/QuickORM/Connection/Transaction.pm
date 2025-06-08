package DBIx::QuickORM::Connection::Transaction;
use strict;
use warnings;

use Carp qw/croak confess/;

use DBIx::QuickORM::Util::HashBase qw{
    <id
    +savepoint

    +on_success
    +on_fail
    +on_completion

    verbose

    <result
    <errors
    <trace

    <rolled_back
    <committed

    <in_destroy
    +finalize

    no_last
};

sub is_savepoint { $_[0]->{+SAVEPOINT} ? 1 : 0 }

sub init {
    my $self = shift;

    croak "A transaction ID is required" unless $self->{+ID};

    $self->{+RESULT} = undef;

    $self->{+ON_SUCCESS}    = [$self->{+ON_SUCCESS}]    if 'CODE' eq ref($self->{+ON_SUCCESS});
    $self->{+ON_FAIL}       = [$self->{+ON_FAIL}]       if 'CODE' eq ref($self->{+ON_FAIL});
    $self->{+ON_COMPLETION} = [$self->{+ON_COMPLETION}] if 'CODE' eq ref($self->{+ON_COMPLETION});
}

sub complete { defined $_[0]->{+RESULT} }

sub state {
    my $self = shift;
    return 'committed'   if $self->{+COMMITTED};
    return 'rolled_back' if $self->{+ROLLED_BACK};
    return 'complete'    if $self->{+RESULT};
    return 'active';
}

{
    no warnings 'once';
    *abort = \&rollback;
}
sub rollback {
    my $self = shift;
    my ($why) = @_;

    if ($self->{+VERBOSE} || !$why) {
        my @caller = caller;
        my $trace = "$caller[1] line $caller[2]";

        if (my $verbose = $self->{+VERBOSE}) {
            my $name = length($verbose) > 1 ? $verbose : $self->{+ID};
            warn "Transaction '$name' rolled back in $trace" . ($why ? " ($why)" : ".") . "\n";
        }

        if ($why) {
            $why .= " in $trace" unless $why =~ m/\n$/;
        }
        else {
            $why = $trace;
        }
    }

    $self->{+ROLLED_BACK} = $why;

    $self->finalize(1, $why) if $self->{+FINALIZE};

    return if $self->{+NO_LAST};

    no warnings 'exiting';
    last QORM_TRANSACTION;
};

sub commit {
    my $self = shift;
    my ($why) = @_;

    if ($self->{+VERBOSE} || !$why) {
        my @caller = caller;
        my $trace = "$caller[1] line $caller[2]";

        if (my $verbose = $self->{+VERBOSE}) {
            my $name = length($verbose) > 1 ? $verbose : $self->{+ID};
            warn "Transaction '$name' committed in $trace" . ($why ? " ($why)" : ".") . "\n";
        }

        if ($why) {
            $why .= " in $trace" unless $why =~ m/\n$/;
        }
        else {
            $why = $trace;
        }
    }

    $self->{+COMMITTED} = $why;

    $self->finalize(1) if $self->{+FINALIZE};

    return if $self->{+NO_LAST};

    no warnings 'exiting';
    last QORM_TRANSACTION;
}

sub terminate {
    my $self = shift;
    my ($res, $err) = @_;

    $self->{+RESULT} = $res ? 1 : 0;
    $self->{+ERRORS} = $res ? undef : $err;

    my $todo = $res ? $self->{+ON_SUCCESS} : $self->{+ON_FAIL};
    $todo = [@{$todo // []}, @{$self->{+ON_COMPLETION} // []}];

    delete $self->{+ON_SUCCESS};
    delete $self->{+ON_FAIL};
    delete $self->{+ON_COMPLETION};
    delete $self->{+SAVEPOINT};

    return (1, undef) unless $todo && @$todo;

    my ($out, $out_err) = (1, undef);
    for my $cb (@$todo) {
        local $@;
        eval { $cb->($self); 1 } and next;
        push @{$out_err //= []} => $@;
        $out = 0;
    }

    return ($out, $out_err);
}

sub add_success_callback {
    my $self = shift;
    my ($cb) = @_;
    push @{$self->{+ON_SUCCESS} //= []} => $cb;
}

sub add_fail_callback {
    my $self = shift;
    my ($cb) = @_;
    push @{$self->{+ON_FAIL} //= []} => $cb;
}

sub add_completion_callback {
    my $self = shift;
    my ($cb) = @_;
    push @{$self->{+ON_COMPLETION} //= []} => $cb;
}

sub throw {
    my $self = shift;
    my ($err) = @_;

    my $trace = $self->{+TRACE} // [qw/unknown unknown unknown/];
    $err = "Transaction error in transaction started in $trace->[1] line $trace->[2]: $err";
    $err = "[In DESTROY] $err" if $self->{+IN_DESTROY};

    confess $err;
}

sub set_finalize {
    my $self = shift;
    my ($cb) = @_;

    $self->{+FINALIZE} = $cb;
}

sub finalize {
    my $self = shift;
    my ($ok, $err) = @_;
    my $cb = delete $self->{+FINALIZE} or croak "Nothing to finalize!";
    $cb->($self, $ok, $err);
    return $ok;
}

sub DESTROY {
    my $self = shift;
    my @caller = caller;
    my $finalize = $self->{+FINALIZE} or return;
    $self->{+IN_DESTROY} = 1;
    $finalize->($self, 1, "Transaction fell out of scope");
}

1;
