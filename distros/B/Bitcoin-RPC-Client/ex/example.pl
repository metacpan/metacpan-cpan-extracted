#!/usr/bin/perl 

use Bitcoin::RPC::Client;

##
# Bitcoin global Vars (user supplied)
##
$RPCHOST = "Your.IP.Address.Here";

# User for RPC commands to bitcoind
$RPCUSER = "YourBitcoindRPCUserName";

# RPC password to bitcoind
$RPCPASSWORD = 'YourBitcoindRPCPassword';

# Create RPC object
$btc = Bitcoin::RPC::Client->new(
    host     => $RPCHOST,
    user     => $RPCUSER,
    password => $RPCPASSWORD,
);

# https://bitcoin.org/en/developer-reference#getinfo
$info   = $btc->getinfo;
$blocks = $info->{blocks};
print $blocks;

# https://bitcoin.org/en/developer-reference#getbalance
$balance = $btc->getbalance("root", 1, JSON::true);
print $balance;

# https://bitcoin.org/en/developer-reference#getblockchaininfo
$info  = $btc->getblockchaininfo;
print $info->{softforks}[0]->{id};


###
# More on handling JSON data
###

# Getting Data when JSON/hash is returned from getinfo 
#     https://bitcoin.org/en/developer-reference#getinfo
#
#{
#  "version": 130000,
#  "protocolversion": 70014,
#  "walletversion": 130000,
#  "balance": 0.00000000,
#  "blocks": 584240,
#  "proxy": "",
#  "difficulty": 1,
#  "paytxfee": 0.00500000,
#  "relayfee": 0.00001000,
#  "errors": ""
#}
$info    = $btc->getinfo;
$balance = $info->{balance};
print $balance;
# 0.0
 
# JSON Objects
# Let's say we want the timeframe value from getnetttotals
#     https://bitcoin.org/en/developer-reference#getnettotals
#
#{
#  "totalbytesrecv": 7137052851,
#  "totalbytessent": 211648636140,
#  "uploadtarget": {
#    "timeframe": 86400,
#    "target": 0,
#    "target_reached": false,
#    "serve_historical_blocks": true,
#    "bytes_left_in_cycle": 0,
#    "time_left_in_cycle": 0
#  }
#}
$nettot = $btc->getnettotals;
$timeframe = $nettot->{uploadtarget}{timeframe};
print $timeframe;
# 86400
 
# JSON arrays
# Let's say we want the softfork IDs from getblockchaininfo
#     https://bitcoin.org/en/developer-reference#getblockchaininfo
#
#{
#  "chain": "main",
#  "blocks": 464562,
#  "headers": 464562,
#  "pruned": false,
#  "softforks": [
#    {
#      "id": "bip34",
#      "version": 2,
#      "reject": {
#        "status": true
#      }
#    },
#    {
#      "id": "bip66",
#      "version": 3,
#      "reject": {
#        "status": true
#      }
#    }
$bchain = $btc->getblockchaininfo;
@forks = @{ $bchain->{softforks} };
foreach $f (@forks) {
   print $f->{id};
   print "\n";
}
# bip34
# bip66


exit(0);
