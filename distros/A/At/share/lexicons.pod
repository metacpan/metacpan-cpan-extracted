# We pull lexicon and spec validation files directly from the atproto repo

Lexicons are stored in `share/lexicons` while the AT Proto team's validation tests are in `t/interop-test-files`

## If you have a reason to reinit this setup, begin with this:

    $ git remote add -f -t main --no-tags atproto https://github.com/bluesky-social/atproto.git

## Update things with this:

    $ git fetch --all

The next line is optional. Without it, the upstream commits get squashed; with it they will be included in your local history. I choose to keep them for context.

    $ git merge -s ours --no-commit atproto/main --allow-unrelated-histories
    $ git rm -rf share/lexicons
    $ git rm -rf t/interop-test-files
    $ git read-tree --prefix=share/lexicons/ -u atproto/main:lexicons
    $ git read-tree --prefix=t/interop-test-files/ -u atproto/main:interop-test-files
    $ git commit

# License

Parts from the original atproto project are covered by the license found here: https://github.com/bluesky-social/atproto/blob/main/LICENSE.txt
