# Contributing to Crypt::OpenSSL::RSA

Thank you for your interest in contributing!

## Getting Started

```bash
# Install build dependencies
cpanm --notest Crypt::OpenSSL::Guess Crypt::OpenSSL::Random

# Build and test
perl Makefile.PL && make && make test
```

## Reporting Bugs

Please open an issue at https://github.com/cpan-authors/Crypt-OpenSSL-RSA/issues with:
- Your Perl version (`perl -v`)
- Your OpenSSL version (`openssl version`)
- A minimal reproducing script

## Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Write tests for your changes
4. Run the full test suite (`make test`)
5. Submit a pull request

## Code Style

- Follow existing conventions in the codebase
- XS changes must compile cleanly on OpenSSL 1.0.x, 1.1.x, 3.x, and LibreSSL
- Use preprocessor conditionals to handle version differences (see `RSA.xs`)

## Security Issues

For security vulnerabilities, please see [SECURITY.md](SECURITY.md) instead of opening a public issue.
