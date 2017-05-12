package ArangoDB2::HTTP;

use strict;
use warnings;

use ArangoDB2::HTTP::LWP;



# new
#
# create new ArangoDB2::HTTP instance which will always be
# one of the sub-classes of ArangoDB2::HTTP which implements
# a particular HTTP client
sub new
{
    my($self, $arango) = @_;

    # see if specific http client is set
    if (my $http_client = $arango->http_client) {
        if ($http_client eq 'lwp') {
            return ArangoDB2::HTTP::LWP->new($arango);
        }
        elsif ($http_client eq 'curl') {
            require ArangoDB2::HTTP::Curl;
            return ArangoDB2::HTTP::Curl->new($arango);
        }
    }

    # if no client was set then use curl if possible
    # and if not fall back to LWP
    my $curl = eval { require WWW::Curl::Easy };

    if ($curl) {
        require ArangoDB2::HTTP::Curl;
        return ArangoDB2::HTTP::Curl->new($arango);
    }
    else {
        # for now use lwp client
        return ArangoDB2::HTTP::LWP->new($arango);
    }
}

# arango
#
# ArangoDB2 instance
sub arango { $_[0]->{arango} }

# error
#
# get/set last error (HTTP status) code
sub error
{
    my($self, $error) = @_;

    $self->{error} = $error
        if defined $error;

    return $self->{error};
}

1;

__END__


=head1 NAME

ArangoDB2::HTTP - Base class for HTTP transport layer implementations

=head1 METHODS

=over 4

=item new

=item arango

=item error

=back

=head1 AUTHOR

Ersun Warncke, C<< <ersun.warncke at outlook.com> >>

http://ersun.warnckes.com

=head1 COPYRIGHT

Copyright (C) 2014 Ersun Warncke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
