# Copyrights 2013-2019 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Any-Daemon-HTTP. Meta-POD processed
# with OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Any::Daemon::FCGI::Request;
use vars '$VERSION';
$VERSION = '0.29';

use base 'HTTP::Request';

use warnings;
use strict;

use Log::Report      'any-daemon-http';


sub new($)
{   my ($class, $args) = @_;
    my $params = $args->{params} or panic;
    my $role   = $args->{role}   or panic;
 
    my @headers;
 
    # Content-Type and Content-Length come specially
    push @headers, 'Content-Type' => $params->{CONTENT_TYPE}
        if exists $params->{CONTENT_TYPE};

    push @headers, 'Content-Length' => $params->{CONTENT_LENGTH}
        if exists $params->{CONTENT_LENGTH};
 
    # Pull all the HTTP_FOO parameters as headers. These will be in all-caps
    # and use _ for word separators, but HTTP::Headers can cope with that.
    foreach (keys %$params)
    {   push @headers, $1 => $params->{$_} if m/^HTTP_(.*)$/;
    }
 
    my $self   = $class->SUPER::new
      ( $params->{REQUEST_METHOD}
      , $params->{REQUEST_URI}
      , \@headers
      , $args->{stdin}
      );

    $self->protocol($params->{SERVER_PROTOCOL});

    $self->{ADFR_reqid}  = $args->{request_id} or panic;
    $self->{ADFR_params} = $params;
    $self->{ADFR_role}   = $role;
    $self->{ADFR_data}   = $args->{data};

    $self;
}

#----------------

sub request_id { shift->{ADFR_reqid} }
sub params() { shift->{ADFR_params} }
sub param($) { $_[0]->{ADFR_params}{$_[1]} }
sub role()   { shift->{ADFR_role} }


sub data()   { shift->{ADFR_data} }

1;
