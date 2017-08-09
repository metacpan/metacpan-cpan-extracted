## DarkSky.net Wrapper

This is a wrapper for the darksky.net API. You need an API key to
use it (https://darksky.net/dev/). Please consult the API docs at
https://darksky.net/dev/.


## Example Use


```perl
use DarkSky::API;
use Data::Dumper;

my $lat  = 43.6667;
my $long = -79.4167;
my $time = "1475363709"; # example epoch time (optional)
my $key = "c9ce1c59d139c3dc62961cbd63097d13"; # example DarkSky.net API key

my $forecast = DarkSky::API->new(
    key       => $key,
    longitude => $long,
    latitude  => $lat,
    time      => $time
);

say "current temperature: " . $forecast->{currently}->{temperature};

my @daily_data_points = @{ $forecast->{daily}->{data} };

# Use your imagination about how to use this data.
# in the meantime, inspect it by dumping it.
for (@daily_data_points) {
    print Dumper($_);
}
```

## Build, release

```sh
$ dzil build
$ dzil test
$ dzil install
$ dzil clean
$ dzil release
```

## Links

Patches/suggestions welcome

Github: https://github.com/mlbright/DarkSky-API
