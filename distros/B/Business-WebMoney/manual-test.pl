#!/usr/bin/perl

use strict;
use utf8;

use lib './lib';

use Business::WebMoney;

print STDERR "==== STEP 0. Initializing ====\n";

my ($my_wmid) = ($ENV{WMTEST_MY_WMID} =~ /^(\d{12})$/) or die 'Environment variable WMTEST_MY_WMID missing';
print STDERR "  * WMID $my_wmid\n";

my ($contragent_wmid) = ($ENV{WMTEST_CONTRAGENT_WMID} =~ /^(\d{12})$/) or die 'Environment variable WMTEST_CONTRAGENT_WMID missing';
print STDERR "  * Contragent WMID $contragent_wmid\n";

my $cert = $ENV{WMTEST_CERT_PATH} or die 'Environment variable WMTEST_CERT_PATH missing';
print STDERR "  * Certificate $cert\n";

my $pass = $ENV{WMTEST_CERT_PASS} or die 'Environment variable WMTEST_CERT_PASS missing';

# tomorrow date (for datefinish)
my ($ss, $mm, $hh, $d, $m, $y) = localtime(time + 86400);
my $tomorrow = sprintf '%04d%02d%02d %02d:%02d:%02d', $y + 1900, $m + 1, $d, $hh, $mm, $ss;

print STDERR "  * datefinish $tomorrow\n";

my $reqn = time;

print STDERR "  * initial reqn $reqn\n";

my $wm = Business::WebMoney->new(
	p12_file => $cert,
	p12_pass => $pass,
);

print STDERR "==== PASSED ====\n\n";

my $my_purse;

{
	print STDERR "==== STEP 1. Getting purses list ====\n";

	my $res = $wm->get_balance(
		reqn => $reqn++,
		wmid => $my_wmid,
	) or die $wm->errstr;

	@$res or die 'This WMID has no purses';

	for my $purse (@$res) {

		print STDERR "  * found $purse->{pursename} - $purse->{amount} $purse->{desc}\n";
	}

	# If we have R-purse with non-zero balance, it's the choice. Otherwise look for Z-purse. Otherwise any other

	my %priority = (
		WMR => 2,
		WMZ => 1,
	);

	($my_purse) = sort {

		$priority{$b->{desc}} <=> $priority{$a->{desc}};

	} @$res;

	$my_purse or die 'This WMID has no purses';

	$my_purse = $my_purse->{pursename};

	print STDERR "  * selected $my_purse\n";

	print STDERR "==== PASSED ====\n\n";
}

{
	print STDERR "==== STEP 2. Testing invoice reject ====\n";

	my $res = $wm->invoice(
		reqn => $reqn++,
		orderid => 1,
		customerwmid => $contragent_wmid,
		storepurse => $my_purse,
		amount => 1000000,
		desc => 'Business::Webmoney invoice test. Reject it'
	) or die $wm->errstr;

	my $invoice_id = $res->{id};
	my $invoice_date = $res->{datecrt};

	print STDERR "  * created invoice $invoice_id at $invoice_date to WMID $contragent_wmid\n";
	print STDERR "  * reject created invoice. waiting ...";

	while (1) {

		sleep 5;

		my $res = $wm->get_out_invoices(
			reqn => $reqn++,
			purse => $my_purse,
			wminvid => $invoice_id,
			datestart => $invoice_date,
			datefinish => $tomorrow,
		) or die $res->errstr;

		if (@$res != 1) {

			require Data::Dumper;
			die "get_out_invoices hasn't return the single invoice:\n" . Data::Dumper::Dumper($res);
		}

		if ($res->[0]->{state} == 0) {

			print STDERR '.';

		} elsif ($res->[0]->{state} == 3) {

			print STDERR " ok\n";
			last;

		} else {

			die " invoice was not rejected. state=$res->[0]->{state}\n";
		}
	}

	print STDERR "==== PASSED ====\n\n";
}

my $contragent_purse;

{
	print STDERR "==== STEP 3. Testing invoice payment ====\n";

	my $res = $wm->invoice(
		reqn => $reqn++,
		orderid => 1,
		customerwmid => $contragent_wmid,
		storepurse => $my_purse,
		amount => 1,
		desc => 'Business::Webmoney invoice test. Pay it without protection'
	) or die $wm->errstr;

	my $invoice_id = $res->{id};
	my $invoice_date = $res->{datecrt};

	print STDERR "  * created invoice $invoice_id at $invoice_date to WMID $contragent_wmid\n";
	print STDERR "  * pay created invoice without protection. waiting ...";

	my $wmtranid;

	while (1) {

		sleep 5;

		my $res = $wm->get_out_invoices(
			reqn => $reqn++,
			purse => $my_purse,
			wminvid => $invoice_id,
			datestart => $invoice_date,
			datefinish => $tomorrow,
		) or die $res->errstr;

		if (@$res != 1) {

			require Data::Dumper;
			die "get_out_invoices hasn't return the single invoice:\n" . Data::Dumper::Dumper($res);
		}

		if ($res->[0]->{state} == 0) {

			print STDERR '.';

		} elsif ($res->[0]->{state} == 2 && $res->[0]->{amount} == 1) {

			$contragent_purse = $res->[0]->{customerpurse};
			$wmtranid = $res->[0]->{wmtranid};

			print STDERR " ok. transaction $wmtranid\n";
			print STDERR "  * contragent purse $contragent_purse\n";
			last;

		} else {

			die " invoice was not paid properly. state=$res->[0]->{state}\n";
		}
	}

	print STDERR "==== PASSED ====\n\n";

	print STDERR "==== STEP 4. Testing money back ====\n";

	my $res = $wm->money_back(
		reqn => $reqn++,
		inwmtranid => $wmtranid,
		amount => 1,
	) or die $wm->errstr;

	print STDERR "  * money returned\n";

	print STDERR "==== PASSED ====\n\n";
}

{
	print STDERR "==== STEP 5. Testing protection reject ====\n";

	my $res = $wm->invoice(
		reqn => $reqn++,
		orderid => 1,
		customerwmid => $contragent_wmid,
		storepurse => $my_purse,
		amount => 1,
		desc => 'Business::Webmoney invoice test. Pay it with protection code "abc"',
		period => 1,
	) or die $wm->errstr;

	my $invoice_id = $res->{id};
	my $invoice_date = $res->{datecrt};

	print STDERR "  * created invoice $invoice_id at $invoice_date to WMID $contragent_wmid\n";
	print STDERR "  * pay created invoice with protection code 'abc'. waiting ...";

	my $wmtranid;

	while (1) {

		sleep 5;

		my $res = $wm->get_out_invoices(
			reqn => $reqn++,
			purse => $my_purse,
			wminvid => $invoice_id,
			datestart => $invoice_date,
			datefinish => $tomorrow,
		) or die $res->errstr;

		if (@$res != 1) {

			require Data::Dumper;
			die "get_out_invoices hasn't return the single invoice:\n" . Data::Dumper::Dumper($res);
		}

		if ($res->[0]->{state} == 0) {

			print STDERR '.';

		} elsif ($res->[0]->{state} == 1 && $res->[0]->{amount} == 1) {

			$wmtranid = $res->[0]->{wmtranid};

			print STDERR " ok. transaction $wmtranid\n";
			last;

		} else {

			die " invoice was not paid properly. state=$res->[0]->{state}\n";
		}
	}

	print STDERR "  * trying to reject transaction ... ";

	my $res = $wm->reject_protect(
		reqn => $reqn++,
		wmtranid => $wmtranid,
	) or die $wm->errstr;

	print STDERR "ok\n";

	print STDERR "==== PASSED ====\n\n";
}

{
	print STDERR "==== STEP 5. Testing protection confirm ====\n";

	my $res = $wm->invoice(
		reqn => $reqn++,
		orderid => 1,
		customerwmid => $contragent_wmid,
		storepurse => $my_purse,
		amount => 1,
		desc => 'Business::Webmoney invoice test. Pay it with protection code "abc"',
		period => 1,
	) or die $wm->errstr;

	my $invoice_id = $res->{id};
	my $invoice_date = $res->{datecrt};

	print STDERR "  * created invoice $invoice_id at $invoice_date to WMID $contragent_wmid\n";
	print STDERR "  * pay created invoice with protection code 'abc'. waiting ...";

	my $wmtranid;

	while (1) {

		sleep 5;

		my $res = $wm->get_out_invoices(
			reqn => $reqn++,
			purse => $my_purse,
			wminvid => $invoice_id,
			datestart => $invoice_date,
			datefinish => $tomorrow,
		) or die $res->errstr;

		if (@$res != 1) {

			require Data::Dumper;
			die "get_out_invoices hasn't return the single invoice:\n" . Data::Dumper::Dumper($res);
		}

		if ($res->[0]->{state} == 0) {

			print STDERR '.';

		} elsif ($res->[0]->{state} == 1 && $res->[0]->{amount} == 1) {

			$wmtranid = $res->[0]->{wmtranid};

			print STDERR " ok. transaction $wmtranid\n";
			last;

		} else {

			die " invoice was not paid properly. state=$res->[0]->{state}\n";
		}
	}

	print STDERR "  * trying to confirm transaction with protection code 'abc' ... ";

	my $res = $wm->finish_protect(
		reqn => $reqn++,
		wmtranid => $wmtranid,
		pcode => 'abc',
	) or die $wm->errstr;

	print STDERR "ok\n";

	print STDERR "==== PASSED ====\n\n";
}

{
	print STDERR "==== STEP 6. Message sending ====\n";

	print STDERR "  * sending message ... ";

	my $res = $wm->message(
		reqn => $reqn++,
		receiverwmid => $contragent_wmid,
		msgsubj => 'Business::WebMoney test',
		msgtext => "Message test passed\nCyrillic letters: и этот тест тоже пройден!",
	) or die $wm->errstr;

	print STDERR "ok\n";

	print STDERR "==== PASSED ====\n\n";
}

{
	print STDERR "==== STEP 7. Money transfer without protection ====\n";

	print STDERR "  * transferring money ... ";

	my $res = $wm->transfer(
		reqn => $reqn++,
		tranid => $reqn,
		pursesrc => $my_purse,
		pursedest => $contragent_purse,
		amount => 0.1,
		desc => 'Business::WebMoney transfer test',
	) or die $wm->errstr;

	print STDERR "ok\n";

	print STDERR "==== PASSED ====\n\n";
}

{
	print STDERR "==== STEP 8. Money transfer with protection ====\n";

	print STDERR "  * transferring money ... ";

	my $res = $wm->transfer(
		reqn => $reqn++,
		tranid => $reqn,
		pursesrc => $my_purse,
		pursedest => $contragent_purse,
		amount => 0.1,
		desc => 'Business::WebMoney protection test. Reject it!',
		period => 1,
		pcode => '123',
	) or die $wm->errstr;

	my $wmtranid = $res->{id};
	my $operation_date = $res->{datecrt};

	print STDERR "ok. transaction $wmtranid at $operation_date\n";

	print STDERR "  * reject transaction. waiting ...";

	while (1) {

		sleep 5;

		my $res = $wm->get_operations(
			reqn => $reqn++,
			purse => $my_purse,
			wmtranid => $wmtranid,
			datestart => $operation_date,
			datefinish => $tomorrow,
		) or die $res->errstr;

		if (@$res != 1) {

			require Data::Dumper;
			die "get_operations hasn't return the single operation:\n" . Data::Dumper::Dumper($res);
		}

		if ($res->[0]->{opertype} == 4) {

			print STDERR '.';

		} elsif ($res->[0]->{opertype} == 12) {

			print STDERR " ok\n";
			last;

		} else {

			die " operation was not rejected. opertype=$res->[0]->{opertype}\n";
		}
	}

	print STDERR "  * transferring money one more time ... ";

	my $res = $wm->transfer(
		reqn => $reqn++,
		tranid => $reqn,
		pursesrc => $my_purse,
		pursedest => $contragent_purse,
		amount => 0.1,
		desc => 'Business::WebMoney protection test. Confirm with protection code "123"',
		period => 1,
		pcode => '123',
	) or die $wm->errstr;

	my $wmtranid = $res->{id};
	my $operation_date = $res->{datecrt};

	print STDERR "ok. transaction $wmtranid at $operation_date\n";

	print STDERR "  * confirm transaction with protection code '123'. waiting ...";

	while (1) {

		sleep 5;

		my $res = $wm->get_operations(
			reqn => $reqn++,
			purse => $my_purse,
			wmtranid => $wmtranid,
			datestart => $operation_date,
			datefinish => $tomorrow,
		) or die $res->errstr;

		if (@$res != 1) {

			require Data::Dumper;
			die "get_operations hasn't return the single operation:\n" . Data::Dumper::Dumper($res);
		}

		if ($res->[0]->{opertype} == 4) {

			print STDERR '.';

		} elsif ($res->[0]->{opertype} == 0) {

			print STDERR " ok\n";
			last;

		} else {

			die " operation was not confirmed. opertype=$res->[0]->{opertype}\n";
		}
	}

	print STDERR "==== PASSED ====\n\n";
}

print STDERR "All tests have been successfully passed. Business::WebMoney is happy to serve you.\n";
