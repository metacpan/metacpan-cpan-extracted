package Apache::AuthCookie::Util;
$Apache::AuthCookie::Util::VERSION = '3.29';
# ABSTRACT: Internal Utility Functions for AuthCookie

use strict;
use base 'Exporter';

our @EXPORT_OK = qw(is_blank);


sub expires {
    my($time,$format) = @_;
    $format ||= 'http';

    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;

    # pass through preformatted dates for the sake of expire_calc()
    $time = expire_calc($time);
    return $time unless $time =~ /^\d+$/;

    # make HTTP/cookie date string from GMT'ed time
    # (cookies use '-' as date separator, HTTP uses ' ')
    my($sc) = ' ';
    $sc = '-' if $format eq "cookie";
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    $year += 1900;
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
                   $WDAY[$wday],$mday,$MON[$mon],$year,$hour,$min,$sec);
}

# -- expire_calc() shamelessly taken from CGI::Util
# This internal routine creates an expires time exactly some number of
# hours from the current time.  It incorporates modifications from 
# Mark Fisher.
sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || (lc($time) eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^\d+/) {
        return $time;
    } elsif ($time=~/^([+-]?(?:\d+|\d*\.\d*))([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return (time+$offset);
}

# escape embedded CR, LF, TAB's to prevent possible XSS attacks.
# see http://www.securiteam.com/securityreviews/5WP0E2KFGK.html
sub escape_destination {
    my $text = shift;

    $text =~ s/([\r\n\t\>\<"])/sprintf("%%%02X", ord $1)/ge;

    return $text;
}

# return true if the given user agent understands a HTTP_FORBIDDEN response
# with custom content. Some agents (e.g.: Symbian OS browser), use their own
# HTML and completely ignore the HTTP content.
sub understands_forbidden_response {
    my $ua = shift;

    return 0 if $ua =~ qr{\AMozilla/5\.0 \(SymbianOS/}  # Symbian phones
             or $ua =~ qr{\bIEMobile/10};            # Nokia Lumia 920, possibly others?

    return 1;
}

# return true if the given value is blank or not defined.
sub is_blank {
    return defined $_[0] && ($_[0] =~ /\S/) ? 0 : 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Apache::AuthCookie::Util - Internal Utility Functions for AuthCookie

=head1 VERSION

version 3.29

=head1 DESCRIPTION

Internal Use Only!

=for Pod::Coverage *EVERYTHING*

=head1 SOURCE

The development version is on github at L<https://https://github.com/mschout/apache-authcookie>
and may be cloned from L<git://https://github.com/mschout/apache-authcookie.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/apache-authcookie/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Ken Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
