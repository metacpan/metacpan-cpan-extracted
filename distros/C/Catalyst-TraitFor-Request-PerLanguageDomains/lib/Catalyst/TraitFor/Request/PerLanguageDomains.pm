package Catalyst::TraitFor::Request::PerLanguageDomains;

use 5.008005;
use Moose::Role;
use I18N::AcceptLanguage;
use Moose::Autobox;
use MooseX::Types -declare => [qw/ ValidConfig /];
use MooseX::Types::Moose qw/ ArrayRef /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Structured qw/ Dict /;
use namespace::autoclean;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

requires qw/
    uri
    _context
    headers
/;

has language => (
    init_arg => undef,
    is => 'ro',
    lazy => 1,
    builder => '_build_language',
);

subtype ValidConfig,
    as Dict[
        default_language => NonEmptySimpleStr,
        selectable_language => ArrayRef([NonEmptySimpleStr])|NonEmptySimpleStr,
    ];

has _perlang_config => (
    init_arg => undef, traits => ['Hash'],
    is => 'ro',
    isa => ValidConfig,
    lazy => 1, builder => '_build_perlang_config',
    handles => {
        map { q[_] . $_ => [ get => $_ ] } 
            qw/default_language selectable_language/
    },
);

sub _build_perlang_config {
    ref(shift->_context)->config->{'TraitFor::Request::PerLanguageDomains'};
}

sub _build_language {
    my $self    = shift;

    my $i18n_accept_language = I18N::AcceptLanguage->new(
        defaultLanguage => $self->_default_language
    );

    my $from_host = sub { (($self->uri->host =~ m{^(\w{2})\.}) ? $1 : undef) };
    my $from_session = sub {
        my $ctx = $self->_context;
        if ( my $session_meth = $ctx->can('session') ) {
            $session_meth->($ctx)->{'language'};
        }
    };
    my $from_header = sub { $self->headers->header('Accept-language') };

    return $i18n_accept_language->accepts(
        $from_host->() || $from_session->() || $from_header->(),
        [ $self->_selectable_language->flatten ]
    );
}

=pod

=head1 NAME

Catalyst::TraitFor::Request::PerLanguageDomains - Language detection for Catalyst::Requests

=head1 SYNOPSIS

    package MyApp;

    use Moose;
    use namespace::autoclean;

    use Catalyst;
    use CatalystX::RoleApplicator;

    extends 'Catalyst';

    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::PerLanguageDomains
    /);

    __PACKAGE__->config(
        'TraitFor::Request::PerLanguageDomains' => {
            default_language => 'de',
            selectable_language => ['de','en'],
        }
    );

    __PACKAGE__->setup;

    # Config::General style:
    <TraitFor::Request::PerLanguageDomains>
        default_language de
        selectable_language de
        selectable_language en
    </Catalyst::Request>

=head1 DESCRIPTION

Extends L<Catalyst::Request> objects with a C<< $ctx->request->language >>
method for language detection.

=head1 METHODS

=head2 language

    my $language = $ctx->request->language;

Returns a string that is the two digit code ISO for the request language.

The following things are checked to find the request language, in order:

=over

=item *

The lang part of the domain (e.g. de from de.example.org)

=item *

The C<language> key set in the session (if L<Catalyst::Plugin::Session> is loaded)

=item *

The C<Accept-Language> header of the request.

=back

=head1 SEE ALSO

L<CatalystX::RoleApplicator>, L<I18N::AcceptLanguage>.

=head1 AUTHOR

  Stephan Jauernick <stephan@stejau.de>

=head1 LICENSE

This software is copyright (c) 2009 by Stephan Jauernick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
