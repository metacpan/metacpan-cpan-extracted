#!/bin/false
# PODNAME: BZ::Client::Test
# ABSTRACT: Module for writing integration tests

use strict;
use warnings 'all';

package BZ::Client::Test;

use BZ::Client;

sub new {
    my $class = shift;
    my $self;
    if (@_ == 1) {
        my $files = shift;
        for my $f (@$files) {
            if (-f $f) {
                my $hash;
                eval {
                    $hash = do $f;
                };
                if ($@) {
                    die "Failed to load configuration file $f: $@";
                }
                die "Configuration file $f didn't return a HASH value."
                    unless ($hash and ref($hash) eq 'HASH');
                # Create a copy of $hash
                $self = \%{ $hash };
            }
        }
        # If no file was found, $self becomes and emtpy hashref
        $self = {} unless ref($self) eq 'HASH';
    }
    else {
        $self = { @_ };
    }
    bless($self, ref($class) || $class);
    return $self
}

sub testUrl {
    my $self = shift;
    if (@_) {
        $self->{'testUrl'} = shift;
    }
    else {
        return $self->{'testUrl'};
    }
}

sub testUser {
    my $self = shift;
    if (@_) {
        $self->{'testUser'} = shift;
    }
    else {
        return $self->{'testUser'};
    }
}

sub testPassword {
    my $self = shift;
    if (@_) {
        $self->{'testPassword'} = shift;
    }
    else {
        return $self->{'testPassword'};
    }
}

sub testApiKey {
    my $self = shift;
    if (@_) {
        $self->{'testApiKey'} = shift;
    }
    else {
        return $self->{'testApiKey'};
    }
}

sub logDirectory {
    my $self = shift;
    if (@_) {
        $self->{'logDirectory'} = shift;
    }
    else {
        return $self->{'logDirectory'};
    }
}

sub client {
    my $self = shift;
    if ($self->isSkippingIntegrationTests()) {
        die 'Unable to create a client, as integration tests are being skipped.';
    }
    return BZ::Client->new(
                    url  => $self->testUrl(),
         (defined $self->{'autologin'} ? +( autologin => $self->{'autologin'} )
                                       : ()),
                    ($self->testUser() ? +(user  => $self->testUser(),
                                           password  => $self->testPassword())
                                       : ()),
                    ($self->testApiKey() ? +(api_key  => $self->testApiKey())
                                         : ()),
                    logDirectory  => $self->logDirectory())
}

sub isSkippingIntegrationTests {
    my $self = shift;
    return !defined($self->testUrl())
}

1;

__END__

=pod

=encoding utf8

=head1 SYNOPSIS

  # Create a new instance, reading configuration from either of
  # the given files.
  my $tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);
  my $skipping = $tester->isSkippingIntegrationTests();
  if ($skipping) {
    # Skip integration tests
  }
  else {
    my $client = $tester->client();
    # Run the tests, using the given client.
  }

=head1 CLASS METHODS

This section lists the class methods.

=head2 new

  # Create a new instance, reading configuration from either of
  # the given files.
  my $tester = BZ::Client::Test->new(['config.pl', 't/config.pl']);

  # Create a new instance, providing configuration explicitly.
  my $tester = BZ::Client::Test->new(
                                'testUrl'      => $url,
                                'testUser'     => $user,
                                'testPassword' => $password);

Creates a new instance with a configuration for running integration
tests. The configuration can be read from a config file or be
provided explicitly.

=head1 INSTANCE METHODS

This section lists the instance methods.

=head2 isSkippingIntegrationTests

  my $skipping = $tester->isSkippingIntegrationTests();

Returns, whether the tester is configured to skip integration
tests. This is the case, if the method L</testUrl> returns a
an undefined value.

=head2 testUrl

  my $url = $tester->testUrl();
  $tester->testUrl( $url );

Gets or sets the Bugzilla servers URL. This is also used to
determine, whether the tester is able to run integration tests
or not: If the URL is undefined, then integration tests will
be skipped.

=head2 testUser

  my $user = $tester->testUser();
  $tester->testUser( $user );

Gets or sets the Bugzilla servers user.

=head2 testPassword

  my $password = $tester->testPassword();
  $tester->testPassword( $password );

Gets or sets the Bugzilla servers password.

=head2 client

  my $client = $tester->client();

Creates an instance of BZ::Client, using the testers configuration.
An exception is thrown, if the tester is unable to create a client
object, because integration tests are being skipped.


=head1 SEE ALSO

L<BZ::Client>

