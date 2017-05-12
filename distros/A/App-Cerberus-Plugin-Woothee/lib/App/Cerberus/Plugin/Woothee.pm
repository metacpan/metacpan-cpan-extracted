package App::Cerberus::Plugin::Woothee;
{
  $App::Cerberus::Plugin::Woothee::VERSION = '0.01';
}

use strict;
use warnings;
use Woothee;
use parent 'App::Cerberus::Plugin';

#===================================
sub init {
#===================================
    my $self = shift;
    $self->{cache} = {};
}

#===================================
sub request {
#===================================
    my ( $self, $req, $response ) = @_;
    my $ua = $req->param('ua') or return;
    $response->{ua} = $self->{cache}{$ua} and return;

    my $detect = Woothee->parse($ua);

    # , category, ,,
    my %data   = (
        browser   => $detect->{'name'}   || '',
        vendor    => $detect->{'vendor'} || '';
        os        => $detect->{'os'}    || '',
        version   => {
            major => '',
            minor => '',
            full  => $detect->{'version'}    || ''
        },
        browser_properties => [ $detect->{'category'} ],
        is_robot  => $detect->{'category'} eq 'crawler',
    );

    if($data{'version'}{'full'} =~ m/^(\d+)\.(\d+)/) {
        $data{'version'}{'major'} = $1;
        $data{'version'}{'minor'} = $1;
    }

    $response->{ua} = $self->{cache}{$ua} = \%data;
}

1;

# ABSTRACT: Add user-agent information to App::Cerberus

__END__

=pod

=head1 NAME

App::Cerberus::Plugin::Woothee - Add user-agent information to App::Cerberus

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This plugin uses L<Woothee> to add information about the user agent
to Cerberus. For instance:

    "ua": {
        "is_robot": 0,
        "vendor": "apple",
        "version": {
            "minor": ".1",
            "full": 5.1,
            "major": "5"
        },
        "browser": "safari",
        "device": "iphone",
        "os": "iOS"
    }

=head1 REQUEST PARAMS

User-Agent information is returned when an User-Agent value is passed in:

    curl http://host:port/?ua=Mozilla%2F5.0 (compatible%3B Googlebot%2F2.1%3B %2Bhttp%3A%2F%2Fwww.google.com%2Fbot.html)

=head1 CONFIGURATION

This plugin takes no configuration options:

    plugins:
      - Woothee

=head1 KNOWN ISSUES

When invoked after any other User-Agent plugin, this one will overwrite
the results from the other plugins. It's planned to merge the ua properties
in a later version but this is yet to be implemented.

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
