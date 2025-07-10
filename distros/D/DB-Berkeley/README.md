# NAME

DB::Berkeley - XS-based OO Berkeley DB HASH interface

# VERSION

Version 0.02

# DESCRIPTION

A lightweight XS wrapper around Berkeley DB using HASH format, without using tie().
DB\_File works, I just prefer this API.

# SYNOPSIS

    use DB::Berkeley;

    # Open or create a Berkeley DB HASH file
    my $db = DB::Berkeley->new("mydata.db", 0, 0666);

    # Store key-value pairs
    $db->put("alpha", "A");
    $db->put("beta",  "B");
    $db->put("gamma", "G");

    # Retrieve a value
    my $val = $db->get("beta");  # "B"

    # Check existence
    if ($db->exists("alpha")) {
        print "alpha is present\n";
    }

    # Delete a key
    $db->delete("gamma");

    # Get all keys (as arrayref)
    my $keys = $db->keys;        # returns arrayref
    my @sorted = sort @$keys;

    # Get all values (as arrayref)
    my $vals = $db->values;      # returns arrayref

    # Iterate using each-style interface
    $db->iterator_reset;
    while (my ($k, $v) = $db->each) {
        print "$k => $v\n";
    }

    # Use low-level iteration
    $db->iterator_reset;
    while (defined(my $key = $db->next_key)) {
        my $value = $db->get($key);
        print "$key: $value\n";
    }

    # Automatic cleanup when $db is destroyed

# METHODS

## store($key, $value)

Alias for `put`. Stores a key-value pair in the database.

## set($key, $value)

Alias for `set`. Stores a key-value pair in the database.

## fetch($key)

Alias for `get`. Retrieves a value for the given key.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [DB\_File](https://metacpan.org/pod/DB_File)

# REPOSITORY

[https://github.com/nigelhorne/DB-Berkeley](https://github.com/nigelhorne/DB-Berkeley)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-db-berkeley at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Berkeley](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DB-Berkeley).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc DB::Berkeley

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/DB-Berkeley](https://metacpan.org/dist/DB-Berkeley)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Berkeley](https://rt.cpan.org/NoAuth/Bugs.html?Dist=DB-Berkeley)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=DB-Berkeley](http://matrix.cpantesters.org/?dist=DB-Berkeley)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=DB::Berkeley](http://deps.cpantesters.org/?module=DB::Berkeley)

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
