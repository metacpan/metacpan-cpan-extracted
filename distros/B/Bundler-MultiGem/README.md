# Bundler-MultiGem

The utility to install multiple versions of the same ruby gem

## Usage

### Setup

Assuming that you have already installed CPAN:
`curl -L http://cpanmin.us | sudo perl - --sudo App::cpanminus`

>This project is not available yet in CPAN

```bash
$ git clone git@github.com:mberlanda/Bundler-MultiGem.git
$ perl Build.PL
$ sudo ./Build installdeps
$ sudo ./Build install
```

This will make available the command `bundle-multigem`

### Initialize

The first command you can run is `initialize` or `init`.

This takes a `path` as parameter and the following options:

option| alias | descriptions
---|---|---
`gem-main-module`|`gm` | provide the gem main module (default: constantize --gem-name)
`gem-name`|`gn` | provide the gem name
`gem-source`|`gs` | provide the gem source (default: https://rubygems.org)
`gem-versions`|`gv` | provide the gem versions to install (e.g: --gv 0.0.1 --gv 0.0.2)
`dir-pkg`|`dp` | directory for downloaded gem pkg (default: pkg)
`dir-target`|`dt` | directory for extracted versions (default: versions)
`cache-pkg`|`cp` | keep cache of pkg directory (default: 1)
`cache-target`|`ct` | keep cache of target directory (default: 0)
`conf-file`|`f` | choose config file name (default: .bundle-multigem.yml)

Example:
```
bundle-multigem initialize --gn jsonschema_serializer --gv 0.5.0 --gv 0.1.0 .
```

This will generate a `.bundle-multigem.yml` in the current path (`.`).
