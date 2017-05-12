#!/bin/sh

# Mapping to an unknown timezone database
echo "[DCE Config]"
sed -n '/"[A-Z].*tzfile=/ s/^.*"\([^"]*\)".*"\([^"]*\)".*$/  \1: \2/p' /etc/dce_config

# Mapping to Olson DB
echo "[Java]"
export TZ
grep '^[A-Z]' /usr/lib/tztab | while read TZ
do
	echo "  $TZ: $(java -cp "$(dirname "$0")"/../lib/DateTime/TimeZone/HPUX TZ)"
done
