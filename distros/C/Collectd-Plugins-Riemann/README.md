# Collectd-Plugins-Riemann

# NAME

Collectd::Plugins::Riemann::Query - Collectd plugin for querying Riemann Events

# SYNOPSIS

To be used with [Collectd](https://metacpan.org/pod/Collectd).

- From the collectd configfile

        <LoadPlugin "perl">
          Globals true
        </LoadPlugin>

        <Plugin "perl">
          BaseName "Collectd::Plugins"
          LoadPlugin "Riemann::Query"
          <Plugin "Riemann::Query">
            Host     myriemann
            Port     5555
            Protocol TCP
            # Static plugin metadata
            <Plugin foo>
              Query          "tagged \"foo\" and service =~ \"bar%\""
              Plugin         foo
              PluginInstance bar
              Type           gauge
            </Plugin>
            # plugin metadata from riemann attributes
            <Plugin>
              Query              "tagged \"aggregation\""
              PluginFrom         plugin
              PluginInstanceFrom plugin_instance
              TypeFrom           ds_type
              TypeInstanceFrom   type_instance
            </Plugin>
          </Plugin>
        </Plugin>

# Root block configuration options

- Host STRING

    riemann host to query. defaults to localhost

- Port STRING

    riemann port to query. defaults to 5555

- Protocol STRING

    defaults to TCP

# Plugin block configuration options

- Query STRING

    Riemann Query. Mandatory

- Host STRING

    Static host part of collectd plugin. If unset, the host part of the riemann event will be used instead.

- PluginFrom/TypeFrom/PluginInstanceFrom/TypeInstanceFrom STRING

    Dynamic plugin metadata: riemann attribute to be used to set corresponding collectd metadata. service and host are also possible. Defaults to plugin, type, plugin\_instance and type\_instance respectively.

- Plugin/Type/PluginInstance/TypeInstance STRING

    Will be used instead if no \*From counterpart is used or found in riemann event. Can be used as a fallback. Default for Type is gauge and for Plugin is riemann service of the event.

# SUBROUTINES

Please refer to the [Collectd](https://metacpan.org/pod/Collectd) documentation.
Or `man collectd-perl`

# FILES

/etc/collectd.conf
/etc/collectd.d/

# SEE ALSO

* [collectd](https://github.com/collectd/collectd)
* [riemann](https://github.com/aphyr/riemann)
* [Collectd](https://github.com/collectd/collectd/blob/master/bindings/perl/lib/Collectd.pm) perl module
* [collectd-perl](https://github.com/collectd/collectd/blob/master/src/collectd-perl.pod) manpage
* [collmann](https://github.com/exoscale/collmann) embedding riemann into collectd

## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Collectd::Plugins::Riemann

## DEVELOPMENT

https://gitlab.in2p3.fr/wernli/collectd-plugins-riemann
https://gitlab.in2p3.fr/wernli/collectd-plugins-riemann/issues
