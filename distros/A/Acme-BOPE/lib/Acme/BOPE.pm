package Acme::BOPE;

require 5.005_62;
#use strict;
#use warnings;

our $VERSION =  0.01;

#use Exporter;
#
#our @ISA = qw(Exporter);
#our @EXPORT = qw(canta_hino fato);

my @ignoradas = (
  "[dn]?[oa][s]?"       , # o, a, os, as, dos, nos, das, nas, no, na, do, da
  "[nd]?e(?:ss|l)[ae]s?", # ele, ela, dele, dela, desse, dessa nesse, nessa
  "s(?:eu|ua)s?"        , # seu, sua
  "(?:uma?|eu)"         , # uma, eu
  "com"                 ,
  "sem"                 ,
  "porra[?!]*"          ,
  "merda[?!]*"          ,
  "viado[?!]*"          ,
);

#my $ignoradas = join "|", @ignoradas;

use Filter::Simple;

FILTER_ONLY
  all => sub {
  my $package = shift;
  my %par = @_;
  
  if ( $par{'DEBUG'} ) {
    filter($_);
    Perl::Tidy::perltidy(source => \$_, destination => \$_)
        if eval "require Perl::Tidy";
    print;
  }
#  my $DEBUG = $par{DEBUG} if $par{DEBUG};
#  return unless $DEBUG;
#  filter($_);
#  Perl::Tidy::perltidy(source => \$_, destination => \$_)
#   if eval "require Perl::Tidy";
#  print if $DEBUG;
#  exit;
},
  code_no_comments  => \&filter;
sub filter {

  $_ = "\$senhor = \$\$_;$/" . $_;
  $_ = "\$| = 1;$/" . $_;
  s#pelot[ãa]o, cantar hino#print Acme::BOPE::canta_hino#gi;
  s#Capit[ãa]o Nascimento#print Acme::BOPE::fato#gi; # mudar por frase legal

  s{\b(?:naum|não|nao|nunca|jamais)\s+(?:ser(?:á|ão)|é|eh)\b}{ne}gi;
  s{\b(?:naum|não|nao|nunca|jamais)\b}{not}gi;
  s{\bser(?:á|ão|a|ah|ao)\b}{eq}gi;
  s{\b(?:é|eh)\b}{=}gi;
  s{\bfor\b}{eq}gi;

  s{\bvale(?:rá)?\b}{==}gi;

  s{\bvai pra guerra\b}{system}gi;

  s#\bse\s+(.*?)\s+ent[ãa]o\b#if($1){\n#gi;
  s#\bent[ãa]o\b#\{#gi;
  s#\bfaz isso aqui[:]?\b#\{#gi;
  s#\bsen[ãa]o\b#}else{\n#gi;
  s#\bestamos entendidos[?!]*\b#}#gi;
  s#\bos? senhor(?:es)? est(?:[aã]o|[aá]) fazendo (?:o )?seu instrutor muito feliz(?:...)#}#gi;
  s{\bfala(?: agora)?[!:]*}{print}gi;
  s{\bgrita[!:]*\b}{print}gi;
  s{\bvai dar merda,?}{warn}gi;
  s{
    \b(?:v(?:ou|ai)\s+)?gritar\s+(?:em|n[oa]|ao?) (.*?):
   }
   {
    (my $file = $1) =~ s/\W/_/g;
    $file =~ s/^_+|_+$//g;
    my $fh = uc $file;
    "open $fh, \">>$file\";
     print \{$fh\}"
   }giex;

  s{\bchega[!]*\b}{last}gi;
  s{\bpára[!]*\b}{last}gi;

  s#\bpara\s+(.*?)\s+(?:ent[aã]o|,)fa[cç]a\b#for($1){#gi;
  s#\benquanto\s+(.*?)\s*,#while($1){\n#gi;

  s{\bfati(?:a|ou)\b}{split}gi;
  s{\bpass(?:a|ou)\b}{next}gi;

  s{\bpede pra sair\b}{die}gi;
  s{\b(?:eu )?desisto\b}{exit}gi;
  s{\bdesistiu\b}{= undef}gi;
  s{\bbota na conta do papa\b}{exit}gi;

  s{\be\b}{and}gi;
  s{\b(?:ent[ãa]o\s+)?senta o dedo nessa porra\b}{print "Caveira meu capitao!"}gi;
 
  # variaveis
  no warnings;
  s#\bsenhor(?:\s+(\d{2,}))?,#\$senhor = \\\$_$1;\n#gi;
  use warnings;
  s{\b(?:senhor|o)\s+(\d{2,})\b}{sprintf"\$_%s ", defined $1?$1:""}gie;
  s{([^\$])senhor|voc[êe]}{$1\$\$senhor}gi;

  # perguntas
  s#(100\s*%\s+(\d{2,})?\?+)#
   print "$1";
   chomp(\$_$2 = <>);
   \$_$2 =~ /^100%|sim|s/ &&#gi;
  s#
    ((?:a?onde (?:es)t[aá]|cad[êe])\s+[oa]s?\s+(\w+)[?!]+)
   #
    my $var;
    ($var = $2) =~ s/\W/_/g;
    $var = lc($var);
    qq:
       print "$1";
       chomp(\$$var = <>);
       print "0" . (int(rand 9) + 1) . ", pega a vassoura!\$/";
      :;
   #gixe;

  my @quotes = m#"(.*?)"#gsm;
  s#"(.*?)"#sprintf qq/"%d"/, my $i++#gsme;

  # palavras que são ignoradas dentro do código  
   foreach my $ignora (@ignoradas){
      s{\b$ignora\b}{}gi;
   }

  s#(?:(?:OK)?\s*[!?]+)#;#gi;
 
  s#"(\d+)"#"$quotes[$1]"#g;

};

# hinos do bope:
sub canta_hino {
    my $self = shift;
    my @hinos = (
         'O interrogatório é muito fácil de fazer/pega o favelado e dá porrada até doer/O interrogatório é muito fácil de acabar/pega o bandido e dá porrada até matar',
         'Esse sangue é muito bom/ já provei não tem perigo/é melhor do que café/é o sangue do inimigo',
         'O quintal do inimigo/não se varre com vassoura/se varre com granada/com fuzil, metralhadora',
         'São os homens da caveira/do bornal e do cantil/Sua força combativa/está na ponta do fuzil',
         'Cachorro latindo/Criança chorando/Vagabundo vazando/É o BOPE chegando',
         'Tropa de elite/osso duro de roer/Pega um, pega geral/também vai pegar você',
         'Homem de preto, qual é sua missão?/Entrar pela favela e deixar corpo no chão/Homem de preto, o que é que você faz?/Eu faço coisas que assustam o satanás',
       );
    $hinos[int(rand(@hinos))];

}

# frases sobre o cap.nascimento
sub fato {
    my $self = shift;
    my @fatos = (
        'Deus disse que iria fazer o mundo em 7 anos. Capitão Nascimento disse bem alto: "O senhor é um fanfarrão, Sr. 01. O senhor tem 7 dias, sr. 01! SETE DIAS!"',
        'Quando vivia no paraíso, Capitão Nascimento forçou Eva a comer a maçã, dizendo: "Come a porra da maçã 02! Tá com nojinho, 02? Come tudo, porra!"', 
        'A farda do Capitão Nascimento é preta porque nenhuma outra cor quis ficar perto dele.',
        'O Capeta queria entrar no BOPE, mas o Capitão Nascimento fez ele desistir apenas dizendo: "666, o senhor é o novo xerife!"',
        'O Capeta vendeu a alma para o Capitão Nascimento.',
        'Capitão Nascimento não sai de lugar nenhum devendo a ninguém, sempre põe na conta do Papa.',
        'Quando Deus disse "Que se faça a luz!". Capitão Nascimento falou "Tá de sacanagem, Sr. 01? Tá com medinho do escuro, Sr. 01?"',
        'Quando Deus resolveu criar o Universo foi pedir permissão ao Capitão Nascimento e ele respondeu: "É 100%? Então senta o dedo nessa porra!"',
        'A roupa do Super-Homem era preta até o Capitão Nascimento dizer: "Tira essa roupa preta que você não é caveira, você é MOLEQUE, ouviu? MO-LE-QUE!"',
        'Capitão Nascimento trabalhou como negociador da polícia. Seu trabalho era ligar para os seqüestradores e dizer: "Pede pra sair, porra!"',
        'Quantos Capitães Nascimento são necessários para trocar uma lâmpada? Nenhum, Capitão Nascimento também mata no escuro.',
        'Capitão Nascimento não lê livros, ele os coloca no saco até conseguir toda a informação que precisa.',
        'Uma vez ele esqueçeu onde deixou as chaves do seu caveirão. Ele se colocou no saco por 40 segundos e lembrou!',
        'Não existiam mesmo armas de destruição em massa no Iraque. Capitão Nascimento mora no Rio de Janeiro.',
        'Porque você acha que não existe terrorismo no Brasil?',
        'Nunca, em nenhuma hipotese, durma na frente do Capitão Nascimento. Ele vai pedir pra você fazer a bondade de segurar a granada.',
        'Em um de seus mandamentos, Deus disse: "Não Matarás". O Capitão Nascimento disse para Deus: "Tá de sacanagem, Sr. 01? Cê tá de sacanagem comigo, Sr. 01?"',
        'Não houve impeachment no Governo Collor. O Capitão Nascimento chegou no Palácio do Planalto e disse para o Collor:: "Pede prá sair!! Pede prá sair!!"',
        'No dia de São Cosme e São Damião, o Capitão Nascimento só pegava saco de doce que tivesse chiclete de Caveira.',
        'Capitão Nascimento fez com que o Seu Madruga pagasse o aluguel - todos os 14 meses atrasados - e adiantasse mais dois.',
        'Capitão Nascimento foi ao programa do Faustão e fez com que ele falasse enquanto o faustão ficava calado.',
        'Capitão Nascimento gritou no centro de Buenos Aires que Pelé é o rei do futebol e todos os argentinos concordaram.',
        'Capitão Nascimento fez um operador de telemarketing dizer: "desculpa, juro que não ligo mais".',
        'Capitão Nascimento resolve o travamento do Windows colocando o PC no saco.',
        'Capitão Nascimento disse pra Will Smith depois de ver "MIB": O senhor é um fanfarrão! Homens de Preto é o caralho, só o BOPE usa preto! Seu viado!',
        'Capitão Nascimento dorme com um travesseiro debaixo de uma arma.',
        'Capitão Nascimento sabe exatamente onde está Carmen Sandiego',
        'Principais causas de morte no Brasil: 1. Ataque do coração, 2. Cap. Nascimento, 3.Câncer; mas a opção 1 é maior porque a maioria dos bandidos morre do coração quando vêem o capitão.',
       );
    print $fatos[int(rand(@fatos))];
}

42;

__END__

=head1 NAME

Acme::BOPE.pm - Programe armado, cumpadi, e de farda preta.

I<Note: this Acme module lets you program the way the BOPE (brazilian police's special operations squad) policemen talk in the movie "Tropa de Elite". Since its intended audience have to understand portuguese in order to enjoy the module, the rest of the documentation is all in pt_BR. Have fun! Oh, also, this is not to be taken seriously, nor does it expresses the opinion of any of the involved people, nor is oficially linked to the movie.>

B<Esse módulo foi feito como uma brincadeira em relação ao filme "Tropa de Elite", e não deve ser levado à sério. Nada do que está escrito aqui expressa a opinião dos autores ou qualquer outro envolvido direta ou indiretamente com o mesmo, e não há qualquer tipo de ligação oficial com o filme. Divirtam-se!>



=head1 VERSÃO

Versão 0.01



=head1 SINOPSE

   use Acme::Bope;
  
E a partir daí poderá escrever seus programas assim:

   Senhor 01, o senhor eh um "fanfarrao"!
   se o senhor for "moleque" entao pede pra sair "seu viado"! 
   senao senta o dedo nessa porra e bota na conta do Papa!
   vai dar merda, "vai morrer gente...";
   
   O 01 DESISTIU!!!
   
   Os senhores estao fazendo o seu instrutor muito feliz...

que é mais ou menos equivalente a:

   $_01 = "fanfarrao";
   if ($_01 eq "moleque") {
      die "seu viado";
   }
   else {
      print "Caveira, meu capitao!\n" and exit;
      warn "vai morrer gente";

      $_01 = undef;
   }

Você ainda pode dar o comando para ouvir seu pelotão...quer dizer, seu programa... cantar um dos famosos hinos do BOPE:

    Pelotão, cantar hino!
    # Cachorro latindo/Criança chorando/Vagabundo vazando/É o BOPE chegando

Essa versão possui 7 hinos cadastrados. Se você souber de outro, grite!

E, se você tem alguma dúvida sobre o seu capitão, basta citar o nome dele pra ouvir um dos fatos:

    Capitão Nascimento?
    # Capitão Nascimento dorme com um travesseiro debaixo de uma arma.

Essa versão possui 28 "fatos" cadastrados. Se você souber de outro, grite! E antes que alguém pergunte, não vamos incluir nenhum fato que seja "compartilhado" com Chuck Norris ou Jack Bauer, porque eles são MOLEQUES!



=head1 DESCRIÇÃO

Criado na base do morro da Babilônia, Rio de Janeiro, em plena noite de baile funk, este módulo permite que os senhores façam incursões de programação Perl usando apenas jargões e linguagens retiradas do famoso filme 'Tropa de Elite' de José Padilha, com estratégia e sem fanfarronice. Isso é, se vocês conseguirem. Senão, pede pra sair... e bota na conta do Papa.


=head1 EQUIVALÊNCIAS

Caso ainda seja novo no batalhão, aqui vão algumas equivalências:

=over 4

=item * I<(print)> - fala, grita

=item * I<(warn "MENSAGEM")> - vai dar merda "MENSAGEM"

=item * I<(system "COMANDO")> - vai pra guerra "COMANDO"

=item * I<(split)> - fatia, fatiou

=item * I<(next)> - passa, passou

=item * I<(last)> - chega!!! pára!!!

=item * I<(die)> - pede pra sair

=item * I<(exit)> - desisto, eu desisto, bota na conta do papa

=back

Blocos podem ser escritos de forma simples e direta:

    faz isso aqui:
        ...
    estamos entendidos?
    # ou ainda: os senhores estão fazendo o seu instrutor muito feliz

É o mesmo que:

    {
        ...
    }

Condicionais são feitos assim:

    se EXPRESSÃO então
        ...
    senão
        ...
    estamos entendidos?

É o mesmo que:

    if (EXPRESSÃO) {
        ...
    }
    else {
        ...
    }

Você pode também usar laços (laço de homem, nada de ficar botando lacinho nos seus programas!!!):

   para (...) então, faça
      ...
   estamos entendidos?

É o mesmo que:

   for (...) {
      ...
   }

ou ainda:

   enquanto (...)
      ...
   estamos entendidos?

É o mesmo que:

   while (...) {
      ...
   }

Lembrando que comparações podem ser feitas assim:

   ne      nunca serão, jamais serão, não é, não será, jamais será
   not     não, nunca, jamais
   eq      será, serão, for
   ==      vale, valerá


É possível ainda adicionar uma série de palavras adicionais para deixar seu código mais "legível", e impor a ordem entre esses programadores fanfarrões.

=over 4

=item * o, a, os, as, no, na, nos, nas, do, da, dos, das

=item * ele, ela, eles, elas, dele, dela, deles, delas, desse, dessa, desses, dessas, nesse, nessa, nesses, nessas

=item * seu, sua, seus, suas

=item * eu

=item * com, sem

=item * porra, merda, viado (e pode adicionar quantas interrogações ou exclamações quiser depois)

=back 

=head1 MAIÚSCULAS E ACENTOS

No linguajar do Bope, nenhuma palavra é sensível a caixa. Você pode sussurar comandos ou gritar com vagabundos, tudo funciona. Exemplos:



=head1 DIAGNÓSTICO

Se você acha que fez m#$%@ e quer ver o código equivalente em Perl (em vez de simplesmente executar seu programa inútil), passe o parâmetro C<DEBUG> para o módulo:

   use Acme::BOPE DEBUG => 1;

Quanto tempo você precisa pra depurar? 10 minutos???? Fanfarrão.



=head1 DEPENDÊNCIAS

Tu é dependente, mermão????? Se quiser ver o código de debug cheio de frufru, instala o Perl::Tidy que é 100%.

Ah, e se os senhores não tiverem o Filter::Simple instalado, nunca serão...



=head1 BUGS

Provavelmente um monte. Se encontrar algum, avisa via RT. Mas sem fanfarrice, estamos entendidos?

(temos ainda que atualizar a documentação do módulo para incluir variáveis


=head1 AUTORES

Breno G. de Oliveira C<< <garu at cpan.org> >> e Fernando Corrêa C<< <fco at cpan.org> >>

Esse módulo foi feito como uma brincadeira dentro da comunidade Perl sobre o filme Tropa de Elite, na semana de lançamento do filme. Apresentamos durante o YAPC::Brasil 2007 e o pessoal gostou tanto que encheu a nossa paciência para botarmos no ar. Taí.


=head1 RECONHECIMENTOS E AGRADECIMENTOS

O código foi fortemente baseado no L<Acme::Lingua::Strine::Perl> do Simon Wistow C<simon [at] twoshortplanks.com>

Agradecimentos especiais ao Bruno C. Buss pelas idéias e colaborações, e a todo o pessoal do ônibus que nos levou até São Paulo na véspera do evento, que nos aturaram madrugada a dentro enquanto terminávamos o desenvolvimento e corrigíamos alguns bugs.



=head1 VEJA TAMBÉM

L<Filter::Simple>, L<Acme::Lingua::Strine::Perl>
L<http://www.tropadeeliteofilme.com.br>



=head1 LICENÇA E COPYRIGHT

Copyright 2008 Breno, Fernando. Todos os direitos reservados.

Este módulo é software livre; você pode redistribuí-lo e/ou modificá-lo sob os mesmos termos que o Perl em si. Veja L<perlartistic>.



=head1 GARANTIA

Nenhuma. Eu hein...
