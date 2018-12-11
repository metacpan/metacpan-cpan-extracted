# How to contribute #

## Ask questions ##

Yes, asking a question is a form of contribution that helps the author
to improve documentation.

Feel free to ask questions by sending a mail to the [author](mailto:ddumont@cpan.org)

## Log a bug ##

Please report issue on https://github.com/dod38fr/config-model-backend-yaml/issues

## Source code structure ##

The main parts of this modules are:

* `lib/Config/Model/Backend/Yaml.pm`: the "main" file of the Perl package. YAML data is converted to a Perl data structure by YAML::XS and loaded into Config::Model (through [Config::Model::BackendMgr](https://metacpan.org/pod/Config::Model::BackendMgr). The reverse is done when writing back data.
* `t`: test files. Run the tests with `prove -l t`
* `t/model_tests.d` test the YAML backend using [Config::Model::Tester](http://search.cpan.org/dist/Config-Model-Tester/lib/Config/Model/Tester.pm). Use `prove -l t/model_test.t` command to run only model tests.

## Edit source code from github ##

If you have a github account, you can clone a repo and prepare a pull-request.

You can:

* run `git clone https://github.com/dod38fr/config-model-backend-yaml/`
* edit files
* run `prove -l t` to run non-regression tests

There's no need to worry about `dzil`, `Dist::Zilla` or `dist.ini`
files. These are useful to prepare a new release, but not to fix bugs.

## Edit source code from Debian source package  ##

You can also prepare a patch using Debian source package:

For instance:

* download and unpack `apt-get source libconfig-model-backend-yaml-perl`
* jump in `cd libconfig-model-backend-yaml-perl-0.xxx`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output to the [author](mailto:ddumont@cpan.org) 


## Edit source code from Debian source package or CPAN tarball ##

Non Debian users can also prepare a patch using CPAN tarball:

* Download tar file from http://search.cpan.org
* unpack tar file with something like `tar axvf Config-Model-Backend-Yaml-1.xxx.tar.gz`
* jump in `cd Config-Model-Backend-Yaml-xxx`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output to the [author](mailto:ddumont@cpan.org) 

## Provide feedback ##

Feedback is important. Please take a moment to rate, comment or add
stars to this project:

* [config-model github](https://github.com/dod38fr/config-model-backend-yaml) or [config-model cpan ratings](http://cpanratings.perl.org/rate/?distribution=Config::Model::Backend::Yaml)
