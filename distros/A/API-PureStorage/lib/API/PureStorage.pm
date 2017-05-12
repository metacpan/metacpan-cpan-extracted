package API::PureStorage;

use Data::Dumper;
use REST::Client;
use JSON;
use Net::SSL;

use warnings;
use strict;

$API::PureStorage::VERSION = '0.03';

our %ENV;
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

my $debug = 0;

sub new {
    my $class = shift @_;
    my $self = {
        cookie_file => '/tmp/cookies.txt',
        host => $_[0],
        token => $_[1]
    };
    bless $self, $class;

    my $client = REST::Client->new( follow => 1 );
    $client->setHost('https://'.$self->{host});

    $client->addHeader('Content-Type', 'application/json');

    $client->getUseragent()->cookie_jar({ file => $self->{cookie_file} });
    $client->getUseragent()->ssl_opts(verify_hostname => 0);

    $self->{client} = $client;

    # Check API compatibility

    my @versions = $self->version();

    my %api_versions;
    for my $version (@versions) {
        $api_versions{$version}++;
    }

    my $api_version = $api_versions{'1.4'} ? '1.4' :
                      $api_versions{'1.3'} ? '1.3' :
                      $api_versions{'1.1'} ? '1.1' :
                      $api_versions{'1.0'} ? '1.0' :
                      undef;

    unless ( $api_version ) {
      die "API version 1.3 or 1.4 is not supported by host: $self->{host}\n";
    }

    $self->{api_version} = $api_version;

    ### Set the Session Cookie

    my $ret = $self->_api_post("/api/$api_version/auth/session", { api_token => $self->{token} });

    return $self;
}

sub DESTROY {
  my $self = shift @_;
  my $ret = $self->{client}->DELETE("/api/$self->{api_version}/auth/session") if defined $self->{api_version};
  unlink $self->{cookie_file};
}

### Methods

sub array_info {
    my $self = shift @_;
    my $ref = $self->_api_get("/api/$self->{api_version}/array?space=true");
    return wantarray ? @$ref : $ref;
}

sub volume_detail {
    my $self = shift @_;
    my $name = shift @_;
    my $ref = $self->_api_get("/api/$self->{api_version}/volume/".$name);
    return wantarray ? @$ref : $ref;
}

sub volume_info {
    my $self = shift @_;
    my $ref = $self->_api_get("/api/$self->{api_version}/volume?space=true");
    return wantarray ? @$ref : $ref;
}

sub version {
    my $self = shift @_;
    my $ref = $self->_api_get('/api/api_version');
    return wantarray ? @{$ref->{version}} : $ref->{version};
}

### Subs

sub _api_get {
    my $self = shift @_;
    my $url = shift @_;
    my $ret = $self->{client}->GET($url);
    my $num = $ret->responseCode();
    my $con = $ret->responseContent();
    if ( $num == 500 ) {
        die "API returned error 500 for '$url' - $con\n";
    }
    if ( $num != 200 ) {
        die "API returned code $num for URL '$url'\n";
    }
    print 'DEBUG: GET ', $url, ' -> ', $num, ":\n", Dumper(from_json($con)), "\n" if $debug;
    return from_json($con);
}

sub _api_post {
    my $self = shift @_;
    my $url = shift @_;
    my $data = shift @_;
    my $ret = $self->{client}->POST($url, to_json($data));
    my $num = $ret->responseCode();
    my $con = $ret->responseContent();
    if ( $num == 500 ) {
        die "API returned error 500 for '$url' - $con\n";
    }
    if ( $num != 200 ) {
        die "API returned code $num for URL '$url'\n";
    }
    print 'DEBUG: POST ', $url, ' -> ', $num, ":\n", Dumper(from_json($con)), "\n" if $debug;
    return from_json($con);
}

1;
__END__
=head1 NAME

API::PureStorage - Interacting with Pure Storage devices

=head1 SYNOPSIS

  my $pure = new API::PureStorage ($host, $api_token);

  my $info = $pure->array_info();
  my $percent = sprintf('%0.2f', (100 * $info->{total} / $info->{capacity}));

  print "The array $host is currently $percent full\n";

  print "\nVolumes on host $host:\n";

  my $vol_info = $pure->volume_info();
  for my $vol (sort { lc($a->{name}) cmp lc($b->{name}) } @$vol_info) {
    my $detail = $pure->volume_detail($vol->{name});
    print join("\t", $detail->{name}, $detail->{serial}, $detail->{created}), "\n";
  }

=head1 DESCRIPTION

This module is a wrapper around the Pure Storage API for their devices.

It currently supports API v1.4 and earlier. It supports a limited set of
the available API commands: basic reading of volume and array information.

=head1 METHODS

=head2 array_info()

    my %volume_info = $pure->volume_info()
    my $volume_info_ref = $pure->volume_info()

Returns a hash or hasref (depending on requested context) of general array
information, including space usage.

=head3 Hash data reference:

* hostname - the configured hostname of the system

* total_reduction - The current overall data reduction multiple of the array. IE: A "2" here means "2:1" reduction.

* data_reduction - The reduction multiple of just data partitions.

Array-wide space usage info:

* volumes - bytes in use by active volume data

* shared_space - bytes recognized in use between multiple copies, volumes, snapshots, etc

* snapshots - bytes in use by snapshots

* system - bytes in use by system overhead. This can include recently allocated bytes
that have yet to be accounted for in other categories. IE: a recently deleted volume
that has yet to garbage collect.

* total - a byte count of all data on the system.

* capacity - the total capacity of the array in bytes

* thin_provisioning - ?

NB: To calculate the percentage usage of whole array, divide total by capacity.

=head2 volume_info()

    my @volume_info = $pure->volume_info();
    my $volume_info_ref = $pure->volume_info();

Returns an array or arrayref of general information about volumes include space
usage.

Each element of the array is a hash reference, representing a single volume.

=head3 Hash data reference:

* name - the name of this volume

* data_reduction - Reduction multiple of the data on this volume

* total_reduction - overall reduction multiple of this volume

Volume space usage info:

* shared_space - bytes recognized in use between multiple copies, snapshots, etc

* snapshots - bytes in use by snapshots

* system - bytes in use by system overhead

* total - a byte count of all data used by the the volume

* size - the max size of the volume

* thin_provisioning - ?

NB: To calculate the percentage usage of the volume, divide total by size.

=head2 volume_detail($volume_name)

    my %volume_detail = $pure->volume_detail($volume_name);
    my $volume_detail_ref = $pure->volume_detail($volume_name);

Returns a hash or hasref (depending on requested context) of additional
information on the volumes now shown in the vol_info() summary.

=head3 Hash data reference:

* created - A time stamp from when the volume was created
* name - the name of the volume
* serial - the serial number of the volume
* size - Size of the volume in bytes
* source - the source of this volume if it was cloned from a snapshot or other volume

=head2 version()

    my @versions = $pure->version();
    my $versions_ref = $pure->version();

Returns an array/arrayref of API versions supported by the storage array.

=head1 SEE ALSO

    http://www.purestorage.com/

=head1 REQUESTS

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=API-PureStorage

	Source hosting: http://www.github.com/bennie/perl-API-PureStorage
	
=head1 VERSION

	API::PureStorage v0.03 (2016/07/01)

=head1 COPYRIGHT

	(c) 2015-2016, Phillip Pollard <bennie@cpan.org>
    Published with permission of Pure Storage, Inc.

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of
which is included in the LICENSE file of this distribution. It may also be
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORSHIP

Authored by Phillip Pollard.

=cut
