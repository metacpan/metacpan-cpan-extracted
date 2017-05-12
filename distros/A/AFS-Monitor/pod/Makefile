CONVERTERS = pod2html

POD2HTML = $(P2H) \
	    --htmlroot=./ \
	    --podpath=./ \
	    --verbose \
	    --noindex \
	    --libpods=Monitor:afsmon_stats:afsmonitor:cmdebug:rxdebug:scout:udebug:xstat_cm_test:xstat_fs_test

all: $(CONVERTERS)

converters: $(CONVERTERS)

P2H = /usr/local/bin/pod2html

POD = \
	afsmon_stats.pod  \
	afsmonitor.pod    \
	Monitor.pod  \
	cmdebug.pod       \
	rxdebug.pod       \
	scout.pod         \
	udebug.pod        \
	xstat_cm_test.pod \
	xstat_fs_test.pod

HTML = \
	afsmon_stats.html  \
	afsmonitor.html    \
	Monitor.html  \
	cmdebug.html       \
	rxdebug.html       \
	scout.html         \
	udebug.html        \
	xstat_cm_test.html \
	xstat_fs_test.html

html:	$(P2H) $(HTML)

.SUFFIXES: .pm .pod

.SUFFIXES: .html

.pod.html:
	$(POD2HTML) --infile=$*.pod --outfile=$*.html

clean:
	rm -f $(HTML)
	rm -f pod2html-*cache
	rm -f pod2htmi.x* pod2htmd.x*

realclean:	clean
	rm -f $(CONVERTERS)

distclean:	realclean
