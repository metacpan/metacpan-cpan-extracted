# How to contribute #

## Ask questions ##

Yes, asking a question is a form of contribution that helps the author
to improve documentation.

Feel free to ask questions by sending a mail to
[config-model-user mailing list](mailto:config-model-users@lists.sourceforge.net)

## Log a bug ##

Please report issue on[cme issue tracker](https://github.com/dod38fr/cme-perl/issues).

## Source code structure ##

The main parts of this modules are:

* `bin/cme`: mostly cme command documentation
* `contrib/bash_completion.cme`: the file that enable user to type 'cme[TAB]' and get the list of available sub-commands. See bash man page for more details on bash completion
* `lib/App/Cme/Command/**.pm`: implementation of cme sub-commands
* `t`: test files. Run the tests with `prove -l t`

## Edit source code from github ##

If you have a github account, you can clone a repo and prepare a pull-request.

You can:

* run `git clone https://github.com/dod38fr/cme-perl`
* edit files
* run `prove -l t` to run non-regression tests

There's no need to worry about `dzil`, `Dist::Zilla` or `dist.ini`
files. These are useful to prepare a new release, but not to fix bugs.

## Edit source code from Debian source package  ##

You can also prepare a patch using Debian source package:

For instance:

* download and unpack `apt-get source cme`
* jump in `cd cme-1.xxx`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output on [config-model-user mailing list](mailto:config-model-users@lists.sourceforge.net)


## Edit source code from Debian source package or CPAN tarball ##

Non Debian users can also prepare a patch using CPAN tarball:

* Download tar file from http://search.cpan.org
* unpack tar file with something like `tar axvf App-Cme-1.xxx.tar.gz`
* jump in `cd App-Cme-1.xxx`
* useful to create a patch later: `git init`
* commit all files: `git add -A ; git commit -m"committed all"`
* edit files
* run `prove -l t` to run non-regression tests
* run `git diff` and send the output on [config-model-user mailing list](mailto:config-model-users@lists.sourceforge.net)

## Provide feedback ##

Feedback is important. Please take a moment to rate, comment or add
stars to this project:

* [cme github](https://github.com/dod38fr/cme-perl) or [cme cpan ratings](http://cpanratings.perl.org/rate/?distribution=App-Cme)

