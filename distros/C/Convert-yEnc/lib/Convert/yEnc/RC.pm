package Convert::yEnc::RC;

use strict;
use Convert::yEnc::Entry;
use warnings;

use overload 'eq' => \&_eq;


sub new
{
    my ($class, $file) = @_;

    my $rc = { };
    bless $rc, $class;
    $rc->load($file) if $file;

    $rc
}


sub load
{
    my($rc, $file) = @_;
    
    $rc->{file } = $file;
    $rc->{db   } = { };

    no warnings qw(uninitialized);
    open RC, $file or return undef;

    while (my $line = <RC>)
    {
	$line =~ /\S/ or next;
	my($name, $rest) = split "\t", $line, 2;
	my $entry = load Convert::yEnc::Entry $rest;
	$rc->{db}{$name} = $entry;
    }

    close(RC);

    1
}

sub update
{
    my($rc, $line) = @_;

    my($tag, @fields) = split ' ', $line;

    my %field;
    for my $field (@fields)
    {
	my($key, $val) = split /=/, $field;
	$field{$key} = $val;
    }

    $line =~ s(\s+$)();
    my($name) = $line =~ /name=\s*(.*)/;  # Die! Die! Die!
    $field{name} = $name if $name;

    $tag =~ s/^=/_/;
    $rc->can($tag) and $rc->$tag(\%field)
}

sub _ybegin
{
    my($rc, $fields) = @_;

    my $name = $fields->{name};
    $name or return 0;

    my $entry = $rc->{db}{$name};

    if ($entry)
    {
	$rc->{current} = $entry;
	return $entry->ybegin($fields);
    }

    $rc->{current} = $rc->{db}{$name} = new Convert::yEnc::Entry $fields;
}

sub _ypart
{
    my($rc, $fields) = @_;

    my $entry = $rc->{current};
    $entry and $entry->ypart($fields);
}

sub _yend
{
    my($rc, $fields) = @_;

    my $entry = $rc->{current};
    delete $rc->{current};

    $entry and $entry->yend($fields);
}


sub files
{
    my $rc = shift;
    my $db = $rc->{db};
    keys %$db
}

sub complete
{
    my($rc, $name) = @_;

    $name ? $rc->_is_complete($name) : $rc->_complete_files
}

sub _is_complete
{
    my($rc, $name) = @_;
    my $entry = $rc->{db}{$name};
    $entry and $entry->complete;
}

sub _complete_files
{
    my $rc = shift;
    my $db = $rc->{db};

    grep { $db->{$_}->complete($_) } keys %$db
}

sub entry
{
    my($rc, $name) = @_;

    $rc->{db}{$name}
}

sub drop
{
    my($rc, $name) = @_;

    delete $rc->{db}{$name};
}


sub save
{
    my $rc   = shift;
    my $file = shift || $rc->{file} or 
	die ref $rc, "::save: no file\n";
    
    open(RC, "> $file.tmp") or 
	die ref $rc, ": Can't open $file.tmp: $!\n";

    my $db = $rc->{db};

    for my $name (sort keys %$db)
    {
	my $entry = $db->{$name};
	print RC "$name\t$entry\n";
    }

    close RC;

    rename "$file.tmp", $file or 
	die ref $rc, ": can't rename $file.tmp -> $file: $!\n";

    $rc->{file} = $file;
}


sub _eq
{
    my($a, $b) = @_;

    my $dba = $a->{db};
    my $dbb = $b->{db};

    my @a = keys %$dba;
    my @b = keys %$dbb;

    @a==@b or return 0;

    for my $name (@a)
    {
	$a->{db}{$name} eq $b->{db}{$name} or return 0;
    }

    1
}

1

__END__


=head1 NAME

Convert::yEnc::RC - yEnc file-part database


=head1 SYNOPSIS

  use Convert::yEnc::RC;
  
  	      $rc = new Convert::yEnc::RC;
  	      $rc = new Convert::yEnc::RC $file;
  
  $ok       = $rc->load;
  $ok 	    = $rc->load($file);
  
  $ok       = $rc->update  ($line);
  @files    = $rc->files;
  @complete = $rc->complete;
  $complete = $rc->complete($fileName);
  $entry    = $rc->entry   ($fileName);
  $ok       = $rc->drop    ($fileName);
  
  	      $rc->save;
  	      $rc->save($file);


=head1 ABSTRACT

yEnc file-part database


=head1 DESCRIPTION

A C<Convert::yEnc::RC> object manages a database of yEnc file parts.

Applications pass the C<=ybegin>, C<=ypart>, and C<=yend> lines
from yEncoded files to the object, and it keeps track of the
files, parts and bytes as they are received.
The object reports errors if the sequence of C<=y> lines is inconsistent.

Applications can query the object to find out what files, parts, and 
bytes have been received, and whether a given file is complete.

The database can be be saved to and restored from disk.


=head2 Database format

The database is stored on disk as a flat ASCII file.
There is one line in the database for each yEncoded file.

A line for a single-part file has 3 fields

=over 4

=item *

the file name

=item *

the file size

=item *

the number of bytes received

=back

A line for a multi-part file has 4 fields

=over 4

=item *

the file name

=item *

the file size

=item *

a C<Set::IntSpan> run list
showing which bytes of the file have been recieved

=item *

a C<Set::IntSpan> run list
showing which parts of the file have been recieved

=back

Fields are tab-delimited, so that file names may contain whitespace.

Example

    a.jpg	20000	20000
    b.jpg	10000	1-5000	1


=head2 Exports

Nothing.


=head2 Methods

=over 4


=item I<$rc> = C<new> C<Convert::yEnc::RC>

=item I<$rc> = C<new> C<Convert::yEnc::RC> I<$file>

Creates and returns a new C<Convert::yEnc::RC> object.

If I<$file> is supplied, 
initializes the database from I<$file>.

If I<$file> is not supplied, or doesn't exist,
initializes the database to empty.


=item I<$ok> = I<$rc>->C<load>(I<$file>)

Loads the database in I<$file> into I<$rc>.
Any existing data in I<$rc> is discarded.
Returns true on success.

If I<$file> can't be opened,
C<load> does nothing and returns false.

If I<$file> contains invalid lines, C<load> C<die>s.
When this happens, the state of I<$rc> is undefined.


=item $I<ok> = I<$rc>->C<update>(I<$line>)

Updates I<$rc> according to the contents of I<$line>.
I<$line> should be a header (C<=begin>), trailer (C<=end>),
or part (C<=part>) line from a yEncoded file.

Returns true iff I<$line> is well-formed and consistent
with the current state of the database.


=item I<@files> = I<$rc>->C<files>

Returns a list of all the files in the database.


=item I<@complete> = I<$rc>->C<complete>

Returns a list of all the files in the database that are complete.


=item I<$complete> = I<$rc>->C<complete>(I<$fileName>)

Returns true iff all parts of (I<$fileName>) have been received.


=item I<$entry> = I<$rc>->C<entry>(I<$fileName>)

Returns the database entry for I<$fileName>.
I<$entry> is a C<Convert::yEnc::Entry> object.

If I<$fileName> is not in the database, return undef.


=item I<$ok> = I<$rc>->C<drop>(I<$fileName>)

Deletes the entry for I<$fileName> from the database.

If I<$fileName> is not in the database, return false.


=item I<$rc>->C<save>

Writes the contents of I<$newsrc> back to the file 
from which it was C<load>ed. 

C<save> C<die>s if there is an error writing the file.


=item I<$newsrc>->C<save>(I<$file>)

Writes the contents of I<$newsrc> to I<$file>. 
Subsequent calls to C<save>() will write to I<$file>.

C<save> C<die>s if there is an error writing the file.

=back


=head1 BUGS

=over 4

item *

The database doesn't persist the yEnc 1.2 "total" field to disk.

=back


=head1 SEE ALSO

=over 4

=item *

L<Convert::yEnc>

=item *

L<Convert::yEnc::Entry>

=item *

http://www.yenc.org

=back



=head1 AUTHOR

Steven W McDougall, E<lt>swmcd@world.std.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2004 by Steven McDougall.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 


