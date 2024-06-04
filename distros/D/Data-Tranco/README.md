# SYNOPSIS

    use Data::Tranco;

    # get a random domain from the list
    $domain = Data::Tranco->random_domain;

    # get a random domain from the list with a specific suffix
    $domain = Data::Tranco->random_domain("org");

    # get the highest ranking domain
    $domain = Data::Tranco->top_domain;

    # get the highest ranking domain from the list with a specific suffix
    $domain = Data::Tranco->top_domain("co.uk");

# DESCRIPTION

[Data::Tranco](https://metacpan.org/pod/Data%3A%3ATranco) provides an interface to the [Tranco](https://tranco-list.eu)
list of popular domain names.

# METHODS

## RANDOM DOMAIN

    $domain = Data::Tranco->random_domain($suffix);

Returns a randomly-selected domain from the list. If `$suffix` is specified,
then only a domain that ends with that suffix will be returned.

## TOP DOMAIN

    $domain = Data::Tranco->top_domain($suffix);

Returns the highest-ranking domain from the list. If `$suffix` is specified,
then the highest-ranking domain that ends with that suffix will be returned.

# IMPLEMENTATION

The Tranco list is published as a zip-compressed CSV file. By default,
[Data::Tranco](https://metacpan.org/pod/Data%3A%3ATranco) will automatically download that file, extract the CSV file,
and write it to an [SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite) database if (a) the file doesn't exist
yet or (b) it's more than a day old.

If you want to control this behaviour, you can use the following:

## `$Data::Tranco::TTL`

This is how old the local file can be (in seconds) before it is updated. It is
86400 seconds by default.

## `$Data::Tranco::STATIC`

If you set this value to `1` then [Data::Tranco](https://metacpan.org/pod/Data%3A%3ATranco) will not update the database.

## `Data::Tranco->update_db`

This will force an update to the database.
