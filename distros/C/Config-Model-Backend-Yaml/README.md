[![](https://travis-ci.org/dod38fr/config-model-backend-yaml.svg?branch=master)](https://travis-ci.org/dod38fr/config-model-backend-yaml)


# config-model-backend-yaml

YAML read/write plugin for [Config::Model](https://github.com/dod38fr/config-model/wiki)

## Description

A plugin to let [cme](https://metacpan.org/pod/distribution/App-Cme/bin/cme)
and [Config::Model](https://github.com/dod38fr/config-model/wiki)
read and write Yaml files.

## Usage

Once this module is installed, you can modify a model to specify a
`YAML` backend, either with
[cme meta edit](https://github.com/dod38fr/config-model/wiki/How-to-add-a-new-parameter-to-an-existing-model)
or using Perl code. See the example in 
[Config::Model::BackendMgr synopsis](https://metacpan.org/pod/Config::Model::BackendMgr#SYNOPSIS) 


## Installation

### Debian, Ubuntu

Run:

    apt install cme libconfig-model-backend-yaml-perl

### Others

You can also install this project from CPAN:

    cpanm install App::Cme
    cpanm install Config::Model::Backend::Yaml

### From GitHub

You may also follow these [instructions](README-build-from-git.md) to install and build from git.

## Problems ?

Please report any issue on https://github.com/dod38fr/config-model-backend-yaml/issues

## More information

* [Using cme](https://github.com/dod38fr/config-model/wiki/Using-cme)
* An example that shows how to [update a model](https://github.com/dod38fr/config-model/wiki/How-to-add-a-new-parameter-to-an-existing-model)
