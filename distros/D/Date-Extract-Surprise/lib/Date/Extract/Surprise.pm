use strict;
use warnings;
package Date::Extract::Surprise;
BEGIN {
  $Date::Extract::Surprise::VERSION = '0.006';
}
BEGIN {
  $Date::Extract::Surprise::DIST = 'Date-Extract-Surprise';
}
# ABSTRACT: extract probable dates from strings *with surprises*

use Carp qw( croak );
use Scalar::Util qw( blessed );
# just trying to be helpful.
use Exporter::Easy (
    OK => [qw( extract_datetimes )],
);

use DateTime::Format::Flexible qw();


sub new {
    my $class = shift;
    my $self =
        bless {
            DEBUG => 0,
            @_,
        },
    $class;

    return $self;
}



sub extract {
    return unless @_;

    # can be called as an object method, class method, or function
    # there's probably better ways to support this.
    my $self = blessed( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ? shift
             : $_[0] eq __PACKAGE__ ? shift->new()
             : croak "Please call as a class or object method!\n";

    my $text = shift;

    my %args = @_;

    # set a base date for ambiguous DTs we find, default to epoch.
    # if a string value is passed and can't be parsed, croak.
    my $base = blessed( $args{base} ) && $args{base}->isa( 'DateTime' ) ? delete $args{base}
             : defined $args{base} ? DateTime::Format::Flexible->parse_datetime( $args{base} )
             : DateTime->new( year => 1970, month => 1, day => 1 );

    my @timestamps; # populate this

    # there's no immediate need to split into lines, but it should make
    # some future features easier (like reporting which lines matched)
    for my $line ( split /[\n\r]+/, $text ) {

        warn " {$line}\n" if $self->{DEBUG} > 0;

        # split it into terms and remove chars that may trip us up
        my @terms = map { (my $s = $_) =~ s/[,]/ /g; $s } split q[ ], $line;

        for my $i ( 0 .. $#terms ) {
            for my $j ( $i .. $#terms ) {
                my $search_str = join ' ', @terms[$i .. $j];

                # clean up other crap that DT::F::F chokes on?
                $search_str =~ s/at//ig;

                # clean up whitespace
                $search_str =~ s/(\s){2,}/$1/g;
                $search_str =~ s/^\s+|\s+$//g;

                # it almost certainly has some *numbers* in it!
                next unless $search_str =~ /\d/;

                warn "  {$search_str}\n" if $self->{DEBUG} > 1;

                # if we can't determine the *date*, assume epoch
                DateTime::Format::Flexible->base( $base );

                next unless my $dt = eval {
                    DateTime::Format::Flexible->parse_datetime( $search_str );
                };

                push @timestamps, $dt;
            }
        }
    }

    return @timestamps;
}



sub extract_datetimes {
    return unless @_;

    # can be called as an object method, class method, or function
    # there's probably better ways to support this.
    croak "This is a function. Use extract() if you need a method!\n"
        if ( blessed( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) or
           ( $_[0] eq __PACKAGE__ );

    my $self = __PACKAGE__->new();

    return $self->extract( @_ );
}

1 || q{life without coffee isn't worth living}; #truth


=pod

=head1 NAME

Date::Extract::Surprise - extract probable dates from strings *with surprises*

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Date::Extract::Surprise;
  my $des = Date::Extract::Surprise->new();
  my @datetimes = $des->extract( $arbitrary_text );

  # or...
  use Date::Extract::Surprise;
  my @datetimes = Date::Extract::Surprise->extract( $arbitrary_text );

  # or...
  use Date::Extract::Surprise qw( extract_datetimes );
  my @datetimes = extract_datetimes( $arbitrary_text );

=head1 DESCRIPTION

This is modeled on Sartak's excellent L<Date::Extract>, a proven
and capable module that you can use to extract references to dates
and times from otherwise arbitrary text. For example:

  "The package will be delivered at 3:15 PM, March 15, 2007, on the dot."

Upon parsing that, you should end up with a L<DateTime> object
representing March 15, 2007 at 3:15PM in your timezone.

L<Date::Extract> is designed to try to minimize "false-positives"
(ie. detecting things that *aren't* actually dates or times), but
at the expense of potentially missing some dates. As its
documentation states, "I<Surprises are B<not> welcome here.>"

Because I had the I<opposite> need - to find dates in strings I<even
if some were going to be bogus>, I created L<Date::Extract::Surprise>
which will gladly detect anything that even I<remotely looks> like
it could be a date or time.

B<Bottom line:> at least I<one> of the dates this will 'detect' in some
text should be what you wanted. It's up to you to figure out which one
that is! :-)

=head1 METHODS

=head2 new

Just your basic object constructor.

  my $des = Date::Extract::Surprise->new();

Currently takes only one argument:

=head2 extract

This is designed to (more or less) mirror the interface of
Date::Extract->extract(). However, at this time, it supports
almost none of its namesake's extra options, and adds one
additional option.

This can be called as either a class method or as a method on
an object, as seen in the L<SYNOPSIS>.

=head1 FUNCTIONS

=head2 extract_datetimes

If you're old-skool and prefer things to export a function, you can have it.

It takes the same arguments as the L<extract> method and returns the same values.

=for :list = DEBUG
integer greater than 0 for debugging level. higher numbers
give more detail

It will probably take more in the future.

=head1 SEE ALSO

=for :list * Date::Extract
* DateTime::Format::Flexible
* Time::ParseDate
* Date::Manip

=head1 NOTES

Yes, this code is slow and dumb, but it helped me solve a problem and
I hope it may help others, too. Let me know if you need anything changed!

I'm hoping this will work on perl 5.6 and before, because I want
to be helpful to as many people as possible, but I am too lazy
to test it myself. Bug reports and/or patches please!

=head1 TODO

=for :list * more test strings in the tests
* support more options from L<Date::Extract>
* more rigorous tests beyond basic functionality
* eat a sandwich

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

