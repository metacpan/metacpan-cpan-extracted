## App::eachgit

eachgit - Run git commands on multiple repos at once.

## USAGE

    eachgit <parent_dir> <git_args ...>

## SYNOPSIS

    # Run 'git grep "Some String"' for all repos under '/path/to/repos':
    eachgit /path/to/repos grep \"Some String\"
    
    # Show git status for all repos in the current dir:
    eachgit . status

## DESCRIPTION

Very simple script lets you run a git command multiple on repos at once. 
See the SYNOPSIS for usage.

I wrote this specifically so I could run `git grep` on all my repos at once, but
any git command works, too.

## AUTHOR

Henry Van Styn <vanstyn@cpan.org>

## COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
