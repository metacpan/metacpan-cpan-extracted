# How to contribute #

## Ask questions ##

Yes, asking a question is a form of contribution that helps the author
to improve documentation.

Feel free to ask questions by sending a mail to
[config-model-user mailing list](mailto:ddumont@cpan.org)

## Log a bug ##

Please report issue on https://github.com/dod38fr/config-model-itself/issues

## To modify Itself model

All Itself model files are located in [lib/Config/Model/models/Itself](https://github.com/dod38fr/config-model-itself/tree/master/lib/Config/Model/models/Itself).

To understand the relations between the classes, please install [grapvhviz](http://graphviz.org/) and run the following commands:

* `cme meta gen-dot`
* `dot -Tps model.dot  > model.ps`

and visualize the ps file with your favorite postscript viewer (may be `okular` or `gs`):

* each box contains a configuration class with its attributes
* arrows represent 'include' relations
* dotted arrows represent usage relations (i.e. the class is used in a node (a Config::Model::Node object) or in a warped node (a Config::Model::WarpedNode object)

You can also view the models files using `cme meta edit`. But please do not save the meta configuration with this tool: this will lead to a huge diff.

Note that the author is reluctant to use `cme meta edit` to edit Itself model files for fear of sawing the branch he's sitting on.

## Edit source code from github ##

If you have a github account, you can clone a repo and prepare a pull-request.

You can:

* run `git clone https://github.com/dod38fr/config-model-itself/`
* edit files
* run `prove -l t` to run non-regression tests

There's no need to worry about `dzil`, `Dist::Zilla` or `dist.ini`
files. These are useful to prepare a new release, but not to fix bugs.

## Edit source code from Debian source package  ##

You can also prepare a patch using Debian source package:

For instance:

* download and unpack `apt-get source libconfig-model-itself-perl`
* jump in `cd libconfig-model-itself-perl-2.004`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output on [config-model-user mailing list](mailto:ddumont@cpan.org)


## Edit source code from Debian source package or CPAN tarball ##

Non Debian users can also prepare a patch using CPAN tarball:

* Download tar file from http://search.cpan.org
* unpack tar file with something like `tar axvf Config-Model-Itself-2.004.tar.gz`
* jump in `cd Config-Model-Itself-2.004`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output on [config-model-user mailing list](mailto:ddumont@cpan.org)

## Provide feedback ##

Feedback is important. Please take a moment to rate, comment or add
stars to this project:

* [config-model-itself github](https://github.com/dod38fr/config-model-itself)
