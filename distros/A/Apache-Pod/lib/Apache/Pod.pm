package Apache::Pod;

=head1 NAME

Apache::Pod - base class for converting Pod files to prettier forms

=head1 VERSION

Version 0.22

=cut

use vars qw( $VERSION );
use strict;

$VERSION = '0.22';

=head1 SYNOPSIS

The Apache::Pod::* are mod_perl handlers to easily convert Pod to HTML
or other forms.  You can also emulate F<perldoc>.

=head1 CONFIGURATION

All configuration is done in one of the subclasses.

=head1 TODO

I could envision a day when the user can specify which output format
he'd like from the URL, such as

    http://your.server/perldoc/f/printf?rtf

=head1 FUNCTIONS

No functions are exported.  I don't want to dink around with Exporter
in mod_perl if I don't need to.

=head2 getpodfile( I<$r> )

Returns the filename requested off of the C<$r> request object, or what
Perldoc would find, based on Pod::Find.

=cut

use Pod::Find;

sub getpodfile {
    my $r = shift;

    my $filename;

    if ($r->filename =~ m/\.pod$/i) {
        $filename = $r->filename;
    } else {
        my $module = $r->path_info;
        $module =~ s|/||;
        $module =~ s|/|::|g;
        $module =~ s|\.html?$||;  # Intermodule links end with .html

        $filename = Pod::Find::pod_where( {-inc=>1}, $module );

        # XXX Unimplemented
        # $pod =~ s/^f::/-f /;    # If we specify /f/ as our "base", it's a function search
    }

    return $filename;
}

1;

=head1 AUTHOR

Andy Lester <andy at petdance.com>

=head1 ACKNOWLEDGEMENTS

Adapted from Apache::Perldoc by Rich Bowen.  Thanks also to
Pete Krawczyk,
Kjetil Skotheim,
Kate Yoak
and
Chris Eade
for contributions.

=head1 LICENSE

This package is licensed under the same terms as Perl itself.

=cut
