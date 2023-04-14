App::PythonToPerl
==============
Create Perl source code from Python source code using both regular expression rules and large language models

## Description
App::PythonToPerl is a Perl distribution which includes the `bin/python_to_perl` application for converting Python source code into Perl source code.  Perl currently handles the translation of top-level file structure, comments, includes, function definitions, and class definitions.  Large language model (LLM) neural networks handle the translation of all remaining source code lines.  Currently, OpenAI LLMs are supported via OpenAI::API.


## Installation
```
$ cpanm App::PythonToPerl
```

## Developers Only
```
# install static dependencies
$ dzil authordeps | cpanm
$ dzil listdeps | cpanm

# document changes & insert copyrights before CPAN release
$ vi Changes       # include latest release info, used by [NextRelease] and [CheckChangesHasContent] plugins
$ vi dist.ini      # update version number
$ vi FOO.pm foo.t  # add "# COPYRIGHT" as first  line of file, used by [InsertCopyright] plugin
$ vi foo.pl        # add "# COPYRIGHT" as second line of file, used by [InsertCopyright] plugin

# build & install dynamic dependencies & test before CPAN release
$ dzil build
$ ls -ld App-PythonToPerl*
$ cpanm --installdeps ./App-PythonToPerl-FOO.tar.gz  # install dynamic dependencies for share (non-system) build, including Mozilla::CA
$ dzil test  # needs all dependencies installed by above `cpanm` commands

# inspect build files before CPAN release
$ cd App-PythonToPerl-FOO
$ ls -l
$ less Changes 
$ less LICENSE 
$ less COPYRIGHT
$ less CONTRIBUTING
$ less MANIFEST 
$ less README.md 
$ less README
$ less META.json 
$ less META.yml

# make CPAN release
$ git add -A; git commit -av  # CPAN Release, vX.YYY; Codename FOO, BAR Edition
$ git push origin main
$ dzil release  # will build, test, prompt for CPAN upload, and create/tag/upload new git commit w/ only version number as commit message
```

## Original Creation
App::PythonToPerl was originally created via the following commands:

```
# normal installation procedure for minting profile
$ cpanm Dist::Zilla::MintingProfile

# normal minting procedure
$ dzil new App::PythonToPerl
```

## License & Copyright
App::PythonToPerl is Free & Open Source Software (FOSS), please see the LICENSE and COPYRIGHT and CONTRIBUTING files for legal information.
