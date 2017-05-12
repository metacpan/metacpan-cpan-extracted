package CIAO::Lib::StackIO;

use strict;
use warnings;
use Carp;


our $VERSION = '0.02';

require XSLoader;
XSLoader::load('CIAO::Lib::StackIO', $VERSION);

# Preloaded methods go here.

our %Options = ( prepend => 1, expand => 1 );

sub new
{
  my $class = shift;
  my $list = shift;
  my $opts = shift || { prepend => 1, expand => 0 };

  croak( __PACKAGE__, ": options must be hash ref\n" )
    unless 'HASH' eq ref $opts;

  croak( __PACKAGE__, ": extra arguments to constructor\n" )
    if @_;

  my @badopts = grep { ! exists $Options{lc $_ } } keys %$opts;
  croak( __PACKAGE__, ": unknown options: ", join(', ', @badopts ) )
    if @badopts;

  my %opts = map { lc $_ => $opts->{$_} } keys %$opts;

  my $stack;
  if ( exists $opts{expand} && $opts{expand} )
  {
    $stack = 
      CIAO::Lib::StackIO::Private::stk_expand_n( $list, $opts{expand} )
	  or croak( __PACKAGE__, ": error generating expanded stack\n" );
  }
  else
  {
    $stack = ( exists $opts{prepend} && $opts{prepend} ) ?
      CIAO::Lib::StackIO::Private::stk_build( $list ) :
      CIAO::Lib::StackIO::Private::stk_build_gen( $list );

    croak( __PACKAGE__, ": error building stack\n" )
      unless $stack;
  }

  # force a stack rewind because of a bug in the stackio library when
  # creating empty stacks.
  $stack->rewind;

  $stack;
}


1;


__END__


=head1 NAME

CIAO::Lib::StackIO - Perl wrapper for the CIAO stackio library

=head1 SYNOPSIS

  use CIAO::Lib::StackIO;

  my $stack = CIAO::Lib::StackIO->new( $list, \%args );


=head1 DESCRIPTION

B<CIAO::Lib::StackIO> is an interface to the stackio (libstk)
library shipped with the Chandra Interactive Analysis of Observations
(CIAO) software package.

The library maintains a stack of filenames.  Various means of
constructing the stack are available, including reading the names from
a file, using wild cards, interpolating numerical sequences into
filename templates, etc.  Various standard operations may be performed
on the stack.

Note that indices into the stack are unary based.

=head2 Stack Syntax

The best (only?) exposition of the stack specification syntax may be
found here: L<http://asc.harvard.edu/ciao/ahelp/stack.html>.

=head2 Methods

The methods implemented here mostly mirror the underlying library.
Some changes have been made to make things more Perl like and to
work around awkwardness in the interface.

=over

=item new

  $stack = CIAO::Lib::StackIO->new( $stackspec, \%args );

This builds a stack.  C<$stackspec> is the user provided stack
specification.  It B<croaks> upon error.

The passed argument hash may contain the following entries

=over

=item prepend I<boolean>

If true, the full path is prepended to each entry of the stack.
This defaults to true.

=item expand I<integer>

If specified, a stack of the specified number of entries is created,
where each entry is consecutively numbered, starting from C<1>. The
C<stackspec> argument should contain the C<#> character, which will be
replaced by the number, which will be padded with leading C<0> digits
to ensure that each string in the stack has the same length.  Only the
first C<#> character will be expanded.

The full path will be prepended to each entry in this stack.  The
value of the B<prepend> option is ignored.

=back

=item append

  $stack->append( $stackspec );
  $stack->append( $stackspec, $prepend );

Append the specified stack entry to the stack. It returns C<0> upon
success, C<1> upon failure.

If the C<$prepend> flag is present, and is true, the full path is
prepended to the entries added to the stack;

=item count

  $count = $stack->count;

returns the number of entries in the stack.

=item change

  $stack->change( $stackdesc );
  $stack->change( $stackdesc, $idx );

In the first form, replace the current entry.

In the second form, replace the stack entry at the specified index.
If the index is C<-1> the last entry will be replaced.
It returns non-zero if the index is out of bounds.

=item current

  $current = $stack->current;
  $oldcurrent = $stack->current( $idx );

In the first form, return the index of the current entry in the stack.
If the stack has been rewound, or has never been read out, this will
return C<0>.

In the second form, set the current entry to the passed index and
return the previous index.  An index of C<-1> indicates the last entry
in the stack.  An index of C<0> is equivalent to rewinding the stack.

If the specified index is out of bounds, the current
entry is set to the closest bound.

=item delete

  $status = $stack->delete;
  $status = $stack->delete( $idx );

In the first form, delete the current entry.

In the second form, delete the entry at the specified index. If the
position is C<-1> the last will be deleted.  It returns non-zero if
the index was out of bounds.

=item disp

  $stack->disp

This dumps the stack to the standard output stream.

=item read

  $entry = $stack->read;
  $entry = $stack->read( $idx );
  @list  = $stack->read;

In the first form, retrieve the next entry in the stack.  It returns
undef if there are no more entries left.  Note that this returns the
entry I<after> the current one.

In the second form (list context), the entire stack is read out.  The
index of the current entry is unchanged.

In the third form, read the entry at the specified index.  If the
index is C<-1>, the last entry will be returned.  If the index is out
of bounds, the entry at the closest bound is returned.



=item rewind

  $stack->rewind;

Rewind the stack so that the next B<read> operation returns the first entry.
This sets the "current" entry index to zero.

=back


=head1 BUGS

The underlying stackio library's error reporting approach is
primitive; it cannot present unique error codes to the caller. It
makes up for it by printing error messages to the standard error
stream.  I consider this a bug, but have not fixed it, as it requires
changes to the library API.


=head1 SEE ALSO

The CIAO application suite is available at L<http://asc.harvard.edu/ciao>.

Much of the documentation was taken from the B<CIAO> online
documentation at
L<http://asc.harvard.edu/ciao/ahelp/index_context.html#stackio> and
L<http://asc.harvard.edu/ciao/ahelp/stack.html>.

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by the Smithsonian Astrophysical Observatory.

The Perl interface to the stklib library is released under the GNU
General Public License.  You may find a copy at
L<http://www.fsf.org/copyleft/gpl.html>.

The source to the included stklib library is released under a separate
license, a copy of which may be found in the stklib subdirectory.

=cut
