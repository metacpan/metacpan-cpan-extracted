package Amazon::SimpleDB;
use strict;
use warnings;

our $VERSION = '0.03';

use URI;
use LWP::UserAgent;
use Digest::HMAC_SHA1;
use MIME::Base64 qw(encode_base64);
use Carp qw( croak );

use Amazon::SimpleDB::Domain;
use Amazon::SimpleDB::Response;

use constant SERVICE_URI          => 'http://sdb.amazonaws.com/';
use constant KEEP_ALIVE_CACHESIZE => 10;

sub new {
    my $class = shift;
    my $args  = shift || {};
    my $self  = bless $args, $class;
    croak "No aws_access_key_id"     unless $self->{aws_access_key_id};
    croak "No aws_secret_access_key" unless $self->{aws_secret_access_key};
    unless ($self->{agent}) {
        my $agent = LWP::UserAgent->new(keep_alive => KEEP_ALIVE_CACHESIZE);
        $agent->timeout(10);
        $agent->env_proxy;
        $self->{agent} = $agent;
    }
    return $self;
}

sub domains {
    my $self   = shift;
    my $args   = shift || {};
    my $params = {};
    $params->{MaxNumberOfDomains} = $args->{'limit'} if $args->{'limit'};
    $params->{NextToken}          = $args->{'next'}  if $args->{'next'};
    my $res = $self->request('ListDomains', $params);
    return
      Amazon::SimpleDB::Response->new(
                                      {
                                       http_response => $res,
                                       account       => $self
                                      }
      );
}

sub domain {
    return Amazon::SimpleDB::Domain->new({name => $_[1], account => $_[0]});
}

sub create_domain {    # note no more than 100 per account.
    my ($self, $name) = @_;
    my $res = $self->request('CreateDomain', {DomainName => $name});
    return
      Amazon::SimpleDB::Response->new(
                                      {
                                       http_response => $res,
                                       account       => $self
                                      }
      );
}

sub delete_domain {
    my ($self, $name) = @_;
    my $res = $self->request('DeleteDomain', {DomainName => $name});
    return
      Amazon::SimpleDB::Response->new(
                                      {
                                       http_response => $res,
                                       account       => $self
                                      }
      );
}

#--- utility methods

sub request {    # returns "raw" HTTP Response from SimpleDB
    my ($self, $action, $params) = @_;
    croak "No Action parameter" unless $action;
    $params ||= {};
    $params->{Action}           = $action;
    $params->{AWSAccessKeyId}   = $self->{aws_access_key_id};
    $params->{Version}          = '2007-11-07';
    $params->{SignatureVersion} = 1 unless defined $params->{SignatureVersion};
    $params->{Timestamp}        = timestamp() unless $params->{Expires};
    my $time = $params->{Expires} || $params->{Timestamp};
    my $sig = '';
    if ($params->{SignatureVersion} == 1) {
        $sig .= $_ . $params->{$_}
          for (sort { lc($a) cmp lc($b) } keys %$params)
          ;    # Must be alphabetical in a case-insensitive manner.
    } else {
        $sig = $params->{Action} . $time;
    }
    my $hash = Digest::HMAC_SHA1->new($self->{aws_secret_access_key});
    $hash->add($sig);
    $params->{Signature} = encode_base64($hash->digest, '');
    my $uri = URI->new(SERVICE_URI);
    $uri->query_form($params);
    return $self->{agent}->get($uri->as_string);
}

sub timestamp {
    my $t = shift;
    $t = time unless defined $t;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
      gmtime($t);
    return
      sprintf("%4i-%02i-%02iT%02i:%02i:%02iZ",
              ($year + 1900),
              ($mon + 1),
              $mday, $hour, $min, $sec);
}

1;

__END__

=head1 NAME

Amazon::SimpleDB - a low-level perlish interface for
working with Amazon's SimpleDB service.

=head1 DESCRIPTION

B<This is code is in the early stages of development. Do not
consider it stable. Feedback and patches welcome.>

Amazon::SimpleDB provides a "low-level" perlish interface for
working with Amazon's SimpleDB (SMB) service. 

"Amazon SimpleDB is a web service for running queries on
structured data in real time. This service works in close
conjunction with Amazon Simple Storage Service (Amazon S3)
and Amazon Elastic Compute Cloud (Amazon EC2), collectively
providing the ability to store, process and query data sets
in the cloud. These services are designed to make web-scale
computing easier and more cost-effective for developers."

To sign up for an Amazon Web Services account, required to
use this library and the SimpleDB service, please visit the
Amazon Web Services web site at http://www.amazonaws.com/.

You will be billed accordingly by Amazon when you use this
module and must be responsible for these costs.

To learn more about Amazon's SimpleDB service, please visit:
http://simpledb.amazonaws.com/.

=head1 METHODS

=head2 Amazon::SimpleDB->new($args)

=head2 Amazon::SimpleDB->domains

=head2 $sdb->domain($name)

=head2 $sdb->create_domain($name)

=head2 $sdb->delete_domain($name)

=head2 $sdb->request($action,[\%args])

=head2 timestamp([$epoch])

=head1 TO DO

=over

=item Development of a proper test suite. Currently this
module is only testing that the code compiles. This priority
one.

=item Support the use of HTTP POST. Right now the module
only uses GET for everything. The SimpleDB is sadly GETsful
and not really REST.

=item Support retries of the SimpleDB service is a server
error (HTTP 5xx status) is returned before giving.

=item Implement a C<query_all> method that will
automatically issue multiple calls to the service if a
NextToken is returned.

=back

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Amazon-SimpleDB>

For other issues, contact the author.

=head1 AUTHOR

Timothy Appnel <tima@cpan.org>

=head1 SEE ALSO

L<Amazon::S3>

=head1 COPYRIGHT AND LICENCE

The software is released under the Artistic License. The
terms of the Artistic License are described at
http://www.perl.com/language/misc/Artistic.html. Except
where otherwise noted, Amazon::SimpleDB is Copyright 2008,
Timothy Appnel, tima@cpan.org. All rights reserved.
