package App::MonM::Skel::Config; # $Id: Config.pm 58 2016-10-05 09:49:47Z abalama $
use strict;

use CTK::Util qw/ :BASE /;

use constant SIGNATURE => "config";

use vars qw($VERSION);
$VERSION = '1.02';

sub build { # Процесс сборки
    my $self = shift;

    my $rplc = $self->{rplc};
    $rplc->{FOO} = "foo";
    $rplc->{BAR} = "bar";
    $rplc->{BAZ} = "baz";
    
    $self->maybe::next::method();
    return 1;
}
sub dirs { # Список директорий и прав доступа к каждой из них
    my $self = shift;    
    $self->{subdirs}{(SIGNATURE)} = [
        {
            path => 'extra',
            mode => 0755,
        },
        {
            path => 'conf.d',
            mode => 0755,
        },
    ];
    $self->maybe::next::method();
    return 1;
}
sub pool { # Бассеин с разделенными multipart файламми
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;
__DATA__

-----BEGIN FILE-----
Name: monm.conf
File: monm.conf
Mode: 644

# %DOLLAR%Id%DOLLAR%
# GENERATED: %GENERATED%
#
# See Config::General for details
#

# Activate or deactivate the logging: on/off (yes/no)
# LogEnable off
LogEnable   on

# debug level: debug, info, notice, warning, error, crit, alert, emerg, fatal, except
# LogLevel debug
LogLevel warning

Include extra/*.conf
Include conf.d/*.conf

-----END FILE-----

-----BEGIN FILE-----
Name: sendmail.conf
File: extra/sendmail.conf
Mode: 644

<SendMail>
    To          to@example.com
    Cc          cc@example.com
    From        from@example.com
    Type        text/plain
    #Sendmail   /usr/sbin/sendmail
    #Flags      -t
    SMTP        192.168.0.1
</SendMail>

-----END FILE-----

-----BEGIN FILE-----
Name: checkit.conf
File: extra/checkit.conf
Mode: 644

# GateWay for sending SMS
SMSGW "sendalertsms -s SIDNAME -u USER -p PASSWORD -q "SELECT SMS_FUNCTION('[PHONE]', '[MESSAGE]') FROM DUAL" [PHONE]"

-----END FILE-----

-----BEGIN FILE-----
Name: checkit-foo.conf
File: conf.d/checkit-foo.conf
Mode: 644

#
# See checkit-foo.conf.sample and README for details
#
<Checkit "foo">
    Enable      yes
    URL         http://www.example.com
    Target      code
    IsTrue      200
</Checkit>

-----END FILE-----

-----BEGIN FILE-----
Name: checkit-foo.conf.sample
File: conf.d/checkit-foo.conf.sample
Mode: 644

#
# See README for details
#
<Checkit "foo">
    Enable      yes
    URL         http://www.example.com
    Target      code
    IsTrue      200
</Checkit>

-----END FILE-----

-----BEGIN FILE-----
Name: checkit-foo.conf.sample
File: conf.d/checkit-foo.conf.sample
Mode: 644
Type: Windows

<Checkit "foo">
    # Включен или выключен счетчик. По умолчанию счетчик выключен!
    # Enable    no
    Enable      yes

    # Определение "Что такое плохо!"
    # IsFalse   !!perl/regexp (?i-xsm:^\s*(error|fault|no)) # Используется по умолчанию
    # IsFalse   ERROR
    
    # Определение "Что такое хорошо!"
    # IsTrue    !!perl/regexp (?i-xsm:^\s*(ok|yes)) # Используется по умолчанию
    # IsTrue    OK
    # IsTrue    Ok.

    # Порядок сортировки проверок.
    # OrderBy   true, false # Используется по умолчанию
    # OrderBy   ASC # Аналог предыдущего примера
    # OrderBy   ASC

    # Обратный порядок сортировки. При этом порядке проверяется сначала 
    # правило false а потом true, в случае если не задано правило true
    # OrderBy   false, true
    # OrderBy   DESC # Аналог предыдущего примера

    # Тип способа получения результата.
    # Type      http # Используется по умолчанию
    # Type      dbi
    # Type      oracle
    # Type      command
    
    ###################################
    ## Секция для запросов типа HTTP ##
    ###################################
    
    # Адрес для HTTP запроса 
    # URL       http://user:password@www.example.com
    URL         http://www.example.com
    
    # Метод HTTP. GET, POST, PUT, HEAD, OPTIONS, PATCH, DELETE, TRACE, CONNECT
    # Method    GET # Используется по умолчанию
    # Method    POST
    # Method    HEAD
    # Method    OPTIONS
    
    # Объект анализа
    # Target    content # Анализирует содержимое. Используется по умолчанию
    # Target    code # Анализирует HTTP код ответа.
    # Target    status # Анализирует HTTP статус ответа (status line).

    ##################################
    ## Секция для запросов типа DBI ##
    ##################################
    
    DSN         DBI:mysql:database=DATABASE;host=HOSTNAME
    # SQL       "SELECT 'OK' AS OK FROM DUAL" # Используется по умолчанию
    User        USER
    Password    PASSWORD
    # Connect_to    5 # Таймаут на коннект
    # Request_to    60 # Таймаут на выполнение запроса
    
    # Атрибуты. По умолчанию выставляется только PrintError 0
    #<ATTR>
    #  Mysql_enable_utf8    1
    #  PrintError           0
    #</ATTR>

    # Выставление регистрозависымых атрибутов
    # Set PrintError  0
    
    #####################################
    ## Секция для запросов типа ORACLE ##
    #####################################
    
    SID         SIDNAME # SID задается исходя из настроенного Вами tnsnames.sql. По умолчанию TEST
    # SQL       "SELECT 'OK' AS OK FROM DUAL" # Используется по умолчанию
    User        USER
    Password    PASSWORD
    # Connect_to    5 # Таймаут на коннект
    # Request_to    60 # Таймаут на выполнение запроса
    
    # Атрибуты. По умолчанию выставляется только PrintError 0
    #<ATTR>
    #  PrintError           0
    #</ATTR>

    # Выставление регистрозависымых атрибутов
    # Set PrintError  0
    
    ######################################
    ## Секция для запросов типа COMMAND ##
    ######################################
    
    Command     "ls -la" # Команда которая будет выполнена на текущей для App::MonM системе!
    IsTrue      !!perl/regexp (?i-xsm:README)

    # Триггеры.
    # Триггеры выполняются по изменению счетчика с True на False и обратно с учетом 
    # поправки на случайную (разовую) ошибку.
    <Triggers>
        # Список адресов электронной почты для отправки писем стандартного формата:
        # Тема: MONM CHECKIT REPORT
        # Сообщение: Дамп структуры счетчика в конфигурации
        # emailalert    foo@example.com
        # emailalert    bar@example.com
        # emailalert    baz@example.com

        # Список номеров телефонов для отправки сообщений с помощью внешнего приложения. Номера
        # следует определять в международном стандарте (DEF) без ведущего плюса (+)
        # smsalert      11231230001
        # smsalert      11231230002
        # smsalert      11231230003

        # Список команд, которые будут выполнены по срабатыванию триггера
        # Работают подстановки:
        #   [SUBJECT] -- Тема
        #   [MESSAGE] -- Сообщение
        # command       "mycommand1 \"[SUBJECT]\" \"[MESSAGE]\""
        # command       "mycommand2 \"[MESSAGE]\""
        # command       "mycommand3"
    </Triggers>

    # Параметры для шлюза SMS. Если данное определение опущено, то по умолчанию будет
    # использоваться определение из файла extra/checkit.conf
    # Работают подстановки:
    #   [PHONE]   -- Номер телефона
    #   [SUBJECT] -- Тема
    #   [MESSAGE] -- Сообщение
    # SMSGW "sendalertsms "[NUMBER]" "[SUBJECT]" "[MESSAGE]""

</Checkit>

-----END FILE-----

-----BEGIN FILE-----
Name: dbi-foo.conf.sample
File: conf.d/dbi-foo.conf.sample
Mode: 644

<DBI foo>
    DSN     "DBI:mysql:database=NAME;host=HOST"
    #SID    TEST
    SQL     SELECT SYSDATE() FROM DUAL
    User                    USER
    Password                PASSWORD
    Connect_to              5
    Request_to              60
    Set mysql_enable_utf8   1
    Set PrintError          0
</DBI>

-----END FILE-----

-----BEGIN FILE-----
Name: http-foo.conf.sample
File: conf.d/http-foo.conf.sample
Mode: 644

<HTTP foo>
    CookieEnable    yes
    Method          POST
    URL             "http://www.example.com"
    #Login          USER
    #Password       PASSWORD
    UTF8            yes
    Data            "foo=bar&baz=qux"

    <Cookie>
      Autosave      1
      #File	data/test.cj
    </Cookie>
    <UA>
      <Header>
        Accept-Language     ru
        Cache-Control       no-cache
      </Header>
      <SSL_OPTS>
        verify_hostname		0
      </SSL_OPTS>

      Protocols_Allowed     http
      Protocols_Allowed     https # Required Crypt::SSLeay

      Requests_Redirectable GET
      Requests_Redirectable HEAD
      Requests_Redirectable POST

      Agent         "MonM/1.0"
      Max_Redirect  10
      Keep_Alive    1
      Env_Proxy     1
      Timeout       180
    </UA>
</HTTP>

-----END FILE-----

-----BEGIN FILE-----
Name: alertgrid.conf.sample
File: conf.d/alertgrid.conf.sample
Mode: 644

<AlertGrid>
    AlertGridName   localhost
    
    <Agent>
        IP 127.0.0.1
    
        #TransferType   local
        TransferType    http
        
        # HTTP connect
        <HTTP>
            URI     "http://USER:PASSWORD@host.example.com:8082/alertgrid.cgi?foo=bar"
        
            #Method  GET
            Method  POST

            #Login          USER
            #Password       PASSWORD
            
            #SendDBFile      yes
            
            CookieEnable    no
            <Cookie>
                Autosave    1
                #File       data/test.cj
            </Cookie>
            
            <UA>
                <Header>
                    #Accept-Language    ru
                    Cache-Control       no-cache
                </Header>
                <SSL_OPTS>
                    verify_hostname		0
                </SSL_OPTS>
                
                Protocols_Allowed	http
                # Required Crypt::SSLeay
                Protocols_Allowed	https

                Requests_Redirectable	GET
                Requests_Redirectable	HEAD
                Requests_Redirectable	POST
                
                Agent           "MonM/1.0"
                Max_Redirect    10
                Keep_Alive      1
                Env_Proxy       1
                Timeout         5
            </UA>
            
            # Attributes
            #Set foo 1
            #Set bar 2
            #Set baz 3
            
        </HTTP>
    </Agent>
    
    <Server>
        DBFile      "/var/tmp/alertgrid.db"

    </Server>

    <Count "foo">
        #Enable     no
        Enable      yes

        #Type       dbi
        #Type       oracle
        #Type       http
        #Type       command
        Type        command
        
        #Command    "alertgrid_snmp -c mydesktop get SNMPv2-MIB::sysName.0"
        #Command    "alertgrid_snmp -s mydesktop -c mydesktop resources"
        Command     "alertgrid_snmp -c mydesktop get SNMPv2-MIB::sysName.0"
    </Count>

    <Count "bar">
        Enable      yes
        
        Type        command
        Command     "cat data/2.xml"
    </Count>

    <Count "baz">
        Enable      yes
        
        Type        command
        Command     "cat data/3.xml"
    </Count>

    <Count "qux">
        Enabled     no
    </Count>

    <Count "nginx_test">
        Enable     yes

        Type command
        command "alertgrid_nginx -q http://nginx.myhost.com/server-status"
    </Count>

</AlertGrid>

-----END FILE-----

-----BEGIN FILE-----
Name: alertgrid.conf.sample
File: conf.d/alertgrid.conf.sample
Mode: 644
Type: Windows

<AlertGrid>
    # Имя. Нужно при работе с виртуальными хостами, чаще всего используется доменное имя
    # сервера или имя хоста
    AlertGridName   localhost
    
    # Настройки активного агента
    <Agent>
        # IP клиента для локального обращения к серверу. Чаще всего используется 127.0.0.1
        IP              127.0.0.1
    
        # Тип общения с сервером, принимающим запросы от клиента. По умолчанию http
        #TransferType    local
        #TransferType    http
        
        # HTTP connect
        <HTTP>
            URI     "http://USER:PASSWORD@host.example.com:8082/alertgrid.cgi?foo=bar"
        
            #Method  GET
            Method  POST

            # Логин и пароль можно задавать используя эти параметры или использовать URI, см. выше
            #Login          USER
            #Password       PASSWORD
            
            # Нужно ли отправлять значение конфигурационного параметра AlertGrid/Server/DBFile
            # на сервер при работе с ним. По умолчанию - выключено. Если вы используете агент и
            # сервер на одном и том же оборудовании то следует включить данную опцию
            #SendDBFile      yes
            
            # Опциональная поддержка работы с Cookies
            CookieEnable    no
            <Cookie>
                Autosave    1
                #File       data/test.cj
            </Cookie>
            
            # Опции агента HTTP. См. модуль libwww-perl
            <UA>
                <Header>
                    #Accept-Language    ru
                    Cache-Control       no-cache
                </Header>
                <SSL_OPTS>
                    verify_hostname		0
                </SSL_OPTS>
                
                Protocols_Allowed	http
                # Required Crypt::SSLeay
                Protocols_Allowed	https

                Requests_Redirectable	GET
                Requests_Redirectable	HEAD
                Requests_Redirectable	POST
                
                Agent           "MonM/1.0"
                Max_Redirect    10
                Keep_Alive      1
                Env_Proxy       1
                Timeout         5
            </UA>
            
            # Attributes
            #Set foo 1
            #Set bar 2
            #Set baz 3
            
        </HTTP>
    </Agent>
    
    # Настройки локального пассивного сервера
    <Server>
        # Путь до файла базы данных alertgrid
        DBFile      "/var/tmp/alertgrid.db"

    </Server>

    # Счетчики AlertGrid
    <Count "foo">
        # Включен или выключен счетчик. По умолчанию - выключен!
        #Enable    no
        Enable     yes

        # Тип способа получения результата.
        #Type        dbi
        #Type        oracle
        #Type        http
        #Type        command
        Type        command
        
        #Command     "alertgrid_snmp -c mydesktop get SNMPv2-MIB::sysName.0"
        #Command     "alertgrid_snmp -s mydesktop -c mydesktop resources"
        Command      "alertgrid_snmp -c mydesktop get SNMPv2-MIB::sysName.0"
    </Count>

    <Count "bar">
        Enable     yes
        
        Type        command
        Command     "cat data/2.xml"
    </Count>

    <Count "baz">
        Enable     yes
        
        Type        command
        Command     "cat data/3.xml"
    </Count>
    
    <Count "qux">
        Enabled     no
    </Count>

    <Count "nginx_test">
        Enable     yes

        Type command
        command "alertgrid_nginx -q http://nginx.myhost.com/server-status"
    </Count>

</AlertGrid>

-----END FILE-----

-----BEGIN FILE-----
Name: rrd.conf.sample
File: conf.d/rrd.conf.sample
Mode: 644

<RRD>
    OutputDirectory	"/var/www/rrd"
    ImageMask		"[TYPE].[KEY].[GTYPE].[EXT]"
    IndexFile     	"index.html"
    #IndexTemplateFile	"/root/index.tpl"
    #IndexTemplateURI	"http://USER:PASSWORD@host.example.com:8080/index.htm"
    
    <Graph "rl0">
        Enable yes
        Type traffic
        File        "/root/traffic.rl0.rrd"
        SRCinput    127.0.0.1::test::rl0::traffic::1::In
        SRCoutput   127.0.0.1::test::rl0::traffic::1::Out
    </Graph>
    
    <Graph "rl1">
        Enable yes
        Type traffic
        File        "/root/traffic.rl1.rrd"
        SRCinput    127.0.0.1::test::rl1::traffic::2::In
        SRCoutput   127.0.0.1::test::rl1::traffic::2::Out
    </Graph>

    <Graph "myhost">
        Enable yes
        Type resources
        File    "/root/resources.bar.rrd"
        SRCCPU  127.0.0.1::test::myhost::resources::cpu::UsedPercent
        SRCHDD  127.0.0.1::test::myhost::resources::hdd::UsedPercent
        SRCMEM  127.0.0.1::test::myhost::resources::mem::UsedPercent
        SRCSWP  127.0.0.1::test::myhost::resources::swp::UsedPercent
    </Graph>
    
    <Graph "baz">
        Enable no
    </Graph>
    
    <Graph "single">
        Enable yes
        Type single
        File "/root/single.rrd"
        SRCUSR1	127.0.0.1::test::nginx_cc::nginx::stub::requests
    </Graph>

    <Graph "double">
        Enable yes
        Type double
        File "/root/double.rrd"
        SRCUSR1	127.0.0.1::test::nginx_test::nginx::stub::active
        SRCUSR2	127.0.0.1::test::nginx_test::nginx::stub::waiting
    </Graph>

    <Graph "triple">
        Enable yes
        Type triple
        File "/root/triple.rrd"
        SRCUSR1	127.0.0.1::test::nginx_test::nginx::stub::active
        SRCUSR2	127.0.0.1::test::nginx_test::nginx::stub::writing
        SRCUSR3	127.0.0.1::test::nginx_test::nginx::stub::waiting
    </Graph>
    
    <Graph "quadruple">
        Enable yes
        Type quadruple
        File "/root/quadruple.rrd"
        SRCUSR1	127.0.0.1::test::nginx_test::nginx::stub::active
        SRCUSR2	127.0.0.1::test::nginx_test::nginx::stub::writing
        SRCUSR3	127.0.0.1::test::nginx_test::nginx::stub::waiting
        SRCUSR4	127.0.0.1::test::nginx_test::nginx::test
    </Graph>

</RRD>

-----END FILE-----