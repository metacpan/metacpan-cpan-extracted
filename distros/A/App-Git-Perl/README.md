# NAME

git-perl ... - work easily with Perl CPAN modules repositories

# USAGE

    git perl recent                                     = shows recent list of changes from https://metacpan.org/recent
    git perl log BAYASHI/Object-Container-0.16          = git clone repository and show latest changes
    git perl log BAYASHI/Object-Container-0.16 remove   = remove cloned repository
    git perl log Log::Any                               = git clone repository and show latest changes
    git perl log Log::Any remove                        = remove cloned repository
    git perl clone BAYASHI/Object-Container-0.16        = git clone repository
    git perl clone BAYASHI/Object-Container-0.16 remove = remove cloned repository
    git perl clone Log::Any                             = git clone repository
    git perl clone Log::Any remove                      = remove cloned repository
    git perl local                                      = list cloned repositories
    git perl local object-container-perl                = list cloned repository 'object-container-perl'
    git perl local object-container-perl log            = show latest changes in repository
    git perl local object-container-perl remove         = remove local repository stored in 'object-container-perl'
    git perl local Log::Any                             = git clone repository ( get remote repository locally )
    git perl local Log::Any remove                      = remove cloned repository

    git perl config                                     = show current config ( from ~/.config/git-perl.conf )
    git perl config dir                                 = show value of 'dir' from config
    git perl config dir ~/git/perl                      = set value of 'dir' to '~/git/perl'
    git perl config --unset dir                         = remove variable 'dir' from config file

# SYNOPSIS

    $ git perl config dir ~/git/perl
    $ git perl recent
    ...
    02 Jul 2022 17:17:12 UTC GEEKRUTH/Dist-Zilla-PluginBundle-Author-GEEKRUTH-1.0202
    02 Jul 2022 17:26:20 UTC GENE/MIDI-Bassline-Walk-0.0402
    02 Jul 2022 17:27:54 UTC GEEKRUTH/Task-BeLike-GEEKRUTH-1.0200
    02 Jul 2022 18:00:59 UTC GEEKRUTH/DBIx-Class-Schema-ResultSetNames-1.0301
    02 Jul 2022 19:16:57 UTC DANX/Weather-NHC-TropicalCyclone-0.32
    02 Jul 2022 19:31:17 UTC TOBYINK/Mite-0.002003

    $ git perl log TOBYINK/Mite-0.002003
    commit 90c6ba708e995f7e06af559613c99ba252ee199a (HEAD -> master, origin/master, origin/HEAD)
    Author: Toby Inkster <mail@tobyinkster.co.uk>
    Date:   Sat Jul 2 20:40:44 2022 +0100

        Fix typos in the documentation for accessor

    diff --git a/lib/Mite/Manual/Syntax.pod b/lib/Mite/Manual/Syntax.pod
    index e6e5f91..54fe23b 100644
    ...

    $ git perl local
    p5-mite Mite 0.002003

    $ git perl local p5-mite remove
    Removed repository stored in subdir 'p5-mite'.

# DESCRIPTION

It makes you easy to monitor recent changes in perl modules, and make you collaborate faster.

It is useful to monitor/read the latest code change in recently uploaded distribution. Good to read how authors solve the problems.

It will clone the remote repository locally, and you can easily collaborate on them, if/when needed.

# INSTALLATION

Using `cpan`

    $ cpan App::Git::Perl

Manual install:

    $ perl Makefile.PL
    $ make
    $ make install

# AUTHOR

Nedzad Hrnjica <nedzad@nedzadhrnjica.com>

# LICENSE

    Perl License (perl)
