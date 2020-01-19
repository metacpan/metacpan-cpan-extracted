[![](https://github.com/toddr/CDB_File/workflows/linux/badge.svg)](https://github.com/toddr/CDB_File/actions) [![](https://github.com/toddr/CDB_File/workflows/macos/badge.svg)](https://github.com/toddr/CDB_File/actions) [![](https://github.com/toddr/CDB_File/workflows/windows/badge.svg)](https://github.com/toddr/CDB_File/actions)

# NAME

CDB\_File - Perl extension for access to cdb databases

# SYNOPSIS

    use CDB_File;
    $c = tie %h, 'CDB_File', 'file.cdb' or die "tie failed: $!\n";

    $fh = $c->handle;
    sysseek $fh, $c->datapos, 0 or die ...;
    sysread $fh, $x, $c->datalen;
    undef $c;
    untie %h;

    $t = new CDB_File ('t.cdb', "t.$$") or die ...;
    $t->insert('key', 'value');
    $t->finish;

    CDB_File::create %t, $file, "$file.$$";

or

    use CDB_File 'create';
    create %t, $file, "$file.$$";

# DESCRIPTION

**CDB\_File** is a module which provides a Perl interface to Dan
Bernstein's **cdb** package:

    cdb is a fast, reliable, lightweight package for creating and
    reading constant databases.

## Reading from a cdb

After the `tie` shown above, accesses to `%h` will refer
to the **cdb** file `file.cdb`, as described in ["tie" in perlfunc](https://metacpan.org/pod/perlfunc#tie).

Low level access to the database is provided by the three methods
`handle`, `datapos`, and `datalen`.  To use them, you must remember
the `CDB_File` object returned by the `tie` call: `$c` in the
example above.  The `datapos` and `datalen` methods return the
file offset position and length respectively of the most recently
visited key (for example, via `exists`).

Beware that if you create an extra reference to the `CDB_File` object
(like `$c` in the example above) you must destroy it (with `undef`)
before calling `untie` on the hash.  This ensures that the object's
`DESTROY` method is called.  Note that `perl -w` will check this for
you; see [perltie](https://metacpan.org/pod/perltie) for further details.

## Creating a cdb

A **cdb** file is created in three steps.  First call `new CDB_File
($final, $tmp)`, where `$final` is the name of the database to be
created, and `$tmp` is the name of a temporary file which can be
atomically renamed to `$final`.  Secondly, call the `insert` method
once for each (_key_, _value_) pair.  Finally, call the `finish`
method to complete the creation and renaming of the **cdb** file.

Alternatively, call the `insert()` method with multiple key/value
pairs. This can be significantly faster because there is less crossing
over the bridge from perl to C code. One simple way to do this is to pass
in an entire hash, as in: `$cdbmaker->insert(%hash);`.

A simpler interface to **cdb** file creation is provided by
`CDB_File::create %t, $final, $tmp`.  This creates a **cdb** file named
`$final` containing the contents of `%t`.  As before,  `$tmp` must
name a temporary file which can be atomically renamed to `$final`.
`CDB_File::create` may be imported.

# EXAMPLES

These are all complete programs.

1\. Convert a Berkeley DB (B-tree) database to **cdb** format.

    use CDB_File;
    use DB_File;

    tie %h, DB_File, $ARGV[0], O_RDONLY, undef, $DB_BTREE or
            die "$0: can't tie to $ARGV[0]: $!\n";

    CDB_File::create %h, $ARGV[1], "$ARGV[1].$$" or
            die "$0: can't create cdb: $!\n";

2\. Convert a flat file to **cdb** format.  In this example, the flat
file consists of one key per line, separated by a colon from the value.
Blank lines and lines beginning with **#** are skipped.

    use CDB_File;

    $cdb = new CDB_File("data.cdb", "data.$$") or
            die "$0: new CDB_File failed: $!\n";
    while (<>) {
            next if /^$/ or /^#/;
            chop;
            ($k, $v) = split /:/, $_, 2;
            if (defined $v) {
                    $cdb->insert($k, $v);
            } else {
                    warn "bogus line: $_\n";
            }
    }
    $cdb->finish or die "$0: CDB_File finish failed: $!\n";

3\. Perl version of **cdbdump**.

    use CDB_File;

    tie %data, 'CDB_File', $ARGV[0] or
            die "$0: can't tie to $ARGV[0]: $!\n";
    while (($k, $v) = each %data) {
            print '+', length $k, ',', length $v, ":$k->$v\n";
    }
    print "\n";

4\. For really enormous data values, you can use `handle`, `datapos`,
and `datalen`, in combination with `sysseek` and `sysread`, to
avoid reading the values into memory.  Here is the script `bun-x.pl`,
which can extract uncompressed files and directories from a **bun**
file.

    use CDB_File;

    sub unnetstrings {
        my($netstrings) = @_;
        my @result;
        while ($netstrings =~ s/^([0-9]+)://) {
                push @result, substr($netstrings, 0, $1, '');
                $netstrings =~ s/^,//;
        }
        return @result;
    }

    my $chunk = 8192;

    sub extract {
        my($file, $t, $b) = @_;
        my $head = $$b{"H$file"};
        my ($code, $type) = $head =~ m/^([0-9]+)(.)/;
        if ($type eq "/") {
                mkdir $file, 0777;
        } elsif ($type eq "_") {
                my ($total, $now, $got, $x);
                open OUT, ">$file" or die "open for output: $!\n";
                exists $$b{"D$code"} or die "corrupt bun file\n";
                my $fh = $t->handle;
                sysseek $fh, $t->datapos, 0;
                $total = $t->datalen;
                while ($total) {
                        $now = ($total > $chunk) ? $chunk : $total;
                        $got = sysread $fh, $x, $now;
                        if (not $got) { die "read error\n"; }
                        $total -= $got;
                        print OUT $x;
                }
                close OUT;
        } else {
                print STDERR "warning: skipping unknown file type\n";
        }
    }

    die "usage\n" if @ARGV != 1;

    my (%b, $t);
    $t = tie %b, 'CDB_File', $ARGV[0] or die "tie: $!\n";
    map { extract $_, $t, \%b } unnetstrings $b{""};

5\. Although a **cdb** file is constant, you can simulate updating it
in Perl.  This is an expensive operation, as you have to create a
new database, and copy into it everything that's unchanged from the
old database.  (As compensation, the update does not affect database
readers.  The old database is available for them, till the moment the
new one is `finish`ed.)

    use CDB_File;

    $file = 'data.cdb';
    $new = new CDB_File($file, "$file.$$") or
            die "$0: new CDB_File failed: $!\n";

    # Add the new values; remember which keys we've seen.
    while (<>) {
            chop;
            ($k, $v) = split;
            $new->insert($k, $v);
            $seen{$k} = 1;
    }

    # Add any old values that haven't been replaced.
    tie %old, 'CDB_File', $file or die "$0: can't tie to $file: $!\n";
    while (($k, $v) = each %old) {
            $new->insert($k, $v) unless $seen{$k};
    }

    $new->finish or die "$0: CDB_File finish failed: $!\n";

# REPEATED KEYS

Most users can ignore this section.

A **cdb** file can contain repeated keys.  If the `insert` method is
called more than once with the same key during the creation of a **cdb**
file, that key will be repeated.

Here's an example.

    $cdb = new CDB_File ("$file.cdb", "$file.$$") or die ...;
    $cdb->insert('cat', 'gato');
    $cdb->insert('cat', 'chat');
    $cdb->finish;

Normally, any attempt to access a key retrieves the first value
stored under that key.  This code snippet always prints **gato**.

    $catref = tie %catalogue, CDB_File, "$file.cdb" or die ...;
    print "$catalogue{cat}";

However, all the usual ways of iterating over a hash---`keys`,
`values`, and `each`---do the Right Thing, even in the presence of
repeated keys.  This code snippet prints **cat cat gato chat**.

    print join(' ', keys %catalogue, values %catalogue);

And these two both print **cat:gato cat:chat**, although the second is
more efficient.

    foreach $key (keys %catalogue) {
            print "$key:$catalogue{$key} ";
    }

    while (($key, $val) = each %catalogue) {
            print "$key:$val ";
    }

The `multi_get` method retrieves all the values associated with a key.
It returns a reference to an array containing all the values.  This code
prints **gato chat**.

    print "@{$catref->multi_get('cat')}";

`multi_get` always returns an array reference.  If the key was not
found in the database, it will be a reference to an empty array.  To
test whether the key was found, you must test the array, and not the
reference.

    $x = $catref->multiget($key);
    warn "$key not found\n" unless $x; # WRONG; message never printed
    warn "$key not found\n" unless @$x; # Correct

The `fetch_all` method returns a hashref of all keys with the first
value in the cdb.  This is useful for quickly loading a cdb file where
there is a 1:1 key mapping.  In practice it proved to be about 400%
faster then iterating a tied hash.

    # Slow
    my %copy = %tied_cdb;

    # Much Faster
    my $copy_hashref = $catref->fetch_all();

# RETURN VALUES

The routines `tie`, `new`, and `finish` return **undef** if the
attempted operation failed; `$!` contains the reason for failure.

# DIAGNOSTICS

The following fatal errors may occur.  (See ["eval" in perlfunc](https://metacpan.org/pod/perlfunc#eval) if
you want to trap them.)

- Modification of a CDB\_File attempted

    You attempted to modify a hash tied to a **CDB\_File**.

- CDB database too large

    You attempted to create a **cdb** file larger than 4 gigabytes.

- \[ Write to | Read of | Seek in \] CDB\_File failed: &lt;error string>

    If **error string** is **Protocol error**, you tried to `use CDB_File` to
    access something that isn't a **cdb** file.  Otherwise a serious OS level
    problem occurred, for example, you have run out of disk space.

# PERFORMANCE

Sometimes you need to get the most performance possible out of a
library. Rumour has it that perl's tie() interface is slow. In order
to get around that you can use CDB\_File in an object oriented
fashion, rather than via tie().

    my $cdb = CDB_File->TIEHASH('/path/to/cdbfile.cdb');

    if ($cdb->EXISTS('key')) {
        print "Key is: ", $cdb->FETCH('key'), "\n";
    }

For more information on the methods available on tied hashes see
[perltie](https://metacpan.org/pod/perltie).

# BUGS

The `create()` interface could be done with `TIEHASH`.

# SEE ALSO

cdb(3).

# AUTHOR

Tim Goodwin, <tjg@star.le.ac.uk>.  **CDB\_File** began on 1997-01-08.

Now maintained by Matt Sergeant, <matt@sergeant.org>
