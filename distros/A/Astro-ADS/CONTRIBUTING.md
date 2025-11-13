# Contributions Welcome

If you've found a bug or have a suggestion, raise an
[Issue](https://github.com/duffee/astro-ads/issues).
If you've got a fix, submit a
[Pull Request](https://github.com/duffee/astro-ads/pulls) (PR).

Don't dispair if I don't get back to you right away. This is my
side project to help me better estimate how long it takes to write
an API.

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

### working with the live ADS service

Be aware of the [ADS Terms of Use](http://adsabs.github.io/help/terms/).
Be nice.

To obtain access to the ADS Developer API you must do two things:

* Create an account and log in to the latest version of the [ADS](https://ui.adsabs.harvard.edu/).
* Push the "Generate a new key" button under the [user profile](https://ui.adsabs.harvard.edu/#user/settings/token)

To use this key with Astro::ADS, either store it in a file called **.ads/dev_key**
under your home directory (not tested under Windows yet) or store it in an
environment variable called **ADS_DEV_KEY** like so:
```
export ADS_DEV_KEY=your_dev_key_goes_here
```

## Submitting a PR

If this is your first time contributing, that's great!
This will help us get on the same wavelength.

### Create a PR
Tell me what changes you've made and explain why they're great.
Read it over from the point of view of someone receiving the PR (i.e. me).

**Do** run the tests.
`dzil` helps with the build process but is not required for just raising an issue.
`perltidy` helps keep it easy to read.

## Reference documentation

The [ADS API docs](https://ui.adsabs.harvard.edu/help/api/api-docs.html)
are extensive. If you get an API dev key, you can run queries against all their
endpoints and see the responses.
