package CPAN::Testers::Reports::Query::JSON;

use Moose;
use namespace::autoclean;

use version;
use LWP::Simple;
use CPAN::Testers::WWW::Reports::Parser;
use CPAN::Testers::Reports::Query::JSON::Set;

our $VERSION = '0.04';

has distribution    => ( isa => 'Str', is => 'ro', required   => 1 );
has version         => ( isa => 'Str', is => 'rw' );
has current_version => ( isa => 'Str', is => 'ro', lazy_build => 1 );
has versions => ( isa => 'ArrayRef[Str]', is => 'ro', lazy_build => 1 );
has report => (
    is         => 'rw',
    lazy_build => 1,
    isa        => 'ArrayRef[CPAN::Testers::WWW::Reports::Report]',
);

sub _build_current_version {
    my $self = shift;
    return $self->versions()->[0];
}

sub _build_report {
    my $self = shift;

    my $data = $self->_raw_json();

    my $obj = CPAN::Testers::WWW::Reports::Parser->new(
        format  => 'JSON',
        data    => $data,
        objects => 1,
    );

    my @results;
    while ( my $data = $obj->report() ) {
        next unless $data->csspatch() eq 'unp';
        push( @results, $data );
    }
    return \@results;
}

sub _build_versions {
    my $self   = shift;
    my $report = $self->report();

    my %versions;
    foreach my $data ( @{$report} ) {
        my $this_version = version->new( $data->version() );
        $versions{ $this_version->stringify } = 1;
    }
    my @vers = reverse sort keys %versions;
    return \@vers;
}

=head1 NAME
 
  CPAN::Testers::Reports::Query::JSON - Find out about a distributions cpantesters results
  
=head1 SYNOPSIS

    my $dist_query = CPAN::Testers::Reports::Query::JSON->new(
        {   distribution => 'Data::Pageset',
            version => '1.01',    # optional, will default to latest version
        }
    );

    print "Processing version: " . $dist_query->version() . "\n";
    print "Other versions are: " . join(" ", @{$dist_query->versions()}) . "\n";

    my $all = $dist_query->all();
    printf "There were %s tests, %s passed, %s failed - e.g. %s percent",
        $all->total_tests(),
        $all->number_passed(),
        $all->number_failed(),
        $all->percent_passed();

    my $win32_only = $dist_query->win32_only();
    printf "There were %s windows tests, %s passed, %s failed - e.g. %s percent",
        $win32_only->total_tests(),
        $win32_only->number_passed(),
        $win32_only->number_failed(),
        $win32_only->percent_passed();

    my $non_win32 = $dist_query->non_win32();
    printf "There were %s windows tests, %s passed, %s failed - e.g. %s percent",
        $non_win32->total_tests(),
        $non_win32->number_passed(),
        $non_win32->number_failed(),
        $non_win32->percent_passed();
        
    # Get results for a specific OS
    my $specific_os = $dist_query->for_os('linux');
  
=head1 DESCRIPTION

This module queries the cpantesters website (via the JSON interface) and 
gets the test results back, it then parses these to answer a few simple questions.

This module only reports on versions of Perl which are unpatched.

=head2 all()

Get stats on all tests, returns a CPAN::Testers::Reports::Query::JSON::Set object.

=head2 win32_only()

Returns a CPAN::Testers::Reports::Query::JSON::Set object for win32 only
test results. 'MSWin32' and 'cygwin' are osnames.

=head2 non_win32()

Non windows, returns a CPAN::Testers::Reports::Query::JSON::Set object.

=head2 for_os()

  my $report = $dist_query->for_os('linux');
  
Returns a CPAN::Testers::Reports::Query::JSON::Set object for the
specified OS.

=head2 current_version()

  my $current_version = $query->current_version();

Returns the latest version available

=head1 AUTHOR
 
Leo Lapworth, LLAP@cuckoo.org
 
=head1 BUGS
 
None that I'm aware of - export may not encode correctly.
 
=head1 Repository (git)

http://github.com/ranguard/cpan-testers-reports-query-json,
git://github.com/ranguard/cpan-testers-reports-query-json.git
 
=head1 COPYRIGHT
 
Copyright (c) Leo Lapworth. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

sub all {
    my $self = shift;

    return $self->_create_set( { name => 'all', } );
}

sub win32_only {
    my $self = shift;

    return $self->_create_set(
        {   os_include_only => {
                'MSWin32' => 1,
                'cygwin'  => 1,
            },
            name => 'win32_only',
        }
    );

}

sub non_win32 {
    my $self = shift;

    return $self->_create_set(
        {   os_exclude => {
                'MSWin32' => 1,
                'cygwin'  => 1,
            },
            name => 'non_win32',
        }
    );

}

sub for_os {
    my ( $self, $os ) = @_;
    return $self->_create_set(
        {   os_include_only => { $os => 1, },
            name            => $os,
        }
    );
}

sub _create_set {
    my ( $self, $conf ) = @_;

    $conf ||= {};

    my @os_data;

    foreach my $data ( @{ $self->_get_data_for_version() } ) {

        # Only want non-patched Perl at the moment
        if ( $conf->{os_exclude} ) {
            next if $conf->{os_exclude}->{ $data->osname() };
        }
        if ( $conf->{os_include_only} ) {
            next unless $conf->{os_include_only}->{ $data->osname() };
        }
        push( @os_data, $data );
    }

    return CPAN::Testers::Reports::Query::JSON::Set->new(
        { data => \@os_data, name => $conf->{name} } );
}

sub _get_data_for_version {
    my $self    = shift;
    my $version = $self->version || $self->current_version;
    my $report  = $self->report();

    my @data = grep { $_->version() eq $version } @{$report};
    return \@data;
}

sub _json_url {
    my $self = shift;
    my $dist = $self->distribution();
    $dist =~ s/::/-/;
    my ($letter) = ( $dist =~ /(.{1})/ );

    return "http://www.cpantesters.org/distro/$letter/$dist.json";
}

sub _raw_json {
    my $self = shift;

    # Fetch from website - could have caching here
    return get( $self->_json_url() );
}

__PACKAGE__->meta->make_immutable;

1;
