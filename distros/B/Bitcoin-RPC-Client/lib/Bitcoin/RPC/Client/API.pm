package Bitcoin::RPC::Client::API;

use strict;
use warnings;

our $VERSION  = '0.06';

our @methods = (
#==Blockchain}
qq{getbestblockhash},
qq{getblock},
qq{getblockchaininfo},
qq{getblockcount},
qq{getblockhash},
qq{getblockheader},
qq{getchaintips},
qq{getdifficulty},
qq{getmempoolinfo},
qq{getrawmempool},
qq{gettxout},
qq{gettxoutproof},
qq{gettxoutsetinfo},
qq{verifychain},
qq{verifytxoutproof},
#==Control}
qq{getinfo},
qq{help},
qq{stop},
#==Generating}
qq{generate},
qq{getgenerate},
qq{setgenerate},
#==Mining}
qq{getblocktemplate},
qq{getmininginfo},
qq{getnetworkhashps},
qq{prioritisetransaction},
qq{submitblock},
#==Network}
qq{addnode},
qq{clearbanned},
qq{disconnectnode},
qq{getaddednodeinfo},
qq{getconnectioncount},
qq{getnettotals},
qq{getnetworkinfo},
qq{getpeerinfo},
qq{listbanned},
qq{ping},
qq{setban},
#==Rawtransactions}
qq{createrawtransaction},
qq{decoderawtransaction},
qq{decodescript},
qq{fundrawtransaction},
qq{getrawtransaction},
qq{sendrawtransaction},
qq{signrawtransaction},
#==Util}
qq{createmultisig},
qq{estimatefee},
qq{estimatepriority},
qq{estimatesmartfee},
qq{estimatesmartpriority},
qq{validateaddress},
qq{verifymessage},
#==Wallet}
qq{abandontransaction},
qq{addmultisigaddress},
qq{backupwallet},
qq{dumpprivkey},
qq{dumpwallet},
qq{encryptwallet},
qq{getaccount},
qq{getaccountaddress},
qq{getaddressesbyaccount},
qq{getbalance},
qq{getnewaddress},
qq{getrawchangeaddress},
qq{getreceivedbyaccount},
qq{getreceivedbyaddress},
qq{gettransaction},
qq{getunconfirmedbalance},
qq{getwalletinfo},
qq{importaddress},
qq{importprivkey},
qq{importpubkey},
qq{importwallet},
qq{keypoolrefill},
qq{listaccounts},
qq{listaddressgroupings},
qq{listlockunspent},
qq{listreceivedbyaccount},
qq{listreceivedbyaddress},
qq{listsinceblock},
qq{listtransactions},
qq{listunspent},
qq{lockunspent},
qq{move},
qq{sendfrom},
qq{sendmany},
qq{sendtoaddress},
qq{setaccount},
qq{settxfee},
qq{signmessage},
);

our @help = (
#== Blockchain ==}
qq{getbestblockhash},
qq{getblock "hash" ( verbose )},
qq{getblockchaininfo},
qq{getblockcount},
qq{getblockhash index},
qq{getblockheader "hash" ( verbose )},
qq{getchaintips},
qq{getdifficulty},
qq{getmempoolinfo},
qq{getrawmempool ( verbose )},
qq{gettxout "txid" n ( includemempool )},
qq{gettxoutproof ["txid",...] ( blockhash )},
qq{gettxoutsetinfo},
qq{verifychain ( checklevel numblocks )},
qq{verifytxoutproof "proof"},
#== Control ==}
qq{getinfo},
qq{help ( "command" )},
qq{stop},
#== Generating ==}
qq{generate numblocks},
qq{getgenerate},
qq{setgenerate generate ( genproclimit )},
#== Mining ==}
qq{getblocktemplate ( "jsonrequestobject" )},
qq{getmininginfo},
qq{getnetworkhashps ( blocks height )},
qq{prioritisetransaction <txid> <priority delta> <fee delta>},
qq{submitblock "hexdata" ( "jsonparametersobject" )},
#== Network ==}
qq{addnode "node" "add|remove|onetry"},
qq{clearbanned},
qq{disconnectnode "node" },
qq{getaddednodeinfo dns ( "node" )},
qq{getconnectioncount},
qq{getnettotals},
qq{getnetworkinfo},
qq{getpeerinfo},
qq{listbanned},
qq{ping},
qq{setban "ip(/netmask)" "add|remove" (bantime) (absolute)},
#== Rawtransactions ==}
qq{createrawtransaction [{"txid":"id","vout":n},...] {"address":amount,"data":"hex",...} ( locktime )},
qq{decoderawtransaction "hexstring"},
qq{decodescript "hex"},
qq{fundrawtransaction "hexstring" includeWatching},
qq{getrawtransaction "txid" ( verbose )},
qq{sendrawtransaction "hexstring" ( allowhighfees )},
qq{signrawtransaction "hexstring" ( [{"txid":"id","vout":n,"scriptPubKey":"hex","redeemScript":"hex"},...] ["privatekey1",...] sighashtype )},
#== Util ==}
qq{createmultisig nrequired ["key",...]},
qq{estimatefee nblocks},
qq{estimatepriority nblocks},
qq{estimatesmartfee nblocks},
qq{estimatesmartpriority nblocks},
qq{validateaddress "bitcoinaddress"},
qq{verifymessage "bitcoinaddress" "signature" "message"},
#== Wallet ==}
qq{abandontransaction "txid"},
qq{addmultisigaddress nrequired ["key",...] ( "account" )},
qq{backupwallet "destination"},
qq{dumpprivkey "bitcoinaddress"},
qq{dumpwallet "filename"},
qq{encryptwallet "passphrase"},
qq{getaccount "bitcoinaddress"},
qq{getaccountaddress "account"},
qq{getaddressesbyaccount "account"},
qq{getbalance ( "account" minconf includeWatchonly )},
qq{getnewaddress ( "account" )},
qq{getrawchangeaddress},
qq{getreceivedbyaccount "account" ( minconf )},
qq{getreceivedbyaddress "bitcoinaddress" ( minconf )},
qq{gettransaction "txid" ( includeWatchonly )},
qq{getunconfirmedbalance},
qq{getwalletinfo},
qq{importaddress "address" ( "label" rescan p2sh )},
qq{importprivkey "bitcoinprivkey" ( "label" rescan )},
qq{importpubkey "pubkey" ( "label" rescan )},
qq{importwallet "filename"},
qq{keypoolrefill ( newsize )},
qq{listaccounts ( minconf includeWatchonly)},
qq{listaddressgroupings},
qq{listlockunspent},
qq{listreceivedbyaccount ( minconf includeempty includeWatchonly)},
qq{listreceivedbyaddress ( minconf includeempty includeWatchonly)},
qq{listsinceblock ( "blockhash" target-confirmations includeWatchonly)},
qq{listtransactions ( "account" count from includeWatchonly)},
qq{listunspent ( minconf maxconf  ["address",...] )},
qq{lockunspent unlock [{"txid":"txid","vout":n},...]},
qq{move "fromaccount" "toaccount" amount ( minconf "comment" )},
qq{sendfrom "fromaccount" "tobitcoinaddress" amount ( minconf "comment" "comment-to" )},
qq{sendmany "fromaccount" {"address":amount,...} ( minconf "comment" ["address",...] )},
qq{sendtoaddress "bitcoinaddress" amount ( "comment" "comment-to" subtractfeefromamount )},
qq{setaccount "bitcoinaddress" "account"},
qq{settxfee amount},
qq{signmessage "bitcoinaddress" "message"},
);

=pod

=head1 NAME

Bitcoin::RPC::Client::API - Bitcoin Core API RPCs

=head1 SYNOPSIS

   use Bitcoin::RPC::Client::API;

   # print all avaiable API calls
   foreach $method (@Bitcoin::RPC::Client::API::methods) {
      print $method;
   }

=head1 DESCRIPTION

A module that has lists of API commands and their syntax.
Generated from $ bitcoin-cli help
https://bitcoin.org/en/developer-reference

=head1 AUTHOR

Wesley Hinds wesley.hinds@gmail.com

=head1 AVAILABILITY

The latest branch is avaiable from Github.

https://github.com/whindsx/Bitcoin-RPC-Client.git

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Wesley Hinds.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
