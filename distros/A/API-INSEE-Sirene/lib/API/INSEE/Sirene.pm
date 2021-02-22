package API::INSEE::Sirene;

use strict;
use warnings;

use Carp 'croak';
use JSON;
use HTTP::Request::Common qw/ GET POST /;
use HTTP::Status ':constants';
use List::Util 'any';
use LWP::UserAgent;
use POSIX 'strftime';
use Switch;

use Data::Dumper;

our $VERSION = 4.02;

use constant {
    API_AUTH_URL        => 'https://api.insee.fr/token',
    API_BASE_URL        => 'https://api.insee.fr/entreprises/sirene/V3',
    DEFAULT_MAX_RESULTS => 20, # from documentation
    DEFAULT_TIMEOUT     => 20,
    HARD_MAX_RESULTS    => 1_000, # from documentation
    MAX_SIREN_LENGHT    => 9,
    MAX_SIRET_LENGHT    => 14,
    MIN_LENGHT          => 3,
};

my $EMPTY = q//;

my $historized_fields = {
    siren => [ qw/
        dateFin dateDebut
        etatAdministratifUniteLegale changementEtatAdministratifUniteLegale
        nomUniteLegale changementNomUniteLegale nomUsageUniteLegale changementNomUsageUniteLegale
        denominationUniteLegale changementDenominationUniteLegale denominationUsuelle1UniteLegale
        denominationUsuelle2UniteLegale denominationUsuelle3UniteLegale changementDenominationUsuelleUniteLegale
        categorieJuridiqueUniteLegale changementCategorieJuridiqueUniteLegale activitePrincipaleUniteLegale
        nomenclatureActivitePrincipaleUniteLegale changementActivitePrincipaleUniteLegale nicSiegeUniteLegale
        changementNicSiegeUniteLegale economieSocialeSolidaireUniteLegale changementEconomieSocialeSolidaireUniteLegale
        caractereEmployeurUniteLegale changementCaractereEmployeurUniteLegale
    / ],
    siret => [ qw/
        etatAdministratifEtablissement changementEtatAdministratifEtablissement
        enseigne1Etablissement enseigne2Etablissement enseigne3Etablissement changementEnseigneEtablissement
        denominationUsuelleEtablissement changementDenominationUsuelleEtablissement
        activitePrincipaleEtablissement nomenclatureActivitePrincipaleEtablissement changementActivitePrincipaleEtablissement
        caractereEmployeurEtablissement changementCaractereEmployeurEtablissement
    / ],
};

my $useful_fields_legal_unit = [
    qw/
        siren
        dateCreationUniteLegale
        sigleUniteLegale
        categorieEntreprise
        denominationUniteLegale denominationUsuelle1UniteLegale nomUniteLegale
        categorieJuridiqueUniteLegale
        activitePrincipaleUniteLegale nomenclatureActivitePrincipaleUniteLegale
        nicSiegeUniteLegale
    /
];

my $useful_fields_establishment = [
    qw/
        siren siret
        denominationUsuelleEtablissement denominationUniteLegale denominationUsuelle1UniteLegale nomUniteLegale
        activitePrincipaleUniteLegale
        numeroVoieEtablissement typeVoieEtablissement libelleVoieEtablissement
        codePostalEtablissement libelleCommuneEtablissement
    /
];

my $useful_fields_aliases = {
    nicSiege                        => 'nicSiegeUniteLegale',
    nom                             => [ 'denominationUniteLegale', 'nomUniteLegale' ],
    dateCreation                    => 'dateCreationUniteLegale',
    sigle                           => 'sigleUniteLegale',
    categorieJuridique              => 'categorieJuridiqueUniteLegale',
    nomenclatureActivitePrincipale  => 'nomenclatureActivitePrincipaleUniteLegale',
    activitePrincipale              => 'activitePrincipaleUniteLegale',
    numvoie                         => 'numeroVoieEtablissement',
    typevoie                        => 'typeVoieEtablissement',
    nomvoie                         => 'libelleVoieEtablissement',
    codePostal                      => 'codePostalEtablissement',
    nomCommune                      => 'libelleCommuneEtablissement',
    adresseComplete                 => [
                                        'numeroVoieEtablissement',
                                        'typeVoieEtablissement', 'libelleVoieEtablissement',
                                        'codePostalEtablissement', 'libelleCommuneEtablissement'
                                    ],
};

sub new {
    my $class = shift;
    my ($credentials, $timeout, $max_results, $proxy) = @_;

    my $self = bless {
        credentials      => $credentials,
        user_agent       => undef,
        token_expiration => undef,
        max_results      => undef,
        debug_mode       => 0,
        current_endpoint => undef,
    }, $class;

    $self->_initUserAgent();
    $self->setProxy($proxy);
    $self->setMaxResults($max_results);
    $self->setTimeout($timeout);

    return $self;
}

sub setCredentials {
    my ($self, $credentials) = @_;

    $self->{'credentials'} = $credentials;
}

sub setMaxResults {
    my ($self, $max_results) = @_;

    $max_results //= DEFAULT_MAX_RESULTS;
    $self->{'max_results'} = $max_results > HARD_MAX_RESULTS ? HARD_MAX_RESULTS : $max_results;
}

sub setDebugMode {
    my ($self, $debug_value) = @_;

    $self->{'debug_mode'} = $debug_value;
}

sub setProxy {
    my ($self, $proxy) = @_;

    defined $proxy ? $self->{'user_agent'}->proxy([ 'http', 'https' ], $proxy) : $self->{'user_agent'}->env_proxy;
}

sub setTimeout {
    my ($self, $timeout) = @_;

    $timeout //= DEFAULT_TIMEOUT;
    $self->{'user_agent'}->timeout($timeout);
}

sub setCurrentEndpoint {
    my ($self, $endpoint) = @_;

    $self->{'current_endpoint'} = $endpoint;
}

sub _dumpRequest {
    my ($self, $request, $response) = @_;

    my $dump = sprintf "Sent request:\n%s\n", $request->as_string;
    $dump .= sprintf "Received response:\n%s\n", $response->as_string if defined $response;

    return $dump;
}

sub _initUserAgent {
    my $self = shift;

    $self->{'user_agent'} = LWP::UserAgent->new(protocols_allowed => [ 'http', 'https' ]);

    $self->{'user_agent'}->agent("Perl API::INSEE::Sirene V$VERSION");
    $self->{'user_agent'}->default_header('Accept' => 'application/json');
}

sub _getToken {
    my $self = shift;

    croak 'Please provide your credentials.' if !defined $self->{'credentials'};

    my $request = POST API_AUTH_URL,
        Authorization => "Basic $self->{'credentials'}",
        Content       => [ grant_type => 'client_credentials' ];

    my $response = $self->{'user_agent'}->request($request);
    my $json_obj = decode_json($response->content);

    switch ($response->code) {
        case HTTP_OK {
            $self->{'token_expiration'} = time + $json_obj->{'expires_in'};
            $self->{'user_agent'}->default_header( Authorization => "Bearer $json_obj->{'access_token'}" );
            return 0;
        }
        case HTTP_UNAUTHORIZED { # wrong credentials
            return 1 , $json_obj->{'error_description'};
        }
        else { # oh dear we are in trouble
            return 1, $self->_dumpRequest($request, $response);
        }
    }
}

sub _sendRequest {
    my ($self, $parameters) = @_;

    my $request;
    if (!exists $parameters->{'q'}) {
        my @url_parameters;

        foreach my $key (keys %{ $parameters }) {
            push @url_parameters, join '=', $key, $parameters->{$key};
        }

        my $endpoint = join '?', $self->{'current_endpoint'}, join '&', @url_parameters;
        $request = GET join '/', API_BASE_URL, $endpoint;
    }
    else {
        $request = POST join('/', API_BASE_URL, $self->{'current_endpoint'}),
            Content => [ %{ $parameters } ];
    }

    if ($self->{'debug_mode'}) { # Requests will not be sent in debug mode
        return 0, $self->_dumpRequest($request);
    }

    if (!defined $self->{'token_expiration'} || $self->{'token_expiration'} < time) {
        my ($err, $msg) = $self->_getToken();
        croak $msg if $err;
    }

    my $response = $self->{'user_agent'}->request($request);

    switch ($response->code) {
        case HTTP_OK
          || HTTP_NOT_FOUND {
            return 0, $response->content;
        }
        case HTTP_MOVED_PERMANENTLY { # duplicated legal unit/ establishment
            return 1, sprintf "%s\n%s", $response->message, $response->header('Location');
        }
        case HTTP_REQUEST_URI_TOO_LARGE
          || HTTP_TOO_MANY_REQUESTS
          || HTTP_UNAUTHORIZED
          || HTTP_FORBIDDEN
          || HTTP_SERVICE_UNAVAILABLE {
# There is no syntax error in request, the http message should be sufficient to understand the problem
            return 1, $response->message;
        }
        else { # case HTTP_BAD_REQUEST || HTTP_INTERNAL_SERVER_ERROR
            return 1, $self->_dumpRequest($request, $response);
        }
    }
}

sub _buildParameters {
    my ($self, $usefull_fields, $desired_fields, $criteria) = @_;

# Parameters names come from the documentation
    my $parameters = {
        date   => strftime('%Y-%m-%d', localtime),
        nombre => $self->{'max_results'},
    };
    $parameters->{'champs'} = $self->_buildFields($usefull_fields, $desired_fields) if (defined $desired_fields && $desired_fields ne 'all');
    $parameters->{'q'}      = sprintf('(%s)', $criteria) if defined $criteria;

    return $parameters;
}

sub _buildFields {
    my ($self, $usefull_fields, $desired_fields) = @_;

    if (defined $desired_fields) {
        return $self->_mapAliases($desired_fields);
    }
    else {
        return join ',', @{ $usefull_fields };
    }
}

sub _mapAliases {
    my ($self, $desired_fields) = @_;

    my @desired_fields = ref $desired_fields eq 'ARRAY' ? @{ $desired_fields } : $desired_fields;

    foreach my $desired_field (@desired_fields) {
        if (exists $useful_fields_aliases->{$desired_field}) {
            if (ref $useful_fields_aliases->{$desired_field} eq 'ARRAY') {
                $desired_field = join ',', @{ $useful_fields_aliases->{$desired_field} };
            }
            else {
                $desired_field = $useful_fields_aliases->{$desired_field};
            }
        }
    }

    return join ',', @desired_fields;
}

sub getCustomCriteria {
    my ($self, $field_name, $value, $search_mode) = @_;

    croak 'No endpoint specified.' if !defined $self->{'current_endpoint'};

    $search_mode //= 'aproximate';
    if (exists $useful_fields_aliases->{$field_name}) {
        if (ref $useful_fields_aliases->{$field_name} eq 'ARRAY') {
            croak "Can't use the alias $field_name in custom criteria";
        }
        $field_name = $useful_fields_aliases->{$field_name};
    }

    if ($search_mode eq 'aproximate') {
        my @criteria;
        my @words = split /[ \/-]/, $value;

        foreach my $word (@words) {
            $word =~ s/&/%26/ig;
            $word = sprintf '(%s:"%s"~ OR %s:*%s*)', $field_name, $word, $field_name, $word;
            $word = "periode$word" if any { $_ eq $field_name } @{ $historized_fields->{$self->{'current_endpoint'}} };


            push @criteria, $word;
        }

        return join ' AND ', @criteria;
    }

    my $criteria;
    $value =~ s/&/%26/ig;

    if ($search_mode eq 'exact') {
        $criteria = sprintf '%s:%s', $field_name, $value;
    }
    elsif ($search_mode eq 'begin') {
        $criteria = sprintf '%s:%s*', $field_name, $value;
    }

    $criteria = "periode($criteria)" if any { $_ eq $field_name } @{ $historized_fields->{$self->{'current_endpoint'}} };

    return $criteria;
}

sub searchByCustomCriteria {
    my ($self, $criteria, $desired_fields) = @_;

    my $parameters;
    switch ($self->{'current_endpoint'}) {
        case 'siren' { $parameters = $self->_buildParameters($useful_fields_legal_unit, $desired_fields, $criteria) }
        case 'siret' { $parameters = $self->_buildParameters($useful_fields_establishment, $desired_fields, $criteria) }
        else { croak 'Bad endpoint specified.' }
    }

    return $self->_sendRequest($parameters);
}

sub getLegalUnitBySIREN {
    my ($self, $siren_number, $desired_fields) = @_;

    return 1, "Invalid SIREN $siren_number -> Must be a ${ \MAX_SIREN_LENGHT } digits number."
        if $siren_number !~ m/^\d{${ \MAX_SIREN_LENGHT }}$/;

    $self->setCurrentEndpoint("siren/$siren_number");
    my $parameters = $self->_buildParameters($useful_fields_legal_unit, $desired_fields);

    return $self->_sendRequest($parameters);
}

sub searchLegalUnitBySIREN {
    my ($self, $siren_number, $desired_fields) = @_;

    return 1, "Invalid SIREN $siren_number -> Must be a ${ \MIN_LENGHT } digits min and ${ \MAX_SIREN_LENGHT } digits number max."
        if $siren_number !~ m/^\d{${ \MIN_LENGHT },${ \MAX_SIREN_LENGHT }}$/;

    $self->setCurrentEndpoint('siren');
    my $criteria = $self->getCustomCriteria('siren', $siren_number, 'begin');

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

sub getEstablishmentBySIRET {
    my ($self, $siret_number, $desired_fields) = @_;

    return 1, "Invalid SIRET $siret_number -> Must be a ${ \MAX_SIRET_LENGHT } digits number."
        if $siret_number !~ m/^\d{${ \MAX_SIRET_LENGHT }}$/;

    $self->setCurrentEndpoint("siret/$siret_number");
    my $parameters = $self->_buildParameters($useful_fields_establishment, $desired_fields);

    return $self->_sendRequest($parameters);
}

sub getEstablishmentsBySIREN {
    my ($self, $siren_number, $desired_fields) = @_;

    return (1, "Invalid SIREN $siren_number -> Must be a ${ \MAX_SIREN_LENGHT } digits number.")
        if $siren_number !~ m/^\d{${ \MAX_SIREN_LENGHT }}$/;

    $self->setCurrentEndpoint('siret');
    my $criteria = $self->getCustomCriteria('siren', $siren_number);

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

sub searchEstablishmentBySIRET {
    my ($self, $siret_number, $desired_fields) = @_;

    return 1, "Invalid SIRET $siret_number -> Must be a ${ \MIN_LENGHT } digits min and a ${ \MAX_SIRET_LENGHT } digits number max."
        if $siret_number !~ m/^\d{${ \MIN_LENGHT },${ \MAX_SIRET_LENGHT }}$/;

    $self->setCurrentEndpoint('siret');
    my $criteria = $self->getCustomCriteria('siret', $siret_number);

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

sub getLegalUnitsByName {
    my ($self, $name, $desired_fields) = @_;

    $self->setCurrentEndpoint('siren');
    my $criteria = $self->getCustomCriteria('denominationUniteLegale', $name);

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

sub getEstablishmentsByName {
    my ($self, $name, $desired_fields) = @_;

    $self->setCurrentEndpoint('siret');
    my $criteria = $self->getCustomCriteria('denominationUniteLegale', $name);

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

sub getLegalUnitsByUsualName {
    my ($self, $name, $desired_fields) = @_;


    $self->setCurrentEndpoint('siren');
    my $criteria = $self->getCustomCriteria('denominationUsuelle1UniteLegale', $name);

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

sub getEstablishmentsByUsualName {
    my ($self, $name, $desired_fields) = @_;

    $self->setCurrentEndpoint('siret');
    my $criteria = $self->getCustomCriteria('denominationUsuelle1UniteLegale', $name);

    return $self->searchByCustomCriteria($criteria, $desired_fields);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

API::INSEE::Sirene - An interface for the Sirene API of INSEE

=head1 VERSION

Version 4.02

=head1 SYNOPSIS

  use API::INSEE::Sirene;

  my $sirene = API::INSEE::Sirene->new('Y29uc3VtZXIta2V5OmNvbnN1bWVyLXNlY3JldA=='); # your base64 encoded credentials
  $sirene->setMaxResults(30);

  # Examples to get information about an establishment with SIRET number '12345678987654'
  $sirene->getEstablishmentBySIRET(12345678987654, 'all');

  # or
  my $fields_that_interest_me = ['numeroVoieEtablissement', 'typeVoieEtablissement', 'libelleVoieEtablissement',
                                 'codePostalEtablissement', 'libelleCommuneEtablissement'];
  $sirene->getEstablishmentBySIRET(12345678987654, $fields_that_interest_me);

  # or
  $sirene->getEstablishmentBySIRET(12345678987654, 'denominationUniteLegale');

  # or simply
  $sirene->getEstablishmentBySIRET(12345678987654);

  # you can also perform searches whith a partial SIREN/SIRET number using search functions:
  $sirene->searchEstablishmentBySIRET(1234567898);
  $sirene->searchLegalUnitBySIREN(123456);

=head1 DESCRIPTION

This module allows you to interact with the Sirene API of INSEE (Institut National de la Statistique et des Études Économiques) in France.

It contains a set of functions that can perform searches on INSEE's database to get some information about french companies like their SIREN number, company name, company headquarters address, etc.

The terms "enterprise", "legal unit" and "establishment" used in this documentation are defined at the INSEE website in the following pages:

=over 4

=item * B<Enterprise definition:>

L<< https://www.insee.fr/en/metadonnees/definition/c1496 >>

=item * B<Legal unit definition:>

L<< https://www.insee.fr/en/metadonnees/definition/c1044 >>

=item * B<Establishment definition:>

L<< https://www.insee.fr/en/metadonnees/definition/c1377 >>

=back

Here is the documentation with among others all fields names:

=over 4

=item *

L<< https://api.insee.fr/catalogue/site/themes/wso2/subthemes/insee/pages/item-info.jag?name=Sirene&version=V3&provider=insee >>

=back

B<Please note that this API is french so all fields names used in function calls are in french, including the aliases.>

This module has been tested with 3.9 INSEE API version.

=head1 DEPENDENCIES

=over 4

=item * L<< Carp|https://perldoc.perl.org/Carp >>

=item * L<< JSON|https://metacpan.org/pod/JSON >>

=item * L<< List::Util|https://perldoc.perl.org/List::Util >>

=item * L<< HTTP::Request::Common|https://metacpan.org/pod/HTTP::Request::Common >>

=item * L<< HTTP::Status|https://metacpan.org/pod/HTTP::Status >> B<< version < 6.26 >>

=item * L<< LWP::UserAgent|https://metacpan.org/pod/LWP::UserAgent >>

=item * L<< POSIX::strftime|https://metacpan.org/pod/POSIX#strftime >>

=item * L<< Switch|https://metacpan.org/pod/Switch >>

=back

=head1 CONSTANTS

=head2 DEFAULT_MAX_RESULTS

The API's default number of results for each request. You can override it with the C<< setMaxResults >> method. A too big value may impact response time and general performances.

This constant is set to 20 results.

=head2 DEFAULT_TIMEOUT

This constant specifies how many seconds the client module has to wait for server response before giving up. You can override it with the C<< setTimeout >> method.

This constant is set to 20 seconds.

=head2 HARD_MAX_RESULTS

The maximum number of results that you can get. This value can't be increased (restricted by API). If you try to send a request with a higher value, the C<nombre> parameter will be forced to HARD_MAX_RESULTS value.

This constant is set to 1000 results.

=head2 MAX_SIREN_LENGHT

A SIREN number has a maximum length of 9 digits.

=head2 MAX_SIRET_LENGHT

A SIREN number has a maximum length of 14 digits.

=head2 MIN_LENGHT

In order to avoid useless requests with too short SIREN/SIRET numbers, the module requires at least 3 digits to allow you performing a search.

=head1 METHODS

=head2 getCustomCriteria

You can use this method to build more specific criteria:

  my $criteria1 = $sirene->getCustomCriteria('numeroVoieEtablissement', 42);

You can choose between three search modes: 'exact', 'begin' or 'approximate' match. Default is 'approximate'.

  my $criteria2 = $sirene->getCustomCriteria('libelleVoieEtablissement', 'avenue', undef, 'exact');

B<< Important: >> You must specify the endpoint reached B<< before >> calling the C<< getCustomCriteria >> method using the C<< setCurrentEndpoint >>

  $sirene->setCurrentEndpoint('siret');

=head2 getEstablishmentsByName

Search all establishments matching the specified name. (denominationUniteLegale field)

=head2 getEstablishmentsBySIREN

Search all the establishments attached to a legal unit identified by a SIREN number.

=head2 getEstablishmentBySIRET

Search an establishment by its SIRET number.

=head2 getEstablishmentsByUsualName

Search all establishments matching the specified name. (denominationUsuelle1UniteLegale field)

=head2 getLegalUnitsByName

Search all legal units matching the specified name. (denominationUniteLegale field)

=head2 getLegalUnitsByUsualName

Search all legal units matching the specified name. (denominationUsuelle1UniteLegale field)

=head2 getLegalUnitBySIREN

Search a legal unit by its SIREN number.

=head2 searchByCustomCriteria

This method is used to perform a search with a custom criteria built using the C<< getCustomCriteria >> method.

Before using this method, you have to specify the targeted endpoint by calling the C<< setCurrentEndpoint >> method.

  my $final_criteria = "$criteria1 OR $criteria2";
  my ($err, $result) = $sirene->$sirene->searchByCustomCriteria($final_criteria);

=head2 searchEstablishmentBySIRET

Search all establishments which SIRET number is begining by the number given in parameter.

=head2 searchLegalUnitBySIREN

Search all legal units which SIREN number is begining by the number given in parameter.

=head2 setCredentials

You can set your credentials separately from the instantiation if you need to (but this must be done before any call to the search methods).

  $sirene->setCredentials('Y29uc3VtZXIta2V5OmNvbnN1bWVyLXNlY3JldA==');

=head2 setCurrentEndpoint

Used to specifie the reached API endpoint.

=head2 setDebugMode

Enables the debug mode. When enabled, all the requests built by the module are displayed instead of being sent.

  $sirene->setDebugMode(1);

=head2 setMaxResults

Used to override the B<< DEFAULT_MAX_RESULTS >> value to get more results, within the limit of B<< HARD_MAX_RESULTS >> value.

  $sirene->setMaxResults(30);

=head2 setProxy

You can define which proxy server must be used to send requests. The system's proxy settings are used by default.

  $sirene->setProxy('https://myproxy.com:1234');

=head2 setTimeout

Used to override the B<< DEFAULT_TIMEOUT >> value.

  $sirene->setTimeout(40);

=head1 PARAMETERS

All search methods take an optional C<< $desired_fields >> parameter that comes in three differents flavours:

  my $fields_that_interest_me = ['dateCreationUniteLegale', 'sigleUniteLegale'];
  my $response_json = $sirene->getLegalUnitBySIREN(123456789, $fields_that_interest_me);

  # or
  my $response_json = $sirene->getLegalUnitBySIREN(123456789, 'dateCreationUniteLegale');

  # or
  my $response_json = $sirene->getLegalUnitBySIREN(123456789, 'all');

When you don't specify any desired field, the module returns a selection of fields that are most likely to interest you. (see C<$useful_fields_legal_unit> and C<$useful_fields_establishment> in source code to find out which ones)

If you want all fields, you have to specify it explicitly by passing the value 'all' as parameter.

=head1 RETURN VALUES

Each method returns a list of two elements: a return code, which is 0 in case of success, or something else in case of failure; and the result of the request (some json or an error message). In case of problem when calling API (malformed request for example), the complete sent request and the response received with headers are returned in the error message.

The module may launch a croak if the crendentials are not initialized or if the SIREN/SIRET numbers are not given in a correct format.

=head1 ALIAS

Some fields have more user-friendly aliases:

  my $useful_fields_aliases = {
    nicSiege                        => 'nicSiegeUniteLegale',
    nom                             => [ 'denominationUniteLegale', 'nomUniteLegale' ],
    dateCreation                    => 'dateCreationUniteLegale',
    sigle                           => 'sigleUniteLegale',
    categorieJuridique              => 'categorieJuridiqueUniteLegale',
    nomenclatureActivitePrincipale  => 'nomenclatureActivitePrincipaleUniteLegale',
    activitePrincipale              => 'activitePrincipaleUniteLegale',
    numvoie                         => 'numeroVoieEtablissement',
    typevoie                        => 'typeVoieEtablissement',
    nomvoie                         => 'libelleVoieEtablissement',
    codePostal                      => 'codePostalEtablissement',
    nomCommune                      => 'libelleCommuneEtablissement',
    adresseComplete                 => [
                                        'numeroVoieEtablissement',
                                        'typeVoieEtablissement', 'libelleVoieEtablissement',
                                        'codePostalEtablissement', 'libelleCommuneEtablissement'
                                    ],
  };

B<Usage:>

  my $response_json = $sirene->getLegalUnitBySIREN(123456789, 'nom');

is equivalent to

  my $response_json = $sirene->getLegalUnitBySIREN(123456789, 'denominationUniteLegale');

=head1 AUTHOR

Justin Fouquet <jfouquet at lncsa dot fr>

=head1 COPYRIGHT AND LICENSE

Copyright 2018-2021 by Les Nouveaux Constructeurs

This library is free software; You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
