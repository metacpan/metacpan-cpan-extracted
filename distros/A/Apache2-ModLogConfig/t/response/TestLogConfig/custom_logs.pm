package TestLogConfig::custom_logs;

use Apache2::ModLogConfig;
use Apache2::Const -compile=>qw/OK/;
use Apache2::RequestRec ();
use Apache2::ServerRec ();
use Apache::Test;
use Apache::TestUtil qw/t_server_log_error_is_expected/;

sub handler {
    my ($r)=@_;
    my @names=$r->server->custom_logs;

    if( $r->args eq 'VHost' ) {
	Apache::Test::plan($r, tests=>5);
	Apache::Test::ok(@names==2);
	my %names; undef @names{@names};
	Apache::Test::ok(exists $names{q!logs/perl-fritz.log!});
	Apache::Test::ok(exists $names{q!@perl: sub {My::Hnd(q{fritz}, !.
				       q!@_, q{fritz})}!});
	for my $n (@names) {
	    my $log=$r->server->custom_log_by_name($n);
	    Apache::Test::ok(ref($log) eq 'Apache2::CustomLog');
	}
    } else {
	Apache::Test::plan($r, tests=>8);
	Apache::Test::ok(@names==3);
	my %names; undef @names{@names};
	Apache::Test::ok(exists $names{q!logs/perl.log!});
	Apache::Test::ok(exists $names{q!@perl: sub {My::Hnd(q{sentinel}, !.
				       q!@_, q{sentinel})}!});
	for my $n (@names) {
	    my $log=$r->server->custom_log_by_name($n);
	    Apache::Test::ok(ref($log) eq 'Apache2::CustomLog');
	}
	{
	    my @l=eval{$r->server->custom_log_by_name};
	    Apache::Test::ok($@);
	    @l=$r->server->custom_log_by_name('   ');
	    Apache::Test::ok(@l==0);
	}
    }

    return Apache2::Const::OK;
}

1;
