package CPAN::Search::Lite::Lang::es;
use strict;
use warnings;
our $VERSION = 0.77;

use base qw(Exporter);
our (@EXPORT_OK, $chaps_desc, $pages, $dslip, $months);
@EXPORT_OK = qw($chaps_desc $pages $dslip $months);

$chaps_desc = {
        2 => q{M&oacute;dulos b&aacute;sicos del Perl},
        3 => q{Ayuda para el desarrollo},
        4 => q{Interfaces con el Sistema Operativo},
        5 => q{Servicios red IPC},
        6 => q{Utilidades de estructuras de datos},
        7 => q{Interfaces de bases de datos},
        8 => q{Interfaces del usuario},
        9 => q{Interfaces de lenguajes},
        10 => q{Sistemas de ficheros},
        11 => q{Procesamiento de textos},
        12 => q{Procesamiento de argumentos y opciones},
        13 => q{Configuraciones regionales},
        14 => q{Seguridad y cifrado},
        15 => q{World Wide Web HTML HTTP CGI},
        16 => q{Servidores y demonios},
        17 => q{Archivando y comprimiendo},
        18 => q{Im&aacute;genes y Bitmaps},
        19 => q{Correo electr&oacute;nico y News},
        20 => q{Utilidades de control de flujo},
        21 => q{Ficheros. Entrada/Salida},
        22 => q{M&oacute;dulos de Microsoft Windows},
        23 => q{M&oacute;dulos varios},
        24 => q{Interfaces de Software Comercial},
        26 => q{Documentaci&oacute;n},
        27 => q{Pragma},
        28 => q{Perl6},
        99 => q{No todav&iacute;a en lista de m&oacute;dulos},
};

$dslip = {
    d => {
      M => q{Maduro (no es una definici&oacute;n rigurosa)},
      R => q{Liberado},
      S => q{Est&aacute;ndar, disponible con Perl 5},
      a => q{Alfa, en modo test},
      b => q{Beta, en modo test},
      c => q{Bajo construcci&oacute;n pero pre-alfa (todav&iacute;a no liberado)},
      desc => q{Estado del desarrollo (Nota: * NO IMPLICA TIEMPOS *)},
      i => q{Idea, enumerada para ganar consenso o como repositorio},
    },
    s => {
      a => q{Abandonado, el m&oacute;dulo ha sido abandonado por su autor},
      d => q{Desarrollador},
      desc => q{Nivel de soporte},
      m => q{Lista de correo},
      n => q{Nada conocido, intente comp.lang.perl.modules},
      u => q{Grupo de News comp.lang.perl.modules},
    },
    l => {
      '+' => q{C++ y Perl, un compilador de C++ ser&aacute; necesario},
      c => q{C y Perl, un compilador de C ser&aacute; necesario},
      desc => q{Lenguaje utilizado},
      h => q{H&iacute;brido, escrito en Perl con c&oacute;digo opcional en C, no se necesita compilador},
      o => q{Perl y otro lenguaje distinto de C o de C++},
      p => q{S&oacute;lo Perl, ning&uacute;n compilador necesario, debe ser independiente de la plataforma},
    },
    i => {
      O => q{Orientado a objetos utilizando referencias bendecidas y/o herencia},
      desc => q{Estilo del Interfaz},
      f => q{Funciones normales, no se utilizaron referencias},
      h => q{H&iacute;brido, existen objetos y funciones},
      n => q{Ninguna interfaz (&iquest;c&oacute;mo?)},
      r => q{alg&uacute;n uso de lazos o referencias no bendecidas},
    },
    p => {
      a => q{Licencia art&iacute;stica solamente},
      b => q{BSD: La licencia del BSD},
      desc => q{Licencia p&uacute;blica},
      g => q{GPL: Licencia P&uacute;blica General de GNU},
      l => q{LGPL: "Licencia Ligera P&uacute;blica General de GNU" (conocida previamente como "Licencia P&uacute;blica General de la librer&iacute;a del GNU")},
      o => q{otra (pero la distribuci&oacute;n est&aacute; permitida sin restricciones)},
      p => q{Perl est&aacute;ndar: el usuario puede elegir entre la GPL y la art&iacute;stica},
    },
};

$pages = {
          title => 'Hojear y buscar en CPAN',
          list => { module => 'M&oacute;dulos',
                     dist => 'Distribuciones',
                     author => 'Autores',
                     chapter => 'Categor&iacute;as',
                   },
          buttons => {Home => 'Principal',
                      Documentation => 'Documentaci&oacute;n',
                      Recent => 'Recientes',
                      Mirror => 'Espejo',
                      Preferences => 'Preferencias',
                      Modules => 'M&oacute;dulos',
                      Distributions => 'Distribuciones',
                      Authors => 'Autores',
                     },
          form => {Find => 'Encontrar',
                    in => 'en',
                    Search => 'Buscar',
                   },
          Problems => 'Problemas, sugerencias, o comentarios a',
          Language => 'Opci&oacute;n de la lengua',
          Questions => '&iquest;Preguntas? Compruebe el',
          na => 'no especificado',
          bytes => 'byte',
          download => 'Descarga',
          cpanid => 'CPAN id',
          name => 'Nombre completo',
          email => 'email',
          results => 'resultados encontrados',
          try => 'Intente esta b&uacute;squeda en',
          categories => 'Categor&iacute;as',
          category => 'Categor&iacute;a',
          distribution => 'Distribuci&oacute;n',
          author => 'Autor',
          module => 'Modul',
          version => 'Versi&oacute;n',
          abstract => 'Resumen',
          released => 'Creado',
          size => 'Tama&ntilde;o',
          cs => 'MD5 Checksum',
          additional => 'Archivos Adicionales',
          links => 'Enlaces',
          info => 'informaci&oacute;n',
          prereqs => 'Prerequisitos',
          packages => 'paquetes para',
          related => 'related',
          browse => 'Hojear por',
          uploads => 'Novedades de los &uacute;ltimos',
          days => 'd&iacute;as',
          more => 'more',
          nada => 'Ningunos resultados encontraron',
          error1 => 'Lo siento - hab&iacute;a un error en su b&uacute;squeda por',
          error2 => 'del tipo',
          error3 => '',
          error4 => 'Lo siento - ocurri&oacute; un error.',
          error5 => << 'END',
Se ha registrado el error. Si ha ocurrido cuando se realizaba una 
b&uacute;squeda con expresiones regulares, quiz&aacute;s desee comprobar la 
<a href="http://www.mysql.com/documentation/mysql/bychapter/manual_Regexp.html#Regexp">sintaxis permitida</a>.
<p>Si usted piensa que es un error de la herramienta de b&uacute;squeda, 
puede ayudarnos para arreglarlo enviando un mensaje a
END
          error6 => << 'END',
con los detalles de lo que buscaba cuando sucedi&oacute; esto. &iexcl;Gracias!
END
           missing1 => 'Lo siento - Ning&uacute;n resultado por',
           missing2 => 'se encontr&oacute; del tipo',
           missing3 => 'Int&eacute;ntelo por favor con otro t&eacute;rmino de b&uacute;squeda.',
           missing4 => 'Lo siento - No entiendo lo que se intent&oacute; buscar. Por favor int&eacute;ntelo otra vez.',
           mirror => 'CPAN Espejos',
           public => 'Espejo p&uacute;blico.',
           none => 'Ninguno - usar URL personal',
           custom => 'URL personal',
           default => 'El enlace por defecto de',
           alt => 'o',
          install => 'Instale',
           mirror1 => << 'END',
Con este formulario usted puede especificar de d&oacute;nde desea 
realizar las descargas (esto requiere que las 
cookies est&eacute;n permitidas). 
Su configuraci&oacute;n actual es 
END
           mirror2 => << 'END',
intentar&aacute; redirigirle a un espejo pr&oacute;ximo 
de CPAN, basado en su pa&iacute;s de origen.
END
          webstart => << 'END',
Seleccionar esta opci&oacute;n proporcionar&aacute; 
acoplamientos permiti&eacute;ndole 
instalar los m&oacute;dulos de CPAN y los paquetes de 
Win32 PPM por usar del uso
END
};

$months = {
         '01' => 'enero',
         '02' => 'feb',
         '03' => 'marzo',
         '04' => 'abr',
         '05' => 'mayo',
         '06' => 'jun',
         '07' => 'jul',
         '08' => 'agosto',
         '09' => 'sept',
         '10' => 'oct',
         '11' => 'nov',
         '12' => 'dic',
};

1;

__END__

=head1 NAME

CPAN::Search::Lite::Lang::es - export some common data structures used by CPAN::Search::Lite::* for Spanish

=head1 SEE ALSO

L<CPAN::Search::Lite::Lang>

=cut

