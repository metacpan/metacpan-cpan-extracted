# CAPE-Utils

Utilities for use with CAPEv2.

## Installation

### FreeBSD

Only relevant for `suricata_extract_submit`.

```
pkg install p5-App-cpanminus
cpanm CAPE::Utils
```

## Debian/Ubuntu

For Debian, only `suricata_extract_submit` is relevant.

```
apt-get install cpanminus
cpanm CAPE::Utils
```

## Configuration

### suricata_extract_submit

The config file used is '/usr/local/etc/suricata_extract_submit.ini'.

```
# the API key to use if needed
#apikey=
# URL to find mojo_cape_submit at
url=http://192.168.14.15:8080/
# the group/client/whathaveya slug
slug=foo
# where Suricata has the file store at
filestore=/var/log/suricata/files
# a file of IPs or subnets to ignore SRC or DEST IPs of
#ignore=
```

Then a cron job set up like below.

```
*/5 * * * * /usr/local/bin/suricata_extract_submit 2> /dev/null > /dev/null
```

Suricata just needs the file-store output setup akin to below.

```
  - file-store:
      version: 2
      enabled: yes
      dir: /var/log/suricata/files
      write-fileinfo: yes
      stream-depth: 0
      force-hash: [sha1, md5]
      xff:
        enabled: no
        mode: extra-data
        deployment: reverse
        header: X-Forwarded-For
```

### CAPE::Utils

The default config file is '/usr/local/etc/cape_utils.ini'.

The defaults are as below, which out of the box, it will work by
default with CAPEv2 in it's default config.

```
# The DBI dsn to use
dsn=dbi:Pg:dbname=cape
# DB user
user=cape
# DB password
pass=
# the install base for CAPEv2
base=/opt/CAPEv2/
# 0/1 if poetry should be used
poetry=1
# 0/1 if fail should be allowed to run with out a where statement
fail_all=0
# colums to use for pending table show
pending_columns=id,target,package,timeout,ET,route,options,clock,added_on
# colums to use for runniong table show
running_columns=id,target,package,timeout,ET,route,options,clock,added_on,started_on,machine
# colums to use for tasks table
task_columns=id,target,package,timeout,ET,route,options,clock,added_on,latest,machine,status
# if the target column for running table display should be clipped to the filename
running_target_clip=1
# if microseconds should be clipped from time for running table display
running_time_clip=1
# if the target column for pending table display should be clipped to the filename
pending_target_clip=1
# if microseconds should be clipped from time for pending table display
pending_time_clip=1
# if the target column for task table display should be clipped to the filename
task_target_clip=1
# if microseconds should be clipped from time for task table display
task_time_clip=1
# default table color
table_color=Text::ANSITable::Standard::NoGradation
# default table border
table_border=ASCII::None
# when submitting use now for the current time
set_clock_to_now=1
# default timeout value for submit
timeout=200
# default value for enforce timeout for submit
enforce_timeout=0
# the api key to for with mojo_cape_submit
#apikey=
# auth by IP only for mojo_cape_submit
auth_by_IP_only=1
 # comma seperated list of allowed subnets for mojo_cape_submit
subnets=192.168.0.0/16,127.0.0.1/8,::1/128,172.16.0.0/12,10.0.0.0/8
# incoming dir to use for mojo_cape_submit
incoming=/malware/client-incoming
# directory to store json data files for submissions recieved by mojo_cape_submit
incoming_json=/malware/incoming-json
```

### mojo_cape_submit

If cape_utils has been configured and is working, this just requires
two more additional bits configured.

The first is the setting 'incoming'. This setting is a directory in
which incoming files are placed for submission. By default this is
'/malware/client-incoming'.

The second is 'incoming_json'. This is a directory the data files for
submitted files are written to. The name of the file is the task ID
with '.json' appended. So task ID '123' would become '123.json'. The
default directory for this is '/malware/incoming-json'.

By default this will auth of the remote IP via the setting 'subnets',
which by default is
'192.168.0.0/16,127.0.0.1/8,::1/128,172.16.0.0/12,10.0.0.0/8'. This
value is a comma seperated string of subnets to accept submissions
from.

To enable the use of a API key, it requires setting the value of
'apikey' and setting 'auth_by_IP_only' to '0'.

Using the provided systemd service file, you will also need to create
'/usr/local/etc/mojo_cape_submit.env' and configure it akin to below.

```
CAPE_USER="cape"
LISTEN_ON="http://192.168.14.15:8080"
```
