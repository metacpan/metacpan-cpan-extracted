#!/usr/bin/perl -w

package Apache::Sling::URL;

use 5.008001;
use strict;
use warnings;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub add_leading_slash

sub add_leading_slash {
    my ($value) = @_;
    if ( defined $value ) {
        if ( $value !~ /^\//msx ) {
            $value = "/$value";
        }
    }
    return ($value);
}

#}}}

#{{{sub strip_leading_slash

sub strip_leading_slash {
    my ($value) = @_;
    if ( defined $value ) {
        $value =~ s/^\///msx;
    }
    return ($value);
}

#}}}

#{{{sub properties_array_to_string

sub properties_array_to_string {
    my ($properties) = @_;
    my $property_post_vars;
    foreach my $property ( @{$properties} ) {

        # Escaping single quotes:
        $property =~ s/'/\\'/gmsx;
        $property =~ /^([^=]*)=(.*)/msx;
        if ( defined $1 ) {
            $property_post_vars .= "'$1','$2',";
        }
    }
    if ( defined $property_post_vars ) {
        $property_post_vars =~ s/,$//msx;
    }
    else {
        $property_post_vars = q{};
    }
    return $property_post_vars;
}

#}}}

#{{{sub urlencode

sub urlencode {
    my ($value) = @_;
    $value =~
      s/([^a-zA-Z_0-9 ])/"%" . uc(sprintf "%lx" , unpack("C", $1))/egmsx;
    $value =~ tr/ /+/;
    return ($value);
}

#}}}

#{{{sub url_input_sanitize

sub url_input_sanitize {
    my ($url) = @_;
    $url = ( defined $url ? $url : 'http://localhost:8080' );
    $url = ( $url ne q{} ? $url : 'http://localhost:8080' );
    $url =~ s/(.*)\/$/$1/msx;
    $url = ( $url !~ /^http/msx ? "http://$url" : "$url" );
    return ($url);
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::URL - Functions for handling urls to be passed from/to an Apache Sling instance.

=head1 ABSTRACT

useful utility functions for manipulating URLs.

=head1 METHODS

=head2 add_leading_slash

Function to add a leading slash to a string if one does not exist.

=head2 strip_leading_slash

Function to remove any leading slashes from a string.

=head2 properties_array_to_string

Function to convert an array of a property values to a suitable string
representation.

=head2 urlencode

Function to encode a string so it is suitable for use in urls.

=head2 url_input_sanitize

Sanitizes input url by removing trailing slashes and adding a protocol if
missing.

=head1 USAGE

use Apache::Sling::URL;

=head1 DESCRIPTION

Utility library providing useful URL functions for general Rest functionality.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
