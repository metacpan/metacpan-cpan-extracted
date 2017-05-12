The _Pipeline_ configures the entire _transport_ process by setting and configuring an _Importer_, _Fixes_ and an _Exporter_. Pipeline files are in [INI](https://en.wikipedia.org/wiki/INI_file) format and are provided to the application via the `--pipeline` switch. By not using a system-wide configuration file, it is possible to run the application multiple times on the same host with different settings.

## Layout
The file is divided in two sections: the first section sets the Importer, Fixer and Exporter; and the second configures them.

### Importer, Fixer and Exporter
The pipeline file has three sections called `[Importer]`, `[Fixer]` and `[Exporter]`. Set the `plugin` key to the plugin you want to use.

A list of supported plugins is available [here](https://metacpan.org/pod/Datahub::Factory::Command::transport). The `[Fixer]` section has an additional key `id_path` that refers to the path (in [JSONPath](http://goessner.net/articles/JsonPath/) format) in the data, after the fix has been applied, where the identifier can be found. This is used by the logger so you know which item caused a malfunction.

### Plugin configuration
Configuration takes place in a section called `[plugin_<type>_<name>]` where `<type>` is either _exporter_, _importer_ or _fixer_ and `<name>` is the value of the `plugin` setting in the _Importer_/_Fixer_/_Exporter_ section.

All plugins have their own options that can be discovered by reading their documentation. All parameters are valid keys in the plugin configuration section.

## Example configuration file
```
[Importer]
plugin = Adlib

[Fixer]
plugin = Fix
id_path = 'administrativeMetadata.recordWrap.recordID.0._'

[Exporter]
plugin = Datahub

[plugin_importer_Adlib]
file_name = '/tmp/adlib.xml'
data_path = 'recordList.record.*'

[plugin_fixer_Fix]
file_name = '/tmp/msk.fix'

[plugin_exporter_Datahub]
datahub_url = https://my.thedatahub.io
datahub_format = LIDO
oauth_client_id = datahub
oauth_client_secret = datahub
oauth_username = datahub
oauth_password = datahub
```
