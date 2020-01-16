## Crypto::NanoRPC

Some Object Oriented perl classes for interacting with a Nano (rai) node

These classes do not need to be installed; you can just use them like this:

```perl
use Crypto::NanoRPC;
```
## Dependencies

The module uses these other modules, which you need to install by CPAN or your favourite package manager

* HTTP::Request;
* LWP::UserAgent;
* JSON;

After meeting these dependencies you can 


```perl
use Data::Dumper;
my $rpc = Crypto::NanoRPC->new();
my $count = $rpc->block_count();
my $newkey = $rpc->key_create();
print Dumper($count);
print Dumper($newkey);
```
Result:
```perl
$VAR1 = {
          'count' => '14452072',
          'unchecked' => '629'
        };
$VAR1 = {
          'public' => '51C9F72ED415331B6F5DDC6E4620EEFB8E87C7EC4011EC697B98D59D57C7C022',
          'account' => 'xrb_1ngbywqfa7bm5fqouq5garigxywgiz5yri1jxjnqq88omodwhi34c9wxgtwf',
          'private' => '5DA0774339494A1FEDC371C4680ACA47036CED78B9757FF6B69B6E5F56443348'
        };
```
Most rpc calls require arguments, see for example https://docs.nano.org/commands/rpc-protocol/#account\_create. Implemented RPC calls
are defined in the array rpc\_calls in NanoRPC.pm. The required arguments can be set using the set\_params() method. The most 
common arguments, "wallet" and "account", have their own set\_ methods.

## Other example uses:

```perl
ny $url = 'http://[::1]:7076';
my $wallet_id = '0000000000000000000000000000000000000000000000000000000000000000'; ## replace with real wallet id
my $account = 'xrb_111111111111111111111111111111111111111111111111111111111111';   ## replace with real account number

my $rpc = NanoRPC->new($url);

my $amount = $rpc->mrai_to_raw(amount => 2)->{amount}; ## 2 Nano, converted to raw

$rpc->set_wallet($wallet_id);

$rpc->set_params(
                    destination => 'xrb_333333333333333333333333333333333333333333333333333333333333'
                    amount => $amount,
                );

my $result = $rpc->send();

if (defined $result->{error}) {
    print "Send $amount raw failed\nError message:" . $result->{error};
} else {
    print "Send $amount succes!\n";
}

```

## Return values

All rpc calls return hashes of key => value pairs. When an error occurs, a hash with 'error' as a single key 'error' will be
returned and the value will be a description of the error.

