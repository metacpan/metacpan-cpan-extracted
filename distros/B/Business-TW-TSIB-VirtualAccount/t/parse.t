#!/usr/bin/perl -T
use Test::More tests => 25;
BEGIN {
	use_ok( 'Business::TW::TSIB::VirtualAccount' );
}

diag( "Testing Business::TW::TSIB::VirtualAccount $Business::TW::TSIB::VirtualAccount::VERSION, Perl $], $^X" );


# create test file   
# 4     # response code
# 14    # account
# 8     # date
# 6     # sequence number (seqno)
# 1     # flag
# 6     # time
# 4     # transaction type
# 12    # amount
# 1     # postive
# 1     # entry type
# 16    # virtual account
# 10    # ID Card
# 3     # from bank
# 20    # comment
# 18    # preserve
# 1     # status
my $content =<<EOF;
00002076010000204720071105000001A093158ATM 39000       +C9567860922892400          825                    168371            S
00002076010000204720071105000002A093250ATM 49000       +C9567861232896100          806                    379508            S
00002076010000204720071105000003A093530ATM 39000       +C9567863361032000          806                    382570            S
00002076010000204720071105000004A093707ATM 12890       +C9567862563859000          012                    531033            S
00002076010000204720071105000005A094040ATM 10230       +C9567860926531600          012                    533008            S
00002076010000204720071105000006A094503ATM 29390       +C9567863069378900          807                    563153            S
00002076010000204720071105000007A094708ATM 900000      +C9567860332980700          807                    565561            S
00002076010000204720071105000008A095013ATM 39000       +C9567860923848000          807                    638530            S
00002076010000204720071105000009A095218ATM 1238880     +C9567860936138700          050                    100861            S
00002076010000204720071105000010B100032OTC 438990      +C9567862528977000          812                    194532            S
EOF

open my $fh , '<' , \$content or die $!;
my $entries = Business::TW::TSIB::VirtualAccount->parse_summary($fh);
is( $entries->[0]->seqno,           '000001' );
is( $entries->[0]->date,            '20071105' );
is( $entries->[0]->time,            '093158' );
is( $entries->[0]->txn_type,           'ATM' );
is( $entries->[0]->amount,          3900 );
is( $entries->[0]->postive,        '+' );
is( $entries->[0]->entry_type,      'C' );
is( $entries->[0]->virtual_account, '9567860922892400' );
is( $entries->[0]->from_bank,       '825' );
is( $entries->[0]->status,          'S' );
is( $entries->[0]->ar_id, '2892' );    # 5 cols for corp id , 4 cols for due , 4 cols for ar_id


is( $entries->[1]->response_code , '0000' );
is( $entries->[1]->account,  '20760100002047' );
is( $entries->[1]->date, '20071105' );
is( $entries->[1]->seqno, '000002' );
is( $entries->[1]->flag, 'A');
is( $entries->[1]->time , '093250' );
is( $entries->[1]->txn_type , 'ATM' );
is( $entries->[1]->amount, 4900 );
is( $entries->[1]->postive , '+' );
is( $entries->[1]->entry_type , 'C' );
is( $entries->[1]->virtual_account , '9567861232896100' );
is( $entries->[1]->from_bank , '806' );
is( $entries->[1]->status , 'S');
