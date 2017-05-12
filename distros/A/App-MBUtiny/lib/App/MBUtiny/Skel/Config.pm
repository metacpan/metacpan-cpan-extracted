package App::MBUtiny::Skel::Config; # $Id: Config.pm 76 2014-09-24 15:02:37Z abalama $
use strict;

use CTK::Util qw/ :BASE /;

use vars qw($VERSION);
$VERSION = '1.06';

sub build {
    # Процесс сборки
    my $self = shift;

    my $rplc = $self->{rplc};
    $rplc->{FOO} = "FOO";
    $rplc->{BAR} = "BAR";
    $rplc->{BAZ} = "BAZ";
    
    return 1;
}
sub dirs {
    # Список директорий и прав доступа к каждой из них

    {
            path => 'extra',
            mode => 0755,
    },
    {
            path => 'hosts',
            mode => 0755,
    },
    
}
sub pool {
    # Бассеин с разделенными multipart файламми
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    return $data;
}

1;
__DATA__

-----BEGIN FILE-----
Name: mbutiny.conf
File: mbutiny.conf
Mode: 644

#
# See Config::General for details
#

# Activate or deactivate the logging: on/off (yes/no)
# LogEnable off
LogEnable   on

# debug level: debug, info, notice, warning, error, crit, alert, emerg, fatal, except
# LogLevel debug
LogLevel warning

# The number of daily archives
# This is the number of stored past the daily archives.
# BUday 3
BUday    3

# The number of weekly archives
# This is the last weekly number of stored files. Weekly archives are those daily 
# archives that were created on Sunday.
# BUweek   3
BUweek   3

# Number of monthly archives
# This amount of stored past monthly archives. Monthly Archives are those daily archives 
# that were created on the first of each month.
# BUmonth  3
BUmonth  3

SendReport      no
SendErrorReport no

# Definitions of required hosts for checking
#CheckupRequire foo bar baz quux

Include extra/*.conf
Include hosts/*.conf
-----END FILE-----

-----BEGIN FILE-----
Name: arc.conf
File: extra/arc.conf
Mode: 644

# Tape ARchive
<Arc tar>
    type       tar
    ext        tar
    create     tar -cpf [FILE] [LIST] 2>/dev/null
    extract    tar -xp -C [DIRDST] -f [FILE]
    exclude    --exclude-from
    list       tar -tf [FILE]
    nocompress tar -cpf [FILE]
</Arc>

# Tape ARchive + GNU Zip
<Arc tgz>
    type       tar
    ext        tgz
    create     tar -zcpf [FILE] [LIST] 2>/dev/null
    extract    tar -zxp -C [DIRDST] -f [FILE]
    exclude    --exclude-from
    list       tar -ztf [FILE]
    nocompress tar -cpf [FILE]
</Arc>

# GNU Zip (One file only)
<Arc gz>
    type       gz
    ext        gz
    create     gzip --best [FILE] [LIST]
    extract    gzip -d [FILE]
    exclude    --exclude-from
    list       gzip -l [FILE]
    nocompress gzip -0 [FILE] [LIST]
</Arc>

# ZIP
<Arc zip>
    type       zip
    ext        zip
    create     zip -rqqy [FILE] [LIST]
    extract    unzip -uqqoX [FILE] [DIRDST]
    exclude    -x\@
    list       unzip -lqq
    nocompress zip -qq0
</Arc>

# bzip2 (One file only)
<Arc bz2>
    type       bzip2 
    ext        bz2
    create     bzip2 --best [FILE] [LIST]
    extract    bzip2 -d [FILE]
    exclude    --exclude-from
    list       bzip2 -l [FILE]
    nocompress bzip2 --fast [FILE] [LIST]
</Arc>

# RAR
<Arc rar>
    type       rar
    ext        rar
    create    rar a -r -ol -y [FILE] [LIST]
    extract    rar x -y [FILE] [DIRDST]
    exclude    -x\@
    list       rar vb
    nocompress rar a -m0
</Arc>

-----END FILE-----

-----BEGIN FILE-----
Name: arc.conf
File: extra/arc.conf
Mode: 644
Type: Windows

#######################
#
# Секция работы с архивами. Оригинал см. в модуле CTK
# 
# В этой секции определяются основные настройки работы с архивами,
# каждое значение любого параметра обрабатывается единым механизмом обработки маски.
# Ключи в маске могут быть использованы следующие:
#
# Для случая извлечения файлов из арива:
#    FILE     -- Полное имя файла с путем
#    FILENAME -- Только имя файлов архивов
#    DIRSRC   -- Каталог поиска имен файлов
#    DIRIN    -- = DIRSRC
#    DIRDST   -- Каталог для исзвлечения содержимого архивов
#    DIROUT   -- = DIRDST
#    LIST     -- Список файлов в архиве, через пробел
#    EXC      -- 'exclude file' !!!Зарезервировано!!!
#
# Для случая сжатия файлов используется следеющий набор ключей:
#    FILE     -- Полное имя выходного файла архива с путем
#    DIRSRC   -- Каталог поиска имен файлов и подкаталогов для сжатия
#    DIRIN    -- = DIRSRC
#    LIST     -- Список файлов для сжатия, через пробел
#    EXC      -- 'exclude file' !!!Зарезервировано!!!
#
# Для примера можно рассмотреть случай с архиватором tar
# 
# <Arc tgz> # Начало именованной секции. Имя, как правило, это расширение файлов архива
#    type       tar                       # Тип архива, его версия имени
#    ext        tgz                       # Расширение файлов архива
#    create     tar -zcpf [FILE] [LIST]   # Команда для создания архива
#    extract    tar -zxpf [FILE] [DIRDST] # Команда для извлечения файлов из архива
#    exclude    --exclude-from            # !!!Зарезервировано!!!
#    list       tar -ztf [FILE]           # Команда для получения списка файлов в архиве
#    nocompress tar -cpf [FILE]           # Команда для упаковки файлов без сжатия
# </Arc>
#
######################

# Tape ARchive
<Arc tar>
    type       tar
    ext        tar
    create     tar -cpf [FILE] [LIST] 2>NUL
    extract    tar -xpf [FILE] -C [DIRDST]
    exclude    --exclude-from
    list       tar -tf [FILE]
    nocompress tar -cpf [FILE]
</Arc>

# Tape ARchive + GNU Zip
<Arc tgz>
    type       tar
    ext        tgz
    create     tar -cvf %TEMP%/mbutiny_arch.tar [LIST] 2>NUL \
               && gzip --best -S .tmp %TEMP%/mbutiny_arch.tar \
               && mv %TEMP%/mbutiny_arch.tar.tmp [FILE]
    extract    tar -zxpf [FILE] -C [DIRDST]
    exclude    --exclude-from
    list       tar -ztf [FILE]
    nocompress tar -cpf [FILE]
</Arc>

# GNU Zip (One file only)
<Arc gz>
    type       gz
    ext        gz
    create     gzip --best [FILE] [LIST]
    extract    gzip -d [FILE]
    exclude    --exclude-from
    list       gzip -l [FILE]
    nocompress gzip -0 [FILE] [LIST]
</Arc>

# ZIP
<Arc zip>
    type       zip
    ext        zip
    create     zip -rqq [FILE] [LIST]
    extract    unzip -uqqoX [FILE] -d [DIRDST]
    exclude    -x\@
    list       unzip -lqq
    nocompress zip -qq0
</Arc>

# bzip2 (One file only)
<Arc bz2>
    type       bzip2 
    ext        bz2
    create     bzip2 --best [FILE] [LIST]
    extract    bzip2 -d [FILE]
    exclude    --exclude-from
    list       bzip2 -l [FILE]
    nocompress bzip2 --fast [FILE] [LIST]
</Arc>

# RAR
<Arc rar>
    type       rar
    ext        rar
    create     rar a -r -y -ep2 [FILE] [LIST]
    extract    rar x -y [FILE] [DIRDST]
    exclude    -x\@
    list       rar vb
    nocompress rar a -m0
</Arc>

-----END FILE-----

-----BEGIN FILE-----
Name: sendmail.conf
File: extra/sendmail.conf
Mode: 644

<SendMail>
    To          to@example.com
    Cc          cc@example.com
    From        from@example.com
    TestMail    test@example.com
    ErrorMail   error@example.com
    Charset     windows-1251
    Type        text/plain
    #Sendmail   /usr/sbin/sendmail
    #Flags      -t
    SMTP        192.168.0.1
    
    # Authorization SMTP
    #SMTPuser   user
    #SMTPpass   password

    # Attachment files
    #<Attach>
    #    Filename    doc1.txt 
    #    Type        text/plain 
    #    Disposition attachment
    #    Data        "Document 1. Content"
    #</Attach>
    #<Attach>
    #    Filename    mbutiny.log
    #    Type        text/plain
    #    Disposition attachment
    #    Path        /var/log/mbutiny.log
    #</Attach>
</SendMail>

-----END FILE-----

-----BEGIN FILE-----
Name: collector.conf
File: extra/collector.conf
Mode: 644

# See also collector.cgi.sample file
<Collector>
###
### !!! WARNING !!!
###
### Before using the collector-server, please check your DataBase and create the table "mbutiny"
###
#CREATE TABLE `mbutiny` (
#  `id` int(11) NOT NULL auto_increment,
#  `type` int(2) default '0' COMMENT '0 - external backup / 1 - internal backup',
#  `datestamp` datetime NOT NULL default '0000-00-00 00:00:00',
#  `agent_host` varchar(255) collate utf8_bin default NULL,
#  `agent_ip` varchar(40) collate utf8_bin default NULL,
#  `agent_name` varchar(255) collate utf8_bin default NULL,
#  `server_host` varchar(255) collate utf8_bin default NULL,
#  `server_ip` varchar(40) collate utf8_bin default NULL,
#  `status` int(2) default '0' COMMENT '0 - Error / 1 - OK',
#  `date_start` datetime default NULL,
#  `date_finish` datetime default NULL,
#  `file_name` varchar(255) collate utf8_bin default NULL,
#  `file_size` int(11) default NULL,
#  `file_md5` varchar(32) collate utf8_bin default NULL,
#  `file_sha1` varchar(40) collate utf8_bin default NULL,
#  `message` text collate utf8_bin,
#  `comment` text collate utf8_bin,
#  PRIMARY KEY  (`id`),
#  UNIQUE KEY `id` (`id`)
#) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

    # Directory for backup files. 
    # Default: current directory of Your web-server (DOCUMENT_ROOT)
    # DataDir   "/var/data/mbutiny"

    # Section for connection with Your database. Recommended for use follow databases:
    # MySQL, Oracle, PostgreSQL (pg) and SQLite
    # MySQL example:
    <DBI>
        DSN         "DBI:mysql:database=mbutiny;host=mysql.example.com"
        User        username
        Password    password
        Table       mbutiny
        Set RaiseError          0
        Set PrintError          0
        Set mysql_enable_utf8   1
    </DBI>

    # Oracle Example
    #<DBI>
    #    DSN        "dbi:Oracle:MYSID"
    #    User       username
    #    Password   password
    #    Table      mbutiny
    #    Set RaiseError 0
    #    Set PrintError 0
    #</DBI>

    # SQLite example:
    #<DBI>
    #    DSN        "dbi:SQLite:dbname=test.db"
    #    Table      mbutiny
    #    Set RaiseError     0
    #    Set PrintError     0
    #    Set sqlite_unicode 1
    #</DBI>
</Collector>

-----END FILE-----

-----BEGIN FILE-----
Name: host-foo.conf.sample
File: hosts/host-foo.conf.sample
Mode: 644

<Host foo>
    Enable          yes
    SendReport      no
    SendErrorReport yes

    ArcName         tgz
    ArcMask         [HOST]-[YEAR]-[MONTH]-[DAY].[EXT]

    BUday           3
    BUweek          3
    BUmonth         3

    SHA1sum         yes
    MD5sum          yes

    # Triggers
    Trigger mkdir ./test
    Trigger mkdir ./test/mbu_sample
    Trigger mkdir ./test/mbu_sample/test
    Trigger echo foo > ./test/mbu_sample/foo.txt
    Trigger echo bar > ./test/mbu_sample/bar.txt
    Trigger echo baz > ./test/mbu_sample/baz.txt
    Trigger ls -la > ./test/mbu_sample/test/dir.lst
    #Trigger mysqldump -f -h mysql.host.com -u user --port=3306 --password=password \
    #        --add-drop-table --default-character-set=utf8 \
    #        --databases databasename > ./test/mbu_sample/test/databasename.sql
    
    # Objects
    Object ./test/mbu_sample/foo.txt
    Object ./test/mbu_sample/bar.txt
    Object ./test/mbu_sample/baz.txt
    Object ./test/mbu_sample/test

    # Exlusive objects (Can be defined by several sections)
    <Exclude "exclude_sample">
         Object ./test/mbu_sample
         #Target ./test/mbu_sample_target

         Exclude bar.txt
         Exclude test/dir.lst
    </Exclude>

    # SendMail functions (optional)
    # See extra/sendmail.conf for details
    <SendMail>
        To          to@example.com
        Cc          cc@example.com
        From        from@example.com
        Testmail    test@example.com
        Errormail   error@example.com
        Charset     windows-1251
        Type        text/plain
        #Sendmail    /usr/sbin/sendmail
        #Flags       -t
        Smtp        192.168.0.1
        #SMTPuser user
        #SMTPpass password
        #<Attach>
        #    Filename    foo.log
        #    Type        text/plain
        #    Disposition attachment
        #    Path        /var/log/mbutiny-foo.log
        #</Attach>
    </SendMail>
    
    # Collector definitions (Can be defined by several sections)
    #<Collector>
    #    URI         https://user:password@collector.example.com/collector.cgi
    #    #User       user # Optional. See URI
    #    #Password   password # Optional. See URI
    #    Comment     HTTP said blah-blah-blah for collector # Optional for collector
    #    #TimeOut    180
    #</Collector>

    # Local storage
    <Local>
        FixUP       off
        Localdir    ./test/mbutimy-local1
        Localdir    ./test/mbutimy-local2
        #Comment    Local said blah-blah-blah for collector # Optional for collector
    </Local>

    # FTP storage (Can be defined by several sections)
    #<FTP>
    #    FixUP       on
    #    FTPhost     ftp.example.com
    #    FTPdir      mbutiny/foo
    #    FTPuser     user
    #    FTPpassword password
    #    Set         Passive 1
    #    Comment     FTP said blah-blah-blah for collector # Optional for collector
    #</FTP>

    # HTTP storage (Can be defined by several sections)
    #<HTTP>
    #    FixUP       on
    #    URI         https://user:password@collector.example.com/collector.cgi
    #    #User       user # Optional. See URI
    #    #Password   password # Optional. See URI
    #    Comment     HTTP said blah-blah-blah for collector # Optional for collector
    #    #TimeOut    180
    #</HTTP>

</Host>
-----END FILE-----

-----BEGIN FILE-----
Name: host-foo.conf.sample
File: hosts/host-foo.conf.sample
Mode: 644
Type: Windows

#######################
#
# Секция работы с именованным хостом
# 
# В этой секции определются настройки резервоного копирования хоста.
# Хост, в термах проекта mbutiny - это услованый, именованный набор объектов
# для сжатия и отправки в определенный каталог назначения, используя при этом
# свой набор правил и параметров, отличных от параметров установленных в
# секциях по умолчанию.
# Здесь следует указывать секции, которые будут работать в данном хосте:
#
#    <SendMail>, <FTP>, <Local> и другие
#
# Если какие-либо параметры не будут определены, то их значения будут 
# использованы из секций по умолчанию.
#
# Важное замечание по параметру ArcMask. ArcMask указывает на то, по какому
# формату (маске) хранить архив результативного бэкапа. Маски файлов могут 
# иметь сложный вид, но по умолчанию используется маска вида:
#
#    [HOST]-[YEAR]-[MONTH]-[DAY].[EXT]
#
# Ключи маски могут быть использованы следующие:
#
#    DEFAULT  -- Значение соответствующее формату [HOST]-[YEAR]-[MONTH]-[DAY].[EXT]
#    HOST     -- Имя секции хоста
#    YEAR     -- Год создания архива
#    MONTH    -- Месяц создания архива
#    DAY      -- День создания архива
#    EXT      -- Расширение файла архива
#    TYPE     -- Тип архива
#
######################
<Host foo>
    # Включение или выключение хоста. Аттрибут влияет на обработку
    # Если атрибут установлен, то обработка хоста выполнится, иначе хост игнорируется.
    Enable      yes

    # Включение или выключение отправки письма о статусе работы
    # Если "включить" SendReport то значение SendErrorReport игнорируется 
    SendReport  no

    # Включение или выключение отправки письма о статусе работы только в случае неудачи.
    # Если "включить" SendReport то значение SendErrorReport игнорируется 
    SendErrorReport yes

    # Имя типовых архиваторов. См. файл extra/arc.conf
    ArcName     zip

    # Маска файлов архивов. См. описание выше
    ArcMask [HOST]-[YEAR]-[MONTH]-[DAY].[EXT]
  
    # Количество ежедневных архивов
    # Это количество хранимых последних ежедневных архивов.
    BUday       3

    # Количество еженедельных архивов
    # Это Количество хранимых последних еженедельных архивов. 
    # Еженедельными архивами считаются те ежедневные архивы,
    # которые были созданы в воскресенье.
    BUweek      3

    # Количество ежемесячных архивов
    # Это Количество хранимых последних ежемесячных архивов. 
    # Ежемесячными архивами считаются те ежедневные архивы,
    # которые были созданы первого числа каждого месяца.
    BUmonth     3

    # По завершению операции сжатия происходит подсчет контрольных сумм 
    # SHA1 и MD5. Данные сумы желательно использовать для контроля качества
    # прохождения бэкапов и восстановления, а также при работе с коллектором
    SHA1sum     yes
    MD5sum      yes

    # Триггеры. Это команды, выполняющиеся до того как будет сформирован конечный 
    # список обрабатываемых объекстов. Триггеры выполняются один за другим, но порядок
    # их выполнения является неопределнным. Для соблюдения требуемого порядкя
    # следует использовать сложные команды или выносить их в отдельные скрипты
    Trigger mkdir C:\\Temp\\mbu_sample
    Trigger mkdir C:\\Temp\\mbu_sample\\test
    Trigger echo foo > C:\\Temp\\mbu_sample\\foo.txt
    Trigger echo bar > C:\\Temp\\mbu_sample\\bar.txt
    Trigger echo baz > C:\\Temp\\mbu_sample\\baz.txt
    Trigger dir > C:\\Temp\\mbu_sample\\test\\dir.lst
    #Trigger mysqldump -f -h mysql.host.com -u user --port=3306 --password=password \
    #        --add-drop-table --default-character-set=utf8 \
    #        --databases databasename > C:\\Temp\\mbu_sample\\test\\databasename.sql
    
    # Список имен объектов для обработки (локальные папки и файлы)
    Object C:\\Temp\\mbu_sample\\foo.txt
    Object C:\\Temp\\mbu_sample\\bar.txt
    Object C:\\Temp\\mbu_sample\\baz.txt
    Object C:\\Temp\\mbu_sample\\test

    # Секции эксклюзивного копирования объектов. Секции позволяют копировать файлы и 
    # папки каталога указанного в директиве Object в целевой каталог определенный
    # с поощью директивы Target. Копирование происходит всей структуры исходного 
    # каталога в целефой каталог исключая объекты, указанные во внутренних
    # директивах Exclude. Данный способ создания объектов требует дополнительного 
    # свободного места.
    <Exclude "exclude_sample">
         # Отсюда берутся сами файлы. Директива может быть только одна
         Object C:\\Temp\\mbu_sample

         # Опционально. Сюда копируются объекты
         #Target C:\\Temp\\mbu_sample_target

         # Относительные пути файлов и папок
         Exclude bar.txt
         Exclude test/dir.lst
    </Exclude>


    # Программа SendMail и параметры отправки почты
    # Более детальную информацию см. в файле extra/sendmail.conf
    <SendMail>
        To          to@example.com
        Cc          cc@example.com
        From        from@example.com
        Testmail    test@example.com
        Errormail   error@example.com
        Charset     windows-1251
        Type        text/plain
        Smtp        192.168.0.1
        #SMTPuser user
        #SMTPpass password
        #<Attach>
        #    Filename    foo.log
        #    Type        text/plain
        #    Disposition attachment
        #    Path        /var/log/mbutiny-foo.log
        #</Attach>
    </SendMail>

    # Параметры коллектора. Секций может быть определено несколько
    # URI         - Адрес URI до хранилища (коллектора). Логин и пароль HTTP авторизации
    #               указывается либо в URI либо отдельно, если это требует безопасность.
    # TimeOut     - Таймаут. По умолчанию 180 секунд.
    #<Collector>
    #    URI         https://user:password@collector.example.com/collector.cgi
    #    #User       user # Optional. See URI
    #    #Password   password # Optional. See URI
    #    #TimeOut    180
    #</Collector>

    # Параметры локального хранилища, это хранилище не является надежным,
    # если его точка монтирования не является внешней относительно данного
    # аппаратного устройства (сервера, компьютера, хранилища, маршрутизатора и т.д.)
    <Local>
        FixUP       off

        # Директив Localdir может быть несколько, тогда произойдет копирование бэкапа в 
        # различные локальные хранилища 
        Localdir    C:\\Temp\\mbutimy-local1
        Localdir    C:\\Temp\\mbutimy-local2

        #Comment    Local said blah-blah-blah for collector # Optional for collector
    </Local>

    # Параметры удаленного FTP-хранилища
    # FTPhost     - Адрес или доменное имя FTP сервера
    # FTPdir      - Директория хранения архивов. Для каждого хоста нужна своя директория
    # FTPuser     - Имя пользователя FTP сервера
    # FTPpassword - Пароль пользователя FTP сервера
    # Set         - Устанавливает атрибут соединения FTP и его значение (через пробел)
    # FixUP       - on/off - Указывает выполнять фиксацию результата работы на коллекторе
    # Comment     - Комментарий для коллектора. Полезен для мониторинга
    # Секций <FTP> может быть несколько. В этом случае выполнится работа над каждым
    # FTP-хранилищем
    #<FTP>
    #    FixUP       on
    #    FTPhost     ftp.example.com
    #    FTPdir      mbutiny/foo
    #    FTPuser     user
    #    FTPpassword password
    #    Set         Passive 1
    #    Comment     FTP said blah-blah-blah for collector # Optional for collector
    #</FTP>
    
    # Параметры удаленного HTTP-хранилища
    # URI         - Адрес URI до хранилища (коллектора). Логин и пароль HTTP авторизации
    #               указывается либо в URI либо отдельно, если это требует безопасность.
    # FixUP       - on/off - Указывает выполнять фиксацию результата работы на коллекторе
    #               Следует учитывать, что параметры для коллектора фиксапа задаются 
    #               отдельной секцией, т.к. файлы могут хранится на одном коллекторе а
    #               данные о статусе на другом
    # Comment     - Комментарий для коллектора. Полезен для мониторинга
    # TimeOut     - Таймаут. По умолчанию 180 секунд. Следует задавать если размер бэкапа
    #               существенно большой, и не успевает пройти за дефолтное значение
    #               параметра. 
    # Секций <HTTP> может быть несколько. В этом случае выполнится работа над каждым
    # HTTP-хранилищем
    #<HTTP>
    #    FixUP       on
    #    URI         https://user:password@collector.example.com/collector.cgi
    #    #User       user # Optional. See URI
    #    #Password   password # Optional. See URI
    #    Comment     HTTP said blah-blah-blah for collector # Optional for collector
    #    #TimeOut    180
    #</HTTP>
</Host>
-----END FILE-----

-----BEGIN FILE-----
Name: collector.cgi.sample
File: collector.cgi.sample
Mode: 644

#!/usr/bin/perl -w
use strict;

use WWW::MLite;
my $mlite = new WWW::MLite(
        prefix  => 'collector',
        name    => 'Collector',
        module  => 'App::MBUtiny::Collector',
        config_file => '/path/to/mbutiny/extra/collector.conf',
        register => ['App::MBUtiny::Collector::Root'],
    );
$mlite->show;

-----END FILE-----
