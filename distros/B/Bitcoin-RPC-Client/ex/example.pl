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

# When a scalar value is returned
#     https://developer.bitcoin.org/reference/rpc/getbalance.html
$balance = $btc->getbalance("*", 1, JSON::true);
print $balance;
print "\n";

# Getting data when JSON/hash is returned from getblockchaininfo
#     https://developer.bitcoin.org/reference/rpc/getblockchaininfo.html
#
#{
#  "version": 130000,
#  "blocks": 584240,
#  "paytxfee": 0.00500000
#}
$info = $btc->getblockchaininfo;
$blocks = $info->{blocks};
print $blocks;
print "\n";
# 584240

# JSON Objects
# Let's say we want the timeframe value from getnetttotals
#     https://developer.bitcoin.org/reference/rpc/getnettotals.html
#
#{
#  "totalbytesrecv": 7137052851,
#  "totalbytessent": 211648636140,
#  "uploadtarget": {
#    "timeframe": 86400,
#    "target": 0
#  }
#}
$nettot = $btc->getnettotals;
$timeframe = $nettot->{uploadtarget}->{timeframe};
print $timeframe;
print "\n";
# 86400

# JSON arrays
# Let's say we want the feerate_percentiles from getblockstats
#     https://developer.bitcoin.org/reference/rpc/getblockstats.html
#{
#  "avgfee": 8967,
#  "avgfeerate": 28,
#  "feerate_percentiles": [1,1,3,62,65],
#  "height": 584240,
#  "maxfee": 850011
#}
$bstats = $btc->getblockstats(584240);
@fps = @{ $bstats->{feerate_percentiles} };
foreach $fr (@fps) {
   print $fr;
   print "\n";
}
# 1
# 1
# 3
# 62
# 65

exit(0);
