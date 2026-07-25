use strict;
use warnings;
use Test::More;
use Config;
use Data::Log::Shared;

plan skip_all => 'fork required' unless $Config{d_fork};

# Argument magic that explicitly calls $obj->DESTROY frees the C handle
# mid-method. Without the REEXTRACT_LOG calls the method then dereferences
# a handle whose header was munmapped by log_destroy and SEGFAULTs; with
# them it must croak cleanly. Child exit 0 = croaked (correct), exit 7 =
# ran on through freed memory (REEXTRACT removed and no crash).
#
# Magic placement note: for read_entry/wait_for the offset/expected_count
# UV is converted by the INPUT typemap BEFORE EXTRACT_LOG (PREINIT) runs,
# so magic on that argument would croak in EXTRACT even without REEXTRACT
# -- a passes-either-way test. The discriminating window is the optional
# third argument (abandon_wait_us / timeout), read in PPCODE/CODE after
# EXTRACT_LOG and before REEXTRACT_LOG. append's data is a raw SV* whose
# SvPV runs in the same window, so it can carry the magic directly.

{
    package Evil;
    use overload
        '""' => sub { $_[0][0]->DESTROY; 'k' },
        '0+' => sub { $_[0][0]->DESTROY; 0 },
        fallback => 1;
}

my %call = (
    append     => sub { my ($log, $evil) = @_; $log->append($evil) },
    read_entry => sub { my ($log, $evil) = @_; $log->read_entry(0, $evil) },
    wait_for   => sub { my ($log, $evil) = @_; $log->wait_for(0, $evil) },
);

for my $method (sort keys %call) {
    my $pid = fork();
    unless ($pid) {
        my $log  = Data::Log::Shared->new(undef, 8192);
        my $evil = bless [$log], 'Evil';
        my $ok = eval { $call{$method}->($log, $evil); 1 };
        exit($ok ? 7 : 0);
    }
    waitpid($pid, 0);
    my $st = $?;
    ok !($st & 127), "$method: no crash when argument magic destroys the handle"
        or diag sprintf('died with signal %d', $st & 127);
    is $st >> 8, 0, "$method: croaks instead of using the freed handle";
}

done_testing;
