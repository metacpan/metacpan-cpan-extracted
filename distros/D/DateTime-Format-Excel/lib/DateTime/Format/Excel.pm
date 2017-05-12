package DateTime::Format::Excel;
# $Id: Excel.pm 4458 2010-10-20 09:53:33Z achim66 $

=head1 NAME

DateTime::Format::Excel - Convert between DateTime and Excel dates.

=cut

use strict;
use 5.005;
use Carp;
use DateTime 0.1705;
use vars qw( $VERSION );

$VERSION = '0.31';

=head1 SYNOPSIS

    use DateTime::Format::Excel;

    # From Excel via class method:

    my $datetime = DateTime::Format::Excel->parse_datetime( 37680 );
    print $datetime->ymd();     # prints 2003-02-28

    my $datetime = DateTime::Format::Excel->parse_datetime( 40123.625 );
    print $datetime->iso8601(); # prints 2009-11-06T15:00:00

    #  or via an object
    
    my $excel = DateTime::Format::Excel->new();
    print $excel->parse_datetime( 25569 )->ymd; # prints 1970-01-01

    # Back to Excel number:
    
    use DateTime;
    my $dt = DateTime->new( year => 1979, month => 7, day => 16 );
    my $daynum = DateTime::Format::Excel->format_datetime( $dt );
    print $daynum; # prints 29052

    my $dt_with_time = DateTime->new( year => 2010, month => 7, day => 23
                                    , hour => 18, minute => 20 );
    my $excel_date = DateTime::Format::Excel->format_datetime( $dt_with_time );
    print $excel_date; # prints 40382.763888889

    # or via the object created above
    my $other_daynum = $excel->format_datetime( $dt );
    print $other_daynum; # prints 29052

=head1 DESCRIPTION

Excel uses a different system for its dates than most Unix programs.
This module allows you to convert between a few of the Excel raw formats
and C<DateTime> objects, which can then be further converted via any
of the other C<DateTime::Format::*> modules, or just with C<DateTime>'s
methods.

If you happen to be dealing with dates between S<1 Jan 1900> and
S<1 Mar 1900> please read the notes on L<epochs|/EPOCHS>.

Since version 0.30 this modules handles the time part (the decimal 
fraction of the Excel time number) correctly, so you can convert
a single point in time to and from Excel format. (Older versions
did only calculate the day number, effectively loosing the time
of day information).
The H:M:S is stored as a fraction where 1 second = 1 / (60*60*24).

If you're wanting to handle actual spreadsheet files, you may find
L<Spreadsheet::WriteExcel> and L<Spreadsheet::ParseExcel> of use.

=head1 CONSTRUCTORS

=head2 new

Creates a new C<DateTime::Format::Excel> instance. This is generally
not required for simple operations. If you wish to use a different
epoch, however, then you'll need to create an object.

   my $excel = DateTime::Format::Excel->new()
   my $copy = $excel->new();

It takes no parameters. If called on an existing object then it
clones the object.

=cut

sub new
{
    my $class = shift;
    croak "${class}->new takes no parameters." if @_;

    my $self = bless {}, ref($class)||$class;
    if (ref $class)
    {
	# If called on an object, clone
	$self->_epoch( scalar $class->epoch );
	# and that's it. we don't store that much info per object
    }

    $self;
}

=head2 clone

This method is provided For those who prefer to explicitly clone via a
method called C<clone()>. If called as a class method it will die.

   my $clone = $original->clone();

=cut

sub clone
{
    my $self = shift;
    croak 'Calling object method as class method!' unless ref $self;
    return $self->new();
}

=head1 CLASS/OBJECT METHODS

These methods work as both class and object methods.

=head2 parse_datetime

Given an Excel day number, return a C<DateTime> object representing that
date and time.

    # As a class method
    my $datetime = DateTime::format::Excel->parse_datetime( 37680 );
    print $datetime->ymd('.'); # '2003.02.28'

    # Or via an object
    my $excel = DateTime::Format::Excel->new();
    my $viaobj $excel->parse_datetime( 25569 );
    print $viaobj->ymd; # '1970-01-01'

=cut

sub parse_datetime
{
    my $self = shift;
    croak 'No date specified.' unless @_;
    croak 'Invalid number of days' unless $_[0] =~ /^ (\d+ (?: (\.\d+ ) )? ) $/x;
    my $excel_days = $1;
    my $excel_secs = $2;
    my $dt = DateTime->new( $self->epoch );
    if(defined $excel_secs){
       $excel_secs           = $excel_secs * 86400; # RT7498
       my $excel_nanoseconds = ($excel_secs - int($excel_secs)) * 1_000_000_000;
       $dt->add( days        => $excel_days,
                 seconds     => $excel_secs,
                 nanoseconds => $excel_nanoseconds);
    } else {
       $dt->add( days => $excel_days );
    }
    return $dt;
}

=head2 format_datetime

Given a C<DateTime> object, return the Excel daynum time.

    use DateTime;
    my $dt = DateTime->new( year => 1979, month => 7, day => 16 );
    my $daynum = DateTime::Format::Excel->format_datetime( $dt );
    print $daynum; # 29052

    # or via an object
    my $excel = DateTime::Format::Excel->new();
    $excel->epoch_mac(); # Let's imagine we want the Mac number
    my $mac_daynum = $excel->format_datetime( $dt );
    print $mac_daynum; # 27590


=cut

sub format_datetime
{
    my $self = shift;
    croak 'No DateTime object specified.' unless @_;
    my $dt = shift;

    my $base = DateTime->new( $self->epoch );
    my $excel = $dt->jd - $base->jd; # RT7498

    return $excel;
}

=begin _development

=head1 BETA METHODS

I don't really know whether durations should be handled by this module.
They're nothing interesting.

=cut

sub parse_duration
{
    my $self = shift;
    croak 'No duration specified.' unless @_;
    croak 'Invalid number of days' unless $_[0] =~ /^ (\d+ (?: \.\d+ )? ) $/x;
    my $days = $1;

    return DateTime::Duration->new( days => $days );
}

sub format_duration
{
    my $self = shift;
    croak 'No DateTime::Duration object specified.' unless @_;

    return $_[0]->delta_days();
}

=end _development

=head1 OBJECT METHODS

=head2 epoch

In scalar context, returns a string identifying the current epoch.

   my $epoch = $excel->epoch();

Currently either `mac' or `win' with the default being `win'.

In list context, returns appropriate parameters with which to
create a C<DateTime> object representing the start of the epoch.

   my $base = DateTime->new( $excel->epoch );

=cut

sub epoch { $_[0]->_epoch() }

=head2 epoch_mac

Set the object to use a Macintosh epoch.

   $excel->epoch_mac(); # epoch is now  1 Jan 1904

Thus, 1 maps to C<2 Jan 1904>.

=cut

sub epoch_mac { $_[0]->_epoch('mac') }

=head2 epoch_win

Set the object to use a Windows Excel epoch.

   $excel->epoch_win(); # epoch is now 30 Dec 1899

Thus, 2 maps to C<1 Jan 1900>.

=cut

sub epoch_win { $_[0]->_epoch('win') }

=head1 EPOCHS

Excel uses ``number of days since S<31 Dec 1899>''. Naturally, Microsoft
messed this up because they happened to believe that 1900 was a leap
year. In this module, we assume what Psion assumed for their Abacus /
Sheet program: S<1 Jan 1900> maps to 2 rather than 1. Thus, 61 maps to
S<1 Mar 1900> in both Excel and this module (and Abacus).

I<Excel for Macintosh> has a little option hidden away in its
calculations preferences. It can use either the Windows epoch, or it can
use the Macintosh epoch, which means that the day number is calculated
as ``number of days since S< 1 Jan 1904>''. This module supports both
notations.

B<Note>: the results of this module have only been compared with
I<Microsoft Excel for Macintosh 98> and I<Abacus> on the
I<Acorn Pocket Book>. Where they have differed, I've opted for I<Abacus>'s
result rather than I<Excel>'s.

=cut

{
    my %epochs = (
	win => [ year => 1899, month => 12, day => 30 ],
	mac => [ year => 1904, month => 1, day => 1 ],
    );

    sub _epoch
    {
	my $self = shift;
	if (@_)
	{
	    croak 'Calling object method as class method!' unless ref $self;
	    croak 'Invalid epoch' unless exists $epochs{$_[0]};
	    $self->{epoch} = $_[0];
	    return $self; # more useful this way, I feel.
	}
	else
	{
	    my $epoch;
	    $epoch = $self->{epoch} if ref $self;
	    $epoch ||= 'win';
	    return wantarray ? @{ $epochs{$epoch} } : $epoch;
	}
    }
}

1;

__END__

=head1 THANKS

Dave Rolsky (DROLSKY) for kickstarting the DateTime project.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

Alternatively, log them via the CPAN RT system via the web or email:

    http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime%3A%3AFormat%3A%3AExcel
    bug-datetime-format-excel@rt.cpan.org

This makes it much easier for us to track things and thus means
your problem is less likely to be neglected.

=head1 LICENCE AND COPYRIGHT

Copyright E<copy> 2003-2010 Iain Truskett, Dave Rolsky, Achim Bursian. 
All rights reserved. This library is free software; you can redistribute 
it and/or modify it under the same terms as Perl itself.

The full text of the licences can be found in the F<Artistic> and
F<COPYING> files included with this module.

=head1 AUTHOR

Originally written by Iain Truskett <spoon@cpan.org>, who died on
December 29, 2003.

Maintained by Dave Rolsky <autarch@urth.org> and, since 2010-06-01, by 
Achim Bursian <aburs@cpan.org>.

The following people have either submitted patches or suggestions,
or their bug reports or comments have inspired the appropriate
patches.  

 Peter (Stig) Edwards  
 Bobby Metz

=head1 SEE ALSO

datetime@perl.org mailing list.

http://datetime.perl.org/

L<perl>, L<DateTime>, L<Spreadsheet::WriteExcel>

=cut
