package Apache::Scriptor;
$VERSION="1.21";
use CGI::WebOut;
use Cwd;

# constructor new()
# Создает новый Apache::Scriptor-объект.
sub new
{ my ($class)=@_;
  my $this = {
    Handlers        => {},
    HandDir         => ".",
    htaccess        => ".htaccess",
    # Запоминаем, какой запрос в действительности был выполнен, чтобы
    # потом искать его в htaccess-ах.
    self_scriptname => $ENV{SCRIPT_NAME}
  };
  return bless($this,$class);
}


# void set_handlers_dir(string $dir)
# Устанавливает директорию для поиска обработчиков.
sub set_handlers_dir
{ my ($this,$dir)=@_;
  $this->{HandDir}=$dir;
}

# void addhandler(ext1=>[h1, h2,...], ext2=>[...])
# Устанавливает обработчик(и) для расширений ext1 и ext2.
# Здесь h1, h2 и т.д. представляют собой ССЫЛКИ на функции-обработчики.
# Если же они заданы не как ссылки, а как СТРОКИ, то в момент обращения 
# к очередному обработчику производится попытка его загрузить из файла,
# имя которого совпадает с именем обработчика с расширением ".pl" из
# директории, которая задана вызовом set_handlers_dir().
sub addhandler
{ my ($this,%hands)=@_;
  %{$this->{Handlers}}=(%{$this->{Handlers}},%hands);
  return;
}

# void pushhandler(string ext, func &func)
# Добавляет обработчик для расширения ext в конец списка обработчиков.
sub pushhandler
{ my ($this,$ext,$func)=@_;
  $this->{Handlers}{$ext}||=[];
  push(@{$this->{Handlers}{$ext}},$func);
  return;
}

# void removehandler(ext1, ext2, ...)
# Удаляет обработчик(и) для расширений ext1 и ext2.
sub removehandler
{ my ($this,@ext)=@_;
  foreach (@ext) { delete $this->{Handlers}{$_} }
  return;
}

# void set_404_url($url)
# Устанавливает адрес страницы 404-й ошибки, на которую будет произведен 
# редирект, если файл не найден.
sub set_404_url
{ my ($th,$url)=@_;
  $th->{404}=$url;
}

# void set_htaccess_name($name)
# Устанавливает имя htaccess-файла. По умолчанию это .htaccess.
sub set_htaccess_name
{ my ($th,$htaccess)=@_;
  $th->{htaccess}=$htaccess;
}

sub process_htaccess
{ my ($th,$fname)=@_;
  open(local *F,$fname) or return;
  # Сначала собираем все директивы из .htaccess
  my %Action=();
  my @AddHandler=();
  while(!eof(F)) {
    my $s=<F>; $s=~s/^\s+|#.*|\s+$//sg; next if $s eq "";
    # Директива Action
    if($s=~m/Action\s+([\w\d-]+)\s*"?([^"]+)"?/si) {
      $Action{$1}=1 if $2 eq $th->{self_scriptname};
    }
    # Директива AddHandler
    if($s=~m/AddHandler\s+([\w\d-]+)\s*(.+)/si) {
      push @AddHandler, [ $1, [ map { s/^\s*\.?|\s+$//sg; $_?($_):() } split /\s+/, $2 ] ];
    }
    # Директива ErrorDocument 404
    if($s=~/ErrorDocument\s+404\s+"?([^"]+)"?/si) {
      $th->set_404_url($1);
    }
  }
  # Затем добавляем цепочки обработчиков
  my %ProcessedExt=();
  foreach my $info (@AddHandler) {
    my ($hand,$ext)=@$info;
    # Сразу отметаем обработчики, которые НЕ указывают на Apache::Scriptor.
    # Мы не могли этого сделать в верхнем цикле, потопму что директивы
    # Action и AddHandler могут идти не по порядку.
    next if !$Action{$hand};
    # Добавляем для каждого расширения обработчик в цепочку
    foreach my $ext (@$ext) {
      # Если это расширение встречается в текущем htaccess-файле 
      # впервые, это значит, что начата очередная цепочка обработчиков.
      # В этом случае нужно удалить уже имеющуюся цепочку.
      if(!$ProcessedExt{$ext}) {
        $th->removehandler($ext);
        $ProcessedExt{$ext}=1;
      }
      # Затем спокойно вызываем pushhandler()
      $th->pushhandler($ext,$hand);
    }
  }
}

sub process_htaccesses
{ my ($th,$path)=@_;
  # Сначала определяем все полные пути к htaccess-файлам
  my @Hts=();
  while($path=~m{[/\\]}) {
    if(-d $path) {
      my $ht="$path/$th->{htaccess}";
      unshift(@Hts,$ht) if -f $ht;
    }
    $path=~s{[/\\][^/\\]*$}{}s;
  }
  # Затем обрабатываем эти файлы, начиная с самого корневого
  map { $th->process_htaccess($_) } @Hts;
}

# void run_uri(string $uri [,string $path_translated])
# Запускает указанный URI на обработку. Если указан параметр $path_translated,
# то он содержит полное имя файла с содержимым для обработки. В противном 
# случае имя файла вычисляется автоматически на основе $uri (это не всегда
# работает правильно - например, такая штука не пройдет, если директория была
# заведена как Alias Apache).
sub run_uri
{ my ($this,$uri,$path)=@_;
  Header("X-Powered-by: Apache::Scriptor v$VERSION. (C) Dmitry Koterov <koterov at cpan dot org>") if !$CopySend++;

  # Теперь работаем с КОПИЕЙ объекта. Таким образом, дальнейшие вызовы
  # process_htaccesses и т.д. не отразятся на общем состоянии объекта
  # после окончания запроса.
  local $this->{Handlers}={%{$this->{Handlers}}};
  local $this->{404}=$this->{404};

  # Разделяем на URL и QUERY_STRING
  local ($ENV{SCRIPT_NAME},$q) = split /\?/, $uri, 2;
  $ENV{QUERY_STRING}=defined $q? $q : "";

  # Вычисляем путь к файлу скрипта по URI
  if(!$path) {
    $path="$ENV{DOCUMENT_ROOT}$ENV{SCRIPT_NAME}";
  }

  # Готовим новые переменные окружения, чтобы скрыть Apache::Scriptor;
  local $ENV{REQUEST_URI}     = $uri;
  local $ENV{SCRIPT_FILENAME} = $path;
  local $ENV{REDIRECT_URL};     delete($ENV{REDIRECT_URL});
  local $ENV{REDIRECT_STATUS};  delete($ENV{REDIRECT_STATUS});
  # Меняем текущую директорию.
  my $MyDir=getcwd(); 
  ($MyDir) = $MyDir=~/(.*)/;
  my ($dir) = $path; $dir=~s{(.)[/\\][^/\\]*$}{$1}sg;
 
  chdir($dir); getcwd(); # getcwd: Сбрасывает $ENV{PWD}. Нам это надо? Фиг знает...
  # Обрабатываем файлы .htaccess.
  $this->process_htaccesses($path);

  # Все. Теперь состояние переменных скрипта такое же, как у страницы,
  # которая в дальнейшем получит управление. Запускаем обработчики.
  $this->__run_handlers();
  
  # Восстанавливаем текущую директорию
  chdir($MyDir); getcwd(); 
}


# Внутренняя функция - запускает обработчики для файла, который задан в %ENV.
# Вызывается В КОНТЕКСТЕ ЭТОГО ФАЙЛА (то есть, %ENV находится в таком же состоянии,
# как после обячного запуска скрипта Апачем, и текущая директория соответствует
# директории со страницей).
sub __run_handlers
{ my ($th)=@_;
  # расширение файла
  my ($ext)  = $ENV{SCRIPT_FILENAME}=~m|\.([^.]*)$|; if(!defined $ext) { $ext=""; }

  # выбираем список обработчиков для этого расширения
  $th->{Handlers}{$ext} 
    or die "$ENV{SCRIPT_NAME}: could not find handlers chain for extension \"$ext\"\n";

  # входной буфер (вначале в нем содержимое файла, если доступно)
  my $input="";
  if(open(local *F, $ENV{SCRIPT_FILENAME})) { local ($/,$\); binmode(F); $input=<F>; }

  # проходимся по всем обработчикам
  my $next=1; # номер следующего обработчика
  my @hands=@{$th->{Handlers}{$ext}};
  NoAutoflush() if @hands>1;
  foreach my $hand (@hands)
  { # Объект перенаправления вывода. Если у нас всего один обработчик, то 
    # перенаправлять вывод не потребуется. Иначе - потребуется, что и делается
    my $OutObj=$hands[$next++]? CGI::WebOut->new : undef;
    my $func=$hand; # указатель на функцию
    # Проверяем - нужно ли загрузить обработчик?
    if((ref($func)||"") ne "CODE") {
      # переключаем пакет
      package Apache::Scriptor::Handlers; 
      # обработчика еще нет в этом пакете?
      if(!*{$func}{CODE}) {
        my $hname="$th->{HandDir}/$func.pl";
        -f $hname or die "$ENV{SCRIPT_NAME}: could not load the file $hname for handler $hand\n";
        do "$hname";
        *{$func}{CODE} or die "$ENV{SCRIPT_NAME}: cannot find handler $hand in $hname after loading $hname\n";
      }
      # получаем указатель на функцию обработчика
      local $this=$th;
      $func=*{$func}{CODE};
    }
    # Функция обработчика принимает параметр: входной буфер.
    # Ее задача - обработать его и, используя print, пропечатать результат.
    # В случае ошибки (файл не найден) функция должна возвратить -1!
    my $result=&$func($input);
    if($result eq "-1") {
      if($th->{404} && $th->{404} ne $th->{self_scriptname}) {
        Redirect($th->{404});
        exit;
      } else {
        die "$hand: could not find the file $ENV{SCRIPT_FILENAME}\n";
      }
    }

    # То, что получилось, кладем во входной буфер для следующего обработчика.
    # Если вывод не перенаправлялся, то кладем туда "".
    $input=$OutObj?$OutObj->buf:"";
  }
  # Окончательный результат окажется во входном буфере (как будто готовый для 
  # следующего обработчика, которого нет). Его-то мы и выводим в браузер.
  print $input;
}



package Apache::Scriptor::Handlers;
use CGI::WebOut;
# В этом пакете перечисляются стандартные обработчики, 
# которые, скорее всего, будут испрользованы в первую очередь.
# Именно в этот пакет попадают обработчики, загруженные автоматически.

# Обработчик по умолчанию - просто выводит текст
sub default
{ my ($input,$fname)=@_;
  -f $ENV{SCRIPT_FILENAME} or return -1;
  CGI::WebOut::Header("Content-type: text/html");
  print $input;
}

# Обработчик perl-скриптов. Подразумевается, что вывод скрипта идет через print.
sub perl
{ my ($input)=@_;
  -f $ENV{SCRIPT_FILENAME} or return -1;
  eval("\n#line 1 \"$ENV{SCRIPT_NAME}\"\npackage main; $input");
}

return 1;
__END__







=head1 NAME

Apache::Scriptor - Support for Apache handlers conveyor.

=head1 SYNOPSIS

Synopsis are not so easy as in other modules, that's why let's see example below.

=head1 FEATURES

=over 4

=item *

Uses ONLY perl binary.

=item *

Helps to organize the Apache handler conveyor. That means you can redirect the output from one handler to another handler.

=item *

Supports non-existance URL handling and 404 Error processing.

=item *

Uses C<.htaccess> files to configure.

=back


=head1 EXAMPLE

  ### Consider the server structure:
  ### /
  ###   _Kernel/
  ###      handlers/
  ###        s_copyright.pl
  ###        ...
  ###      .htaccess
  ###      Scriptor.pl
  ###   .htaccess
  ###   test.htm

  ### File /.htaccess:
    # Setting up the conveyor for .htm:
    # "input" => eperl => s_copyright => "output" 
    Action     perl "/_Kernel/Scriptor.pl"
    AddHandler perl .htm
    Action     s_copyright "/_Kernel/Scriptor.pl"
    AddHandler s_copyright .htm


  ### File /_Kernel/.htaccess:
    # Enables Scriptor.pl as perl executable
    Options ExecCGI
    AddHandler cgi-script .pl

  ### File /_Kernel/Scriptor.pl:
    #!/usr/local/bin/perl -w 
    use FindBin qw($Bin);          # текущая директория
    my $HandDir="$Bin/handlers";   # директория с обработчиками
    # This is run not as CGI-script?
    if(!$ENV{DOCUMENT_ROOT} || !$ENV{SCRIPT_NAME} || !$ENV{SERVER_NAME}) {
      print "This script has to be used only as Apache handler!\n\n";
      exit;
    }
    # Non-Apache-handler run?
    if(!$ENV{REDIRECT_URL}) {
      print "Location: http"."://$ENV{SERVER_NAME}/\n\n";
      exit;
    }
    require Apache::Scriptor;
    my $Scr=Apache::Scriptor->new();
    # Setting up the handlers' directory.
    $Scr->set_handlers_dir($HandDir);
    # Go on!
    $Scr->run_uri($ENV{REQUEST_URI},$ENV{PATH_TRANSLATED});

  ### File /_Kernel/handlers/s_copyright.pl:
    sub s_copyright
    {  my ($input)=@_;
       -f $ENV{SCRIPT_FILENAME} or return -1; # Error indicator
       # Adds the comment string BEFORE all the output.
       print '<!-- Copyright (C) by Dmitry Koterov (koterov at cpan dot org) -->\n'.$input;
       return 0; # OK
    }

  ### File /test.htm:
    print "<html><body>Hello, world!</body></html>";

  ### Then, user enters the URL: http://ourhost.com/test.htm.
  ### The result will be:
    Content-type: text/html\n\n
    <!-- Copyright (C) by Dmitry Koterov (koterov at cpan dot org) -->\n
    Hello, world!

=head1 OVERVIEW

This module is used to handle all the requests through the Perl script 
(such as C</_Kernel/Scriptor.pl>, see above). This script is just calling
the handlers conveyor for the specified file types.

When you place directives like these in your C<.htaccess> file:

  Action     s_copyright "/_Kernel/Scriptor.pl"
  AddHandler s_copyright .htm

Apache sees that, to process C<.htm> document, C</_Kernel/Scriptor.pl> handler
should be used. Then, Apache::Scriptor starts, reads this C<.htaccess> and remembers
the handler name for C<.htm> document: it is C<s_copyright>. Apache::Scriptor searches 
for C</_Kernel/handlers/s_copyright.pl>, trying to find the subroutine with the same name:
C<s_copyright()>. Then it runs that and passes the document body, returned from the previous 
handler, as the first parameter. 

How to start the new conveyor for extension C<.html>, for example? It's easy: you
place some Action-AddHandler pairs into the C<.htaccess> file. You must choose
the name for these handlers corresponding to the Scriptor handler file names 
(placed in C</_Kernel/handlers>). Apache does NOT care about these names, but 
Apache::Scriptor does. See example above (it uses two handlers: built-in C<perl> and user-defined C<s_copyright>).

=head1 DESCRIPTION

=over 11

=item C<require Apache::Scriptor>

Loads the module core.

=item C<Apache::Scriptor'new>

Creates the new Apache::Scriptor object. Then you may set up its 
properties and run methods (see below).

=item C<$obj'set_handlers_dir($dir)>

Sets up the directory, which is used to search for handlers.

=item C<$obj'run_uri($uri [, $filename])>

Runs the specified URI through the handlers conveyer and prints out 
the result. If C<$filename> parameter is specified, module does not
try to convert URL to filename and uses it directly.

=item C<$obj'addhandler(ext1=>[h1, h2,...], ext2=>[...])>

Manually sets up the handlers' conveyor for document extensions. 
Values of C<h1>, C<h2> etc. could be code references or 
late-loadable function names (as while parsing the C<.htaccess> file).

=item C<$obj'pushhandler($ext, $handler)>

Adds the handler C<$handler> th the end of the conveyor for extension C<$ext>.

=item C<$obj'removehandler($ext)>

Removes all the handlers for extension C<$ext>.

=item C<$obj'set_404_url($url)>

Sets up the redirect address for 404 error. By default, this value is 
bringing up from C<.htaccess> files.

=item C<$obj'set_htaccess_name($name)>

Tells Apache::Scriptor object then Apache user configuration file is called C<$name>
(by default C<$name=".htaccess">).

=item C<$obj'process_htaccess($filename)>

Processes all the directives in the C<.htaccess> file C<$filename> and adds
all the found handlers th the object.

=item C<package Apache::Scriptor::Handlers>

This package holds ALL the handler subroutines. You can place 
some user-defined handlers into it before loading the module to 
avoid their late loading from handlers directory.

=back

=head1 AUTHOR

Dmitry Koterov <koterov at cpan dot org>, http://www.dklab.ru

=head1 SEE ALSO

C<CGI::WebOut>.

=cut
