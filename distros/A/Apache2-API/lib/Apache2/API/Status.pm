##----------------------------------------------------------------------------
## Apache2 API Framework - ~/lib/Apache2/API/Status.pm
## Version v0.2.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/05/30
## Modified 2025/10/08
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Apache2::API::Status;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Apache2::API' );
    use parent qw( Module::Generic );
    use vars qw( $CODES $HTTP_CODES $MAP_LANG_SHORT $STATUS_TO_TYPE );
    use Apache2::Const -compile => qw( :http );
    use constant 
    {
    HTTP_CONTINUE                           => 100,
    HTTP_SWITCHING_PROTOCOLS                => 101,
    HTTP_PROCESSING                         => 102,
    HTTP_EARLY_HINTS                        => 103,
    HTTP_OK                                 => 200,
    HTTP_CREATED                            => 201,
    HTTP_ACCEPTED                           => 202,
    HTTP_NON_AUTHORITATIVE                  => 203,
    HTTP_NO_CONTENT                         => 204,
    HTTP_RESET_CONTENT                      => 205,
    HTTP_PARTIAL_CONTENT                    => 206,
    HTTP_MULTI_STATUS                       => 207,
    HTTP_ALREADY_REPORTED                   => 208,
    HTTP_IM_USED                            => 226,
    HTTP_MULTIPLE_CHOICES                   => 300,
    HTTP_MOVED_PERMANENTLY                  => 301,
    HTTP_MOVED_TEMPORARILY                  => 302,
    HTTP_SEE_OTHER                          => 303,
    HTTP_NOT_MODIFIED                       => 304,
    HTTP_USE_PROXY                          => 305,
    HTTP_TEMPORARY_REDIRECT                 => 307,
    HTTP_PERMANENT_REDIRECT                 => 308,
    HTTP_BAD_REQUEST                        => 400,
    HTTP_UNAUTHORIZED                       => 401,
    HTTP_PAYMENT_REQUIRED                   => 402,
    HTTP_FORBIDDEN                          => 403,
    HTTP_NOT_FOUND                          => 404,
    HTTP_METHOD_NOT_ALLOWED                 => 405,
    HTTP_NOT_ACCEPTABLE                     => 406,
    HTTP_PROXY_AUTHENTICATION_REQUIRED      => 407,
    HTTP_REQUEST_TIME_OUT                   => 408,
    HTTP_CONFLICT                           => 409,
    HTTP_GONE                               => 410,
    HTTP_LENGTH_REQUIRED                    => 411,
    HTTP_PRECONDITION_FAILED                => 412,
    HTTP_REQUEST_ENTITY_TOO_LARGE           => 413,
    # Compatibility with HTTP::Status
    HTTP_PAYLOAD_TOO_LARGE                  => 413,
    HTTP_REQUEST_URI_TOO_LARGE              => 414,
    HTTP_URI_TOO_LONG                       => 414,
    HTTP_UNSUPPORTED_MEDIA_TYPE             => 415,
    HTTP_RANGE_NOT_SATISFIABLE              => 416,
    # Compatibility with HTTP::Status
    HTTP_REQUEST_RANGE_NOT_SATISFIABLE      => 416,
    HTTP_EXPECTATION_FAILED                 => 417,
    HTTP_I_AM_A_TEA_POT                     => 418,
    # Compatibility with HTTP::Status
    HTTP_I_AM_A_TEAPOT                      => 418,
    HTTP_MISDIRECTED_REQUEST                => 421,
    HTTP_UNPROCESSABLE_ENTITY               => 422,
    HTTP_LOCKED                             => 423,
    HTTP_FAILED_DEPENDENCY                  => 424,
    HTTP_TOO_EARLY                          => 425,
    # Compatibility with HTTP::Status
    HTTP_NO_CODE                            => 425,
    # Compatibility with HTTP::Status
    HTTP_UNORDERED_COLLECTION               => 425,
    HTTP_UPGRADE_REQUIRED                   => 426,
    HTTP_PRECONDITION_REQUIRED              => 428,
    HTTP_TOO_MANY_REQUESTS                  => 429,
    HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE    => 431,
    HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE => 444,
    HTTP_UNAVAILABLE_FOR_LEGAL_REASONS      => 451,
    HTTP_CLIENT_CLOSED_REQUEST              => 499,
    HTTP_INTERNAL_SERVER_ERROR              => 500,
    HTTP_NOT_IMPLEMENTED                    => 501,
    HTTP_BAD_GATEWAY                        => 502,
    HTTP_SERVICE_UNAVAILABLE                => 503,
    HTTP_GATEWAY_TIME_OUT                   => 504,
    HTTP_VERSION_NOT_SUPPORTED              => 505,
    HTTP_VARIANT_ALSO_VARIES                => 506,
    HTTP_INSUFFICIENT_STORAGE               => 507,
    HTTP_LOOP_DETECTED                      => 508,
    HTTP_BANDWIDTH_LIMIT_EXCEEDED           => 509,
    HTTP_NOT_EXTENDED                       => 510,
    HTTP_NETWORK_AUTHENTICATION_REQUIRED    => 511,
    HTTP_NETWORK_CONNECT_TIMEOUT_ERROR      => 599,
    };
    our @EXPORT_OK = qw(
        HTTP_ACCEPTED HTTP_ALREADY_REPORTED HTTP_BAD_GATEWAY HTTP_BAD_REQUEST
        HTTP_BANDWIDTH_LIMIT_EXCEEDED HTTP_CLIENT_CLOSED_REQUEST HTTP_CONFLICT
        HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE HTTP_CONTINUE HTTP_CREATED
        HTTP_EARLY_HINTS HTTP_EXPECTATION_FAILED HTTP_FAILED_DEPENDENCY
        HTTP_FORBIDDEN HTTP_GATEWAY_TIME_OUT HTTP_GONE HTTP_IM_USED
        HTTP_INSUFFICIENT_STORAGE HTTP_INTERNAL_SERVER_ERROR
        HTTP_I_AM_A_TEAPOT HTTP_I_AM_A_TEA_POT HTTP_LENGTH_REQUIRED
        HTTP_LOCKED HTTP_LOOP_DETECTED HTTP_METHOD_NOT_ALLOWED
        HTTP_MISDIRECTED_REQUEST HTTP_MOVED_PERMANENTLY HTTP_MOVED_TEMPORARILY
        HTTP_MULTIPLE_CHOICES HTTP_MULTI_STATUS
        HTTP_NETWORK_AUTHENTICATION_REQUIRED
        HTTP_NETWORK_CONNECT_TIMEOUT_ERROR HTTP_NON_AUTHORITATIVE
        HTTP_NOT_ACCEPTABLE HTTP_NOT_EXTENDED HTTP_NOT_FOUND
        HTTP_NOT_IMPLEMENTED HTTP_NOT_MODIFIED HTTP_NO_CODE HTTP_NO_CONTENT
        HTTP_OK HTTP_PARTIAL_CONTENT HTTP_PAYLOAD_TOO_LARGE
        HTTP_PAYMENT_REQUIRED HTTP_PERMANENT_REDIRECT HTTP_PRECONDITION_FAILED
        HTTP_PRECONDITION_REQUIRED HTTP_PROCESSING
        HTTP_PROXY_AUTHENTICATION_REQUIRED HTTP_RANGE_NOT_SATISFIABLE
        HTTP_REQUEST_ENTITY_TOO_LARGE HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE
        HTTP_REQUEST_RANGE_NOT_SATISFIABLE HTTP_REQUEST_TIME_OUT
        HTTP_REQUEST_URI_TOO_LARGE HTTP_RESET_CONTENT HTTP_SEE_OTHER
        HTTP_SERVICE_UNAVAILABLE HTTP_SWITCHING_PROTOCOLS
        HTTP_TEMPORARY_REDIRECT HTTP_TOO_EARLY HTTP_TOO_MANY_REQUESTS
        HTTP_UNAUTHORIZED HTTP_UNAVAILABLE_FOR_LEGAL_REASONS
        HTTP_UNORDERED_COLLECTION HTTP_UNPROCESSABLE_ENTITY
        HTTP_UNSUPPORTED_MEDIA_TYPE HTTP_UPGRADE_REQUIRED HTTP_URI_TOO_LONG
        HTTP_USE_PROXY HTTP_VARIANT_ALSO_VARIES HTTP_VERSION_NOT_SUPPORTED
    );
    our %EXPORT_TAGS = (
        all => [@EXPORT_OK], 
        common  => [qw( HTTP_NETWORK_AUTHENTICATION_REQUIRED HTTP_FORBIDDEN HTTP_NOT_FOUND HTTP_OK HTTP_TEMPORARY_REDIRECT HTTP_INTERNAL_SERVER_ERROR )],
    );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

use utf8;
# Ref:
# <https://datatracker.ietf.org/doc/html/rfc7231#section-8.2>
# <http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>
our $CODES =
{
# Info 1xx
100 => Apache2::Const::HTTP_CONTINUE,
101 => Apache2::Const::HTTP_SWITCHING_PROTOCOLS,
102 => Apache2::Const::HTTP_PROCESSING,
# Success 2xx
200 => Apache2::Const::HTTP_OK,
201 => Apache2::Const::HTTP_CREATED,
202 => Apache2::Const::HTTP_ACCEPTED,
203 => Apache2::Const::HTTP_NON_AUTHORITATIVE,
204 => Apache2::Const::HTTP_NO_CONTENT,
205 => Apache2::Const::HTTP_RESET_CONTENT,
206 => Apache2::Const::HTTP_PARTIAL_CONTENT,
207 => Apache2::Const::HTTP_MULTI_STATUS,
208 => Apache2::Const::HTTP_ALREADY_REPORTED,
226 => Apache2::Const::HTTP_IM_USED,
# Redirect 3xx
300 => Apache2::Const::HTTP_MULTIPLE_CHOICES,
301 => Apache2::Const::HTTP_MOVED_PERMANENTLY,
302 => Apache2::Const::HTTP_MOVED_TEMPORARILY,
303 => Apache2::Const::HTTP_SEE_OTHER,
304 => Apache2::Const::HTTP_NOT_MODIFIED,
305 => Apache2::Const::HTTP_USE_PROXY,
307 => Apache2::Const::HTTP_TEMPORARY_REDIRECT,
308 => Apache2::Const::HTTP_PERMANENT_REDIRECT,
# Client error 4xx
400 => Apache2::Const::HTTP_BAD_REQUEST,
401 => Apache2::Const::HTTP_UNAUTHORIZED,
402 => Apache2::Const::HTTP_PAYMENT_REQUIRED,
403 => Apache2::Const::HTTP_FORBIDDEN,
404 => Apache2::Const::HTTP_NOT_FOUND,
405 => Apache2::Const::HTTP_METHOD_NOT_ALLOWED,
406 => Apache2::Const::HTTP_NOT_ACCEPTABLE,
407 => Apache2::Const::HTTP_PROXY_AUTHENTICATION_REQUIRED,
408 => Apache2::Const::HTTP_REQUEST_TIME_OUT,
409 => Apache2::Const::HTTP_CONFLICT,
410 => Apache2::Const::HTTP_GONE,
411 => Apache2::Const::HTTP_LENGTH_REQUIRED,
412 => Apache2::Const::HTTP_PRECONDITION_FAILED,
413 => Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE,
414 => Apache2::Const::HTTP_REQUEST_URI_TOO_LARGE,
415 => Apache2::Const::HTTP_UNSUPPORTED_MEDIA_TYPE,
416 => Apache2::Const::HTTP_RANGE_NOT_SATISFIABLE,
417 => Apache2::Const::HTTP_EXPECTATION_FAILED,
# 421 => Apache2::Const::HTTP_MISDIRECTED_REQUEST,
#W WebDAV
422 => Apache2::Const::HTTP_UNPROCESSABLE_ENTITY,
# WebDAV
423 => Apache2::Const::HTTP_LOCKED,
# WebDAV
424 => Apache2::Const::HTTP_FAILED_DEPENDENCY,
426 => Apache2::Const::HTTP_UPGRADE_REQUIRED,
428 => Apache2::Const::HTTP_PRECONDITION_REQUIRED,
429 => Apache2::Const::HTTP_TOO_MANY_REQUESTS,
431 => Apache2::Const::HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE,
# 451 => Apache2::Const::HTTP_UNAVAILABLE_FOR_LEGAL_REASONS,
# Server error 5xx
500 => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR,
501 => Apache2::Const::HTTP_NOT_IMPLEMENTED,
502 => Apache2::Const::HTTP_BAD_GATEWAY,
503 => Apache2::Const::HTTP_SERVICE_UNAVAILABLE,
504 => Apache2::Const::HTTP_GATEWAY_TIME_OUT,
506 => Apache2::Const::HTTP_VARIANT_ALSO_VARIES,
# WebDAV
507 => Apache2::Const::HTTP_INSUFFICIENT_STORAGE,
508 => Apache2::Const::HTTP_LOOP_DETECTED,
510 => Apache2::Const::HTTP_NOT_EXTENDED,
511 => Apache2::Const::HTTP_NETWORK_AUTHENTICATION_REQUIRED,
};

our $HTTP_CODES =
{
    cs_CZ => {
        100 => "Pokračovat",
        101 => "Přepínání protokolů",
        102 => "Zpracovává se",
        103 => "Předběžné pokyny",
        200 => "OK",
        201 => "Vytvořeno",
        202 => "Přijato",
        203 => "Neautoritativní informace",
        204 => "Bez obsahu",
        205 => "Obnovit obsah",
        206 => "Částečný obsah",
        207 => "Více stavů",
        208 => "Již nahlášeno",
        226 => "IM použito",
        300 => "Více možností",
        301 => "Trvale přesunuto!",
        302 => "Dočasně přesunuto!",
        303 => "Viz jiné",
        304 => "Nezměněno",
        305 => "Použít proxy",
        307 => "Dočasné přesměrování!",
        308 => "Trvalé přesměrování!",
        400 => "Chybný požadavek!",
        401 => "Požadováno ověření!",
        402 => "Platba vyžadována!",
        403 => "Přístup odmítnut!",
        404 => "Objekt nenalezen!",
        405 => "Metoda nepovolena!",
        406 => "Nepřijatelné!",
        407 => "Požadováno ověření proxy!",
        408 => "Vypršel časový limit požadavku!",
        409 => "Konflikt!",
        410 => "Zdroj již není dále dostupný!",
        411 => "Chybná hlavička Content-Length!",
        412 => "Předběžná podmínka nesplněna!",
        413 => "Požadovaná entita je příliš velká!",
        414 => "Požadované URI je příliš dlouhé!",
        415 => "Nepodporovaný typ média!",
        416 => "Požadovanému rozsahu nelze vyhovět!",
        417 => "Očekávání nesplněno!",
        418 => "Jsem čajník",
        421 => "Chybně směrovaný požadavek",
        422 => "Nezpracovatelná entita!",
        423 => "Zámek zdroje!",
        424 => "Selhávající závislost!",
        425 => "Příliš brzy!",
        426 => "Vyžadována aktualizace!",
        428 => "Vyžadována předpodmínka",
        429 => "Příliš mnoho požadavků!",
        431 => "Hlavičky požadavku příliš velké!",
        444 => "Připojení ukončeno bez odpovědi",
        451 => "Nedostupné z právních důvodů!",
        499 => "Požadavek ukončen klientem",
        500 => "Chyba serveru!",
        501 => "Nelze zpracovat požadavek!",
        502 => "Chybná brána!",
        503 => "Služba není dostupná!",
        504 => "Vypršel čas brány!",
        505 => "Nepodporovaná verze HTTP",
        506 => "Varianta rovněž variuje!",
        507 => "Nedostatek úložného prostoru!",
        508 => "Zjištěna smyčka!",
        509 => "Překročeno omezení šířky pásma",
        510 => "Nerozšířeno",
        511 => "Vyžadováno síťové ověření",
        599 => "Chyba časového limitu síťového připojení",
    },
    # Ref: <https://developer.mozilla.org/de/docs/Web/HTTP/Status/100>
    # <https://www.dotcom-monitor.com/wiki/de/knowledge-base/http-status-codes/>
    de_DE => {
        100 => "Weiter",
        101 => "Protokolle wechseln",
        102 => "Verarbeitung",
        103 => "Frühe Hinweise",
        200 => "OK",
        201 => "Erstellt",
        202 => "Akzeptiert",
        203 => "Nicht autorisierende Informationen",
        204 => "Kein Inhalt",
        205 => "Inhalt zurücksetzen",
        206 => "Teilinhalt",
        207 => "Multi-Status",
        208 => "Bereits gemeldet",
        226 => "IM verwendet",
        300 => "Mehrfachauswahlmöglichkeiten",
        301 => "Dauerhaft verschoben!",
        302 => "Vorübergehend verschoben!",
        303 => "Andere sehen",
        304 => "Nicht geändert",
        305 => "Proxy verwenden",
        307 => "Vorübergehende Umleitung!",
        308 => "Dauerhafte Umleitung!",
        400 => "Fehlerhafte Anfrage!",
        401 => "Authentifizierung erforderlich!",
        402 => "Zahlung erforderlich!",
        403 => "Zugriff verweigert!",
        404 => "Objekt nicht gefunden!",
        405 => "Methode nicht erlaubt!",
        406 => "Nicht akzeptabel!",
        407 => "Proxy-Authentifizierung erforderlich!",
        408 => "Zeitlimit überschritten!",
        409 => "Konflikt!",
        410 => "Objekt nicht mehr verfügbar!",
        411 => "Content-Length-Angabe fehlerhaft!",
        412 => "Vorbedingung nicht erfüllt!",
        413 => "Übergebene Daten zu groß!",
        414 => "Übergebener URI zu lang!",
        415 => "Nicht unterstützter Medientyp!",
        416 => "Bereich nicht erfüllbar!",
        417 => "Erwartung fehlgeschlagen!",
        418 => "Ich bin eine Teekanne",
        421 => "Fehlgeleitete Anfrage",
        422 => "Unverarbeitbare Entität!",
        423 => "Ressource gesperrt!",
        424 => "Fehlende Abhängigkeit!",
        425 => "Zu früh!",
        426 => "Upgrade erforderlich!",
        428 => "Vorbedingung erforderlich",
        429 => "Zu viele Anfragen!",
        431 => "Anfrage-Header zu groß!",
        444 => "Verbindung ohne Antwort geschlossen",
        451 => "Aus rechtlichen Gründen nicht verfügbar!",
        499 => "Client die Verbindung schließt",
        500 => "Serverfehler!",
        501 => "Anfrage nicht ausführbar!",
        502 => "Fehlerhaftes Gateway!",
        503 => "Dienst nicht verfügbar!",
        504 => "Gateway-Zeitüberschreitung!",
        505 => "HTTP-Version nicht unterstützt",
        506 => "Variante variiert ebenfalls!",
        507 => "Unzureichender Speicherplatz!",
        508 => "Endlosschleife erkannt!",
        509 => "Bandbreitenlimit überschritten",
        510 => "Nicht erweitert",
        511 => "Netzwerkauthentifizierung erforderlich",
        599 => "Timeout-Fehler bei Netzwerkverbindung",
    },
    en_GB => {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",
        103 => "Early Hints",
        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        208 => "Already Reported",
        226 => "IM Used",
        300 => "Multiple Choices",
        301 => "Moved permanently!",
        302 => "Found (temporary redirect)!",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary redirect!",
        308 => "Permanent redirect!",
        400 => "Bad request!",
        401 => "Authentication required!",
        402 => "Payment required!",
        403 => "Access forbidden!",
        404 => "Object not found!",
        405 => "Method not allowed!",
        406 => "Not acceptable!",
        407 => "Proxy authentication required!",
        408 => "Request time-out!",
        409 => "Conflict!",
        410 => "Resource is no longer available!",
        411 => "Bad Content-Length!",
        412 => "Precondition failed!",
        413 => "Request entity too large!",
        414 => "Submitted URI too long!",
        415 => "Unsupported media type!",
        416 => "Range not satisfiable!",
        417 => "Expectation failed!",
        # Humour: April's fool
        # <https://en.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol>
        418 => "I'm a teapot",
        421 => "Misdirected Request",
        422 => "Unprocessable entity!",
        423 => "Resource locked!",
        424 => "Failed dependency!",
        425 => "Too early!",
        426 => "Upgrade Required!",
        428 => "Precondition Required",
        429 => "Too many requests!",
        431 => "Request Headers Too Large!",
        444 => "Connection Closed Without Response",
        451 => "Unavailable for legal reasons!",
        499 => "Client Closed Request",
        500 => "Server error!",
        501 => "Cannot process request!",
        502 => "Bad Gateway!",
        503 => "Service unavailable!",
        504 => "Gateway timeout!",
        505 => "HTTP Version Not Supported",
        506 => "Variant also varies!",
        507 => "Insufficient storage!",
        508 => "Loop detected!",
        509 => "Bandwidth Limit Exceeded",
        510 => "Not Extended",
        511 => "Network Authentication Required",
        599 => "Network Connect Timeout Error",
    },
    es_ES => {
        100 => "Continuar",
        101 => "Cambio de protocolos",
        102 => "Procesando",
        103 => "Pistas tempranas",
        200 => "OK",
        201 => "Creado",
        202 => "Aceptado",
        203 => "Información no autoritativa",
        204 => "Sin contenido",
        205 => "Restablecer contenido",
        206 => "Contenido parcial",
        207 => "Multi-estado",
        208 => "Ya informado",
        226 => "IM usado",
        300 => "Múltiples opciones",
        301 => "¡Movido permanentemente!",
        302 => "¡Encontrado (redirección temporal)!",
        303 => "Ver otros",
        304 => "No modificado",
        305 => "Usar proxy",
        307 => "¡Redirección temporal!",
        308 => "¡Redirección permanente!",
        400 => "¡Petición errónea!",
        401 => "¡Autenticación requerida!",
        402 => "¡Pago requerido!",
        403 => "¡Acceso prohibido!",
        404 => "¡Objeto no localizado!",
        405 => "¡Método no permitido!",
        406 => "¡No aceptable!",
        407 => "¡Se requiere autenticación de proxy!",
        408 => "¡Tiempo de espera excedido!",
        409 => "¡Conflicto!",
        410 => "¡El recurso ya no está disponible!",
        411 => "¡Error en la longitud del contenido!",
        412 => "¡Fallo de precondición!",
        413 => "¡La entidad solicitada es demasiado grande!",
        414 => "¡El URI enviado es demasiado largo!",
        415 => "¡Tipo de medio no soportado!",
        416 => "Rango no satisfacible!",
        417 => "Expectativa no satisfecha!",
        418 => "Soy una tetera",
        421 => "Solicitud mal dirigida",
        422 => "¡Entidad no procesable!",
        423 => "Recurso bloqueado!",
        424 => "¡Dependencia fallida!",
        425 => "¡Demasiado pronto!",
        426 => "¡Actualización requerida!",
        428 => "Se requiere condición previa",
        429 => "¡Demasiadas solicitudes!",
        431 => "¡Encabezados de solicitud demasiado grandes!",
        444 => "Conexión cerrada sin respuesta",
        451 => "¡No disponible por razones legales!",
        499 => "Solicitud cerrada por el cliente",
        500 => "¡Error del servidor!",
        501 => "¡No se puede procesar la petición!",
        502 => "¡Puerta de enlace errónea!",
        503 => "¡Servicio no disponible!",
        504 => "¡Tiempo de espera de la pasarela agotado!",
        505 => "Versión HTTP no soportada",
        506 => "La variante también varía",
        507 => "¡Almacenamiento insuficiente!",
        508 => "¡Bucle detectado!",
        509 => "Límite de ancho de banda excedido",
        510 => "No extendido",
        511 => "Autenticación de red requerida",
        599 => "Error de tiempo de espera de conexión de red",
    },
    fr_FR => {
        100 => "Continuer",
        101 => "Changement de protocole",
        102 => "En traitement",
        103 => "Premiers indices",
        200 => "OK",
        201 => "Créé",
        202 => "Accepté",
        203 => "Information non certifiée",
        204 => "Pas de contenu",
        205 => "Contenu réinitialisé",
        206 => "Contenu partiel",
        207 => "Multi-Status",
        208 => "Déjà rapporté",
        226 => "IM utilisé",
        300 => "Choix multiples",
        301 => "Déplacé définitivement !",
        302 => "Trouvé (redirection temporaire) !",
        303 => "Voir ailleurs",
        304 => "Non modifié",
        305 => "Utiliser le proxy",
        307 => "Redirection temporaire !",
        308 => "Redirection permanente !",
        400 => "Requête incorrecte !",
        401 => "Authentification requise !",
        402 => "Paiement requis !",
        403 => "Accès interdit!",
        404 => "Objet non trouvé!",
        405 => "Méthode interdite!",
        406 => "Non acceptable !",
        407 => "Authentification proxy requise !",
        408 => "Délai d’attente de la requête dépassé !",
        409 => "Conflit !",
        410 => "Cette ressource n'existe plus!",
        411 => "Longueur du contenu invalide!",
        412 => "Échec de la précondition !",
        413 => "Corps de requête trop volumineux !",
        414 => "L’URI transmis est trop long !",
        415 => "Type de média non pris en charge !",
        416 => "Plage de requête non satisfaisable !",
        417 => "Attente non satisfaite !",
        # Humour; poisson d'avril
        # <https://fr.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol>
        418 => "Je suis une théière",
        421 => "Requête mal dirigée",
        422 => "Entité non traitable !",
        423 => "Ressource verrouillée !",
        424 => "Dépendance défaillante !",
        425 => "Trop tôt !",
        426 => "Mise à niveau requise !",
        428 => "Précondition requise",
        429 => "Trop de requêtes !",
        431 => "En-têtes de requête trop grands !",
        444 => "Connexion clôturée sans réponse",
        451 => "Indisponible pour des raisons juridiques !",
        499 => "Le client a terminé la requête",
        500 => "Erreur du serveur!",
        501 => "La requête ne peut pas être traitée!",
        502 => "Mauvaise passerelle !",
        503 => "Service inaccessible!",
        504 => "Délai d’attente de la passerelle dépassé !",
        505 => "Version HTTP non supportée",
        506 => "La variante varie également !",
        507 => "Espace de stockage insuffisant !",
        508 => "Boucle détectée !",
        509 => "Limite de bande passante dépassée",
        510 => "Pas étendu",
        511 => "Authentification réseau requise",
        599 => "Délai d’attente de la connexion réseau dépassé",
    },
    ga_IE => {
        100 => "Lean ar aghaidh",
        101 => "Prótacail á n-athrú",
        102 => "Á phróiseáil",
        103 => "Leideanna luatha",
        200 => "OK",
        201 => "Cruthaithe",
        202 => "Glactha",
        203 => "Eolas neamhúdarásach",
        204 => "Gan ábhar",
        205 => "Ábhar athshocraithe",
        206 => "Ábhar páirteach",
        207 => "Il-stádas",
        208 => "Tuairiscithe cheana",
        226 => "IM in úsáid",
        300 => "Ilroghanna",
        301 => "Bogtha go buan!",
        302 => "Aimsíodh (atreorú sealadach)!",
        303 => "Féach eile",
        304 => "Gan athrú",
        305 => "Úsáid seachfhreastalaí",
        307 => "Atreorú sealadach!",
        308 => "Atreorú buan!",
        400 => "Iarratas mícheart!",
        401 => "Is gá fíordheimhniú!",
        402 => "Íocaíocht de dhíth!",
        403 => "Rochtain neamhcheadaithe!",
        404 => "Aidhm ar iarraidh!",
        405 => "Modh neamhcheadaithe!",
        406 => "Neamhghlactha!",
        407 => "Fíordheimhniú seachfhreastalaí de dhíth!",
        408 => "Iarratas thar am!",
        409 => "Coinbhleacht!",
        410 => "Acmhainn imithe!",
        411 => "Content-Length mícheart!",
        412 => "Theip ar réamhchoinníoll!",
        413 => "Eintiteas an iarratais ró-mhór!",
        414 => "URI ró-fhada cuirthe isteach!",
        415 => "Cineál meán gan tacaíocht!",
        416 => "Raon nach féidir a shásamh!",
        417 => "Theip an ionchas!",
        418 => "Is taephota mé",
        421 => "Iarratas mí-treoraithe",
        422 => "Aonad do-dhéanta a phróiseáil!",
        423 => "Acmhainn faoi ghlas!",
        424 => "Spleáchas teipthe!",
        425 => "Ró-luath!",
        426 => "Uasghrádú riachtanach!",
        428 => "Réamhchoinníoll riachtanach",
        429 => "An iomarca iarrataí!",
        431 => "Ceannteidil iarratais ró-mhór!",
        444 => "Ceangal dúnta gan freagra",
        451 => "Níl ar fáil ar chúiseanna dlí!",
        499 => "Iarratas dúnta ag an gcliant",
        500 => "Earráid fhreastalaí!",
        501 => "Ní féidir an t-iarratas a phróiseáil!",
        502 => "Geata mícheart!",
        503 => "Seirbhís doúsáidte!",
        504 => "Teorainn ama geata imithe thar fóir!",
        505 => "Leagan HTTP gan tacaíocht",
        506 => "Athróg ag athrú freisin!",
        507 => "Stóráil neamhleor!",
        508 => "Lúb aithnithe!",
        509 => "Teorainn bandaleithid sáraithe",
        510 => "Gan leathnú",
        511 => "Fíordheimhniú líonra riachtanach",
        599 => "Earráid ama-theorann ceangail líonra",
    },
    it_IT => {
        100 => "Continua",
        101 => "Cambio di protocollo",
        102 => "Elaborazione in corso",
        103 => "Suggerimenti iniziali",
        200 => "OK",
        201 => "Creato",
        202 => "Accettato",
        203 => "Informazioni non autorevoli",
        204 => "Nessun contenuto",
        205 => "Reimposta contenuto",
        206 => "Contenuto parziale",
        207 => "Multi-stato",
        208 => "Già segnalato",
        226 => "IM utilizzato",
        300 => "Scelte multiple",
        301 => "Spostato definitivamente!",
        302 => "Trovato (reindirizzamento temporaneo)!",
        303 => "Vedi altro",
        304 => "Non modificato",
        305 => "Usa proxy",
        307 => "Reindirizzamento temporaneo!",
        308 => "Reindirizzamento permanente!",
        400 => "Richiesta non valida!",
        401 => "Autenticazione richiesta!",
        402 => "È richiesto il pagamento!",
        403 => "Accesso negato!",
        404 => "Oggetto non trovato!",
        405 => "Metodo non consentito!",
        406 => "Non accettabile!",
        407 => "Autenticazione proxy richiesta!",
        408 => "Time-out della richiesta!",
        409 => "Conflitto!",
        410 => "La risorsa non è più disponibile!",
        411 => "Campo Content-Length non valido!",
        412 => "Precondizione non soddisfatta!",
        413 => "Entità della richiesta troppo grande!",
        414 => "URI troppo lungo!",
        415 => "Tipo di media non supportato!",
        416 => "Intervallo non soddisfacibile!",
        417 => "Expectation fallita!",
        418 => "Sono una teiera",
        421 => "Richiesta mal indirizzata",
        422 => "Entità non elaborabile!",
        423 => "Risorsa bloccata!",
        424 => "Dipendenza non soddisfatta!",
        425 => "Troppo presto!",
        426 => "Aggiornamento richiesto!",
        428 => "Precondizione richiesta",
        429 => "Troppe richieste!",
        431 => "Intestazioni di richiesta troppo grandi!",
        444 => "Connessione chiusa senza risposta",
        451 => "Non disponibile per motivi legali!",
        499 => "Richiesta chiusa dal client",
        500 => "Errore del server!",
        501 => "La richiesta non può essere soddisfatta!",
        502 => "Gateway errato!",
        503 => "Servizio non disponibile!",
        504 => "Timeout del gateway!",
        505 => "Versione HTTP non supportata",
        506 => "La variante varia anch’essa!",
        507 => "Spazio di archiviazione insufficiente!",
        508 => "Rilevato loop!",
        509 => "Limite di banda superato",
        510 => "Non esteso",
        511 => "Autenticazione di rete richiesta",
        599 => "Errore di timeout della connessione di rete",
    },
    ja_JP => {
        100 => "継続",
        101 => "プロトコル切替",
        102 => "処理中",
        103 => "早期のヒント",
        200 => "成功",
        201 => "作成完了",
        202 => "受理",
        203 => "信頼できない情報",
        204 => "内容なし",
        205 => "内容をリセット",
        206 => "部分的内容",
        207 => "複数のステータス",
        208 => "既に報告",
        226 => "IM使用",
        300 => "複数の選択",
        301 => "恒久的に移動しました！",
        302 => "一時的に移動しました！",
        303 => "他を参照せよ",
        304 => "未更新",
        305 => "プロキシを使用せよ",
        307 => "一時的なリダイレクト！",
        308 => "恒久的なリダイレクト！",
        400 => "不正なリクエスト！",
        401 => "認証が必要です！",
        402 => "お支払いが必要です！",
        403 => "アクセス拒否！",
        404 => "未検出！",
        405 => "許可されていないメソッド！",
        406 => "受理できません！",
        407 => "プロキシ認証が必要です！",
        408 => "リクエストタイムアウト！",
        409 => "競合が発生しました！",
        410 => "リソースはもう使えない！",
        411 => "不正なContent-Length！",
        412 => "前提条件を満たしていません！",
        413 => "ペイロードが大きすぎる！",
        414 => "URI が長すぎます！",
        415 => "サポートされていないメディアタイプ！",
        416 => "要求範囲は満たせません！",
        417 => "Expect ヘッダーを満たせません！",
        418 => "私はティーポット",
        421 => "誤った宛先へのリクエスト",
        422 => "処理できないエンティティ！",
        423 => "リソースがロックされています！",
        424 => "依存関係の失敗！",
        425 => "時期尚早！",
        426 => "アップグレードが必要！",
        428 => "前提条件が必要です",
        429 => "リクエストが多すぎます！",
        431 => "リクエストヘッダが大きすぎる！",
        444 => "応答なしで接続が閉じられました",
        451 => "法的理由により利用できません！",
        499 => "クライアントによるリクエストの終了",
        500 => "サーバ内部エラー！",
        501 => "リクエストを処理できない！",
        502 => "不正なゲートウェイ！",
        503 => "サービス利用不可！",
        504 => "ゲートウェイタイムアウト！",
        505 => "サポートしていないHTTPバージョン",
        506 => "バリアントも変動します！",
        507 => "ストレージ不足！",
        508 => "ループを検出しました！",
        509 => "帯域幅制限超過",
        510 => "拡張できない",
        511 => "ネットワーク認証が必要",
        599 => "ネットワーク接続タイムアウトエラー",
    },
    # Ref: <https://developer.mozilla.org/ko/docs/Web/HTTP/Status>
    # <https://ko.wikipedia.org/wiki/HTTP_%EC%83%81%ED%83%9C_%EC%BD%94%EB%93%9C>
    # <http://wiki.hash.kr/index.php/HTTP>
    ko_KR => {
        100 => "계속",
        101 => "스위칭 프로토콜",
        102 => "처리 중",
        103 => "초기 힌트",
        200 => "확인",
        201 => "생성됨",
        202 => "수락",
        203 => "신뢰할 수 없는 정보",
        204 => "내용 없음",
        205 => "콘텐츠 재설정",
        206 => "부분적인 내용",
        207 => "다중 상태",
        208 => "이미 보고됨",
        226 => "IM 사용",
        300 => "다중 선택",
        301 => "영구적으로 이동되었습니다!",
        302 => "임시로 이동되었습니다!",
        303 => "다른 참조",
        304 => "수정되지 않음",
        305 => "프록시 사용",
        307 => "임시 리디렉션!",
        308 => "영구 리디렉션!",
        400 => "잘못된 요청!",
        401 => "인증 필요!",
        402 => "결제가 필요합니다!",
        403 => "접근이 거부됨!",
        404 => "객체 없음!",
        405 => "허용되지 않는 요청 방식!",
        406 => "허용되지 않음!",
        407 => "프록시 인증이 필요합니다!",
        408 => "요청 시간 초과!",
        409 => "충돌!",
        410 => "요청한 리소스는 더 이상 제공되지 않습니다!",
        411 => "잘못된 Content-Length!",
        412 => "사전 조건이 충족되지 않았습니다!",
        413 => "요청 본문이 너무 큽니다!",
        414 => "제출한 URI가 너무 깁니다!",
        415 => "지원되지 않는 미디어 유형!",
        416 => "범위를 만족시킬 수 없습니다!",
        417 => "기대(Expect) 조건을 충족하지 못했습니다!",
        418 => "나는 주전자입니다",
        421 => "잘못된 요청",
        422 => "처리할 수 없는 엔터티!",
        423 => "리소스가 잠겨 있습니다!",
        424 => "종속성이 실패했습니다!",
        425 => "너무 이른 요청!",
        426 => "업그레이드 필요!",
        428 => "전제조건 필요",
        429 => "요청이 너무 많습니다!",
        431 => "요청 헤더가 너무 큼!",
        444 => "응답없이 연결이 닫힘",
        451 => "법적 사유로 이용할 수 없습니다!",
        499 => "클라이언트가 요청을 닫음",
        500 => "서버 오류!",
        501 => "요청 처리 실패!",
        502 => "잘못된 게이트웨이!",
        503 => "서비스를 사용할 수 없음!",
        504 => "게이트웨이 시간 초과!",
        505 => "HTTP 버전이 지원되지 않음",
        506 => "변형도 변동합니다!",
        507 => "저장 공간 부족!",
        508 => "루프 감지됨!",
        509 => "대역폭 제한 초과",
        510 => "확장되지 않음",
        511 => "네트워크 인증 필요",
        599 => "네트워크 연결 시간초과 오류",
    },
    nb_NO => {
        100 => "Fortsett",
        101 => "Bytter protokoller",
        102 => "Behandler",
        103 => "Tidlige hint",
        200 => "OK",
        201 => "Opprettet",
        202 => "Akseptert",
        203 => "Ikke-autoritativ informasjon",
        204 => "Intet innhold",
        205 => "Tilbakestill innhold",
        206 => "Delvis innhold",
        207 => "Multi-status",
        208 => "Allerede rapportert",
        226 => "IM brukt",
        300 => "Flere valg",
        301 => "Flyttet permanent!",
        302 => "Funnet (midlertidig omdirigering)!",
        303 => "Se annet",
        304 => "Ikke endret",
        305 => "Bruk proxy",
        307 => "Midlertidig omdirigering!",
        308 => "Permanent omdirigering!",
        400 => "Ugyldig forespørsel!",
        401 => "Autentisering kreves!",
        402 => "Betaling kreves!",
        403 => "Adgang forbudt!",
        404 => "Objektet ble ikke funnet!",
        405 => "Metoden er ikke tillatt!",
        406 => "Ikke akseptabelt!",
        407 => "Proxy-autentisering kreves!",
        408 => "Tidsgrense overskredet!",
        409 => "Konflikt!",
        410 => "Ressursen er ikke lenger tilgjengelig!",
        411 => "Feil Content-Length!",
        412 => "Forutsetning ikke oppfylt!",
        413 => "Forespørselens innhold er for stort!",
        414 => "Forespurt URI for lang!",
        415 => "Mediatype støttes ikke!",
        416 => "Område ikke tilfredsstillbart!",
        417 => "Forventning kunne ikke oppfylles!",
        418 => "Jeg er en tekanne",
        421 => "Feiladressert forespørsel",
        422 => "Kan ikke behandle enheten!",
        423 => "Ressursen er låst!",
        424 => "Avhengighet feilet!",
        425 => "For tidlig!",
        426 => "Oppgradering kreves!",
        428 => "Forhåndsbetingelse kreves",
        429 => "For mange forespørsler!",
        431 => "Forespørselsheadere for store!",
        444 => "Tilkobling lukket uten svar",
        451 => "Ikke tilgjengelig av juridiske årsaker!",
        499 => "Forespørsel lukket av klient",
        500 => "Serverfeil!",
        501 => "Kan ikke behandle forespørsel!",
        502 => "Feil gateway!",
        503 => "Tjenesten er ikke tilgjengelig!",
        504 => "Tidsavbrudd i gateway!",
        505 => "HTTP-versjon ikke støttet",
        506 => "Varianten varierer også!",
        507 => "Utilstrekkelig lagringsplass!",
        508 => "Løkke oppdaget!",
        509 => "Båndbreddegrense overskredet",
        510 => "Ikke utvidet",
        511 => "Nettverksautentisering kreves",
        599 => "Tidsavbrudd for nettverkstilkobling",
    },
    nl_NL => {
        100 => "Doorgaan",
        101 => "Protocolwisseling",
        102 => "Verwerken",
        103 => "Vroege hints",
        200 => "OK",
        201 => "Aangemaakt",
        202 => "Geaccepteerd",
        203 => "Niet-gezaghebbende informatie",
        204 => "Geen inhoud",
        205 => "Inhoud herstellen",
        206 => "Gedeeltelijke inhoud",
        207 => "Multi-status",
        208 => "Reeds gerapporteerd",
        226 => "IM gebruikt",
        300 => "Meerdere keuzes",
        301 => "Permanent verplaatst!",
        302 => "Gevonden (tijdelijke omleiding)!",
        303 => "Zie andere",
        304 => "Niet gewijzigd",
        305 => "Proxy gebruiken",
        307 => "Tijdelijke omleiding!",
        308 => "Permanente omleiding!",
        400 => "Ongeldig verzoek!",
        401 => "Authenticatie vereist!",
        402 => "Betaling vereist!",
        403 => "Toegang verboden!",
        404 => "Object niet gevonden!",
        405 => "Methode niet toegestaan!",
        406 => "Niet acceptabel!",
        407 => "Proxy-authenticatie vereist!",
        408 => "Tijdlimiet overschreden!",
        409 => "Conflict!",
        410 => "Dit object is niet langer beschikbaar!",
        411 => "Ongeldige Content-Length!",
        412 => "Voorwaarde niet voldaan!",
        413 => "Aanvraaginhoud te groot!",
        414 => "Aangeboden URI te lang!",
        415 => "Niet-ondersteund mediatype!",
        416 => "Bereik niet te vervullen!",
        417 => "Expectation niet voldaan!",
        418 => "Ik ben een theepot",
        421 => "Verkeerd gerichte aanvraag",
        422 => "Niet-verwerkbare entiteit!",
        423 => "Bron vergrendeld!",
        424 => "Mislukte afhankelijkheid!",
        425 => "Te vroeg!",
        426 => "Upgrade vereist!",
        428 => "Voorwaarde vereist",
        429 => "Te veel verzoeken!",
        431 => "Verzoekheaders te groot!",
        444 => "Verbinding gesloten zonder antwoord",
        451 => "Niet beschikbaar om juridische redenen!",
        499 => "Aanvraag door cliënt gesloten",
        500 => "Serverfout!",
        501 => "Kan verzoek niet verwerken!",
        502 => "Verkeerde Gateway!",
        503 => "Dienst niet beschikbaar!",
        504 => "Gateway-time-out!",
        505 => "HTTP-versie niet ondersteund",
        506 => "Variant varieert ook!",
        507 => "Onvoldoende opslagruimte!",
        508 => "Lus gedetecteerd!",
        509 => "Bandbreedtelimiet overschreden",
        510 => "Niet uitgebreid",
        511 => "Netwerkauthenticatie vereist",
        599 => "Time-out bij netwerkverbinding",
    },
    pl_PL => {
        100 => "Kontynuuj",
        101 => "Zmiana protokołów",
        102 => "Przetwarzanie",
        103 => "Wczesne wskazówki",
        200 => "OK",
        201 => "Utworzono",
        202 => "Przyjęto",
        203 => "Informacja nieautorytatywna",
        204 => "Brak treści",
        205 => "Resetuj treść",
        206 => "Częściowa treść",
        207 => "Wiele statusów",
        208 => "Już zgłoszono",
        226 => "Użyto IM",
        300 => "Wiele możliwości",
        301 => "Trwale przeniesiono!",
        302 => "Znaleziono (tymczasowe przekierowanie)!",
        303 => "Zobacz inne",
        304 => "Nie zmodyfikowano",
        305 => "Użyj serwera proxy",
        307 => "Tymczasowe przekierowanie!",
        308 => "Stałe przekierowanie!",
        400 => "Nieprawidłowe żądanie!",
        401 => "Wymagane uwierzytelnienie!",
        402 => "Wymagana płatność!",
        403 => "Zabroniony dostęp!",
        404 => "Nie znaleziono obiektu!",
        405 => "Niedozwolona metoda!",
        406 => "Nieakceptowalne!",
        407 => "Wymagana autoryzacja proxy!",
        408 => "Przedawnione żądanie!",
        409 => "Konflikt!",
        410 => "Zasób usunięty!",
        411 => "Błędny nagłówek Content-Length!",
        412 => "Warunek wstępny niespełniony!",
        413 => "Treść żądania zbyt duża!",
        414 => "Zbyt długie URI!",
        415 => "Nieobsługiwany typ mediów!",
        416 => "Zakres nie do zrealizowania!",
        417 => "Oczekiwanie niespełnione!",
        418 => "Jestem czajniczkiem",
        421 => "Źle skierowane żądanie",
        422 => "Nieprzetwarzalna jednostka!",
        423 => "Zasób zablokowany!",
        424 => "Błędna zależność!",
        425 => "Zbyt wcześnie!",
        426 => "Wymagana aktualizacja!",
        428 => "Wymagany warunek wstępny",
        429 => "Zbyt wiele żądań!",
        431 => "Nagłówki żądania za duże!",
        444 => "Połączenie zamknięte bez odpowiedzi",
        451 => "Niedostępne z powodów prawnych!",
        499 => "Żądanie zamknięte przez klienta",
        500 => "Błąd serwera!",
        501 => "Żądanie nieobsługiwane!",
        502 => "Nieprawidłowa brama!",
        503 => "Serwis niedostępny!",
        504 => "Przekroczono limit czasu bramy!",
        505 => "Wersja HTTP nieobsługiwana",
        506 => "Wariant również się zmienia!",
        507 => "Niewystarczająca przestrzeń dyskowa!",
        508 => "Wykryto pętlę!",
        509 => "Przekroczono limit przepustowości",
        510 => "Nie rozszerzono",
        511 => "Wymagane uwierzytelnienie sieciowe",
        599 => "Przekroczono limit czasu połączenia sieciowego",
    },
    pt_BR => {
        100 => "Continuar",
        101 => "Mudando protocolos",
        102 => "Processando",
        103 => "Dicas iniciais",
        200 => "OK",
        201 => "Criado",
        202 => "Aceito",
        203 => "Informação não autoritativa",
        204 => "Sem conteúdo",
        205 => "Redefinir conteúdo",
        206 => "Conteúdo parcial",
        207 => "Multi-status",
        208 => "Já reportado",
        226 => "IM usado",
        300 => "Múltiplas escolhas",
        301 => "Movido permanentemente!",
        302 => "Encontrado (redirecionamento temporário)!",
        303 => "Ver outro",
        304 => "Não modificado",
        305 => "Usar proxy",
        307 => "Redirecionamento temporário!",
        308 => "Redirecionamento permanente!",
        400 => "Requisição inválida!",
        401 => "Autenticação necessária!",
        402 => "Pagamento necessário!",
        403 => "Acesso Proibido!",
        404 => "Objeto não encontrado!",
        405 => "Método não permitido!",
        406 => "Não aceitável!",
        407 => "Autenticação de proxy necessária!",
        408 => "Tempo excedido!",
        409 => "Conflito!",
        410 => "Recurso não está mais disponível!",
        411 => "Content-Length inválido!",
        412 => "Falha na pré-condição!",
        413 => "Volume de dados muito grande!",
        414 => "URI enviado é muito longo!",
        415 => "Tipo de mídia não suportado!",
        416 => "Intervalo não satisfatível!",
        417 => "Expectativa não atendida!",
        418 => "Eu sou um bule de chá",
        421 => "Requisição mal direcionada",
        422 => "Entidade não processável!",
        423 => "Recurso bloqueado!",
        424 => "Dependência falhou!",
        425 => "Cedo demais!",
        426 => "Atualização necessária!",
        428 => "Pré-condição necessária",
        429 => "Muitas requisições!",
        431 => "Cabeçalhos de requisição muito grandes!",
        444 => "Conexão fechada sem resposta",
        451 => "Indisponível por motivos legais!",
        499 => "Requisição fechada pelo cliente",
        500 => "Erro interno do Servidor!",
        501 => "A requisição não pode ser processada!",
        502 => "Gateway inválido!",
        503 => "Serviço indisponível!",
        504 => "Tempo esgotado do gateway!",
        505 => "Versão HTTP não suportada",
        506 => "A variante também varia!",
        507 => "Armazenamento insuficiente!",
        508 => "Loop detectado!",
        509 => "Limite de banda excedido",
        510 => "Não estendido",
        511 => "Autenticação de rede necessária",
        599 => "Erro de tempo de conexão de rede",
    },
    pt_PT => {
        100 => "Continuar",
        101 => "A mudar protocolos",
        102 => "A processar",
        103 => "Dicas iniciais",
        200 => "OK",
        201 => "Criado",
        202 => "Aceite",
        203 => "Informação não autoritativa",
        204 => "Sem conteúdo",
        205 => "Repor conteúdo",
        206 => "Conteúdo parcial",
        207 => "Multi-estado",
        208 => "Já reportado",
        226 => "IM usado",
        300 => "Várias opções",
        301 => "Movido permanentemente!",
        302 => "Encontrado (redirecionamento temporário)!",
        303 => "Ver outro",
        304 => "Não modificado",
        305 => "Usar proxy",
        307 => "Redirecionamento temporário!",
        308 => "Redirecionamento permanente!",
        400 => "Pedido incorreto!",
        401 => "Autenticação necessária!",
        402 => "Pagamento exigido!",
        403 => "Acesso proibido!",
        404 => "Objeto não encontrado!",
        405 => "Método não permitido!",
        406 => "Não aceitável!",
        407 => "Autenticação de proxy necessária!",
        408 => "Tempo excedido!",
        409 => "Conflito!",
        410 => "Recurso já não está disponível!",
        411 => "Content-Length incorreto!",
        412 => "Falha na pré-condição!",
        413 => "Volume de dados demasiado grande!",
        414 => "URI demasiado longo!",
        415 => "Tipo de média não suportado!",
        416 => "Intervalo não satisfazível!",
        417 => "Expectativa não satisfeita!",
        418 => "Sou um bule de chá",
        421 => "Pedido mal direcionado",
        422 => "Entidade não processável!",
        423 => "Recurso bloqueado!",
        424 => "Dependência falhou!",
        425 => "Demasiado cedo!",
        426 => "Atualização necessária!",
        428 => "Pré-condição necessária",
        429 => "Pedidos em excesso!",
        431 => "Cabeçalhos de pedido muito grandes!",
        444 => "Ligação fechada sem resposta",
        451 => "Indisponível por motivos legais!",
        499 => "Pedido fechado pelo cliente",
        500 => "Erro interno do servidor!",
        501 => "Não posso processar o pedido!",
        502 => "Gateway inválido!",
        503 => "Serviço indisponível!",
        504 => "Tempo excedido na gateway!",
        505 => "Versão HTTP não suportada",
        506 => "A variante também varia!",
        507 => "Armazenamento insuficiente!",
        508 => "Loop detetado!",
        509 => "Limite de largura de banda excedido",
        510 => "Não estendido",
        511 => "Autenticação de rede necessária",
        599 => "Erro de tempo limite de ligação de rede",
    },
    ro_RO => {
        100 => "Continuați",
        101 => "Schimbarea protocoalelor",
        102 => "Se procesează",
        103 => "Indicii timpurii",
        200 => "OK",
        201 => "Creat",
        202 => "Acceptat",
        203 => "Informații neautoritare",
        204 => "Fără conținut",
        205 => "Resetați conținutul",
        206 => "Conținut parțial",
        207 => "Multi-status",
        208 => "Deja raportat",
        226 => "IM utilizat",
        300 => "Mai multe opțiuni",
        301 => "Mutat permanent!",
        302 => "Găsit (redirecționare temporară)!",
        303 => "Vezi altele",
        304 => "Neschimbat",
        305 => "Utilizați proxy",
        307 => "Redirecționare temporară!",
        308 => "Redirecționare permanentă!",
        400 => "Cerere nevalidă!",
        401 => "Autentificare necesară!",
        402 => "Plata necesară!",
        403 => "Accesul interzis!",
        404 => "Obiectul nu a fost gasit!",
        405 => "Metodă nepermisă!",
        406 => "Inacceptabil!",
        407 => "Este necesară autentificarea prin proxy!",
        408 => "Time-out al cererii!",
        409 => "Conflict!",
        410 => "Resursa nu mai este disponibilă!",
        411 => "Content-Length invalid!",
        412 => "Precondiția a eșuat!",
        413 => "Entitatea cererii este prea mare!",
        414 => "URI-ul trimis este prea lung!",
        415 => "Tip de date nesuportat!",
        416 => "Interval nesatisfiabil!",
        417 => "Așteptarea nu a fost îndeplinită!",
        418 => "Sunt un ceainic",
        421 => "Cerere direcționată greșit",
        422 => "Entitate imposibil de procesat!",
        423 => "Resursa este blocată!",
        424 => "Dependență eșuată!",
        425 => "Prea devreme!",
        426 => "Actualizare necesară!",
        428 => "Precondiție necesară",
        429 => "Prea multe cereri!",
        431 => "Antete de cerere prea mari!",
        444 => "Conexiune închisă fără răspuns",
        451 => "Indisponibil din motive legale!",
        499 => "Cerere închisă de client",
        500 => "Eroare server!",
        501 => "Cererea nu poate fi procesată!",
        502 => "Gateway invalid!",
        503 => "Serviciu indisponibil!",
        504 => "Depășire de timp a gateway-ului!",
        505 => "Versiune HTTP nesuportată",
        506 => "Varianta variază, de asemenea!",
        507 => "Spațiu de stocare insuficient!",
        508 => "Buclă detectată!",
        509 => "Limită de lățime de bandă depășită",
        510 => "Neextins",
        511 => "Autentificare de rețea necesară",
        599 => "Eroare: expirare timp conexiune la rețea",
    },
    # Ref: <https://ru.wikipedia.org/wiki/%D0%A1%D0%BF%D0%B8%D1%81%D0%BE%D0%BA_%D0%BA%D0%BE%D0%B4%D0%BE%D0%B2_%D1%81%D0%BE%D1%81%D1%82%D0%BE%D1%8F%D0%BD%D0%B8%D1%8F_HTTP>
    # <https://developer.roman.grinyov.name/blog/80>
    ru_RU => {
        100 => "продолжай",
        101 => "переключение протоколов",
        102 => "идёт обработка",
        103 => "ранняя метаинформация",
        200 => "хорошо",
        201 => "создано",
        202 => "принято",
        203 => "информация не авторитетна",
        204 => "нет содержимого",
        205 => "сбросить содержимое",
        206 => "частичное содержимое",
        207 => "многостатусный",
        208 => "уже сообщалось",
        226 => "использовано IM",
        300 => "множество выборов",
        301 => "Перемещено навсегда!",
        302 => "Найдено (временное перенаправление)!",
        303 => "смотреть другое",
        304 => "не изменялось",
        305 => "использовать прокси",
        307 => "Временное перенаправление!",
        308 => "Постоянное перенаправление!",
        400 => "Неверный запрос!",
        401 => "Необходима аутентификация!",
        402 => "Требуется оплата!",
        403 => "Доступ запрещён!",
        404 => "Объект не найден!",
        405 => "Метод не поддерживается!",
        406 => "Неприемлемо!",
        407 => "Требуется аутентификация прокси!",
        408 => "Истекло время ожидания!",
        409 => "Конфликт!",
        410 => "Документ удалён!",
        411 => "Неверный заголовок Content-Length!",
        412 => "Предусловие не выполнено!",
        413 => "Размер запроса слишком велик!",
        414 => "URI слишком длинный!",
        415 => "Неподдерживаемый тип медиа!",
        416 => "Диапазон не может быть удовлетворён!",
        417 => "Ожидание не выполнено!",
        418 => "я — чайник",
        421 => "Неверно адресованный запрос",
        422 => "Необрабатываемая сущность!",
        423 => "Ресурс заблокирован!",
        424 => "Сбой зависимости!",
        425 => "Слишком рано!",
        426 => "Требуется обновление!",
        428 => "необходимо предусловие",
        429 => "Слишком много запросов!",
        431 => "Заголовки запроса слишком велики!",
        444 => "Соединение закрыто без ответа",
        451 => "Недоступно по юридическим причинам!",
        499 => "клиент закрыл соединение",
        500 => "Ошибка сервера!",
        501 => "Запрос не может быть обработан!",
        502 => "Неверный шлюз!",
        503 => "Сервис недоступен!",
        504 => "Тайм-аут шлюза!",
        505 => "версия HTTP не поддерживается",
        506 => "Вариант также меняется!",
        507 => "Недостаточно памяти для хранения!",
        508 => "Обнаружен цикл!",
        509 => "исчерпана пропускная ширина канала",
        510 => "не расширено",
        511 => "требуется сетевая аутентификация",
        599 => "Ошибка тайм-аута сетевого подключения",
    },
    sr_RS => {
        100 => "Настави",
        101 => "Промена протокола",
        102 => "Обрада у току",
        103 => "Рани наговештаји",
        200 => "У реду",
        201 => "Креирано",
        202 => "Прихваћено",
        203 => "Неауторитативне информације",
        204 => "Нема садржаја",
        205 => "Ресет садржаја",
        206 => "Делимичан садржај",
        207 => "Вишестатус",
        208 => "Већ пријављено",
        226 => "ИМ коришћен",
        300 => "Више избора",
        301 => "Трајно премештено!",
        302 => "Пронађено (привремено преусмеравање)!",
        303 => "Погледај друго",
        304 => "Није измењено",
        305 => "Користи прокси",
        307 => "Привремено преусмеравање!",
        308 => "Трајно преусмеравање!",
        400 => "Лош захтев!",
        401 => "Обавезна аутентификација!",
        402 => "Потребно плаћање!",
        403 => "Забрањен приступ!",
        404 => "Објекат није пронађен!",
        405 => "Метод није дозвољен!",
        406 => "Неприхватљиво!",
        407 => "Потребна је прокси аутентикација!",
        408 => "Захтеву је истекло време!",
        409 => "Сукоб!",
        410 => "Ресурс није више доступан!",
        411 => "Неисправно Content-Length заглавље!",
        412 => "Предуслов није испуњен!",
        413 => "Тело захтева је превелико!",
        414 => "Послати УРИ је предугачак!",
        415 => "Неподржана врста медија!",
        416 => "Опсег није могуће испунити!",
        417 => "Очекивање није испуњено!",
        418 => "Ја сам чајник",
        421 => "Погрешно усмерен захтев",
        422 => "Необрадив ентитет!",
        423 => "Ресурс је закључан!",
        424 => "Неуспела зависност!",
        425 => "Прерано!",
        426 => "Потребна надоградња!",
        428 => "Потребан предуслов",
        429 => "Превише захтева!",
        431 => "Заглавља захтева су превелика!",
        444 => "Веза затворена без одговора",
        451 => "Недоступно из правних разлога!",
        499 => "Клијент је затворио захтев",
        500 => "Грешка сервера!",
        501 => "Не могу да обрадим захтев!",
        502 => "Лош пролаз!",
        503 => "Услуга је недоступна!",
        504 => "Истекло време пролаза (gateway)!",
        505 => "HTTP верзија није подржана",
        506 => "Варијанта такође варира!",
        507 => "Недовољно простора за складиштење!",
        508 => "Откривена петља!",
        509 => "Превазиђено ограничење пропусног опсега",
        510 => "Није проширено",
        511 => "Потребна мрежна аутентификација",
        599 => "Грешка: истек времена на мрежној вези",
    },
    sv_SE => {
        100 => "Fortsätt",
        101 => "Växlar protokoll",
        102 => "Bearbetar",
        103 => "Tidiga tips",
        200 => "OK",
        201 => "Skapad",
        202 => "Accepterad",
        203 => "Icke-auktoritativ information",
        204 => "Inget innehåll",
        205 => "Återställ innehåll",
        206 => "Partiellt innehåll",
        207 => "Multi-status",
        208 => "Redan rapporterat",
        226 => "IM används",
        300 => "Flera val",
        301 => "Flyttad permanent!",
        302 => "Hittad (tillfällig omdirigering)!",
        303 => "Se annat",
        304 => "Inte ändrad",
        305 => "Använd proxy",
        307 => "Tillfällig omdirigering!",
        308 => "Permanent omdirigering!",
        400 => "Felaktig förfrågan!",
        401 => "Autentisering krävs!",
        402 => "Betalning krävs!",
        403 => "Åtkomst förbjuden!",
        404 => "Objektet hittas ej!",
        405 => "Metoden inte tillåten!",
        406 => "Inte acceptabelt!",
        407 => "Proxyautentisering krävs!",
        408 => "Tidsgränsen överskreds!",
        409 => "Konflikt!",
        410 => "Resursen är inte längre tillgänglig!",
        411 => "Felaktig Content-Length!",
        412 => "Förhandsvillkor uppfylldes inte!",
        413 => "Begärans innehåll är för stort!",
        414 => "Efterfrågad URI för lång!",
        415 => "Mediatypen stöds ej!",
        416 => "Begärt intervall kan inte tillgodoses!",
        417 => "Förväntan uppfylldes inte!",
        418 => "Jag är en tekanna",
        421 => "Feladresserad begäran",
        422 => "Obehandlingsbar enhet!",
        423 => "Resursen är låst!",
        424 => "Misslyckat beroende!",
        425 => "För tidigt!",
        426 => "Uppgradering krävs!",
        428 => "Förhandsvillkor krävs",
        429 => "För många förfrågningar!",
        431 => "Begäransrubriker för stora!",
        444 => "Anslutning stängd utan svar",
        451 => "Otillgänglig av juridiska skäl!",
        499 => "Begäran stängd av klienten",
        500 => "Serverfel!",
        501 => "Kan inte behandla begäran!",
        502 => "Felaktig Gateway!",
        503 => "Tjänsten ej tillgänglig!",
        504 => "Tidsgräns i gateway överskreds!",
        505 => "HTTP-version stöds inte",
        506 => "Varianten varierar också!",
        507 => "Otillräckligt lagringsutrymme!",
        508 => "Loop upptäckt!",
        509 => "Bandbreddsgräns överskriden",
        510 => "Inte utökad",
        511 => "Nätverksautentisering krävs",
        599 => "Tidsgräns för nätverksanslutning överskreds",
    },
    tr_TR => {
        100 => "Devam et",
        101 => "Protokoller değiştiriliyor",
        102 => "İşleniyor",
        103 => "Erken ipuçları",
        200 => "Tamam",
        201 => "Oluşturuldu",
        202 => "Kabul edildi",
        203 => "Yetkili olmayan bilgi",
        204 => "İçerik yok",
        205 => "İçeriği sıfırla",
        206 => "Kısmi içerik",
        207 => "Çoklu durum",
        208 => "Zaten bildirildi",
        226 => "IM kullanıldı",
        300 => "Birden çok seçenek",
        301 => "Kalıcı olarak taşındı!",
        302 => "Bulundu (geçici yönlendirme)!",
        303 => "Başka bir yere bakın",
        304 => "Değiştirilmedi",
        305 => "Vekil sunucu kullan",
        307 => "Geçici yönlendirme!",
        308 => "Kalıcı yönlendirme!",
        400 => "Hatalı istek!",
        401 => "Kimlik doğrulama gerekli!",
        402 => "Ödeme gerekli!",
        403 => "Erişim engellendi!",
        404 => "Nesne mevcut değil!",
        405 => "Yönteme izin verilmedi!",
        406 => "Kabul edilemez!",
        407 => "Vekil sunucu kimlik doğrulaması gerekli!",
        408 => "İstekte zaman aşımı!",
        409 => "Çakışma!",
        410 => "Kaynak artık mevcut değil!",
        411 => "Hatalı Content-Length başlığı!",
        412 => "Önkoşul karşılanamadı!",
        413 => "İstek gövdesi çok büyük!",
        414 => "Gönderilen URI çok uzun!",
        415 => "Desteklenmeyen ortam türü!",
        416 => "Aralık karşılanamaz!",
        417 => "Beklenti karşılanamadı!",
        418 => "Ben bir çaydanlığım",
        421 => "Yanlış yönlendirilmiş istek",
        422 => "İşlenemeyen varlık!",
        423 => "Kaynak kilitlendi!",
        424 => "Bağımlılık başarısız!",
        425 => "Çok erken!",
        426 => "Yükseltme gerekli!",
        428 => "Önkoşul gerekli",
        429 => "Çok fazla istek!",
        431 => "İstek başlıkları çok büyük!",
        444 => "Yanıt verilmeden bağlantı kapatıldı",
        451 => "Hukuki nedenlerle kullanılamıyor!",
        499 => "İstek istemci tarafından kapatıldı",
        500 => "Sunucu hatası!",
        501 => "İstek yerine getirilemiyor!",
        502 => "Hatalı Ağ Geçidi!",
        503 => "Hizmet sunulamıyor!",
        504 => "Ağ geçidi zaman aşımı!",
        505 => "HTTP sürümü desteklenmiyor",
        506 => "Varyant da değişiyor!",
        507 => "Yetersiz depolama alanı!",
        508 => "Döngü tespit edildi!",
        509 => "Bant genişliği sınırı aşıldı",
        510 => "Genişletilmemiş",
        511 => "Ağ kimlik doğrulaması gerekli",
        599 => "Ağ bağlantısı zaman aşımı hatası",
    },
    # Ref: <https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status>
    # <https://www.websiterating.com/zh-CN/resources/http-status-codes-cheat-sheet/>
    # <https://zh.wikipedia.org/wiki/HTTP%E7%8A%B6%E6%80%81%E7%A0%81>
    # <https://learn.microsoft.com/zh-cn/onedrive/developer/rest-api/concepts/errors?view=odsp-graph-online>
    # <https://tinychen.com/20200717-http-code-introduction/>
    zh_CN => {
        100 => "继续",
        101 => "切换协议",
        102 => "处理中",
        103 => "早期提示",
        200 => "OK",
        201 => "创建",
        202 => "已接受",
        203 => "非权威信息",
        204 => "无内容",
        205 => "重置内容",
        206 => "部分内容",
        207 => "多状态",
        208 => "已报告",
        226 => "IM已使用",
        300 => "多项选择",
        301 => "已永久移动！",
        302 => "已找到（临时重定向）！",
        303 => "查看其他",
        304 => "未修改",
        305 => "使用代理",
        307 => "临时重定向！",
        308 => "永久重定向！",
        400 => "无效请求！",
        401 => "需要认证！",
        402 => "需要付款！",
        403 => "禁止访问！",
        404 => "找不到对象！",
        405 => "请求的方法不允许！",
        406 => "不可接受！",
        407 => "需要代理身份验证！",
        408 => "请求超时！",
        409 => "冲突！",
        410 => "资源不再可用！",
        411 => "无效的 Content-Length！",
        412 => "先决条件未满足！",
        413 => "请求体过大！",
        414 => "提交的 URI 过长！",
        415 => "不支持的媒体类型！",
        416 => "范围无法满足！",
        417 => "未能满足请求期望！",
        418 => "我是一个茶壶",
        421 => "错误定向的请求",
        422 => "无法处理的实体！",
        423 => "资源已锁定！",
        424 => "依赖失败！",
        425 => "为时过早！",
        426 => "需要升级！",
        428 => "需要前提条件",
        429 => "请求过多！",
        431 => "请求头字段过大！",
        444 => "连接关闭没有响应",
        451 => "因法律原因无法提供！",
        499 => "客户关闭请求",
        500 => "服务器错误！",
        501 => "无法执行请求！",
        502 => "错误的网关！",
        503 => "服务不可用！",
        504 => "网关超时！",
        505 => "不支持的HTTP版本",
        506 => "变体也会变化！",
        507 => "存储空间不足！",
        508 => "检测到循环！",
        509 => "超出带宽限制",
        510 => "未扩展",
        511 => "需要网络身份验证",
        599 => "网络连接超时错误",
    },
    # Ref: <https://zh.wikipedia.org/zh-tw/HTTP%E7%8A%B6%E6%80%81%E7%A0%81>
    # <https://developer.mozilla.org/zh-TW/docs/Web/HTTP/Status>
    # <https://www.websitehostingrating.com/zh-TW/http-status-codes-cheat-sheet/>
    zh_TW => {
        100 => "繼續",
        101 => "交換協議",
        102 => "處理",
        103 => "早期提示",
        200 => "OK",
        201 => "已創建",
        202 => "已收到請求",
        203 => "非權威信息",
        204 => "沒有內容",
        205 => "重設內容",
        206 => "部分內容",
        207 => "多重狀態",
        208 => "已報告",
        226 => "使用了IM",
        300 => "多重選擇",
        301 => "已永久移動！",
        302 => "已找到（臨時重新導向）！",
        303 => "查看其他",
        304 => "未修改",
        305 => "使用代理",
        307 => "臨時重新導向！",
        308 => "永久重新導向！",
        400 => "請求錯誤！",
        401 => "需要認證！",
        402 => "需要付款！",
        403 => "禁止訪問！",
        404 => "找不到物件！",
        405 => "請求的方法不允許！",
        406 => "不可接受！",
        407 => "需要代理伺服器驗證！",
        408 => "請求超時！",
        409 => "衝突！",
        410 => "資源不再可用！",
        411 => "無效的 Content-Length！",
        412 => "先決條件未滿足！",
        413 => "請求體過大！",
        414 => "提交的 URI 過長！",
        415 => "不支援的媒體型式！",
        416 => "無法滿足請求範圍！",
        417 => "未能滿足請求期望！",
        418 => "我是茶壺",
        421 => "錯誤定向的請求",
        422 => "無法處理的實體！",
        423 => "資源已鎖定！",
        424 => "相依關係失敗！",
        425 => "時機過早！",
        426 => "需要升級！",
        428 => "需要先決條件",
        429 => "請求過多！",
        431 => "請求標頭欄位過大！",
        444 => "連接關閉而沒有響應",
        451 => "因法律因素無法提供！",
        499 => "用戶端關閉請求",
        500 => "伺服器錯誤！",
        501 => "無法執行請求！",
        502 => "閘道器錯誤！",
        503 => "服務不可用！",
        504 => "閘道逾時！",
        505 => "不支持HTTP版本",
        506 => "變體也會變化！",
        507 => "儲存空間不足！",
        508 => "偵測到循環！",
        509 => "超過帶寬限制",
        510 => "未擴展",
        511 => "需要網路驗證",
        599 => "網絡連接超時錯誤",
    },
};
our $MAP_LANG_SHORT =
{
de		=> 'de_DE',
en		=> 'en_GB',
fr		=> 'fr_FR',
it		=> 'it_IT',
ja		=> 'ja_JP',
ko      => 'ko_KR',
nl      => 'nl_NL',
pl      => 'pl_PL',
pt      => 'pt_PT',
ro      => 'ro_RO',
ru      => 'ru_RU',
'tr'    => 'tr_TR',
zh		=> 'zh_TW',
};

# So that querying the hash directly with $HTTP_CODES->{ja} works too
foreach my $lang ( keys( %$MAP_LANG_SHORT ) )
{
    $HTTP_CODES->{ $lang } = $HTTP_CODES->{ $MAP_LANG_SHORT->{ $lang } };
}

our $STATUS_TO_TYPE =
{
    301 => "moved_permanently",
    302 => "moved_temporarily",
    307 => "redirect_temporarily",
    308 => "redirect_permanent",
    400 => "bad_request",
    401 => "unauthorized",
    402 => "payment_required",
    403 => "forbidden",
    404 => "not_found",
    405 => "method_not_allowed",
    406 => "not_acceptable",
    407 => "proxy_authentication_required",
    408 => "request_time_out",
    409 => "conflict",
    410 => "gone",
    411 => "length_required",
    412 => "precondition_failed",
    413 => "request_entity_too_large",
    414 => "request_uri_too_large",
    415 => "unsupported_media_type",
    416 => "range_not_satisfiable",
    417 => "expectation_failed",
    422 => "unprocessable_entity",
    423 => "locked",
    424 => "failed_dependency",
    425 => "too_early",
    426 => "upgrade_required",
    429 => "too_many_requests",
    431 => "request_header_fields_too_large",
    451 => "unavailable_for_legal_reasons",
    500 => "internal_server_error",
    501 => "not_implemented",
    502 => "bad_gateway",
    503 => "service_unavailable",
    504 => "gateway_timeout",
    505 => "http_version_not_supported",
    506 => "variant_also_varies",
    507 => "insufficient_storage",
    508 => "loop_detected",
};

# Missing constants in Apache2::Const
my $additions =
{
103 => 'EARLY_HINTS',
418 => 'I_AM_A_TEA_POT',
421 => 'MISDIRECTED_REQUEST',
425 => 'TOO_EARLY',
444 => 'CONNECTION_CLOSED_WITHOUT_RESPONSE',
451 => 'UNAVAILABLE_FOR_LEGAL_REASONS',
499 => 'CLIENT_CLOSED_REQUEST',
505 => 'HTTP_VERSION_NOT_SUPPORTED',
509 => 'BANDWIDTH_LIMIT_EXCEEDED',
599 => 'NETWORK_CONNECT_TIMEOUT_ERROR',
};

foreach my $code ( keys( %$additions ) )
{
    unless( Apache2::Const->can( $additions->{ $code } ) )
    {
        eval( "*Apache2::Const::" . $additions->{ $code } . " = sub{$code};" );
        warn( "Error adding Apache2::Const for HTTP code $code: $@" ) if( $@ );
    }
}

sub init
{
    my $self = shift( @_ );
    my $r = shift( @_ );
    $self->SUPER::init( @_ );
    return( $self );
}

sub convert_short_lang_to_long
{
	my $self = shift( @_ );
	my $lang = shift( @_ );
	# Nothing to do; we already have a good value
	return( $lang ) if( $lang =~ /^[a-z]{2}_[A-Z]{2}$/ );
	return( $MAP_LANG_SHORT->{ lc( $lang ) } ) if( CORE::exists( $MAP_LANG_SHORT->{ lc( $lang ) } ) );
	return( '' );
}

sub is_cacheable_by_default
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    return( $self->error( "A 3 digit code is required." ) ) if( !defined( $code ) || $code !~ /^\d{3}$/ );
    return(
           $code == 200 # OK
        || $code == 203 # Non-Authoritative Information
        || $code == 204 # No Content
        || $code == 206 # Not Acceptable
        || $code == 300 # Multiple Choices
        || $code == 301 # Moved Permanently
        || $code == 308 # Permanent Redirect
        || $code == 404 # Not Found
        || $code == 405 # Method Not Allowed
        || $code == 410 # Gone
        || $code == 414 # Request-URI Too Large
        || $code == 451 # Unavailable For Legal Reasons
        || $code == 501 # Not Implemented
    );
}

sub is_client_error { return( shift->_min_max( 400 => 500, @_ ) ); }

sub is_error { return( shift->_min_max( 400 => 600, @_ ) ); }

sub is_info { return( shift->_min_max( 100 => 200, @_ ) ); }

sub is_redirect { return( shift->_min_max( 300 => 400, @_ ) ); }

sub is_server_error { return( shift->_min_max( 500 => 600, @_ ) ); }

sub is_success { return( shift->_min_max( 200 => 300, @_ ) ); }

sub status_to_type
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    my $sep  = shift( @_ );
    if( !defined( $sep ) ||
        ( defined( $sep ) && $sep eq '_' ) )
    {
        return( $STATUS_TO_TYPE->{ $code } );
    }
    ( my $type = $STATUS_TO_TYPE->{ $code } ) =~ s/_/$sep/;
    return( $type );
}

# Returns a status line for a given code
# e.g. status_message( 404 ) would yield "Not found"
sub status_message
{
    my $self = shift( @_ );
    my( $code, $lang );
    if( scalar( @_ ) == 2 )
    {
        ( $code, $lang ) = @_;
    }
    else
    {
        $code = shift( @_ );
        $lang = 'en_GB';
    }
    $lang = 'en_GB' if( !exists( $HTTP_CODES->{ $lang } ) );
    my $ref = $HTTP_CODES->{ $lang };
    return( $ref->{ $code } );
}

sub supported_languages
{
    my $self = shift( @_ );
    return( [sort( keys( %$HTTP_CODES ) )] );
}

sub _min_max
{
    my $this = shift( @_ );
    my( $min, $max, $code ) = @_;
    return( $this->error( "A 3 digit code is required." ) ) if( !defined( $code ) || $code !~ /^\d{3}$/ );
    return( $code >= $min && $code < $max );
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

Apache2::API::Status - Apache2 Status Codes

=head1 SYNOPSIS

    use Apache2::API::Status ':common';
    use Apache2::API::Status ':all';
    say Apache2::API::Status::HTTP_TOO_MANY_REQUESTS;
    # returns code 429


    use Apache2::API::Status;
    # in German: Zu viele Anfragen
    say $Apache2::API::Status::HTTP_CODES->{de_DE}->{429};
    # same
    say $Apache2::API::Status::HTTP_CODES->{de}->{429};
    # In English: Too Many Requests
    say $Apache2::API::Status::HTTP_CODES->{en_GB}->{429};
    # same
    say $Apache2::API::Status::HTTP_CODES->{en}->{429};
    # in French: Trop de requête
    say $Apache2::API::Status::HTTP_CODES->{fr_FR}->{429};
    # same
    say $Apache2::API::Status::HTTP_CODES->{fr}->{429};
    # In Japanese: リクエスト過大で拒否した
    say $Apache2::API::Status::HTTP_CODES->{ja_JP}->{429};
    # same
    say $Apache2::API::Status::HTTP_CODES->{ja}->{429};
    # In Korean: 너무 많은 요청
    say $Apache2::API::Status::HTTP_CODES->{ko_KR}->{429};
    # same
    say $Apache2::API::Status::HTTP_CODES->{ko}->{429};
    # In Russian: слишком много запросов
    say $Apache2::API::Status::HTTP_CODES->{ru_RU}->{429};
    # same
    say $Apache2::API::Status::HTTP_CODES->{ru}->{429};
    # In simplified Chinese: 太多请求
    say $Apache2::API::Status::HTTP_CODES->{zh_CN}->{429};
    # In Taiwanese (traditional) Chinese: 太多請求
    say $Apache2::API::Status::HTTP_CODES->{zh_TW}->{429};

But maybe more simply:

    my $status = Apache2::API::Status->new;
    say $status->status_message( 429 => 'ja_JP' );
    # Or without the language code parameter, it will default to en_GB
    say $status->status_message( 429 );

    # Is success
    say $status->is_info( 102 ); # true
    say $status->is_success( 200 ); # true
    say $status->is_redirect( 302 ); # true
    say $status->is_error( 404 ); # true
    say $status->is_client_error( 403 ); # true
    say $status->is_server_error( 501 ); # true

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module allows to get the localised version of the HTTP status for a given code for currently supported languages: fr_FR (French), en_GB (British English) and ja_JP (Japanese), de_DE (German), ko_KR (Korean), ru_RU (Russian), zh_CN (simplified Chinese), zh_TW (Taiwanese).

It also provides some functions to check if a given code is an information, success, redirect, error, client error or server error code.

It provides a full set of constants to use and import.

Finally, it adds a few more C<Apache2::Const>. See L</CONSTANTS> below.

=head1 METHODS

=head2 init

Creates an instance of L<Apache2::API::Status> and returns the object.

=head2 convert_short_lang_to_long

Given a 2 characters language code (not case sensitive) and this will return its iso 639 5 characters equivalent for supported languages.

For example:

    Apache2::API::Status->convert_short_lang_to_long( 'zh' );
    # returns: zh_TW

=head2 is_cacheable_by_default

Return true if the 3-digits code provided indicates that a response is cacheable by default, and it can be reused by a cache with heuristic expiration. All other status codes are not cacheable by default. See L<RFC 7231 - HTTP/1.1 Semantics and Content, Section 6.1. Overview of Status Codes|https://tools.ietf.org/html/rfc7231#section-6.1>.

=head2 is_client_error

Returns true if the 3-digits code provided is between 400 and 500

=head2 is_error

Returns true if the 3-digits code provided is between 400 and 600

=head2 is_info

Returns true if the 3-digits code provided is between 100 and 200

=head2 is_redirect

Returns true if the 3-digits code provided is between 300 and 400

=head2 is_server_error

Returns true if the 3-digits code provided is between 500 and 600

=head2 is_success

Returns true if the 3-digits code provided is between 200 and 300

=head2 status_message

Provided with a 3-digits HTTP code and an optional language code such as C<en_GB> and this will return the status message in its localised form.

This is useful to provide response to error in the user preferred language. L<Apache2::API/reply> uses it to set a json response with the HTTP error code along with a localised status message.

If no language code is provided, this will default to C<en_GB>.

See L</supported_languages> for the supported languages.

=head2 supported_languages

This will return a sorted array reference of support languages for status codes.

The following language codes are currently supported: de_DE (German), en_GB (British English), fr_FR (French), ja_JP (Japanese), ko_KR (Korean), ru_RU (Russian) and zh_TW (Traditional Chinese as spoken in Taiwan).

Feel free to contribute those codes in other languages.

=head1 CONSTANTS

The following constants can be exported. You can use the C<:all> tag to export them all, such as:

    use Apache2::API::Status qw( :all );

or you can use the tag C<:common> to export the following common status codes:

    HTTP_NETWORK_AUTHENTICATION_REQUIRED
    HTTP_FORBIDDEN
    HTTP_NOT_FOUND
    HTTP_OK
    HTTP_TEMPORARY_REDIRECT
    HTTP_INTERNAL_SERVER_ERROR

=head2 HTTP_CONTINUE (100)

See L<rfc 7231, section 5.1.1|https://tools.ietf.org/html/rfc7231#section-5.1.1> and section L<6.2.1|https://tools.ietf.org/html/rfc7231#section-6.2.1> and L<Mozilla docs|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/100>

This is provisional response returned by the web server upon an abbreviated request to find out whether the web server will accept the actual request. For example when the client is sending a large file in chunks, such as in C<PUT> request (here a 742MB file):

    PUT /some//big/file.mp4 HTTP/1.1
    Host: www.example.org
    Content-Type: video/mp4
    Content-Length: 778043392
    Expect: 100-continue

If the server refused, it could return a C<413 Request Entity Too Large> or C<405 Method Not Allowed> or even C<401 Unauthorized>, or even a C<417 Expectation Failed> if it does not support this feature.

A response C<417 Expectation Failed> means the server is likely a HTTP/1.0 server or does not understand the request and the actual request must be sent, i.e. without the header field C<Expect: 100-continue>

In some REST API implementation, the server response code C<417> is used to mean the server understood the requested, but rejected it. This is a divergent use of the original purpose of this code.

=head2 HTTP_SWITCHING_PROTOCOLS (101)

See L<rfc7231, section 6.2.2|https://tools.ietf.org/html/rfc7231#section-6.2.2>

This is used to indicate that the TCP conncection is switching to a different protocol.

This is typically used for the L<WebSocket> protocol, which uses initially a HTTP handshake when establishing the connection. For example:

    GET /chat HTTP/1.1
    Host: server.example.com
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
    Origin: http://example.com
    Sec-WebSocket-Protocol: chat, superchat
    Sec-WebSocket-Version: 13

Then the server could reply something like:

    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
    Sec-WebSocket-Protocol: chat

=head2 HTTP_PROCESSING (102)

See L<rfc 2518 on WebDAV|https://tools.ietf.org/html/rfc2518>

This is returned to notify the client that the server is currently processing the request and that it is taking some time.

The server could return repeated instance of this response code until it is done processing the request and then send back the actual final response headers.

=head2 HTTP_EARLY_HINTS (103)

See L<rfc 8297 on Indicating Hints|https://tools.ietf.org/html/rfc8297>

This is a preemptive return code to notify the client to make some optimisations, while the actual final response headers are sent later. For example:

    HTTP/1.1 103 Early Hints
    Link: </style.css>; rel=preload; as=style
    Link: </script.js>; rel=preload; as=script

then, a few seconds, or minutes later:

    HTTP/1.1 200 OK
    Date: Mon, 16 Apr 2022 02:15:12 GMT
    Content-Length: 1234
    Content-Type: text/html; charset=utf-8
    Link: </style.css>; rel=preload; as=style
    Link: </script.js>; rel=preload; as=script

=head2 HTTP_OK (200)

See L<rfc7231, section 6.3.1|https://datatracker.ietf.org/doc/html/rfc7231#section-6.3.1>

This is returned to inform the request has succeeded. It can also alternatively be C<204 No Content> when there is no response body.

For example:

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    Content-Length: 184
    Connection: keep-alive
    Cache-Control: s-maxage=300, public, max-age=0
    Content-Language: en-US
    Date: Mon, 18 Apr 2022 17:37:18 GMT
    ETag: "2e77ad1dc6ab0b53a2996dfd4653c1c3"
    Server: Apache/2.4
    Strict-Transport-Security: max-age=63072000
    X-Content-Type-Options: nosniff
    X-Frame-Options: DENY
    X-XSS-Protection: 1; mode=block
    Vary: Accept-Encoding,Cookie
    Age: 7

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>A simple webpage</title>
    </head>
    <body>
      <h1>Simple HTML5 webpage</h1>
      <p>Hello, world!</p>
    </body>
    </html>

=head2 HTTP_CREATED (201)

See L<rfc7231, section 6.3.2|https://datatracker.ietf.org/doc/html/rfc7231#section-6.3.2>

This is returned to notify the related resource has been created, most likely by a C<PUT> request, such as:

    PUT /some/where HTTP/1.1
    Content-Type: text/html
    Host: example.org

Then, the server would reply:

    HTTP/1.1 201 Created
    ETag: "foo-bar"

=head2 HTTP_ACCEPTED (202)

See L<rfc7231, section 6.3.3|https://tools.ietf.org/html/rfc7231#section-6.3.3>

This is returned when the web server has accepted the request, without guarantee of successful completion.

Thus, the remote service would typically send an email to inform the user of the status, or maybe provide a link in the header. For example:

    POST /some/where HTTP/1.1
    Content-Type: application/json

Then the server response:

    HTTP/1.1 202 Accepted
    Link: </some/status/1234> rel="https://example.org/status"
    Content-Length: 0

=head2 HTTP_NON_AUTHORITATIVE (203)

See L<rfc 7231, section 6.3.4|https://tools.ietf.org/html/rfc7231#section-6.3.4>

This would typically be returned by an HTTP proxy after it has made some change to the content.

=head2 HTTP_NO_CONTENT (204)

L<See rfc 7231, section 6.3.5|https://tools.ietf.org/html/rfc7231#section-6.3.5>

This is returned when the request was processed successfully, but there is no body content returned.

=head2 HTTP_RESET_CONTENT (205)

L<See rfc 7231, section 6.3.6|https://tools.ietf.org/html/rfc7231#section-6.3.6>

This is to inform the client the request was successfully processed and the content should be reset, like a web form.

=head2 HTTP_PARTIAL_CONTENT (206)

See L<rfc 7233 on Range Requests|https://tools.ietf.org/html/rfc7233>

This is returned in response to a request for partial content, such as a certain number of bytes from a video. For example:

    GET /video.mp4 HTTP/1.1
    Range: bytes=1048576-2097152

Then, the server would reply something like:

    HTTP/1.1 206 Partial Content
    Content-Range: bytes 1048576-2097152/3145728
    Content-Type: video/mp4

=head2 HTTP_MULTI_STATUS (207)

See L<rfc 4918 on WebDAV|https://tools.ietf.org/html/rfc4918>

This is returned predominantly under the WebDav protocol, when multiple operations occurred. For example:

    HTTP/1.1 207 Multi-Status
    Content-Type: application/xml; charset="utf-8"
    Content-Length: 637

    <d:multistatus xmlns:d="DAV:">
        <d:response>
            <d:href>/calendars/johndoe/home/132456762153245.ics</d:href>
            <d:propstat>
                <d:prop>
                    <d:getetag>"xxxx-xxx"</d:getetag>
                </d:prop>
                <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
        </d:response>
        <d:response>
            <d:href>/calendars/johndoe/home/fancy-caldav-client-1234253678.ics</d:href>
            <d:propstat>
                <d:prop>
                    <d:getetag>"5-12"</d:getetag>
                </d:prop>
                <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
        </d:response>
    </d:multistatus>

=head2 HTTP_ALREADY_REPORTED (208)

See L<rfc 5842, section 7.1 on WebDAV bindings|https://tools.ietf.org/html/rfc5842#section-7.1>

This is returned predominantly under the WebDav protocol.

=head2 HTTP_IM_USED (226)

See L<rfc 3229 on Delta encoding|https://tools.ietf.org/html/rfc3229>

C<IM> stands for C<Instance Manipulation>.

This is an HTTP protocol extension used to indicate a diff performed and return only a fraction of the resource. This is especially true when the actual resource is large and it would be a waste of bandwidth to return the entire resource. For example:

    GET /foo.html HTTP/1.1
    Host: bar.example.net
    If-None-Match: "123xyz"
    A-IM: vcdiff, diffe, gzip

Then, the server would reply something like:

    HTTP/1.1 226 IM Used
    ETag: "489uhw"
    IM: vcdiff
    Date: Tue, 25 Nov 1997 18:30:05 GMT
    Cache-Control: no-store, im, max-age=30

See also the L<HTTP range request|https://tools.ietf.org/html/rfc7233> triggering a C<206 Partial Content> response.

=head2 HTTP_MULTIPLE_CHOICES (300)

See L<rfc 7231, section 6.4.1|https://tools.ietf.org/html/rfc7231#section-6.4.1> and L<rfc 5988|https://tools.ietf.org/html/rfc5988> for the C<Link> header.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/300>

This is returned when there is a redirection with multiple choices possible. For example:

    HTTP/1.1 300 Multiple Choices
    Server: Apache/2.4
    Access-Control-Allow-Headers: Content-Type,User-Agent
    Access-Control-Allow-Origin: *
    Link: </foo> rel="alternate"
    Link: </bar> rel="alternate"
    Content-Type: text/html
    Location: /foo

However, because there is no standard way to have the user choose, this response code is never used.

=head2 HTTP_MOVED_PERMANENTLY (301)

See L<rfc 7231, section 6.4.2|https://tools.ietf.org/html/rfc7231#section-6.4.2>

This is returned to indicate the target resource can now be found at a different location and all pointers should be updated accordingly. For example:

    HTTP/1.1 301 Moved Permanently
    Server: Apache/2.4
    Content-Type: text/html; charset=utf-8
    Date: Mon, 18 Apr 2022 17:33:08 GMT
    Location: https://example.org/some/where/else.html
    Keep-Alive: timeout=15, max=98
    Accept-Ranges: bytes
    Via: Moz-Cache-zlb05
    Connection: Keep-Alive
    Content-Length: 212

    <!DOCTYPE html>
    <html><head>
    <title>301 Moved Permanently</title>
    </head><body>
    <h1>Moved Permanently</h1>
    <p>The document has moved <a href="https://example.org/some/where/else.html">here</a>.</p>
    </body></html>

See also C<308 Permanent Redirect>

=head2 HTTP_MOVED_TEMPORARILY (302)

See L<rfc 7231, section 6.4.3|https://tools.ietf.org/html/rfc7231#section-6.4.3>

This is returned to indicate the resource was found, but somewhere else. This is to be understood as a temporary change.

The de facto standard, divergent from the original intent, is to point the client to a new location after a C<POST> request was performed. This is why the status code C<307> was created.

See also C<307 Temporary Redirect>, which more formally tells the client to reformulate their request to the new location.

See also C<303 See Other> for a formal implementation of aforementioned de facto standard, i.e. C<GET> new location after C<POST> request.

=head2 HTTP_SEE_OTHER (303)

See L<rfc 7231, section 6.4.4|https://tools.ietf.org/html/rfc7231#section-6.4.4>

This is returned to indicate the result of processing the request can be found at another location. For example, after a C<POST> request, such as:

    HTTP/1.1 303 See Other
    Server: Apache/2.4
    Location: /worked/well

It is considered better to redirect once request has been processed rather than returning the result immediately in the response body, because in the former case, this wil register a new entry in the client history whereas with the former, this would force the user to re-submit if the user did a back in history.

=head2 HTTP_NOT_MODIFIED (304)

See L<rfc 7232, section 4.1 on Conditional Request|https://tools.ietf.org/html/rfc7232#section-4.1>

This is returned in response to a conditional C<GET> or C<POST> request with headers such as:

=over 4

=item L<If-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match>

=item L<If-None-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match>

=item L<If-Modified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>

=item L<If-Unmodified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Unmodified-Since>

=item L<If-Range|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range>

=back

For example:

    GET /foo HTTP/1.1
    Accept: text/html

Then, the server would reply something like:

    HTTP/1.1 200 Ok
    Content-Type: text/html
    ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

Later, the client would do another request, such as:

    GET /foo HTTP/1.1
    Accept: text/html
    If-None-Match: "33a64df551425fcc55e4d42a148795d9f25f89d4"

And if nothing changed, the server would return something like this:

    HTTP/1.1 304 Not Modified
    ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"

=head2 HTTP_USE_PROXY (305)

See L<rfc 7231, section 6.4.5|https://tools.ietf.org/html/rfc7231#section-6.4.5> and the L<rfc 2616, section 10.3.6 deprecating this status code|https://tools.ietf.org/html/rfc2616#section-10.3.6>

This is returned to indicate to the client to submit the request again, using a proxy. For example:

    HTTP/1.1 305 Use Proxy
    Location: https://proxy.example.org:8080/

This is deprecated and is not in use.

=head2 306 Switch Proxy

This is deprecated and now a reserved status code that was L<originally designed|https://lists.w3.org/Archives/Public/ietf-http-wg-old/1997MayAug/0373.html> to indicate to the client the need to change proxy, but was deemed ultimately a security risk. See the original L<rfc draft|https://datatracker.ietf.org/doc/html/draft-cohen-http-305-306-responses-00>

For example:

    HTTP/1.1 306 Switch Proxy
    Set-Proxy: SET; proxyURI="https://proxy.example.org:8080/" scope="http://", seconds=100

=head2 HTTP_TEMPORARY_REDIRECT (307)

See L<rfc 2731, section 6.4.7|https://tools.ietf.org/html/rfc7231#section-6.4.7>

This is returned to indicate the client to perform the request again at a different location. The difference with status code C<302> is that the client would redirect to the new location using a C<GET> method, whereas with the status code C<307>, they have to perform the same request.

For example:

    HTTP/1.1 307 Temporary Redirect
    Server: Apache/2.4
    Location: https://example.org/some/where/else.html

=head2 HTTP_PERMANENT_REDIRECT (308)

See L<rfc 7538 on Permanent Redirect|https://tools.ietf.org/html/rfc7538>

Similar to the status code C<307> and C<302>, the status code C<308> indicates to the client to perform the request again at a different location and that the location has changed permanently. This echoes the status code C<301>, except that the standard with C<301> is for clients to redirect using C<GET> method even if originally the method used was C<POST>. With the status code C<308>, the client must reproduce the request with the original method.

For example:

    GET / HTTP/1.1
    Host: example.org

Then, the server would respond something like:

    HTTP/1.1 308 Permanent Redirect
    Server: Apache/2.4
    Content-Type: text/html; charset=UTF-8
    Location: https://example.org/some/where/else.html
    Content-Length: 393

    <!DOCTYPE HTML>
    <html>
       <head>
          <title>Permanent Redirect</title>
          <meta http-equiv="refresh"
                content="0; url=https://example.org/some/where/else.html">
       </head>
       <body>
          <p>
             The document has been moved to
             <a href="https://example.org/some/where/else.html"
             >https://example.org/some/where/else.html</a>.
          </p>
       </body>
    </html>

=head2 HTTP_BAD_REQUEST (400)

See L<rfc 7231, section 6.5.1|https://tools.ietf.org/html/rfc7231#section-6.5.1>

This is returned to indicate the client made a request the server could not interpret.

This is generally used as a fallback client-error code when other mode detailed C<4xx> code are not suitable.

=head2 HTTP_UNAUTHORIZED (401)

See L<rfc 7235, section 3.1 on Authentication|https://tools.ietf.org/html/rfc7235#section-3.1>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401>

This is returned to indicate to the client it must authenticate first before issuing the request.

See also status code C<403 Forbidden> when client is outright forbidden from accessing the resource.

For example:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Basic; realm="Secured area"

or, for APIs:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Bearer

or, combining both:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Basic; realm="Dev zone", Bearer

which equates to:

    HTTP/1.1 401 Unauthorized
    WWW-Authenticate: Basic; realm="Dev zone"
    WWW-Authenticate: Bearer

So, for example, a user C<aladdin> with password C<opensesame> would result in the following request:

    GET / HTTP/1.1
    Authorization: Basic YWxhZGRpbjpvcGVuc2VzYW1l

See also L<Mozilla documentation on Authorization header|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization>

=head2 HTTP_PAYMENT_REQUIRED (402)

See L<rfc 7231, section 6.5.2|https://tools.ietf.org/html/rfc7231#section-6.5.2>

This was originally designed to inform the client that the resource could only be accessed once payment was made, but is now reserved and its current use is left at the discretion of the site implementing it.

=head2 HTTP_FORBIDDEN (403)

See L<rfc 7231, section 6.5.3|https://tools.ietf.org/html/rfc7231#section-6.5.3>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/403>

This is returned to indicate the client is barred from accessing the resource.

This is different from C<405 Method Not Allowed>, which is used when the client has proper permission to access the resource, but is using a method not allowed, such as using C<PUT> instead of C<GET> method.

=head2 HTTP_NOT_FOUND (404)

See L<rfc 7231, section 6.5.4|https://tools.ietf.org/html/rfc7231#section-6.5.4>

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404>

This is returned to indicate the resource does not exist anymore.

=head2 HTTP_METHOD_NOT_ALLOWED (405)

See L<rfc 7231, section 6.5.5|https://tools.ietf.org/html/rfc7231#section-6.5.5>

This is returned to indicate the client it used a L<method|https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods> not allowed, such as using C<PUT> instead of C<GET>. The server can point out the supported methods with the C<Allow> header, such as:

    HTTP/1.1 405 Method Not Allowed
    Content-Type: text/html
    Content-Length: 32
    Allow: GET, HEAD, OPTIONS, PUT

    <h1>405 Try another method!</h1>

=head2 HTTP_NOT_ACCEPTABLE (406)

See L<rfc 7231, section 6.5.6|https://tools.ietf.org/html/rfc7231#section-6.5.6>

This is returned to the client to indicate its requirements are not supported and thus not acceptable. This is in response to L<Accept|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept>, L<Accept-Charset|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Charset>, L<Accept-Encoding|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Encoding>, L<Accept-Language|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language> headers

For example:

    GET /foo HTTP/1.1
    Accept: application/json
    Accept-Language: fr-FR,en-GB;q=0.8,fr;q=0.6,en;q=0.4,ja;q=0.2

    HTTP/1.1 406 Not Acceptable
    Server: Apache/2.4
    Content-Type: text/html

    <h1>Je ne gère pas le type application/json</h1>


Then, the server would response something like:

=head2 HTTP_PROXY_AUTHENTICATION_REQUIRED (407)

See L<rfc 7235, section 3.2 on Authentication|https://tools.ietf.org/html/rfc7235#section-3.2>

This is returned to indicate the proxy used requires authentication. This is similar to the status code C<401 Unauthorized>.

=head2 HTTP_REQUEST_TIME_OUT (408)

See L<rfc 7231, section 6.5.7|https://tools.ietf.org/html/rfc7231#section-6.5.7>

This is returned to indicate the request took too long to be received and timed out. For example:

    HTTP/1.1 408 Request Timeout
    Connection: close
    Content-Type: text/plain
    Content-Length: 19

    Too slow! Try again

=head2 HTTP_CONFLICT (409)

See L<rfc 7231, section 6.5.8|https://tools.ietf.org/html/rfc7231#section-6.5.8>

This is returned to indicate a request conflict with the current state of the target resource, such as uploading with C<PUT> a file older than the remote one.

=head2 HTTP_GONE (410)

See L<rfc 7231, section 6.5.9|https://tools.ietf.org/html/rfc7231#section-6.5.9>

This is returned to indicate that the target resource is gone permanently. The subtle difference with the status code C<404> is that with C<404>, the resource may be only temporally unavailable whereas with C<410>, this is irremediable. For example:

    HTTP/1.1 410 Gone
    Server: Apache/2.4
    Content-Type: text/plain
    Content-Length: 30

    The resource has been removed.

=head2 HTTP_LENGTH_REQUIRED (411)

See L<rfc 7231, section 6.5.10|https://tools.ietf.org/html/rfc7231#section-6.5.10>

This is returned when the C<Content-Length> header was not provided by the client and the server requires it to be present. Most servers can do without.

=head2 HTTP_PRECONDITION_FAILED (412)

See L<rfc 7232 on Conditional Request|https://tools.ietf.org/html/rfc7232>

This is returned when some preconditions set by the client could not be met.

For example:

Issuing a C<PUT> request for a document if it does not already exist.

    PUT /foo/new-article.md HTTP/1.1
    Content-Type: text/markdown
    If-None-Match: *

Update a document if it has not changed since last time (etag)

    PUT /foo/old-article.md HTTP/1.1
    If-Match: "1345-12315"
    Content-Type: text/markdown

If those failed, it would return something like:

    HTTP/1.1 412 Precondition Failed
    Content-Type: text/plain
    Content-Length: 64

    The article you are tring to update has changed since last time.

If one adds the C<Prefer> header, the servers will return the current state of the resource, thus saving a round of request with a C<GET>, such as:

    PUT /foo/old-article.md HTTP/1.1
    If-Match: "1345-12315"
    Content-Type: text/markdown
    Prefer: return=representation

    ### Article version 2.1

Then, the server would respond something like:

    HTTP/1.1 412 Precondition Failed
    Content-Type: text/markdown
    Etag: "4444-12345"
    Vary: Prefer

    ### Article version 3.0

See also L<rfc 7240 about the Prefer header field|https://tools.ietf.org/html/rfc7240> and L<rfc 8144, Section 3.2|https://tools.ietf.org/html/rfc8144#section-3.2> about the usage of C<Prefer: return=representation> with status code C<412>

=head2 HTTP_REQUEST_ENTITY_TOO_LARGE (413)

See L<rfc 7231, section 6.5.11|https://tools.ietf.org/html/rfc7231#section-6.5.11>

This is returned when the body of the request is too large, such as when sending a file whose size has exceeded the maximum size limit.

For example:

    HTTP/1.1 413 Payload Too Large
    Retry-After: 3600
    Content-Type: text/html
    Content-Length: 52

    <p>You exceeded your quota. Try again in an hour</p>

See also L<rfc 7231, section 7.1.3|https://tools.ietf.org/html/rfc7231#section-7.1.3> on C<Retry-After> header field.

See also C<507 Insufficient Storage>

=head2 HTTP_PAYLOAD_TOO_LARGE (413)

Same as previous. Used here for compatibility with C<HTTP::Status>

=head2 HTTP_REQUEST_URI_TOO_LARGE (414)

See L<rfc 7231, section 6.5.12|https://tools.ietf.org/html/rfc7231#section-6.5.12>

Although there is no official limit to the size of an URI, some servers may implement a limit and return this status code when the URI exceeds it. Usually, it is recommended not to exceed 2048 bytes for an URI.

=head2 HTTP_UNSUPPORTED_MEDIA_TYPE (415)

See L<rfc 7231, section 6.5.13|https://tools.ietf.org/html/rfc7231#section-6.5.13>

This is returned when the server received a request body type it does not understand.

This status code may be returned even if the C<Content-Type> header value is supported, because the server would still inspect the request body, such as with a broken C<JSON> payload.

Usually, in those cases, the server would rather return C<422 Unprocessable Entity>

=head2 HTTP_RANGE_NOT_SATISFIABLE (416)

See L<rfc 7233, section 4.4 on Range Requests|https://tools.ietf.org/html/rfc7233#section-4.4>

This is returned when the client made a range request it did not understand.

Client can issue range request instead of downloading the entire file, which is helpful for large data.

=head2 HTTP_REQUEST_RANGE_NOT_SATISFIABLE (416)

Same as previous. Used here for compatibility with C<HTTP::Status>

=head2 HTTP_EXPECTATION_FAILED (417)

See L<rfc 7231, section 6.5.14|https://tools.ietf.org/html/rfc7231#section-6.5.14>

This is returned when the server received an C<Expect> header field value it did not understand.

For example:

    PUT /some//big/file.mp4 HTTP/1.1
    Host: www.example.org
    Content-Type: video/mp4
    Content-Length: 778043392
    Expect: 100-continue

Then, the server could respond with the following:

    HTTP/1.1 417 Expectation Failed
    Server: Apache/2.4
    Content-Type: text/plain
    Content-Length: 30

    We do not support 100-continue

See also L<rfc 7231, section 5.1.1|https://tools.ietf.org/html/rfc7231#section-5.1.1> on the C<Expect> header.

=head2 HTTP_I_AM_A_TEAPOT (418)

See L<rfc 2324 on HTCPC/1.0  1-april|https://tools.ietf.org/html/rfc2324>

This status code is not actually a real one, but one that was made by the IETF as an april-fools' joke, and it stuck. Attempts to remove it was met with L<strong resistance|https://save418.com/>.

There has even been L<libraries developed|https://github.com/dkundel/htcpcp-delonghi> to implement the L<HTCPC protocol|https://github.com/HyperTextCoffeePot/HyperTextCoffeePot>.

=head2 HTTP_I_AM_A_TEA_POT (418)

Same as previous.

=head2 HTTP_MISDIRECTED_REQUEST (421)

See L<rfc 7540, section 9.1.2 on HTTP/2|https://tools.ietf.org/html/rfc7540#section-9.1.2>

This is returned when the web server received a request that was not intended for him.

For example:

    GET /contact.html HTTP/1.1
    Host: foo.example.org

    HTTP/1.1 421 Misdirected Request
    Content-Type: text/plain
    Content-Length: 27

    This host unsupported here.

=head2 HTTP_UNPROCESSABLE_ENTITY (422)

See L<rfc 4918, section 11.2|https://tools.ietf.org/html/rfc4918#section-11.2>

This is returned when the web server understood the request, but deemed the body content to not be processable.

For example:

    POST /new-article HTTP/1.1
    Content-Type: application/json
    Content-Length: 26

    { "title": "Hello world!"}

Then, the web server could respond something like:

    HTTP/1.1 422 Unprocessable Entity
    Content-Type: application/problem+json
    Content-Length: 114

    {
      "type" : "https://example.org/errors/missing-property",
      "status": 422,
      "title": "Missing property: body"
    }

=head2 HTTP_LOCKED (423)

See L<rfc 4918 on WebDAV|https://tools.ietf.org/html/rfc4918>

This is returned under the WebDav protocol when one tries to make change to a locked resource.

=head2 HTTP_FAILED_DEPENDENCY (424)

See L<rfc 4918 on WebDAV|https://tools.ietf.org/html/rfc4918>

This is returned under the WebDav protocol when the processing of one of the resources failed.

=head2 HTTP_TOO_EARLY (425)

See L<rfc 8470, section 5.2 on Using Early Data in HTTP|https://tools.ietf.org/html/rfc8470#section-5.2>

This predominantly occurs during the TLS handshake to notify the client to retry a bit later once the TLS connection is up.

=head2 HTTP_NO_CODE (425)

Same as previous. Used here for compatibility with C<HTTP::Status>

=head2 HTTP_UNORDERED_COLLECTION (425)

Same as previous. Used here for compatibility with C<HTTP::Status>

=head2 HTTP_UPGRADE_REQUIRED (426)

See L<rfc 7231, section 6.5.15|https://tools.ietf.org/html/rfc7231#section-6.5.15>

This is returned to notify the client to use a newer version of the HTTP protocol.

=head2 HTTP_PRECONDITION_REQUIRED (428)

See L<rfc 6585, section 3 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-3>

This is used when the web server requires the client to use condition requests, such as:

=over 4

=item L<If-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Match>

=item L<If-None-Match|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match>

=item L<If-Modified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Modified-Since>

=item L<If-Unmodified-Since|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Unmodified-Since>

=item L<If-Range|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-Range>

=back

=head2 HTTP_TOO_MANY_REQUESTS (429)

See L<rfc 6585, section 4 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-4>

This is returned when the server needs to notify the client to slow down the number of requests. This is predominantly used for API, but not only.

For example:

    HTTP/1.1 429 Too Many Requests
    Content-Type: text/plain
    Content-Length: 44
    Retry-After: 3600

    You exceeded the limit. Try again in an hour

=head2 HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE (431)

See L<rfc 6585, section 5 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-5>

This is returned when the client issued a request containing HTTP header fields that are too big in size. Most likely culprit are the HTTP cookies.

=head2 HTTP_CONNECTION_CLOSED_WITHOUT_RESPONSE (444)

This is a non-standard status code used by some web servers, such as nginx, to instruct it to close the connection without sending a response back to the client, predominantly to deny malicious or malformed requests.

This status code is actually not seen by the client, but only appears in nginx log files.

=head2 HTTP_UNAVAILABLE_FOR_LEGAL_REASONS (451)

See L<rfc 7725 on Legal Obstacles|https://tools.ietf.org/html/rfc7725>

This is returned when, for some legal reasons, the resource could not be served.

This status code has been chosen on purpose, for its relation with the book L<Fahrenheit 451|https://en.wikipedia.org/wiki/Fahrenheit_451> from Ray Bradbury. In his book, the central theme is the censorship of literature. The book title itself "Fahrenheit 451" refers to the temperature at which paper ignites, i.e. 451 Fahrenheit or 232° Celsius.

For example:

    HTTP/1.1 451 Unavailable For Legal Reasons
    Link: <https://example.org/legal>; rel="blocked-by"
    Content-Type text/plain
    Content-Length: 48

    You are prohibited from accessing this resource.

=head2 HTTP_CLIENT_CLOSED_REQUEST (499)

This is a non-standard status code used by some web servers, such as nginx, when the client has closed the connection while the web server was still processing the request.

This status code is actually not seen by the client, but only appears in nginx log files.

=head2 HTTP_INTERNAL_SERVER_ERROR (500)

See L<rfc 7231, section 6.6.1|https://tools.ietf.org/html/rfc7231#section-6.6.1>

This is returned when an internal malfunction due to some bug of general processing error.

=head2 HTTP_NOT_IMPLEMENTED (501)

See L<rfc 7231, section 6.6.2|https://tools.ietf.org/html/rfc7231#section-6.6.2>

This is returned when the web server unexpectedly does not support certain features, although the request was itself acceptable.

=head2 HTTP_BAD_GATEWAY (502)

See L<rfc 7231, section 6.6.3|https://tools.ietf.org/html/rfc7231#section-6.6.3>

This is returned by proxy servers when the original target server is not operating properly and to notify the client of this.

=head2 HTTP_SERVICE_UNAVAILABLE (503)

See L<rfc 7231, section 6.6.4|https://tools.ietf.org/html/rfc7231#section-6.6.4>

This is returned when the web server is temporally incapable of processing the request, such as due to overload.

For example:

    HTTP/1.1 503 Service Unavailable
    Content-Type text/plain
    Content-Length: 56
    Retry-After: 1800

    System overload! Give us some time to increase capacity.

=head2 HTTP_GATEWAY_TIME_OUT (504)

See L<rfc 7231, section 6.6.5|https://tools.ietf.org/html/rfc7231#section-6.6.5>

This is returned by a proxy server when the upstream target server is not responding in a timely manner.

=head2 HTTP_VERSION_NOT_SUPPORTED (505)

See L<rfc 7231, section 6.6.6|https://tools.ietf.org/html/rfc7231#section-6.6.6>

This is returned when the web server does not support the HTTP version submitted by the client.

For example:

    GET / HTTP/4.0
    Host: www.example.org

Then, the server would respond something like:

    HTTP/1.1 505 HTTP Version Not Supported
    Server: Apache/2.4
    Date: Mon, 18 Apr 2022 15:23:35 GMT
    Content-Type: text/plain
    Content-Length: 30
    Connection: close

    505 HTTP Version Not Supported

=head2 HTTP_VARIANT_ALSO_VARIES (506)

See L<rfc 2295 on Transparant Ngttn|https://tools.ietf.org/html/rfc2295>

This is returned in the context of Transparent Content Negotiation when there is a server-side misconfiguration that leads the chosen variant itself to also engage in content negotiation, thus looping.

For example:

    GET / HTTP/1.1
    Host: www.example.org
    Accept: text/html; image/png; text/*; q=0.9
    Accept-Language: en-GB; en
    Accept-Charset: UTF-8
    Accept-Encoding: gzip, deflate, br

=head2 HTTP_INSUFFICIENT_STORAGE (507)

See L<rfc 4918, section 11.5 on WebDAV|https://tools.ietf.org/html/rfc4918#section-11.5>

This is returned in the context of WebDav protocol when a C<POST> or C<PUT> request leads to storing data, but the operations fails, because the resource is too large to fit on the remaining space on the server disk.

=head2 HTTP_LOOP_DETECTED (508)

See L<rfc 5842, section 7.2 on WebDAV bindings|https://tools.ietf.org/html/rfc5842#section-7.2>

This is returned in the context of WebDav when the target resource is looping.

=head2 HTTP_BANDWIDTH_LIMIT_EXCEEDED (509)

This is returned by some web servers when the amount of bandwidth consumed exceeded the maximum possible.

=head2 HTTP_NOT_EXTENDED (510)

See L<rfc 2774, section 6 on Extension Framework|https://tools.ietf.org/html/rfc2774#section-6>

This is returned by the web server who expected the client to use an extended http feature, but did not.

This is not widely implemented.

=head2 HTTP_NETWORK_AUTHENTICATION_REQUIRED (511)

See L<rfc 6585, section 6.1 on Additional Codes|https://tools.ietf.org/html/rfc6585#section-6.1>

This is returned by web server on private network to notify the client that a prior authentication is required to be able to browse the web. This is most likely used in location with private WiFi, such as lounges.

=head2 HTTP_NETWORK_CONNECT_TIMEOUT_ERROR (599)

This is returned by some proxy servers to signal a network connect timeout behind the proxy and the upstream target server.

This is not part of the standard.

=head1 APACHE CONSTANTS

This module adds the following missing L<Apache2::Const> constants for completeness:

=head2 Apache2::Const::EARLY_HINTS

HTTP code 103

=head2 Apache2::Const::I_AM_A_TEA_POT

HTTP code 418

=head2 Apache2::Const::MISDIRECTED_REQUEST

HTTP code 421

=head2 Apache2::Const::TOO_EARLY

HTTP code 425

=head2 Apache2::Const::CONNECTION_CLOSED_WITHOUT_RESPONSE

HTTP code 444

=head2 Apache2::Const::UNAVAILABLE_FOR_LEGAL_REASONS

HTTP code 451

=head2 Apache2::Const::CLIENT_CLOSED_REQUEST

HTTP code 499

=head2 Apache2::Const::HTTP_VERSION_NOT_SUPPORTED

HTTP code 505

=head2 Apache2::Const::BANDWIDTH_LIMIT_EXCEEDED

HTTP code 509

=head2 Apache2::Const::NETWORK_CONNECT_TIMEOUT_ERROR

HTTP code 599

=head2 SEE ALSO

Apache distribution and file C<httpd-2.x.x/include/httpd.h>

L<IANA HTTP codes list|http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2023 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
