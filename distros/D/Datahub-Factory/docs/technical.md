_Datahub::Factory_ is built on [Catmandu](http://librecat.org/) and leverages it to do the importing, fixing and exporting.

The plugins are mostly wrappers around Catmandu modules (stores, importers or exporters) that implement the actual actions. Most Catmandu [stores](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Store.pm), [importers](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Importer.pm) and [exporters](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Exporter.pm) can be used as the basis for a plugin (see [extending](extending) for more information).

## Plugin architecture
Plugins can be and are used to provide Importer, Exporter and Fixer actions. Supporting a new action is as ease as dropping a new plugin in `lib/Datahub/Factory/Importer` (or `Exporter` or `Fixer`, depending on the action you want to provide).

An Importer plugin fetches data from a source (which can be remote (an API) or a data dump) and makes it available for the rest of the application. It must always have an `importer` attribute, which is a [Catmandu::Importer](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Importer.pm) or [Catmandu::Store](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Store.pm) that supports the `->each()` method. It can define more attributes, and those are read from the [pipeline configuration file](pipeline).

The Fixer is responsible for converting between data formats. By default, it uses the internal Catmandu [fixer](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Fix.pm), so it is not necessary to create a new fixer to support a new data format. You can simply provide a new fix file in the pipeline configuration. The Fixer plugin must have an attribute `fixer` that supports `->each()`.

The exporter puts data out: it can submit to a remote store (e.g. a Datahub), to STDOUT, to a file or to anything else. It is built on a [Catmandu::Exporter](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Exporter.pm) or [Catmandu::Store](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Store.pm), which it exposes as the `out` attribute. This attribute must support `->add()`. As with Importers and Fixers, extra attributes are read from the pipeline configuration file.

Data always takes the same path through the application: it is imported first, then handed to the Fixer, and lastly transferred to an exporter.
