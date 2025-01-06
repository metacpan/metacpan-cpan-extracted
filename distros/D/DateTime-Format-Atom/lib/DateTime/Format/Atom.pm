
package DateTime::Format::Atom;

use strict;
use warnings;

use version; our $VERSION = qv( 'v1.8.0' );

use DateTime::Format::RFC3339 qw( );


use constant NEXT_IDX => 0;


my $helper = DateTime::Format::RFC3339->new( uc_only => 1 );


sub new {
   my $class = shift;
   #my %opts = @_;

   my $self = bless( [], $class );

   # $self->[ IDX_HELPER ]->parse_datetime( $str );

   return $self;
}


sub parse_datetime {
   my $self = shift;
   my $str  = shift;

   # $self = $default_self //= $self->new()
   #    if !ref( $self );
   #
   # return $self->[ IDX_HELPER ]->parse_datetime( $str );

   return $helper->parse_datetime( $str );
}


sub format_datetime {
   my $self = shift;
   my $dt   = shift;

   # $self = $default_self //= $self->new()
   #    if !ref( $self );
   #
   # return $self->[ IDX_HELPER ]->format_datetime( $dt );

   return $helper->format_datetime( $dt );
}


1;


__END__

=head1 NAME

DateTime::Format::Atom - Parse and format Atom datetime strings


=head1 VERSION

Version 1.8.0


=head1 SYNOPSIS

   use DateTime::Format::Atom;

   my $format = DateTime::Format::Atom->new();
   my $dt = $format->parse_datetime( '2002-07-01T13:50:05Z' );

   # 2002-07-01T13:50:05Z
   print $format->format_datetime( $dt );


=head1 DESCRIPTION

This module understands the Atom date/time format, an ISO 8601 profile, defined
at L<http://tools.ietf.org/html/rfc4287>

It can be used to parse these formats in order to create the appropriate
objects.

All the work is actually done by L<DateTime::Format::RFC3339>.

=head1 CONSTRUCTOR

=head2 new

   my $format = DateTime::Format::Atom->new();


=head1 METHODS

=head2 parse_datetime

   my $dt = DateTime::Format::Atom->parse_datetime( $string );
   my $dt = $format->parse_datetime( $string );

Given a Atom datetime string, this method will return a new
L<DateTime> object.

If given an improperly formatted string, this method will croak.

For a more flexible parser, see L<DateTime::Format::ISO8601>.


=head2 format_datetime

   my $string = DateTime::Format::Atom->format_datetime( $dt );
   my $string = $format->format_datetime( $dt );

Given a L<DateTime> object, this methods returns a Atom datetime
string.


=head1 SEE ALSO

=over 4

=item * L<DateTime>

=item * L<DateTime::Format::RFC3339>

=item * L<DateTime::Format::ISO8601>

=item * L<http://tools.ietf.org/html/rfc3339>, "Date and Time on the Internet: Timestamps"

=item * L<http://tools.ietf.org/html/rfc4287>, "The Atom Syndication Format"

=back


=head1 DOCUMENTATION AND SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Format::Atom

You can also find it online at this location:

=over

=item * L<https://metacpan.org/dist/Datetime-Format-Atom>

=back

If you need help, the following are great resources:

=over

=item * L<https://stackoverflow.com/|StackOverflow>

=item * L<http://www.perlmonks.org/|PerlMonks>

=item * You may also contact the author directly.

=back


=head1 BUGS

Please report any bugs or feature requests using L<https://github.com/ikegami/perl-Datetime-Format-Atom/issues>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 REPOSITORY

=over

=item * Web: L<https://github.com/ikegami/perl-Datetime-Format-Atom>

=item * git: L<https://github.com/ikegami/perl-Datetime-Format-Atom.git>

=back


=head1 AUTHOR

Eric Brine, C<< <ikegami@adaelis.com> >>


=head1 COPYRIGHT AND LICENSE

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.


=cut
