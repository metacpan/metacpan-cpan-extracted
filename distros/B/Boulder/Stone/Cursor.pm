# A simple iterator on a Stone.
package Stone::Cursor;

=head1 NAME

Stone::Cursor - Traverse tags and values of a Stone

=head1 SYNOPSIS

 use Boulder::Store;
$store = Boulder::Store->new('./soccer_teams');

 my $stone = $store->get(28);
 $cursor = $stone->cursor;
 while (my ($key,$value) = $cursor->each) {
   print "$value: Go Bluejays!\n" if $key eq 'State' and $value eq 'Katonah';
 }

=head1 DESCRIPTION

Boulder::Cursor is a utility class that allows you to create one or
more iterators across a L<Stone> object.  This is used for traversing
large Stone objects in order to identify or modify portions of the
record.

=head2 CLASS METHODS

=item Boulder::Cursor->new($stone)

Return a new Boulder::Cursor over the specified L<Stone> object.  This
will return an error if the object is not a L<Stone> or a
descendent. This method is usually not called directly, but rather
indirectly via the L<Stone> cursor() method:

  my $cursor = $stone->cursor;

=head2 OBJECT METHODS

=item $cursor->each() 

Iterate over the attached B<Stone>.  Each iteration will return a
two-valued list consisting of a tag path and a value.  The tag path is
of a form that can be used with B<Stone::index()> (in fact, a cursor
is used internally to implement the B<Stone::dump()> method.  When the
end of the B<Stone> is reached, C<each()> will return an empty list,
after which it will start over again from the beginning.  If you
attempt to insert or delete from the stone while iterating over it,
all attached cursors will reset to the beginnning.

For example:

	$cursor = $s->cursor;
	while (($key,$value) = $cursor->each) {
           print "$value: BOW WOW!\n" if $key=~/pet/;		
	}

=item $cursor->reset()

This resets the cursor back to the beginning of the associated
B<Stone>.

=head1 AUTHOR

Lincoln D. Stein <lstein@cshl.org>.

=head1 COPYRIGHT

Copyright 1997-1999, Cold Spring Harbor Laboratory, Cold Spring Harbor
NY.  This module can be used and distributed on the same terms as Perl
itself.

=head1 SEE ALSO

L<Boulder>, L<Stone>

=cut


#------------------- Boulder::Cursor---------------


*next_pair = \&each;

# New expects a Stone object as its single
# parameter.
sub new {
    my($package,$stone) = @_;
    die "Boulder::Cursor: expect a Stone object parameter"
	unless ref($stone);

    my $self = bless {'stone'=>$stone},$package;
    $self->reset;
    $stone->_register_cursor($self,'true');
    return $self;
}

# This procedure does a breadth-first search
# over the entire structure.  It returns an array that looks like this
# (key1[index1].key2[index2].key3[index3],value)
sub each {
  my $self = shift;
  my $short_keys = shift;

  my $stack = $self->{'stack'};

  my($found,$key,$value);
  my $top = $stack->[$#{$stack}];
  while ($top && !$found) {
    $found++ if ($key,$value) = $top->next;
    if (!$found) {		# this iterator is done
      pop @{$stack};
      $top = $stack->[$#{$stack}];
      next;
    }
    if ( ref $value && !exists $value->{'.name'} ) { # found another record to begin iterating on
      if (%{$value}) {
	undef $found;
	$top = $value->cursor;
	push @{$stack},$top;
	next;
      } else {
	undef $value;
      }
    }
  }
  unless ($found) {
    $self->reset;
    return ();
  }
  return ($key,$value) if $short_keys;
  
  my @keylist = map {($_->{'keys'}->[$_->{'hashindex'}]) 
		       . "[" . ($_->{'arrayindex'}-1) ."]"; } @{$stack};
  return (join(".",@keylist),$value);
}

sub reset {
    my $self = shift;
    $self->{'arrayindex'} = 0;
    $self->{'hashindex'} = 0;
    $self->{'keys'}=[$self->{'stone'}->tags];
    $self->{'stack'}=[$self];
}

sub DESTROY {
    my $self = shift;
    if (ref $self->{'stone'}) {
	$self->{'stone'}->_register_cursor($self,undef);
    }
}

# Next will return the next index in its Stone object,
# indexing first through the members of the array, and then through
# the individual keys.  When iteration is finished, it resets itself
# and returns an empty array.
sub next {
    my $self = shift;
    my($arrayi,$hashi,$stone,$keys) = ($self->{'arrayindex'},
				       $self->{'hashindex'},
				       $self->{'stone'},
				       $self->{'keys'});
    unless ($stone->exists($keys->[$hashi],$arrayi)) {
	$self->{hashindex}=++$hashi;
	$self->{arrayindex}=$arrayi=0;
	unless (defined($keys->[$hashi]) &&
		defined($stone->get($keys->[$hashi],$arrayi))) {
	    $self->reset;
	    return ();
	}
    }
    $self->{arrayindex}++;
    return ($keys->[$hashi],$stone->get($keys->[$hashi],$arrayi));
}


1;
