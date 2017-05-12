_Datahub::Factory_ is an application that extracts data from _Collection Management Systems_, converts it to [LIDO](http://network.icom.museum/cidoc/working-groups/lido/what-is-lido/) and submits it to a [Datahub for Museums](https://github.com/thedatahub/Datahub).

It is written in [Perl](https://www.perl.org/) and uses [Catmandu](http://librecat.org/) as the underlying framework.

_Datahub::Factory_ can extract data from data dumps (usually in XML) or directly from the API of the Collection Management System (CMS for short). It does this by using specific _Importer_ plugins, based around _Catmandu_ modules.

At the moment, it includes support for:

* [The Museum System](http://www.gallerysystems.com/products-and-services/tms/): [Datahub::Factory::Importer::TMS](https://metacpan.org/pod/Datahub::Factory::Importer::TMS)
* [Adlib](http://www.adlibsoft.nl/) (API and dump): [Datahub::Factory::Importer::Adlib](https://metacpan.org/pod/Datahub::Factory::Importer::Adlib)
* [Collective Access](http://collectiveaccess.org/) (API): [Datahub::Factory::Importer::CollectiveAccess](https://metacpan.org/pod/Datahub::Factory::Importer::CollectiveAccess)

By default, it will convert data to LIDO and attempt to submit it to a Datahub. However, this can be changed by changing the _Exporter_ plugin:

* [Datahub for Museums](https://github.com/thedatahub/Datahub) (the default)
* [LIDO](http://network.icom.museum/cidoc/working-groups/lido/what-is-lido/) (an XML dump)
* [YAML](http://yaml.org/)

To convert between data formats, we use the powerful [Catmandu Fixing Language](https://github.com/LibreCat/Catmandu/wiki/Fixes-Cheat-Sheet), so it is theoretically possible to convert between a limitless amount of formats.

## Usage
The application (`script/dhconveyor`) supports several commands that are provided as the first argument. Nevertheless, only the `transport` command (to _transport_ data from source to sink) is really supported.

To use the application, you need to define an _Importer_ plugin and configure it. While _Datahub::Factory_ supports the conversion between data formats, it won't do it by itself. You have to provide a _Fix_ file that does the actual conversion. Example files can be found [here](https://github.com/VlaamseKunstcollectie/Datahub-Fixes). By default, the application will attempt to push to a Datahub. You can however, export to LIDO-XML or to YAML.

It is possible to extend the program by adding more plugins, see [this guide](extending).

All configuration (which plugin to use for importing and exporting, the location of the fixes file and any plugin-specific options) are set in a _Pipeline file_ that is provided to the application via the `--pipeline` switch. For more information, consult the [pipeline documentation](pipeline).

## Puppet
A [puppet module](https://forge.puppet.com/packedvzw/datahub_factory/readme) exists for this application and can be used to create and manage [pipeline](pipeline) configuration files.

## Under the hood
_Datahub::Factory_ is built on [Catmandu](http://librecat.org) and uses its Fix language and plugin architecture to support its operation.

A more technical (and complete) explanation can be found [here](technical).
