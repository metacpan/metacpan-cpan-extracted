#!/usr/bin/perl -w
package Apache::Sling;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::Authn;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub new

sub new {
    my ( $class, $max_allowed_forks ) = @_;

    # control the maximum number of forks that can be
    # created when testing concurrency:
    $max_allowed_forks =
      ( defined $max_allowed_forks ? $max_allowed_forks : 32 );
    my $auth;
    my $authn;
    my $help;
    my $log;
    my $man;
    my $number_forks = 1;
    my $password;
    my $url;
    my $user;
    my $verbose;

    my $sling = {
        MaxForks => $max_allowed_forks,
        Auth     => $auth,
        Authn    => $authn,
        Help     => $help,
        Log      => $log,
        Man      => $man,
        Pass     => $password,
        Threads  => $number_forks,
        URL      => $url,
        User     => $user,
        Verbose  => $verbose
    };
    bless $sling, $class;
    return $sling;
}

#}}}

#{{{sub check_forks

sub check_forks {
    my ($sling) = @_;
    $sling->{'Threads'} = ( $sling->{'Threads'} || 1 );
    $sling->{'Threads'} =
      ( $sling->{'Threads'} =~ /^[0-9]+$/xms ? $sling->{'Threads'} : 1 );
    $sling->{'Threads'} =
      ( $sling->{'Threads'} < $sling->{'MaxForks'} ? $sling->{'Threads'} : 1 );
    return 1;
}

#}}}

1;
__END__

=head1 NAME

Apache::Sling - Perl library for interacting with the apache sling web framework

=head1 ABSTRACT

Top level Entry point to the Apache Sling libraries. Provides a basic
configuration for running the various Sling operations.

=head1 METHODS

=head2 new

Create, set up, and return a Sling object.

=head2 check_forks

Check number of forks to create complies with maximum number of forks
allowed.

=head1 USAGE

use Apache::Sling;

=head1 DESCRIPTION

The Apache::Sling perl library is designed to provide a perl based interface on
to the Apache sling web framework. 

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

1 on success.

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
