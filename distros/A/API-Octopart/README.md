# NAME

API::Octopart - Simple inteface for querying part status across vendors at octopart.com.

# SYNOPSIS

        my $o = API::Octopart->new(
                token => 'abcdefg-your-octopart-token-here',
                cache => "$ENV{HOME}/.octopart/cache",
                include_specs => 1,
                ua_debug => 1,
                query_limit => 10
                );

        # Query part stock:
        my %opts = (
                currency => 'USD',
                max_moq => 100,
                min_qty => 10,
                max_price => 4,
                #mfg => 'Murata',
        );
        print Dumper $o->get_part_stock_detail('RC0805FR-0710KL', %opts);
        print Dumper $o->get_part_stock_detail('GQM1555C2DR90BB01D', %opts);

# METHODS

- $o = API::Octopart->new(%opts) - Returns new Octopart object.

    Object Options (%opt):

    - token => 'abcdefg-your-octopart-token-here',

        This is your Octopart API token.  You could do something like this to read the token from a file:

                token => (sub { my $t = `cat ~/.octopart/token`; chomp $t; return $t})->(),

    - include\_specs => 1

        If you have a PRO account then you can include product specs:

    - cache => "$ENV{HOME}/.octopart/cache"

        An optional (but recommended) cache directory to minimize requests to Octopart:

    - cache\_age => 3

        The cache age (in days) before re-querying octopart.  Defaults to 30 days.

    - query\_limit: die if too many API requests are made.

        Defaults to no limit.  I exhasted 20,000 queries very quickly due to a bug!
        This might help with that, set to a reasonable limit while testing.

    - ua\_debug => 1

        User Agent debugging.  This is very verbose and provides API communication details.

    - json\_debug => 1

        JSON response debugging.  This is very verbose and dumps the Octopart response
        in JSON.

- $o->has\_stock($part, %opts) - Returns the number of items in stock

    $part: The model number of the part

    %opts: Optional filters. No defaults are specified, it will return all unless limited.

    - min\_qty => &lt;n>    - Minimum stock quantity, per seller.

        If a sellerhas fewer than min\_qty parts in stock then the seller will be excluded.

    - max\_moq => &lt;n>    - Maximum "minimum order quantity"

        This is the max MOQ you will accept as being in
        stock.  For example, a 5000-part reel might be more
        than you want for prototyping so set this to 10 or
        100.

    - seller => &lt;regex> - Seller's name (regular expression)

        This is a regular expression so something like
        'Mouser|Digi-key' is valid.

    - mfg => &lt;regex>    - Manufacturer name (regular expression)

        Specifying the mfg name is useful if your part model
        number is similar to those of other manufacturers.

    - currency => &lt;s>   - eg, 'USD' for US dollars

        Defaults to include all currencies

- $o->get\_part\_stock($part, %opts) - Returns a simple stock structure

    $part, %opts: same as has\_stock().

    Returns the following structure:

            {
              'Mouser' => {
                            'moq_price' => '0.2',
                            'moq' => 1,
                            'stock' => 24071
                          },
              'Digi-Key' => {
                              'moq_price' => '0.2',
                              'moq' => 1,
                              'stock' => 10000
                            }
            };

- $o->get\_part\_stock\_detail($part, %opts) - Returns a stock detail structure

    $part, %opts: same as has\_stock().

    Returns a structure like this:

            [
                {
                    'mfg'     => 'Yageo',
                    'sellers' => {
                        'Digi-Key' => {
                            'moq'        => 1,
                            'moq_price'  => '0.1',
                            'price_tier' => {
                                '1'    => '0.1',
                                '10'   => '0.042',
                                '100'  => '0.017',
                                '1000' => '0.00762',
                                '2500' => '0.00661',
                                '5000' => '0.00546'
                            },
                            'stock' => 4041192
                        },
                        ...
                    },
                    'specs' => {
                        'case_package'       => '0805',
                        'composition'        => 'Thick Film',
                        'contactplating'     => 'Tin',
                        'leadfree'           => 'Lead Free',
                        'length'             => '2mm',
                        'numberofpins'       => '2',
                        'radiationhardening' => 'No',
                        'reachsvhc'          => 'No SVHC',
                        'resistance' =>
                          "10k\x{ce}\x{a9}",    # <- That is an Ohm symbol
                        'rohs'              => 'Compliant',
                        'tolerance'         => '1%',
                        'voltagerating_dc_' => '150V',
                        'width'             => '1.25mm',
                        ...
                    }
                },
                ...
            ]

- $o->octo\_query($q) - Queries the Octopart API

    Return the JSON response structure as a perl ARRAY/HASH given a query meeting Octopart's
    API specification.

- $o->octo\_query\_count() - Return the number of API calls so far.
- $o->query\_part\_detail($part)

    Return the JSON response structure as a perl ARRAY/HASH given a part search term
    shown as "$part".  This function calls $o->octo\_query() with a query from Octopart's
    "Basic Example" so you can easily lookup a specific part number.  The has\_stock()
    and get\_part\_stock\_detail() methods use this query internally.

# SEE ALSO

[https://octopart.com/](https://octopart.com/), [https://octopart.com/api](https://octopart.com/api)

# ATTRIBUTION

Octopart is a registered trademark and brand of Octopart, Inc.  All tradmarks,
product names, logos, and brands are property of their respective owners and no
grant or license is provided thereof.

The copyright below applies to this software module; the copyright holder is
unaffiliated with Octopart, Inc.

# AUTHOR

Originally written at eWheeler, Inc. dba Linux Global by Eric Wheeler
to facilitate optimization of RF matching components, but only for
components that are available for purchase at electronic component
vendors (of course!) [https://youtu.be/xbdBjR4szjE](https://youtu.be/xbdBjR4szjE)

# COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. dba Linux Global
[https://www.linuxglobal.com/](https://www.linuxglobal.com/)

This module is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This module is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this module. If not, see &lt;http://www.gnu.org/licenses/>.
