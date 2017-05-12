package Bot::Backbone::Service::Ticket::Tracker::FogBugz;
$Bot::Backbone::Service::Ticket::Tracker::FogBugz::VERSION = '0.160490';
use Moose;

with qw( Bot::Backbone::Service::Ticket::Tracker );

use DOM::Tiny;
use WebService::FogBugz;

# ABSTRACT: ticket tracker lookups for FogBugz


has config   => ( is => 'ro' );
has base_url => ( is => 'ro' );
has token    => ( is => 'ro' );
has email    => ( is => 'ro' );
has password => ( is => 'ro' );


sub lookup_issue {
    my ($self, $number) = @_;

    my $fb = WebService::FogBugz->new(
        config   => $self->config,
        base_url => $self->base_url,
        token    => $self->token,
        email    => $self->email,
        password => $self->password,
    );

    my $case = $fb->request_method('search', {
        q    => $number,
        cols => 'sTitle',
    });
    my $dom = DOM::Tiny->new($case);

    return unless $dom;

    my $summary = $dom->at("case[ixBug=$number] sTitle")->text,

    return {
        issue   => $number,
        summary => $dom->at("case[ixBug=$number] sTitle")->text,
    };
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::Ticket::Tracker::FogBugz - ticket tracker lookups for FogBugz

=head1 VERSION

version 0.160490

=head1 SYNOPSIS

    service fogbugz_tickets => (
        service  => 'Ticket',
        trackers => [{
            type       => 'FogBugz',

            # use an external configuration
            config     => 'fbrc',

            # mandatory without config to specify the base URL
            base_url   => 'http://company.fogbugz.com/api.asp',

            # use token auth without config
            token      => 'secrettoken',

            # or use username/password auth without config
            email      => 'botuser@example.com',
            password   => 'secret',

            # And formatting and matching config...
            title      => 'Case %{issue}s: %{summary}s',
            link       => 'https://company.fogbugz.com/f/cases/%{issue}s',
            patterns   => [
                qr{(?<!/)\bbugzid:(?<issue>\d+)\b},
                qr{(?<![\[])\b(?<schema>https:)//company\.fogbugz\.com/f/cases/(?<issue>\d+)\b},
            ],
        }],
    );

=head1 DESCRIPTION

This works with L<Bot::Backbone::SErvice::Ticket> to perform FogBugz ticket lookups and summaries.

=head1 ATTRIBUTE

=head2 config

This will set the C<config> in L<WebService::FogBugz>.

=head2 base_url

This is the base URL of your FogBugz host instance. This is required when L</config> is not set.

=head2 token

This is required unless L</email> and L</password> are used. This is the authorization token to use when contacting the FogBugz web API.

=head2 email

This is required unless L</token> is used. This is the email to use for authentication.

=head2 password

This is required unless L</token> is used. This is the password to use for authentication.

=head1 METHODS

=head2 lookup_issue

This is a vere simple lookup that will grab the case metadata and return the title summary.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
