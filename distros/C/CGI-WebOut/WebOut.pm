#
# Гарантирует, что вывод через print можно безопасно направить в браузер.
# То есть, буферизует его, следит за заголовками, а также за тем, чтобы
# заголовок Content-type всегда выводился перед текстом документа.
# Помимо всего этого, следит за ошибками, возникающими в скрипте, и 
# перенаправляет их в браузер (в виде комментариев или видимого текста).
# Также позволяет выборочно перехватывать выходной поток скрипта для
# последующей обработки: $text = grab { print "Hello" }.
# В общем, полная эмуляция поведения PHP.
package CGI::WebOut;
our $VERSION = "2.25";

use strict;
use Exporter; our @ISA=qw(Exporter);
our @EXPORT=qw(
  ER_NoErr
  ER_Err2Browser 
  ER_Err2Comment 
  ER_Err2Plain
  ErrorReporting
  grab
  echo  
  SetAutoflush 
  NoAutoflush 
  UseAutoflush 
  Header
  HeadersSent
  Redirect
  ExternRedirect
  NoCache
  Flush
  try catch warnings throw
);


##
## Константы
##
sub ER_NoErr { 0 }                # Запретить вывод об ошибках
sub ER_Err2Browser { 1 }          # Ошибки и предупреждения направить в браузер
sub ER_Err2Comment { 2 }          # То же, но в виде <!--...-->-комментариев
sub ER_Err2Plain { 3 }            # То же, но в виде plain-текста


##
## Внутренние переменные
##
#our $DEBUG = "/wo";              # отладочный режим - задает имя файла.
our $DEBUG = undef;              # отладочный режим - задает имя файла.
our $UseAutoflush = 1;           # Режим автосброса включен
our $HeadersSent = 0;            # признак: заголовки уже посланы
our @Headers = ();               # заголовки ответа
our $NoCached = 0;               # документ не кэшируется
our $Redirected = 0;             # была переадресация
our $ErrorReporting = 1;         # вывод ошибок в браузер включен
our @Errors = ();                # здесь накапливаются ошибки
our @Warns = ();                 # предупреждения

# К сожалению, вместо того, чтобы хранить текущий и корневой ОБЪЕКТЫ вывода, 
# приходится хранить лишь СТРОКОВЫЕ БУФЕРА. Дело в том, что хранение объекта
# увеличивает его счетчик ссылок, а значит, если в программе встретится:
#   $b = new CGI::WebOut();
#   ...
#   $b = undef;
# то деструктор для $b вызван не будет (т.к. ссылка на него записана в $CurObj).
# Если же хранить в объектах ссылки на строковые буфера, а ссылки на сами
# объекты дополнительно НЕ хранить, деструктор вызывается, как надо.
#
# Это все также означает, что получить в этом модуле ссылку на текущий 
# ОБЪЕКТ ВЫВОДА нельзя никак. Можно лишь получить ссылку на его буфер.
# Таким образом, echo всегда работает со строковым буфером, но НЕ объектом.
our $rRootBuf = \(my $s="");     # главный буфер вывода
our $rCurBuf;                    # текущий буфер вывода

#
# Algorythm is:
# 1. Tie STDOUT to newly created CGI::WebOut::Tie.
# 2. Constructor CGI::WebOut::Tie->RIEHANDLE creates new objecc CGI::WebOut
#    and stores its reference in its property. It is IMPORTANT that there 
#    are NO other reserences to this object stored in some other place.
# 3. That's why, when STDOUT is untied (in END or during global destruction)
#    CGI::WebOut object is destroyed too.
# 4. In destructor CGI::WebOut->DESTROY works code: if this object is the 
#    first (root), Flush() is called and errors are printed.
#


# Synopsis: use CGI::WebOut($restart=0)
# При подключении проверяет связывание STDOUT и, если свящанности нет или
# она поменялась, устанавливает ее на себя.
#
# Вниманию пользователей FastCGI: import работает не так, как хотелось бы. 
# Например, если в цикле с двумя итерациями написать use CGI::WebOut, то 
# реально import будет вызван только 1 раз. Зато если дважды написать эту же 
# команду, то import вызовется дважды. Гарантированно import запускается 
# следующей конструкцией: eval("use CGI::WebOut(1)"). Ее рекомендуется 
# вставлять внутрь цикла обработки подключений FastCGI.
#
# Если параметр $restart равен true, то все происходит так, будто бы 
# заголовки ответа еще никогда не посылались.


##
## Общедоступные статические функции. 
##

# void retieSTDOUT($restart=false)
# Запоминаем старый STDOUT (длинное название - специально, чтобы не 
# злоупотребляли!) и устанавливает свой перехватчик на STDOUT. В случае, 
# если свой перехватчик уже установлен, ничего не делает. 
my $numReties;
sub retieSTDOUT
{ my ($needRestart) = @_;
  $needRestart ||= !$numReties++;
  # Handle all warnings and errors.
  $SIG{__WARN__} = sub { &Warning(($_[0] !~ /^\w+:/ ? "Warning: " : "").shift) };
  $SIG{__DIE__} = sub { return if ref $_[0]; &Warning(($_[0] !~ /^\w+:/ ? "Fatal: " : "").shift) };
  # Если начат новый скрипт, сбрасываем признак отсылки заголовков.
  if ($needRestart) {
    $HeadersSent = $Redirected = $NoCached = 0;
    @Headers = ();
    $$rRootBuf = '';
  }
  # Если ничего не изменилось, выходим
  return if tied(*STDOUT) && ref tied(*STDOUT) eq __PACKAGE__."::Tie";
  tie(*STDOUT, __PACKAGE__."::Tie", \*STDOUT, tied(*STDOUT));
}


# Проверяет, используется ли библиотека Web-скриптом или обычным
sub IsWebMode() { 
  return $ENV{SCRIPT_NAME}? 1 : 0 
}


# Посланы ли заголовки?
sub HeadersSent { 
  return $HeadersSent;
}


# static int echo(...)
# Выводит список агрументов в ТЕКУЩИЙ активный буфер. Если этот 
# буфер направлен непосредственно в браузер, вызывает Flush().
# Возвращает число выведенных символов.
sub echo {
  # В случае наличия undef-значений в списке делаем то же,
  # что и print.
  if(grep {!defined $_} @_) {
    # Если модуля нет - не страшно, просто ничего не печатается.
    eval { require Carp } 
      and Carp::carp("Use of uninitialized value in print"); 
  }
  my $txt = join("", map { defined $_? $_:"" } @_); 
  return if $txt eq "";
  $$rCurBuf .= $txt;
  Flush() if $UseAutoflush && $rCurBuf == $rRootBuf;
  return length($txt);
}


# Перехват выходного потока. Использование:
# $grabbed = grab { 
#     print 'Hello!' 
# } catch {
#     die "An error occurred while grabbing the output: $@";
# };
# или то же, но без catch: 
# $grabbed = grab { print 'Hello!' };
sub grab(&@)
{ my ($func, $catch)=@_;
  my $Buf = CGI::WebOut->new; 
  $@ = undef; eval { &$func() };
  if ($@ && $catch) { chomp($@); local $_ = $@; &$catch; }
  return $Buf->buf;
}


# static Header($header)
# Устанавливает заголовок ответа.
sub Header($)
{ my ($head)=@_;
  if ($HeadersSent) {
    eval { require Carp } 
      and Carp::carp("Oops... Header('$head') called after content had been sent to browser!\n"); 
    return undef; 
  }
  push(@Headers, $head);
  return 1;
}


# Сбрасывает содержимое главного буфера в браузер.
sub Flush() { 
  # Отключаем внутреннюю буферизацию Perl-а
  local $| = 1; 
  # Если заголовки еще не отосланы, отослать их
  if (!$HeadersSent && IsWebMode()) {
    my $ContType="text/html";
    unshift(@Headers,"X-Powered-By: CGI::WebOut v$VERSION (http://www.dklab.ru/chicken/4.html), (C) by Dmitry Koterov");
    # Ищем Content-type, чтобы потом отправить его в конце
    for (my $i=0; $i<@Headers; $i++) {
      if ($Headers[$i]=~/^content-type: *(.*)$/i) {
        $ContType = $1; splice(@Headers, $i, 1); $i--;
        next;
      }
      if ($Headers[$i]=~m/^location: /i) {
        $Redirected = 1;
      }
    }
    if (!$Redirected) {
      push(@Headers, "Content-type: $ContType");
      my $headers = join("\n",@Headers)."\n\n";
      # Prepend the output buffer with headers data.
      # So we output the buffer and headers in ONE print call (it is 
      # more transparent for calling code if it ties STDOUT by himself).
      $$rRootBuf = $headers.$$rRootBuf;
    } else {
      # Only headers should be sent. 
      my $headers = join("\n",@Headers)."\n\n";
      _RealPrint($headers);
    }
    $HeadersSent = 1;
  }
  # Отправить буфер и очистить его
  _Debug("Flush: len=%d", length($$rRootBuf));
  if (!$Redirected) { 
    _RealPrint($$rRootBuf);
  }
  $$rRootBuf = "";
  return 1;
}


# constructor new($refToNewBuf=undef)
# Делает текущим новый буфер вывода.
sub new
{ my ($class, $rBuf)=@_;
  $rBuf = \(my $b="") if !defined $rBuf;
  my $this = bless {
    rPrevBuf => $rCurBuf,
    rCurBuf  => $rBuf,
  }, $class;
  $rCurBuf = $rBuf;
  _Debug("[%s] New: prevSt=%s, curSt=%s", $this, $this->{rPrevBuf}, $this->{rCurBuf});
  return $this;
}


# Восстанавливает предыдущий активный объект вывода
sub DESTROY
{ my ($this)=@_;
  _Debug("[%s] DESTROY: prevSt=%s, curSt=%s", $this, $this->{rPrevBuf}, $this->{rCurBuf});

  # Если это последний объект, то выполняем действия, которые нужно обязательно
  # закончить к моменту завершения программы. То есть, этот участок кода выполняется
  # тогда и только тогда, когда вызывается DESTROY для объекта, связанного с
  # STDOUT, то есть перед самым завершением программы (по ошибке или нет - не важно).
  # Все эти сложности нужны только потому, что, оказывается, в Perl нельзя
  # объявить функцию, которая будет гарантировано вызываться в конце, особенно при
  # фатальной ошибке... Однако можно создать некоторый объект, который при уничтожении 
  # вызовет свой деструктор. Таким объектом для нас будет объект, связанный
  # с STDOUT. Нам это жизненно необходимо, потому что нужно любой ценой вывести 
  # заголовки и, возможно, сообщения о возникших ошибках. Это, собственно, и 
  # делается здесь.
  if ($rCurBuf == $rRootBuf) {
    # Вызываемая отсюда функция НЕ МОЖЕТ использовать print и STDOUT, потому что
    # в момент прохождения этой точки STDOUT ни к чему не "привязан", но
    # Perl-у кажется, что привязан, поэтому генерируется GP Fault.
    &__PrintAllErrors() if @Errors;
    Flush();
    return;
  }
  $rCurBuf = $this->{rPrevBuf};
}


# string method buf()
# Вызывается для получения данных из буфера вывода.
sub buf { 
  return ${$_[0]->{rCurBuf}};
}



##
## Служебные функции и методы.
##

# constructor _newRoot()
# Creates the new ROOT (!!!) buffer. Called internally while tying STDOUT.
sub _newRoot {
  $$rRootBuf = "";
  $rCurBuf = undef;
  goto &new;
}


# Package import.
sub import {
  my ($pkg, $needRestart)=@_;
  retieSTDOUT($needRestart);
  goto &Exporter::import;
}


# Деструктор пакета. Следит за тем, чтобы все объекты были удалены в 
# правильном порядке. Вызывается ДО фазы "global destruction", что 
# нам и нужно. Правда, есть сведения, что иногда END НЕ вызывается
# (в случае каких-то ошибок), однако и в этом случае все будет работать
# корректно (см. _RealPrint).
sub END {
  return if !tied(*STDOUT) || ref tied(*STDOUT) ne __PACKAGE__."::Tie";
  CGI::WebOut::_Debug("CGI::WebOut::END");
  my $this = tied(*STDOUT);
  my ($handle, $obj) = ($this->{handle}, $this->{prevObj});
  CGI::WebOut::Tie::tieobj(*$handle, $obj) 
}


# static _RealPrint()
# Prints the data to "native" STDOUT handler.
sub _RealPrint {  
  my $obj = tied(*STDOUT);
  _Debug("_RealPrint: STDOUT tied: %s", $obj);
  my $txt = join("", @_);
  return if $txt eq "";
  if ($obj) { 
    if (ref $obj eq "CGI::WebOut::Tie") {
      return $obj->parentPrint(@_) 
    } else {
      print STDOUT @_;
    }
  } else {
    # Sometimes, during global destruction, STDOUT is already untied
    # but print still does not work. I don't know, why. This workaround
    # works always.
    open(local *H, ">&STDOUT");
    return print H @_;
  }
}


# Для отладки - выводит сообщение в файл
my $opened;
sub _Debug {  
  return if !$DEBUG;
  my ($msg, @args) = @_;

  # Detect "global destruction" stage.
  my $gd = '';
  {
    local $SIG{__WARN__} = sub { $gd .= $_[0] };
    warn("test");
    $gd =~ s/^.*? at \s+ .*? \s+ line \s+ \d+ \s+//sx;
    $gd =~ s/^\s+|[\s.]+$//sg;
    $gd = undef if $gd !~ /global\s*destruction/i;
  }
  local $^W;
  open(local *F, ($opened++? ">>" : ">").$DEBUG); binmode(F);
  print F sprintf($msg, map { defined $_? $_ : "undef" } @args) . ($gd? " ($gd)" : "")."\n";
}


##
## Для перехвата вывода print-а
##

{{{
##
## This class is used to tie some Perl variable to specified $object
## WITHOUT calling TIE* method of ref($object). Unfortunately Perl
## does not support 
##   tied(thing) = something;
## construction. Instead of this use:
##   tie(thing, "CGI::WebOut::TieMediator", something).
## See tieobj() below.
##
package CGI::WebOut::TieMediator;
#sub TIESCALAR { return $_[1] }
#sub TIEARRAY  { return $_[1] }
#sub TIEHASH   { return $_[1] }
sub TIEHANDLE { return $_[1] }
}}}


{{{
##
## This class is used to tie objects to filehandle.
## Synopsis:
##   tie(*STDOUT, "CGI::WebOut::Tie", \*STDOUT, tied(*STDOUT));
## All the parent methods is virtually inherited. So you
## may call print(*FH, ...), close(*FH, ...) etc.
## All the output is redirected to current CGI::WebOut object.
## This class is used internally by the main module.
##
package CGI::WebOut::Tie;

# The same as tie(), but ties existed object to the handle.
sub tieobj { 
# return $_[1]? tie($_[0], "CGI::WebOut::TieMediator", $_[1]) : untie($_[0]); 
  return tie($_[0], "CGI::WebOut::TieMediator", $_[1]); 
}

## Fully overriden methods.
sub WRITE  { shift; goto &CGI::WebOut::echo; }
sub PRINT  { shift; goto &CGI::WebOut::echo; }
sub PRINTF { shift; @_ = sprintf(@_); goto &CGI::WebOut::echo; }

# Creates the new tie. Saves the old object and handle reference.
# See synopsis above.
sub TIEHANDLE 
{ my ($cls, $handle, $prevObj) = @_;
  CGI::WebOut::_Debug("TIEHANDLE(%s, %s, %s)", $cls, $handle, $prevObj);
  return bless { 
    handle  => $handle,
    prevObj => $prevObj,
    outObj  => CGI::WebOut->_newRoot($rRootBuf),
  }, $cls;
}

sub DESTROY {
  CGI::WebOut::_Debug("[%s] DESTROY", $_[0]);
}

## Methods, inherited from parent.
sub CLOSE 
{ my ($this) = @_;
  CGI::WebOut::Flush();
  $this->parentCall(sub { close(*{$this->{handle}}) });
}
sub BINMODE 
{ my ($this) = @_;
  $this->parentCall(sub { binmode(*{$this->{handle}}) });
}
sub FILENO
{ my ($this) = @_;
  # Do not call Flush() here, because it is incompatible with CGI::Session.
  # E.g. the following code will not work if Flush() is uncommented:
  #   use CGI::WebOut;
  #   use CGI::Session;
  #   my $session = new CGI::Session(...);
  #   SetCookie(...); # says that "headers are already sent"
  #CGI::WebOut::Flush();
  $this->parentCall(sub { return fileno(*{$this->{handle}}) });
  return 0;
}

# Untie process is fully transparent for parent. For example, code:
#   tie(*STDOUT, "T1");
#   eval "use CGI::WebOut"; #***
#   print "OK!";
#   untie(*STDOUT);
# generates EXACTLY the same sequence of call to T1 class, as this 
# code without ***-marked line.
# Unfortunately we cannot retie CGI::WebOut::Tie back to the object
# in UNTIE() - when the sub finishes, Perl hardly remove tie. 
our $doNotUntie = 0;
sub UNTIE
{ my ($this, $nRef) = @_;
  return if $doNotUntie;
  my $handle = $this->{handle};
  CGI::WebOut::_Debug("UNTIE prev=%s, cur=%s", $this->{prevObj}, tied(*$handle));
  # Destroy output object BEFORE untie parent.
  $this->{outObj} = undef;
  # Untie parent object.
  if ($this->{prevObj}) {
    tieobj(*$handle, $this->{prevObj});
    $this->{prevObj} = undef; # release ref
    untie(*$handle); # call parent untie
    $this->{prevObj} = tied(*$handle);
  }
}

# void method parentPrint(...)
# Prints using parent print method.
sub parentPrint
{ my $this = shift;
  my $params = \@_;
  CGI::WebOut::_Debug("parentPrint('%s')", join "", @$params);
  $this->parentCall(sub { print STDOUT @$params });
}

# void method parentCall($codeRef)
# Calls $codeRef in the context of object, previously tied to handle.
# After call context is switched back, as if nothing has happened.
# Returns the same that $codeRef had returned.
sub parentCall
{ my ($this, $sub) = @_;
  my ($handle, $obj) = ($this->{handle}, $this->{prevObj});
  my $save = tied(*$handle);
  if ($obj) {
    tieobj(*$handle, $obj) 
  } elsif ($save) {
    local $doNotUntie = 1;
    local $^W;
    untie(*$handle);
  }
  CGI::WebOut::_Debug("parentCall for STDOUT=%s", $obj);
  my @result = eval { wantarray? $sub->() : scalar $sub->() };
  if ($save) {
    tieobj(*$handle, $save);
  } elsif ($obj) {
    local $doNotUntie = 1;
    local $^W;
    untie(*$handle);
  }
  return wantarray? @result : $result[0];
}
}}}


# Since v2.0 AutoLoader is not used.
#use AutoLoader 'AUTOLOAD';
#return 1;
#__END__


# Использование try-catch-throw:
# try { 
#   код, который может вылететь по ошибке
#   или который генерирует исключение с помощью throw
# } catch {
#   имя исключения или сообщение об ошибке - в $_
# } warnings {
#   список произошедших ошибок и предупреждений в @_
# }
# Блоки catch и warnings выполняются в порядке их появления и могут отсутствовать.
sub try (&;@) 
{ my ($try,@Hand) = @_;
  # Мы НЕ можем использовать local для сохранения @Errors по следующей присине.
  # Если в &$try выведутся предупреждения, а потом будет вызван exit(),
  # то до конца try() управление так и не дойдет. Если бы мы использовали 
  # local, то эти предупреждения в @Errors потерялись бы. Так как используется
  # сохранение во временной переменной, предупреждения в @Errors останутся на 
  # месте и выведутся на экран.
  my @SvErrors = @Errors;
  # Запускаем try-блок
  my @Result = eval { &$try };
  # Управление попало сюда, если внутри кода не было вызова exit().
  # В противном случае происодит вылет из функции и из программы.
  # Получаем все возникшие предупреждения. Причем записываем их в
  # переменную типа local, чтобы эта переменныя была видна внутри 
  # warnings-функции (см. ниже).
  local @Warns = @Errors>@SvErrors? @Errors[@SvErrors..$#Errors] : ();
  # Восстанавливаем сообщения об ошибках
  @Errors = @SvErrors;
  # Запускаем обработчики в порядке их появления
  map { &$_() } @Hand;
  # Возвращаем значение, которое вернул try-блок
  return wantarray? @Result: $Result[0];
}

# Возвращает функцию-замыкание, которая вызывает тело catch-блока.
sub catch(&;@) 
{ my ($body, @Hand)=@_;
  return (sub { if($@) { chomp($@); local $_=$@; &$body($_) } }, @Hand);
}

# Возвращает функцию-замыкание, которая вызывает тело warnings-блока.
sub warnings(&;@) 
{ my ($body,@Hand)=@_;
  return (sub { &$body(@Warns) }, @Hand);
}

# Выбрасывает исключение.
sub throw($) { 
  die(ref($_[0])? $_[0] : "$_[0]\n") 
}


# bool SetAutoflush([bool $mode])
# Устанавливает режим сброса буфера echo: если $mode=1, то разрешает его автосброс после
# каждого вывода print или echo, иначе - запрещает (сброс должен производиться по Flush()).
# Возвращает предыдущий установленный режим автосброса.
sub SetAutoflush(;$)
{ my ($mode)=@_;
  my $old = $UseAutoflush;
  if (defined $mode) { $UseAutoflush = $mode; }
  return $old;
}

# bool NoAutoflush()
# Запрещает сбрасывать буфер после каждого echo.
# Возвращает предыдущий статус автосброса.
sub NoAutoflush() {
  return SetAutoflush(0);
}


# bool UseAutoflush()
# Разрашает сбрасывать буфер после каждого echo.
# Возвращает предыдущий статус автосброса.
sub UseAutoflush() {
  return SetAutoflush(1);
}


# Перенаправляет на другой URL (может быть внутренним редиректом)
sub Redirect($)
{ my ($url) = @_;
  $Redirected = Header("Location: $url");
  exit;
}


# Перенаправляет БРАУЗЕР на другой URL
sub ExternRedirect($)
{ my ($url) = @_;
  if ($url !~ /^\w+:/) {
    # Относительный адрес.
    if ($url !~ m{^/}) {
      my $sn = $ENV{SCRIPT_NAME};
      $sn =~ s{/+[^/]*$}{}sg;
      $url = "$sn/$url";
    }
    # Добавить имя хоста.
    $url = "http://$ENV{SERVER_NAME}$url";
  }
  $Redirected = Header("Location: $url");
  exit;
}


# Запрещает кэширование документа браузером
sub NoCache()
{ return 1 if $NoCached++;
  Header("Expires: Mon, 26 Jul 1997 05:00:00 GMT") or return undef;
  Header("Last-Modified: ".gmtime(time)." GMT") or return undef;
  Header("Cache-Control: no-cache, must-revalidate") or return undef;
  Header("Pragma: no-cache") or return undef;
  return 1;
}


# int ErrorReporting([int $level])
# Устанавливает режим вывода ошибок:
# 0 - ошибки не выводятся
# 1 - ошибки выводятся в браузер
# 2 - ошибки выводятся в браузер в виде комментариев
# Если параметр не задан, режим не меняется.
# Возвращает предыдущий статус вывода.
sub ErrorReporting(;$)
{ my ($lev)=@_;
  my $old = $ErrorReporting;
  $ErrorReporting = $lev if defined $lev;
  return $old;
}


# Добавляет сообщение об ошибке к массиву ошибок.
sub Warning($)
{ my ($msg)=@_;
  push(@Errors, $msg);
}


# Печатает все накопившиеся сообщения об ошибках.
# Эта функция вызывается в момент, когда STDOUT находится в "подвешенном" состоянии, 
# поэтому использование print ЗАПРЕЩЕНО!!!
sub __PrintAllErrors()
{ local $^W = undef;
  # http://forum.dklab.ru/perl/symbiosis/Fastcgi+WeboutUtechkaPamyati.html
  if(!@Errors || !$ErrorReporting){
    @Errors=(); 
          return ; 
  }
  if (IsWebMode) {
    if ($ErrorReporting == ER_Err2Browser) {
      # мало ли, какие там были таблицы...
      echo "</script>","</xmp>","</pre>","</table>"x6,"</tt>"x2,"</i>"x2,"</b>"x2,"</div>"x10,"\n";
    }
    my %wasErr=();
    for (my $i=0; $i<@Errors; $i++) {
      chomp(my $st = $Errors[$i]); 
      # Исключаем дублирующиеся сообщения о ФАТАЛЬНЫХ ошибках.
      next if $wasErr{$st};
      $wasErr{$st}=1 if $st =~ /^Fatal:/;
      # Выводим сообщение.
      if ($ErrorReporting == ER_Err2Browser) {
        $st=~s/>/&gt;/sg;
        $st=~s/</&lt;/sg;
        $st=~s|^([a-zA-Z]+:)|<b>$1</b>|mgx;
        $st=~s|\n|<br>\n&nbsp;&nbsp;&nbsp;&nbsp;|g; 
        my $s=$i+1;
        for(my $i=length($s); $i<length(scalar(@Errors)); $i++) { $s="&nbsp;$s" }
            echo "<b><tt>$s)</tt></b> $st<br>\n"; 
      } elsif ($ErrorReporting == ER_Err2Comment) {
            echo "\n<!-- $st -->"; 
      } elsif ($ErrorReporting == ER_Err2Plain) {
            echo "\n$st"; 
      }
    }
  } else {
    foreach my $st (@Errors) { chomp($st); echo "\n$st" }
  }
  @Errors=();
}

return 1;
__END__

=head1 NAME

CGI::WebOut - Perl extension to handle CGI output (in PHP-style).

=head1 SYNOPSIS

  # Simple CGI script (no 500 Apache error!)
  use CGI::WebOut;
  print "Hello world!"; # wow, we may NOT output Content-type!
  # Handle output for {}-block
  my $str=grab {
    print "Hi there!\n";
  };
  $str=~s/\n/<br>/sg;
  print $str;

=head1 DESCRIPTION

This module is used to make CGI programmer's work more comfortable. 
The main idea is to handle output stream (C<STDOUT>) to avoid any data 
to be sent to browser without C<Content-type> header. Of cource,
you may also send your own headers to browser using C<Header()>. Any 
errors or warnings in your script will be printed at the bottom of the page 
"in PHP-style". You may also use C<Carp> module together with C<CGI::WebOut>.

You may also handle any program block's output (using C<print> etc.)
and place it to the variable using C<grab {...}> subroutine. It is a 
very useful feature for lots of CGI-programmers.

The last thing - support of C<try-catch> "instruction". B<WARNING:> they 
are I<not> real instructions, like C<map {...}>, C<grep {...}> etc.! Be careful
with C<return> instruction in C<try-catch> blocks.

Note: you may use C<CGI::WebOut> outside the field of CGI scripting. In "non-CGI" 
script headers are NOT output, and warnings are shown as plain-text. 
C<grab {...}>, C<try-catch> etc. work as usual.

=head2 New features in version 2.0

Since version 2.0 module if fully tie-safe. That means the code:

  tie(*STDOUT, "T");
  eval "use CGI::WebOut";
  print "OK!";
  untie(*STDOUT);

generates I<exactly> the same sequense of T method calls as:

  tie(*STDOUT, "T");
  print "OK!";
  untie(*STDOUT);

So you can use CGI::WebOut with, for example, FastCGI module.

=head2 EXPORT

All the useful functions. Larry says it is not a good idea, 
but Rasmus does not think so.

=head1 EXAMPLES

  # Using Header()
  use CGI::WebOut;
  NoAutoflush();
  print "Hello world!"
  Header("X-Powered-by: dklab");

  # Handle output buffer
  use CGI::WebOut;
  my $str=grab {
    print "Hi there!\n";
  # Nested grab!
  my $s=grab {
    print "This string will be redirect to variable!";
  }
  }
  $str=~s/\n/<br>/sg;

  # Exception/warnings handle
  use CGI::WebOut;
  try {
    DoSomeDangerousStuff();
  } catch {
    print "An error occured: $_";
  throw "Error";
  } warnings {
    print "Wanning & error messages:".join("\n",@_);
  };



=head1 DESCRIPTION

=over 13

=item C<use CGI::WebOut [($forgotAboutHeaders)]>

Handles the C<STDOUT> to avoid document output without C<Content-type> header in "PHP-style". If C<$forgotAboutHeaders> is true, following "print" will produce output of all HTTP headers. Use this options only in FastCGI environment.


=item C<string grab { ... }>

Handles output stream. Usage:

    $grabbed = grab { 
        print 'Hello!' 
    } catch { 
        die "An error occurred while grabbing the output: $@"; 
    };

or simply

    $grabbed = grab { print 'Hello!' };


=item C<bool try {...} catch {...} warnings {...}>

Try-catch preudo-instruction. Usage:

    try { 
       some dangeorus code, which may call die() or
       any other bad function (or throw "instruction")
    } catch {
       use $_ to get the exception or error message
    } warnings {
       use @_ to get all the warning messages
    }

Note: C<catch> and C<warnings> blocks are optional and called in 
order of their appearance.


=item C<void throw($exception_object)>

Throws an exception.

=item C<int ErrorReporting([int $level])>

Sets the error handling mode. C<$level> may be:

    ER_NoErr       - no error reporting;
    ER_Err2Browser - errors are printed to browser;
    ER_Err2Comment - errors are printed to browser inside <!-- ... -->;
    ER_Err2Plain   - plain-text warnings.

Returns the previous error reporting mode.


=item C<void Header(string $header)>

Sets document responce header. If autoflush mode is not set, this 
function may be used just I<before> the first output.


=item C<int SetAutoflush([bool $mode])>

Sets the autoflush mode (C<$mode>!=0) or disables if (C<$mode>=0). Returns the
previous status of autoflush mode.


=item C<int NoAutoflush()>

Equivalents to C<SetAutoflush(0)>.


=item C<int UseAutoflush()>

Equivalents to C<SetAutoflush(1)>.


=item C<void Flush()>

Flushes the main output buffer to browser. If autoflush mode is set,
this function is called automatically after each C<print> call.


=item C<void Redirect(string $URL)>

Sends C<Location: $URL> header to redirect the browser to C<$URL>. Also finishes the script with C<exit()> call.


=item C<void ExternRedirect(string $URL)>

The same as C<Redirect()>, but first translates C<$URL> to absolute format: "http://host/url".


=item C<void NoCache()>

Disables browser document caching.

=back

=head1 AUTHOR

Dmitry Koterov <koterov@cpan.org>, http://dklab.ru/chicken/4.html

=head1 SEE ALSO

C<CGI::WebIn>, C<Carp>.

=cut
