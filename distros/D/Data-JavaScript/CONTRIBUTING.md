# Contributing

Your contributions are absolutely welcome!

**NOTE**: The default branch on this repository is `main`.

## In order to contribute, please:

0. If you'd like to fix a problem you found, please make sure that an issue exists for it first.
1. Fork the repository on github
2. Make your changes
3. Submit a PR to `main`.
4. Make sure your PR mentions the issue you're resolving so that we can close issues.
5. Please use `perltidy` with the `.perltidyrc` in this repository.
6. Please use `perlcritic --harsh`

## When you're contributing, please observe our code quality standards (they're pretty light).

1. Do your best not to drop code coverage. There are a lot of folks who use the module, and we want to make sure everyone has a great experience.
2. Please run `make test` prior to submitting any PRs. If your tests don't pass, we can't merge your branch.
3. Please try to stick to the formatting in the file you are modifying as closely as possible.
4. Don't forget that we have a number of users, so check Travis-CI if you don't have access to multiple OS' for testing.

## Other requests

1. If you're looking for something to do, please consider adding test coverage or finding an issue to resolve.
4. Please do not submit PRs which include massive formatting changes. Those are no fun to code review.

Thank you for contributing!
