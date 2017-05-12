package Data::LineBuffer;

use strict;
use warnings;

our $VERSION = '0.01';

sub new
{
  my $class = shift;
  $class = ref($class) || $class;

  my $self = bless { cache => [], 
		     line => 1 }, $class;



  # we use closures like mad here to make a uniform definition
  # of the  get method possible.

  # Don't shift next argument; need to get a reference
  # to it if it's a scalar.

  my $what = $_[0];

  # scalar? split on newlines
  unless  ( ref $_[0]  ) 
  {
    my $sref = \$_[0];

    pos( $$sref ) = 0;
    
    $self->{next} = 
      sub {
	defined pos($$sref) ? scalar $$sref =~ /^(.*)$/mg && $1 : undef 
      };
  }

  # array? grab the next element
  elsif ( 'ARRAY'  eq ref($what)  ) 
  {
    my $idx = 0;
    $self->{next} =
      sub { $idx == @$what ? undef : $what->[$idx++] }; 
  }
    
  # glob (we're assuming file glob)? read next line
  elsif ( 'GLOB'   eq ref($what)  ) 
  {
    $self->{next} = sub { scalar <$what> };
  }
    
  # subroutine? call it
  elsif ( 'CODE'   eq ref($what)  ) 
  {
    $self->{next} = $what;
  }
    
  # file handle? read next line 
  elsif ( UNIVERSAL::isa($what, 'IO::File')  ) 
  {
    $self->{next} = sub { scalar <$what> };
  }
    
  else
  {
    undef $self;
  }

  $self;
}

sub pos { $_[0]->{line} }

sub unget
{
  my $self = shift;
  push @{$self->{cache}}, @_;

  $self->{line} -= @_; 
}

sub get
{
  my $self = shift;

  my $ret = pop @{$self->{cache}};

  $ret = &{$self->{next}}
    unless defined $ret;

  if ( defined $ret )
  {
    $self->{line}++;
    chomp $ret;
  }

  $ret;
}

sub cache { $_[0]->{cache} };



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Data::LineBuffer - provide a line oriented data push back facility for input sources

=head1 SYNOPSIS

  use Data::LineBuffer;

  $fh = new IO::File $file;
  $src = new Data::LineBuffer $fh;

  $src = new Data::LineBuffer $scalar;

  $src = new Data::LineBuffer \@array;

  $src = new Data::LineBuffer \&sub;

  $next_line = $src->get;

  $src->unget( @lines_i_wish_i_hadnt_gotten );

  print "We just read line", $src->pos, "\n";

=head1 DESCRIPTION

B<Data::LineBuffer> provides a very rudimentary input push back facility.
It provides a layer between the input source and the calling routine
which allows data to be pushed back onto the input source for
retrieval, as a last in, first out, stack.

It is only concerned with line-oriented data, and can interface with a
filehandle, a subroutine (which returns data), a string containing
multiple lines to be parsed, or an array of lines.  In order to
provide a uniform interface, all returned input is B<chomp()>'d.

As an example, consider the following code:

  use Data::LineBuffer;

  my $src = new Data::LineBuffer "Line 1\nLine 2\nLine 3\nLine 4\n";

  print $src->get, "\n";
  print $src->get, "\n";
  $src->unget( "Oh Happy Day!" );
  $src->unget( "I Sing with Joy!" );
  print $src->get, "\n";
  print $src->get, "\n";
  print $src->get, "\n";

This produces the following output:

  Line 1
  Line 2
  I Sing with Joy!
  Oh Happy Day!
  Line 3
  Line 4

=head2 Constructors

=over 8

=item new

  $src = new Data::LineBuffer $fh;
  $src = new Data::LineBuffer $scalar;
  $src = new Data::LineBuffer \@array;
  $src = new Data::LineBuffer \&sub;
   
The constructor can take a filehandle, a subroutine, a scalar, or an array.
It returns undefined if an error ocurred, which currently occurs
only if it is passed a type not in the above list.

Each element of an array source is considered a single line, regardless
of the number of actual lines in the element.

Scalar sources are chopped up (figuratively) into separate lines.

Subroutines should return the next line or C<undef> if there are no more.

=back

=head2 Methods

=over 8

=item get

  $line = $src->get;

This returns the next line from the input source.  The line is
B<chomp()>'d before being returned. It returns the undefined value
when input has been exhausted. 

Do I<not> test for end of input like this,

   while ( $_ = $src->get() )  # WRONG! DON'T DO THIS!

as empty lines or lines which resolve to a numeric value of zero
will fail this test.  Instead, ensure that the result is defined:

   while ( defined( $_ = $src->get()) )  # CORRECT! DO THIS!

=item unget

  $src->unget( $line );
  $src->unget( @lines );

This pushes one or more lines back onto the input source. Lines
will be returned by B<get()> in the reverse order in which they
were pushed, i.e. Last In First out.

=item pos

  my $pos

This returns the current line position in the source.  This is
the line number of the I<next> line to be read.

=back

=head2 EXPORT

None by default.

=head1 LIMITATIONS

All of the cached data is stored in memory.

The scalar's search position (see the B<pos> Perl function) is used to
keep track of the next line.  Don't muck about with the scalar (or
do any regexp's on it) or you'll confuse this poor module.

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius (djerius@cpan.org)

=cut
