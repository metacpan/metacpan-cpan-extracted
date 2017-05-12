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
print "\n";

# https://bitcoin.org/en/developer-reference#getbalance
$balance = $btc->getbalance("root", 1, JSON::true);
print $balance;
print "\n";

# https://bitcoin.org/en/developer-reference#getblockchaininfo
$info  = $btc->getblockchaininfo;
print $info->{softforks}[0]->{id};
print "\n";

exit(0);
