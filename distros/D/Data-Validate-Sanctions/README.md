[![Build Status](https://travis-ci.org/binary-com/perl-Data-Validate-Sanctions.svg?branch=master)](https://travis-ci.org/binary-com/perl-Data-Validate-Sanctions)
[![codecov](https://codecov.io/gh/binary-com/perl-Data-Validate-Sanctions/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Data-Validate-Sanctions)

# NAME

Data::Validate::Sanctions - Validate a name against sanctions lists

# SYNOPSIS

    # as exported function
    use Data::Validate::Sanctions qw/is_sanctioned get_sanction_file set_sanction_file/;
    set_sanction_file('/var/storage/sanction.csv');

    print 'BAD' if is_sanctioned($first_name, $last_name);

    # as OO
    use Data::Validate::Sanctions;

    #You can also set sanction_file in the new method.
    my $validator = Data::Validate::Sanctions->new(sanction_file => '/var/storage/sanction.csv');
    print 'BAD' if $validator->is_sanctioned("$last_name $first_name");

# DESCRIPTION

Data::Validate::Sanctions is a simple validitor to validate a name against sanctions lists.

The list is from the following sources:

- https://www.treasury.gov/ofac/downloads/sdn_xml.zip
- https://www.treasury.gov/ofac/downloads/consolidated/consolidated.xml
- https://ofsistorage.blob.core.windows.net/publishlive/ConList.csv
- https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1/content?token=$eu_token

run [update\_sanctions\_csv](https://metacpan.org/pod/update_sanctions_csv) to update the bundled csv.

The path of list can be set by function ["set\_sanction\_file"](#set_sanction_file) or by method ["new"](#new). If not set, then environment variable $ENV{SANCTION\_FILE} will be checked, at last
the default file in this package will be used.

# Sanctions check - How does it work?

Note that a positive result means `marked as prohibited` and negative result means `innocent`.

1. Client information can be passed in two ways:
a.) a hash-ref containing any of these fields: `first_name` (required), `last_name` (required), `date_of_birth`, `place_of_birth`, `residence`, `citizen`, `nationality`, `postal_code`, `national_id`, `passport_no`.
Example: `get_sanctioned_info({first_name => 'Alex', last_name => 'Xela', date_of_birth => '..', residence => 'fr', citizen => 'Iran');`

b.) three scalar arguments (to keep compliant with the old API):
Example: `get_sanctioned_info($client->first_name, $client->last_name, $client->date_of_birth);`

2. `first_name` and `last_name` are treated together as the `full_name`. The `full_name` is then cleaned by removing non-alphabets (if any)
Example: `Ahmad Sheikh` becomes `AHMAD SHEIKH`

3. The above procedure is applied when a sanctioned individual's name is used
Example: `ABDUL-QADER Ahmad Sheik` becomes `ABDUL QADER AHMAD SHEIKH`

4. Name matching takes place, based on the following four scenarios:
a.) **Exact name**: If the client is `Ahmad Sheikh` and the sanctioned individual is `Ahmad Sheikh`, it is a **positive match**. Even if the names were reversed, the match would stil be positive, as it looks for **exact** wording and regardless of order.
b.) **Partial exact match (I)**: If the client is `Ahmad Sheikh` and the sanctioned individual is `Abdul Qader Ahmad Sheikh`, then it is also a positive match. This is because the client's name `Ahmad Sheikh` is a substring of `Abdul Qader Ahmad Sheikh`.
c.) **Partial exact match (II)**: If the client is `Abdul Qader Ahmad Sheikh` and the sanctioned individual is `Ahmad Sheikh`, then it is also a positive match. This is because, as mentioned above, it is a substring **and** also because we take the shortest name into consideration first and compare with the longer name.

**NOTE**: As long as there are **two** or more matches, the result will always be a positive match due to name similarity. If the shortest name has only one token and there is a match, then it is also a positive result.

5. If a `date_of_birth` value is passed, it is compared to the list of **date_of_birth** in the sanction lists (if a value is found), based on epoch value and the sanctioned individual's name.

6. Scenarios to consider when **date_of_birth** is taken into consideration:
a.) `name matches and no date_of_birth value found in sanctions list`: This returns a positive result
b.) `name matches and date_of_birth matches`: This returns a positive result
c.) `name matches but date_of_birth does not match from all given values`: This returns a negative result 
d.) `name matches but no date_of_birth value is passed`: This returns a positive result

# METHODS

## is\_sanctioned
    is_sanctioned({first_name => '...', last_name => '...', date_of_birth => '...'});
    is_sanctioned($last_name, $first_name);
    is_sanctioned($first_name, $last_name);
    is_sanctioned("$last_name $first_name");

when one string is passed, please be sure last\_name is before first\_name.

or you can pass first\_name, last\_name (last\_name, first\_name), we'll check both "$last\_name $first\_name" and "$first\_name $last\_name".

return list name for yes, 0 for no.

it will remove all non-alpha chars and compare with the list we have.

## new

Create the object, and set sanction\_file

    my $validator = Data::Validate::Sanctions->new(sanction_file => '/var/storage/sanction.csv');

## get\_sanction\_file

get sanction\_file which is used by ["is\_sanctioned"](#is_sanctioned) (procedure-oriented)

## set\_sanction\_file

set sanction\_file which is used by ["is\_sanctioned"](#is_sanctioned) (procedure-oriented)

# AUTHOR

Binary.com <fayland@binary.com>

# COPYRIGHT

Copyright 2014- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
