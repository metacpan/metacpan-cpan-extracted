# Amazon::Sites

A Perl class that contains information about the various international Amazon
sites.

## Example

    use Amazon::Sites;

    my $az = Amazon::Sites->new;

    my $az_uk = $az->site('UK');

    say $az_uk->currency; # GBP
    say $az_uk->tldr;     # co.uk
    say $az_uk->domain;   # amazon.co.uk

## Installation

Install like any other CPAN module.

    cpan Amazon::Sites

Or

    cpanm Amazon::Sites

## Code

The code is maintained on GitHub.

* https://github.com/davorg-cpan/amazon-sites

## Author

* Dave Cross <dave@perlhacks.com>
