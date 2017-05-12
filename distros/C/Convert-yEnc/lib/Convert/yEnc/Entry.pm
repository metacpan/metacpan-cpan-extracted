package Convert::yEnc::Entry;

use strict;
use Set::IntSpan;
use warnings;

sub new
{
    my($class, $fields) = @_;

    $fields->{part} ?
	new Convert::yEnc::EntryM $fields :
	new Convert::yEnc::EntryS $fields
}

sub load
{
    my($class, $line) = @_;

    my($size, $bytes, $parts) = split "\t", $line;

    $parts ?
	load Convert::yEnc::EntryM $size, $bytes, $parts :
	load Convert::yEnc::EntryS $size, $bytes
}


package Convert::yEnc::EntryS;

use base qw(Convert::yEnc::Entry);

use overload '""' => \&to_string,
             'eq' => \&_eq;



sub new
{
    my($class, $fields) = @_;

    my $size = $fields->{size};
    $size or return undef;

    my $entry = { state => 'ybegin',
		  size  => $size,
	          bytes => 0       };

    bless $entry, $class
}

sub load
{
    my($class, $size, $bytes) = @_;

    my $entry = { state => 'yend',
		  size  => $size,
		  bytes => $bytes };

    bless $entry, $class
}


sub ybegin { 0 }
sub ypart  { 0 }

sub yend
{
    my($entry, $fields) = @_;

    $entry->{state} eq 'ybegin' or return 0;
    $entry->{state} =  'yend';

    my $size = $fields->{size};
    $entry->{bytes} = $size;
    $size and $size == $entry->{size}
}

sub complete 
{
    my $entry = shift;

    $entry->{state} eq 'yend'
}


sub to_string
{
    my $entry = shift;
    my $size  = $entry->{size}  || 0;
    my $bytes = $entry->{bytes} || 0;

    "$size\t$bytes"
}

sub _eq
{
    no warnings qw(uninitialized);

    my($a, $b) = $_;

    $a->{size }==$b->{size } and
    $a->{bytes}==$b->{bytes}
}


package Convert::yEnc::EntryM;

use base qw(Convert::yEnc::Entry);

use overload '""' => \&to_string,
             'eq' => \&_eq;



sub new
{
    my($class, $fields) = @_;

    defined $fields->{size} or return undef;

    my $entry = { state => 'ybegin',
		  fSize => $fields->{size},
		  part  => $fields->{part},
		  total => $fields->{total},
		  parts => (new Set::IntSpan),
		  bytes => (new Set::IntSpan)  };

    bless $entry, $class
}

sub load
{
    my($class, $size, $bytes, $parts) = @_;

    my $entry = { state => 'yend',
		  fSize => $size,
		  bytes => (new Set::IntSpan $bytes),
		  parts => (new Set::IntSpan $parts) };

    bless $entry, $class
}

sub ypart
{
    my($entry, $fields) = @_;

    $entry->{state} eq 'ybegin' or return 0;
    $entry->{state} =  'ypart';

    my $begin = $fields->{begin};
    my $end   = $fields->{end  };
    $begin and $end or return 0;

    $entry->{begin} = $begin;
    $entry->{end  } = $end;
    
    $entry->{pSize} = $end - $begin + 1;
}

sub yend
{
    my($entry, $fields) = @_;

    $entry->{state} eq 'ypart' or return 0;
    $entry->{state} =  'yend';

    my $pSize = $fields->{size};
    defined $pSize or return 0;

    my $part = $fields->{part};
    $part == $entry->{part} or return 0;

    $entry->{parts}->insert($part);

    my $begin = $entry->{begin};
    my $end   = $entry->{end  };
    my $bytes = "$begin-$end";

    valid Set::IntSpan $bytes or return 0;
    $entry->{bytes} = $entry->{bytes}->union($bytes);

    1
}

sub ybegin
{
    my($entry, $fields) = @_;

    $entry->{state} eq 'yend' or return 0;
    $entry->{state} =  'ybegin';

    $fields->{size}==$entry->{fSize} or return 0;

    my $total = $fields->{total};
    defined $total and defined $entry->{total} and $total != $entry->{total} and 
	return 0;
    
    my $part  = $fields->{part};
    defined $part or return 0;
    $entry->{part} = $part;

    1
}

sub complete
{
    my $entry = shift;

    $entry->{fSize} == $entry->{bytes}->cardinality;
}


sub to_string
{
    my $entry = shift;
    my $size  = $entry->{fSize};
    my $bytes = $entry->{bytes}->run_list;
    my $parts = $entry->{parts}->run_list;

    "$size\t$bytes\t$parts"
}


sub _eq
{
    my($a, $b) = @_;

    $a->{fSize}==$b->{fSize}        and
    $a->{bytes}->equal($b->{bytes}) and
    $a->{parts}->equal($b->{parts})
}


1

__END__


=head1 NAME

Convert::yEnc::Entry - an entry in a Convert::yEnc::RC database

=head1 SYNOPSIS

  use Convert::yEnc::Entry;
  
  $entry = new  Convert::yEnc::Entry { size => 10000 };
  $entry = new  Convert::yEnc::Entry { size => 50000,  part => 1 };
  
  $entry = load Convert::yEnc::Entry "10000\t10000";
  $entry = load Convert::yEnc::Entry "20000\t1-20000\t1-2";
  
  $ok = $entry->ybegin( { size=>10000	        } );
  $ok = $entry->ypart ( { begin=>1, end=>10000	} );
  $ok = $entry->yend  ( { size=>10000	        } );

        $entry->complete and ...
  
  print "$entry\n";


=head1 ABSTRACT

An entry in a Convert::yEnc::RC database

=head1 DESCRIPTION

C<Convert::yEnc::Entry> manages a single entry in a Convert::yEnc::RC database 

=head2 Exports

Nothing.

=head2 Methods

=over 4

=item I<$entry> = C<new> C<Convert::yEnc::Entry> \I<%ybegin>

Creates and returns a new C<Convert::yEnc::Entry> object.
I<%ybegin> is a hash of key => value pairs from a C<=ybegin> line.


=item I<$entry> = C<load> C<Convert::yEnc::Entry> I<$fields>

Creates and returns a new C<Convert::yEnc::Entry> object.
I<$fields> is the portion of a line from an RC database
following the file name.


=item I<$ok> = I<$entry>->C<ybegin>(\I<%ybegin>)

=item I<$ok> = I<$entry>->C<ypart>(\I<%ypart>)

=item I<$ok> = I<$entry>->C<yend>(\I<%yend>)

Updates I<$entry> according to the contents of a
C<=ybegin>, C<=ypart> or C<=yend> control line.

The argument is a reference to a hash of key => value pairs from the control line.

Returns true iff the control line is consistent with the current state of
I<$entry>.


=item I<$entry>->C<complete>

Returns true iff all parts of the file described by I<$entry> have been received.


=back


=head2 Overloads

=over 4

=item C<""> (stringify)

Serializes a C<Convert::yEnc::Entry> object for storage in an RC database.


=back


=head1 SEE ALSO

L<Convert::yEnc::RC>


=head1 AUTHOR

Steven W McDougall, E<lt>swmcd@world.std.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2008 by Steven McDougall.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
