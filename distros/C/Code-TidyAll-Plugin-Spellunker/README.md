[![Build Status](https://travis-ci.com/karupanerura/Code-TidyAll-Plugin-Spellunker.svg?branch=master)](https://travis-ci.com/karupanerura/Code-TidyAll-Plugin-Spellunker) [![Coverage Status](http://codecov.io/github/karupanerura/Code-TidyAll-Plugin-Spellunker/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/Code-TidyAll-Plugin-Spellunker?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Code-TidyAll-Plugin-Spellunker.svg)](https://metacpan.org/release/Code-TidyAll-Plugin-Spellunker)
# NAME

Code::TidyAll::Plugin::Spellunker - Code::TydyAll plugin for Spellunker

# SYNOPSIS

    [Spellunker]
    select = doc/**/*.txt
    stopwords = karupanerura

    [Spellunker::Pod]
    select = lib/**/*.{pm,pod}
    stopwords = karupanerura

# DESCRIPTION

Code::TidyAll::Plugin::Spellunker is Code::TydyAll plugin for Spellunker.

# OPTIONS

## stopwords

Add stopwords to the on memory dictionary. Separate it by ",".

SEE ALSO: https://metacpan.org/pod/Spellunker#$spellunker-%3Eadd\_stopwords(@stopwords)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
