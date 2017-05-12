package CPAN::Search::Lite::Lang::pt;
use utf8;
use strict;
use warnings;
our $VERSION = 0.77;

use base qw(Exporter);
our (@EXPORT_OK, $chaps_desc, $pages, $dslip, $months);
@EXPORT_OK = qw($chaps_desc $pages $dslip $months);

$chaps_desc = {
        2 => q{Módulos da Distribuição},
        3 => q{Suporte ao Desenvolvimento},
        4 => q{Interface ao Sistema Operativo},
        5 => q{Aparelhos de Rede (IPC)},
        6 => q{Utilidades de Tipos de Dados},
        7 => q{Interfaces a Bases de Dados},
        8 => q{Interfaces ao Utilizador},
        9 => q{Interfaces a Linguagens},
        10 => q{Ficheiros e Sistemas de Concorrência},
        11 => q{Processamento de Strings, Língua e Texto},
        12 => q{Processamento de Argumentos e Parametros},
        13 => q{Internacionalização Localização},
        14 => q{Segurança e Encriptação},
        15 => q{World Wide Web HTML HTTP CGI},
        16 => q{Utilidades para Servidores e Daemons},
        17 => q{Métodos de Arquivo e Compressão},
        18 => q{Imagens (Pixmaps Bitmaps)},
        19 => q{Mails e Novidades Usenet},
        20 => q{Controlo de Fluxo},
        21 => q{Gestão de Ficheiros (Input Output)},
        22 => q{Módulos para Microsoft Windows},
        23 => q{Outros Módulos},
        24 => q{Interfaces a Programas Comerciais},
        26 => q{Documentação},
        27 => q{Pragma},
        28 => q{Perl6},
        99 => q{Ainda não na Lista de Módulos},
};

$dslip = {
    d => {
      M => q{Adulto (definição não rigorosa)},
      R => q{Disponibilizado},
      S => q{Standard, disponívem com o Perl 5},
      a => q{Em testes (alfa)},
      b => q{Em testes (beta)},
      c => q{Em construção (pre-alfa, ainda não disponibilizado)},
      desc => q{Nível de Desenvolvimento (Nota: *SEM ESCALAS TEMPORAIS IMPLICADAS*)},
      i => q{Ideia, listado para ganhar consenso, ou para marcar lugar},
    },
    s => {
      a => q{Abandonado, o módulo foi abandonado pelo autor},
      d => q{Programador},
      desc => q{Nível de Suporte},
      m => q{Listas de discussão},
      n => q{Nenhum conhecido, tente comp.lang.perl.modules},
      u => q{Grupos de novidades Usenet: comp.lang.perl.modules},
    },
    l => {
      '+' => q{C++ e perl, será necessário um compilador de C++},
      c => q{C e perl, será necessário um compilador de C},
      desc => q{Linguagem Usada},
      h => q{Hibrida, escrito em Perl com código C opcional (compilador não necessário)},
      o => q{Perl e outra linguagem que não C ou C++},
      p => q{Só Perl, compiladores não necessários, deverá ser independente de plataforma},
    },
    i => {
      O => q{Orientado a objectos usando referências "blessds" e/ou herança},
      desc => q{Estilo de Interface},
      f => q{Funções standard, sem uso de referências},
      h => q{Hibrido, disponíveis interfaces orientadas a objectos e a funções},
      n => q{Sem interface (huh?)},
      r => q{Uso de algumas referências "unblessed" ou "ties"},
    },
    p => {
      a => q{Licença Artística},
      b => q{BSD: A Licença BSD},
      desc => q{Licença},
      g => q{GPL: GNU General Public License},
      l => q{LGPL: "GNU Lesser General Public License" (anteriormente conhecida como "GNU Library General Public License")},
      o => q{outra (mas a distribuição é permitida sem restrições)},
      p => q{Standard-Perl: o utilizador pode escolher entre GPL ou Artística},
    },
};

$pages = { title => 'Navegar e procurar no CPAN',
           list => { module => 'Módulos',
                    dist => 'Distribuições',
                    author => 'Autores',
                    chapter => 'Categorias',
                  },
          buttons => {Home => 'Início',
                      Documentation => 'Documentação',
                      Recent => 'Recentes',
                      Mirror => 'Mirror',
                      Preferences => 'Prefer&ecirc;ncias',
                      Modules => 'Módules',
                      Distributions => 'Distribuições',
                      Authors => 'Autores',
                  },
           form => {Find => 'Encontrar',
                    in => 'em',
                    Search => 'Procurar',
                   },
           Problems => 'Problemas, sugestões, ou comentários para',
          Language => 'Escolha da l&iacute;ngua',
           Questions => 'Questões? Veja',
           na => 'não especificado',
           bytes => 'bytes',
           download => 'Descarregar',
           cpanid => 'Identificador CPAN',
           name => 'Nome completo',
           email => 'email',
           results => 'resultados encontrados',
           try => 'Tentar esta pesquisa em',
           categories => 'Categorias',
           category => 'Categoria',
           distribution => 'Distribuição',
           author => 'Autor',
           module => 'Módulo',
           version => 'Versão',
           abstract => 'Resumo',
           released => 'Disponibilizado',
           size => 'Tamanho',
           cs => 'MD5',
           additional => 'Ficheiros Adicionais',
           links => 'Ligações',
           info => 'informação',
           prereqs => 'Prér equisitos',
           packages => 'pacotes para',
           related => 'relacionads',
           browse => 'Navegar por',
           uploads => 'Disponibilizados nos últimos',
           days => 'dias',
           more => 'mais',
           nada => 'Nenhum resultado encontrou',
           error1 => 'Desculpe - houve um erro na sua pesquisa por',
           error2 => 'de tipo',
           error3 => '',
           error4 => 'Desculpe - um erro foi encontrado.',
           error5 => << 'END',
O erro foi gravado. Se este erro ocorreu ao tentar usar
uma expressão regular, talvez queira verificar a
<a 
href="http://www.mysql.com/documentation/mysql/bychapter/manual_Regexp.html#Regexp">
sintaxe permitida</a>. 
<p>
Se lhe parece que isto é um erro da ferramenta de pesquisa,
pode ajudar a corrigir enviando uma mensagem para
END
           error6 => << 'END',
com detalhes sobre o que é que procurava quando isto aconteceu.
Obrigado!
END
           missing1 => 'Desculpe - nenhum resultado para',
           missing2 => 'foram encontrados do tipo',
           missing3 => 'Por favor tente outro termo de procura.',
           missing4 => 'Desculpe - Não consegui entender o que perguntou. Por favor, tente de novo.',
           mirror => 'Mirrors do CPAN',
           public => 'Mirror público',
           none => 'Nenhum -- Use um URL específico',
           custom => 'URL',
           default => 'A ligação por omissão de',
           alt => 'ou',
           install => 'Instale',
           mirror1 => << 'END',
Com este formulário pode especificar de onde quer
descarregar os ficheiros (precisa de ter os cookies activos).
O seu valor actual é
END
           mirror2 => << 'END',
irei tentar redireccionar para um mirror CPAN próximo
baseado no seu país de origem.
END
           webstart => << 'END',
Selecionar esta op&ccedil;&atilde;o fornecer&aacute; 
as liga&ccedil;&otilde;es permitindo o de instalar 
os m&oacute;dulos de CPAN e os pacotes de Win32 PPM 
usar-se da aplica&ccedil;&atilde;o
END
};

$months = {
         '01' => 'Jan',
         '02' => 'Fev',
         '03' => 'Mar',
         '04' => 'Abr',
         '05' => 'Mai',
         '06' => 'Jun',
         '07' => 'Jul',
         '08' => 'Ago',
         '09' => 'Set',
         '10' => 'Out',
         '11' => 'Nov',
         '12' => 'Dez',
};

1;

__END__

=head1 NAME

CPAN::Search::Lite::Lang::pt - export some common data structures used by CPAN::Search::Lite::* for Portuguese

=head1 SEE ALSO

L<CPAN::Search::Lite::Lang>

=cut

