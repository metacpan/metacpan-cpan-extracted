# `Data-Password-zxcvbn`

This is a Perl port of Dropbox's password strength estimation library,
[`zxcvbn`](https://github.com/dropbox/zxcvbn).

The code layout has been reworked to be generally nicer (e.g. we use
classes instead of dispatch tables, all data structures are immutable)
and to pre-compute more (e.g. the dictionaries are completely
pre-built, instead of being partially computed at run time).

The code has been tested against the [Python
port's](https://github.com/dwolfhub/zxcvbn-python)
`password_expected_value.json` test. When the dictionaries contain
exactly the same data (including some words that are loaded wrongly
due to escaping issues), our results are identical. With the
dictionaries as provided in this distribution, the results (estimated
number of guesses) are still within 1%.
