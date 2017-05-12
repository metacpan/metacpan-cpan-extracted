[![Build Status](https://travis-ci.org/kablamo/CPAN-Diff.svg?branch=master)](https://travis-ci.org/kablamo/CPAN-Diff)
# NAME

CPAN::Diff - Compare local Perl packages/versions with a CPAN

# SYNOPSIS

    use CPAN::Diff;

    # All params are optional
    # Mirror defaults to http://cpan.org
    my $diff = CPAN::Diff->new(
        mirror         => 'https://darkpan.mycompany.com',
        local_lib      => 'local',
        self_contained => 0,
        exclude_core   => 1,
    );

    # Local modules not in your darkpan.
    # Returns an array of CPAN::Diff::Module objects.
    my $extra = $diff->extra_modules;  
    printf "%-40s: %10s\n", $_->name, $_->local_version for @$extra;

    # Local modules which are older than the ones in your darkpan.
    # Returns an array of CPAN::Diff::Module objects.
    my $older = $diff->older_modules; 
    printf "%-40s: %10s %10s\n",
        $_->name,
        $_->local_version,
        $_->cpan_version,
        $_->cpan_dist->pathname
            for @$older;

    # Local modules which are newer than the ones in your darkpan.
    # Returns an array of CPAN::Diff::Module objects.
    my $newer = $diff->newer_modules; 
    printf "%-40s: %10s\n", $_->name, $_->local_version for @$newer;

# DESCRIPTION

Discover which Perl packages/versions are different in your environment compared to
CPAN or your darkpan (pinto or orepan2 or whatever).

This module comes with a handy script as well: [cpan-diff](https://metacpan.org/pod/cpan-diff)

This modules steals a lot of code from [cpan-outdated](https://metacpan.org/pod/cpan-outdated).

# LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
