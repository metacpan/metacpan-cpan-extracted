package App::MonM::Skel::Share; # $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
use strict;

use CTK::Util qw/ :BASE /;

use constant SIGNATURE => "share";
use constant MAKE_TOOLS_WIN => <<'WIN';
# --- MakeMaker tools_other section:
EXE_EXT    = .exe
PERL       = perl -w
PERLEU     = $(PERL) -MExtUtils::Command
FIXIN      = pl2bat.bat
NOOP       = rem
NOECHO     = @
UMASK_NULL = umask 0
DEV_NULL   = > NUL
UNINST     = 0
VERBINST   = 0
PERM_DIR   = 755
PERM_RW    = 644
PERM_RWX   = 755

CHMOD      = $(PERLEU) -e chmod --
CP         = $(PERLEU) -e cp --
MV         = $(PERLEU) -e mv --
RM_F       = $(PERLEU) -e rm_f --
RM_RF      = $(PERLEU) -e rm_rf --
TEST_F     = $(PERLEU) -e test_f --
TOUCH      = $(PERLEU) -e touch --
MKPATH     = $(PERLEU) -e mkpath --
EQTIME     = $(PERLEU) -e eqtime --
FALSE      = $(PERL) -e "exit 1" --
TRUE       = $(PERL) -e "exit 0" --
ECHO       = $(PERL) -l -e "print qq{{@ARGV}}" --
ECHO_N     = $(PERL) -e "print qq{{@ARGV}}" --
WIN

use constant MAKE_TOOLS_UNX => <<'UNX';
# --- MakeMaker tools_other section:
EXE_EXT    = .exe
PERL       = perl -w
PERLEU     = $(PERL) -MExtUtils::Command
FIXIN      = $(PERL) -MExtUtils::MY -e 'MY->fixin(shift)' --
NOOP       = true
NOECHO     = @
UMASK_NULL = umask 0
DEV_NULL   = > /dev/null 2>&1
UNINST     = 0
VERBINST   = 0
PERM_DIR   = 755
PERM_RW    = 644
PERM_RWX   = 755

CHMOD      = $(PERLEU) -e chmod --
CP         = $(PERLEU) -e cp --
MV         = $(PERLEU) -e mv --
RM_F       = $(PERLEU) -e rm_f --
RM_RF      = $(PERLEU) -e rm_rf --
TEST_F     = $(PERLEU) -e test_f --
TOUCH      = $(PERLEU) -e touch --
MKPATH     = $(PERLEU) -e mkpath --
EQTIME     = $(PERLEU) -e eqtime --
FALSE      = $(PERL) -e "exit 1" --
TRUE       = $(PERL) -e "exit 0" --
ECHO       = $(PERL) -l -e "print qq{{@ARGV}}" --
ECHO_N     = $(PERL) -e "print qq{{@ARGV}}" --
TMP_PFX    = /tmp/
UNX

use constant GRAPHS_TYPICAL => <<'GRAPHS_TYPICAL';
# --- Typical graphs section:
$(TMP_PFX)$(PROJECT).quarter.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(QUARTER)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).quarter.proc
	$(NOECHO) $(RRDTOOL) graph $(QUARTER) $(GRAPH_PFX) \
		--title "$(NAME) 6 hours (5 Minute Average)" \
		--start -6h --end now \
		--x-grid "MINUTE:20:HOUR:1:HOUR:1:0:%a %H:%M" $(GRAPH_SFX)
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).daily.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(DAILY)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).daily.proc
	$(NOECHO) $(RRDTOOL) graph $(DAILY) $(GRAPH_PFX) \
		--title "$(NAME) daily (5 Minute Average)" \
		--start -27h --end now \
		--x-grid "MINUTE:20:HOUR:1:HOUR:3:0:%a %H:%M" $(GRAPH_SFX) VRULE:$(BRD_D)#EE0000
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).weekly.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(WEEKLY)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).weekly.proc
	$(NOECHO) $(RRDTOOL) graph $(WEEKLY) $(GRAPH_PFX) \
		--title "$(NAME) weekly (30 Minute Average)" \
		--start -8d --end now \
		--x-grid "HOUR:6:DAY:1:DAY:1:86400:%a %d/%m" $(GRAPH_SFX) VRULE:$(BRD_W)#EE0000
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).monthly.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(MONTHLY)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).monthly.proc
	$(NOECHO) $(RRDTOOL) graph $(MONTHLY) $(GRAPH_PFX) \
		--title "$(NAME) monthly (2 Hour Average)" \
		--start -1mon1d --end now \
		--x-grid "DAY:3:DAY:1:DAY:3:0:%d/%m" $(GRAPH_SFX) VRULE:$(BRD_M)#EE0000
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).yearly.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(YEARLY)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).yearly.proc
	$(NOECHO) $(RRDTOOL) graph $(YEARLY) $(GRAPH_PFX) \
		--title "$(NAME) yearly (1 Day Average)" \
		--start -13mon --end now \
		--x-grid "MONTH:3:MONTH:1:MONTH:1:2592000:%b" $(GRAPH_SFX) VRULE:$(BRD_Y)#EE0000
	$(NOECHO) $(ECHO) Done.
GRAPHS_TYPICAL

use vars qw($VERSION);
$VERSION = '1.02';

sub build { # Процесс сборки
    my $self = shift;
    
    my $rplc = $self->{rplc};
    $rplc->{MAKE_TOOLS} = isostype('Windows') ? MAKE_TOOLS_WIN : MAKE_TOOLS_UNX;
    $rplc->{'GRAPHS_TYPICAL'} = GRAPHS_TYPICAL;

    $self->maybe::next::method();
    return 1;
}
sub dirs { # Список директорий и прав доступа к каждой из них
    my $self = shift;    
    $self->{subdirs}{(SIGNATURE)} = [
        #{
        #    path => '%BAZ%',
        #    mode => 0755,
        #},
        {
            path => 'www',
            mode => 0755,
        },
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool { # Бассеин с разделенными multipart файламми
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;
__DATA__

-----BEGIN FILE-----
Name: agrrd.sh
File: agrrd.sh
Mode: 711
Type: Unix

#!/bin/sh
#
# Exmaple (in crontab):
#
# */2  *  *  *  * /usr/share/monm/agrrd.sh >/dev/null 2>/var/log/monm_agrrd_error.log
#

# Run local agent
/usr/local/bin/monm alertgrid agent -o /dev/null

# Export data from alertgrid database into rrd database
/usr/local/bin/monm alertgrid export -F xml | /usr/local/bin/monm rrd update -I -o /dev/null

# Creating graphs
/usr/local/bin/monm rrd graph -o /dev/null

-----END FILE-----

-----BEGIN FILE-----
Name: agrrd.bat
File: agrrd.bat
Type: Windows

rem Утилита создания ряда операций для совметной работы alertgrid и rrd
rem Данная утилита должна выполняться с равными небольшими интервалами времени таким образом,
rem чтобы все переданные данные своевременно обновляли данные в базах RRD

@echo off

rem Run local agent
monm alertgrid agent

rem Export data from alertgrid database into rrd database 
monm alertgrid export -F xml | monm rrd update -I

rem Creating graphs
monm rrd graph

-----END FILE-----

-----BEGIN FILE-----
Name: alertgrid.cgi
File: www/alertgrid.cgi
Mode: 711

#!/usr/bin/perl -w
use strict; # %DOLLAR%Id%DOLLAR%

use WWW::MLite;

my $mlite = new WWW::MLite(
        prefix  => 'alertgrid',
        name    => 'Server',
        module  => 'App::MonM::AlertGrid::Server',

        # You MAY specify the location of the configuration file App::MonM (alertgrid.conf)
        #config_file => '/etc/monm/conf.d/alertgrid.conf',

        # You also MAY specify the default location of the database file AlertGrid (alertgrid.db)
        #params  => {
        #        dbfile => '/var/db/alertgrid.db',
        #    },

    );
$mlite->show;
-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.net
File: Makefile.net
Mode: 644

#
# Makefile for Windows or Unix/Linux platform only
#
# $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
# GENERATED: %GENERATED%
#
PROJECT    = monm_rrd
RRDTOOL    = rrdtool

%MAKE_TOOLS%

GRAPH_PFX = --imgformat PNG \
 -v "Bits per Second" \
 --base 1000 \
 --width 640 --height 260 \
 --color ARROW\#EE0000

GRAPH_SFX = DEF:inoctets=$(FILE):input:AVERAGE \
 DEF:outoctets=$(FILE):output:AVERAGE \
 CDEF:in=inoctets,8,* \
 CDEF:out=outoctets,8,* \
 VDEF:in_cur=in,LAST \
 VDEF:in_avg=in,AVERAGE \
 VDEF:in_min=in,MINIMUM \
 VDEF:in_max=in,MAXIMUM \
 VDEF:out_cur=out,LAST \
 VDEF:out_avg=out,AVERAGE \
 VDEF:out_min=out,MINIMUM \
 VDEF:out_max=out,MAXIMUM \
 "COMMENT:\\s" \
 "COMMENT:----------------------------------------------------------------------------------------------------\\s" \
 "COMMENT:\\s" \
 "COMMENT:\\t\\t\\t      Current\\t\\t Average\\t    Minimum\\t\\tMaximum\\s" \
 "COMMENT:\\s" \
 "COMMENT:----------------------------------------------------------------------------------------------------\\s" \
 "COMMENT:\\s" \
 "COMMENT: " \
 AREA:in\#00FF00:"In traffic" \
 GPRINT:in_cur:\\t%8.0lf%s \
 GPRINT:in_avg:\\t%8.0lf%s \
 GPRINT:in_min:\\t%8.0lf%s \
 GPRINT:in_max:\\t%8.0lf%s\\l \
 "COMMENT: " \
 LINE1:out\#0000FF:"Out traffic" \
 GPRINT:out_cur:\\t%8.0lf%s \
 GPRINT:out_avg:\\t%8.0lf%s \
 GPRINT:out_min:\\t%8.0lf%s \
 GPRINT:out_max:\\t%8.0lf%s\\l \
 "COMMENT: " \
 "COMMENT:\\s" \
 "COMMENT:----------------------------------------------------------------------------------------------------\\l" \
 "COMMENT:Generated\: $(PUBDATE)\\r" \

.PHONY: all create update graph

.USESHELL:

all:
	$(NOECHO) $(ECHO) "Usage:"
	$(NOECHO) $(ECHO) "    dmake create FILE=..."
	$(NOECHO) $(ECHO) "    dmake update FILE=... INPUT=... OUTPUT=..."
	$(NOECHO) $(ECHO) "    dmake graph FILE=... NAME=... ...other..."

create:
	$(NOECHO) $(ECHO) Creating $(FILE)...
	$(NOECHO) $(RRDTOOL) create $(FILE) \
		--step 300 \
		DS:input:COUNTER:600:U:U \
		DS:output:COUNTER:600:U:U \
		RRA:AVERAGE:0.5:1:600 \
		RRA:AVERAGE:0.5:6:700 \
		RRA:AVERAGE:0.5:24:775 \
		RRA:AVERAGE:0.5:288:797 \
		RRA:MIN:0.5:1:600 \
		RRA:MIN:0.5:6:700 \
		RRA:MIN:0.5:24:775 \
		RRA:MIN:0.5:288:797 \
		RRA:MAX:0.5:1:600 \
		RRA:MAX:0.5:6:700 \
		RRA:MAX:0.5:24:775 \
		RRA:MAX:0.5:288:797
	$(NOECHO) $(ECHO) Done.

update:
	$(NOECHO) $(ECHO) Updating $(FILE)...
	$(NOECHO) $(RRDTOOL) update $(FILE) \
		--template input:output \
		$(PUBDATE):$(INPUT):$(OUTPUT)
	$(NOECHO) $(ECHO) Done.

graph:
	$(NOECHO) $(ECHO) Plotting $(MINI)...
	$(NOECHO) $(RRDTOOL) graph $(MINI) \
		--imgformat PNG --slope-mode --rigid \
		--title "$(NAME) 3h" \
		-v bps \
		--base 1000 \
		--start -3h --end now \
		--width 150 --height 50 \
		--x-grid "MINUTE:10:HOUR:1:HOUR:1:0:%H:%M" \
		--color ARROW#EE0000 \
		DEF:inoctets=$(FILE):input:AVERAGE \
		DEF:outoctets=$(FILE):output:AVERAGE \
		CDEF:in=inoctets,8,* \
		CDEF:out=outoctets,8,* \
		VDEF:in_cur=in,LAST \
		VDEF:out_cur=out,LAST \
		AREA:in#00FF00:In \
		GPRINT:in_cur:%3.0lf%s \
		LINE1:out#0000FF:Out \
		GPRINT:out_cur:%3.0lf%s
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(QUARTER)...
	$(NOECHO) $(RRDTOOL) graph $(QUARTER) $(GRAPH_PFX) \
		--title "$(NAME) 6 hours (5 Minute Average)" \
		--start -6h --end now \
		--x-grid "MINUTE:20:HOUR:1:HOUR:1:0:%a %H:%M" $(GRAPH_SFX)
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(DAILY)...
	$(NOECHO) $(RRDTOOL) graph $(DAILY) $(GRAPH_PFX) \
		--title "$(NAME) daily (5 Minute Average)" \
		--start -27h --end now \
		--x-grid "MINUTE:20:HOUR:1:HOUR:3:0:%a %H:%M" $(GRAPH_SFX) VRULE:$(BRD_D)#EE0000
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(WEEKLY)...
	$(NOECHO) $(RRDTOOL) graph $(WEEKLY) $(GRAPH_PFX) \
		--title "$(NAME) weekly (30 Minute Average)" \
		--start -8d --end now \
		--x-grid "HOUR:6:DAY:1:DAY:1:86400:%a %d/%m" $(GRAPH_SFX) VRULE:$(BRD_W)#EE0000
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(MONTHLY)...
	$(NOECHO) $(RRDTOOL) graph $(MONTHLY) $(GRAPH_PFX) \
		--title "$(NAME) monthly (2 Hour Average)" \
		--start -1mon1d --end now \
		--x-grid "DAY:3:DAY:1:DAY:3:0:%d/%m" $(GRAPH_SFX) VRULE:$(BRD_M)#EE0000
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(YEARLY)...
	$(NOECHO) $(RRDTOOL) graph $(YEARLY) $(GRAPH_PFX) \
		--title "$(NAME) yearly (1 Day Average)" \
		--start -13mon --end now \
		--x-grid "MONTH:3:MONTH:1:MONTH:1:2592000:%b" $(GRAPH_SFX) VRULE:$(BRD_Y)#EE0000
	$(NOECHO) $(ECHO) Done.

-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.res
File: Makefile.res
Mode: 644

#
# Makefile for Windows or Unix/Linux platform only
#
# $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
# GENERATED: %GENERATED%
#
PROJECT    = monm_rrd
RRDTOOL    = rrdtool

%MAKE_TOOLS%

GRAPH_PFX = --imgformat PNG \
 -v "Load, %" \
 --base 1000 \
 --width 640 --height 260 \
 --color ARROW\#EE0000

GRAPH_SFX = DEF:mem=$(FILE):mem:AVERAGE \
 DEF:swp=$(FILE):swp:AVERAGE \
 DEF:cpu=$(FILE):cpu:AVERAGE \
 DEF:hdd=$(FILE):hdd:AVERAGE \
 VDEF:mem_cur=mem,LAST \
 VDEF:mem_avg=mem,AVERAGE \
 VDEF:mem_min=mem,MINIMUM \
 VDEF:mem_max=mem,MAXIMUM \
 VDEF:swp_cur=swp,LAST \
 VDEF:swp_avg=swp,AVERAGE \
 VDEF:swp_min=swp,MINIMUM \
 VDEF:swp_max=swp,MAXIMUM \
 VDEF:cpu_cur=cpu,LAST \
 VDEF:cpu_avg=cpu,AVERAGE \
 VDEF:cpu_min=cpu,MINIMUM \
 VDEF:cpu_max=cpu,MAXIMUM \
 VDEF:hdd_cur=hdd,LAST \
 VDEF:hdd_avg=hdd,AVERAGE \
 VDEF:hdd_min=hdd,MINIMUM \
 VDEF:hdd_max=hdd,MAXIMUM \
 "COMMENT:\\s" \
 "COMMENT:----------------------------------------------------------------------------------------------------\\s" \
 "COMMENT:\\s" \
 "COMMENT:\\t\\t\\t\\t\\t\\tCurrent\\t\\t  Average\\t\\t    Minimum\\t      Maximum\\s" \
 "COMMENT:\\s" \
 "COMMENT:----------------------------------------------------------------------------------------------------\\s" \
 "COMMENT:\\s" \
 "COMMENT: " \
 LINE2:mem\#00FF00:"Memory usage\\t" \
 GPRINT:mem_cur:\\t%7.0lf%s \
 GPRINT:mem_avg:\\t%7.0lf%s \
 GPRINT:mem_min:\\t%7.0lf%s \
 GPRINT:mem_max:\\t%7.0lf%s\\l \
 "COMMENT: " \
 LINE2:swp\#FFFF00:"Swap usage  \\t" \
 GPRINT:swp_cur:\\t%7.0lf%s \
 GPRINT:swp_avg:\\t%7.0lf%s \
 GPRINT:swp_min:\\t%7.0lf%s \
 GPRINT:swp_max:\\t%7.0lf%s\\l \
 "COMMENT: " \
 LINE2:cpu\#FF0000:"CPU usage   \\t" \
 GPRINT:cpu_cur:\\t%7.0lf%s \
 GPRINT:cpu_avg:\\t%7.0lf%s \
 GPRINT:cpu_min:\\t%7.0lf%s \
 GPRINT:cpu_max:\\t%7.0lf%s\\l \
 "COMMENT: " \
 LINE2:hdd\#0000FF:"Disk usage  \\t" \
 GPRINT:hdd_cur:\\t%7.0lf%s \
 GPRINT:hdd_avg:\\t%7.0lf%s \
 GPRINT:hdd_min:\\t%7.0lf%s \
 GPRINT:hdd_max:\\t%7.0lf%s\\l \
 "COMMENT:\\s" \
 "COMMENT:----------------------------------------------------------------------------------------------------\\l" \
 "COMMENT:Generated\: $(PUBDATE)\\r" \

.PHONY: all create update graph

.USESHELL:

all:
	$(NOECHO) $(ECHO) "Usage:"
	$(NOECHO) $(ECHO) "    dmake create FILE=..."
	$(NOECHO) $(ECHO) "    dmake update FILE=... INPUT=... OUTPUT=..."
	$(NOECHO) $(ECHO) "    dmake graph FILE=... NAME=... ...other..."

create:
	$(NOECHO) $(ECHO) Creating $(FILE)...
	$(NOECHO) $(RRDTOOL) create $(FILE) \
		--step 300 \
		DS:cpu:GAUGE:600:0:100 \
		DS:hdd:GAUGE:600:0:100 \
		DS:mem:GAUGE:600:0:100 \
		DS:swp:GAUGE:600:0:100 \
		RRA:AVERAGE:0.5:1:600 \
		RRA:AVERAGE:0.5:6:700 \
		RRA:AVERAGE:0.5:24:775 \
		RRA:AVERAGE:0.5:288:797 \
		RRA:MIN:0.5:1:600 \
		RRA:MIN:0.5:6:700 \
		RRA:MIN:0.5:24:775 \
		RRA:MIN:0.5:288:797 \
		RRA:MAX:0.5:1:600 \
		RRA:MAX:0.5:6:700 \
		RRA:MAX:0.5:24:775 \
		RRA:MAX:0.5:288:797

	$(NOECHO) $(ECHO) Done.

update:
	$(NOECHO) $(ECHO) Updating $(FILE)...
	$(NOECHO) $(RRDTOOL) update $(FILE) \
		--template cpu:hdd:mem:swp \
		$(PUBDATE):$(CPU):$(HDD):$(MEM):$(SWP)
	$(NOECHO) $(ECHO) Done.

graph: 
	$(NOECHO) $(ECHO) Plotting $(MINI)...
	$(NOECHO) $(RRDTOOL) graph $(MINI) \
		--imgformat PNG --slope-mode --rigid \
		--title "$(NAME) 3h" \
		-v "Load, %" \
		--base 1000 \
		--start -3h --end now \
		--width 150 --height 50 \
		--x-grid "MINUTE:10:HOUR:1:HOUR:1:0:%H:%M" \
		--color ARROW#EE0000 \
		DEF:mem=$(FILE):mem:AVERAGE \
		DEF:swp=$(FILE):swp:AVERAGE \
		DEF:cpu=$(FILE):cpu:AVERAGE \
		DEF:hdd=$(FILE):hdd:AVERAGE \
		LINE1:mem#00FF00:MEM \
		LINE1:swp#FFFF00:SWP \
		LINE1:cpu#FF0000:CPU \
		LINE1:hdd#0000FF:HDD
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(QUARTER)...
	$(NOECHO) $(RRDTOOL) graph $(QUARTER) $(GRAPH_PFX) \
		--title "$(NAME) 6 hours (5 Minute Average)" \
		--start -6h --end now \
		--x-grid "MINUTE:20:HOUR:1:HOUR:1:0:%a %H:%M" $(GRAPH_SFX)
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(DAILY)...
	$(NOECHO) $(RRDTOOL) graph $(DAILY) $(GRAPH_PFX) \
		--title "$(NAME) daily (5 Minute Average)" \
		--start -27h --end now \
		--x-grid "MINUTE:20:HOUR:1:HOUR:3:0:%a %H:%M" $(GRAPH_SFX) VRULE:$(BRD_D)#EE0000
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(WEEKLY)...
	$(NOECHO) $(RRDTOOL) graph $(WEEKLY) $(GRAPH_PFX) \
		--title "$(NAME) weekly (30 Minute Average)" \
		--start -8d --end now \
		--x-grid "HOUR:6:DAY:1:DAY:1:86400:%a %d/%m" $(GRAPH_SFX) VRULE:$(BRD_W)#EE0000
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(MONTHLY)...
	$(NOECHO) $(RRDTOOL) graph $(MONTHLY) $(GRAPH_PFX) \
		--title "$(NAME) monthly (2 Hour Average)" \
		--start -1mon1d --end now \
		--x-grid "DAY:3:DAY:1:DAY:3:0:%d/%m" $(GRAPH_SFX) VRULE:$(BRD_M)#EE0000
	$(NOECHO) $(ECHO) Done.
	$(NOECHO) $(ECHO) Plotting $(YEARLY)...
	$(NOECHO) $(RRDTOOL) graph $(YEARLY) $(GRAPH_PFX) \
		--title "$(NAME) yearly (1 Day Average)" \
		--start -13mon --end now \
		--x-grid "MONTH:3:MONTH:1:MONTH:1:2592000:%b" $(GRAPH_SFX) VRULE:$(BRD_Y)#EE0000
	$(NOECHO) $(ECHO) Done.

-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.sng
File: Makefile.sng
Mode: 644

#
# Makefile for Windows or Unix/Linux platform only
#
# $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
# GENERATED: %GENERATED%
#
PROJECT    = monm_rrd_sng
RRDTOOL    = rrdtool

%MAKE_TOOLS%

GRAPH_PFX = --imgformat PNG --slope-mode \
 -v "Units" \
 --base 1000 \
 --width 640 --height 260 \
 --color ARROW\#EE0000

GRAPH_SFX = DEF:usr1=$(FILE):usr1:AVERAGE \
 CDEF:usr1_ln=usr1,usr1,0,+,UNKN,IF \
 VDEF:usr1_cur=usr1,LAST \
 VDEF:usr1_avg=usr1,AVERAGE \
 VDEF:usr1_min=usr1,MINIMUM \
 VDEF:usr1_max=usr1,MAXIMUM \
 AREA:usr1\#54EC48:"USR1\\t" \
 LINE1:usr1_ln\#006600 \
 GPRINT:usr1_cur:[LST=%1.0lf \
 GPRINT:usr1_avg:AVG=%1.0lf \
 GPRINT:usr1_min:MIN=%1.0lf \
 GPRINT:usr1_max:MAX=%1.0lf]\\l \
 "COMMENT:\\s" \
 "COMMENT:Generated\: $(PUBDATE)\\r" \

.PHONY: all create update graph

.USESHELL:

all:
	$(NOECHO) $(ECHO) "Usage:"
	$(NOECHO) $(ECHO) "    dmake create FILE=..."
	$(NOECHO) $(ECHO) "    dmake update FILE=... USR1=..."
	$(NOECHO) $(ECHO) "    dmake graph FILE=... NAME=... ...other..."

create: $(FILE)
	$(NOECHO) $(NOOP)

update: $(TMP_PFX)$(PROJECT).proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).proc

graph: $(TMP_PFX)$(PROJECT).mini.proc \
 $(TMP_PFX)$(PROJECT).quarter.proc \
 $(TMP_PFX)$(PROJECT).daily.proc \
 $(TMP_PFX)$(PROJECT).weekly.proc \
 $(TMP_PFX)$(PROJECT).monthly.proc \
 $(TMP_PFX)$(PROJECT).yearly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).mini.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).quarter.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).daily.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).weekly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).monthly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).yearly.proc

$(FILE):
	$(NOECHO) $(ECHO) Creating $(FILE)...
	$(NOECHO) $(RRDTOOL) create $(FILE) \
		--step 300 \
		DS:usr1:GAUGE:600:U:U \
		RRA:AVERAGE:0.5:1:600 \
		RRA:AVERAGE:0.5:6:700 \
		RRA:AVERAGE:0.5:24:775 \
		RRA:AVERAGE:0.5:288:797 \
		RRA:MIN:0.5:1:600 \
		RRA:MIN:0.5:6:700 \
		RRA:MIN:0.5:24:775 \
		RRA:MIN:0.5:288:797 \
		RRA:MAX:0.5:1:600 \
		RRA:MAX:0.5:6:700 \
		RRA:MAX:0.5:24:775 \
		RRA:MAX:0.5:288:797
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).proc: $(FILE)
	$(NOECHO) $(ECHO) Updating $(FILE)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).proc
	$(NOECHO) $(RRDTOOL) update $(FILE) \
		--template usr1 \
		$(PUBDATE):$(USR1)
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).mini.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(MINI)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).mini.proc
	$(NOECHO) $(RRDTOOL) graph $(MINI) \
		--imgformat PNG --slope-mode --rigid \
		--title "$(NAME) 3h" \
		-v "Units" \
		--base 1000 \
		--start -3h --end now \
		--width 150 --height 50 \
		--x-grid "MINUTE:10:HOUR:1:HOUR:1:0:%H:%M" \
		--logarithmic \
		--units=si \
		--color ARROW#EE0000 \
        --color CANVAS#111144 \
		DEF:usr1=$(FILE):usr1:AVERAGE \
		LINE2:usr1#00FF00:USR1
	$(NOECHO) $(ECHO) Done.

%GRAPHS_TYPICAL%

-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.dbl
File: Makefile.dbl
Mode: 644

#
# Makefile for Windows or Unix/Linux platform only
#
# $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
# GENERATED: %GENERATED%
#
PROJECT    = monm_rrd_dbl
RRDTOOL    = rrdtool

%MAKE_TOOLS%

GRAPH_PFX = --imgformat PNG --slope-mode \
 -v "Units" \
 --base 1000 \
 --width 640 --height 260 \
 --color ARROW\#EE0000

GRAPH_SFX = \
 DEF:usr1=$(FILE):usr1:AVERAGE \
 DEF:usr2=$(FILE):usr2:AVERAGE \
 VDEF:usr1_cur=usr1,LAST \
 VDEF:usr1_avg=usr1,AVERAGE \
 VDEF:usr1_min=usr1,MINIMUM \
 VDEF:usr1_max=usr1,MAXIMUM \
 VDEF:usr2_cur=usr2,LAST \
 VDEF:usr2_avg=usr2,AVERAGE \
 VDEF:usr2_min=usr2,MINIMUM \
 VDEF:usr2_max=usr2,MAXIMUM \
 AREA:usr1\#54EC48:"USR1\\t" \
 GPRINT:usr1_cur:[LST=%1.0lf \
 GPRINT:usr1_avg:AVG=%1.0lf \
 GPRINT:usr1_min:MIN=%1.0lf \
 GPRINT:usr1_max:MAX=%1.0lf]\\l \
 LINE2:usr2\#000066:"USR2\\t" \
 GPRINT:usr2_cur:[LST=%1.0lf \
 GPRINT:usr2_avg:AVG=%1.0lf \
 GPRINT:usr2_min:MIN=%1.0lf \
 GPRINT:usr2_max:MAX=%1.0lf]\\l \
 "COMMENT:\\s" \
 "COMMENT:Generated\: $(PUBDATE)\\r" \

.PHONY: all create update graph

.USESHELL:

all:
	$(NOECHO) $(ECHO) "Usage:"
	$(NOECHO) $(ECHO) "    dmake create FILE=..."
	$(NOECHO) $(ECHO) "    dmake update FILE=... USR1=... USR2=..."
	$(NOECHO) $(ECHO) "    dmake graph FILE=... NAME=... ...other..."

create: $(FILE)
	$(NOECHO) $(NOOP)

update: $(TMP_PFX)$(PROJECT).proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).proc

graph: $(TMP_PFX)$(PROJECT).mini.proc \
 $(TMP_PFX)$(PROJECT).quarter.proc \
 $(TMP_PFX)$(PROJECT).daily.proc \
 $(TMP_PFX)$(PROJECT).weekly.proc \
 $(TMP_PFX)$(PROJECT).monthly.proc \
 $(TMP_PFX)$(PROJECT).yearly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).mini.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).quarter.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).daily.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).weekly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).monthly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).yearly.proc

$(FILE):
	$(NOECHO) $(ECHO) Creating $(FILE)...
	$(NOECHO) $(RRDTOOL) create $(FILE) \
		--step 300 \
		DS:usr1:GAUGE:600:U:U \
		DS:usr2:GAUGE:600:U:U \
		RRA:AVERAGE:0.5:1:600 \
		RRA:AVERAGE:0.5:6:700 \
		RRA:AVERAGE:0.5:24:775 \
		RRA:AVERAGE:0.5:288:797 \
		RRA:MIN:0.5:1:600 \
		RRA:MIN:0.5:6:700 \
		RRA:MIN:0.5:24:775 \
		RRA:MIN:0.5:288:797 \
		RRA:MAX:0.5:1:600 \
		RRA:MAX:0.5:6:700 \
		RRA:MAX:0.5:24:775 \
		RRA:MAX:0.5:288:797
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).proc: $(FILE)
	$(NOECHO) $(ECHO) Updating $(FILE)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).proc
	$(NOECHO) $(RRDTOOL) update $(FILE) \
		--template usr1:usr2 \
		$(PUBDATE):$(USR1):$(USR2)
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).mini.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(MINI)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).mini.proc
	$(NOECHO) $(RRDTOOL) graph $(MINI) \
		--imgformat PNG --slope-mode --rigid \
		--title "$(NAME) 3h" \
		-v "Units" \
		--base 1000 \
		--start -3h --end now \
		--width 150 --height 50 \
		--x-grid "MINUTE:10:HOUR:1:HOUR:1:0:%H:%M" \
		--logarithmic \
		--units=si \
		--color ARROW#EE0000 \
		--color CANVAS#111144 \
		DEF:usr1=$(FILE):usr1:AVERAGE \
		DEF:usr2=$(FILE):usr2:AVERAGE \
		LINE2:usr1#00FF00:USR1 \
		LINE2:usr2#4444FF:USR2
	$(NOECHO) $(ECHO) Done.

%GRAPHS_TYPICAL%

-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.trp
File: Makefile.trp
Mode: 644

#
# Makefile for Windows or Unix/Linux platform only
#
# $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
# GENERATED: %GENERATED%
#
PROJECT    = monm_rrd_trp
RRDTOOL    = rrdtool

%MAKE_TOOLS%

GRAPH_PFX = --imgformat PNG --slope-mode \
 -v "Units" \
 --base 1000 \
 --width 640 --height 260 \
 --color ARROW\#EE0000

GRAPH_SFX = \
 DEF:usr1=$(FILE):usr1:AVERAGE \
 DEF:usr2=$(FILE):usr2:AVERAGE \
 DEF:usr3=$(FILE):usr3:AVERAGE \
 VDEF:usr1_cur=usr1,LAST \
 VDEF:usr1_avg=usr1,AVERAGE \
 VDEF:usr1_min=usr1,MINIMUM \
 VDEF:usr1_max=usr1,MAXIMUM \
 VDEF:usr2_cur=usr2,LAST \
 VDEF:usr2_avg=usr2,AVERAGE \
 VDEF:usr2_min=usr2,MINIMUM \
 VDEF:usr2_max=usr2,MAXIMUM \
 VDEF:usr3_cur=usr3,LAST \
 VDEF:usr3_avg=usr3,AVERAGE \
 VDEF:usr3_min=usr3,MINIMUM \
 VDEF:usr3_max=usr3,MAXIMUM \
 LINE2:usr1\#00CC00:"USR1\\t" \
 GPRINT:usr1_cur:[LST=%1.0lf \
 GPRINT:usr1_avg:AVG=%1.0lf \
 GPRINT:usr1_min:MIN=%1.0lf \
 GPRINT:usr1_max:MAX=%1.0lf]\\l \
 LINE2:usr2\#000066:"USR2\\t" \
 GPRINT:usr2_cur:[LST=%1.0lf \
 GPRINT:usr2_avg:AVG=%1.0lf \
 GPRINT:usr2_min:MIN=%1.0lf \
 GPRINT:usr2_max:MAX=%1.0lf]\\l \
 LINE2:usr3\#FF0000:"USR3\\t" \
 GPRINT:usr3_cur:[LST=%1.0lf \
 GPRINT:usr3_avg:AVG=%1.0lf \
 GPRINT:usr3_min:MIN=%1.0lf \
 GPRINT:usr3_max:MAX=%1.0lf]\\l \
 "COMMENT:\\s" \
 "COMMENT:Generated\: $(PUBDATE)\\r" \

.PHONY: all create update graph

.USESHELL:

all:
	$(NOECHO) $(ECHO) "Usage:"
	$(NOECHO) $(ECHO) "    dmake create FILE=..."
	$(NOECHO) $(ECHO) "    dmake update FILE=... USR1=... USR2=... USR3=..."
	$(NOECHO) $(ECHO) "    dmake graph FILE=... NAME=... ...other..."

create: $(FILE)
	$(NOECHO) $(NOOP)

update: $(TMP_PFX)$(PROJECT).proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).proc

graph: $(TMP_PFX)$(PROJECT).mini.proc \
 $(TMP_PFX)$(PROJECT).quarter.proc \
 $(TMP_PFX)$(PROJECT).daily.proc \
 $(TMP_PFX)$(PROJECT).weekly.proc \
 $(TMP_PFX)$(PROJECT).monthly.proc \
 $(TMP_PFX)$(PROJECT).yearly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).mini.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).quarter.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).daily.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).weekly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).monthly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).yearly.proc

$(FILE):
	$(NOECHO) $(ECHO) Creating $(FILE)...
	$(NOECHO) $(RRDTOOL) create $(FILE) \
		--step 300 \
		DS:usr1:GAUGE:600:U:U \
		DS:usr2:GAUGE:600:U:U \
		DS:usr3:GAUGE:600:U:U \
		RRA:AVERAGE:0.5:1:600 \
		RRA:AVERAGE:0.5:6:700 \
		RRA:AVERAGE:0.5:24:775 \
		RRA:AVERAGE:0.5:288:797 \
		RRA:MIN:0.5:1:600 \
		RRA:MIN:0.5:6:700 \
		RRA:MIN:0.5:24:775 \
		RRA:MIN:0.5:288:797 \
		RRA:MAX:0.5:1:600 \
		RRA:MAX:0.5:6:700 \
		RRA:MAX:0.5:24:775 \
		RRA:MAX:0.5:288:797
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).proc: $(FILE)
	$(NOECHO) $(ECHO) Updating $(FILE)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).proc
	$(NOECHO) $(RRDTOOL) update $(FILE) \
		--template usr1:usr2:usr3 \
		$(PUBDATE):$(USR1):$(USR2):$(USR3)
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).mini.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(MINI)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).mini.proc
	$(NOECHO) $(RRDTOOL) graph $(MINI) \
		--imgformat PNG --slope-mode --rigid \
		--title "$(NAME) 3h" \
		-v "Units" \
		--base 1000 \
		--start -3h --end now \
		--width 150 --height 50 \
		--x-grid "MINUTE:10:HOUR:1:HOUR:1:0:%H:%M" \
		--logarithmic \
		--units=si \
		--color ARROW#EE0000 \
		--color CANVAS#111144 \
		DEF:usr1=$(FILE):usr1:AVERAGE \
		DEF:usr2=$(FILE):usr2:AVERAGE \
		DEF:usr3=$(FILE):usr3:AVERAGE \
		LINE2:usr1#00FF00:USR1 \
		LINE2:usr2#4444FF:USR2 \
		LINE2:usr3#FF4444:USR3
	$(NOECHO) $(ECHO) Done.

%GRAPHS_TYPICAL%

-----END FILE-----

-----BEGIN FILE-----
Name: Makefile.qdr
File: Makefile.qdr
Mode: 644

#
# Makefile for Windows or Unix/Linux platform only
#
# $Id: Share.pm 66 2016-10-05 16:26:46Z abalama $
# GENERATED: %GENERATED%
#
PROJECT    = monm_rrd_qdr
RRDTOOL    = rrdtool

%MAKE_TOOLS%

GRAPH_PFX = --imgformat PNG --slope-mode \
 -v "Units" \
 --base 1000 \
 --width 640 --height 260 \
 --color ARROW\#EE0000

GRAPH_SFX = \
 DEF:usr1=$(FILE):usr1:AVERAGE \
 DEF:usr2=$(FILE):usr2:AVERAGE \
 DEF:usr3=$(FILE):usr3:AVERAGE \
 DEF:usr4=$(FILE):usr4:AVERAGE \
 VDEF:usr1_cur=usr1,LAST \
 VDEF:usr1_avg=usr1,AVERAGE \
 VDEF:usr1_min=usr1,MINIMUM \
 VDEF:usr1_max=usr1,MAXIMUM \
 VDEF:usr2_cur=usr2,LAST \
 VDEF:usr2_avg=usr2,AVERAGE \
 VDEF:usr2_min=usr2,MINIMUM \
 VDEF:usr2_max=usr2,MAXIMUM \
 VDEF:usr3_cur=usr3,LAST \
 VDEF:usr3_avg=usr3,AVERAGE \
 VDEF:usr3_min=usr3,MINIMUM \
 VDEF:usr3_max=usr3,MAXIMUM \
 VDEF:usr4_cur=usr4,LAST \
 VDEF:usr4_avg=usr4,AVERAGE \
 VDEF:usr4_min=usr4,MINIMUM \
 VDEF:usr4_max=usr4,MAXIMUM \
 LINE2:usr1\#00CC00:"USR1\\t" \
 GPRINT:usr1_cur:[LST=%1.0lf \
 GPRINT:usr1_avg:AVG=%1.0lf \
 GPRINT:usr1_min:MIN=%1.0lf \
 GPRINT:usr1_max:MAX=%1.0lf]\\l \
 LINE2:usr2\#000066:"USR2\\t" \
 GPRINT:usr2_cur:[LST=%1.0lf \
 GPRINT:usr2_avg:AVG=%1.0lf \
 GPRINT:usr2_min:MIN=%1.0lf \
 GPRINT:usr2_max:MAX=%1.0lf]\\l \
 LINE2:usr3\#FF0000:"USR3\\t" \
 GPRINT:usr3_cur:[LST=%1.0lf \
 GPRINT:usr3_avg:AVG=%1.0lf \
 GPRINT:usr3_min:MIN=%1.0lf \
 GPRINT:usr3_max:MAX=%1.0lf]\\l \
 LINE2:usr4\#DAA520:"USR4\\t" \
 GPRINT:usr4_cur:[LST=%1.0lf \
 GPRINT:usr4_avg:AVG=%1.0lf \
 GPRINT:usr4_min:MIN=%1.0lf \
 GPRINT:usr4_max:MAX=%1.0lf]\\l \
 "COMMENT:\\s" \
 "COMMENT:Generated\: $(PUBDATE)\\r" \

.PHONY: all create update graph

.USESHELL:

all:
	$(NOECHO) $(ECHO) "Usage:"
	$(NOECHO) $(ECHO) "    dmake create FILE=..."
	$(NOECHO) $(ECHO) "    dmake update FILE=... USR1=... USR2=... USR3=... USR4=..."
	$(NOECHO) $(ECHO) "    dmake graph FILE=... NAME=... ...other..."

create: $(FILE)
	$(NOECHO) $(NOOP)

update: $(TMP_PFX)$(PROJECT).proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).proc

graph: $(TMP_PFX)$(PROJECT).mini.proc \
 $(TMP_PFX)$(PROJECT).quarter.proc \
 $(TMP_PFX)$(PROJECT).daily.proc \
 $(TMP_PFX)$(PROJECT).weekly.proc \
 $(TMP_PFX)$(PROJECT).monthly.proc \
 $(TMP_PFX)$(PROJECT).yearly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).mini.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).quarter.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).daily.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).weekly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).monthly.proc
	-$(NOECHO) $(RM_F) $(TMP_PFX)$(PROJECT).yearly.proc

$(FILE):
	$(NOECHO) $(ECHO) Creating $(FILE)...
	$(NOECHO) $(RRDTOOL) create $(FILE) \
		--step 300 \
		DS:usr1:GAUGE:600:U:U \
		DS:usr2:GAUGE:600:U:U \
		DS:usr3:GAUGE:600:U:U \
		DS:usr4:GAUGE:600:U:U \
		RRA:AVERAGE:0.5:1:600 \
		RRA:AVERAGE:0.5:6:700 \
		RRA:AVERAGE:0.5:24:775 \
		RRA:AVERAGE:0.5:288:797 \
		RRA:MIN:0.5:1:600 \
		RRA:MIN:0.5:6:700 \
		RRA:MIN:0.5:24:775 \
		RRA:MIN:0.5:288:797 \
		RRA:MAX:0.5:1:600 \
		RRA:MAX:0.5:6:700 \
		RRA:MAX:0.5:24:775 \
		RRA:MAX:0.5:288:797
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).proc: $(FILE)
	$(NOECHO) $(ECHO) Updating $(FILE)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).proc
	$(NOECHO) $(RRDTOOL) update $(FILE) \
		--template usr1:usr2:usr3:usr4 \
		$(PUBDATE):$(USR1):$(USR2):$(USR3):$(USR4)
	$(NOECHO) $(ECHO) Done.

$(TMP_PFX)$(PROJECT).mini.proc: $(FILE)
	$(NOECHO) $(ECHO) Plotting $(MINI)...
	$(NOECHO) $(TOUCH) $(TMP_PFX)$(PROJECT).mini.proc
	$(NOECHO) $(RRDTOOL) graph $(MINI) \
		--imgformat PNG --slope-mode --rigid \
		--title "$(NAME) 3h" \
		-v "Units" \
		--base 1000 \
		--start -3h --end now \
		--width 150 --height 50 \
		--x-grid "MINUTE:10:HOUR:1:HOUR:1:0:%H:%M" \
		--logarithmic \
		--units=si \
		--color ARROW#EE0000 \
		--color CANVAS#111144 \
		DEF:usr1=$(FILE):usr1:AVERAGE \
		DEF:usr2=$(FILE):usr2:AVERAGE \
		DEF:usr3=$(FILE):usr3:AVERAGE \
		DEF:usr4=$(FILE):usr4:AVERAGE \
		LINE2:usr1#00FF00:U1 \
		LINE2:usr2#4444FF:U2 \
		LINE2:usr3#FF4444:U3 \
		LINE2:usr4#FFFF00:U4
	$(NOECHO) $(ECHO) Done.

%GRAPHS_TYPICAL%

-----END FILE-----

-----BEGIN FILE-----
Name: rrd.simple.tpl
File: www/rrd.simple.tpl
Mode: 644

<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
	<title>MonM RRDtool Index Page</title>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<meta http-equiv="copyright" content="Copyright &copy; 1998-2014 D&amp;D Corporation. All Rights Reserved" />
	<meta http-equiv="refresh" content="300" />
	<meta http-equiv="cache-control" content="no-cache" />
	<meta http-equiv="pragma" content="no-cache" />
	<meta http-equiv="expires" content="<!-- cgi: expires -->" />
	<meta http-equiv="pubdate" content="<!-- cgi: pubdate -->" />
	<meta name="description" content="MonM RRDtool Index Page" />
	<meta name="command-line" content="monm rrd index" />
</head>

<body>

<a name="index"></a><h1>MonM RRDtool Index Page</h1>
<!-- do: index -->
	<a href="#<!-- val: name -->"><img src="<!-- val: image -->" alt="<!-- val: path --><!-- val: image -->" /></a>
<!-- loop: index -->
<hr />

<!-- do: graphs -->
<h2><!-- val: title -->&nbsp;<a name="<!-- val: title -->" href="#index" title="Top">^</a></h2>
<p>
	<!-- do: images -->
	<a href="#<!-- val: title -->" title="<!-- val: title -->"><img src="<!-- val: image -->" alt="<!-- val: path --><!-- val: image -->" /></a>
	<!-- loop: images -->
</p>
<hr />
<!-- loop: graphs -->

<p id="copyright">
	<small>Pudlic date: <!-- cgi: pubdate --></small>
	<br />
	<small>Copyright &copy; 1998-2014 D&amp;D Corporation. All Rights Reserved</small>
</p>

</body>
</html>

-----END FILE-----

-----BEGIN FILE-----
Name: rrd.tpl
File: www/rrd.tpl
Mode: 644

<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">

<head>
	<title>MonM RRDtool Index Page</title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<meta http-equiv="Content-Style-Type" content="text/css" />
	<meta http-equiv="Refresh" content="300" />
	<meta http-equiv="Cache-Control" content="no-cache" />
	<meta http-equiv="Pragma" content="no-cache" />
	<meta http-equiv="Expires" content="<!-- cgi: expires -->" />
	<meta name="Author" content="Serz Minus" />
	<meta name="Copyright" content="Copyright &copy; 1998-2014 D&amp;D Corporation. All Rights Reserved" />
	<meta name="Pubdate" content="<!-- cgi: pubdate -->" />
	<meta name="Description" content="MonM RRDtool Index Page" />
	<meta name="Command-Line" content="monm rrd index" />
	<link rev="start" href="/" title="Home Page" />

	<!-- CSS -->
	<style type="text/css" media="all">
		html {
			position: relative;
			height: 100%;
		}
		body {
			background-color: #eee;
			overflow-y: scroll;
			padding: 5px;
		}
		a {
			text-decoration: none;
		}
		a:visited {
			color: blue;
		}

		a img {
			border: 0;
			margin: 3px;
		}
		hr {
			height: 1px;
			color: silver;
			background-color: silver;
			border: 0;
			margin: 5px 0;
		}
		#copyright {
			text-align: right;
			color: silver;
		}
	</style>

	<!-- JS -->
	<script type="text/javascript">
	//<![CDATA[
	//$(document).ready(function(){
	//	$( ".button" ).button();
	//});
	//]]>
	</script>
</head>

<body>

<a name="index"></a><h1>MonM RRDtool Index Page</h1>
<!-- do: index -->
	<a href="#<!-- val: name -->"><img src="<!-- val: image -->" alt="<!-- val: path --><!-- val: image -->" /></a>
<!-- loop: index -->
<hr />

<!-- do: graphs -->
<h2><!-- val: title -->&nbsp;<a name="<!-- val: title -->" href="#index" title="Top">^</a></h2>
<p>
	<!-- do: images -->
	<a href="#<!-- val: title -->" title="<!-- val: title -->"><img src="<!-- val: image -->" alt="<!-- val: path --><!-- val: image -->" /></a>
	<!-- loop: images -->
</p>
<hr />
<!-- loop: graphs -->

<p id="copyright">
	<small>Public date: <!-- cgi: pubdate --></small>
	<br />
	<small>Copyright &copy; 1998-2014 D&amp;D Corporation. All Rights Reserved</small>
</p>
</body>
</html>

-----END FILE-----
