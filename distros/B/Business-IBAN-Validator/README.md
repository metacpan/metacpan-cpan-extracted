# Business-IBAN-Validator

This module provides a validator for IBANs (International Bank Account Numbers)
(ISO 13616).

The validation consists of a number of tests:

- Know country code (ISO 3166 alpha2)
- Correct length (different for each country)
- Correct pattern (different for each country)
- Correct 97-checksum

On top of that, the validator also knows which countries participate in SEPA
(Single Euro Payment Area).

The "Database" with this information is based on a document published by
SWIFT (Society for Worldwide Interbank Financial Telecommunication) in January
2015 (IBAN Registry Release 54).

# INSTALLATION

To install this module, run the following commands:

```bash
perl Makefile.PL
make
make test
make install
```

# SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
`perldoc` command.

```bash
perldoc Business::IBAN::Validator
```

You can also look for information at GitHub:

[`https://github.com/abeltje/Business-IBAN-Validator`](https://github.com/abeltje/Business-IBAN-Validator)

# COPYRIGHT

&copy; 2013-2015 Abe Timmerman

# LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
