	use common::sense 3;
	use lib::abs '../lib';
	use EV;
	
	use AnyEvent::DBD::Pg;
	
	my $adb = AnyEvent::DBD::Pg->new('dbi:Pg:dbname=test', user => 'pass', {
		pg_enable_utf8 => 1,
		pg_server_prepare => 0,
		quote_char => '"',
		name_sep => ".",
	}, debug => 1);
	
	$adb->queue_size( 4 );
	$adb->debug( 1 );
	
	$adb->connect;
	
	$adb->selectcol_arrayref("select pg_sleep( 0.1 ), 1", { Columns => [ 1 ] }, sub {
		my $rc = shift or return warn;
		my $res = shift;
		warn "Got <$adb->{qd}> = $rc / @{$res}";
		$adb->selectrow_hashref("select data,* from tx limit 2", {}, sub {
			my $rc = shift or return warn;
			warn "Got $adb->{qd} = $rc [@_]";
		});
	});
	
	$adb->execute("update tx set data = data;",sub {
		my $rc = shift or return warn;
		warn "Got exec: $rc";
		#my $st = shift;
		#$st->finish;
	});
	
	$adb->execute("select from 1",sub {
		shift or return warn;
		warn "Got $adb->{qd} = @_";
	});
	
	$adb->selectrow_array("select pg_sleep( 0.1 ), 2", {}, sub {
		shift or return warn;
		warn "Got $adb->{qd} = [@_]";
		$adb->selectrow_hashref("select * from tx limit 1", {}, sub {
			warn "Got $adb->{qd} = [@_]";
			$adb->execute("select * from tx", sub {
				my $rc = shift or return warn;
				my $st = shift;
				while(my $row = $st->fetchrow_hashref) { warn "$row->{id}"; }
				$st->finish;
				exit;
			});
		});
	});
	
	AE::cv->recv;
