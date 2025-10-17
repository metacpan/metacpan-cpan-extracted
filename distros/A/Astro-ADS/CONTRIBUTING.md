# Contributions Welcome

If you've found a bug or have a suggestion, raise an Issue.
If you've got a fix, submit a Pull Request (PR).

## Create the development environment

```
gh repo clone duffee/astro-ads
cd astro-ads
cpanm -l local --installdeps . 
cpanm -l local --notest Mojo::UserAgent::Mockable
```

```
prove -Ilocal/lib/perl5 -lrv t/
```

### working with local::lib and dzil

Because not everyone is a fan of Dist::Zilla, this will make
it as painless as possible.

```
eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=local)"
dzil test
```

## Submitting a PR

If this is your first time contributing, that's great!
This will help us get on the same wavelength.

create a PR
tell me what changes you've made and explain why 
read it over from the point of view of someone receiving this

run the tests
dzil helps but not required
perltidy helps

## Reference documentation

link to ADS API docs
