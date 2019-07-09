package API::INSEE::Sirene;

use strict;
use warnings;

use Carp 'croak';
use JSON;
use LWP::UserAgent;
use POSIX 'strftime';

use Exporter 'import';
our @EXPORT = qw(&getEstablishmentBySIRET &getEstablishmentsBySIREN &getEstablishmentsByName &getEstablishmentsByUsualName &getEstablishmentsByCriteria);
our @EXPORT_OK = qw(&getLegalUnitBySIREN &getLegalUnitsByCriteria &getLegalUnitsByName &getLegalUnitsByUsualName &getUserAgentInitialized);

my $API_VERSION = 3;
my $API_REVISION = 5;
my $PACKAGE_REVISION = '01';
our $VERSION = 3.501;

my $EMPTY = q{};
my $API_BASE_URL = "https://api.insee.fr/entreprises/sirene/V$API_VERSION";
our $CLIENT_AUTH = undef;

my $user_agent = undef;
our $proxy = undef;
our $timeout = 20;

our $default_max_results = 20; # from documentation
my $HARD_MAX_RESULTS = 10_000; # from documentation

my $historized_fields = [

    qw(
        dateFin dateDebut
        etatAdministratifUniteLegale
        changementEtatAdministratifUniteLegale
        nomUniteLegale changementNomUniteLegale
        nomUsageUniteLegale changementNomUsageUniteLegale
        denominationUniteLegale changementDenominationUniteLegale
        denominationUsuelle1UniteLegale denominationUsuelle2UniteLegale denominationUsuelle3UniteLegale
        changementDenominationUsuelleUniteLegale
        categorieJuridiqueUniteLegale changementCategorieJuridiqueUniteLegale
        activitePrincipaleUniteLegale nomenclatureActivitePrincipaleUniteLegale changementActivitePrincipaleUniteLegale
        nicSiegeUniteLegale changementNicSiegeUniteLegale economieSocialeSolidaireUniteLegale
        changementEconomieSocialeSolidaireUniteLegale
        caractereEmployeurUniteLegale changementCaractereEmployeurUniteLegale
    )
];

my $usefull_fields_unite_legale = [

    qw(
        siren
        dateCreationUniteLegale
        sigleUniteLegale
        categorieEntreprise
        denominationUniteLegale denominationUsuelle1UniteLegale nomUniteLegale
        categorieJuridiqueUniteLegale
        activitePrincipaleUniteLegale nomenclatureActivitePrincipaleUniteLegale
        nicSiegeUniteLegale
    )
];

my $usefull_fields_etablissement = [

    qw(
        siren siret
        denominationUsuelleEtablissement denominationUniteLegale denominationUsuelle1UniteLegale nomUniteLegale
        activitePrincipaleUniteLegale
        numeroVoieEtablissement typeVoieEtablissement libelleVoieEtablissement
        codePostalEtablissement libelleCommuneEtablissement
    )
];

my $usefull_fields_alias = {

    'nicSiege'                        => 'nicSiegeUniteLegale',
    'nom'                             => 'denominationUniteLegale',
    'dateCreation'                    => 'dateCreationUniteLegale',
    'sigle'                           => 'sigleUniteLegale',
    'categorieJuridique'              => 'categorieJuridiqueUniteLegale',
    'nomenclatureActivitePrincipale'  => 'nomenclatureActivitePrincipaleUniteLegale',
    'activitePrincipale'              => 'activitePrincipaleUniteLegale',
    'numvoie'                         => 'numeroVoieEtablissement',
    'typevoie'                        => 'typeVoieEtablissement',
    'nomvoie'                         => 'libelleVoieEtablissement',
    'codePostal'                      => 'codePostalEtablissement',
    'nomCommune'                      => 'libelleCommuneEtablissement'
};

sub initUserAgent {

    croak "No credentials" if (not $CLIENT_AUTH);
    $user_agent = LWP::UserAgent->new();

    $user_agent->agent("Perl API::INSEE::Sirene V$API_VERSION");
    $user_agent->timeout($timeout);
    $proxy ? $user_agent->proxy(['https', 'http'], $proxy) : $user_agent->env_proxy;

    my ($token, $err) = getToken();

    croak "Unable to get token.\n$err" if (!$token);

    $user_agent->default_header('Authorization' => "Bearer $token");
    $user_agent->default_header('Accept' => 'application/json');
}

sub getUserAgentInitialized {

    initUserAgent() if (not defined $user_agent);
    return $user_agent;
}

sub getToken {

    my $url = 'https://api.insee.fr/token?grant_type=client_credentials';
    my $header = ['Authorization' => "Basic $CLIENT_AUTH"];

    my $request = HTTP::Request->new('POST', $url, $header);
    my $response = $user_agent->request($request);

    if ($response->is_success) {

        # TODO check $response->header('Content-Type') eq 'application/json'
        my $json_obj;
        eval {$json_obj = decode_json($response->content);};

        return $@ ? (0, sprintf "Sent request:\n%s\nReceived response:\n%s\n", $request->as_string, $@) : $json_obj->{'access_token'};
    }

    return (0, sprintf "Sent Request:\n%s\nReceived response:\n%s\n", $request->as_string, $response->as_string);
}

sub buildParameters {

    my ($usefull_fields, $use_historized_fields, $fields, $criteria) = @_;

    my $date = strftime('%Y-%m-%d', localtime);
    $fields = buildFields($usefull_fields, $fields);
    $criteria = $criteria ? buildQuery($criteria, $use_historized_fields) : $EMPTY;

    $default_max_results = $HARD_MAX_RESULTS if ($default_max_results > $HARD_MAX_RESULTS);
    return "q=($criteria)&champs=$fields&date=$date&nombre=$default_max_results";
}

sub buildQuery {

    my ($criteria, $use_historized_fields) = @_;
    my @query;

    foreach my $key (keys %$criteria) {

        my $field_name = exists $usefull_fields_alias->{$key} ? $usefull_fields_alias->{$key} : $key;
        my @words = split /[ ?'\/-]/, $criteria->{$key};

        foreach my $word (@words) {

            if ($field_name eq 'codePostalEtablissement') {

                push @query, "$field_name:$word*";
                next;
            }

            $word =~ s/&/%26/ig;
            my $query = sprintf '(%s:"%s"~ OR %s:*%s*)', $field_name, $word, $field_name, $word;
            $query = "periode$query" if ($use_historized_fields && isInArray($field_name, $historized_fields));

            push @query, $query;
        }
    }

    return join ' AND ', @query;
}

sub buildFields {

    my ($usefull_fields, $fields) = @_;

    return join ',', @{$usefull_fields} if (not defined $fields);

    if (ref $fields eq 'ARRAY') {

        map { $_ = $usefull_fields_alias->{$_} if (exists $usefull_fields_alias->{$_}); } @{$fields};
        return join ',', @{$fields};
    }
    else {

        $fields = $usefull_fields_alias->{$fields} if (exists $usefull_fields_alias->{$fields});
        return $fields eq 'all' ? $EMPTY : $fields;
    }
}

sub isInArray {

    my ($element, $array) = @_;

    foreach (@{$array}) {

        return 1 if ($_ eq $element);
    }

    return 0;
}

sub getLegalUnitBySIREN {

    my ($siren, $fields) = @_;

    return (0, "Invalid SIREN -> Must be a 9 digits number") if ($siren !~ m/\d{9}/);

    my $parameters = buildParameters($usefull_fields_unite_legale, 0, $fields);
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siren/$siren?$parameters")->content;
}

sub getEstablishmentBySIRET {

    my ($siret, $fields) = @_;

    return (0, "Invalid SIRET -> Must be a 14 digits number") if ($siret !~ m/\d{14}/);

    my $parameters = buildParameters($usefull_fields_etablissement, 0, $fields);
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siret/$siret?$parameters")->content;
}

sub getEstablishmentsBySIREN {

    my ($siren, $fields) = @_;

    return (0, "Invalid SIREN -> Must be a 9 digits number.") if ($siren !~ m/\d{9}/);

    my $parameters = buildParameters($usefull_fields_etablissement, 0, $fields, {siren => $siren});
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siret?$parameters")->content;
}

sub getLegalUnitsByCriteria {

    my ($criteria, $fields) = @_;

    my $parameters = buildParameters($usefull_fields_unite_legale, 1, $fields, $criteria);
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siren?$parameters")->content;
}

sub getEstablishmentsByCriteria {

    my ($criteria, $fields) = @_;

    my $parameters = buildParameters($usefull_fields_etablissement, 0, $fields, $criteria);
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siret?$parameters")->content;
}

sub getLegalUnitsByName {

    my ($nom, $fields) = @_;

    my $parameters = buildParameters($usefull_fields_unite_legale, 1, $fields, {denominationUniteLegale => $nom});
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siren?$parameters")->content;
}

sub getEstablishmentsByName {

    my ($nom, $fields) = @_;

    my $parameters = buildParameters($usefull_fields_etablissement, 0, $fields, {denominationUniteLegale => $nom});
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siret?$parameters")->content;
}

sub getLegalUnitsByUsualName {

    my ($nom, $fields) = @_;

    my $parameters = buildParameters($usefull_fields_unite_legale, 1, $fields, {denominationUsuelle1UniteLegale => $nom});
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siren?$parameters")->content;
}

sub getEstablishmentsByUsualName {

    my ($nom, $fields) = @_;

    my $parameters = buildParameters($usefull_fields_etablissement, 0, $fields, {denominationUsuelle1UniteLegale => $nom});
    initUserAgent() if (not defined $user_agent);

    return $user_agent->get("$API_BASE_URL/siret?$parameters")->content;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::INSEE::Sirene - An interface for the Sirene API of INSEE

=head1 SYNOPSIS

  use API::INSEE::Sirene;

  ${API::INSEE::Sirene::CLIENT_AUTH} = 'Y2xpZW50X2tleTpjbGllbnRfc2VjcmV0'; # required: your base64 encoded credentials
  ${API::INSEE::Sirene::default_max_results} = 30; # optional
  ${API::INSEE::Sirene::proxy} = 'http://example.com:80'; # optional: if your connection require proxy, enter it here
  ${API::INSEE::Sirene::timeout} = 40; # optional

  # Examples to get informations about an establishment with SIRET number '12345678987654'
  getEstablishmentBySIRET(12345678987654, 'all');

  #or
  my $fields_that_interest_me = ['numeroVoieEtablissement', 'typeVoieEtablissement', 'libelleVoieEtablissement', 
                                 'codePostalEtablissement', 'libelleCommuneEtablissement'];
  getEstablishmentBySIRET(12345678987654, $fields_that_interest_me);

  #or
  getEstablishmentBySIRET(12345678987654, 'denominationUniteLegale');

  #or simply
  getEstablishmentBySIRET(12345678987654);

=head1 DESCRIPTION

This module allows you to interact with the Sirene API of INSEE (Institut National de la Statistique et des Études Économiques) in France.

It contains a set of functions that can perform searches on INSEE's database to get some information about french entreprises like their SIREN number, company name, company headquarters address, etc.

The terms "enterprise", "legal unit" and "establishment" used in this documentation are defined at the INSEE website in the following pages:

=over 4

=item *

B<Enterprise definition:>

L<< https://www.insee.fr/en/metadonnees/definition/c1496 >>

=item *

B<Legal unit definition:>

L<< https://www.insee.fr/en/metadonnees/definition/c1044 >>

=item *

B<Establishment definition:>

L<< https://www.insee.fr/en/metadonnees/definition/c1377 >>

=back

Here is the documentation with among others all fields names:

=over 4

=item *

L<< https://api.insee.fr/catalogue/site/themes/wso2/subthemes/insee/pages/item-info.jag?name=Sirene&version=V3&provider=insee#tab2 >>

=back

B<Please note that this API is french so all fields names used in function calls are in french.>

=head1 REQUIRED MODULES

=over 4

=item *

L<< JSON|https://metacpan.org/pod/JSON >>

=item *

L<< LWP::UserAgent|https://metacpan.org/pod/LWP::UserAgent >>

=item *

L<< POSIX::strftime|https://metacpan.org/pod/POSIX#strftime >>

=item *

L<< Carp|https://perldoc.perl.org/Carp.html >>

=back

This module makes use of the LWP library to send http requests and JSON library to decode JSON when getting the token. Also, this module gives you responses in JSON format so you may need the JSON library.

=head1 EXPORT

These following functions are exported by default:

=over 4

=item * getEstablishmentBySIRET

=item * getEstablishmentsBySIREN

=item * getEstablishmentsByName

=item * getEstablishmentsByUsualName

=item * getEstablishmentsByCriteria

=back

These folowing functions are available by manual import:

=over 4

=item * getLegalUnitBySIREN

=item * getLegalUnitsByCriteria

=item * getLegalUnitsByName

=item * getLegalUnitsByUsualName

=item * getUserAgentInitialized

=back

=head1 FUNCTIONAL INTERFACE

This section describes all functionalities available in this module.

=head2 VARIABLES

=over 4

=item B<CLIENT_AUTH>

Required variable so the module can connect to your INSEE account and obtain a token that allows him to send requests thereafter. The value must be your base64 encoded credentials.

The token has a limited lifetime (7 days by default but you can change it) and is automatically renewed by the API.
The module gets the token only once at program launch so you need to relaunch the module to get the new token.

=item B<default_max_results>

Optional variable that specifies how many results the API must return to the module. A too big value may impact response time and general performances.

This variable is set to 20 results by default.

=item B<HARD_MAX_RESULTS>

Constant that specifies the max results number you can get. This value can't be increased. If you try to send a request with a higher value, the number parameter will be forced to HARD_MAX_RESULTS value.

=item B<proxy>

Optional variable that specifies which proxy server must be used to send requests.

This variable is set to undef by default. If this variable is not set, the module uses system proxy settings.

=item B<timeout>

An optional variable that specify how many seconds the client module waits for server response before giving up.

This variable is set to 20 seconds by default.

=back

=head2 FUNCTIONS

=over 4

=item B<getLegalUnitBySIREN()>

Search a legal unit by her SIREN number.

=item B<getEstablishmentBySIRET()>

Search an establishment by his SIRET number.

=item B<getEstablishmentsBySIREN()>

Search all establishments that are attached to the legal unit identified by this SIREN number.

=item B<getLegalUnitsByCriteria()>

Search all legal units matching the specified criteria.

=item B<getEstablishmentsByCriteria()>

Search all establishments matching the specified criteria.

=item B<getLegalUnitsByName()>

Search all legal units matching the specified name. (denominationUniteLegale field)

=item B<getEstablishmentsByName()>

Search all establishments matching the specified name. (denominationUniteLegale field)

=item B<getLegalUnitsByUsualName()>

Search all legal units matching the specified name. (denominationUsuelle1UniteLegale field)

=item B<getEstablishmentsByUsualName()>

Search all establishments matching the specified name. (denominationUsuelle1UniteLegale field)

=item B<getUserAgentInitialized()>

Return the user agent initialized with the token. Allows advanced users to make their own requests.

=back

B<Note: All functions search and return values that are in the most recent legal unit period.>

=head2 PARAMETERS

=over 4

=item B<siren and siret>

In the B<getEstablishmentBySIRET()>, B<getEstablishmentsBySIREN()> and B<getLegalUnitBySIREN()> functions, you must give a SIREN or a SIRET number:

  my $response_json = getLegalUnitBySIREN(123456789);
  my $response_json = getEstablishmentBySIRET(12345678987654);
  my $response_json = getEstablishmentsBySIREN(123456789);

Note: A SIREN number must be 9 digits long and a SIRET number must be 14 digits long.

=item B<criteria>

In the B<getLegalUnitsByCriteria()> and B<getEstablishmentsByCriteria()> functions, you must give a hash reference of search criteria:

  # search all legal units whose acronym like 'ABC' AND whose category like 'ETI'
  my %criteria = (

    sigleUniteLegale => 'ABC',
    categorieEntreprise => 'ETI'
  );

  my $response_json = getLegalUnitsByCriteria(\%criteria);

Note: Criteria are concatened with an AND in query search. A criteria is a couple of field:value, you can use aliases defined below.

=item B<name>

In the B<getLegalUnitsByName()>, B<getEstablishmentsByName()>, B<getLegalUnitsByUsualName()> and B<getEstablishmentsByUsualName()> functions, you must give a string:

    my $response_json = getLegalUnitsByName("EnterpriseName");

Note: You can enter a part or the complete name of an enterprise.

=item B<fields>

All functions are taking two parameters including an optional one. The second parameter, if present, can be presented in three forms:

  my $fields_that_interest_me = ['dateCreationUniteLegale', 'sigleUniteLegale'];
  my $result_json = getLegalUnitBySIREN(123456789, $fields_that_interest_me);

  #or
  my $result_json = getLegalUnitBySIREN(123456789, 'dateCreationUniteLegale');

  #or
  my $result_json = getLegalUnitBySIREN(123456789, 'all');

You can specify an array of fields that interest you in order that the module returns to you only these fields. If you want to get only one field, you do not have to give it as an array.

When you don't specify fields like this:

  my $result_json = getLegalUnitBySIREN(123456789);

The module will not return to you all fields by default because there are too many. Instead, it returns a selection of fields that are most likely of interest to you.

If you want all fields, you have to specify it explicitly by passing the 'all' parameter.

=back

=head2 ALIAS

Some fields have an alias to be more user-friendly, here is the list of available aliases:

  my %usefull_fields_alias = (

    'nicSiege'                       => 'nicSiegeUniteLegale',
    'nom'                            => 'denominationUniteLegale',
    'dateCreation'                   => 'dateCreationUniteLegale',
    'sigle'                          => 'sigleUniteLegale',
    'categorieJuridique'             => 'categorieJuridiqueUniteLegale',
    'nomenclatureActivitePrincipale' => 'nomenclatureActivitePrincipaleUniteLegale',
    'activitePrincipale'             => 'activitePrincipaleUniteLegale',
    'numvoie'                        => 'numeroVoieEtablissement',
    'typevoie'                       => 'typeVoieEtablissement',
    'nomvoie'                        => 'libelleVoieEtablissement',
    'codePostal'                     => 'codePostalEtablissement',
    'nomCommune'                     => 'libelleCommuneEtablissement'
  );

B<Usage:>

  my $result_json = getLegalUnitBySIREN(123456789, 'nom');

is equivalent to

  my $result_json = getLegalUnitBySIREN(123456789, 'denominationUniteLegale');

=head1 AUTHOR

Justin Fouquet <jfouquet at lncsa dot fr>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 by Les Nouveaux Constructeurs

This library is free software; You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
