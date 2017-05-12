# Для разрешения upload-а нужно в директорию со скриптом поместить файл с 
# именем ".can_upload". В противном случае upload запрещаеся.
# Если же этот файл задан, то делается попытка прочитать из него параметры:
# dir=имя_директории для закачки
# maxsize=максимальный_размер закачиваемого файла
# В любом случае, по окончание работы скрипта закачанные файлы удаляются 
# (если только они не были перемещены скриптом в другое место).

# TODO:
# 3. Попробовать решить проблему экспорта
# 4. Имена временных файлов должны быть совместимы с Маком.
# 5. Поддержка undef в Serialize + предупреждения.

package CGI::WebIn;
use strict;
our $VERSION = '2.03';
our @EXPORT=qw(
  %IN 
  %GET 
  %POST 
  %COOKIES 
  SetCookie 
  DropCookie
);


####################### Константы, управляющие работой #####################
our $CANUPL_FILE = ".can_upload";  # имя файла, разрешающего закачку
our $MULTICHUNK_SIZE = 20000;      # длина блока считывания STDIN-а
our $MAX_ARRAY_IDX = 10000;        # максимально возможный индекс N в a[N]
our $uniq_tempnam = 0; # temp files counter
our @TempFiles = ();   # all temp files (to delete after end)
our @Errors = ();      # all query parsing errors

# Настройки сериализации.
# Некоторые внутренние настроечные переменные. Фактически, они используются 
# в качестве констант. Лучше всего их никогда не трогать. Эти константы 
# должны состоять из одного символа!
our $Div1 = ".";    # ALWAYS should be one nondigit!!!
our $Div2 = ".";    # may be the same as $Div1


####################### Преременные с данными браузера #####################
our %IN = ();                          # Данные формы 
our %GET = ();                         # Данные GET
our %POST = ();                        # Данные POST
our %COOKIES = ();                     # Все пришедшие Cookies
our %IMPORT_MOD = ();                  # Модули, затребовавшие импорт переменных (ключи)


# void _reparseAll()
# Parses all the input data.
sub _reparseAll {
  if($ENV{QUERY_STRING}) {
    _parseURLEnc($ENV{QUERY_STRING},"get"); 
  }
  if(uc($ENV{REQUEST_METHOD}) eq "POST") {
    if(exists($ENV{'CONTENT_TYPE'}) && $ENV{'CONTENT_TYPE'}=~m|^\s*multipart/form-data|i) {
      _parseMultipart();
    } else {
      read(STDIN,my $data,$ENV{CONTENT_LENGTH});
      _parseURLEnc($data,"post");
    }
  }
  if($ENV{HTTP_COOKIE} || $ENV{COOKIE}) {
    _parseCookies();
  }
# use Data::Dumper; print "<pre>".Dumper(\%IN)."</pre>";
}


# void import(...) 
# Called on 'use'.
sub import
{ my ($pkg, $opt)=@_;
  my $caller = caller();
  export_vars($opt, $caller) if $opt;
  no strict;
  foreach (@EXPORT) {
    my ($type, $name) = /^([%@\$]?)(.*)$/s;
    if ($type eq '%') {
      *{$caller."::".$name} = \%{$name};
    } elsif ($type eq '') {
      *{$caller."::".$name} = \&{$name};
    }
  }
}


# Deletes temporary files if present.
sub END
{ map { unlink($_) } @TempFiles if @TempFiles;
}

# list of string GetErrors()
# Returns all errors collected while parsing the form input data
# (for example, too large autoarray index).
sub GetErrors {
  return @Errors;
}


# Encoding and decoding.
sub URLEncode { my ($s)=@_; $s=~s{([^-_A-Za-z0-9./])}{sprintf("%%%02X", ord $1)}sge; return $s }
sub URLDecode { my ($s)=@_; $s=~tr/+/ /; $s=~s/%([0-9A-Fa-f]{2})/chr(hex($1))/esg; return $s }


my %CODE = (
'export_vars' => <<'END_OF_FUNC',
  # void export_vars(sting $options, string $toPkg)
  # Export EGPC-variables from %GET, %POST etc.
  sub export_vars
  { my ($opt, $to)=@_;
    if(!scalar(@_)) {
      # Вызов без параметров - обойти и экспортировать во все модули-клиенты
      while(my ($mod,$opt)=each(%IMPORT_MOD)) {
        export_vars($opt,$mod);
      }
    } else {
      # Вызов с параметрами - экспорт переменных только в укакзанный модуль
      return if !$opt;
      $opt="gpces" if lc($opt) eq "a" || $opt eq "1";
      # Сохраняем информацию о том, что модуль "хочет" экспортирования и 
      # в дальнейшем. Например, при вызове SetCookie() соответствующая 
      # переменная создастся не только в %COOKIES, но и во всех модулях.
      $IMPORT_MOD{$to}=$opt;
      # Экспортируем еще не существующие переменные
      no strict;
      my $Bad=\%{$to."::"};
      foreach my $op (split //,$opt) {
        $op=lc($op);
        my $Hash = 
          $op eq "g" && \%GET ||
          $op eq "p" && \%POST ||
          $op eq "c" && \%COOKIES ||
          $op eq "e" && \%ENV || next;
        while(my ($k,$v)=each(%$Hash)) {
          # не переписывать существующие переменные
          next if exists $Bad->{$k};
          ## BUGFIX 11.07.2002 v1.10:
          ##   разрешается применять только буквенно-цифровые имена,
          ##   раньше имена вида SomeModule::var приводили к дыре
          ##   в безопасности.
          next if $k=~/[^\w\d_]/s;
          *{$to."::".$k}=ref($v)? $Hash->{$k} : \$Hash->{$k}; 
        }
      }
    }
  }
END_OF_FUNC


'_processPar' => <<'END_OF_FUNC',
  # void _processPar(string $key, string $value, string $type)
  # Добавляет пару $key=>$value в хэш %IN (с разбором многоуровневых хэшей),
  # а также в хэш %GET, %POST или %COOKIES, в зависимости от значения $type 
  # (get, post, cookies соответственно).
  # Пустые скобки "{}" заменяются на значение "{$v}"!
  sub _processPar
  { my ($k,$v,$type)=@_; 
    return if !defined($k);
    $type=uc($type||"IN");

    ## BUGFIX 12.07.2002 v1.10:
    ##   до этого было s/\r//sg, что неправильно работало на Маке.
    $v=~s/\x0d\x0a?|\x0a\x0d?/\n/sg if defined $v && !ref $v;

    # Проверяем вид "a{10}{20}" и заодно получаем первый ключ
    do { push @Errors, "$type: Unknown input field format '$k'"; return } if $k!~/^([^}{\[\]]+)/sg;

    ## Этап I: Получаем все индексы, обрамленные соотв. скобками.
    my @Ind = ([$1, '']);
    while(pos $k < length $k) {
      my ($i,$t);
      $k=~/\G
        \{ (
          (?:
            [^}"']* |
            ## BUGFIX 12.07.2002 v1.10:
            ##   нужно писать [^"\\], а не [^"].
            ## after slash ALWAYS must be any character.
            "(?:[^"\\]+|\\.)*" |  
            '(?:[^'\\]+|\\.)*'
          )
        ) \}
      /sxgc and do { $t=$Ind[-1][1]='HASH'; push @Ind, $i=[$1, ''] }
        or ####   
      $k=~/\G
        \[ (
          (?:
            [^]"']* |
            "(?:[^"\\]+|\\.)*" |  
            '(?:[^'\\]+|\\.)*'
          )*
        ) \]
      /sxgc and do { $t=$Ind[-1][1]='ARRAY'; push @Ind, $i=[$1, ''] }
        or ###
      do { push @Errors, "$type: Corrupted parameter '$k'"; return };

      if($i->[0] eq "" && defined $v) {
        # Заменяем пустой индекс БЕЗ КАВЫЧЕК на $v или -1
        $i->[0] = $t eq 'HASH'? $v : '';
      } else {
        # Убираем слэши перед кавычками, но только если строка была заковычена.
        $i->[0]=~s/^(['"])(.*)\1$/$2/sg
          and
        $i->[0]=~s/\\(['"\\])/$1/sg;
      }
    }
    # [0] содержит очередной индекс.
    # [1] содержит ТИП объекта, в котором этот индекс СОДЕРЖИТСЯ.

  # use Data::Dumper; print "<pre>".Dumper(\%IN)."</pre>";

    ## Этап II: заполняем хэши. К сожалению, приходится делать
    ## цикл по всем хэшам и фактически делать одну работу несколько 
    ## раз, потому что где-то уже могут существовать полузаполненные
    ## хэши.
    my   @Outs=(\%IN);
    push @Outs, \%GET     if lc($type) eq "get";
    push @Outs, \%POST    if lc($type) eq "post";
    push @Outs, \%COOKIES if lc($type) eq "cookie";
    foreach my $cur (@Outs) {
      foreach my $idx (@Ind) {
        # Текущий ключ и тип значения по этому ключу.
        my ($i,$t) = @$idx;
        # Получаем ссылку $r не то место, куда нужно записать значение.
        my $r;
        if(ref $cur eq 'HASH') {
          # Работаем с $cur как с хэшем.
          $r = \$cur->{$i};
        } elsif(ref $cur eq 'ARRAY') {
          # Работаем с $cur как с массивом. 
          # Индекс -1 означает "добавить в конец".
          $i = @$cur if $i eq "";
          # Не-цифровые и слишком большие индексы не допускаются.
          do { push @Errors, "$type: Non-numeric index '$i' in '$k'"; return } if $i=~/[^\d]/s;
          do { push @Errors, "$type: Too large index '$i' in '$k'"; return } if $i>$MAX_ARRAY_IDX;
          $r = \$cur->[$i];
        }
        # Если такого ключа еще нет, то в $$r будет undef.
        $$r = ($t eq 'HASH'? {} : $t eq 'ARRAY'? [] : '') if !defined $$r;
        # Проверка соответствия типов.
        if(ref($$r) ne $t) {
          push @Errors, "$type: Mismatched parameter type:  key '$i' in '$k' later defined as ".(ref($$r)||"SCALAR").", not ".(!$t? "SCALAR" : $t eq 'HASH'? 'HASH' : 'ARRAY');
          return;
        }
        $$r = $v if !$t;
        $cur = $$r;
      }
    }
  }
END_OF_FUNC


'_parseURLEnc' => <<'END_OF_FUNC',
  # void _parseURLEnc(string $input, string $type)
  sub _parseURLEnc
  { my ($tosplit,$type) = @_;
    my (@pairs) = split(/[&?]/,$tosplit);
    my ($param,$value);
    foreach (@pairs) {
      ($param,$value) = split('=',$_,2);
      $param = URLDecode(defined($param)?$param:"");
      $value = URLDecode(defined($value)?$value:"");
      _processPar($param,$value,$type);
    }
  }
END_OF_FUNC


'tempnam' => <<'END_OF_FUNC',
  # string tempnam([string $Dir])
  # Возвращает уникальное (используется PID и таймер) имя файла в директории, указанной в 
  # параметрах. По умолчанию - в директории, указанной в переменной окружения TMP или TEMP,
  # или, в крайнем случае, в текущей. В конце работы скрипта все файлы, имеющие
  # имена, сгенерированные tempnam(), будут удалены!
  # Всегда возвращает полный путь к временному файлу.
  sub tempnam
  { my ($dir)=@_; 
    foreach my $cd ($dir,$ENV{TMP},$ENV{TEMP},"/tmp",".") {
      if(defined $cd && -d $cd && -w $cd) { $dir=$cd; last; }
    }
    my $nm=$dir."/".time()."-$$-".(++$uniq_tempnam).".tmp";
    if($nm!~m{^[/\\]}) {
      require Cwd;
      $nm=Cwd::getcwd()."/".$nm;
    }
    push(@TempFiles,$nm);
    return $nm;
  }
END_OF_FUNC


'_parseMultipart' => <<'END_OF_FUNC',
  # hash _readUplConf()
  # Читает конфигурационный файл, разрешающий или запрещающий 
  # закачку в текущей директории.
  sub _readUplConf {
    open(local *F,"<$CANUPL_FILE") or return
    my %cfg=();
    while(my $st=<F>) {
      $st=~s/^\s+|\s+$|#.*$//gs;
      next if $st eq "";
      my ($k,$v)=split(/=/,$st,2);
      $cfg{$k}=$v;
    }
    return %cfg;
  }

  # Обработка Multipart-данных формы
  # void _parseMultipart()
  our ($InBuf, $InLength); # our для strict
  sub _parseMultipart
  { # Устанавливаем директорию и другие параметры для закачки (если разрешена)
    my %cfg=_readUplConf(); # свойства закачки

    #------- Работа с STDIN с возможностью "запихивания" данных обратно в поток
    $InBuf=""; $InLength=$ENV{CONTENT_LENGTH};
    sub _readInput {  
      my $sz=shift||$InLength;
      my $need=$MULTICHUNK_SIZE>$sz? $sz : $MULTICHUNK_SIZE;
      my $nBuf=length($InBuf)<$need? length($InBuf) : $need;
      my $out=substr($InBuf,0,$nBuf); $InBuf=substr($InBuf,$nBuf);
      read(STDIN,$out,$need-$nBuf,$nBuf) if $need-$nBuf>0;
      $InLength-=length($out);
      return $out;
    } 
    sub _putBack 
    { my ($data)=@_;
      $InBuf=$data.$InBuf;
      $InLength+=length($data);
    }
    sub _isEof { return !$InLength; }
    #-------- Конец внутренних функций

    binmode(STDIN);
    # Сначала читаем разделитель и финальные "\r\n"
    my ($bound,$CRLF) = _readInput()=~/(^[^\r\n]*)([\r\n]*)(.*)/s; # Выделяем разделитель БЕЗ \n
    _putBack($3); 

    # Теперь читаем записи, завершенные разделителем
    while((my $Data=_readInput()) ne "") {
      if(substr($Data,0,2) eq "--") { last; } # Проверяем, не конец ли это
      # Выделяем ВСЕ строки заголовка (до пустой строки).
      $Data=~/^[$CRLF]*(.*?)$CRLF$CRLF(.*)/s 
        or do { push @Errors, "Malformed multipart header"; return };
      _putBack($2); # Остаток запихиваем обратно
      
      # Получаем заголовки записи в %Headers
      my @Lines=split(/$CRLF/,$1);        # строки заголовка
      my %Headers=();
      foreach my $st (@Lines) {
        my ($k,$v)=split(/: */,$st,2);
        $Headers{lc($k)}=$v;
      }
      if(!%Headers) { push @Errors, "Malformed multipart POST (no header)"; return; }

      # Выделяем имя тэга и имя файла (если задано)
      my ($name)=$Headers{'content-disposition'}=~/\bname="?([^\";]*)"?/;
      my ($filename) = $Headers{'content-disposition'}=~/\bfilename="?([^\";]*)"?/;

      # Если это не закачка, то читаем данные и продолжаем
      if(!defined $filename || $filename eq "")  {
        my ($body,$i);
        $body = "";
        for($body=""; ($i=index($body,$bound))<0 && !_isEof(); ) { 
          $body.=_readInput(); 
        }
        if($i<0) { push @Errors, "Malformed multipart POST (no boundary after body)"; return; }
        _putBack(substr($body,$i+length($bound)));  # запихиваем остаток назад
        _processPar($name,substr($body,0,$i-length($CRLF)),"post");
        next;
      }

      # Иначе это закачка. Записываем временный файл.
      my $temp=defined $cfg{dir}? tempnam($cfg{dir}):tempnam();
      local *F; open(F,">$temp") or die("Cannot open temporary file $temp"); binmode(F);
      my $written=0;   # сколько байт в файле
      my $stopWrite=0; # нужно ли записывать, или пропускать
      while(1) {
        # Файл слишком велик или же закачка запрещена?..
        $stopWrite ||= 
          !%cfg && "File not found: $CANUPL_FILE" 
          || (defined $cfg{maxsize} && $written>$cfg{maxsize}) && "File exceeds limit of $cfg{maxsize} bytes";

        my $body1=_readInput();
        my $body2=_readInput(128); # для проверки разделителя длиной <128 байт
        my $body=$body1.$body2;

        # Нашли конец файла (разделитель)?
        if((my $i=index($body,$bound))>=0) {
          $written+=$i-length($CRLF);
          print F substr($body,0,$i-length($CRLF)) if !$stopWrite;
          _putBack(substr($body,$i+length($bound)));
          last;
        }
        $written+=length($body1);
        print F $body1 if !$stopWrite;
        _putBack($body2);     
      }
      close(F);

      # Формируем значение параметра.
      ## BUGFIX 13.07.2002:
      ##   раньше имя вида f[] и f{} приводило к неправильному 
      ##   созданию этого хэша, т.к. было насколько вызовов
      ##   _processPar с суффиксами {filename}, {file} и т.д.
      my %hash=();
      $hash{filename}=$filename;
      # Файл слишком большой, либо upload запрещен?..
      if($stopWrite) {
        unlink($temp);
        $hash{aborted}=$stopWrite;
      } else {
        # Иначе все в порядке
        $hash{headers}=\%Headers;
        $hash{file}=$temp;
        $hash{size}=-s $temp;
        $hash{type}=$Headers{'content-type'} if $Headers{'content-type'};
      }
      # Добавляем параметр.
      _processPar($name,\%hash,"post");
    }
  }
END_OF_FUNC


'_parseCookies' => <<'END_OF_FUNC',
  # Разбирает пришедшие cookies
  sub _parseCookies
  { my @Pairs = split("; *",$ENV{HTTP_COOKIE} || $ENV{COOKIE} || "");
    foreach (@Pairs) {
      my ($key,$value);
      if(/^([^=]+)=(.*)/) { $key = $1; $value = $2; } else { $key = $_; $value = ''; }
      $key=URLDecode($key);
      $value=URLDecode($value);
      my $v=Unserialize($value);
      $value=defined($v)?$v:$value;
      _processPar($key,$value,"cookie");
    }
  }
END_OF_FUNC


'ExpireCalc' => <<'END_OF_FUNC',
  # int ExpireCalc(string $tm)
  # This routine creates an expires time exactly some number of
  # hours from the current time.  It incorporates modifications from Mark Fisher.
  # Format for time $tm can be in any of the forms...
  # "now"   -- expire immediately
  # "+180s"   -- in 180 seconds
  # "+2m"   -- in 2 minutes
  # "+12h"  -- in 12 hours
  # "+1d"   -- in 1 day
  # "+3M"   -- in 3 months
  # "+2y"   -- in 2 years
  # "-3m"   -- 3 minutes ago(!)
  sub ExpireCalc
  { my($time)=@_;
    my(%mult)=('s'=>1, 'm'=>60, 'h'=>60*60, 'd'=>60*60*24, 'M'=>60*60*24*30, 'y'=>60*60*24*365);
    my($offset);
    if(lc($time) eq 'now') { $offset = 0; } 
    elsif($time=~/^([+-](?:\d+|\d*\.\d*))([mhdMy]?)/) { $offset = ($mult{$2} || 1)*$1; }
    else { return $time; }
    return (time+$offset);
  }
END_OF_FUNC


'Expires' => <<'END_OF_FUNC',
  # int Expires(int $time, string $format)
  # This internal routine creates date strings suitable for use in
  # cookies ($format="cookie") and HTTP headers ($format="http" or nothing). 
  # (They differ, unfortunately.) Thanks to Fisher Mark for this.
  sub Expires
  { my($time,$format) = @_; $format ||= 'http';
    my(@MON)=qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
    my(@WDAY) = qw/Sun Mon Tue Wed Thu Fri Sat/;
    # pass through preformatted dates for the sake of expire_calc()
    $time = ExpireCalc($time);  return $time unless $time =~ /^\d+$/;
    # cookies use '-' as date separator, HTTP uses ' '
    my($sc) = ' '; $sc = '-' if $format eq "cookie";
    my($sec,$min,$hour,$mday,$mon,$year,$wday) = gmtime($time);
    return sprintf("%s, %02d$sc%s$sc%04d %02d:%02d:%02d GMT",
         $WDAY[$wday],$mday,$MON[$mon],$year+1900,$hour,$min,$sec);
  }
END_OF_FUNC


'SetCookie' => <<'END_OF_FUNC',
  # void SetCookie(string $name, string $value [,int $expire][,$path][,$domain][bool $secure])
  # Устанавливает cookie с именем $name и значение $value ($value может быть сложным объектом
  # - в частности, ссылкой на массив или хэш).
  # Если $value не задан (undef), cookie удаляется.
  # Если $expire не задан, время жизни становится бесконечным. Если задан, но равен 
  # нулю - создается one-session cookie.
  # Параметр $expire можно задавать в виде, который "понимает" функция ExpireCalc().
  sub SetCookie
  { my ($name,$value,$expires,$path,$domain,$secure)=@_;
    my $NeedDel=0;

  # [12.03.2002] Можно и без этого.
  # if(!defined $path) { 
  #   $path=$ENV{SCRIPT_NAME};
  #   $path=~s{/[^/]*$}{}sg;
  #   $path.="/";
  # }

    if(!defined $expires) { $expires="+20y"; }
    if(!defined $value)   { $value=""; $expires="-3y"; $NeedDel=1; }
    
    my @Param;
    push(@Param,URLEncode($name)."=".URLEncode(Serialize($value)));
    push(@Param,"domain=$domain") if defined $domain;
    push(@Param,"path=$path") if defined $path;
    push(@Param,"expires=".Expires($expires,"cookie")) if $expires;
    push(@Param,'secure') if $secure;
    
    my $cook="Set-Cookie: ".join("; ",@Param);
    eval {
      local ($SIG{__WARN__},$SIG{__DIE__})=(sub {}, sub {});
      require CGI::WebOut;
    };
    if($@) {
      # Если не вышло загрузить CGI::WebOut, то просто печатаем.
      print $cook . "\r\n";
    } else {
      CGI::WebOut::Header($cook);
    }
    if(!$NeedDel) { _processPar($name,$value,"cookie"); } 
      else { _processPar($name,undef,"cookie"); }
    # Экспортируем Cookie во все нужные модули
    export_vars();
  }
END_OF_FUNC


'DropCookie' => <<'END_OF_FUNC',
  # void DropCookie(string $name [,$path] [,$domain])
  # Удаляет cookie с именем $name. Параметры $path и $domain 
  # должны точно совпадать с теми, которые были заданы при 
  # установке Cookie.
  sub DropCookie
  { my ($name,$path,$domain)=@_;
    SetCookie($name,undef,undef,$path,$domain);
  }
END_OF_FUNC


'Serialize' => <<'END_OF_FUNC',
  # string Serialize(mixed @args)
  # Упаковывает в строку любой (практически) объект. Так что не обязательно передавать
  # этой функции ссылку - можно прямо объект целиком.
  # (В этом случае он будет рассмотрен как список). 
  # Нельзя упаковывать объекты, содержащие ссылки на функции и дескрипторы файлов.
  # В случае ошибки возвращает undef и выводит warning.
  sub Serialize
  { my $st="L".($#_+1).$Div2;
    foreach my $Arg (@_) {
      while((my $Ref=ref($Arg)) eq "REF") { $st.="r"; $Arg=$$Arg; }
      if(ref($Arg) ne "") { $st.="r"; }
      if(ref($Arg) eq "") { $st.=length($Arg).$Div1.$Arg; }
      elsif(ref($Arg) eq "SCALAR") { $st.=length($$Arg).$Div1.$$Arg; }
      elsif(ref($Arg) eq "ARRAY") { $st.=Serialize(@$Arg); }
      elsif(ref($Arg) eq "HASH") { $st.="H".Serialize(%$Arg); }
      else { warn("Serialize: invalid field type '".ref($Arg)."'"); return undef; }
    }
    return $st;
  }
END_OF_FUNC


'Unserialize' => <<'END_OF_FUNC',
  # mixed _Unserialize(string $st)
  # Internal function.
  sub _Unserialize
  { my ($st,$TotalLen)=@_;
    # Считаем число ссылок
    my $RefCount; 
    for($RefCount=0; substr($st,$RefCount,1) eq "r"; $RefCount++) {;}
    $$TotalLen+=$RefCount; $st=substr($st,$RefCount);
    # Определяем тип
    my $Type="S";   # Может быть еще: "HL" (да, 2 символа!!!) или "L" 
    if(substr($st,0,1) eq "H") { $Type="H"; $st=substr($st,2); $$TotalLen+=2; }
      elsif(substr($st,0,1) eq "L") { $Type="L"; $$TotalLen++; $st=substr($st,1); }
    # Выполняем действия в зваисимости от типа  
    my $PResult;
    if($Type eq "S") {
      # Это - обычная строка.
      my $len=substr($st,0,my $p=index($st,$Div1));  # 0123.aaabbb
      $st=substr($st,$p+1); $$TotalLen+=$p+1+$len;   # ^   ^p
      # Распаковываем исходную строку
      my $s=substr($st,0,$len); $PResult=\$s;
    } elsif($Type eq "L" || $Type eq "H") {
      my @Unpack;
      my $size=substr($st,0,my $p=index($st,$Div2));
      $st=substr($st,$p+1); $$TotalLen+=$p+1;
      foreach my $i (0..$size-1) {
        my $len; push(@Unpack,_Unserialize($st,\$len));
        $$TotalLen+=$len;
        $st=substr($st,$len);
      }
      if($Type eq "L") { $PResult=\@Unpack; } else { my %Hash=@Unpack; $PResult=\%Hash; }
    }
    # We have the pointer to the object $PResult. Returning the (n-1)-th reference on it.
    for(my $i=0; $i<$RefCount; $i++) { my $tmp=$PResult; $PResult=\$tmp; }
    if(ref($PResult) eq "ARRAY") { return wantarray?@$PResult:@$PResult[0]; }
      elsif(ref($PResult) eq "HASH") { return %$PResult; }
        else { return $$PResult; }
  }


  # mixed _Unserialize(string $st)
  # Распаковывает строку, созданную ранее при помощи Serialize(). Возвращает то, что
  # было когда-то передано в параметрах Serialize.
  # В случае ошибки возвращает undef и выдает warning.
  sub Unserialize
  { return undef if !defined $_[0];
    my @Result=(); my $err=0;
    local $SIG{__WARN__}=sub { $err=1; };
    local $SIG{__DIE__}=sub { $err=1; };
    eval { @Result=_Unserialize($_[0]); };
    if($err||$@) { return undef; }
    return wantarray?@Result:$Result[0];
  }
END_OF_FUNC
);

#eval join("", values %CODE);

our $AUTOLOAD;
sub AUTOLOAD {
  my ($pkg, $sub) = $AUTOLOAD =~ /^(.*)::(.*)$/s or return;
  return if $pkg ne __PACKAGE__;
  eval($CODE{$sub} or return);
  goto &$sub;
}

_reparseAll();

return 1;
__END__


=head1 NAME

CGI::WebIn - Perl extension for reading CGI form data

=head1 SYNOPSIS

  use CGI::WebOut;
  use CGI::WebIn(1);

  # just to avoid "typo warning"
  our ($doGo,%Address,$Count); 

  # count visits
  SetCookie("Count",++$Count,"+10y");

  # is the button pressed?
  if($doGo) {
      print "Hello from $Address{Russia}{Moscow}!";
  }

  print <<EOT;
    You have visited this page $Count times.
    <form action=$SCRIPT_NAME method=post enctype=multipart/form-data>
    <input type=text name="Address{Russia}{Moscow}" value="house">
    <input type=submit name=doGo value="Say hello">
    </form>
  EOT

=head1 FEATURES

=over 5

=item *

Handle multi-dimentional GET/POST form data (see SYNOPSIS).

=item *

Handle multipart forms for file uploads.

=item *

Full real-time multi-dimentional cookie support.

=item *

PHP-style form data exporting.

=item *

Fast URL encode/decode subroutines.

=back


=head1 OVERVIEW

This module is used to make CGI programmer's work more comfortable. 
The main idea is to handle input stream (C<STDIN>) and C<QUERY_STRING>
environment variable sent by browser and parse their correctly
(including multipart forms). Resulting variables are put to C<%GET>, 
C<%POST>, C<%COOKIES> and C<%IN> (C<%IN> holds ALL the data). Also 
allows you to get/set cookies (any structure, not only scalars!) with 
C<SetCookie()> subroutine.

If this module is included without any arguments:

  use CGI::WebIn;

it exports the following: C<%IN>, C<%GET>, C<%POST>, C<%COOKIES>, 
C<SetCookie()> and C<DropCookie()>

You can specify additional information to be exported by using 
include arguments:

  use CGI::WebIn 'gpce';

means that all the GET, POST, Cookies and then environment 
variables will be exported to "usual" package variables. 
You must not be afraid to write everywhere C<'gpce'> - the 
following instruction does the same:

  use CGI::WebIn 'gpce';

=head1 DESCRIPTION

=over 6

=item C<use CGI::WebIn(1)>

Reads all the CGI input and exports it to the caller module
(like PHP does).

=item C<%IN, %GET, %POST and %COOKIES>

C<%IN> contains all the form data. C<%GET>, C<%POST> and C<%COOKIES> 
holds GET, POST and Cookies variables respectively.

=item C<void SetCookie($name, $value [,int $expire][,$path][,$domain][bool $secure])>

Sets the cookie in user browser. Value of that cookie is placed to C<%COOKIES> 
and ALL exported client modules immediately. Format for time C<$expire> can be 
in any of the forms:

  <stamp> - UNIX timestamp
  0       - one-session cookie
  undef   - drop this cookie
  "now"   - expire immediately
  "+180s" - in 180 seconds
  "+2m"   - in 2 minutes
  "+12h"  - in 12 hours
  "+1d"   - in 1 day
  "+3M"   - in 3 months
  "+2y"   - in 2 years
  "-3m"   - 3 minutes ago(!)

=item C<void DropCookie(string $name [,string $path] [,string $domain])>

Destroys the specified cookie. Make sure the C<$path> and C<$domain> parameters are 
the same to previous C<SetCookie()> call.

=item C<list of string CGI::WebIn::GetErrors()>

While parsing the form input data errors may appear. For example, these
QUERY_STRINGs are invalid: 

  test[-10]=abc
  test[123456789]=123
  test{1}=a&test[1]=100

Errors may also appear while parsing multipart data. In such cases all the 
error messages are collected and may be received using this function.

=item C<file uploading support>

To enable file uploading, you must create the following 
file C<.can_upload>:

  # directory to upload user files
  dir = .
  # maximum allowed size of the file to upload
  maxsize = 100000

and place it to the current directory. If there is no C<.can_upload> 
file, uploading is disabled.

=back

=head1 AUTHOR

Dmitry Koterov <koterov at cpan dot org>, http://www.dklab.ru

=head1 SEE ALSO

C<CGI::WebOut>.

=cut
