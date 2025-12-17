CPAN::InGit
-----------

### About

This module creates git branches with the file structure of a CPAN mirror.
It facilitates pulling them from the public CPAN, pulling dependencies,
and serving the trees as if they were a CPAN mirror.  It operates directly
on Git object storage (using Git::Raw) and can also optionally make its
changes to a Git working directory for manual commits.

```
mkdir localpan && cd localpan && git init

# Create a mirror of public CPAN
# Setting "upstream_url" creates a partial mirror which advertises all
# current public CPAN versions of modules, and fetches dists on demand
# and commits them to that branch, as a cache.
cpangit-create --upstream_url=https://www.cpan.org www_cpan_org

# Create a branch to be the per-application tree of modules.
# Configure it to "import_modules" from branch "www_cpan_org".
cpangit-create --from=www_cpan_org --corelist=v5.26 my_app

# This pulls modules Catalyst and DBIx::Class from the www_cpan_org branch
# (which fetches and commits on demand) and then adds them to the package
# index of branch 'my_app'.
cpangit-add --branch=my_app Catalyst DBIx::Class

# This only pulls Log::Any, because the versions of Catalyst and DBIx::Class
# are already satisfied, even if new versions of DBIx::Class were available,
# and even if those new versions were in branch 'www_cpan_org'.
# The versions are pinned until you request a newer version.
cpangit-add --branch=my_app Catalyst DBIx::Class Log::Any

# Serve your own CPAN
cpangit-server -l http://localhost:3000 &

# Consider only the modules you committed to the my_app branch
cpanm -M http://localhost:3000/my_app/ Catalyst DBIx::Class

```

### Installing

When distributed, all you should need to do is run

    perl Makefile.PL
    make install

or better,

    cpanm CPAN-InGit-0.001.tar.gz

or from CPAN:

    cpanm CPAN::InGit

### Developing

However if you're trying to build from a fresh Git checkout, you'll need
the Dist::Zilla tool (and many plugins) to create the Makefile.PL

    cpanm Dist::Zilla
    dzil authordeps | cpanm
    dzil build

### Copyright

This software is copyright (c) 2024-2025 by Michael Conrad and IntelliTree Solutions

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
