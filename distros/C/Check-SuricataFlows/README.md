# Check-SuricataFlows

This reads the Suricata EVE JSON flow data file.

    .timestamp :: Used for double checking to make sure we don't read farther
        back than we need to.

If the following is found, the entry is checked.

    .dest_ip
    .src_ip
    .flow.pkts_toclient
    .flow.pkts_toserver

Bi-directional is when .flow.pkts_toclient and .flow.pkts_toserver are both greater
than zero.

Uni-directional is when only .flow.pkts_toclient or .flow.pkts_toserver is greater
than zero and the other is zero.

If all entries found are uni-directional then it is safe to assume the monitored span
is misconfigured.

If more than one Suricata instance is appending to the file, you will likely want to use
-s to specify each sensor name to check for.

## FLAGS

```
check_suricataflows [-f <flows.json>] [-a <alert count>] [-w <warn
    count>] [-t <seconds>] [<-m> <max lines>]

check_suricataflows [B<-f> <flows.json>] [B<-a> <alert count>] [B<-w> <warn count>]
    [B<-t> <seconds>] [<-m> <max lines>] B<-s> <sensor> [B<-s> <sensor>]

check_suricataflows -h/--help

check_suricataflows -v/--version
```

### -f flows.json

The flows EVE JSON location.

Default: /var/log/suricata/flows/current/flow.json

### -a alert_count

Alert if the number of bidirectional flows are less than this.

Default: 10

### head2 -w warn_count

Warn if the number of directional flows are less than this.

Default: 20

### -t seconds

How far back into the file to read in seconds.

Default: 300

### -m max_lines

Max number of lines to read in.

### -s sensor

Sensor names to check for. May used more than once.

If used then each of the specified sensors is checked for. It is
checked from .host in the JSON and the variable for setting that
in the Suricata config is .sensor-name .

If more than once Suricata instance is appending to the file, then
you will most likely want to use this.

### -i IP

An IP to ignore.

# SNECK

If [Monitoring::Sneck::Checks](https://github.com/VVelox/Monitoring-Sneck-Checks)
is installed, this can also be run in process by
[sneck](https://github.com/VVelox/Monitoring-Sneck) as `perl:suricata_flows`,
or from the shell through `sneck_check`. Monitoring::Sneck::Checks is optional
and not installed along with this.

```
suricata_flows|perl:suricata_flows -s sensor1 -s sensor2 -i 192.0.2.1
```

```
sneck_check suricata_flows -f /var/log/suricata/flows/current/flow.json
```

It takes the same options as check_suricataflows, -f, -a, -w, -t, -m, -s,
and -i, and works out the status the same way. The status line has the
bi and uni directional counts and perfdata, followed by the same lines
check_suricataflows prints.

See `perldoc Monitoring::Sneck::Checks::suricata_flows`.

# INSTALLATION

## FreeBSD

```
pkg install p5-JSON p5-File-ReadBackwards p5-NetAddr-IP p5-Regexp-IPv6 p5-App-cpanminus
cpanm Check::SuricataFlows
```

## Debian

```
apt-get install libjson-perl libfile-readbackwards-perl libnetaddr-ip-perl libregexp-ipv6-perl cpanminus
cpanm Check::SuricataFlows
```

cpanm installs anything not packaged, such as Regexp::IPv4.

## From Source

Install the dependencies, JSON, File::ReadBackwards, NetAddr::IP,
Regexp::IPv4, and Regexp::IPv6, then run the following commands:

	perl Makefile.PL
	make
	make test
	make install
