package Astro::FITS::CFITSIO::CheckStatus;

use 5.006;
use strict;
use warnings;

use Carp;

our $VERSION = '0.03';


sub TIESCALAR
{
  my $class = shift;

  my $self = bless {}, $class;

  # the next argument tells us how to croak
  $self->set_croak( @_ ? shift : \&Carp::croak );

  $self->{value} = 0;
  $self->utxt( undef );
  $self->{etxt} = undef;
  $self->reset_ustr( 1 );
  $self->reset_usub( 1 );

  $self;
}

sub FETCH
{
  $_[0]->{value};
}

sub STORE
{
  require Scalar::Util;

  if ( defined $_[1] && ! ref $_[1] && Scalar::Util::looks_like_number( $_[1] ) )
  {
    # set to non-zero value
    if ( $_[0]->{value} = $_[1] )
    {
      require Astro::FITS::CFITSIO;

      Astro::FITS::CFITSIO::fits_get_errstatus($_[0]->{value}, $_[0]->{etxt});
      $_[0]->{croak}->( 
         defined $_[0]->{utxt} ? ( 'CODE' eq ref $_[0]->{utxt} ?
				   $_[0]->{utxt}->(@{$_[0]}{'value','etxt'}) :
				   $_[0]->{utxt}
				 ) : "CFITSIO error: ", $_[0]->{etxt} )
	if defined $_[0]->{croak};

    }

    # set to zero value
    else
    {
      $_[0]->{etxt} = undef;

      # reset utxt if the planets are aligned
      if ( 'CODE' eq ref $_[0]->{utxt} )
      {
	$_[0]->{utxt} = undef
	  if $_[0]->{reset_usub};
      }

      elsif ( $_[0]->{reset_ustr} )
      {
	$_[0]->{utxt} = undef;
      }
    }

  }

  else
  {
    $_[0]->{utxt} = $_[1];
  }
}

sub set_croak
{
  my $self = shift;

  my $old_croak = $self->{croak};

  if ( @_ )
  {
    my $croak = shift;

    # explicit undef to reset to no croaking?
    if ( ! defined $croak )
    {
      $self->{croak} = undef;
    }

    # Log::Log4perl::Logger object?
    elsif ( UNIVERSAL::isa( $croak, 'Log::Log4perl::Logger' ) )
    {
      my $logger = $croak;
      $self->{croak} =
	sub { local $Log::Log4perl::caller_depth = 2;
	      $logger->fatal( @_ ) && Carp::croak (@_) };
    }

    # subroutine reference
    elsif ( 'CODE' eq ref $croak )
    {
      $self->{croak} = $croak;
    }

    # everything else is no good
    else
    {
      croak( "illegal value passed to croak()\n" );
    }
  }
  return $old_croak;
}

sub utxt
{
  my $self = shift;
  my $old_utxt = $self->{utxt};
  $self->{utxt} = shift if @_;
  $old_utxt;
}

sub etxt
{
  $_[0]->{etxt};
}

sub reset_ustr
{
  my $self = shift;
  my $old_ar = $self->{reset_ustr};
  $self->{reset_ustr} = shift if @_;
  $old_ar;
}

sub reset_usub
{
  my $self = shift;
  my $old_ar = $self->{reset_usub};
  $self->{reset_usub} = shift if @_;
  $old_ar;
}

1;
__END__

=head1 NAME

Astro::FITS::CFITSIO::CheckStatus - automatically catch CFITSIO status errors

=head1 SYNOPSIS

  use Astro::FITS::CFITSIO::CheckStatus;

  # call Carp::croak upon error
  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus';
  $fptr = Astro::FITS::CFITSIO::create_file( $file, $status );

  # call user specified function upon error:
  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus', $mycroak;
  $fptr = Astro::FITS::CFITSIO::create_file( $file, $status );

  # call Log::Log4perl->logcroak;
  $logger = Log::Log4perl::get_logger();
  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus', $logger;
  $fptr = Astro::FITS::CFITSIO::create_file( $file, $status );

=head1 DESCRIPTION

The B<CFITSIO> library uses the concept of a status variable passed to
each B<CFITSIO> function call to return an error status.  At present,
the B<Astro::FITS::CFITSIO> Perl interface mirrors the B<CFITSIO>
interfaces directly, and does not do anything special to handle error
returns (e.g., by throwing an exception).  It should be noted that
B<CFITSIO> routines will not perform their requested action if a
non-zero status value is passed in, so as long as the same status
variable is used throughout, B<CFITSIO> routines won't do extra work
after an error. However, this can lead to the situation where one does
not know at which step the error occurred.

In order to immediately catch an error, the status error must be
checked after each call to a B<CFITSIO> routine.  Littering one's code
with status variable checks is ugly.

This module resolves the impasse by tieing the status variable to a
class which will check the value every time it is set, and throw an
exception (via B<Carp::croak>) containing the B<CFITISO> error message
if the value is non-zero.  

The drawback to this approach is that only the (sometimes)
impenetrable B<CFITSIO> error message is available.  If the
tied variable is set equal to a string (which should not pass the
B<Scalar::Util::look_like_number()> test) or a subroutine, the string
or return value from the subroutine is prepended to the B<CFITSIO>
error message.  For example

  Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits',
	   Astro::FITS::CFITSIO::READONLY(), $status = "Bad Open:" );

will result in:

  Bad Open: CFITSIO error: could not open the named file

The prefixing value may also be specified with the the B<utxt()>
method (see L<Class Methods>).  Whenever the status variable is set to
zero, the prefixing value is forgotten.  As Astro::FITS::CFITSIO sets
the status variable (whether zero or not) after every call to a
B<CFITSIO> function, this implies that the prefix will not reset after
every successful function call.  This behavior may be modified by the
B<reset_ustr()> and B<reset_usub()> class methods in L<Class Methods>.
Alternatively, the prefix may be reset by assigning C<undef> to the
status variable.

The caller may provide an alternate means of throwing the exception,
either by passing in a subroutine reference,

  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus', 
           sub { die "An awful thing happened: @_" };
  $fptr = Astro::FITS::CFITSIO::create_file( $file, $status );

or a reference to a B<Log::Log4perl::Logger> object.

  $logger = Log::Log4perl::get_logger();
  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus', $logger;
  $fptr = Astro::FITS::CFITSIO::create_file( $file, $status );

In the latter case, it will be equivalent to calling
C<$logger-E<gt>logcroak>.  An alternative interface is available via
the B<set_croak()> method (see L<Class Methods>).

=head2 Class Methods

The object to which the status variable is tied (accessible via the Perl
B<tied> function) has the following methods:

=over

=item set_croak

  $func = $obj->set_croak;
  $old_value = $obj->set_croak( sub { ... } )

Get or set the function called if the status variable is set to a
non-zero numerical value.  The function takes a single argument.

=item utxt

  $utxt = $obj->utxt;
  $old_value = $obj->utxt( "user error message" );

This provides access to the "user text" which may prefix the output
error message.  It is another interface to the functionality provided
by setting the status variable to either a string or a code reference.

=item etxt

  print $obj->etxt, "\n";

This provides access to the B<CFITSIO> error string if the status has
been set to a non-zero numerical value.

=item reset_ustr

  $old_value = $obj->reset_ustr( $boolean )

If the passed value is C<true>, every time that the status variable is
set to zero, and the "user text" is a string, it will be set to the
undefined value.  The default value is C<true>

=item reset_usub

  $old_value = $obj->reset_usub( $boolean )

If the passed value is C<true>, every time that the status variable is
set to zero, and the "user text" is a subroutine reference, it will be
set to the undefined value.  The default value is C<true>.

=back

=head2 EXPORT

None by default.


=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by The Smithsonian Astrophysical Observatory.

This software is released under the GNU General Public License.
You may find a copy at L<http://www.fsf.org/copyleft/gpl.html>.

=head1 SEE ALSO

L<Astro::FITS::CFITSIO>, L<perl>.

=cut
