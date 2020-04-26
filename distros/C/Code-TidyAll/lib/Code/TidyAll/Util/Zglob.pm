# This is a copy of Text::Glob, modified to support "**/"
#
package Code::TidyAll::Util::Zglob;

use strict;
use warnings;

our $VERSION = '0.78';

use Exporter qw(import);

our @EXPORT_OK = qw( zglobs_to_regex zglob_to_regex );

our $strict_leading_dot    = 1;
our $strict_wildcard_slash = 1;

use constant debug => 0;

sub zglobs_to_regex {
    my @globs = @_;
    return @globs
        ? do {
        my $re = join( '|', map { "(?:" . zglob_to_regex($_) . ")" } @globs );
        qr/$re/;
        }
        : qr/(?!)/;
}

sub zglob_to_regex {
    my $glob  = shift;
    my $regex = zglob_to_regex_string($glob);
    return qr/^$regex$/;
}

sub zglob_to_regex_string {
    my $glob = shift;
    my ( $regex, $in_curlies, $escaping );
    local $_;
    my $first_byte = 1;
    $glob =~ s/\*\*\//\cZ/g;    # convert **/ to single character
    for ( $glob =~ m/(.)/gs ) {
        if ($first_byte) {
            if ($strict_leading_dot) {
                $regex .= '(?=[^\.])' unless $_ eq '.';
            }
            $first_byte = 0;
        }
        if ( $_ eq '/' ) {
            $first_byte = 1;
        }
        if (   $_ eq '.'
            || $_ eq '('
            || $_ eq ')'
            || $_ eq '|'
            || $_ eq '+'
            || $_ eq '^'
            || $_ eq '$'
            || $_ eq '@'
            || $_ eq '%' ) {
            $regex .= "\\$_";
        }
        elsif ( $_ eq "\cZ" ) {    # handle **/ - if escaping, only escape first *
            $regex .=
                $escaping
                ? ( "\\*" . ( $strict_wildcard_slash ? "[^/]*" : ".*" ) . "/" )
                : ".*";
        }
        elsif ( $_ eq '*' ) {
            $regex .=
                  $escaping              ? "\\*"
                : $strict_wildcard_slash ? "[^/]*"
                :                          ".*";
        }
        elsif ( $_ eq '?' ) {
            $regex .=
                  $escaping              ? "\\?"
                : $strict_wildcard_slash ? "[^/]"
                :                          ".";
        }
        elsif ( $_ eq '{' ) {
            $regex .= $escaping ? "\\{" : "(";
            ++$in_curlies unless $escaping;
        }
        elsif ( $_ eq '}' && $in_curlies ) {
            $regex .= $escaping ? "}" : ")";
            --$in_curlies unless $escaping;
        }
        elsif ( $_ eq ',' && $in_curlies ) {
            $regex .= $escaping ? "," : "|";
        }
        elsif ( $_ eq "\\" ) {
            if ($escaping) {
                $regex .= "\\\\";
                $escaping = 0;
            }
            else {
                $escaping = 1;
            }
            next;
        }
        else {
            $regex .= $_;
            $escaping = 0;
        }
        $escaping = 0;
    }
    print "# $glob $regex\n" if debug;

    return $regex;
}

1;

# ABSTRACT: Test::Glob hacked up to support "**/*"

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::TidyAll::Util::Zglob - Test::Glob hacked up to support "**/*"

=head1 VERSION

version 0.78

=head1 SUPPORT

Bugs may be submitted at
L<https://github.com/houseabsolute/perl-code-tidyall/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Code-TidyAll can be found at
L<https://github.com/houseabsolute/perl-code-tidyall>.

=head1 AUTHORS

=over 4

=item *

Jonathan Swartz <swartz@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2020 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

The full text of the license can be found in the F<LICENSE> file included with
this distribution.

=cut
