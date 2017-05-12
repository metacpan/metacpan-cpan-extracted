package CGI::Embedder;
use strict;

our $VERSION = 1.21;

# Настроечные константы.
my $c0=chr(1);        # символ для qw
my %ExpandCache=();   # кэш

# string Compile(string $Content [string \&filter_func(string $st)])
# Преобразует весь текст в строке $Content ВНЕ тэгов <? и ?> в серию print.
# Сами тэги <? и ?>, конечно, удаляются. Если затем проработать результат 
# eval-ом, напечатается "развернутый" шаблон в чистом виде. Если задан 
# параметр &filter_func, то эта функция вызывается для каждой подстроки 
# вне <? и ?>. Она должна возвращать обработанную строку. Но если в 
# ней появятся <? и ?>, они уже не будут обработаны!
sub Compile($;$)
{ my ($Cont,$filter)=@_;
  $Cont =~ s{^\t*}{}mgo;
  $Cont="?>$Cont<?";
  $Cont=~s{<\?=}{<?print }sgo;
  if(!$filter) {
    $Cont=~s{\?>(\n?)(.*?)<\?}{"$1;print(qq$c0"._Slash($2)."$c0);"}sgeo;
  } else {
    $Cont=~s{\?>(\n?)(.*?)<\?}{"$1;print(qq$c0"._Slash(&$filter($2))."$c0);"}sgeo;
  }
  $Cont=~s{print qq$c0$c0}{}sgo;
  return $Cont;
}

# void Expand(string $Templ [,string $CacheId] [,string $Filename])
# "Разворачивает" шаблон $Templ. Результат печатается с помощью print. 
# Потом его можно перехватить с помощью модуля CGI::WebOut. Удобно 
# использовать в "почтовых" целях. Если задан параметр $CacheId, то 
# шаблон кэшируется, и для следующего вызова ExpandTemplate() 
# с таким же $CacheId компилирование шаблона уже не произойдет.
# Параметр $Filename влияет только не сообщения об ошибках, которые 
# могут возникнуть в шаблоне $Templ.
sub Expand($;$;$;$)
{ my ($Templ,$CacheId,$Filename,$pkg)=@_;
  my $Compiled;
  if(defined($CacheId) && exists($ExpandCache{$CacheId})) {
    $Compiled=$ExpandCache{$CacheId}; 
  } else {
    $Compiled=Compile($Templ); 
    if(defined($CacheId)) { $ExpandCache{$CacheId}=$Compiled; }
  }
  $pkg||=caller;
  $Filename||="template";
  $@=undef; 
  eval("package $pkg; no strict;\n#line 1 \"$Filename\"\n$Compiled;");
  die $@ if $@;
  return;
}

# string ExpandFile($fname)
# То же, что и Expand(), только считывает файл с диска.
sub ExpandFile($)
{ my ($fname)=@_;
  local *F;
  if(!open(F,$fname)) {
    require Carp;
    Carp::croak("Could not open the file $fname");
  }
  binmode(F);
  local ($/,$\);
  return Expand(<F>,$fname,$fname,caller);
}

# string _Slash(string $st)
# Проставляет слэши перед специальными символами, а также обрабатывает
# вхождения символов-разделителей.
sub _Slash($)
{ my ($st)=@_;
  $st=~s/$c0/$c0."$c0".qq$c0/g;
  $st=~s/(\r?\n\s*#line\s*\d[^\n]*\r?\n)/$c0;$1print qq$c0/gs;
  $st=~s/\\(?!\$)/\\\\/g;
  $st=~s/\@/\\\@/g;
  $st=~s/\%/\\\%/g;
  return $st;
}

return 1;
__END__


=head1 NAME

CGI::Embedder - Module for HTML embedding in your Perl programs.

=head1 SYNOPSIS

  #!/usr/local/bin/perl -w 
  use CGI::Embedder; 
  ...
  CGI::Embedder::ExpandFile("tmpl.htm");

  # where tmpl.htm is:
  <h1>Hello</h1>
  <?for(my $i=10; $i<20; $i++) {?>
    Hello, world N$i! 
    $i * $i = <?=$i*$i?><br>
  <?}?>

=head1 DESCRIPTION

This module is used to parse e-perl templates.

=over 4

=item C<use CGI::Embedder>

Loads the module core. No subroutines are exported.

=item C<Compile($content [,string \&filter_func(string $input)])>

Converts all the <?...?> sequences in C<$content> to C<print> series.
You may then run C<eval> for resulting string to print out the template.
Template example:

  Text with variable: $variable.
  Running: <?do_some_work(); do_another_work()?>
  Product is: <?=$a*$b*$c?>

If C<&filter_func> defined, this function is used to parse
the the HTML placed outside code tags.

=item C<Expand($templ [,$cacheId] [,$filename])>

Compiles and then expands (runs) the template C<$templ>. Compiled code
is cached using C<$cacheId> hash-code. Parameter C<$filename> is used
ONLY in resulting error messages. If your need to get the output as string,
use CGI::WebOut to grab it:

  use CGI::WebOut;
  my $str=grab { CGI::Embedder::Expand($template) };

=item C<ExpandFile($filename)>

Does the same as Expand(), but always expands the file C<$filename> content.

=back

=head1 AUTHOR

Dmitry Koterov <koterov at cpan dot org>, http://www.dklab.ru

=cut
