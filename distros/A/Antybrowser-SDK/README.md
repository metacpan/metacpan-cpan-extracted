# Antybrowser SDK for Perl

[![CPAN](https://img.shields.io/badge/CPAN-Antybrowser::SDK-green)](https://metacpan.org/pod/Antybrowser::SDK)

Official Perl client for the [Antybrowser](https://antybrowser.com) Local API.

## Installation

### CPAN

```sh
cpan Antybrowser::SDK
```

### From source

```sh
perl Makefile.PL
make
make install
```

### Other SDKs

- [TypeScript/JavaScript](../typescript/) · [Python](../python/) · [C#](../csharp/) · [Go](../go/) · [PHP](../php/) · [Ruby](../ruby/) · [Java](../java/) · [Lua](../lua/) · [Elixir](../elixir/)

## Usage

```perl
use Antybrowser::SDK;

my $client = Antybrowser::SDK->new(api_key => 'your_api_key');

# List profiles
my $profiles = $client->get_profiles();

# Create a profile
my $profile = $client->create_profile({ name => 'My Profile' });

# Start a profile
my $result = $client->start_profile($profile->{id});

# Stop a profile
$client->stop_profile($profile->{id});

# Delete a profile
$client->delete_profile($profile->{id});
```

## API

### Constructor

```perl
Antybrowser::SDK->new(api_key => 'key', port => 5173)
```

- `api_key` — your Antybrowser API key (required)
- `port` — API port (default: `5173`)
- `base_url` — override full base URL

### Methods

| Method | Description |
|---|---|
| `get_status()` | Get system status |
| `get_settings()` | Get app settings |
| `get_sync_status()` | Get sync status |
| `refresh_sync($profile_id?)` | Trigger sync refresh |
| `get_profiles()` | List all profiles |
| `create_profile($data)` | Create a new profile |
| `update_profile($id, $data)` | Update a profile |
| `delete_profile($id)` | Delete a profile |
| `start_profile($id)` | Start a profile browser |
| `stop_profile($id)` | Stop a profile browser |
| `duplicate_profile($id, $name?)` | Duplicate a profile |
| `get_automations()` | List automations |
| `run_automation($id, $profile_id)` | Run an automation |
| `get_groups()` | List groups |
| `create_group($data)` | Create a group |
| `update_group($id, $data)` | Update a group |
| `delete_group($id)` | Delete a group |
| `get_proxies()` | List proxies |
| `create_proxy($data)` | Create a proxy |
| `check_proxy($data)` | Check proxy connectivity |
| `delete_proxy($id)` | Delete a proxy |
| `get_extensions()` | List extensions |
| `delete_extension($id)` | Delete an extension |
| `get_profile_extensions($profile_id)` | List profile extensions |
| `set_profile_extensions($profile_id, $extension_ids)` | Set profile extensions |

## License

MIT
