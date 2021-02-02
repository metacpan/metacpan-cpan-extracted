package CatalystX::Utils::ErrorMessages;

use strict;
use warnings;
use utf8;

my %messages = (
  en_US => {
    "400"=> {
        "title" => "Bad Request",
        "message" => "The server cannot process the request due to something that is perceived to be a client error." 
    },
    "401"=> {
        "title"=> "Unauthorized",
        "message"=> "The requested resource requires an authentication."
    },
    "403"=> {
        "title"=> "Access Denied",
        "message"=> "The requested resource requires an authentication." 
    },
    "404"=> {
        "title"=> "Resource not found",
        "message"=> "The requested resource could not be found but may be available again in the future." 
    },
    "500"=> {
        "title"=> "Webservice currently unavailable",
        "message"=> "An unexpected condition was encountered.\nOur service team has been dispatched to bring it back online." 
    },
    "501"=> {
        "title"=> "Not Implemented",
        "message"=> "The Webserver cannot recognize the request method."
    },
    "502"=> {
        "title"=> "Webservice currently unavailable",
        "message"=> "We've got some trouble with our backend upstream cluster.\nOur service team has been dispatched to bring it back online."
    },
    "503"=> {
        "title"=> "Webservice currently unavailable",
        "message"=> "We've got some trouble with our backend upstream cluster.\nOur service team has been dispatched to bring it back online."
    },
    "520"=> {
        "title"=> "Origin Error - Unknown Host",
        "message"=> "The requested hostname is not routed. Use only hostnames to access resources."
    },
    "521"=> {
        "title"=> "Webservice currently unavailable",
        "message"=> "We've got some trouble with our backend upstream cluster.\nOur service team has been dispatched to bring it back online."
    },
    "533"=> {
        "title"=> "Scheduled Maintenance",
        "message"=> "This site is currently down for maintenance.\nOur service team is working hard to bring it back online soon."                
    },
  },
  es_VE => {
    "400" => {
        "title"=> "Solicitud incorrecta",
        "message"=> "El servidor no puede procesar la solicitud debido a un error en la petición del cliente, por favor <b>modifique su petición</b> e intente de nuevo." 
    },
    "401" => {
        "title"=> "No autorizado",
        "message"=> "El recurso solicitado requiere de una autorización."
    },
    "403" => {
        "title"=> "Acceso denegado",
        "message"=> "El recurso está prohibido, por favor NO reintente su solicitud." 
    },
    "404" => {
        "title"=> "Recurso no encontrado",
        "message"=> "El recurso solicitado no se pudo encontrar, pero podría estar disponible a futuro." 
    },
    "500" => {
        "title"=> "Hemos sufrido un error interno",
        "message"=> "Eso es lo que sabemos, ya un equipo se apresta a localizar el fallo en nuestro servidor web." 
    },
    "501" => {
        "title"=> "No implementado",
        "message"=> "El servidor web no puede reconocer el método de solicitud."
    },
    "502" => {
        "title"=> "Servicio web proxy actualmente no disponible",
        "message"=> "Tenemos algunos problemas con nuestro racimo. Nuestro equipo de servicio fue enviado para restablecerlo nuevamente en línea."
    },
    "503" => {
        "title"=> "Servicio web actualmente no disponible",
        "message"=> "Se encontró una condición inesperada. Nuestro equipo de servicio está abocado para colocarlo nuevamente en servicio."
    },
    "520" => {
        "title"=> "Error de origen: anfitrión desconocido",
        "message"=> "El nombre de anfitrión solicitado no se encontró en ruta. Utilice solo nombres de anfitrión para acceder a los recursos."
    },
    "521" => {
        "title"=> "Servicio web no disponible por ahora",
        "message"=> "Tenemos algunos problemas con nuestro servicio, un equipo ya está trabajando para colocarlo de nuevo en línea."
    },
    "533" => {
        "title"=> "Mantenimiento progamado",
        "message"=> "Nuestro sitio está en mantenimiento y trabajamos para que muy pronto estaremos en línea de nuevo, agradecemos paciencia."                
    },
  },
  fr_FR => {
    "400" => {
        "title" => "Bad Request",
        "message" => "Le serveur ne peut pas traiter la requête en raison d'une erreur perçue comme étant une erreur du client." 
    },
    "401" => {
        "title" => "Non autorisé",
        "message" => "La ressource demandée nécessite une authentification."
    },
    "403" => {
        "title" => "Accès refusé",
        "message" => "La ressource demandée nécessite une authentification." 
    },
    "404" => {
        "title" => "Ressource non trouvée",
        "message" => "La ressource demandée n'a pu être trouvée, mais elle pourrait être de nouveau disponible à l'avenir." 
    },
    "500" => {
        "title" => "Service Web actuellement indisponible",
        "message" => "Une condition inattendue a été rencontrée. Notre équipe de service a été dépêchée pour la remettre en service." 
    },
    "501" => {
        "title" => "Non implémenté",
        "message" => "Le serveur Web ne peut pas reconnaître la méthode de requête."
    },
    "502" => {
        "title" => "Service Web actuellement indisponible",
        "message" => "Nous avons quelques problèmes avec notre cluster en amont. Notre équipe de service a été dépêchée pour le remettre en ligne."
    },
    "503" => {
        "title" => "Service Web actuellement indisponible",
        "message" => "Nous avons quelques problèmes avec notre cluster en amont. Notre équipe de service a été dépêchée pour le remettre en ligne."
    },
    "520" => {
        "title" => "Origin Error - Unknown Host",
        "message" => "Le nom d'hôte demandé n'est pas routé. Utilisez uniquement les noms d'hôtes pour accéder aux ressources."
    },
    "521" => {
        "title" => "Service Web actuellement indisponible",
        "message" => "Nous avons quelques problèmes avec notre cluster en amont. Notre équipe de service a été dépêchée pour le remettre en ligne."
    },
    "533" => {
        "title" => "Maintenance Programmée",
        "message" => "Ce site est actuellement en maintenance. Notre équipe de service travaille dur pour le remettre en ligne prochainement."                
    },
  },
  it_IT => {        
    "400" => {
        "title" => "Richiesta non valida",
        "message" => "Il server non può elaborare la richiesta a causa di qualcosa che è percepito come un errore del client." 
    },
    "401" => {
        "title" => "Accesso negato",
        "message" => "La risorsa richiesta richiede un'autenticazione."
    },
    "403" => {
        "title" => "Operazione non consentita",
        "message" => "La risorsa richiesta richiede un'autenticazione." 
    },
    "404" => {
        "title" => "Risorsa non trovata",
        "message" => "La risorsa richiesta non è stata trovata ma potrebbe essere nuovamente disponibile in futuro." 
    },
    "500" => {
        "title" => "Web Server attualmente non disponibile",
        "message" => "Si è verificata una condizione imprevista.\nIl nostro team di assistenza è stato inviato per riportarlo online." 
    },
    "501" => {
        "title" => "Non implementato",
        "message" => "Il server Web non è in grado di riconoscere il metodo della richiesta."
    },
    "502" => {
        "title" => "Web Server attualmente non disponibile - Gateway non valido",
        "message" => "Abbiamo qualche problema con il nostro cluster back-end.\nIl nostro team di assistenza è stato inviato per riportarlo online."
    },
    "503" => {
        "title" => "Web Server attualmente non disponibile",
        "message" => "Abbiamo qualche problema con il nostro cluster back-end.\nIl nostro team di assistenza è stato inviato per riportarlo online."
    },
    "504" => {
        "title" => "Web Server attualmente non disponibile - Timeout del gateway",
        "message" => "Abbiamo qualche problema con il nostro cluster back-end.\nIl nostro team di assistenza è stato inviato per riportarlo online."
    },
    "520" => {
        "title" => "Errore di origine - Host sconosciuto",
        "message" => "Il nome host richiesto non viene instradato. Utilizzare solo nomi host per accedere alle risorse."
    },
    "521" => {
        "title" => "Web Server attualmente non disponibile",
        "message" => "Abbiamo qualche problema con il nostro cluster back-end.\nIl nostro team di assistenza è stato inviato per riportarlo online."
    },
    "533" => {
        "title" => "Manutenzione programmata",
        "message" => "Questo sito è attualmente fuori servizio per manutenzione.\nIl nostro team di assistenza sta lavorando sodo per riportarlo presto online."
    },
  },
  pt_BR => {        
    "400" => {
        "title" => "Requisição inválida",
        "message" => "Oops! Não conseguimos processar a requisição."	
    },
    "401" => {
        "title" => "Não Autorizado",
        "message" => "Oops! O recurso requer uma autenticação."
    },
    "403" => {
        "title" => "Acesso Negado",
        "message" => "Oops! O recurso requer uma autenticação." 
    },
    "404" => {
        "title" => "Página Não Encontrada",
        "message" => "Oops! Não conseguimos encontrar a página que você estava procurando."	
    },
    "500" => {
        "title" => "Webservice Atualmente Não Disponível",
        "message" => "Uma condição inesperada foi encontrada.\nNosso time de serviços está trabalhando para deixar isso online novamente." 
    },
    "501" => {
        "title" => "Não implementado",
        "message" => "Oops! O Webserver não conseguiu reconhecer o método solicitado"
    },
    "502" => {
        "title" => "Webservice atualmente indisponível",
        "message" => "Nós tivemos alguns problema com o nosso backend. Nosso time de serviços está trabalhando para deixar isso online novamente."
    },
    "503" => {
        "title" => "Webservice atualmente indisponível",
        "message" => "Nós tivemos alguns problema com o nosso backend. Nosso time de serviços está trabalhando para deixar isso online novamente."
    },
    "520" => {
        "title" => "Origin Error - Host Desconhecido",
        "message" => "O hostname requisitado não é roteado. Use apenas hostnames para acessar recursos."
    },
    "521" => {
        "title" => "Webservice atualmente indisponível",
        "message" => "Nós tivemos alguns problema com o nosso backend. Nosso time de serviços está trabalhando para deixar isso online novamente."
    },
    "533" => {
        "title" => "Estamos em manutenção",
        "message" => "O site está offline para manutenção.\nNosso time está trabalhando para reestabelecer o serviço em breve."
    },
  },
  zh_CN => {
    "400" => {
        "title" => "无效的请求",
        "message" => "由于明显的客户端错误，服务器不能或不会处理该请求。" 
    },
    "401" => {
        "title" => "未认证",
        "message" => "所请求的资源需要认证。"
    },

    "403" => {
        "title" => "访问请求被拒绝",
        "message" => "所请求的资源需要认证" 
    },
    "404" => {
        "title" => "资源未找到",
        "message" => "找不到所请求的资源。" 
    },
    "500" => {
        "title" => "Webservice目前不可用",
        "message" => "发生了未知的问题。\n我们的技术支持团队正在努力修复中。" 
    },
    "501" => {
        "title" => "方法未实现",
        "message" => "服务器不支持当前请求所需要的某个功能。"
    },
    "502" => {
        "title" => "Webservice目前不可用",
        "message" => "我们的后端上游服务器出现了问题。\n技术支持团队正在努力修复中。"
    },
    "503" => {
        "title" => "Webservice目前不可用",
        "message" => "我们的后端上游服务器出现了问题。\n技术支持团队正在努力修复中。"
    },
    "520" => {
        "title" => "未知的主机",
        "message" => "没有到达所请求的主机的路由。"
    },
    "521" => {
        "title" => "Webservice暂时不可用",
        "message" => "我们的后端上游服务器出现了问题。\n技术支持团队正在努力修复中。"
    },
    "533" => {
        "title" => "日常维护",
        "message" => "本站暂时因维护原因而下线。\n我们将会尽快恢复。"                
    },
  },
);

my @language_keys = keys %messages;

sub available_languages {
  return @language_keys;
}

sub get_message_info {
  my ($lang, $code) = @_;
  return $messages{$lang}{$code};
}

1;

=head1 NAME

CatalystX::Utils::ErrorMessages - HTTP error message data in various languages

=head1 SYNOPSIS

  use CatalystX::Utils::ErrorMessages

=head1 DESCRIPTION

Not really intended for end user use at this point so see source if you want more
info.

Feel free to send me PRs with additional HTTP error codes and translations.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
