package CPAN::Testers::WWW::Reports::Query::Report;

use strict;
use warnings;

our $VERSION = '0.05';
 
#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::WWW::Reports::Query::Report - Retrieve CPAN Testers report direct from the CPAN Testers website.

=head1 DESCRIPTION
 
This module queries the CPAN Testers website and retrieves a specific report.
 
=head1 SYNOPSIS

    # default options
    my %options = (
        as_json => 0,                       # the default
        as_hash => 0,                       # the default
        host    => 'http://cpantesters.org' # the default
    );

    # establish the object
    my $query = CPAN::Testers::WWW::Reports::Query::Report->new( %options );

The default is to return a Metabase::Fact, as a CPAN::Testers::Report object. 
If you wish to manipulate this differently, use the as_json or as_hash to 
return more simplified forms.

    # get by id
    my $result = $query->report( report => 40000000 );

    # get by GUID
    $result = $query->report( report => '0b3fd09a-7e50-11e3-9609-5744ee331862' );

    # force return as JSON
    my $result = $query->report( report => 40000000, as_json => 1 );

    # force return as a hash
    my $result = $query->report( report => 40000000, as_hash => 1 );

The as_json and as_hash options here will override the general options 
supplied in the object constructor. If you've specified as_json or as_hash in 
the object constructor, to override simply set 'as_json => 0' and/or 
'as_hash => 0' in the method call.

    # get the last error
    my $error = $query->error;

If the result is returned as undef, either no report was found or the JSON
return is malformed. This could be due to network connection, or corrupt data
in the report. If the latter please notify the CPAN Testers discussion list,
so we can investigate and correct as appropriate.

=cut
 
#----------------------------------------------------------------------------
# Library Modules

use CPAN::Testers::Report;
use JSON::XS;
use WWW::Mechanize;

#----------------------------------------------------------------------------
# Variables

my $HOST = 'http://www.cpantesters.org';
my $PATH = '%s/cpan/report/%s?json=1';

my $mech = WWW::Mechanize->new();
$mech->agent_alias( 'Linux Mozilla' );

# -------------------------------------
# Program

sub new {
    my($class, %hash) = @_;
    my $self = {};
    
    $self->{as_json} = $hash{as_json}   || 0;
    $self->{as_hash} = $hash{as_hash}   || 0;
    $self->{host}    = $hash{host}      || $HOST;

    bless $self, $class;

    return $self;
}

sub report {
    my $self    = shift;
    my %hash    = @_;
    
    $self->{error} = '';

    my $url = sprintf $PATH, $self->{host}, $hash{report};
	eval { $mech->get( $url ); };
    if($@ || !$mech->success()) {
        $self->{error} = "No response from server: $@";
        return;
    }

    $self->{content} = $mech->content;
    unless($self->{content}) {
        $self->{error} = 'no data returned by the server';
        return;
    }

    my $data;
    eval {
        $data = decode_json($self->{content});
    };

    if($@ || !$data) {
        $self->{error} = "JSON decoding error: " . ($@ || 'no data returned');
        return;
    }

    unless($data->{success}) {
        $self->{error} = "no report found";
        return;
    }

    my $as = ($hash{as_json} || (!defined $hash{as_json} && $self->{as_json})) ? 'json' : '';
    $as  ||= ($hash{as_hash} || (!defined $hash{as_hash} && $self->{as_hash})) ? 'hash' : 'fact';

    return encode_json($data->{result}) if($as eq 'json');
    return $data->{result}              if($as eq 'hash');

    return $self->_parse($data->{result});
}

sub _parse {
    my ($self,$data) = @_;
    my $hash;

    if(!$data) {
        $self->{error} = 'no data returned';
        return;
    }

    for my $content (@{ $data->{content} }) {
        $content->{content} = encode_json($content->{content});
    }
    $data->{content} = encode_json($data->{content});

    my $fact = CPAN::Testers::Report->from_struct( $data ) ;
    return $fact;

    $self->{hash} = $data;
    return $data;
}

sub content {
    my $self    = shift;
    return $self->{content};
}

sub error {
    my $self    = shift;
    return $self->{error};
}

q("With thanks to the 2014 QA Hackathon");

__END__

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::WWW::Testers::Reports::Query::Report. Can take
options to define whether a hash or json is required on return.

=back

=head2 Search Methods

=over 4

=item * report

For the given id or GUID, returns a hash or JSON describing the specified test 
report.

=back

=head2 Data Methods

=over 4

=item * content

Returns the current server textual response. Useful for debugging.

=item * error

Returns the last recorded error.

=back

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN::Testers::WWW::Reports::Query::Report

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>,
L<CPAN::Testers::WWW::Reports>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

Initially written during the 2014 QA Hackathon in Lyon.

=head1 CPAN TESTERS FUND

CPAN Testers wouldn't exist without the help and support of the Perl 
community. However, since 2008 CPAN Testers has grown far beyond the 
expectations of it's original creators. As a consequence it now requires
considerable funding to help support the infrastructure.

In early 2012 the Enlightened Perl Organisation very kindly set-up a
CPAN Testers Fund within their donatation structure, to help the project
cover the costs of servers and services.

If you would like to donate to the CPAN Testers Fund, please follow the link
below to the Enlightened Perl Organisation's donation site.

L<https://members.enlightenedperl.org/drupal/donate-cpan-testers>

If your company would like to support us, you can donate financially via the
fund link above, or if you have servers or services that we might use, please
send an email to admin@cpantesters.org with details.

Our full list of current sponsors can be found at our I <3 CPAN Testers site.

L<http://iheart.cpantesters.org>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2014-2016 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
