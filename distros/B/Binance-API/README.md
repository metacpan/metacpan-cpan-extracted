[![Build Status](https://travis-ci.com/taskula/binance-perl-api.svg?branch=master)](https://travis-ci.com/taskula/binance-perl-api)

# Binance::API

Perl module for interacting with the [Binance API](https://github.com/binance-exchange/binance-official-api-docs/blob/master/rest-api.mdl).

### Requirements

* make
* Net::SSLeay

#### For Debian/Ubuntu users

```
apt update
apt install make libssl-dev libnet-ssleay-perl
```

### Perl dependencies

See lib/Binance/PerlDependencies.pm

OR

```
apt install cpanminus
cd binance-perl-api
sudo cpanm --installdeps .
```

### Installing

```
perl Makefile.PL
make
make test
sudo make install
```

#### Troubleshooting

`perl Makefile.PL` fails:
```
MakeMaker FATAL: prerequisites not found.
    Exception::Class not installed
    JSON not installed


Please install these modules first and rerun 'perl Makefile.PL'.
```

See `lib/Binance/PerlDependencies.pm` for required Perl Modules. In the above case, you would do:
```
sudo cpan Exception::Class
sudo cpan JSON
```

## Running the tests

```
prove -r t/
```

## Usage

```
use strict;
use warnings;

use Binance::API;

my $api = Binance::API->new(
    apiKey => 'my_api_key',
    secretKey => 'my_secret_key',
);

my $ticker = $api->ticker( symbol => 'ETHBTC' );
```

## Contributing

Feel free to provide pull requests!

## Author

Lari Taskula

## Tip jars

* BNB: 0x28226081c6d662cf10662403cf0d8af8a2a9f104
* BTC: 1786L4tQ3uYw3CFUaayAiZB6zsfzQ27i4f
* ETH: 0x28226081c6d662cf10662403cf0d8af8a2a9f104
* LTC: LKcMxdjGxDYCToZ9rv8fRWsQbxJJjsMtRf

## License

MIT ([LICENSE.md](LICENSE.md))
