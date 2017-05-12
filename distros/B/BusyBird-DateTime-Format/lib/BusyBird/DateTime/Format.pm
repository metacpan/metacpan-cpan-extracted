package BusyBird::DateTime::Format;
use strict;
use warnings;
use DateTime::Format::Strptime;
use Try::Tiny;

our $VERSION = "0.05";

our $preferred = 0;

my %OPT_DEFAULT = (
    locale => 'en_US',
    on_error => 'undef',
);

my @FORMATS = (
    DateTime::Format::Strptime->new(
        %OPT_DEFAULT,
        pattern => '%a %b %d %T %z %Y',
    ),
    DateTime::Format::Strptime->new(
        %OPT_DEFAULT,
        pattern => '%a, %d %b %Y %T %z',
    ),
);

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub parse_datetime {
    my ($class_self, $string) = @_;
    my $parsed;
    return undef if not defined $string;
    foreach my $f (@FORMATS) {
        $parsed = try {
            $f->parse_datetime($string);
        }catch {
            undef;
        };
        last if defined($parsed);
    }
    return $parsed;
}

sub format_datetime {
    my ($class_self, $datetime) = @_;
    return $FORMATS[$preferred]->format_datetime($datetime);
}



1;
__END__

=pod

=head1 NAME

BusyBird::DateTime::Format - DateTime::Format for BusyBird

=head1 SYNOPSIS

    use BusyBird::DateTime::Format;
    my $f = 'BusyBird::DateTime::Format';

    ## Twitter API format
    my $dt1 = $f->parse_datetime('Fri Feb 08 11:02:15 +0900 2013');

    ## Twitter Search API format
    my $dt2 = $f->parse_datetime('Sat, 16 Feb 2013 23:02:54 +0000');

    my $str = $f->format_datetime($dt2);
    ## $str: 'Sat Feb 16 23:02:54 +0000 2013'


=head1 DESCRIPTION

This class is the standard DateTime::Format in L<BusyBird>.

It has a separate distribution from L<BusyBird>, so that input/filter modules
do not have to depend on the entire L<BusyBird> infrastructure.

L<BusyBird::DateTime::Format> can parse the following format.

=over

=item *

'created_at' format of Twitter API.

=item *

'created_at' format of Twitter Search API v1.0.

=back

It formats L<DateTime> object in 'created_at' format of Twitter API.


=head1 CLASS METHODS

=head2 $f = BusyBird::DateTime::Format->new()

Creates a formatter.

=head1 CLASS AND OBJECT METHODS

The following methods can apply both to class and to an object.

=head2 $datetime = $f->parse_datetime($string)

Parse C<$string> to get L<DateTime> object.

If given an improperly formatted string, this method returns C<undef>. It NEVER croaks.

=head2 $string = $f->format_datetime($datetime)

Format L<DateTime> object to a string.

=head1 SEE ALSO

L<BusyBird>

=head1 REPOSITORY

L<https://github.com/debug-ito/BusyBird-DateTime-Format>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/BusyBird-DateTime-Format/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=BusyBird-DateTime-Format>.
Please send email to C<bug-BusyBird-DateTime-Format at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

