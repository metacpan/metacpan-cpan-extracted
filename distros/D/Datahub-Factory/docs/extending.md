Extending _Datahub::Factory_ is mostly done by adding new plugins to support new data sources or sinks. While it is possible to replace the fixer, it is usually not necessary, as the Catmandu fix language supports most conversions.

## Adding a new plugin
All plugins live in `lib/Datahub/Factory/Importer` (for Importer plugins), `Exporter` or `Fixer`.

The name of your new plugin is the same as used in the `plugin` key in the [pipeline configuration file](pipeline), starts with a capital letter and is in the `Datahub::Factory::<type>` namespace (where `<type>` is `Importer`, `Exporter` or `Fixer`).

All plugins have a single required attribute (`importer`, `out` or `fixer`) that is used by the application to pipe the data through it. Your plugin must provide this attribute, and it must be a [Catmandu::Store](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Store.pm), [Catmandu::Importer](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Importer.pm) or [Catmandu::Exporter](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Exporter.pm). By inheriting from the role `Datahub::Factory::Importer`, `Datahub::Factory::Exporter` or `Datahub::Factory::Fixer`, the attribute is automatically required, but doesn't work yet. You have to provide your own function (`_build_<attr>`) to make it do something.

Any extra attributes that you define (parameters to `new Foo()`) will be automatically inserted from the pipeline configuration file (under the `[plugin_importer_Foo]` section).

We use [`Moo`](http://search.cpan.org/~haarg/Moo-2.001001/lib/Moo.pm) to build our classes, and also implement `Catmandu`.

It is easiest if you first develop a [Catmandu::Store](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Store.pm) (or [Catmandu::Importer](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Importer.pm)/[Catmandu::Exporter](http://search.cpan.org/~nics/Catmandu-1.0306/lib/Catmandu/Exporter.pm)) and wrap it in your plugin. This ensures that the required methods and attributes are supported and makes it available for other users of Catmandu, without requiring them to use _Datahub::Factory_.

### Example
```
package Datahub::Factory::Importer::Adlib;

use strict;
use warnings;

use Moo;
use Catmandu;

with 'Datahub::Factory::Importer';

has file_name => (is => 'ro', required => 1);
has data_path => (is => 'ro', default => sub { return 'recordList.record.*'; });


sub _build_importer {
	my $self = shift;
	my $importer = Catmandu->importer('XML', file => $self->file_name, data_path => $self->data_path);
	return $importer;
}

1;
__END__
```
