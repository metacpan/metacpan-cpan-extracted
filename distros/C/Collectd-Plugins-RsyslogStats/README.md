Collectd-Plugins-RsyslogStats
=============================

collectd plugin for reading queue metrics from rsyslog/imstats logfile.

In your collectd config:


    <LoadPlugin "perl">
        Globals true
    </LoadPlugin>

    <Plugin "perl">
      BaseName "Collectd::Plugins"
      LoadPlugin "RsyslogStats"

        <Plugin "RsyslogStats">
          path "/var/log/rsyslog-stats.log"
          prefix "rsyslog"
          metrics "enqueued,size"
        </Plugin>
    </Plugin>
