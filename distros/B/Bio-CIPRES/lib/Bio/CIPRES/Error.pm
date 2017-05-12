package Bio::CIPRES::Error 0.001;

use 5.012;

use strict;
use warnings;

use overload
    '0+'     => sub {return $_[0]->{code}},
    '""'     => \&_stringify,
    fallback => 1;

use Carp;
use Exporter qw/import/;
use XML::LibXML;

# Error codes
use constant ERR_AUTHORIZATION     => 1;
use constant ERR_AUTHENTICATION    => 2;
use constant ERR_NOT_FOUND         => 4;
use constant ERR_FORM_VALIDATION   => 5;
use constant ERR_USER_MISMATCH     => 6;
use constant ERR_BAD_REQUEST       => 7;
use constant ERR_GENERIC_SVC_ERR   => 100;
use constant ERR_GENERIC_COMM_ERR  => 101;
use constant ERR_BAD_INVOCATION    => 102;
use constant ERR_USAGE_LIMIT       => 103;
use constant ERR_DISABLED_RESOURCE => 104;

our @EXPORT_OK = qw/
    ERR_AUTHORIZATION
    ERR_AUTHENTICATION
    ERR_NOT_FOUND
    ERR_FORM_VALIDATION
    ERR_USER_MISMATCH
    ERR_BAD_REQUEST
    ERR_GENERIC_SVC_ERR
    ERR_GENERIC_COMM_ERR
    ERR_BAD_INVOCATION
    ERR_USAGE_LIMIT
    ERR_DISABLED_RESOURCE
/;

our %EXPORT_TAGS = (
    'constants' => \@EXPORT_OK,
);

sub new {

    my ($class, $xml) = @_;

    my $self = bless {}, $class;
    croak "Undefined XML string in constructor\n" if (! defined $xml);
    $self->_parse_xml( $xml );

    return $self;

}

sub _stringify {

    my ($self) = @_;

    return join ' : ', $self->{display},
        map {"Error in param \"$_->{param}\" ($_->{error})"}
        @{ $self->{param_errors} };

}

sub _parse_xml {

    my ($self, $xml) = @_;

    my $dom = XML::LibXML->load_xml('string' => $xml)
        or croak "Error parsing error XML: $!";

    # remove outer tag if necessary
    my $c = $dom->firstChild;
    $dom = $c if ($c->nodeName eq 'error');

    $self->{display} = $dom->findvalue('displayMessage');
    $self->{message} = $dom->findvalue('message');
    $self->{code}    = $dom->findvalue('code');

    # check for missing values
    map {length $self->{$_} || croak "Missing value for $_\n"} keys %$self;

    # parse messages
    for my $err ($dom->findnodes('paramError')) {
        my $ref = {
            param => $err->findvalue('param'),
            error => $err->findvalue('error'),
        };

        # check for missing values
        map {length $ref->{$_} || croak "Missing value for $_\n"} keys %$ref;

        push @{ $self->{param_errors} }, $ref;

    }

    return;

}

1;

__END__

=head1 NAME

Bio::CIPRES::Error - A simple error class for the CIPRES API

=head1 SYNOPSIS

    use Bio::CIPRES:Error qw/:constants/;

    eval {
        $job->download('name' => 'foobar');
    }
    if ($@) {
        warn "Authentication error" if ($@ == ERR_AUTHENTICATION);
        # or just use the default stringification
        warn $@;
    }

=head1 DESCRIPTION

C<Bio::CIPRES::Error> is a simple error class for the CIPRES API. Its purpose
is to parse the XML error report returned by CIPRES and provide an object that
can be used in different contexts. In string context it returns a textual
summary of the error, and in numeric context it returns the error code.

This class does not contain any methods (including the constructor) intended
to be called by the end user. Its functionality is encoded in its overload
behavior as described above.

=head1 EXPORTS

The following error codes are available under the ':constants' tag:

=over 4

=item * ERR_AUTHORIZATION

=item * ERR_AUTHENTICATION

=item * ERR_NOT_FOUND

=item * ERR_FORM_VALIDATION

=item * ERR_USER_MISMATCH

=item * ERR_BAD_REQUEST

=item * ERR_GENERIC_SVC_ERR

=item * ERR_GENERIC_COMM_ERR

=item * ERR_BAD_INVOCATION

=item * ERR_USAGE_LIMIT

=item * ERR_DISABLED_RESOURCE

=back

=head1 METHODS

None

=head1 CAVEATS AND BUGS

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

