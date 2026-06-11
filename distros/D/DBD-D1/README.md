# DBD::D1 — DBI driver for Cloudflare D1

A pure-Perl [DBI](https://metacpan.org/pod/DBI) driver for
[Cloudflare D1](https://developers.cloudflare.com/d1/).

## Quick Start

```perl
use DBI;

my $dbh = DBI->connect(
    'dbi:D1:account_id=<ACCOUNT_ID>;database_id=<DATABASE_ID>',
    undef,
    $ENV{CF_API_TOKEN},
    { RaiseError => 1 },
) or die $DBI::errstr;

my $sth = $dbh->prepare('SELECT * FROM users WHERE active = ?');
$sth->execute(1);

while (my $row = $sth->fetchrow_hashref) {
    print "$row->{name}\n";
}

$dbh->disconnect;
```

## Requirements

```
cpanm DBI IO::Socket::SSL Net::SSLeay
```

HTTP::Tiny and JSON::PP ship with Perl 5.14+.

## Installation

```bash
perl Makefile.PL && make && make test && make install
```

## Running Live Tests

```bash
export CF_ACCOUNT_ID=your_account_id
export CF_D1_DATABASE_ID=your_database_uuid
export CF_API_TOKEN=your_api_token
make test
```

## License

Same terms as Perl itself.
