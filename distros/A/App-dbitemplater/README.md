# App-dbitemplater

Handy utility for running a SQL query via DBI and using the output in a template.

## Install

```
perl Makefile.PL
make
make test
make install
```

## Usage

### Flags

#### -c $config

A short config file to use.

This will convert it to `/usr/local/etc/dbitemplater/$config.yaml`.

#### -f $config_file

The full path to the config file to use.

Default: `/usr/local/etc/dbitemplater.yaml`

#### -o

Print to STDOUT even if a file is specified in the config.

#### -h / --help

Print the help info.

#### -v / --version

Print the version info.

### Configuration

The default config is `/usr/local/etc/dbitemplater.yaml`.

| Var          | Description                                                          | Default | Required |
|--------------|----------------------------------------------------------------------|---------|----------|
| `ds`         | The DBI connection string to use.                                    | undef   | 1        |
| `user`       | The user to use for the connection.                                  | undef   | 0        |
| `pass`       | The pass to use for the connection.                                  | undef   | 0        |
| `output`     | The file to use to the results to. If undef it is printed to STDOUT. | undef   | 0        |
| `query`      | The SQL query to run.                                                | undef   | 1        |
| `header`     | The header template to use.                                          | undef   | 1        |
| `row`        | The template to use for each returned row.                           | undef   | 1        |
| `footer`     | The footer template.                                                 | undef   | 1        |
| `POST_CHOMP` | Passed to Template->new                                              | undef   | 0        |
| `PRE_CHOMP`  | Passed to Template->new                                              | undef   | 0        |
| `PRE_CHOMP`  | Passed to Template->new                                              | undef   | 0        |
| `START_TAG`  | Passed to Template->new                                              | undef   | 0        |
| `END_TAG`    | Passed to Template->new                                              | undef   | 0        |

Everything in this config will be passed to the templates via variable `$config`. So you
can add extra variables to use in the template to the config.

### Templates

[Template::Toolkit](https://metacpan.org/dist/Template-Toolkit) is used for templating the
output.

The raw config will be passed to the to all three templates via the variable
'$config'. For the row template there is the hash '$row' that will contain the contents
each row.

If the config contains a slash, it is assumed to be a full path. Otherwise it is assumed
it will be under `/usr/local/etc/dbitemplater/templates/(header|row|footer)/`.

## Example

Lets say you want to set create a HTML display of LibreNMS alerts you could do like
below...

For `/usr/local/etc/dbitemplater.yaml` ...

```
ds: DBI:mysql:database=librenms;hostname=127.0.0.1
user: librenms
pass: somePassword
query: 'select *,alerts.timestamp AS alert_timestamp,alert_rules.notes AS alert_notes,devices.notes AS device_notes from alerts inner join alert_rules on alerts.rule_id = alert_rules.id inner join devices on alerts.device_id = devices.device_id where alerts.state != 0 order by alerts.timestamp DESC'
header: librenms_alerts
row: librenms_alerts
footer: librenms_alerts
librenms_dev_base: https://librenms.foo.bar/device/
```

For `/usr/local/etc/dbitemplater/templates/header/librenms_alerts`...

```
<!DOCTYPE html>
<html>
<body>
<table>
    <tr>
        <th>Alert Name</th>
        <th>Device Hostname</th>
        <th>State</th>
        <th>Status</th>
        <th>Reason</th>
        <th>Timestamp</th>
        <th>Dev Notes</th>
        <th>Alert Notes</th>
    </tr>
```

For `/usr/local/etc/dbitemplater/templates/row/librenms_alerts`...

```
    <tr>
        <th>[% row.name %]</th>
        <th><a href="[% config.librenms_dev_base %][% row.device_id %]">[% row.hostname %]</a></th>
        <th>[% row.state %]</th>
        <th>[% row.status %]</th>
        <th>[% row.status_reason %]</th>
        <th>[% row.alert_timestamp %]</th>
        <th>[% row.device_notes %]</th>
        <th>[% row.alert_notes %]</th>
    </tr>
```

For `/usr/local/etc/dbitemplater/templates/footer/librenms_alerts` ...

```
</table>
</body>
</html>
```
