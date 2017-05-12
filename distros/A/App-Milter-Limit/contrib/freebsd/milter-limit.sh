#!/bin/sh
#
# rc script for FreeBSD

# PROVIDE: milter_limit
# REQUIRE: mail
# KEYWORD: shutdown

#
# Add the following line to /etc/rc.conf to enable milter-limit:
# milter_limit_enable (bool):    Set to "NO" by default.
#                                Set it to "YES" to enable milter-limit.
#

. /etc/rc.subr

name="milter_limit"
rcvar="${name}_enable"

command="/usr/local/bin/milter-limit"

[ -z "${milter_limit_enable}" ] && milter_limit_enable="NO"
[ -z "${milter_limit_pidfile}" ] && milter_limit_pidfile="/var/run/milter-limit/milter-limit.pid"
[ -z "${milter_limit_configfile}" ] && milter_limit_configfile="/etc/mail/milter-limit.conf"

load_rc_config "${name}"

pidfile="${milter_limit_pidfile}"

required_files="${milter_limit_configfile}"
command_args=""

run_rc_command "$1"
