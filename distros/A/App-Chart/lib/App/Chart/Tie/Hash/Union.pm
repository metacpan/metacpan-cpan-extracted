# Copyright 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Tie::Hash::Union;
use 5.004;
# use strict;
# use warnings;
#use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

sub new {
  tie (my %h, @_);
  return \%h;
}
sub add {
  my $self = shift;
  push @{$self->{'hashes'}}, @_;
}
sub hashes {
  my $self = shift;
  return @{$self->{'hashes'}};
}

sub TIEHASH {
  ### Tie-Hash-Union TIEHASH: @_
  my $class = shift;
  return bless { iterpos => 0,
                 hashes => \@_ }, $class;
}
sub FETCH {
  my ($self, $key) = @_;
  #### Tie-Hash-Union FETCH: $key
  foreach my $h (@{$self->{'hashes'}}) {
    if (exists $h->{$key}) {
      return $h->{$key};
    }
  }
  return undef;
}
sub STORE {
  my ($self, $key, $value) = @_;
  foreach my $h (@{$self->{'hashes'}}) {
    if (exists $h->{$key}) {
      $h->{$key} = $value;
      return;
    }
  }
  if (my $h = $self->{'hashes'}->[0]) {
    $h->{$key} = $value;
  } else {
    # croak "No hashes to store to for App::Chart::Tie::Hash::Union";
  }
}

sub FIRSTKEY {
  my ($self) = @_;
  $self->{'iterpos'} = 0;
  if (my $h = $self->{'hashes'}->[0]) {
    keys %$h;  # reset iterator
  }
  $self->NEXTKEY (undef);
}
sub NEXTKEY {
  my ($self) = @_;
  for (;;) {
    my $iterpos;
    if (($iterpos = $self->{'iterpos'}) >= @{$self->{'hashes'}}) {
      return;
    }
    if (my ($key) = each %{$self->{'hashes'}->[$iterpos]}) {
      return $key;
    }
    $self->{'iterpos'}++;
  }
}

sub EXISTS {
  my ($self, $key) = @_;
  return List::Util::first {exists $_->{$key}} @{$self->{'hashes'}};
}
sub DELETE {
  my ($self, $key) = @_;
  foreach my $h (@{$self->{'hashes'}}) {
    if (exists $h->{$key}) {
      return delete $h->{$key};
    }
  }
  return undef;
}
sub CLEAR {
  my ($self) = @_;
  foreach my $h (@{$self->{'hashes'}}) {
    %$h = ();
  }
}

sub SCALAR {
  my ($self) = @_;
  my $used = 0;
  my $avail = 0;
  foreach my $h (@{$self->{'hashes'}}) {
    my $s = scalar(%$h);
    if ($s =~ m{^(\d+)/(\d+)$}) {
      $used += $1;
      $avail += $2;
    } elsif ($s) {
      $used++;
      $avail++;
    }
  }
  return "$used/$avail";
}

1;
__END__

=head1 NAME

App::Chart::Tie::Hash::Union -- union of multiple hashes

=for test_synopsis my ($pid)

=head1 SYNOPSIS

 use App::Chart::Tie::Hash::Union;
 my %h1 = (a => 1, b => 2);
 my %h2 = (x => 3, y => 3);
 my %union;
 tie %union, \%h1, \%h2;
 print $union{a},"\n";  # entry in %h1
 print $union{y},"\n";  # entry in %h2

=head1 DESCRIPTION

C<App::Chart::Tie::Hash::Union> makes a hash present the keys and values of a given set
of other underlying hash tables.  Accessing the tied hash looks in each of
those hashes for the desired key.  The tied hash hold nothing of it's own
but looks dynamically at the underlying hashes, so it reflects their current
contents at any given time.

=over

=item C<$tiedhash{$key}>

Fetching looks in each unioned hash for the first with C<exists $h->{$key}>.

=item C<$tiedhash{$key} = $value>

Storing looks in each unioned hash for one with C<exists $h->{$key}> and
stores to that entry.  If none have C<$key> already then a new entry is made
in the first unioned hash.  If there are no unioned hashes the store croaks.

=item C<delete $tiedhash{$key}>

Deleting deletes C<$key> from each of the unioned hashes.

=item C<clear %tiedhash>

Clearing clears each unioned hash.

=item C<keys %tiedhash>

Returns the keys of all the unioned hashes.

=item C<each %tiedhash>

Iterates the unioned hashes.  Currently this is implemented using a
corresponding C<each> on those underly hashes, so don't call C<each>,
C<keys> or C<values> on those or it will upset the iterated position of the
tied hash.

=item C<scalar %tiedhash>

In scalar context the tied hash returns bucket usage counts like C<3/64>
like an ordinary hash, made by adding up the unioned hashes.  If a unioned
hash returns something other than a bucket count in scalar context (which
can happen if it in turn is also a tied hash) then it's counted as 1/1 if
true or 0/0 if false.

In Perl 5.8 and earlier tied hashes which don't implement the C<SCALAR>
method always return 0 as if it's empty, when it may not be.  This of course
will propagate up through a C<App::Chart::Tie::Hash::Union> to make it appear empty when
it may not be.

=back

=head1 FUNCTIONS

=over 4

=item C<tie %hash, 'App::Chart::Tie::Hash::Union', \%h1, \%h2, ...>

Tie hash C<%hash> to present the contents of the given C<%h1>, C<%h2>, etc.

=item C<< $hashref = App::Chart::Tie::Hash::Union->new (\%h1, \%h2, ...) >>

Return a ref to a newly created hash table tied to the given C<%h1>, C<%h2>,
etc.  For example

    my $href = App::Chart::Tie::Hash::Union->new (\%h1, \%h2);

is the same as

    tie (my %hash, 'App::Chart::Tie::Hash::Union', \%h1, \%h2);
    my $href = \%hash;

If you want your own C<%hash> as such then the plain C<tie> is easier.  If
you want an hashref to pass around to other funcs then C<new> saves a line
of code.

=back

=head2 Object Methods

The tie object associated with the tied hash, as returned by the C<tie> or
obtained later with C<tied>, has the following methods.

=over 4

=item C<< $thobj->add (\%h3, ...) >>

Add further hash tables to the union.

=item C<< @list = $thobj->hashes() >>

Return a list of hashrefs which are currently being unioned.

=back

=head1 SEE ALSO

L<Hash::Union>, L<Hash::Merge>

=cut
