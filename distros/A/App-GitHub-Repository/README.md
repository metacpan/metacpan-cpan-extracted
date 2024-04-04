# App::GitHub::Repository [![Test distro](https://github.com/JJ/p5-app-github-repository/actions/workflows/test.yml/badge.svg)](https://github.com/JJ/p5-app-github-repository/actions/workflows/test.yml)


Checks things from repositories hosted in GitHub. Uses scraping for extracting
information, so you don't have to use an API. Bear in mind that you can do so
only locally, it is probably blocked from workflows, even in GitHub itself.


## INSTALLATION

It uses Module::Build for installation, so it goes like this

	perl Build.PL
	./Build
	./Build test
	./Build install

Run

```shell
./Build installdeps
```

If you're developing and installing dependencies locally.

## DEPENDENCIES

It uses:

- `Test::More`
- `version`
- `File::Slurper`
- `JSON`
- `Git`
- `Test::Perl::Critic`

As a binary dependency, `curl` needs to be installed on the system and available
in the path

## Version history

- v0.0.6 fixes test bugs created by previous version, improves documentation.
- v0.0.5 fixes some bugs, and reduces binary dependency. Theoretically, it could
  run in Windows too.

## COPYRIGHT AND LICENCE

Copyright (C) 2018, 2024 JJ Merelo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
