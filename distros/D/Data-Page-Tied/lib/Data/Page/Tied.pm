# 
# Copyright (c) 2002-2006
#          Steffen Müller         <smueller@cpan.org>
# 
# All rights reserved.
# 
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
# 

package Data::Page::Tied;

use strict;
use Carp;

use Data::Page;

use vars qw/$VERSION @ISA/;
$VERSION = '2.01';

# inherit methods from Data::Page.
push @ISA, 'Data::Page';

# constructor
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  # get the data to start with
  my $entries               = shift;

  if (ref $entries eq 'ARRAY') {
    # if it's an array ref, we use its contents
    $self->{ENTRIES}   = [ @{ $entries } ];
  } else {
    # if it's not an array ref, we return a Data::Page object
    return Data::Page->new($entries, @_);
  }

  bless($self, $class);

  # set entries per page and current page (args)
  $self->set_entries_per_page(shift);
  $self->set_current_page(shift);

  return $self;
}

# return the total number of entries.
sub total_entries {
  my $self = shift;

  return scalar(@{$self->{ENTRIES}});
}

# set the current page.
sub set_current_page {
  my $o = shift()->current_page(@_);
  $o->current_page();
}

# set entries per page
sub set_entries_per_page {
  my $o = shift()->entries_per_page( @_ );
  return $o->entries_per_page;    
}

# access an entry
sub entry {
  my $self = shift;
  my $index = shift;
  $self->{ENTRIES}->[$index] = shift if @_;
  return $self->{ENTRIES}->[$index];
}

# set an entry
sub set_entry {
  shift()->entry(@_);
}

##################
# tied interface #
##################

# invokes constructor
sub TIEARRAY {
  my $class = shift;
  my $self  = $class->new(@_);
  return $self;
}

sub FETCH {
  $_[0]->{ENTRIES}->[$_[1]];
}

sub STORE {
  $_[0]->{ENTRIES}->[$_[1]] = $_[2];
}

sub FETCHSIZE {
  my $self = shift;
  return scalar @{$self->{ENTRIES}};
}

sub STORESIZE {
  my $self = shift;
  $#{$self->{ENTRIES}} = shift() - 1;
}

sub EXTEND {
   my $self = shift;
   $#{$self->{ENTRIES}} = shift() - 1;
}

sub POP { pop @{ $_[0]->{ENTRIES} } }

sub PUSH { push @{ $_[0]->{ENTRIES} }, @_ }

sub SHIFT { shift @{ $_[0]->{ENTRIES} } }

sub UNSHIFT { unshift @{ $_[0]->{ENTRIES} }, @_ }

sub SPLICE { splice @{ $_[0]->{ENTRIES} }, @_ }

sub DELETE { $_[0]->{ENTRIES}->[$_[1]] = '' }

sub EXISTS { croak "We don't do 'exists' here!" }

sub CLEAR { }

sub DESTROY { }


1;

__END__

=head1 NAME

Data::Page::Tied - Tied interface for the Data::Page module

=head1 SYNOPSIS

  use Data::Page::Tied;
  $handler = tie @data,
             'Data::Page::Tied',
             [qw(some data to start with)],
             $entries_per_page,
             $current_page;

  push @data, @more_data;
  print "first entry on page ", $handler->current_page(),
        " is ",                 $handler->first();

=head1 DEPENDENCIES

This module depends on C<Data::Page> and C<Test::Simple>.

=head1 DESCRIPTION

The C<Data::Page::Tied> module adds a tied interface to the
object-oriented interface defined by Leon Brocard's
C<Data::Page> module. It also adds several methods to set
and get the current page and the number of data items per
page.

Please read L<Data::Page> as C<Data::Page::Tied> inherits
all methods from C<Data::Page>.

The tying constructor has the following syntax:

  tie @ary, 'Data::Page::Tied', ARRAYREF,
            INTEGER,            INTEGER;

Where the referenced array may contain any data to start with
and the integers denote the number of entries per page and the
current page respectively.

=head2 Methods

=over 4

=item new

This is the constructor. It is invoked by the tied interface,
but using it directly allows for two distinct ways of creating
new objects:

You may use the same syntax as the tied interface or you may
use the following syntax to get an ordinary C<Data::Page> object
instead of a C<Data::Page::Tied> object:

  Data::Page::Tied->new( INTEGER, @args );

Where the integer is the number of elements.

=item total_entries

This method returns the number of items in the tied array.

=item set_current_page

This method sets the current page. You may find the current page
by using the inherited C<current_page> method.

=item set_entries_per_page

This method sets the number of items displayed per page. You may
find the current number of items displayed per page
by using the inherited C<entries_per_page> method.

=item entry

This accessor is used to get or set any specific entry. It takes
one or two arguments. The first argument is always the array index
and the second (optional) argument is the value you want to set
C<$array[$index]> to.

=item set_entry

Additional method to make the interface more consistent. Takes
two arguments. See L<entry>.

=back

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006 Steffen Mueller

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself. 

=head1 SEE ALSO

L<Data::Page>

=cut

