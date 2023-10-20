# API::Vultr

A simple Perl interface to the [Vultr](https://www.vultr.com) API, using [LWP::UserAgent](https://github.com/libwww-perl/libwww-perl).

## Example

Please read the `POD` associated with `API::Vultr`, and the [Vultr API](https://vultr.com/api) to get a better understanding of all of the
available methods.

```perl
use API::Vultr;
use Data::Dumper qw(Dumper);

my $vultr_api = API::Vultr->new(api_key => $ENV{VULTR_API_KEY});

my $create_response = $vultr_api->create_instance(
    region => 'ewr',
    plan => 'vc2-6c-16gb',
    label => 'My Instance',
    os_id => 215,
    user_data => 'QmFzZTY4EVsw32WfsGGHsjKJI',
    backups => 'enabled',
    hostname => 'hostname'
);

if ($create_response->is_success) {
    print Dumper($create_response->decoded_content);
}
else {
    die $create_response->status_line;
}
```

## License

This project is licensed under the Artistic 2.0 license. Please read the `LICENSE` file at the root of the
project for more information on what that means.
