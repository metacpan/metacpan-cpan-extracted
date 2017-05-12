package CDB_File;

use strict;

use XSLoader ();
use Exporter ();

our @ISA       = qw(XSLoader Exporter);
our $VERSION   = '0.99';
our @EXPORT_OK = qw(create);

=head1 NAME

CDB_File - Perl extension for access to cdb databases

=head1 SYNOPSIS

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

=head1 DESCRIPTION

B<CDB_File> is a module which provides a Perl interface to Dan
Bernstein's B<cdb> package:

    cdb is a fast, reliable, lightweight package for creating and
    reading constant databases.

=head2 Reading from a cdb

After the C<tie> shown above, accesses to C<%h> will refer
to the B<cdb> file C<file.cdb>, as described in L<perlfunc/tie>.

Low level access to the database is provided by the three methods
C<handle>, C<datapos>, and C<datalen>.  To use them, you must remember
the C<CDB_File> object returned by the C<tie> call: C<$c> in the
example above.  The C<datapos> and C<datalen> methods return the
file offset position and length respectively of the most recently
visited key (for example, via C<exists>).

Beware that if you create an extra reference to the C<CDB_File> object
(like C<$c> in the example above) you must destroy it (with C<undef>)
before calling C<untie> on the hash.  This ensures that the object's
C<DESTROY> method is called.  Note that C<perl -w> will check this for
you; see L<perltie> for further details.

=head2 Creating a cdb

A B<cdb> file is created in three steps.  First call C<new CDB_File
($final, $tmp)>, where C<$final> is the name of the database to be
created, and C<$tmp> is the name of a temporary file which can be
atomically renamed to C<$final>.  Secondly, call the C<insert> method
once for each (I<key>, I<value>) pair.  Finally, call the C<finish>
method to complete the creation and renaming of the B<cdb> file.

Alternatively, call the C<insert()> method with multiple key/value
pairs. This can be significantly faster because there is less crossing
over the bridge from perl to C code. One simple way to do this is to pass
in an entire hash, as in: C<< $cdbmaker->insert(%hash); >>.

A simpler interface to B<cdb> file creation is provided by
C<CDB_File::create %t, $final, $tmp>.  This creates a B<cdb> file named
C<$final> containing the contents of C<%t>.  As before,  C<$tmp> must
name a temporary file which can be atomically renamed to C<$final>.
C<CDB_File::create> may be imported.

=head1 EXAMPLES

These are all complete programs.

1. Convert a Berkeley DB (B-tree) database to B<cdb> format.

    use CDB_File;
    use DB_File;

    tie %h, DB_File, $ARGV[0], O_RDONLY, undef, $DB_BTREE or
            die "$0: can't tie to $ARGV[0]: $!\n";

    CDB_File::create %h, $ARGV[1], "$ARGV[1].$$" or
            die "$0: can't create cdb: $!\n";

2. Convert a flat file to B<cdb> format.  In this example, the flat
file consists of one key per line, separated by a colon from the value.
Blank lines and lines beginning with B<#> are skipped.

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

3. Perl version of B<cdbdump>.

    use CDB_File;

    tie %data, 'CDB_File', $ARGV[0] or
            die "$0: can't tie to $ARGV[0]: $!\n";
    while (($k, $v) = each %data) {
            print '+', length $k, ',', length $v, ":$k->$v\n";
    }
    print "\n";

4. For really enormous data values, you can use C<handle>, C<datapos>,
and C<datalen>, in combination with C<sysseek> and C<sysread>, to
avoid reading the values into memory.  Here is the script F<bun-x.pl>,
which can extract uncompressed files and directories from a B<bun>
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

5. Although a B<cdb> file is constant, you can simulate updating it
in Perl.  This is an expensive operation, as you have to create a
new database, and copy into it everything that's unchanged from the
old database.  (As compensation, the update does not affect database
readers.  The old database is available for them, till the moment the
new one is C<finish>ed.)

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

=head1 REPEATED KEYS

Most users can ignore this section.

A B<cdb> file can contain repeated keys.  If the C<insert> method is
called more than once with the same key during the creation of a B<cdb>
file, that key will be repeated.

Here's an example.

    $cdb = new CDB_File ("$file.cdb", "$file.$$") or die ...;
    $cdb->insert('cat', 'gato');
    $cdb->insert('cat', 'chat');
    $cdb->finish;

Normally, any attempt to access a key retrieves the first value
stored under that key.  This code snippet always prints B<gato>.

    $catref = tie %catalogue, CDB_File, "$file.cdb" or die ...;
    print "$catalogue{cat}";

However, all the usual ways of iterating over a hash---C<keys>,
C<values>, and C<each>---do the Right Thing, even in the presence of
repeated keys.  This code snippet prints B<cat cat gato chat>.

    print join(' ', keys %catalogue, values %catalogue);

And these two both print B<cat:gato cat:chat>, although the second is
more efficient.

    foreach $key (keys %catalogue) {
            print "$key:$catalogue{$key} ";
    }

    while (($key, $val) = each %catalogue) {
            print "$key:$val ";
    }

The C<multi_get> method retrieves all the values associated with a key.
It returns a reference to an array containing all the values.  This code
prints B<gato chat>.

    print "@{$catref->multi_get('cat')}";

C<multi_get> always returns an array reference.  If the key was not
found in the database, it will be a reference to an empty array.  To
test whether the key was found, you must test the array, and not the
reference.

    $x = $catref->multiget($key);
    warn "$key not found\n" unless $x; # WRONG; message never printed
    warn "$key not found\n" unless @$x; # Correct

The C<fetch_all> method returns a hashref of all keys with the first
value in the cdb.  This is useful for quickly loading a cdb file where
there is a 1:1 key mapping.  In practice it proved to be about 400%
faster then iterating a tied hash.

    # Slow
    my %copy = %tied_cdb;

    # Much Faster
    my $copy_hashref = $catref->fetch_all();

=head1 RETURN VALUES

The routines C<tie>, C<new>, and C<finish> return B<undef> if the
attempted operation failed; C<$!> contains the reason for failure.

=head1 DIAGNOSTICS

The following fatal errors may occur.  (See L<perlfunc/eval> if
you want to trap them.)

=over 4

=item Modification of a CDB_File attempted

You attempted to modify a hash tied to a B<CDB_File>.

=item CDB database too large

You attempted to create a B<cdb> file larger than 4 gigabytes.

=item [ Write to | Read of | Seek in ] CDB_File failed: <error string>

If B<error string> is B<Protocol error>, you tried to C<use CDB_File> to
access something that isn't a B<cdb> file.  Otherwise a serious OS level
problem occurred, for example, you have run out of disk space.

=back

=head1 PERFORMANCE

Sometimes you need to get the most performance possible out of a
library. Rumour has it that perl's tie() interface is slow. In order
to get around that you can use CDB_File in an object oriented
fashion, rather than via tie().

  my $cdb = CDB_File->TIEHASH('/path/to/cdbfile.cdb');

  if ($cdb->EXISTS('key')) {
      print "Key is: ", $cdb->FETCH('key'), "\n";
  }

For more information on the methods available on tied hashes see
L<perltie>.

=head1 BUGS

The C<create()> interface could be done with C<TIEHASH>.

=head1 SEE ALSO

cdb(3).

=head1 AUTHOR

Tim Goodwin, <tjg@star.le.ac.uk>.  B<CDB_File> began on 1997-01-08.

Now maintained by Matt Sergeant, <matt@sergeant.org>

=cut

XSLoader::load( 'CDB_File', $VERSION );

sub CLEAR {
    require Carp;
    Carp::croak("Modification of a CDB_File attempted");
}

sub DELETE {
    &CLEAR;
}

sub STORE {
    &CLEAR;
}

# Must be preloaded for the prototype.

sub create(\%$$) {
    my ( $RHdata, $fn, $fntemp ) = @_;

    my $cdb = new CDB_File( $fn, $fntemp ) or return undef;
    my ( $k, $v );
    $cdb->insert(%$RHdata);
    $cdb->finish;
    return 1;
}

1;
