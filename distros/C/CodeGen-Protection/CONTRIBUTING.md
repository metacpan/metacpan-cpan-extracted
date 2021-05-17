# How to Help

This distribution uses [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla)
to manage itself. yeah, it's a pain for some. If you don't know what that
is, don't worry about it. If you do know what that is and want to play
around, you can install all deps with:

    dzil authordeps --missing | cpanm

Otherwise, you can still make changes and run tests just like normal:

    prove -l t
  
If you wish to contribute changes, please make a branch:

    git checkout -b name-of-feature
   
And issue pull requests against that branch.
