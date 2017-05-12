#!perl -w
#
# DBIx::Web - Active Web Database Layer
#
# makarow at mail.com, started 2003-09-16
#
# Future ToDo:
# - !!! ??? *** review, code review
# - record references finder via 'wikn://', 'key://', bracket notation
# - root hierarchical record functionality: -ridRoot
# - calendar views: type and start/end time; start sub{}, entry sub{}, periodical rec.
# - mail-in interface - records and message browser source
# - logfile reading interface - message browser source
# - acknowledgements feature - message browser implementation
# - replication feature - distributing data
# - 'recRead' alike calls may return an objects, knows metadata
# - remake in three tiers: database with triggers, web interface, communicator
#
# Problems - Think:
# - strDiff() breaks hyperlinks
# - table operation trigger instead of -cgiRun0A: should be included within each trigger and duplicated within actions and user interface
#	# -unflt/uglist, -ugflt/uglist/ugroups, -usernt/user/uglist, -userln/user/uglist, -udisp/udisp, -ugadd/ugroups/uglist
#	# ui: -unflt, -udisp
#	# pi: -ugflt, -usernt, -userln, -ugadd
#	# pc: uglist, user, ugroups, udisp
# - store for users preferences, homepages, notes, etc.
#
# Limitation Issues:
# - PerlEx/IIS Source='Application Error', EventID=1000, faulting application:
#	w3wp.exe 6.0.3790.1830; unknown 0.0.0.0; address 0x01805f98.
#	w3wp.exe 6.0.3790.1830; w3cache.dll 6.0.3790.1830; address 0x0000342a.
#	w3wp.exe 6.0.3790.3959; w3cache.dll 6.0.3790.3959; address 0x0000341a.
#	W3SVC. Warning. 1009. A process serving application pool 'IIS5AppPool' terminated unexpectedly. The process id was '6280'. The process exit code was '0xc0000005'.
#	? may occur stopping www serice with DBIx::Web, CGI::Bus, printenv.cgi, reload.cgi
#	? this may be a PerlEx bug or bug in my PerlEx installation
# - html page scrolling with menu bar
#	# no simple means
# - innice htmlML() selection: _frmName.value=_form.value ? _form.value : '';
#	# ms-help://MS.MSDNQTR.2005JAN.1033/DHTML/workshop/samples/author/dhtml/refs/oncontextmenu.htm
# - dbmSeek() -key=>{[{}]} syntax of cgiForm(recQBF)/cgiQKey
#	# dbm not used at all, it seems
#
# ToDo:
# CMDB / Service Desk:
# - hdesk: association records, invisible when not needed?
# - cmdb/hdesk: status classification graphs: object, application, location, personal
#
# Done:
#

package DBIx::Web;
require 5.000;
use strict;
use UNIVERSAL;
use POSIX;
use Fcntl qw(:DEFAULT :flock :seek :mode);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD $SELF $CACHE $LNG $IMG);

	$VERSION= '0.80';
	$SELF   =undef;				# current object pointer, use 'local $SELF'
	$CACHE	={};				# cache for pointers to subobjects
	*isa    = \&UNIVERSAL::isa; isa('','');	# isa function

my	$RISM0  ='/';		# record identification separation mark 0
my	$RISM1	='//';		# record identification table/id seperator 
				# (-idsplit; consider -recInsID, -rfdName)
my	$RISM2  ='.rfd';	# record identification end   special mark 
my	$NLEN	=14;		# length to pad left numbers in indexes
my	$LIMRS	=512;		# limit of result set
my	$LIMLB	=8 *$LIMRS;	# limit of result set for listboxes
my	$KSORD	='-aall';	# default key sequental order
my	$HS	=';';		# hyperlink parameters separation style '&'
my	$TW32	=($^O eq 'MSWin32') && (*Win32::GetTickCount{CODE}) && eval{Win32::GetTickCount()};

if ($ENV{MOD_PERL_API_VERSION}
&& ($ENV{MOD_PERL_API_VERSION} >=2)) {
	# eval('use Apache2; use Apache2::compat;')
	# eval('use Apache2; use Apache2::Const; use Apache2::ServerUtil;');
}
elsif ($ENV{MOD_PERL}) {
	eval('use Apache qw(exit)')
}

$LNG ={				# Language constants
''	=>undef			# see also '-tn' definitions; htmlSubmitSpl()
,-die	=>sub{CORE::die(@_)}
,-warn	=>sub{CORE::warn(@_)}
,''	=>{''		=>['',		'']
	,-lang		=>['en',	'']
	,-charset	=>['windows-1252','']

	,-style		=>['Style',	'HTML/XML style decoration URL']
	,'-frame=set'	=>['Frameset',	'Frameset form']
	,-affected	=>['affected',	'rows affected']
	,-fetched	=>['fetched',	'rows fetched']

	,-key		=>['Key',	'Key of the record']
	,-wkey		=>['Lock key',	'Key to lock update of the record']
	,-wikn		=>['Name',	'May contain name of the record']
	,-ridRef	=>['References','References to another records']
	,-rvcActPtr	=>['Versioning','When record is been saving, its old version record is to be created pointing to it']
	,-rvcChgState	=>['Changing',	'Record is under change without versioning, files may be attached']
	,-rvcCkoState	=>['Check out',	'Record is checked out, without versioning, files may be attached']
	,-rvcDelState	=>['Deleted',	'Record is deleted logically']
	,-racWriter	=>['Writers',	'Writers of the record']
	,-racReader	=>['Readers',	'Readers of the reord']
	,-racActor	=>['Actors',	'Actors of the record']
	,-racManager	=>['Managers',	'Managers of the record']
	,-racPrincipal	=>['Principals','Principals of the record']
	,-racUser	=>['Users',	'Users of the record']

	,'Error'	=>['Error',	'Error']
	,'rfaUplEmpty'	=>['empty',	'Empty filehandle']
	,'recUpdAclStp'	=>['',		'Record updation prohibited to you']
	,'recUpdVerStp'	=>['',		'Editing record\'s version prohibited']
	,'recDelAclStp'	=>['',		'Record deletion prohibited to you']
	,'recReadAclStp'=>['',		'Record reading prohibited to you']
	,'fldReqStp'	=>['required',	'value required']
	,'fldChkStp'	=>['constraint','constraint violated']

	,'home'		=>['Home',	'Home screen']
	,'schpane'	=>['Navigation','Navigation/Search pane']
	,'back'		=>['<',		'Back screen']
	,'login'	=>['Login',	'Login as personated user']
	,'frmCall'	=>['Go',	'Goto/execute choise']
	,'frmCallOpn'	=>['Open']
	,'frmCallNew'	=>['Create for','Create new record to insert into']
	,'frmHelp'	=>['Help',	'Help screen']
	,'frmErr'	=>['Error',	'Error screen']
	,'frmName'	=>['Form',	'Form choice']
	,'frmLso'	=>['Selection',	"Records selections, may overlap other query conditions specified, may be switched off by '--x' choices"]
	,'frmLsoff'	=>['------------x', 'Switch off selections below']
	,'frmLsc'	=>['Ordering',	'Records ordering, may overlap other query conditions spacified']
	,'frmName1'	=>['Create',	'Create new record with form choosen to insert into database']
	,'recNew'	=>['Create',	'Create new record to insert into database']
	,'recRead'	=>['Read',	'Read record from the database; escape edit mode discarding changes']
	,'recEdit'	=>['Edit',	'Edit this record to update in the database']
	,'recPrint'	=>['Print',	'Printable form']
	,'recXML'	=>['XML',	'XML form']
	,'recHist'	=>['History',	'History of changes form']
	,'recIns'	=>['Insert',	'Insert this data into database as a new record']
	,'recUpd'	=>['Save',	'Update this record or save data into database']
	,'recDel'	=>['Delete',	'Delete this record in the database']
	,'recForm'	=>['Form',	'Recheck this data on server']
	,'recList'	=>['List',	'List records, execute query']
	,'recQBF'	=>['Query',	'Specify records to be listed']
	,'recQBFReset'	=>['Reset',	'Reset query conditions to default']

	,'-query'	=>['Query',	'Data query specification']
	,'-qkeyord'	=>['SEEK',	'Key seek relation']
	,'-qjoin'	=>['JOIN',	'FROM database query clause addition to use for WHERE']
	,'-qwhere'	=>['WHERE',	'WHERE database query clause']
	,'-qwheredbm'	=>['Perl',	"{fieldname} (eq|[gt][lt]) 'value' and|or {fieldname} <>==value..."]
	,'-qwheredbi'	=>['SQL',	"fieldname <>= 'value' AND|OR...; #ftext('string'), #urole('role'), #urole('role','name')"
			 ,[["#ftext('string')","full text search substitution, alike FULL TEXT"]
			  ,["#urole(role)",	"user role, alike UROLE: author, authors, actor, actors, manager, managers, principal, principals, user, users"]
			  ,["#urole(role, user)", "user role and name, alike UROLE and UNAME"]
			  ,['See also', "SQL query syntax"]
				]]
	,'-qurole'	=>['UROLE',	'Role of User']
	,'-quname'	=>['UNAME',	'Name of User']
	,'-qftext'	=>['FULL TEXT',	'Full-text search string']
	,'-qversion'	=>['VERSIONS',	'Including old versions of records']
	,'-qorder'	=>['ORDER BY',	'ORDER BY database query clause']
	,'-qlimit'	=>['LIMIT',	'LIMIT database query clause']
	,'-qdisplay'	=>['DISPLAY',	'Columns to display in list']
	,'-qurl'	=>['URL',	'Query URL constructed, press \'Form\' to refresh']

	,'rfafolder'	=>['Files',	'File Attachments']
	,'rfauplfld'	=>['Upload',	'File to upload']
	,'rfaupdate'	=>['+/-',	'Upload file, close or delete attachments selected']
	,'rfaopen'	=>['...',	'Opened file attachments to be closed']
	,'rfaclose'	=>['Close']
	,'rfadelm'	=>['Delete',	'Mark file attachments to be deleted']

	,'ddlbopen'	=>['...',	'Open values']
	,'ddlbopenl'	=>['>',		'Open values recursion']
	,'ddlbsubmit'	=>['Set',	'Assign value selected']
	,'ddlbreset'	=>['c',		'Clear value']
	,'ddlbclose'	=>['x',		'Close values']
	,'ddlbfind'	=>['..',	'Find value in the list']

	,'tvmVersions'	=>['All Versions',	'All records and their versions']
	,'tvmHistory'	=>['All News',		'All news, updates, deletions']
	,'tvmReferences'=>['All References',	'All references to records']
	,'tvdIndex'	=>['All Contents',	'Table of contents']
	,'tvdFTQuery'	=>['All Files Find',	'Full-text query on files']
	,'-qftwhere'	=>['FTQuery',	'Full-text query condition']
	,'-qftord'	=>['FTOrder',	'Full-text search result set sort order']
	,'-qftlimit'	=>['FTLimit',	'Full-text search result set limit']

	,'table'	=>['Table',	'Table or recfile name']
	,'id'		=>['ID',	'Record ID', 'id']
	,'ir'		=>['IR',	"Refered ID"]
	,'idrm'		=>['AboveID',	"Record, above this, 'id' or 'table'//'id'"]
	,'idpr'		=>['PrevID',	"Record, previous to this, 'id' or 'table'//'id'"]
		,'hierarchy'	=>['hierarchy']
	,'cuser'	=>['Ins by',	'User, record inserted by']
	,'creator'	=>['Ins by',	'User, record inserted by']
	,'ctime'	=>['Ins time',	'Date and time, record inserted when']
	,'uuser'	=>['Upd by',	'User, record updated by']
	,'updater'	=>['Upd by',	'User, record updated by']
	,'utime'	=>['Upd time',	'Date and time, record updated when']
	,'idnv'		=>['Ver of',	'Actual record ID, points to the actual and fresh version']
	,'vtime'	=>['Ver time',	'Date and time, version recorded when']
	,'status'	=>['State',	'State of the record']
		,'todo'		=>['todo']
		,'done'		=>['done']
		,'deleted'	=>['deleted']
		,'edit'		=>['edit']
		,'chk-out'	=>['chk-out']
		,'all'		=>['all']
	,'auser'	=>['Actor',	'Actor of the record, user name']
	,'actor'	=>['Actor',	'Actor of the record, user name']
	,'arole'	=>['Actors',	'Role of the actor of the record or additional actor user']
	,'actors'	=>['Actors',	'Actors of the record, users and groups, comma delimited']
	,'puser'	=>['Principal',	'Principal of the record, user name']
	,'principal'	=>['Principal',	'Principal of the record, user name']
	,'prole'	=>['Principals','Role of the principal of the record or additional principal user']
	,'principals'	=>['Principals','Principals of the record, users and groups, comma delimited']
	,'manager'	=>['Manager',	'Manager of the record, user name']
	,'muser'	=>['Manager',	'Manager of the record, user name']
	,'mrole'	=>['Managers',	'Role of the manager of the record, group or user']
	,'managers'	=>['Managers',	'Managers of the record, users and groups, comma delimited']
	,'owner'	=>['Owner',	'Owner of the record, user name']
	,'orole'	=>['Owners',	'Role of the owner of the record or additional owner']
	,'owners'	=>['Owners',	'Owners of the record, users and groups, comma delimited']
	,'user'		=>['User',	'User of the record, user name']
	,'users'	=>['Users',	'Users of the record, users and groups, comma delimited']
	,'author'	=>['Author',	'Author of the record, user name']
	,'authors'	=>['Authors',	'Authors of the record, comma delimited']
	,'rrole'	=>['Readers',	'Readers of the record, group or role']
	,'readers'	=>['Readers',	'Readers of the record, users and groups, comma delimited']
	,'mailto'	=>['MailTo',	'Receipients of e-mail of the record status current, comma delimited']
	,'record'	=>['Record',	'Class/type of the record described by']
	,'object'	=>['Object',	'Object of the record described by']
	,'project'	=>['Project',	'Project, related to the record']
	,'cost'		=>['Cost',	'Cost of the record described by']
	,'doctype'	=>['Doctype',	'Type of the document contained']
	,'subject'	=>['Subject',	'Subject, Title, Brief description']
	,'comment'	=>['Comment',	"Comment text or HTML. Special URL protocols: 'urlh://' (this host), 'urlr://' (this application), 'urlf://' (file attachments), 'key://' (record id or table${RISM1}id), 'wikn://' (wikiname). Bracket URL notations: [[xxx://...]], [[xxx://...][label]], [[xxx://...|label]]. Starting text with <where>condition</where> may be used for embedded query"]
		,'-htmlopt'	=>['Optional HTML', "Field may contain HTML, start text with HTML tag for this case, otherwise plain text will be supposed."]
		,'-hrefs'	=>['Hyperlinks','Hyperlinks in the text will be recognized and highlighted:'
				,[['urlh://',"This host URL"]
				 ,['urlr://',"This script URL, use urlr://?param=value;..."]
				 ,['urlf://',"Files attached to the record"]
				 ,['key://id','Open the record with ID given in this table']
				 ,['key://table//id', 'Record in the particular table']
				 ,['wikn://name', "Named record"]
				 ,['[[xxx://...]]', 'Without escaping key:// or wikn:// (not in HTML)']
				 ,['[[...|label]]', 'Text to highlight (not in HTML)']
				 ,['[[...][label]]', 'Another syntax (not in HTML)']
					]]
	,'cargo'	=>['Cargo',	'Additional data']
	}
,'ru'	=>{''		=>['',		'']
	,-lang		=>['ru-RU',	'']
	,-charset	=>['windows-1251','']

	,-style		=>['Стиль',	'Гиперссылка стилевой декорации HTML/XML']
	,'-frame=set'	=>['Кадрирование','Форма в виде набора фреймов']
	,-affected	=>['затронуто',	'строк затронуто']
	,-fetched	=>['выбрано',	'строк выбрано']
	,-key		=>['Ключ',	'Ключ записи']
	,-wkey		=>['Ключ блк.',	'Ключ блокировки обновления записи']
	,-wikn		=>['Имя',	'Может содержать имя записи']
	,-ridRef	=>['Ссылки',	'Ссылки на другие записи']
	,-rvcActPtr	=>['Версионирование','При сохранении записи, создается запись ее прежней версии, указывающая на актуальную свежую запись']
	,-rvcChgState	=>['Изменение',	'Изменение записи без версионирования, возможно присоединение файлов']
	,-rvcCkoState	=>['Извлечено',	'Запись извлечена для изменения, без версионирования, возможно присоединение файлов']
	,-rvcDelState	=>['Удалено',	'Запись удалена логически']
	,-racWriter	=>['Писатели',	'Могут изменять запись']
	,-racReader	=>['Читатели',	'Могут читать запись']
	,-racActor	=>['Исполнители','Исполнители записи']
	,-racManager	=>['Менеджеры',	'Менеджеры записи']
	,-racPrincipal	=>['Инициаторы','Инициаторы записи']
	,-racUser	=>['Пользователи','Пользователи записи']

	,'Error'	=>['Ошибка',	'Ошибка']
	,'rfaUplEmpty'	=>['пусто',	'Пустой манипулятор файла']
	,'recUpdAclStp'	=>['',		'Изменение записи не разрешено полномочиями доступа пользователя']
	,'recUpdVerStp'	=>['',		'Изменение прежней версии записи запрещено']
	,'recDelAclStp'	=>['',		'Удаление записи не разрешено полномочиями доступа пользователя']
	,'recReadAclStp'=>['',		'Чтение записи не разрешено полномочиями доступа пользователя']
	,'fldReqStp'	=>['требуется',	'значение требуется']
	,'fldChkStp'	=>['ограничение','ограничение нарушено']

	,'home'		=>['Начало',	'Начальная страница']
	,'schpane'	=>['Навигатор',	'Панель навигации/поиска']
	,'back'		=>['<',		'Предыдущая страница']
	,'login'	=>['Войти',	'Открыть персонифицированный сеанс']
	,'frmCall'	=>['Вып',	'Выполнить переход, действие, поиск']
	,'frmCallOpn'	=>['Открыть']
	,'frmCallNew'	=>['Создать для', 'Создать новую запись, чтобы затем вставить ее в']
	,'frmHelp'	=>['Справка',	'Справочная страница']
	,'frmErr'	=>['Ошибка',	'Сообщение об ошибке']
	,'frmName'	=>['Форма',	'Выбор формы']
	,'frmLso'	=>['Выборка',	"Выборки записей, могут перекрывать другие заданные условия запроса, отключаются выбором '--x'"]
	,'frmLsoff'	=>['------------x', 'Отключить нижеуказанный отбор']
	,'frmLsc'	=>['Упорядочение','Упорядочение записей, может перекрывать другие заданные условия запроса']
	,'frmName1'	=>['Создать',	'Создать новую запись выбранной формы, чтобы затем вставить ее в базу данных']
	,'recNew'	=>['Создать',	'Создать новую запись, чтобы затем вставить ее в базу данных']
	,'recRead'	=>['Читать',	'(Пере)читать запись из базы данных; перейти от редактирования записи к просмотру с потерей результатов редактирования']
	,'recEdit'	=>['Править',	'Начать редактирование (изменение) записи']
	,'recPrint'	=>['Печать',	'Представление для печатания']
	,'recXML'	=>['XML',	'Представление XML']
	,'recHist'	=>['История',	'Представление истории изменений']
	,'recIns'	=>['Вставить',	'Добавить результаты редактирования в базу данных как новую запись']
	,'recUpd'	=>['Сохранить',	'Сохранить результаты редактирования (изменения) записи в базе данных']
	,'recDel'	=>['Удалить',	'Удалить эту запись из базы данных']
	,'recForm'	=>['Форм',	'Перезагрузить форму с сервера, перевычислить данные']
	,'recList'	=>['Выбрать',	'(Пере)читать представление, выбрать записи согласно условию выборки (поиска)']
	,'recQBF'	=>['Запрос',	'Задание условия выборки (поиска) записей']
	,'recQBFReset'	=>['Сброс',	'Сброс условия выборки данных в умолчания']

	,'-query'	=>['Запрос',	'Спецификация выборки записей']
	,'-qkeyord'	=>['SEEK',	'Направление поиска по ключу']
	,'-qjoin'	=>['JOIN',	'Дополнение к конструкции запроса FROM, для WHERE']
	,'-qwhere'	=>['WHERE',	'Конструкция запроса WHERE']
	,'-qurole'	=>['UROLE',	'Роль пользователя']
	,'-quname'	=>['UNAME',	'Имя пользователя']
	,'-qftext'	=>['FULL TEXT',	'Строка полнотекстового поиска']
	,'-qversion'	=>['VERSIONS',	'Включение прежних версий записей']
	,'-qorder'	=>['ORDER BY',	'Конструкция запроса ORDER BY']
	,'-qlimit'	=>['LIMIT',	'Конструкция запроса LIMIT']
	,'-qdisplay'	=>['DISPLAY',	'Список столбцов представления']
	,'-qurl'	=>['URL',	'Итоговый URL запроса, обновляется нажатием \'Форм\'']

	,'rfafolder'	=>['Файлы',	'Присоединенные файлы']
	,'rfauplfld'	=>['Загрузить',	'Файл для загрузки']
	,'rfaupdate'	=>['+/-',	'Загрузить файл, закрыть или удалить выбранные присоединения файлов']
	,'rfaopen'	=>['...',	'Открытые присоединенные файлы, которые можно закрыть']
	,'rfaclose'	=>['Закрыть']
	,'rfadelm'	=>['Удалить',	'Пометить присоединения файлов для удаления']

	,'ddlbopen'	=>['...',	'Открыть список значений']
	,'ddlbopenl'	=>['>',		'Открыть рекурсию значений']
	,'ddlbsubmit'	=>['Присв.',	'Присвоить выбранное значение']
	,'ddlbreset'	=>['c',		'Сбросить значение']
	,'ddlbclose'	=>['x',		'Закрыть список значений']
	,'ddlbfind'	=>['..',	'Найти значение в списке']

	,'tvmVersions'	=>['Все Версии',	'Все записи и их версии']
	,'tvmHistory'	=>['Все Новости',	'Все новые, измененные, удаленные записи']
	,'tvmReferences'=>['Все Ссылки',	'Все ссылки на записи']
	,'tvdIndex'	=>['Все Содержание',	'Оглавление']
	,'tvdFTQuery'	=>['Поиск файлов',	'Полнотекстовый поиск в файлах']
	,'-qftwhere'	=>['FTQuery',		'Условие полнотекстового поиска']
	,'-qftord'	=>['FTOrder',		'Сортировка результатов полнотекстового поиска']
	,'-qftlimit'	=>['FTLimit',		'Ограничение численности результатов полнотекстового поиска']

	,'table'	=>['Таблица',	'Имя таблицы или файла записей']
	,'id'		=>['ID',	'Идентификатор записи', 'id']
	,'ir'		=>['Ссылка',	"Ссылка на идентификатор записи"]
	,'idrm'		=>['Главная',	"Идентификатор вышестоящей записи, 'id' либо 'table'//'id'"]
	,'idpr'		=>['Предш',	"Идентификатор предшествующей записи, 'id' либо 'table'//'id'"]
		,'hierarchy'	=>['иерархия']
	,'cuser'	=>['Создал',	'Кем была создана запись']
	,'creator'	=>['Создал',	'Кем была создана запись']
	,'ctime'	=>['Созд-е',	'Когда запись была создана']
	,'uuser'	=>['Изменил',	'Кем была последний раз изменена запись']
	,'updater'	=>['Изменил',	'Кем была последний раз изменена запись']
	,'utime'	=>['Измен-е',	'Когда последний раз была изменена запись']
	,'idnv'		=>['Бывш',	'Идентификатор актуальной записи, указывает на актуальную (последнюю) версию']
	,'vtime'	=>['Записано',	'Когда была записана эта версия']
	,'status'	=>['Статус',	'Статус записи, состояние или результат деятельности']
		,'todo'		=>['сделать']
		,'done'		=>['завершено']
		,'deleted'	=>['удалено']
		,'edit'		=>['редакт-е']
		,'chk-out'	=>['chk-out']
		,'all'		=>['все']
	,'auser'	=>['Исп-ль',	'Исполнитель записи, пользователь']
	,'actor'	=>['Исп-ль',	'Исполнитель записи, пользователь']
	,'arole'	=>['Исп-ли',	'Роль или группа исполнителя записи, либо добавочный исполнитель']
	,'actors'	=>['Исп-ли',	'Исполнители записи, пользователи и группы, через запятую']
	,'puser'	=>['Иниц-р',	'Инициатор записи, пользователь']
	,'principal'	=>['Иниц-р',	'Инициатор записи, пользователь']
	,'prole'	=>['Иниц-ры',	'Роль или группа инициатора записи, либо добавочный инициатор']
	,'principals'	=>['Иниц-ры',	'Инициаторы записи, пользователи и группы, через запятую']
	,'manager'	=>['Менеджер',	'Управляющий записью, пользователь']
	,'muser'	=>['Менеджер',	'Управляющий записью, пользователь']
	,'mrole'	=>['Менеджеры',	'Роль управляющего записью, группа или пользователь']
	,'managers'	=>['Менеджеры',	'Управляющие записью, пользователи и группы, через запятую']
	,'owner'	=>['Владелец',	'Владелец записи, пользователь']
	,'orole'	=>['Владельцы',	'Роль или группа владельца записи, либо добавочный владелец']
	,'owners'	=>['Владельцы',	'Владельцы записи, пользователи и группы, через запятую']
	,'user'		=>['Польз',	'Пользователь записи']
	,'users'	=>['Польз-ли',	'Пользователи записи, пользователи и группы, через запятую']
	,'author'	=>['Автор',	'Автор записи, пользователь']
	,'authors'	=>['Авторы',	'Авторы записи, пользователи и группы, через запятую']
	,'rrole'	=>['Читатели',	'Роль или группа читателей записи']
	,'readers'	=>['Читатели',	'Читатели записи, пользователи и группы, через запятую']
	,'mailto'	=>['эПочтой',	'Получатели сообщений электронной почты об этой записи, через запятую']
	,'record'	=>['Запись',	'Класс или тип записей']
	,'object'	=>['Объект',	'Объект или ключевое слово, к которому относится запись']
	,'project'	=>['Проект',	'Направление, объект, процесс, статья расходов, к которой относится запись']
	,'cost'		=>['Затраты',	'Затраты на выполнение описываемого записью']
	,'doctype'	=>['Тип док.',	'Тип документа, содержащегося в записи']
	,'subject'	=>['Тема',	'Тема или заглавие записи']
	,'comment'	=>['Коммент',	"Текст или HTML комментария. Гиперссылки могут быть начаты с 'urlh://' (компьютер), 'urlr://' (это приложение), 'urlf://' (присоединенные файлы), 'key://' (ключ записи или таблица${RISM1}ключ), 'wikn://' (имя записи); могут быть в скобочной записи [[xxx://...]], [[xxx://...][label]], [[xxx://...|label]]. Начало текста <where>условие</where> может использоваться для встроенной выборки записей"]
	,'cargo'	=>['Карго',	'Дополнительные данные']
	}
,'itf8enc_ru' => sub{my $i; $_[0] =~s/([^\x00-\x7f])/$i=ord($1); ($i >=192) ||($i ==168) ||($i ==184) ? (($i ==184) || ($i >=240) ? "\xD1" : "\xD0") .chr(($i ==168) ||($i ==184) ? $i -39 : $i >=240 ? $i -112 : $i -48) : " "/ge}
,'itf8dec_ru' => sub{my ($i,$j); $_[0] =~s/(\xD0[\x90-\xBF]|\xD1[\x80-\x8F]|\xD1\x91|\xD0\x81)/$i=substr($1,0,1); $j=ord(substr($1,1,1)); $i eq "\xD0" ? chr($j ==129 ? 168 : ($j +48)) : chr($j ==145 ? 184 : ($j +112))/ge}
};

$IMG={				# Images (from Apache)
	 'home'		=>'portal.gif'
	,'schpane'	=>'folder.gif'
	,'schframe'	=>'folder.gif'
	,'back'		=>'back.gif'
	,'login'	=>'small/key.gif'
	,'frmCall'	=>'hand.up.gif'
	,'frmHelp'	=>'unknown.gif'
	,'recNew'	=>'generic.gif'
	,'recRead'	=>'up.gif'
	,'recEdit'	=>'quill.gif'
	,'recPrint'	=>'p.gif'
	,'recXML'	=>'script.gif'
	,'recHist'	=>'text.gif'
	,'recIns'	=>'burst.gif'
	,'recUpd'	=>'down.gif'
	,'recDel'	=>'broken.gif'
	,'recForm'	=>'forward.gif'
	,'recList'	=>'text.gif'
	,'recQBF'	=>'index.gif'
	,'recQBFReset'	=>'pie0.gif'
	,'rfafolder'	=>'folder.open.gif'
};

1;



#######################


sub new {
 my $c=shift;
 my $s;
 if (ref($_[0]) eq 'DBIx::Web') {
	$s =shift;
	$s->DESTROY();
 }
 else {
	shift	if scalar(@_) && !defined($_[0])
		&& (scalar(@_) > int(scalar(@_)/2)*2);
	$s ={};
	bless $s, $c;
 }
 $s =$s->initialize(@_);
}



sub initialize {
 my $s   =shift;
 my %opt =@_;
 $CACHE->{$s} ={};
 $CACHE->{-new} =$CACHE->{-new} +1 if defined($CACHE->{-new});
 $s->set(-env=>$opt{-env})	if $opt{-env};

 %$s =(
 #  -env	=>undef		# Environment variables setup
    -title	=>''		# Application's title
 # ,-locale	=>''		# Application's locale
 # ,-lang	=>undef		# Application's language
 # ,-charset	=>undef		# Application's charset
 # ,-lng	=>''		# User's language
 # ,-lnglbl	=>''		# -lbl key
 # ,-lngcmt	=>''		# -cmt key

   ,-debug      =>0		# Debug Mode
   ,-die        =>$LNG->{-die}	# die  / croak / confess: &{$s->{-die} }('error')
 # ,-diero	=>undef		# die runtime option inside cgiRun()
   ,-warn       =>$LNG->{-warn}	# warn / carp  / cluck  : &{$s->{-warn}}('warning')
   ,-ermu	=>''		# err markip user
   ,-ermd	=>''		# err markup delimiter
 # ,-end0	=>undef		# 'end' before trigger
   ,-endh	=>{}		# 'end' before hash
 # ,-end1	=>undef		# 'end' after  trigger

 # ,-var        =>undef		# Variables {}, see varLoad, varStore
   ,-log        =>1		# Log file switch/handle, see logOpen
   ,-logm	=>100		# Log list max size

   ,-c => {			# Cache for computed values
	# ,-startinit	=>undef # Started by initialize
        # ,-pth_tmp	=>undef	# Temporary files path, see pthForm('tmp')
        # ,-pth_var	=>undef	# Variable  files path, see pthForm('var')
        # ,-pth_log	=>undef	# Log       files path, see pthForm('log')
	# ,-logm	=>[]	# Log list
        # ,-user	=>undef	# User Name
        # ,-unames	=>[]	# User Names
        # ,-ugroups	=>[]	# User Groups
          }

 # ,-path       =>'./dbix-web'	# Path to file store, default below
 # ,-url        =>'/dbix-web'	# URL  to file store, default below
 # ,-urf        =>'file://./dbix-web'# Filesystem URL to file store, default below
                  

   ,-host	=>undef		# Host  Name, default below
 # ,-dbi	=>undef		# DBI object, if used
 # ,-dbiarg	=>undef		# DBI connection arguments string or array
 # ,-dbidsn	=>undef		# DBI connection string from -dbiarg
 # ,-dbiph	=>undef		# DBI placeholders ('?') dialect switch
 # ,-dbiACLike	=>undef		# DBI ACL LIKE options: rlike regexp,...
 # ,-dbiexpl	=>undef		# DBI explain switch: 0/1
 # ,-cgi	=>undef		# CGI object
   ,-serial	=>1		# Serialised: 1 - updates, 2 - updates & reads, 3 - reads
   ,-keyqn	=>1		# query key ''/undef compatibility
 # ,-output	=>undef		# output sub{} instead of 'print'

   ,-table	=>{}		# database files
				# -field=>[name=>{}]
				# -mdefld=>{name=>{}}
				# -key	=>[field]
				# -keycmp=>sub{}	# key compare dbm sub{}
				# -ixcnd=>sub{}||1	# index condition
				# -ixrec=>sub{}		# form index record
				# -optrec		# optional records
				# -dbd =>'dbi'|'dbm'	# database store
				# -recXXX		# trigger or implementation

				# -subst		# substitute another
				# -cgcXXX=>''|sub{}	# cgi call implementation
				# -cgvXXX=>''|sub{}	# cgi call presentation

				# -frmLso		# form query option
				# -query		# query condition hash
				# -qfilter		# filters rows fetched
				# -qhref		# query hyperlink hash or sub{}
				# -qhrcol		# q h left columns
				# -qflghtml		# !empty flag when '!h'
				# -qfetch		# query fetch sub{}
				# -limit		# query limit rows

				# -recRead		# recRead condition hash

 # ,-user	=>undef		# User Name   sub{} or value, default below
   ,-userln	=>1		# User local  short names switch
 # ,-usernt	=>undef		# User syntax alike WinNT
 # ,-udisp	=>undef		# User display group comments '-ug<>dc' or boolean
 # ,-udispq	=>undef		# User display quick always
 # ,-unames	=>[]		# User Names  sub{} or value
 # ,-ugroups	=>[]		# User Groups sub{} or value
 # ,-udflt	=>sub{}		# User Domains	filter
 # ,-unflt	=>sub{}		# User Names	filter
 # ,-ugflt	=>sub{}		# User Groups	filter
 # ,-AuthUserFile		# Apache Users  file, optional
 # ,-AuthGroupFile		# Apache Groups file, optional
 # ,-w32ldap	=>[[win=>ldap]]	# Windows ADSI LDAP users/groups store
 # ,-ldap	=>''||[]||{}	# LDAP constructor arguments, LDAP usage option
 # ,-ldapsrv	=>''||[]||{}	# LDAP constructor arguments
 # ,-ldapbind	=>''||[]||{}	# LDAP bind arguments (version => 3)
 # ,-ldapsearch	=>{}		# LDAP search defaults and basic filter
 # ,-ldapfu	=>''		# LDAP users filter
 # ,-ldapfg	=>''		# LDAP groups filter
   ,-ldapattr	=>['uid','cn']	# LDAP internal and external names
 # ,-fswtr	=>undef		# File Store Writers, defaults in code
 # ,-fsrdr	=>undef		# File Store Readers
   ,-w32IISdpsn	=>($ENV{SERVER_SOFTWARE}||'') =~/IIS/ ? 1 : 0 # MsIIS deimpersonation
 # ,-w32xcacls	=>undef		# Use WinNT 'xcacls' instead of 'cacls'

 # ,&recXXX			# DML command keywords
					# -table -form || record form class
					# -from -join[01]
					# -data
					# -key -where 
					# -urole -uname
					# -ftext -version
					# -filter -limit
					# -order -keyord -group
					# -save -optrec -test -sel
				# DML record attributes
					# -new -file -fupd -editable

				# Record Manipulation Options:
 # ,-dbd	=>undef		# default database engine
   ,-autocommit =>1		# autocommit database mode
 # ,-limit	=>undef||number	# limit of selection
 # ,-affect	=>undef||1	# rows number to affect by DML
 # ,-affected			# rows number affected	by DML
 # ,-fetched			# rows number fetched	by DBL
 # ,-limited			# rows number limited	by DBL
 # ,-index	=>boolean	# include materialized views support
   ,-idsplit	=>1 		# split complex rec ID to table and row ID: 0 || sub{}
   ,-wikn	=>		# wikiname fields possible
		['name','subject']
 # ,-wikq	=>undef		# wikiquery filter sub{} for recWikn()

				# Record Access Control rooles:
   ,-rac	=>1		# switch on
   ,-racAdmWtr	=>'Administrators,root'
   ,-racAdmRdr	=>'Administrators,root'
 # ,-racReader	=>[fieldnames]	# readers fieldnames
 # ,-racWriter	=>[fieldnames]	# writers fieldnames

				# Record Version Control rooles:
 # ,-rvcInsBy	=>'fieldname'	# field for user name	record inserted	by
 # ,-rvcInsWhen	=>'fieldname'	# field for time	record inserted	when
 # ,-rvcUpdBy	=>'fieldname'	# field for user name	record updated	by
 # ,-rvcUpdWhen	=>'fieldname'	# field for time	record updated	when
 # ,-rvcVerWhen	=>'fieldname'	# field for time	version created when
 # ,-rvcActPtr	=>'fieldname'	# field for actual record version pointer
 # ,-rvcChgState=>[fld=>states]	# changeble states of record
 # ,-rvcCkoState=>[fld=>state ]	# check-out state  of record
 # ,-rvcDelState=>[fld=>state ]	# deleted   state  of record

				# Record File Attachments rooles:
   ,-rfa	=>1		# switch on
 # ,-rfdName	=>sub{}		# 'rfdName'  formula for key processing

                                # Record ID References
 # ,-ridRef	=>[]		# reference fields

				# Record Manipulation Triggers:
 # ,-recTrim0A	=>sub{}		# 'recTrim' trigger before	UI action
 # ,-recForm	=>'form'|sub{}	# 'recForm' UI implementation
 # ,-recForm0A	=>sub{}		# 'recForm' trigger before	UI action
 # ,-recForm0C	=>sub{}		# 'recForm' trigger before	command
 # ,-recForm0R	=>sub{}		# 'recForm' trigger before	row
 # ,-recFlim0R	=>sub{}		# 'recForm' limiter before	row
 # ,-recForm1C	=>sub{}		# 'recForm' trigger after	command
 # ,-recForm1A	=>sub{}		# 'recForm' trigger after	UI action
 # ,-recEdt0A	=>sub()		# 'recEdt'  trigger before	UI action
 # ,-recEdt0R	=>sub()		# 'recEdt'  trigger before	row
 # ,-recChg0R	=>sub()		# 'recChg'  trigger before	row
 # ,-recChg0W	=>sub()		# 'recChg'  trigger before	write (and -recInsID)
 # ,-recEdt1A	=>sub()		# 'recEdt'  trigger after	UI action
 # ,-recNew	=>'form'|sub{}	# 'recNew'  UI implementation
 # ,-recNew0C	=>sub{}		# 'recNew'  trigger before	command
 # ,-recNew0R	=>sub{}		# 'recNew'  trigger before	row
 # ,-recNew1C	=>sub{}		# 'recNew'  trigger after	command
 # ,-recIns	=>'form'|sub{}	# 'recIns'  UI implementation
 # ,-recIns0C	=>sub{}		# 'recIns'  trigger before	row command
 # ,-recIns0R	=>sub{}		# 'recIns'  trigger before	row
 # ,-recInsID	=>sub{}		# 'recIns'  trigger for key generation
 # ,-recIns1R	=>sub{}		# 'recIns'  trigger after	row
 # ,-recIns1C	=>sub{}		# 'recIns'  trigger after	row command
 # ,-recUpd	=>'form'|sub{}	# 'recUpd'  UI implementation
 # ,-recUpd0C	=>sub{}		# 'recUpd'  trigger before	command
 # ,-recUpd0R	=>sub{}		# 'recUpd'  trigger before	each row
 # ,-recUpd1C	=>sub{}		# 'recUpd'  trigger after	command
 # ,-recDel	=>'form'|sub{}	# 'recDel'  UI implementation
 # ,-recDel0C	=>sub{}		# 'recDel'  trigger before	command
 # ,-recDel0R	=>sub{}		# 'recDel'  trigger before	each row
 # ,-recDel1C	=>sub{}		# 'recDel'  trigger after	command
 # ,-recSel0C	=>sub{}		# 'recSel'  trigger before	command
 # ,-recRead	=>'form'|sub{}	# 'recRead' UI implementation
 # ,-recRead0C	=>sub{}		# 'recRead' trigger before	row command
 # ,-recRead0R	=>sub{}		# 'recRead' trigger before	row command
 # ,-recRead1R	=>sub{}		# 'recRead' trigger after	row command
 # ,-recRead1C	=>sub{}		# 'recRead' trigger after	row command
 # ,-recList	=>'form'|sub{}	# 'recList' UI implementation

   ,-tn		=>{             # Template naming, see also 'ns' sub
	 ''		=>''
	,-guest		=>'guest'	# guest user name
	,-guests	=>'guests'	# guest user group
	,-users		=>'users'	# authenticated user default group
	,-dbd		=>'dbm'		# defaultest data engine

	,-id		=>'id'		# record identifier
	,-key		=>['id']	# record key
	,-rvcInsBy	=>'cuser'	# user, record inserted by
	,-rvcInsWhen	=>'ctime'	# time, record inserted when
	,-rvcUpdBy	=>'uuser'	# user, record updated  by
	,-rvcUpdWhen	=>'utime'	# time, record updated  when
	,-rvcVerWhen	=>'vtime'	# time, version created when
			# 'auser'	# actor user
			# 'arole'	# actor roles
			# 'puser'	# principal user
			# 'prole'	# principal roles
	,-rvcActPtr	=>'idnv'	# id of new version of record
			# 'idrm'	# id of master record
			# 'idrr'	# id of root reference
			# 'idpr'	# id of previous record in cause chain
			# 'idpt'	# point to record
			# 'idlr'	# location record pointer
	,-rvcState	=>'status'	# state of record
	,-rvcAllState	=>['ok','no','do','progress','delay','chk-out','edit','deleted']
	,-rvcFinState	=>['status'=>'ok','no','deleted']
	,-rvcChgState	=>['status'=>'edit','chk-out']
	,-rvcCkoState	=>['status'=>'chk-out']
	,-rvcDelState	=>['status'=>'deleted']
	,-ridSubject	=>[qw(record object subject)]	# subject fields | sub{}
	,'tvmVersions'	=>'versions'	# versions view name
	,'tvmHistory'	=>'history'	# history view name
	,'tvmReferences'=>'references'	# references view name
	,'tvdIndex'	=>'index'	# index view name
	,'tvdFTQuery'	=>'fulltext'	# full-text view name
   }
				# CGI server user interface
 # ,-httpheader =>{}
 # ,-htmlstart  =>{}
   ,-icons	=>'/icons'	# Icons URL
 # ,-logo	=>''		# Logotype to display
 # ,-search	=>''		# '_search' frame URL
   ,-login	=>'/cgi-bin/ntlm/'# Login URL
 # ,-menuchs	=>[[]]
 # ,-menuchs1	=>[[]]
 # ,-form	=>{}		# user interface forms, see '-table'
 # ,-pcmd	=>{}		# command input parameters
 # ,-pdta	=>{}		# data input
 # ,-pout	=>{}		# parameters output (cursor)
   );

 if (!$opt{-path}
 || ($opt{-path} =~/^(?:DocumentRoot|-DocumentRoot)$/i)) {
	my $pth =$^O eq 'MSWin32' ? scalar(Win32::GetFullPathName($0)) : $0;
	$pth =  $ENV{DOCUMENT_ROOT}
		? $ENV{DOCUMENT_ROOT} .'/'
		: $pth =~/^(.+?[\\\/]wwwroot[\\\/])/i
		? $1
		: $pth =~/^(.+?[\\\/]inetpub[\\\/])/i
		? $1
	 	: $pth =~/^(.+?[\\\/])cgi-bin[\\\/]/i && -d ($1 .'htdocs')
		? $1 .'htdocs/'
		: $pth =~/^(.+?[\\\/]apache[\\\/])/i && -d ($1 .'htdocs')
		? $1 .'htdocs/'
		: $pth =~/^(.+[\\\/])[^\\\/]*$/
		? $1
		: -d '../htdocs'
		? '../htdocs/'
		: -d '../wwwroot'
		? '../wwwroot/'
		: './';
	$opt{-path} =$pth .'dbix-web';
 }
 elsif ($opt{-path} =~/^(?:ServerRoot|-ServerRoot|-path)$/i) {
	my $pth =$^O eq 'MSWin32' ? scalar(Win32::GetFullPathName($0)) : $0;
	$pth =    ($^O eq 'MSWin32') && ($pth =~/^(.+?[\\\/]inetpub[\\\/])/i)
		? $1
		: $ENV{DOCUMENT_ROOT} && ($ENV{DOCUMENT_ROOT} =~/^(.+[\\\/])[^\\\/]*$/)
		? $1
	 	: $pth =~/^(.+?[\\\/])cgi-bin[\\\/]/i && -d ($1 .'htdocs')
		? $1 .'/'
		: $pth =~/^(.+?[\\\/]apache[\\\/])/i && -d ($1 .'htdocs')
		? $1 .'/'
		: $pth =~/^(.+[\\\/])[^\\\/]*$/
		? $1
		: -d '../htdocs'
		? '../'
		: -d '../wwwroot'
		? '../'
		: './';
	$opt{-path} =$pth .'dbix-web';
 }
 $RISM2 ='.rfd'; # for set(-cgibus)

 $s->set(%opt);

 $s->{-url} =cgibus($s) ? '/cgi-bus' : '/dbix-web'
	if !$s->{-url};
 $s->set(-locale=>POSIX::setlocale(&POSIX::LC_CTYPE()))
	if !$s->{-locale};
 $s->set(-die=>($ENV{GATEWAY_INTERFACE}||'') =~/CGI/ ? 'CGI::Carp qw(fatalsToBrowser warningsToBrowser)' : 'Carp')
	if !$opt{-die};
 $s->set(-host=>
	($ENV{COMPUTERNAME}||$ENV{HOSTNAME}||eval('use Sys::Hostname;hostname')||'localhost') 
	=~/^([\d.]+|[\w\d_]+)/ ? $1 : 'unknown'
	)
	if !$s->{-host};
 $s->set(-user=>sub{$ENV{REMOTE_USER}||$ENV{USERNAME}||$_[0]->{-tn}->{-guest}})
	if !$s->{-user};
 $s->set(-recTrim0A=>sub{ # $self, {command}, {data}
		foreach my $k (keys %{$_[2]}) {
			next if !defined($_[2]->{$k});
			if ($_[2]->{$k} =~/^\s+/) {$_[2]->{$k} =$'}
			if ($_[2]->{$k} =~/\s+$/) {$_[2]->{$k} =$`}
		}
		$_[2]})
	if !$s->{-recTrim0A};
 $s->set(-recInsID=>sub{
		# !!! database lookup may be better and faster, 
		# but appropriate insulation level may be needed
		$_[0]->varLock();
		$_[2]->{'id'} =lc($_[0]->{-host})
		.strpad($_[0],$_[0]->{-var}->{-table}->{$_[1]->{-table}}->{-recInsID}
		=dwnext($_[0],$_[0]->{-var}->{-table}->{$_[1]->{-table}}->{-recInsID}));
		$_[0]->varStore();
		$_[2]->{'id'}})
	if !$s->{-recInsID};
 if ($ENV{MOD_PERL_API_VERSION}
 && ($ENV{MOD_PERL_API_VERSION} >=2)) {
	# Apache2::ServerUtil->server->push_handlers("PerlCleanupHandler"
	#	,sub{eval{$s->end}; eval('Apache2::Const::DECLINED;')});
 }
 elsif ($ENV{MOD_PERL}) {
	Apache->push_handlers("PerlCleanupHandler"
		,sub{eval{$s->end}; eval('Apache::DECLINED;')});
 }
 $ENV{TMP} =$ENV{TEMP} =$ENV{TMP}||$ENV{tmp}||$ENV{TEMP}||$ENV{temp}
			||$ENV{TMPDIR}		# see CGI.pm source
			||$s->pthForm('tmp');
 $s->{-c}->{-startinit} =1;
 $s
}


sub class {
 substr($_[0], 0, index($_[0],'='))
}


sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($s, %opt) =@_;
 foreach my $k (keys(%opt)) {
	$s->{$k} =$opt{$k};
 }
 if ($opt{-env}) {
	my $env =$s->{-env} =ref($opt{-env}) eq 'CODE' ? &{$opt{-env}}(@_) : $opt{-env};
	if (ref($env) eq 'HASH') {
		foreach my $k (keys %$env) {
			if (defined($env->{$k})){$ENV{$k} =$env->{$k}}
			else			{delete($ENV{$k})}
		}
	}
 }
 if ($opt{-die}) {
	my ($s, $he, $hw) =($_[0]);
	if    (ref($opt{-die})) {}
	elsif ($opt{-die} =~/^(perl|core)$/i) {
		$s->{-warn} =$LNG->{-warn}; $s->{-die} =$LNG->{-die};
	}
	elsif ($opt{-die}) {
		my $m =($s->{-die} =~/^([^\s]+)\s*/ ? $1 : $s->{-die}) .'::';
		($he, $hw) =($SIG{__DIE__}, $SIG{__WARN__});
		$s->{-warn} =eval('use ' .$s->{-die} .';\\&' .$m .($s->{-debug} ?'cluck'   :'carp' ));
		$s->{-die}  =eval('use ' .$s->{-die} .';\\&' .$m .($s->{-debug} ?'confess' :'croak'));
		$he =($he ||'') ne ($SIG{__DIE__}||'') ? $SIG{__DIE__} : undef;
		$hw =($hw ||'') ne ($SIG{__WARN__}||'') ? $SIG{__WARN__} : undef;
	}
	$SIG{__DIE__}	=sub{	return if ineval();
				my $s =$SELF;
				$s =undef if !isa($s, 'DBIx::Web');
				$s && eval{$s->logRec('Die', ($_[0] =~/(.+)[\n\r]+$/ ? $1 : $_[0]))};
				$s && eval{$s->recRollback()};
				ref($he) && &$he};
	$SIG{__WARN__}	=sub{	return if ineval();
				my $s =$SELF;
				$s =undef if !isa($s, 'DBIx::Web');
				$s && eval{$s->logRec('Warn',($_[0] =~/(.+)[\n\r]+$/ ? $1 : $_[0]))};
				ref($hw) && &$hw};
 }
 if (exists $opt{-locale}) {
	$s->{-lng}	='';
	$s->{-lnglbl}	='';
	$s->{-lngcmt}	='';
	$s->{-lang}	=lc($opt{-locale} =~/^(\w\w)/	? $1	: 'en');
	$s->{-charset}	=$opt{-locale} =~/\.(.+)$/	? $1	: '1252';
 }
 if (exists $opt{-lng}) {
	$s->{-lng}	=lc($s->{-lng});
	$s->{-lnglbl}	=$s->{-lng} ? '-lbl' .'_' .$s->{-lng} : '';
	$s->{-lngcmt}	=$s->{-lng} ? '-cmt' .'_' .$s->{-lng} : '';
 }
 if (exists $opt{-autocommit}) {
	$s->{-dbi}->{AutoCommit} =$opt{-autocommit} if $s->{-dbi};
 }
 if ($opt{-cgibus} && !ref($opt{-cgibus})) {
	$s->{-recInsID} =sub{	# recIns() row ID generation trigger
				# cgi-bus 'gwo.cgi'
		$_[2]->{'id'} =($_[0]->user =~/^([^@]+)@(.+)$/
					? $2 .'\\' .$1
					: $_[0]->user)
				.'/' .$_[0]->strtime('yyyymmddhhmmss')};
	$s->{-rfdName} =sub{	# convert record's key into directory name
				# cgi-bus 'gwo.cgi', '-ksplit, tmsql::fsname()
				# 'rfdName()'/'-rfdName'
			local $_ =$_[1];
			my $r ='';
			return($r) if !$_;
			while ($_ =~/([\\\/])/) {
				$_ =$';
				my $v =$` .$1; $v =~s/([^a-zA-Z0-9])/uc sprintf("_%02x",ord($1))/eg;
				$r .=$v .'/'
			};
			$r .= join('/'
				,map {	if (defined($_) && $_ ne '') {
						my $v =$_; 
						$v =~s/([^a-zA-Z0-9])/uc sprintf("_%02x",ord($1))/eg;
						$v
					}
					else {return()}
					} substr($_,0,4),substr($_,4,2),substr($_,6,2),substr($_,8,2),substr($_,10));
			$r
		};
	$RISM2  ='$';		# record identification end   special mark 
				# tmsql	'sub fsname'
				# rmlIdSplit() / -idsplit, cgiForm(), ui...
 }
 if ($opt{-urf} && (ref($opt{-urf}) eq 'CODE')) {
	$s->{-urf} =$opt{-urf}= &{$opt{-urf}}($s);
 }
 if ($opt{-urf} && (substr($opt{-urf},0,1) eq '-')) {
	$s->{-urf}	= $opt{-urf} ne '-path'
			? $s->{$opt{-urf}}
			: $s->{-cgibus} && cgibus($s)
			?('file://' .cgibus($s))
			:('file://' .$s->{$opt{-urf}})
 }
 $s
}


sub lng {
 my $l =$LNG->{$_[0]->{-lng}} || $LNG->{''};
 my $m;
  @_ <3 
? ($m =$l->{$_[1]} ||$LNG->{''}->{$_[1]}) && ($m->[0] ||$m->[1]) ||$_[1]
: @_ <4
? ( (($m =$l->{$_[2]} ||$l->{'-' .$_[2]}) && $m->[$_[1]])
 || (($m =$LNG->{''}->{$_[2]}	||$LNG->{''}->{'-' .$_[2]})	&& $m->[$_[1]])
 || $_[2])
: eval {my $r =lng(@_[0..2]);
	my $v =!ref($_[3]) ? $_[3] : ref($_[3]) eq 'CODE' ? &{$_[3]}(@_) : strdata($_[0], $_[3]);
	   $v ='undef' if !defined($v);
	$r =~s/\$_/$v/ge ? $r : "$r $v"
	}
}


sub lang {
 my $l =$LNG->{$_[0]->{-lang}} || $LNG->{''};
 my $m;
  @_ <3 
? ($m =$l->{$_[1]} ||$LNG->{''}->{$_[1]}) && ($m->[0] ||$m->[1]) ||$_[1]
: @_ <4
? ( (($m =$l->{$_[2]} ||$l->{'-' .$_[2]}) && $m->[$_[1]])
 || (($m =$LNG->{''}->{$_[2]}	||$LNG->{''}->{'-' .$_[2]})	&& $m->[$_[1]])
 || $_[2])
: eval {my $r =lng(@_[0..2]);
	my $v =!ref($_[3]) ? $_[3] : ref($_[3]) eq 'CODE' ? &{$_[3]}(@_) : strdata($_[0], $_[3]);
	   $v ='undef' if !defined($v);
	$r =~s/\$_/$v/ge ? $r : "$r $v"
	}
}


sub lnghash {	# locale hash (self, index, array)
 return $_[2] 
	? { map {($_, lng($_[0],$_[1],$_))
		} ref($_[2]) eq 'ARRAY' ? @{$_[2]} : ()}
	: ($LNG->{$_[0]->{-lng}} || $LNG->{''})
}


sub lngslot {	# localised slot (self, object, keyname)
 $_[1]->{$_[2] .'_' .$_[0]->{-lng}} || $_[1]->{$_[2]}
}


sub lnglbl {	# localised label (self, object,...)
 foreach my $e (@_[1..$#_]) {
	next if !ref($e);
	my $v =$e->{$_[0]->{-lnglbl}} || $e->{-lbl};
	next if !$v;
	return(ref($v) ? &$v(@_) : $v)
 }
 !ref($_[$#_]) && $_[1]->{$_[$#_]} ? lng($_[0],0,$_[1]->{$_[$#_]}) : ''
}


sub lngcmt {	# localised comment (self, object,...)
 foreach my $e (@_[1..$#_]) {
	next if !ref($e);
	my $v =$e->{$_[0]->{-lngcmt}} || $e->{-cmt} || $e->{$_[0]->{-lnglbl}} || $e->{-lbl};
	next if !$v;
	return(ref($v) ? &$v(@_) : $v)
 }
 !ref($_[$#_]) && $_[1]->{$_[$#_]} ? lng($_[0],1,$_[1]->{$_[$#_]}) : ''
}


sub charset {	# character set name, as for web
 return($LNG->{''}->{-charset}->[0]) if !$_[0]->{-charset};
 $_[0]->{-charset} =~/^\d/ ? 'windows-' .$_[0]->{-charset} : $_[0]->{-charset}
}


sub charpage {	# character page name, as for Encode
	charset($_[0]) =~/^windows-(\d+)/ ? "cp$1" : charset($_[0]);
}

sub ineval {	# is inside eval{}?
		# for PerlEx and mod_perl
		# see CGI::Carp::ineval comments and errors
	return $^S	if !($ENV{GATEWAY_INTERFACE}
				&& ($ENV{GATEWAY_INTERFACE} =~/PerlEx/))
			&& !$ENV{MOD_PERL};
	my ($i, @a) =(1);
	while (@a =caller($i)) {
		# $_[0] && $_[0]->logRec('ineval',$i,$a[0],$a[1],$a[2],$a[3]);
		return(0) if $a[0] =~/^(?:PerlEx::|Apache::Perl|Apache::Registry|Apache::ROOT|ModPerl::ROOT|ModPerl::RegistryCoker)/i;
		return(1) if $a[3] eq '(eval)';
		$i +=1;
	}
}


sub die {
 &{$_[0]->{-die}}($_[0]->{-ermu} 
	.(($#_ <2) && ($_[1] !~/[\r\n]$/)
		? ($_[1] .$_[0]->{-ermd})
		: join('',@_[1..$#_])))
}


sub warn {
 &{$_[0]->{-warn}}(@_[1..$#_])
}


sub diags {	# Health and Inspector
 my ($s, $o) =@_;	# (-html,all,perl,env,cgi,cgiparam)
 $o ='-' if !$o;
 $CACHE->{-new} =1	if !defined($CACHE->{-new});
 $CACHE->{-destroy} =0	if !defined($CACHE->{-destroy});
 my $r ='***HEALTH: ';
 my ($rs, $rc, $rp) =(undef, 0, '');
 $rs =sub{	if (!$_[0] ||!ref($_[0]) ||(ref($_[0]) eq 'CODE')) {}
		elsif (ref($_[0]) && ($_[0]=~/hash/i)) {
			if (($_[0] eq $s) && $_[1]) {
				$rc +=1; $rp .=$_[1] .';';
				return(0)
			}
			foreach my $k (keys %{$_[0]}) {
				&$rs($_[0]->{$k}, ($_[1] || '') ."{$k}") if ref($_[0]->{$k})
			}
		}
		elsif (ref($_[0]) && ($_[0]=~/array/i)) {
			for(my $i=0; $i <=$#{$_[0]}; $i++) {
				&$rs($_[0]->[$i], ($_[1] || '') ."[$i]") if ref($_[0]->[$i])
			}
		}};
 &$rs($s, '');
 $r .=($CACHE->{-new} ? 'new=' .$CACHE->{-new} .' ' : '')
	.($CACHE->{-destroy} ? 'DESTROY=' .$CACHE->{-destroy} .' ' : '')
	.($rc ? 'self recurse=' .$rp .' ' : '')
	.getlogin();

 $r .="\n===Perl: \$^X=$^X; \$]=$]; \@INC=" .join(', ', map{"'$_'"} @INC) .'; getlogin=' .getlogin()
	if ($o =~/\b(?:perl|all)\b/i);
 $r .="\n===\%ENV: " .join(', ', map {"$_=" .(defined($ENV{$_}) ? "'" .$ENV{$_} ."'" : 'undef')
		} qw(SERVER_SOFTWARE SERVER_PROTOCOL DOCUMENT_ROOT GATEWAY_INTERFACE MOD_PERL PERLXS PERL_SEND_HEADER REMOTE_USER TMP TEMP SCRIPT_NAME PATH_INFO PATH_TRANSLATED REQUEST_METHOD REQUEST_URI QUERY_STRING REDIRECT_QUERY_STRING CONTENT_TYPE CONTENT_LENGTH))
	if ($o =~/\b(?:env|all)\b/i);
 $r .="\n===CGI: " .join(', '
	,(map {	my $v =eval("\$CGI::$_");
		("\$$_=" .(defined($v) ? "'$v'" : 'undef'))
		} qw (VERSION TAINTED MOD_PERL PERLEX XHTML NOSTICKY NPH PRIVATE_TEMPFILES TABINDEX CLOSE_UPLOAD_FILES POST_MAX HEADERS_ONCE USE_PARAM_SEMICOLONS))
	,(map {	my $v =$s->url(!$_ ? () : ($_=>1));
		(($_||'%url') .'=' .(defined($v) ? "'$v'" : 'undef'))
		} '', qw(-absolute -relative -base))
	,'-self_url=' .($s->cgi->self_url()||'')
	)
	if $s->{-cgi} && ($o =~/\b(?:cgi|all)\b/i);
 $r .="\n===CGI param: " .join(', '
	,map {("$_=" .(defined($s->cgi->param($_)) ? "'" .$s->cgi->param($_) ."'" : 'undef'))
		} $s->cgi->param
	)
	if $s->{-cgi} && ($o =~/\b(?:cgiparam|all)\b/i);
$o =~/\b(?:html)\b/i
? join("<br /n>", split /[\r\n]/, $s->htmlEscape($r))
: $r
}


sub cgibus {	# (self, set) -> is cgi-bus mode?
 return($_[0]->{-cgibus}) if !ref($_[0]->{-cgibus});
 local $_;
 $_ =&{$_[0]->{-cgibus}}($_[0]
	, $_ =$_[0]->{-pcmd} && ($_[0]->{-pcmd}->{-table} || $_[0]->{-pcmd}->{-form})
	  || $_[0]->cgi->param('_table') || $_[0]->cgi->param('_form') || $_[0]->cgi->param('_key')
	  || 'default'
	, $_[1]);
 $_[0]->set(-cgibus=>$_) if $_[1];
 $_
}


sub start {	# start session
 my $s =shift;
 my %o =@_;
 if (!$s->{-c}->{-startinit}) {
	$CACHE->{$s}	={};
	$s->{-c}	={};
 }
 delete $s->{-c}->{-startinit};
 $s->{-fetched} =0;
 $s->{-limited} =0;
 $s->{-affected}=0;
 $s->{-var}->{'_handle'}->destroy if $s->{-var} && $s->{-var}->{'_handle'};
 $s->w32IISdpsn()	if (($ENV{SERVER_SOFTWARE}||'') =~/IIS/)
			&& ((defined($s->{-w32IISdpsn})
				? $s->{-w32IISdpsn} ||0
				: 2) >1)
			&& !$s->cgi->param('_qftwhere');
 unless ((($ENV{SERVER_SOFTWARE}||'') =~/IIS/)
	&& $s->cgi->param('_qftwhere')) {
	 $s->varLoad(!$s->{-serial} ? 0 : $s->{-serial} >2 ? LOCK_EX : $s->{-serial} >1 ? LOCK_SH : $s->{-serial} >0 ? LOCK_SH : 0);
	 $s->logOpen() if $s->{-log} && !ref($s->{-log});
	 $s->{-log}->lock(0) if ref($s->{-log});
 }
 $s->set(@_);
 $s
}


sub end {	# end session
 my $s =shift;
 $s->logRec('end');
 &{$s->{-end0}}($s) if $s->{-end0};
 if ($s->{-dbi}) {
	# $s->recCommit();
	eval{$s->{-dbi}->disconect};
	$s->{-dbi} =undef;
 }
 if ($s->{-cgi}) {
	eval{$s->{-cgi}->DESTROY()};
	$s->{-cgi} =undef;
	$CGI::Q =undef;
 }
 foreach my $k (sort keys %{$s->{-endh}}) {eval{&{$s->{-endh}->{$k}}($s)}};
 $s->{-endh} ={};
 $s->smtp(undef) if $s->{-smtp};
 if ($s->{-var} && $s->{-var}->{'_handle'}) {
	$s->{-var}->{'_handle'}->destroy;
	delete $s->{-var}->{'_handle'};
 }
 if (ref($s->{-log})) {
	$s->{-log}->destroy;
	$s->{-log} =undef;
 }
 eval{$s->{-c}->{-ldap}->unbind} if $s->{-c}->{-ldap};
 $s->{-c}	={};
 $CACHE->{$s}	={};
 &{$s->{-end1}}($s) if $s->{-end1};
 $s
}


sub DESTROY {
 my $s =shift;
 $CACHE->{-destroy} =($CACHE->{-destroy} ||0) +1
	if defined($CACHE->{-new});
 if ($s->{-cgi}) {
	eval{$s->{-cgi}->DESTROY()};
	delete $s->{-cgi};
	$CGI::Q =undef;
 }
 $s->{-endh} =undef;
 $s->smtp(undef) if $s->{-smtp};
 if ($s->{-var} && $s->{-var}->{'_handle'}) {
	eval{$s->{-var}->{'_handle'}->destroy};
	delete $s->{-var}->{'_handle'};
 }
 if (ref($s->{-log})) {
	eval{$s->{-log}->destroy};
	$s->{-log} =undef;
 }
 eval{$s->{-c}->{-ldap}->unbind} if $s->{-c}->{-ldap};
 $s->{-c}	=undef;
 delete $CACHE->{$s};
 $s
}


sub setup {	# Setup script execution
 my ($s) =@_;

 print "Writing sample '.htaccess-$VERSION' file...\n";
 my $pth =$s->pthForm('tmp') && $s->{-path};
    $pth =~s/\\/\//g;
 $s->hfNew('+>', ($pth .'/.htaccess-' .$VERSION))->lock(LOCK_EX)
	->store( "# Default data and pulic directory tree configuration.\n"
		."# Should be included in 'httpd.conf'.\n"
		."# Include " .($pth .'/.htaccess-' .$VERSION) ."\n"
		."\n"
		."#<IfModule !mod_ntlm.c>\n"
		."#\tLoadModule ntlm_module modules/mod_ntlm.so\n"
		."#</IfModule>\n"
		."#<IfModule !mod_auth_sspi.c>\n"
		."#\tLoadModule sspi_auth_module modules/mod_auth_sspi.so\n"
		."#</IfModule>\n"
		."<Directory " .$pth ." >\n"
		."#\tAllowOverride All\n"
		."\tAllowOverride Limit AuthConfig\n"
		."\tOptions -FollowSymLinks\n"
		."\tAccessFileName .htaccess\n"
		."\tOrder Allow,Deny\n"
		."\tAllow from All\n"
		."#\t<IfModule mod_ntlm.c>\n"
		."#\t\tAuthType NTLM\n"
		."#\t\tNTLMAuth On\n"
		."#\t\tNTLMAuthoritative On\n"
		."#\t\tNTLMOfferBasic On\n"
		."#\t</IfModule>\n"
		."#\t<IfModule mod_auth_sspi.c>\n"
		."#\t\tAuthType SSPI\n"
		."#\t\tSSPIAuth On\n"
		."#\t\tSSPIAuthoritative On\n"
		."#\t\tSSPIOfferBasic On\n"
		."#\t</IfModule>\n"
		.($s->{-AuthUserFile}
		?("\tAuthUserFile " .$s->{-AuthUserFile} ."\n")
		:("#\tAuthUserFile " .($pth ."/var/ualist") ."\n"))
		."\tAuthGroupFile " .($s->{-AuthGroupFile} ||($pth ."/var/uagroup")) ."\n"
		."</Directory>\n"
		."#Alias /dbix-web/rfa/ \"$pth/\"\n"
		)
	->destroy;
 $s->pthForm('rfa');

 print "Executing <DATA>, some SQL DML error messages may be ignored...\n\n";
 local $s->{-dbiargpv}	=$s->{-dbiarg};
 local $s->{-affect}	=undef;
 local $s->{-rac}	=undef;
 my $row;
 my $cmd ='';
 my $cmt ='';
 while ($row =<main::DATA>) { $row =<main::DATA> if 0;
	chomp($row);
	if ($cmd && ($row =~/^#/)) {
		my $v;
		chomp($cmd);
		print $cmt ||$cmd, " -> ";
		local $SELF	=$s;
		local $_	=$s;
		if   ($cmd =~/^\s*\{/) {
			$v =eval($cmd);
			print $@ ? $@ : 'ok'
		}
		else {
			$v =$s->dbi->do($cmd);
			print $s->dbi->err ? $s->dbi->errstr : 'ok'
		}
		print ': ', defined($v) ? $v : 'undef', "\n\n";
		$cmd ='';
		$cmt ='';
	}
	if	($row =~/^\s*#*\s*$/ || $row =~/^\s+#/ || $row eq '') {
		next
	}
	elsif	($row =~/^#/) {
		$cmt =$row
	}
	else {
		$cmd .=($cmd ? "\n" : '') .$row
	}
 }
 $s
}


#########################################################
# Misc Data methods
#########################################################


sub dwnext {	# next digit-word string value
		# self, string, ? min length
 my $v =$_[1] ||'0';
 for(my $i =1; $i <=length($v); $i++) {
	next if ord(substr($v,-$i,1)) >=ord('z');
	substr($v,-$i,1)=chr(ord(substr($v,-$i,1) eq '9' ? chr(ord('a')-1) : substr($v,-$i,1)) +1);
	substr($v,-$i+1)='0' x ($i-1) if $i >1;
	return($_[2] && length($v) <$_[2] ? '0' x ($_[2] -length($v)) .$v : $v)
 }
 $v =chr(ord('0')+1) .('0' x length($v));
 $_[2] && length($v) <$_[2] ? '0' x ($_[2] -length($v)) .$v : $v
}


sub grep1 {	# first non-empty value
		# self, list
		# self, sub{}, list
 local $_;
 if (ref($_[1]) ne 'CODE') {
	foreach (@_[1..$#_]) {return($_) if $_}
 }
 else {
	my $t;
	foreach (@_[2..$#_]) {$t =&{$_[1]}(); return $t if $t}
 }
 return(())
}


sub shiftkeys {	# shift keys from array
 my ($s,$a,$e) =@_;	# (self, array, string regexp | sub{} condition)
 local $_;
 my @r;
 while (scalar(@$a)) {
	if (	ref($e)
		? &$e($s, $_ =$a->[0], 0)
		: $a->[0] =~/^(?:$e)$/) {
		push @r, shift @$a, shift @$a;
	}
	else {
		last
	}
 }
 @r
}


sub splicekeys { # splice keys from array
 my ($s,$a,$e) =@_;	# (self, array, string regexp | sub{} condition)
 local $_;
 my $i =0;
 my @r;
 while (scalar(@$a) && ($i <=$#$a)) {
	if (	ref($e)
		? &$e($_[0], $_ =$a->[$i], $i)
		: $a->[$i] =~/^(?:$e)$/) {
		push @r, $a->[$i], $a->[$i+1];
		splice @$a,$i,2;
	}
	else {
		$i +=2
	}
 }
 @r
}


sub hreverse {	# reverse hierarchy
		# (data, old delim, new delim) -> {value => reversed,...}
 my($s, $d, $m1, $m2) =@_;
 if (defined($m1)) {}
 elsif (!ref($d) && $d && ($d =~/\\/))	{$m1 ='\\'; $m2 ='/'}
 else					{$m1 ='/'; $m2 ='\\'}
 if (!ref($d)) {
	return(!$d ? $d : join($m2, reverse split /\Q$m1\E/, $d))
 }
 elsif (ref($d) eq 'ARRAY') {
	my($r, $e) =({});
	for(my $i =0; $i <=$#$d; $i++) {
		$e =$d->[$i];
		if (ref($e)) {
			$r->{$e->[0]} =[join($m2, reverse split /\Q$m1\E/, $e->[0])
					,@$e[1..$#$e]]
				if defined($e->[0]);
		}
		else {
			$r->{$e} =join($m2, reverse split /\Q$m1\E/, $e)
				if defined($e);
		}
	}
	return($r);
 }
 elsif (ref($d) eq 'HASH') {
	my($r, $e) =({});
	foreach $e (keys %$d) {
		if (ref($d->{$e})) {
			$r->{$e} =[join($m2, reverse split /\Q$m1\E/, $d->{$e}->[0])
					,@{$d->{$e}}[1..$#{$d->{$e}}]]
				if defined($d->{$e}->[0]);
		}
		else {
			$r->{$e} =join($m2, reverse split /\Q$m1\E/, $d->{$e})
				if defined($d->{$e});
		}
	}
	return($r)
 }
 elsif (ref($d)) {
	my($r, $e) =({});
	while (defined($e =$d->fetch())) {
		$r->{$e->[0]} =$#$e >0
				? [join($m2, reverse split /\Q$m1\E/, $e->[0]), @$e[1..$#$e]]
				: join($m2, reverse split /\Q$m1\E/, $e->[0])
			if defined($e->[0]);
	}
	return($r);
 }
 else {
	return($d)
 }
}


sub max {	# maximal number
 (($_[1]||0) >($_[2]||0) ? $_[1] : $_[2])||0
}


sub min {	# minimal number
 (($_[1]||0) >($_[2]||0) ? $_[2] : $_[1])||0
}


sub orarg {	# argument of true result
 shift(@_);
 my $s =ref($_[0]) ? shift 
       :index($_[0], '-') ==0 ? eval('sub{' .shift(@_) .' $_}')
       :eval('sub{' .shift(@_) .'($_)}');
 local $_;
 foreach (@_) {return $_ if &$s($_)};
 undef
}


sub strpad {	# string padding
		# self, string, ?pad char, ?min length
 length($_[1]) <$NLEN ? ($_[2]||'0') x ($_[3] ||$NLEN -length($_[1])) .$_[1] : $_[1];
}


sub strdata {	# Stringify any data structure
  my $v =$_[1];	# self, data
 !defined($v) 
 ? ''
 : !ref($v)
 ? $v # ($v =~s/([\x00-\x1f\\])/sprintf("\\x%02x",ord($1))/eg ? $v : $v)
 : isa($v, 'ARRAY')
 ? join(', ', map {my $v =$_;
	  ref($v)
	? do {my $x =strdata($_[0],$v);
		 $x =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg;
		 '(' .$x .')'
		}
	: !defined($v)
	? ''
	: $v =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg
	? $v
	: $v
	} @$v)
 : isa($v, 'HASH')
 ? join(', ', map {my ($k, $v) =($_, $_[1]->{$_});
	$k =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg;
	  ref($v)
	? do {my $x =strdata($_[0],$v);
		 $x =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg;
		 $k .'=(' .$x .')'
		}
	: !defined($v)
	? "$k="
	: $v =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg
	? "$k=$v"
	: "$k=$v"
	} sort keys %$v)
 : $v
}


sub strdatah {	# Stringify hash data structure
 return(strdata(@_)) if $#_ <2;
 my $r ='';
 for (my $i =1; $i <$#_; $i +=2) {
	my ($k, $v) =@_[$i, $i+1];
	$k	=~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg;
	$r	.=$k .'='
		.(!defined($v)
		? ''
		: ref($v)
		? do {my $x =strdata($_[0],$v);
			 $x =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg;
			 '(' .$x .')'
			}
		: $v =~s/([\x00-\x1f,;=\\\)\(])/sprintf("\\x%02x",ord($1))/eg
		? $v
		: $v)
		.','
 }
 chop($r);
 $r
}


sub strquot {	# Quote and Escape string
 my $v =$_[1];
 return('undef') if !defined($v);
 $v =~s/([\\'])/\\$1/g;
 $v =~s/([\x00-\x1f])/sprintf("\\x%02x",ord($1))/eg;
 $v =~/^\d+$/ ? $v : ('\'' .$v .'\'');
}


sub strHTML {	# Stringify HTML, convert to pure text
 my $h =defined($_[1]) ? $_[1] : '';
 my $t ='';
 $h =$' if $h =~/^[\s\r\n]+/;
 $h =~s/>[\r\n]+</></g;
 $h =~s/[\r\n]+/ /g;
 while ($h =~/</) {
	$t .=$`;
	$h  =$';
	if (($h =~/^\/(?:h\d|div|p)\s*>\s*<\/(?:th|td)/i)
	||  ($h =~/^\/(?:li)\s*>\s*<(?:li|\/ul)/i)) {
		$t .="\n" if $t !~/^\s*$/;
		$h =$';
	}
	elsif ( ($h =~/^\/(?:h\d|div|p|td|th|tr|code|kbd|ul)/i)
	||	($h =~/^(?:br|hr|li|table)/i)) {
		$t .="\n" if $t !~/^\s*$/
	}
	$h =$'	if $h =~/>/;
 }
 $t .=$h;  
 $t =$_[0]->htmlUnescape($t);
 $t =~s/\n{2,}/\n\n/g;
 $t
}


sub strDiff {	# Strings difference
		# (-opt, old, new) -> changes
		# 'h'tml conversion if ishtml();
		# 'w'ords, 'r'ows, 's'entences input break;
		# 'b'rief, 'p'lane output
 my ($s,$o,$s1,$s2) =@_;
 my $r ='';
 $o  ='-br' if !$o;
 $s1 ='' if !defined($s1);
 $s2 ='' if !defined($s2);
 $s1 =$s->strHTML($s1) if ($o =~/h/) && $s->ishtml($s1);
 $s2 =$s->strHTML($s2) if ($o =~/h/) && $s->ishtml($s2);
 return($s2) if ($s1 eq '') || ($s2 eq '');
 my $br =sub{	my ($h, $t)=($_[0], '');
		while ($h =~/([^\n]{100})/) {
			$t .=$`; $h =$';
			my $v =$1;
			if ($v =~/[ \t]$/) {
				$t .=$` ."\n"
			}
			elsif ($h =~/^[ \t]/) {
				$t .=$v ."\n"
			}
			elsif ($v !~/[ \t]/) {
				$t .=$v
			}
			elsif ($v =~/\s+([^\s]+)$/) {
				$t .=$` ."\n";
				$h =$1 .$h
			}
		}
		$t .=$h;
		$t
	};
 if (0) {}
 elsif (($o =~/w/) 				# words diff
 &&	 eval('use Algorithm::Diff; 1')) {
	my $cat =sub{	my($b,$v)=@_[1..2]; # (buf, sign, acc, last)
			$_[2] ='';
			if (($b =~/^=/) && ($o =~/b/)) {
				$v =$' if $v =~/^[\s\n]+/;
				$v =$` if $v =~/[\s\n]+$/;
				$v =~/\n+/;
				if ($_[0] eq '') {
					$v =$1 if $v =~/\n+([^\n]+)$/
				}
				elsif ($_[3]) {
					$v =$1 if $v =~/^([^\n]+)\n+/
				}
				elsif ($v =~/\n+/) {
					my $t =$`;
					if ($' =~/\n+([^\n]+)$/) {
						$v =$t ."\n...\n" .$1
					}
				}
				$v =' ' .$v;
			}
			$v =&$br($v) if $o =~/p/;
			$v =~s/\n/\n$b /g;
			$_[0] .=$b .$v ."\n";
		};
	$s1 =~s/([^ \t])\n/$1 \n/g; $s1 =~s/\n([^ \t])/\n $1/g;
	$s2 =~s/([^ \t])\n/$1 \n/g; $s2 =~s/\n([^ \t])/\n $1/g;
	my ($p, $ax, $ay, $au) =('','','','');
	foreach my $d (Algorithm::Diff::sdiff([split /[ \t]+/, $s1],[split /[ \t]+/, $s2])) {
		if ($p ne $d->[0]) {
			&$cat($r,'-:',$ax) if length($ax) >0;
			&$cat($r,'+:',$ay) if length($ay) >0;
			&$cat($r,'=:',$au) if length($au) >0;
		}
		$p =$d->[0];
		$ax .=' ' .$d->[1] if $p eq '-';
		$ax .=' ' .$d->[1] if $p eq 'c';
		$ay .=' ' .$d->[2] if $p eq '+';
		$ay .=' ' .$d->[2] if $p eq 'c';
		$au .=' ' .$d->[1] if $p eq 'u';
	}
	&$cat($r,'-:',$ax,1) if length($ax) >0;
	&$cat($r,'+:',$ay,1) if length($ay) >0;
	&$cat($r,'=:',$au,1) if length($au) >0;
 }
 elsif (eval('use Algorithm::Diff; 1')) {	# strings diff
	if ($o =~/r/) {		# row break
		$s1 =&$br($s1);
		$s2 =&$br($s2);
	}
	elsif ($o =~/s/) {	# sentence break
		$s1 =~s/\.[ \t]+/\.\n/;
		$s2 =~s/\.[ \t]+/\.\n/;
	}
	my $cat =sub{	my($b,$v)=@_[1..2]; # (buf, sign, acc, last)
			$_[2] ='';
			if (($b =~/^=/) && ($o =~/b/)) {
				$v =$' if $v =~/^[\s\n]+/;
				$v =$` if $v =~/[\s\n]+$/;
				$v =~/\n+/;
				if ($_[0] eq '') {
					$v =$1 if $v =~/\n+([^\n]+)$/
				}
				elsif ($_[3]) {
					$v =$1 if $v =~/^([^\n]+)\n+/
				}
				elsif ($v =~/\n+/) {
					my $t =$`;
					if ($' =~/\n+([^\n]+)$/) {
						$v =$t ."\n...\n" .$1
					}
				}
			}
			else {
				chomp($v)
			}
			$v =&$br($v) if $o =~/p/;
			$v =~s/\n/\n$b /g;
			$_[0] .=$b .' ' .$v ."\n";
		};
	my ($p, $ax, $ay, $au) =('','','','');
	foreach my $d (Algorithm::Diff::sdiff([split /\n+/, $s1],[split /\n+/, $s2])) {
		if ($p ne $d->[0]) {
			&$cat($r,'-:',$ax) if length($ax) >0;
			&$cat($r,'+:',$ay) if length($ay) >0;
			&$cat($r,'=:',$au) if length($au) >0;
		}
		$p =$d->[0];
		$ax .=$d->[1] ."\n" if $p eq '-';
		$ax .=$d->[1] ."\n" if $p eq 'c';
		$ay .=$d->[2] ."\n" if $p eq '+';
		$ay .=$d->[2] ."\n" if $p eq 'c';
		$au .=$d->[1] ."\n" if $p eq 'u';
	}
	&$cat($r,'-:',$ax,1) if length($ax) >0;
	&$cat($r,'+:',$ay,1) if length($ay) >0;
	&$cat($r,'=:',$au,1) if length($au) >0;
 }
 else {						# simplest diff
	$r =	  ($s1 eq '') || ($s2 eq '')
		? $s2
		: (length($s1) >255) && (length($s2) >255) 
		? '...Algorithm::Diff should be used...'
		: $s2;
 }
 $r
}


sub htfrDiff {	# html reformat for difference
 $_[1] =~/<br\s*\/>\n*[-+=]:/
 ? "<table>"
	.join("\n"
	, map {	$_ =~/^([-+=]):\s*/
		? "<tr><td align=\"middle\" valign=\"top\">$1</td><td align=\"middle\" valign=\"top\">:</td><td align=\"left\" valign=\"top\">$'</td></tr>"
		: "<tr><td colspan=3 align=\"left\" valign=\"top\">$_</td></tr>"
		} split /\s*<br\s*\/>\n/, $_[1])
	."</table>"
 : $_[1]
}


sub datastr {	# Data structure from String
		# (for data structure strings only!)
		# self, string, ?unescape
 my $v =$_[1];
    $v =~s/\\x([0-9a-fA-F]{2})/chr hex($1)/eg if $_[2];
    $v =~/^[^\(\)]+[=]/
 ? {map { my ($n, $v) =(/^\s*([^=]+)\s*=\s*(.*)$/ ? ($1,$2) : ());
	   !defined($n) ||($n eq '')
	?  ()
	:  !defined($v)
	? ($n =>$v)
	:  $v =~/^\(/
	? ($n =>datastr($_[0], substr($v,1,-1), 1) ||undef)
	:  $v =~s/\\x([0-9a-fA-F]{2})/chr hex($1)/eg
	? ($n =>$v)
	: ($n =>$v)
	} split /\s*[,;]\s*/, $v}
 : $v =~/[,;]/
 ? [grep {defined($_)} map { 
	!defined($_)
	? ()
	: /^\(/
	? datastr($_[0], substr($_,1,-1), 1) ||undef
	: s/\\x([0-9a-fA-F]{2})/chr hex($1)/eg
	? $_
	: $_
	} split / *[,;] */, $v]
 : $v =~s/\\x([0-9a-fA-F]{2})/chr hex($1)/eg
 ? $v
 : $v
}

sub dsdClone {	# Clone data structure
   !ref($_[1]) ? $_[1]
 : ref($_[1]) eq 'ARRAY' ? [map {ref($_) ? dsdClone($_[0], $_) : $_} @{$_[1]}]
 : ref($_[1]) eq 'HASH'  ? {map {($_, dsdClone($_[0], $_[1]->{$_}))} keys %{$_[1]}}
 : $_[1]
}


sub dsdMk {     # Data structure dump to string
 my ($s, $d) =@_;
 eval('use Data::Dumper');
 my $o =Data::Dumper->new([$d]); 
 $o->Indent(1);
 $o->Dump();
}


sub dsdQuot {	# Quote and Escape data structure
   $#_ <2	# (self, ?'=>', data struct)
 ? dsdQuot($_[0],'=> ',$_[1])
 : !ref($_[2])	# (, hash delim, value) -> stringified
 ? strquot($_[0],$_[2])
 : ref($_[2]) eq 'ARRAY'
 ? '[' .join(', ', map {dsdQuot(@_[0..1],$_)
			} @{$_[2]}) .']'
 : ref($_[2]) eq 'HASH'
 ? '{' .join(', ', map {$_ .$_[1] .dsdQuot(@_[0..1],$_[2]->{$_})
			} sort keys %{$_[2]}) .'}'
 : strquot($_[0],$_[2])
}


sub dsdParse {  # Data structure dump string to perl structure
 my ($s, $d) =@_;
 eval('use Safe');
 Safe->new()->reval($d)
}


sub strtime {	# Stringify Time
 my $s =shift;
 my $msk =@_ ==0 || $_[0] =~/^\d+$/i ? 'yyyy-mm-dd hh:mm:ss' : shift;
 my @tme =@_ ==0 ? localtime(time) : @_ ==1 ? localtime($_[0]) : @_;
 $msk =~s/yyyy/%Y/;
 $msk =~s/yy/%y/;
 $msk =~s/mm/%m/;
 $msk =~s/mm/%M/i;
 $msk =~s/dd/%d/;
 $msk =~s/hh/%H/;
 $msk =~s/hh/%h/i;
 $msk =~s/ss/%S/;
#eval('use POSIX');
 POSIX::strftime($msk, @tme)
}


sub timestr {	# Time from String
 my $s   =shift;
 my $msk =@_ <2 || !$_[1] ? 'yyyy-mm-dd hh:mm:ss' : shift;
 my $ts  =shift;
 my %th;
 while ($msk =~/(yyyy|yy|mm|dd|hh|MM|ss)/) {
    my $m=$1; $msk =$';
    last if !($ts =~/(\d+)/);
    my $d =$1; $ts   =$';
    $d   -=1900   if $m eq 'yyyy' ||$m eq '%Y';
    $m    =chop($m);
    $m    ='M'    if $m eq 'm' && $th{$m};
    $m    =lc($m) if $m ne 'M';
    $th{$m}=$d;
 }
#eval('use POSIX');
 POSIX::mktime($th{'s'}||0,$th{'M'}||0,$th{'h'}||0,$th{'d'}||0,($th{'m'}||1)-1,$th{'y'}||0,0,0,(localtime(time))[8])
}


sub timeadd {	# Adjust time to years, months, days,...
 my $s =$_[0];
 my @t =localtime($_[1]);
 my $i =5;
 foreach my $a (@_[2..$#_]) {$t[$i] += ($a||0); $i--}
#eval('use POSIX');
 POSIX::mktime(@t[0..5],0,0,$t[8])
}


sub cptran {	# Translate strings between codepages
 my ($s,$f,$t,@s) =@_;
 if (($] >=5.008) && eval("use Encode; 1")) {
	map {$_=  /oem|866/i	? 'cp866'
		: /ansi|1251/i	? 'cp1251'
		: /koi/i	? 'koi8-r'
		: /8859-5/i	? 'iso-8859-5'
		: $_
		} $f, $t;
	map {Encode::is_utf8($_)
		? ($_ =Encode::encode($t, $_, 0))
		: Encode::from_to($_, $f, $t, 0)
		if defined($_) && ($_ ne '')
		} @s;
 }
 else {
	foreach my $v ($f, $t) {	# See also utf8enc, utf8dec
		if    ($v =~/oem|866/i)   {$v ='ЂЃ‚ѓ„…р†‡€‰Љ‹ЊЌЋЏђ‘’“”•–—™њ›љќћџ ЎўЈ¤Ґс¦§Ё©Є«¬­®Їабвгдежзиймлкноп'}
		elsif ($v =~/ansi|1251/i) {$v ='АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдеёжзийклмнопрстуфхцчшщьыъэюя'}
		elsif ($v =~/koi/i)       {$v ='бвчздеіцъйклмнопртуфхжигюыэшщяьасБВЧЗДЕЈЦЪЙКЛМНОПРТУФХЖИГЮЫЭШЩЯЬАС'}
		elsif ($v =~/8859-5/i)    {$v ='°±ІіґµЎ¶·ё№є»јЅѕїАБВГДЕЖЗИЙМЛКНОПРСТУФХсЦЧШЩЪЫЬЭЮЯабвгдежзиймлкноп'}
	}
	map {eval("~tr/$f/$t/") if defined($_)} @s;
 }
 @s >1 ? @s : $s[0];
}


sub ishtml {	# Looks like HTML?
 ($_[1] ||'') =~m/^<(?:(?:B|BIG|BLOCKQUOTE|CENTER|CITE|CODE|DFN|DIV|EM|I|KBD|P|SAMP|SMALL|SPAN|STRIKE|STRONG|STYLE|SUB|SUP|TT|U|VAR)\s*>|(?:BR|HR)\s*\/{0,1}>|(?:A|BASE|BASEFONT|DIR|DIV|DL|!DOCTYPE|FONT|H\d|HEAD|HTML|IMG|IFRAME|MAP|MENU|OL|P|PRE|TABLE|UL)\b)/i
}



sub htmlEscape {
 join '',
 map {	my $v =$_; return('') if !defined($_);
	$v =~s{&}{&amp;}gso;
	$v =~s{<}{&lt;}gso;
	$v =~s{>}{&gt;}gso;
	$v =~s{"}{&quot;}gso;
	$v
     } @_[1..$#_]
}


sub htmlEscBlnk {
 join '',
 map {	my $v =$_; return('&nbsp;') if !defined($_) || $_ eq '';
	$v =~s{&}{&amp;}gso;
	$v =~s{<}{&lt;}gso;
	$v =~s{>}{&gt;}gso;
	$v =~s{"}{&quot;}gso;
	$v
     } @_[1..$#_]
}


sub htmlSubmitSpl {	# Special html buttons format
 # Additional Named Entities for HTML
 # ms-help://MS.MSDNQTR.v90.en/vbafpd11/html/fphowHTMLCharSets_HV03091409.htm
 # return($_[0]->cgi->submit(@_[1..$#_]))
 my ($s, %o) =@_;
 $o{-class} =$s->{-c}->{-htmlclass} ? 'Input ' .$s->{-c}->{-htmlclass} : 'Input'
	if !$o{-class};
 if (!$o{-value}) {
	$o{-value} =$s->lng(0,'ddlbopen');
	$o{-title} =$s->lng(1,'ddlbopen') if !$o{-title};
	$o{-style} ="width: 2em;" if !$o{-style};
 }
 join(' ','<input type="submit"'
	,(map {	my ($k, $t) =($_, $_ =~/^-(.+)/ ? $1 : $_);
		$t .'="'
		.(	$t =~/^value$/i
			? (	 $o{$k} eq '...'
				? '&hellip;'
				: htmlEscape($s, $o{$k})
				)
			: htmlEscape($s, $o{$k})
			) .'"'
		} sort keys %o)
	,'>')
}


sub htmlUnescape {
 join '',
 map {	my $v =$_; return('') if !defined($_);
	$v =~s[&(.*?);]{
   	    local $_ = $1;
		/^amp$/i	? "&" :
		/^quot$/i	? '"' :
		/^gt$/i		? ">" :
		/^lt$/i		? "<" :
		$_;
	}gex;
	$v
 } @_[1..$#_]
}


sub urlEscape {
 join '',
 map {	my $v =$_; return('') if !defined($_);
	$v =~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
	$v
 } @_[1..$#_]
}


sub urlUnescape {
 join '',
 map {	local $_ =$_; return('') if !defined($_);
	tr/+/ /;
	s/%([0-9a-fA-F]{2})/chr hex($1)/ge;
	$_
 } @_[1..$#_]
}


sub urlCat {
 my $r =$_[1] =~/\?/ ? ($_[1] .$HS) : ($_[1] .'?');
 for (my $i =2; $i <$#_; $i+=2) {$r .=urlEscape($_[0], $_[$i]) .'=' .urlEscape($_[0], $_[$i+1]) .$HS}
 chop($r); $r
}


sub urlCmd {
 my $r =($_[1]||'') .'?';
 for (my $i =2; $i <$#_; $i+=2) {
	$r .=urlEscape($_[0], $_[$i] =~/^-/ ? '_' .$' : $_[$i]) 
	.'=' 
	.urlEscape($_[0], ref($_[$i+1]) ? strdata($_[0], $_[$i+1]) : $_[$i+1])
	.$HS
 } chop($r); $r
}


sub xmlEscape {
 join '',
 map {	my $v =$_; return('') if !defined($v);
	$v =~s/([\\"<>])/sprintf('\\x%02x',ord($1))/ge;
      # $v =~s/([\\"<])/\\$1/g;
      # $v =~s/([^\w\d ,<.>\/?:;"'\[\]{}`~!@#$%^&*()-_=+\\|])/ ord($1) < 0x20 ? sprintf('\\x%02x',ord($1)) : $1/ge;
	$v =~s/([\x00-\x1F])/sprintf('\\x%02x',ord($1))/ge;
	$v
 } @_[1..$#_]
}


sub xmlAttrEscape {
 xmlEscape(@_)
}


sub xmlTagEscape {
 join '',
 map {	my $v =$_; return('') if !defined($v);
	$v =~s/([\\"<>])/sprintf('\\x%02x',ord($1))/ge;
      # $v =~s/([\\"<])/\\$1/g;
      # $v =~s/([^\w\d\s\n ,<.>\/?:;"'\[\]{}`~!@#$%^&*()-_=+\\|])/ ord($1) < 0x20 ? sprintf('\\x%02x',ord($1)) : $1/eg;
	$v =~s/([\x00-\x08\x0B-\x0C\x0E-\x1F]|[&])/sprintf('\\x%02x',ord($1))/eg;
		# \t=0x09; \n=0x0A; \r=0x0D;
	$v
 } @_[1..$#_]
}


sub xmlUnescape {
 join '',
 map {	my $v =$_; return('') if !defined($v);
	$v =~s/\\\\/\\/g;
	$v =~s|(\\+)([<"])| int(length($1)/2)*2 == length($1) ? ('\\' x (length($1)-1) .$2) : ($1 .$2)|ge;
	$v =~s|(\\+)(x\d+)| int(length($1)/2)*2 == length($1) ? ('\\' x (length($1)-1) .chr(hex($2))) : ($1 .$2)|ge;
	$v
 } @_[1..$#_]
}


sub lsTag {	# Attribute list to tag strings list 
 my($c, $v, $n);# htmlEscape, urlEscape, tagEscape, self, tagname, attr=>value,...
 $#_+1 !=2*int(($#_+1)/2)
 ? 0
 : substr($_[$#_],0,1) eq "\n"
 ? ($n =$_[$#_])
 : ($c =$_[$#_]);
 ((!ref($_[$[+4])
 ? ('<', $_[$[+4]
   ,(map  {$_[$_]
 	  ? (defined($_[$_+1]) 
	    ? (' ', substr($_[$_],0,1) eq '-' ? substr($_[$_],1) : $_[$_], '="'
	       , &{$_[$_] ne 'href' ? $_[$[] : $_[$[+1]}
	        ($_[$[+3], !ref($_[$_+1]) ? $_[$_+1] : strdata($_[$[+3], $_[$_+1]))
	      , '"') 
	    : ())
	  : eval{$c =$_[$_]; $v =$_[$_+1]; ()}
	  } map {$_*2+3} $[+1..int(($#_-3)/2) )
   ,(!defined($c)
     ? ' />'
     : $c eq '0'
     ? '>'
     :  ('>'
       ,  (ref($v) eq 'CODE') && ($v =&{$v}) && 0
	  ? ()
     	  : ref($v) eq 'ARRAY'
     	  ? &lsTag(@_[$[..$[+3], $v)
	  : defined($v)
	  ? &{$_[$[+2]}($_[$[+3], $v)
	  : ()
       , '</', $_[$[+4], '>') )
   )
 : ref($_[$[+4]) eq 'ARRAY'
 ? (map {ref($_) ne 'ARRAY' ? &{$_[$[+2]}($_[$[+3], $_) : lsTag(@_[$[..$[+3], @$_)} @{$_[$[+4]})
 : ref($_[$[+4]) eq 'HASH' && eval{$v =$_[$[+4]; $c =$v->{'-'}||$v->{'-tag'}||'tag'}
 ? ('<', $c
   ,(map {defined($v->{$_}) 
         ?(' '
	  , substr($_,0,1) eq '-' ? substr($_, 1) : $_, '="'
	  , &{$_ ne 'href' ? $_[$[] : $_[$[+1]}
	    ($_[$[+3], !ref($v->{$_}) ? $v->{$_} : strdata($_[$[+3], $v->{$_}))
          ,'"')
         :()
         } 
         sort grep {$_ && $_ !~/^-(tag|data|)$/} keys %$v)
   , (grep {exists($v->{$_}) && eval{$v =$v->{$_}}} '', '-data')
   ? ('>'
     ,(ref($v) eq 'CODE') && ($v =&{$v}) && 0
      ? ()
      : ref($v) eq 'ARRAY'
      ? &lsTag(@_[$[..$[+3], $v)
      : defined($v)
      ? &{$_[$[+2]}($_[$[+3], $v)
      : ()
     ,'</',$c,'>')
   : exists($v->{0})  
   ? '>'
   : ' />'
   )
 : ()
 ), !$n ? () : $n)
}


sub htlsTag {	# Attribute list to html strings list
 lsTag(\&htmlEscape, \&urlEscape, \&htmlEscape, @_)
}


sub xmlsTag {	# Attribute list to xml strings list
 lsTag(\&xmlAttrEscape, \&xmlAttrEscape, \&xmlTagEscape, @_)
}


sub utf8enc {	# Encode to UTF8, see also cptran()
	my $r =$_[1];
	if (($] >=5.008) && eval("use Encode; 1")) {
		# return($r) if Encode::is_utf8($r);
		my $cp =eval('!${^ENCODING}') && $_[0]->charpage();
		eval("use encoding '$cp', STDIN=>undef, STDOUT=>undef") if $cp;
		$r =Encode::encode_utf8($r);
		eval('no encoding') if $cp;
		return($r);
	}
	my $t =$LNG->{'utf8enc_' .($_[0]->{-lang}||'')};
	return($r) if !$t;
	&$t($r);
	$r;
}


sub utf8dec {	# Decode from UTF8, see also cptran()
	my $r =$_[1];
	if (($] >=5.008) && eval("use Encode; 1")) {
		my $cp =eval('!${^ENCODING}') && $_[0]->charpage();
		eval("use encoding '$cp', STDIN=>undef, STDOUT=>undef") if $cp;
		$r =Encode::decode_utf8($r,0);
		eval('no encoding')		if $cp;
		$r =Encode::encode($cp,$r,0)	if $cp;
		return($r);
	}
	my $t =$LNG->{'utf8dec_' .($_[0]->{-lang}||'')};
	return($r) if !$t;
	&$t($r);
	$r;
}



#########################################################
# Misc Utility methods
#########################################################


sub cgi {       # CGI object
 return($_[0]->{-cgi}) if $_[0]->{-cgi};
 if (!eval("use CGI (); 1") ||!eval("use CGI (); 1")) {
	my $e =$@ ||'undef';
	$_[0]->logRec('error',"use CGI -> $e");
	# eval('use CGI::Carp'); CGI::Carp::croak("use CGI -> $e\n");
	&{$_[0]->{-die}}("use CGI -> $e\n");
 }
 no warnings;	# consider also $CGI::Q - default CGI object - due to bugs
 $_[0]->{-cgi} =$CGI::Q =eval('local $^W =0; CGI->new()');
 if (!$_[0]->{-cgi}) {
	my $e =$@ ||'undef';
	$_[0]->logRec('error',"CGI::new() -> $e");
	# eval('use CGI::Carp'); CGI::Carp::croak("CGI::new() -> $e\n");
	&{$_[0]->{-die}}("CGI::new() -> $e\n");
 }
 if ($_[0]->{-cgi}->{'.cgi_error'}) {
	$_[0]->{-c}->{'.cgi_error'} =$_[0]->{-cgi}->{'.cgi_error'};
	$_[0]->logRec('error','CGI::new() -> ' .$_[0]->{-cgi}->{'.cgi_error'})
 }
 $CGI::XHTML =0;
 $CGI::USE_PARAM_SEMICOLONS =$HS eq ';' ? 1 : 0;
 if ((($ENV{SERVER_SOFTWARE}||'') =~/IIS/i)
 ||  ($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER})) {
	$CGI::NPH =1
 }
 if ($ENV{PERLXS}) {
 }
 if (($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/) {
 }
 $_[0]->{-cgi}
}


sub url {	# CGI script URL
 if ($#_ >0) {
	local $^W =0;
	my $v =($_[0]->{-cgi}||$_[0]->cgi)->url(@_[1..$#_]);
	if ($v) {}
	elsif (!($ENV{PERLXS} ||(($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/))) {}
	elsif (($#_ >2) ||(($#_ ==2) && !$_[2])) {}
	elsif ($_[1] eq '-relative') {
		$v =$ENV{SCRIPT_NAME};
		$v =$1 if $v =~/[\\\/]([^\\\/]+)$/;
	}
	elsif ($_[1] eq '-absolute') {
		$v =$ENV{SCRIPT_NAME}
	}
	return($v)
 }
 return($_[0]->{-c}->{-url})
	if $_[0]->{-c}->{-url};
 local $^W =0;
 $_[0]->{-c}->{-url} =$_[0]->cgi->url();
 if ($ENV{PERLXS} ||(($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/)) {
	$_[0]->{-c}->{-url} .=
		(($_[0]->{-c}->{-url} =~/\/$/) ||($ENV{SCRIPT_NAME} =~/^\//) ? '' : '/')
		.$ENV{SCRIPT_NAME}
		if ($_[0]->{-c}->{-url} !~/\w\/\w/) && $ENV{SCRIPT_NAME};
 }
 $_[0]->{-c}->{-url}
}


sub dbi {       # DBI connection object
 return ($_[0]->{-dbi}) if $_[0]->{-dbi};
 $_[0]->{-dbidsn} =ref($_[0]->{-dbiarg}) ? $_[0]->{-dbiarg}->[0] : $_[0]->{-dbiarg};
 $_[0]->{-dbi} =$_[0]->dbiConnect()
		|| &{$_[0]->{-die}}($_[0]->lng(0,'dbi') .": DBI::conect() -> failure\n");
 $_[0]->{-dbi}->{AutoCommit} =$_[0]->{-autocommit};
 if (!$_[0]->{-dbistart}) {
 }
 elsif (ref($_[0]->{-dbistart}) eq 'CODE') {
	&{$_[0]->{-dbistart}}(@_)
 }
 elsif (ref($_[0]->{-dbistart}) eq 'ARRAY') {
	foreach my $v (@{$_[0]->{-dbistart}}) {
		$_[0]->logRec('dbi',$v);
		eval{$_[0]->{-dbi}->do($v)};
		next if !$_[0]->{-dbi}->err;
		$_[0]->logRec($_[0]->lng(0,'Error'), $_[0]->{-dbi}->errstr);
	}
 }
 else {
	$_[0]->logRec('dbi',$_[0]->{-dbistart});
	eval{$_[0]->{-dbi}->do($_[0]->{-dbistart})};
	if ($_[0]->{-dbi}->err) {
		$_[0]->logRec($_[0]->lng(0,'Error'), $_[0]->{-dbi}->errstr);
	}
 }
 $_[0]->{-dbi}
}


sub dbiEng {	# DBI engine name
 if ($_[1]) {	# (? name ) -> match	| () -> dsn
	my $v =$_[1];
	($_[0]->{-dbidsn} || $_[0]->{Driver}->{Name}) =~/\bDBI:\Q$v\E\b/i
 }
 else {
	$_[0]->{-dbidsn} || $_[0]->{Driver}->{Name}
 }
}


sub dbiConnect {# DBI connecting with optional DBI:Proxy:hostname=127.0.0.1
 eval('use PerlEx::DBI') if $ENV{GATEWAY_INTERFACE} =~/PerlEx/;
 eval('use Apache::DBI') if $ENV{MOD_PERL};
 return(undef) if !eval("use DBI; 1;");
 my $c=ref($_[0]->{-dbiarg}) ? $_[0]->{-dbiarg}->[0] : $_[0]->{-dbiarg};
 if ($c =~/^DBI:Proxy:hostname=127\.0\.0\.1;/i) {
	# "dbi:Proxy:hostname=127.0.0.1;port=3334;proxy_no_finish=1;dsn=DBI:mysql:"
	# dbi->{Driver}->{Name} eq 'Proxy'
	my $i =2;
	my $r;
	while (!$r && $i) {
		$r =DBI->connect(ref($_[0]->{-dbiarg}) ? @{$_[0]->{-dbiarg}} : $_[0]->{-dbiarg});
		return($r) if $r;
		if (--$i) {
			my $h =$c=~/hostname=([^;]+)/ ? $1 : '';
			my $p =$c=~/port=([^;]+)/ ? $1 : '';
			my $x =$^X;	# \\?\D:\Share\B\Perl\bin\PerlIS.dll
			$x =$'			if $x =~/^\\\\\?\\/;
			$x =$` .'perl.exe'	if $x =~/(?:PerlIS|PerlEx)\d*\.dll$/i;
			my $a ="$x -e\"use DBI::ProxyServer; DBI::ProxyServer::main('--localaddr'=>'$h','--localport'=>'$p')\"";
			# '--mode'=>'single','--logfile'=>'STDERR','--debug'=>1
			# $_[0]->die($a);
			if ($^O eq 'MSWin32') {
				$_[0]->logRec("Win32::Process($x, $a)");
				eval('use Win32::Process');
				$Win32::Process::Create::ProcessObj =$Win32::Process::Create::ProcessObj;
				Win32::Process::Create($Win32::Process::Create::ProcessObj
				,$x
				,$a
				,0
				,&CREATE_NEW_CONSOLE
				,'.')
				||
				&{$_[0]->{-die}}("Win32::Process($x, $a) -> $! $^E\n");
			}
			elsif (1) {
				$_[0]->logRec("system($a)");
				system(1,$a)
				&& &{$_[0]->{-die}}("system($a) -> $!\n");
			}

		}
	}
	return($r)
 }
 (0 && $_[0]->{-autocommit}
 && (eval{DBI->connect_cached(ref($_[0]->{-dbiarg}) ? @{$_[0]->{-dbiarg}} : $_[0]->{-dbiarg})}))
 || (eval{DBI->connect(ref($_[0]->{-dbiarg}) ? @{$_[0]->{-dbiarg}} : $_[0]->{-dbiarg})})
}


sub dbiQuote {	# DBI quote string
 $_[0]->dbi->quote(@_[1..$#_])
}


sub dbiUnquote { # DBI unquote string
 return($_[1]) if !defined($_[1]);
 my ($q,$r) =$_[1] =~/^(['"])(.*)['"]$/ ? ($1, $2) : (undef, $_[1]);
 return($r) if !$q;
 my $q1 =substr($_[0]->dbi->quote($q),1,-1);
 $r =~s/\Q$q1\E/$q/eg;
 $q ='\\'; $q1 =substr($_[0]->dbi->quote($q),1,-1);
 $r =~s/\Q$q1\E/$q/eg if $q ne $q1;
 $r
}


sub dbiLikesc {	# DBI escape 'like'
 join('', map {my $v =$_; $v =~s/([\\%_])/\\$1/g; $v} @_[1..$#_])
}


sub hfNew {     # New file handle object
 local $SELF =$_[0];
 DBIx::Web::FileHandle->new(-parent=>$_[0]
	,@_ >2 ? (-mode=>$_[1], -name=>$_[2]) 
	:@_ >1 ? (-name=>$_[1])
	: ())
}


sub ccbNew {	# New condition code block object
 local $SELF =$_[0];
 DBIx::Web::ccbHandle->new($_[1])
}


sub dbmNew {	# New isam datafile object
 local $SELF =$_[0];
 DBIx::Web::dbmHandle->new(-parent=>$_[0], @_ >2 ? @_[1..$#_] : (-name=>$_[1]))
}


sub dbmTable {	# Get isam datafile object
 return(&{$_[0]->{-die}}('Bad table \'' .$_[1] .'\'' .$_[0]->{-ermd})) if !$_[1];
   $CACHE->{$_[0]}->{'-dbm/' .$_[1]}
||($CACHE->{$_[0]}->{'-dbm/' .$_[1]}
	=$_[0]->dbmNew(	 -name	=>$_[0]->pthForm('dbm'
				,( $_[0]->{-table}->{$_[1]} 
				&& $_[0]->{-table}->{$_[1]}->{-expr} 
				|| $_[1]))
			,-table	=>$_[0]->{-table}->{$_[1]}
			,-lock	=>LOCK_SH))->opent
}


sub dbmTableClose {	# Close isam datafile object if opened
 return(&{$_[0]->{-die}}('Bad table \'' .$_[1] .'\'' .$_[0]->{-ermd})) if !$_[1];
 if ($_[1] eq '*') {
	# $_[0]->logRec('dbmTableClose',$_[1]);
	foreach my $k (keys %{$CACHE->{$_[0]}}) {
		next if $k !~/^-dbm\//;
		dbmTableClose($_[0], $')
	}
	return($_[0])
 }
 return($_[0]) if !$CACHE->{$_[0]}->{'-dbm/' .$_[1]};
 # $_[0]->logRec('dbmTableClose',$_[1]);
 $CACHE->{$_[0]}->{'-dbm/' .$_[1]}->close();
 delete $CACHE->{$_[0]}->{'-dbm/' .$_[1]};
 $_[0]
}


sub dbmTableFlush {	# Reopen isam datafile object if opened
 return(&{$_[0]->{-die}}('Bad table \'' .$_[1] .'\'' .$_[0]->{-ermd})) if !$_[1];
 if ($_[1] eq '*') {
	# $_[0]->logRec('dbmTableFlush',$_[1]);
	foreach my $k (keys %{$CACHE->{$_[0]}}) {
		next if $k !~/^-dbm\//;
		dbmTableFlush($_[0], $')
	}
	return($_[0])
 }
 return($_[0]) if !$CACHE->{$_[0]}->{'-dbm/' .$_[1]};
 # $_[0]->logRec('dbmTableFlush',$_[1]);
 $CACHE->{$_[0]}->{'-dbm/' .$_[1]}->close();
 $CACHE->{$_[0]}->{'-dbm/' .$_[1]}->opent();
}



sub osCmd {     # OS Command
                # -'i'gnore retcode
  my $s   =shift;
  my $opt =substr($_[0],0,1) eq '-' ? shift : ''; 
  my $sub =ref($_[$#_]) eq 'CODE' ? pop : undef;
  my $r;
  my $o;
  local(*RDRFH, *WTRFH);
  $s->logRec('osCmd', @_);
  if (($^O eq 'MSWin32')	# !!! arguments may need to be quoted
   || ($^X =~/(?:perlis|perlex)\d*\.dll$/i)) {	# ISAPI, DB_File operation problem hacks
     if (!$sub) {
	if (($opt !~/h/)
	&& ($^X =~/(?:perlis|perlex)\d*\.dll$/i
		? $_[0] !~/^(?:xcopy|xcacls|cacls)/	# !!! problematic programs
		: 1)
		) {
		my $c =join(' ', @_) .' 2>&1';
		$o =[`$c`];
	}
	else {
		eval('Win32::SetChildShowWindow(0)') if $] >=5.008;
		if (system(@_) ==-1) {
			$o =[$!,$^E];
			$r =-1;
		}
		eval('Win32::SetChildShowWindow()') if $] >=5.008;
	}
     }
     else {			# !!! command's output will be lost
	open(WTRFH, '|-', join(' ', @_) .' >nul 2>&1') && defined(*WTRFH) 
	|| return(&{$_[0]->{-die}}(join(' ',$s->lng(0,'osCmd'),@_) .' -> ' .$! .$_[0]->{-ermd})||0);
	my $ls =select(); select(WTRFH); $| =1;
	&$sub($s) if $sub;
	select($ls);
	eval{close(WTRFH)};
     }
  }
  else {
     eval('use IPC::Open2');
     my $pid = IPC::Open2::open2(\*RDRFH, \*WTRFH, @_); 
     if ($pid) {
	if ($sub) {
		my $select =select();
		select(WTRFH);
		$| =1;
		&$sub($s);
		select($select);
	}
	$o =[<RDRFH>] if $opt !~/h/;
	waitpid($pid,0);
     }
     else {
	$o =[$!,$^E];
	$r =-1;
     }
  }
  $r =$?>>8 if !$r;
  if ($r && ($r >0) && ($opt =~/i/)) {
	if (!$o){$o =['exit ' .$r]}
	else	{push @$o, 'exit ' .$r}
  }
  return(&{$s->{-die}}(join(' ',$s->lng(0,'osCmd'),@_) 
	.(!$o ? ' ' : join("\n", ' -> ', @{$o||[]}, '')) 
	."-> $r" 
	.$s->{-ermd})||0) 
	if $r && $opt !~/i/;
  if ($o) {foreach my $e (@$o) {
	chomp($e);
	$s->logRec('osCmd',$e)
  }}
  !$r ? $o ||[] : undef
}


sub nfopens {	# opened files (`net file`)
		# (mask, ?container)
 return(undef) if $^O ne 'MSWin32';
 my $rc =$_[2]||[];
 my $mask =$_[1]||''; $mask =~s/\//\\/ig;
#[map {chomp($_); $_} map {/^\d+\s+(.+)\s+\d+[\n\r\s]*$/ ? $1 : $_} grep /^\d+\s*\Q$mask\E/i, `net file`]
 my $o =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); Win32::OLE->GetObject("WinNT://'
	.(eval{Win32::NodeName()}||$ENV{COMPUTERNAME}) .'/lanmanserver")');
 return(undef) if !$o;
 if (ref($rc) eq 'HASH') {
	%$rc =map {(substr($_->{Path}, length($mask)+1), $_->{User} .': ' .substr($_->{Path}, length($mask)+1))
		} grep {(eval{$_->{Path}}||'') =~/^\Q$mask\E/i
			} Win32::OLE::in($o->Resources());
	# %$rc =(1=>'1.1',2=>'2.1',3=>'3.1');
	$rc =undef if !%$rc
 }
 else {
	@$rc =map {eval{substr($_->{Path}, length($mask)+1)}
		} grep {(eval{$_->{Path}}||'') =~/^\Q$mask\E/i  # $_->GetInfo;
			} Win32::OLE::in($o->Resources());
	$rc =undef if !@$rc
 }
 $rc
}


sub nfclose {	# close opened files (`net file /close`)
		# (mask, [filelist])
 return(0) if $^O ne 'MSWin32';
 my $mask =$_[1]||''; $mask =~s/\//\\/ig;
 my $list =$_[2]||[];
 my $o =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); Win32::OLE->GetObject("WinNT://'
	.(eval{Win32::NodeName()}||$ENV{COMPUTERNAME}) .'/lanmanserver")');
 return(0) if !$o;
 foreach my $f (grep {$_ && (eval{$_->{Path}}||'')=~/^\Q$mask\E/i
			} Win32::OLE::in($o->Resources())) {
	my $n =eval{$f->{Path} =~/^\Q$mask\E[\\\/]*(.+)/i ? $1 : undef};
	next if !$n || !grep /^\Q$n\E$/i, @$list;
	$_[0]->osCmd('net','file',$f->{Name},'/close');
 }
 1
}


sub output {    # Output to user, like print, but redefinable
  (!$_[0]->{-output} ? print @_[1..$#_] : &{$_[0]->{-output}}(@_)) 
 && $_[0]
}


sub outhtm  {	# Output HTML tag
  output($_[0], htlsTag(@_))
}

sub outhtml {	# Output HTML tag
  output($_[0], htlsTag(@_))
}


sub outxml  {	# Output XML tag
  output($_[0], xmlsTag(@_))
}


sub smtp {	# SMTP object
		# (| undef | sub{})
 if	(!$_[0]->{-smtp}) {}
 elsif	((scalar(@_) >1) && !$_[1]) {
	$_[0]->{-smtp}->quit() if $_[0]->{-smtp};
	delete $_[0]->{-smtp};
 }
 elsif	($_[0]->{-smtp}) {
	if (ref($_[1])) {
		local $^W=undef;
		return(&{$_[1]}($_[0],$_[0]->{-smtp}));
	}
	return($_[0]->{-smtp}) if $_[0]->{-smtp};
 }
 $_[0]->{-smtp} =eval {
		local $^W=undef; 
		eval("use Net::SMTP"); 
		$_[0]->{-smtphost}
			? Net::SMTP->new($_[0]->{-smtphost})
			: CORE::die('name required')
	};
 return(&{$_[0]->{-die}}("SMTP host '" .$_[0]->{-smtphost} ."': $@\n")) 
	if !$_[0]->{-smtp} ||$@;
 return(&{$_[1]}($_[0],$_[0]->{-smtp})) if ref($_[1]);
 $_[0]->{-smtp};
}


sub smtpAdr {	# SMTP address translate
  ($_[1] =~/^([^\\]+)\\(.+)$/ 
	? $2 
	: $_[1])
 .((index($_[1],'@') <0) && $_[0]->{-smtpdomain}
	? '@' .$_[0]->{-smtpdomain}
	: '')
}


sub smtpAdrd {	# SMTP address displayable translate
 return($_[1]) if $_[1] =~/</;
 my $d =$_[0]->udisp($_[1]) ||$_[1];
 unless ($d =~s/<([^<>]+)>/'<' .$_[0]->smtpAdr($_[1]) .'>'/e) {
	$d .=' <' .$_[0]->smtpAdr($_[1]) .'>'
 }
 $d
}


sub smtpSend {	# SMTP mail msg send
 my ($s, %a) =@_;
 return($s) if !$s->{-smtphost};
 local $s->{-smtpdomain} =$s->{-smtpdomain} 
			|| ($s->{-smtphost} && $s->smtp(sub{$_[1]->domain()}))
			|| 'nothing.net';
 local $s->{-pcmd} =$s->{-pcmd} ||{};
 local $s->{-pcmd}->{-frame} =undef;
 $a{-from}	=$a{-from} ||$a{-sender} ||$s->user;
 $a{-from}	=&{$a{-from}}($s,\%a)	if ref($a{-from}) eq 'CODE';
 $a{-from}	=$s->smtpAdrd($a{-from});
 $a{-to}	=&{$a{-to}}($s,\%a)	if ref($a{-to}) eq 'CODE';
 $a{-to}	=[grep {$_} split /\s*[,;]\s*/, ($a{-to} =~/^\s*(.*)\s*$/ ? $1 : $a{-to})]
					if $a{-to} && !ref($a{-to}) && ($a{-to} =~/[,;]/);
 $a{-to}	=ref($a{-to}) 
			? [map {$s->smtpAdrd($_)} @{$a{-to}}]
			: $s->smtpAdrd($a{-to}) 
			if $a{-to};
 $a{-sender}	=$s->smtpAdr($a{-sender} ||$a{-from} ||$s->user);
 $a{-recipient}	=$a{-recipient} ||$a{-to};
 $a{-recipient}	=&{$a{-recipient}}($s,\%a) if ref($a{-recipient}) eq 'CODE';
 $a{-recipient}	=[grep {$_} split /\s*[,;]\s*/, ($a{-recipient} =~/^\s*(.*)\s*$/ ? $1 : $a{-recipient})]
					if $a{-recipient} && ref($a{-recipient}) && ($a{-recipient} =~/[,;]/);
 return($s)	if !$a{-recipient};
 $a{-recipient}	=ref($a{-recipient}) 
			? [map {$s->smtpAdr($_)} @{$a{-recipient}}]
			: $s->smtpAdr($a{-recipient});
 if (!defined($a{-data})) {
	my $koi =(($a{-charset}||$s->charset()) =~/1251/);
	$a{-subject} =    ref($a{-subject}) eq 'CODE'
			? &{$a{-subject}}($s,\%a)
			: ref($a{-subject})
			? join(' ', map {
				!defined($a{-pout}->{$_})
				? ()
				: ($a{-pout}->{$_})
				} @{$a{-subject}})
			: $a{-pout}
			? $s->mdeSubj($a{-pout})
			: ''
		if ref($a{-subject}) ||!defined($a{-subject});
	$a{-data}  ='';
	$a{-data} .='From: ' .($koi	? $s->cptran('ansi','koi',$a{-from}) 
					: $a{-from})
			."\cM\cJ";
	$a{-data} .='Subject: '
			.($koi
			? $s->cptran('ansi','koi',$a{-subject})
			: $a{-subject}) ."\cM\cJ";
	$a{-data} .='To: ' 
			.($koi	
			? $s->cptran('ansi','koi', ref($a{-to}) ? join(', ',@{$a{-to}}) : $a{-to}) 
			: (ref($a{-to}) ? join(', ',@{$a{-to}}) : $a{-to}))
			."\cM\cJ" 
			if $a{-to};
	$a{-data} .="MIME-Version: 1.0\cM\cJ";
	$a{-data} .='Content-type: '  .($a{-pout} ||$a{-html} ? 'text/html' : 'text/plain')
			.'; charset=' .($a{-charset}||$s->charset())
			."\cM\cJ";
	$a{-data} .='Content-Transfer-Encoding: ' .($a{-encoding} ||'8bit') ."\cM\cJ";
	$a{-data} .="\cM\cJ";
	if ($a{-pout}) {
		$a{-form} =$a{-form} || $a{-pcmd} && ($a{-pcmd}->{-form} ||$a{-pcmd}->{-table});
		$a{-data} .=do{	local $s->{-c}->{-httpheader} =1;
				# local $s->{-htmlstart} ={ref($s->{-htmlstart}) ? %{$s->{-htmlstart}} : (), -xbase=>$s->url};
				$s->htmlStart($a{-form})};
		$a{-data} .='<base href="'. $s->htmlEscape($s->url) .'" />' ."\n";
		local $s->{-output} =sub{$a{-data} .=join('',@_[1..$#_])};
		# local $a{-pout} ={%{$a{-pout}}}; # read-only supposed
		local $a{-pcmd} ={($a{-pcmd} ? %{$a{-pcmd}} : ())
				, -edit=>undef, -print=>1, -mail=>1
				, -cmd=>'recRead', -cmg=>'recRead'};
		local $s->{-pout} =$a{-pout};
		local $s->{-pcmd} =$a{-pcmd};
		$s->cgiForm($a{-form}
			, $a{-pcmd}->{-cmdf} ||$a{-pcmd}->{-cmdt}
			, $a{-pcmd}
			, $a{-pout}
			);
		$a{-data} .=$s->htmlEnd();
	}
	$a{-data} .=$a{-html} ||$a{-text} ||'';
	# $s->logRec('smtpSend',%a);
	# $s->logRec('smtpSend',$a{-data}); 
 }
 return($s) if !$s->{-smtphost};
 $s->logRec('smtpSend',$a{-recipient});
 local $^W=undef;
 $s->smtp->mail($a{-sender} =~/<\s*([^<>]+)\s*>/ ? $1 : $a{-sender})
	||return(&{$_[0]->{-die}}("SMTP sender \'" .$a{-sender} ."'" .$_[0]->{-ermd}));
 $s->smtp->to(ref($a{-recipient})
		? (map { $_ && /<\s*([^<>]+)\s*>/ ? $1 : $_ } @{$a{-recipient}})
		: $a{-recipient})
	||return(&{$_[0]->{-die}}("SMTP recipient \'" 
		.(ref($a{-recipient}) ? join(', ',$a{-recipient}) : $a{-recipient}) ."'" .$_[0]->{-ermd}));
 $s->smtp->data($a{-data})
	||return(&{$_[0]->{-die}}("SMTP data \'" .$a{-data} ."'" .$_[0]->{-ermd}));
 $s->smtp->dataend()
	||return(&{$_[0]->{-die}}("SMTP dataend" .$_[0]->{-ermd}));
 $s;
}



#########################################################
# Filesystem methods
#########################################################


sub pthForm {  # Form filesystem path for 'tmp'|'log'|'var'|'dbm'|'rfa'
 join('/', $_[0]->{-c}->{'-pth_' .$_[1]} ||pthForm_(@_), @_[2..$#_]);
}


sub pthForm_{
 my $p =($_[0]->{-c}->{'-pth_' .$_[1]} 
       =($_[1] eq 'tmp' && ($ENV{TMP} ||$ENV{tmp} ||$ENV{TEMP} ||$ENV{temp}))
	||($_[0]->{-cgibus} && ($_[1] eq 'rfa') && $_[0]->{-cgibus})
	||join('/', $_[0]->{-path}, $_[1]));
 if (!-d $p) {
	$_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
	$_[0]->pthMk($p);
	$_[0]->hfNew('+>', "$p/.htaccess")->lock(LOCK_EX)
		->store("<Files * >\nOrder Deny,Allow\nDeny from All\n</Files>\n")
		->destroy
		if $_[1] ne 'rfa';
	if ($ENV{OS} && $ENV{OS}=~/Windows_NT/i) {
		$p =~s/\//\\/g;
		$_[0]->osCmd($_[0]->{-w32xcacls} ? 'xcacls' : 'cacls'
		,"\"$p\""
		,'/T','/C'
		,'/E'		# for 'rfa' or late $_[0]->{-w32IISdpsn}
		,'/G'
		,(map{(m/([^@]+)\@([^@]+)/ ? "$2\\$1" : $_) .':F'
			} ref($_[0]->{-fswtr}) 
			? (@{$_[0]->{-fswtr}}) 
			: ($_[0]->{-fswtr}||eval{Win32::LoginName()}))
		,$_[0]->{-w32xcacls}
		? '/Y'
		: sub{CORE::print "Y\n"})
	}
 }
 $_[0]->{-c}->{'-pth_' .$_[1]}
}


sub pthMk {    # Create directory if needed
  return(1) if -d $_[1];
  return(&{$_[0]->{-die}}($_[0]->lng(0,'pthMk') .": mkdir('" .$_[1] ."')" .$_[0]->{-ermd})||0)
	if ref($_[1]);
  my $m =$_[1] =~/([\\\/])/ ? $1 : '/';
  my ($a, $v) =$_[1] =~/^([\\\/]+[^\\\/]+[\\\/]|\w:[\\\/]+)(.+)/ ? ($1, $2) : ('', $_[1]);
  foreach my $e (split /[\\\/]/, $v) {
     $a .=$e;
     if (!-d $a) {
	$_[0]->logRec('mkdir', $a) if !$_[0]->{-log} ||ref($_[0]->{-log});
        mkdir($a, 0777) ||return(&{$_[0]->{-die}}($_[0]->lng(0,'pthMk') .": mkdir('$a') -> $!" .$_[0]->{-ermd})||0);
     }
     $a .=$m
  }
  2;
}


sub pthGlob {  # Glob directory
  my $s =shift;
  my @ret;
  if    (0 && ($^O ne 'MSWin32')) {
     CORE::glob(@_)
  }
  elsif (-e $_[0]) {
     push @ret, $_[0];
     @ret
  }
  else {
     my $msk =($_[0] =~/([^\/\\]+)$/i ? $1 : '');
     my $pth =substr($_[0],0,-length($msk));
     $msk =~s/\*\.\*/*/g;
     $msk =~s:(\(\)[].+^\-\${}[|]):\\$1:g;
     $msk =~s/\*/.*/g;
     $msk =~s/\?/.?/g;
     local (*DIR, $_); 
     opendir(DIR, $pth eq '' ? './' : $pth) 
           || return(&{$s->{-die}}($s->lng(0,'pthGlob') .": opendir('$pth') -> $! ($^E)" .$s->{-ermd})||0);
     while(defined($_ =readdir(DIR))) {
       next if $_ eq '.' || $_ eq '..' || $_ !~/^$msk$/i;
       push @ret, "${pth}$_";
     }
     closedir(DIR) || return(&{$s->{-die}}($s->lng(0,'pthGlob') .": closedir('$pth') -> $!" .$s->{-ermd})||0);
     @ret
  }
}


sub pthGlobn { # Glob filenames only
 map {$_ =~/[\\\/]([^\\\/]+)$/ ? $1 : $_} shift->pthGlob(@_)
}


sub pthGlobns {	# Glob filenames sorted
	use locale;
	map {$_ =~/[\\\/]([^\\\/]+)$/ ? $1 : $_
		} sort {  (-d $a) && (!-d $b)
			? -1
			: (!-d $a) && (-d $b)
			? 1
			: lc($a) cmp lc($b)
			} $_[0]->pthGlob(@_[1..$#_])
}


sub pthRm {    # Remove filesystem path
               # '-r' - recurse subdirectories, 'i'gnore errors
  my $s   =shift;
  my $opt =$_[0] =~/^\-/ || $_[0] eq '' ? shift : '';
  my $ret =1;
  $s->logRec('pthRm',$opt,@_);
  foreach my $par (@_) {
    foreach my $e ($s->pthGlob($par)) {
      if (-d $e) {
         if ($opt =~/r/i && !$s->pthRm($opt,"$e/*")) {
               $ret =0
         }
         elsif (!rmdir($e)) {
               $ret =0;
               $opt =~/i/i || return(&{$_[0]->{-die}}($s->lng(0, 'pthRm') .": rmdir('$e') -> $!" .$_[0]->{-ermd})||0);
         }
      }
      elsif (-f $e && !unlink($e)) {
            $ret =0;
            $opt =~/i/i || return(&{$_[0]->{-die}}($s->lng(0, 'pthRm') .": unlink('$e') -> $!" .$s->{-ermd})||0);
      }
    }
  }
  $ret
}


sub pthCln {   # Clean unused (empty) directory
  return(0) if !-d $_[1];
  my ($s, $d) =@_;
  my @g =$s->pthGlob("$d/*");
  return(0) if scalar(@g) >1 
            || scalar(@g) ==1 && $g[0] !~/\.htaccess$/i;
  foreach my $f (@g) { unlink($f) };
  while ($d && rmdir($d)) { $d =($d =~m/^(.+)[\\\/][^\\\/]+$/ ? $1 : '') };
  !-d $d
}


sub pthStamp {	# Stamp filesystem path with system ACL, once
 return($_[1]) if $^O ne 'MSWin32';
 my ($s, $p) =@_;
 $p =~s/\//\\/g;
 return($p) if lc($s->{-c}->{-pthStamp} ||'') eq lc($p);
 if (1 || $s->{-c}->{-RevertToSelf}) {	# ownership
	eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0);');
	$s->logRec('TakeOwnerShip', 'winmgmts:Win32_Directory.Name', $p);
	my $ow =Win32::OLE->GetObject("winmgmts:{impersonationLevel=Impersonate}!root/CIMV2:Win32_Directory.Name='$p'");
	$s->logRec("Error Win32::OLE::GetObject() -> " .Win32::OLE->LastError())
		if !$ow;
	$ow =$ow && $ow->TakeOwnerShip();
	$s->logRec("Error TakeOwnerShip() -> $ow")
		if $ow;
 }
 $s->osCmd($s->{-w32xcacls} ? 'xcacls' : 'cacls'
	, "\"$p\"", '/T','/C','/G'
	,(map { $_ =~/\s/ ? "\"$_\"" : $_
		} map{(m/([^@]+)\@([^@]+)/ ? "$2\\$1" : $_) .':F'
			} ref($s->{-fswtr}) ? (@{$s->{-fswtr}}) : ($s->{-fswtr} ||eval{Win32::LoginName()}))
	,$s->{-fsrdr}
	?(map { $_ =~/\s/ ? "\"$_\"" : $_
		} map{(m/([^@]+)\@([^@]+)/ ? "$2\\$1" : $_) .':R'
			} ref($s->{-fsrdr}) ? (@{$s->{-fsrdr}}) : ($s->{-fsrdr}))
	:()
	,$s->{-w32xcacls}
	? '/Y'
	: sub{CORE::print "Y\n"});
 $s->{-c}->{-pthStamp} =lc($p);
 $p
}


sub pthCp {	# Copy filesystem path
		# -'d'irectory or '*' glob hint; 'r'ecurse subdirectories, 
		# 'i'gnore errors, 'p'ermission stamp
		# file -> file # file -> dir/file # dir -> dir/dir # dir/*  -> dir
 my ($s, $opt, $src, $dst) =defined($_[1]) && ($_[1] =~/^-/) ? @_ : ($_[0], '', @_[1..$#_]);
 my $mc =($src =~/([\\\/])/) || ($dst =~/([\\\/])/) ? $1 : '/';
 my $r  =1;
 $s->logRec('pthCp',$opt,$src,$dst);
 if ($opt !~/d/i) {}
 elsif ($opt !~/i/i) {
	$s->pthMk($dst)
 }
 elsif (!eval{$s->pthMk($dst)}) {
	$s->logRec('Warn',$s->lng(0, 'pthCp') .": $@");
	return(0)
 }
 if (-f $src) {
	my $d1 =($opt =~/d/i) || (-d $dst)
		? $dst .$mc .($src =~/[\\\/]([^\\\/]+)$/ ? $1 : $src)
		: $dst;
	unlink($d1) if (-e $d1);
	if ($^O eq 'MSWin32'
		? Win32::CopyFile($src, $d1, 1)
		: (eval('use File::Copy (); 1') && File::Copy::syscopy($src, $d1))
		) {}
	elsif ($opt =~/i/) {
		$r =0;
		$s->logRec('Warn', $s->lng(0, 'pthCp') .": FileCopy('$src', '$d1') -> $!")
	}
	else {
		return(&{$s->{-die}}($s->lng(0, 'pthCp') .": FileCopy('$src', '$d1') -> $!" .$s->{-ermd})||0)
	}
	return($r);
 }
 if (($opt =~/p/i) && ($opt =~/d/i)) {
	$s->pthStamp($dst);
 }
 foreach my $s1 ($s->pthGlob(($opt =~/\*/)
			&& !(($src =~/([^\\\/]+)$/) && ($1 =~/\*/))
		? $src .$mc .'*' 
		: $src)) {
	my $d1 =$dst .$mc .($s1 =~/[\\\/]([^\\\/]+)$/ ? $1 : $s1);
	if (-d $s1) {
		next if $opt !~/r/i;
		$r =0 if !$s->pthCp('-rd*' .($opt =~/i/i ? 'i' : ''), $s1, $d1);
	}
	else {
		# $s->logRec('copy',$s1,$d1);
		unlink($d1) if -e $d1;
		if ($^O eq 'MSWin32'
			? Win32::CopyFile($s1, $d1, 1)
			: (eval('use File::Copy (); 1') && File::Copy::syscopy($s1, $d1))) {
		}
		elsif ($opt =~/i/) {
			$r =0;
			$s->logRec('Warn',$s->lng(0, 'pthCp') .": FileCopy('$src', '$d1') -> $!")
		}
		else {
			return(&{$s->{-die}}($s->lng(0, 'pthCp') .": FileCopy('$src', '$d1') -> $!" .$s->{-ermd})||0)
		}
	}
 }
 $r
}



#########################################################
# Variables & Logging Methods
#########################################################


sub varFile {   # Common variables filename
 $_[0]->pthForm('var','var.pl');
}


sub varLoad {   # Load common variables
 my ($s, $lck) =@_;
 return($s->{-var}) if $s->{-var} && !$lck;
 $s->{-var}->{'_handle'}->destroy if $s->{-var} && $s->{-var}->{'_handle'};
 $s->{-var} =undef;
 my $fn =$s->varFile;
 my $hf;
 if (!-f $fn) {
    $s->{-var} ={'id'=>'DBIx-Web-variables'};
    $s->varStore();
 }
 # $s->logRec('varLoad', $lck ? ($lck) : (LOCK_SH, $lck));
 $hf =$s->hfNew('+<',$fn)->lock($lck||LOCK_SH);
 $s->{-var} =$hf->{-buf} =$hf->load && $s->dsdParse($hf->{-buf});
 $s->{-var}->{'_handle'} =$hf;
 if (!$lck) {
	# $hf->lock(LOCK_UN |LOCK_NB);
	# $hf->close();		# auto LOCK_UN, auto reopen
	$hf->destroy(); delete $s->{-var}->{'_handle'};
 }
 $s
}


sub varLock  {	# Lock common variables file
 if (!$_[0]->{-var} ||!$_[0]->{-var}->{'_handle'}) {
	$_[0]->varLoad($_[1] ||LOCK_EX)
 }
 elsif ((($_[1] ||LOCK_EX) eq LOCK_EX)
 &&	(($_[0]->{-var}->{'_handle'}->{-lock} ||0) ne LOCK_EX)	){
	$_[0]->varLoad($_[1] ||LOCK_EX)
 }
 else {
	# $_[0]->logRec('varLock',$_[1] ||LOCK_EX);
	$_[0]->{-var}->{'_handle'}->lock($_[1] ||LOCK_EX)
 }
}


sub varStore {  # Store common variables
 my $s  =shift;
 my $hf = !$s->{-var} ||!$s->{-var}->{'_handle'}
        ? $s->hfNew('+>',$s->varFile) 
        : $s->{-var}->{'_handle'};
 delete($s->{-var}->{'_handle'});

 $hf->lock(LOCK_EX)->store($s->dsdMk($s->{-var}))->close();

 $hf->{-buf} =$s->{-var};
 $s->{-var}->{'_handle'} =$hf;
 $s
}


sub logOpen {   # Log File open
 return($_[0]->{-log}) if ref($_[0]->{-log});
 my $fn =$_[0]->pthForm('log','cmdlog.txt');
 $_[0]->{-log} =$_[0]->hfNew('+>>', $fn);
 $_[0]->{-log}->select(sub{$|=1});
 $_[0]->{-log}
}


sub logLock {   # Log File lock
 $_[0]->logOpen if !ref($_[0]->{-log});
 $_[0]->{-log}->lock(@_[1..$#_]);
}


sub logRec {    # Add record to log file
 return(1) if !$_[0]->{-log} && !$_[0]->{-logm};
 $_[0]->logOpen() if $_[0]->{-log} && !ref($_[0]->{-log});
 $_[0]->{-log}->print(strtime($_[0]),"\t"
 	,$_[0]->{-c} && $_[0]->{-c}->{-user} ||'unknown'
 	,"\t",logEsc($_[0],@_[1..$#_]),"\n") if $_[0]->{-log};
 $_[0]->{-c}->{-logm} =[] if $_[0]->{-logm} && !$_[0]->{-c}->{-logm};
 splice @{$_[0]->{-c}->{-logm}}, 2, 2, '...' if $_[0]->{-logm} && scalar(@{$_[0]->{-c}->{-logm}}) >$_[0]->{-logm};
 push @{$_[0]->{-c}->{-logm}}, $_[0]->logEsc('(' 
	.($TW32
	? (Win32::GetTickCount() -$TW32)/1000
	: (time()-$^T))
	.') '. $_[1], @_[2..$#_]) if $_[0]->{-logm};
 1
}


sub logEsc {	# Escape list for logging
 my $s =$_[0];
 my $b =" ";
 my $r =$_[1] .$b;
 for (my $i=2; $i <=$#_; $i++) {
	my $v =$_[$i];
	$r .=	( !defined($v)
		? 'undef,'
		: ref($v) eq 'ARRAY'
		? '[' .join(', '
			,map {strquot($s, $_);
			} @$v) .'],'
		: isa($v,'HASH')
		? '{' .join(', '
			,map {(defined($_) && $_ =~/^-\w+[\d\w]*$/
				? $_
				: strquot($s, $_)) .'=>' .strquot($s, $v->{$_})
			} sort keys %$v) .'},'
		: $v =~/^\d+$/
		? $v .','
		: $v =~/^-\w+[\d\w]*$/
		? $v .'=>'
		: ($i ==2) &&($_[1] =~/^dbi/)
		&&($v =~/^(?:select|insert|update|delete|drop|commit|rollback|fetch)\s+/i)
		? $v .';'
		: ($i ==2) &&($_[1] =~/^dbi/) &&($v =~/^(?:keDel|kePut|affected|single|fetch)\b/i)
		? $v
		: (strquot($s, $v) .',')) .$b
 }
 $r =~/^(.+?)[\s,;=>]*$/ ? $1 : $r
}



#########################################################
# User & Group names methods
#########################################################


sub user {	# current user name
 return($_[0]->{-userln} ? userln(@_) : $_[0]->{-c}->{-user})
	if $_[0]->{-c}->{-user};
 $_[0]->{-c}->{-user} =
   $_[0]->{-user}   ? (ref($_[0]->{-user}) ? &{$_[0]->{-user}}(@_) : $_[0]->{-user})
 : $_[0]->{-unames} ? $_[0]->unames->[0]
 : $_[0]->{-tn}->{-guest};
 $_[0]->{-c}->{-user} =
	$_[0]->{-usernt}
	? ($_[0]->{-c}->{-user} =~/^([^\@]+)\@(.+)$/ ? $2 .'\\' .$1 : $_[0]->{-c}->{-user})
	: ($_[0]->{-c}->{-user} =~/^([^\\]+)\\(.+)$/ ? $2 .'@'  .$1 : $_[0]->{-c}->{-user});
#$_[0]->logRec('user', $_[0]->{-c}->{-user});
 $_[0]->{-userln} ? userln(@_) : $_[0]->{-c}->{-user}
}


sub userln {	# current user local name
 return($_[0]->{-c}->{-userln})        if $_[0]->{-c}->{-userln};
 my $s =$_[0];
 my $un=$s->{-c}->{-user} ||$s->user();
 my ($d, $u) =	  $un =~/^([^\\]+)\\(.+)$/ ? ($1, $2)
		: $un =~/^([^\@]+)\@(.+)$/ ? ($2, $1)
		: ('', $un);
 $s->{-c}->{-userln} =
	  !$d
	? $u
	: $^O eq 'MSWin32' && lc($d) eq lc($s->w32domain())
	? $u
	: eval('use Sys::Hostname; Sys::Hostname::hostname()') =~/\Q$d\E$/i
	? $u
	: $un
}


sub uguest {	# is current user a guest
 lc($_[0]->user()) eq lc($_[0]->{-tn}->{-guest})
}


sub unames {	# current user names
 return($_[0]->{-c}->{-unames})        if $_[0]->{-c}->{-unames};
 $_[0]->{-c}->{-unames} =
   $_[0]->{-unames} ? (ref($_[0]->{-unames}) ? &{$_[0]->{-unames}}(@_) : $_[0]->{-unames})
 : $_[0]->{-user}   ? [$_[0]->user()
			, !defined($_[0]->{-usernt})
			  && ($_[0]->user() =~/^([^\\@]+)([\\@])([^\\@]+)$/)
				? ($2 eq '@'	? "$3\\$1"
						: "$3\@$1")
				: ()
			, $_[0]->user() ne $_[0]->userln()
				? ($_[0]->userln())
				: ()
			]		
 : [$_[0]->{-tn}->{-guest}];
 $_[0]->logRec('unames', $_[0]->{-c}->{-unames});
 $_[0]->{-c}->{-unames}
}


sub ugroups {	# user groups
		# (self, ?user) -> [user's groups]
 return($_[0]->{-c}->{-ugroups})
	if !$_[1] && $_[0]->{-c}->{-ugroups};
 return($_[0]->{-c}->{-ugroups} =ref($_[0]->{-ugroups}) eq 'CODE'
		? &{$_[0]->{-ugroups}}(@_)
		: $_[0]->{-ugroups})
	if $_[0]->{-ugroups};
 my $s =$_[0];
 my $un=$_[1] ||$s->user();
 my $ul=$_[1] ||$s->userln();
 my $ug=$CACHE->{-ugroups}->{$un};
    if ($ug) {
	$s->logRec('ugroups', $un, 'cache', $ug);
	return($ug);
    }
 my $fn=undef;
 my $rs='';
 my $rl='';
 if	(($fn =$s->{-AuthGroupFile}
		|| $s->{-PlainGroupFile}
		|| ((	   ($s->{-ldap} && $s->ugfile('ugf_ldap'))
			|| ($s->{-w32ldap} && $s->ugfile('ugf_w32ldap'))
			|| (($^O eq 'MSWin32') && $s->ugfile('ugf_w32'))
			) && $s->pthForm('var','uagroup') )
	) && -f $fn) {
	my $fh=$s->hfNew('<', $fn)->lock(LOCK_SH);
	$ug =[];
	while(my $r =$fh->readline()) {
		next if $r !~/[:\s](?:\Q$un\E|\Q$ul\E)(?:\s|\Z)/i;
		next if $r !~/^([^:]+):/;
		push @$ug, $1
	}
	$fh->close();
	$ug =undef if !@$ug;
 }
 elsif	(0	# lost code, for example
	&& $s->{-ldap}) {
	$ug =$s->ldapUgroups($un);
	$ug =undef if $ug && !@$ug;
 }
 if ($ug) {
	$rl ='file';
	$un =($rs =~/^([^:]+):/ ? $1 : $rs) if $rs;	# !!! not used
 }
 else {
	$rl ='default';
	$ug =$s->{-ugadd}
		? []
		: [$s->{-tn}->{-guests}, $s->uguest ? () : ($s->{-tn}->{-users})];
 }
 if (!defined($s->{-usernt})) {
 }
 elsif ($s->{-usernt}) {
	$ug =[map {$_ =~/\@/ ? () : $_
			} @$ug]
 }
 else {
	$ug =[map {$_ =~/\\/ ? () : $_
			} @$ug]
 }
 if ($s->{-ugflt}) {
	my $fg =$s->{-ugflt};
	$ug =[map {&$fg($s,$_) ? ($_) : ()
			} @$ug]
 }
 if ($s->{-ugadd}) {
	local $_ =$ug;
	my $ugadd=ref($s->{-ugadd}) eq 'CODE' ? &{$s->{-ugadd}}($s) : $s->{-ugadd};
	foreach my $e (	  ref($ugadd) eq 'ARRAY'
			? @{$ugadd}
			: ref($ugadd) eq 'HASH'
			? keys(%$ugadd)
			: $ugadd){
		push @$ug, $e 
			if defined($e)
			&& !grep /^\Q$e\E$/i, @$ug;
	}
 }
 if ($s->{-ugflt1}) {
	local $_ =$un;
	&{$s->{-ugflt1}}($s, $un, $ul, $ug);
 }
 $s->logRec('ugroups', $un, $rl, $ug) if $rl;
 $s->{-c}->{-ugroups} =$ug if !$_[1];
 if (1 || ($ENV{MOD_PERL} || (($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/))) {
	$CACHE->{-ugroups} ={} if !$CACHE->{-ugroups};
	$CACHE->{-ugroups} ={} if %{$CACHE->{-ugroups}} >200;
	$CACHE->{-ugroups}->{$un} =$ug;
 }
 $ug
}


sub ugnames {	# current user and group names
		# (self, ?user) -> [user's names]
 if ($_[1]) {
	# return([$_[1]]);
	local $_[0]->{-userln}		=0;
	local $_[0]->{-c}->{-user}	=$_[1];
	local $_[0]->{-c}->{-userln}	=undef;
	local $_[0]->{-c}->{-ugroups}	=undef;
	local $_[0]->{-c}->{-unames}	=undef;
	local $_[0]->{-c}->{-ugrexp}	=undef;
	local $_[0]->{-c}->{-ugnames}	=undef;
	my $r =$_[0]->ugnames();
	return($r)
 }
 elsif ($_[0]->{-c}->{-ugnames}) {
	return($_[0]->{-c}->{-ugnames})
 }
 $_[0]->{-c}->{-ugnames} =[map {$_} @{$_[0]->unames()}, map {$_} @{$_[0]->ugroups()}]
}


sub ugrexp {	# current user and group names regexp source
 return($_[0]->{-c}->{-ugrexp}) if $_[0]->{-c}->{-ugrexp};
 my $n =join('|', @{$_[0]->ugnames()}); $n =~s/([\\.?*\$\@])/\\$1/g;
 $_[0]->{-c}->{-ugrexp} =eval('sub{(($_[0]=~/(?:^|,|;)\\s*(' .$n .')\\s*(?:,|;|$)/i) && $1)}')
}


sub ugmember {	# user group membership
 my $e =$_[0]->{-c}->{-ugrexp} ||ugrexp($_[0]);
 foreach my $i (@_[1..$#_]) {
	if (ref($i))	{foreach my $j (@$i) {defined($j) && &$e($j) && return(1)}}
	else		{defined($i) && &$e($i) && return(1)}
 }
 undef
}


sub uadmin {	# user admin groups membership
 uadmwtr(@_)
}


sub uadmwtr {	# user admin writer groups membership
 return($_[0]->{-c}->{-uadmwtr}) if exists($_[0]->{-c}->{-uadmwtr});
 $_[0]->{-c}->{-uadmwtr} =$_[0]->{-racAdmWtr} && ugmember($_[0], $_[0]->{-racAdmWtr})
}


sub uadmrdr {	# user admin reader groups membership
 return($_[0]->{-c}->{-uadmrdr}) if exists($_[0]->{-c}->{-uadmrdr});
 $_[0]->{-c}->{-uadmrdr} =$_[0]->{-racAdmRdr} && ugmember($_[0], $_[0]->{-racAdmRdr})
}


sub uglist {	# User & Group List
 my $s =shift;	# self, '-ug<>dc@', ?user|group|filter, ?container
 my $o =defined($_[0]) && substr($_[0],0,1) eq '-' ? shift : '-ug';
 my $fc=ref($_[0]) eq 'CODE' ? shift : undef;
 my $fm=ref($_[0]) ? undef : $_[0] && $o !~/u/ ? [map {lc($_)} @{$s->ugroups(shift)}] : shift;
 my $fg=$s->{-ugflt};
 my $fu=$s->{-unflt};
 my $r =shift ||[];
 my $fn=undef;
 local $_;
 if	($s->{-uglist}) {
	$r =&{$s->{-uglist}}($s, $o, $r)
 }
 elsif	($s->{-AuthUserFile} ||$s->{-AuthGroupFile}) {
	my @r;
	my $en;
	$fn =$s->{-AuthGroupFile};
	if ($fm && !ref($fm) && -f $fn) {
		my $fh=$s->hfNew('<', $fn)->lock(LOCK_SH);
		while(my $r =$fh->readline()) {
			next if $r !~/^\Q$fm\E:/i;
			$r =$'; chomp($r);
			$fm =[map {lc($_)} split /[\t]+/, $r];
			last;
		}
		$fh->close();
		return($r) if !ref($fm) || !@$fm;
	}
	$fm =undef if $fm && (!ref($fm) || !@$fm);
	$fn =$s->{-AuthUserFile};
	if ($o =~/u/ && $fn && -f $fn) {
		my $fh=$s->hfNew('<', $fn)->lock(LOCK_SH);
		while(my $r =$fh->readline()) {
			next if $r !~/^([^:]+):/;
			$en =$_ =$1;
			next	if $fu && !&$fu($s,$en)
				|| $fc && !&$fc($s,$en);
			if	($fm) {
				my($el, $rl) =(lc($en), undef);
				foreach my $e (@$fm) {if ($el eq $e) {$rl =$el; last}};
				next if !$rl;
			}
			push @r, $en;
		}
		$fh->close()
	}
	$fn =$s->{-AuthGroupFile};
	if ($o =~/g/ && $fn && -f $fn) {
		my $fh=$s->hfNew('<', $fn)->lock(LOCK_SH);
		while(my $r =$fh->readline()) {
			next if $r !~/^([^:]+):/;
			$en =$_ =$1;
			next	if $fg && !&$fg($s,$en)
				|| $fc && !&$fc($s,$en);
			if	($fm) {
				my($el, $rl) =(lc($en), undef);
				foreach my $e (@$fm) {if ($el eq $e) {$rl =$el; last}};
				next if !$rl;
			}
			push @r, $en;
		}
		$fh->close()
	}
	$r =ref($r) eq 'HASH'
		? {map {($_ => $_)} @r}
		: [@r]
 }
 elsif	((
	$s->{-PlainUserFile}
	||($s->{-ldap} && $s->ugfile('ugf_ldap'))
	||($s->{-w32ldap} && $s->ugfile('ugf_w32ldap'))
	||($^O eq 'MSWin32' && $s->ugfile('ugf_w32'))
	)
	&& ($fn =$s->{-PlainUserFile} ||$s->pthForm('var','ualist')) && -f $fn) {
	my $dn=!$s->{-userln}
		&& (!($s->{-ldap}) && ($^O eq 'MSWin32') && $s->w32domain());
		# see ugfile() for domain name qualifications
	if ($fm && !ref($fm)) {
		my $fn=$s->{-PlainGroupFile} ||$s->pthForm('var','uagroup');
		my $vn=!$dn
			? $fm
			: $fm =~/^\Q$dn\E\\/i
			? $'
			: $fm =~/\@\Q$dn\E$/i
			? $`
			: $fm;
		if (-f $fn) {
			my $fh=$s->hfNew('<', $fn)->lock(LOCK_SH);
			while(my $rr =$fh->readline()) {
				next if $rr !~/^\Q$vn\E:/i;
				$rr =$'; chomp($rr);
				$fm =[map {lc($_)} split /[\t]+/, $rr];
				last;
			}
			$fh->close()
		}
		return($r) if !ref($fm) || !scalar(@$fm);
	}
	my $fh=$s->hfNew('<', $fn)->lock(LOCK_SH);
	while(my $rr =$fh->readline()) {
		my ($en, $ef, $ep, $ec, $ed, $em, $ei)
			=(split /\t*:\t+/, $rr); #[0,1,2,3,4,5,6];
		# name, fullname, path, class, display, email, description
		if	($fc) {next if !&$fc($s, $en, $ef, $ep, $ed, $em, $ei)}
		elsif	($fm) {
			my($el, $rl) =(lc($en), undef);
			foreach my $e (@$fm) {if ($el eq $e) {$rl =$el; last}};
			next if !$rl;
		}
		$en =$s->{-usernt}
			? ($en =~/[\\]/ ? $en : $en =~/^([^\@]+)\@([^\@]+)$/ ? "$2\\$1" : $dn && ($ef=~/\@/) ? "$dn\\$en" : $en)
			: ($en =~/[@]/  ? $en : $en =~/^([^\\]+)\\([^\\]+)$/ ? "$2\@$1" : $dn && ($ef=~/\@/) ? "$en\@$dn" : $en);
		my $ev =($en =~/[\@\\]/ && $o !~/[<>]/ ? $ef : $en);
		$en =lc($en) if $o =~/d/;
		$_ =$en;
		if ($o =~/g/ && $ec =~/^g/i) {
			next if $fg && !&$fg($s, $en, $ef, $ep, $ed, $em, $ei);
			if (ref($r) eq 'ARRAY') {
				push(@$r, $en)
			}
			elsif ($o =~/\@/) {
				if ($em) {
					$r->{lc $en} =$em
				}
				elsif (($o =~/c/) && $ei && ($ei =~/\b([\w\d_+-]+\@[\w\d.]+)\b/)) {
					$r->{lc $en} =$1
				}
			}
			elsif ($ed) {
				$r->{$en} =
					  $o =~/d/
					? $ed
					: ($ed.' <' .$ev .'>')
			}
			else {
				$ed =$ei ||$ef if !$ed;
				$r->{$en} =
					  !$ed
					? $ev
					: $ed =~/^\Q$en\E\s*([,.-:]*)\s*(.*)/i
					? $ev .(!$2 || ($o =~/d/) 
						? '' 
						: (($1 ? " $1 " : ' - ') .$2))
					: ($o =~/d/) && ($o =~/c/)
					? $ed
					: $o =~/[<>]/
					? (length($ed)+length($ev)+3 >60 
						? substr($ed, 0, 60 -length($ev)-6) .'...' 
						: $ed) 
					  .' <' .$ev .'>'
					: "$ev, $ed";
				$r->{$en} =substr($r->{$en},0,60-3) .'...'
					if length($r->{$en}) >60 -3;
			}
		}
		if ($o =~/u/ && $ec =~/^u/i) {
			next if $fu && !&$fu($s, $en, $ef, $ep, $ed, $em, $ei);
			if (ref($r) eq 'ARRAY') {
				push(@$r, $en)
			}
			elsif ($o =~/\@/) {
				if ($em) {
					$r->{lc $en} =$em
				}
				elsif (($o =~/c/) && $ei && ($ei =~/\b([\w\d_+-]+\@[\w\d.]+)\b/)) {
					$r->{lc $en} =$1
				}
			}
			else {
				$r->{$en} =
					  $o =~/d/ 
					? $ed ||$ef
					: (($ed ||$ef).' <' .$ev .'>')
			}
		}
	}
	$fh->close();
 }
 elsif	(0 && $s->{-ldap}) {	# lost code, for example
	$r =$s->ldapLst($o, $fc||$fm||'', $r);
 }
 else {
 }
 if ($s->{-ugadd} && $r && ($o =~/g/) && ($o !~/\@/)) {
	local $_ =$r;
	my $ugadd=ref($s->{-ugadd}) eq 'CODE' ? &{$s->{-ugadd}}($s) : $s->{-ugadd};
	if ((ref($ugadd) eq 'HASH')
	&&  (ref($r) eq 'HASH')) {
		foreach my $e (keys(%$ugadd)) {
			$r->{$e} =$ugadd->{$e} if !$r->{$e};
		}
	}
	else {
		foreach my $e (	  ref($ugadd) eq 'ARRAY'
				? @{$ugadd}
				: ref($ugadd) eq 'HASH'
				? keys(%$ugadd)
				: $ugadd){
			if (ref($r) eq 'HASH') {
				$r->{$e} =$e if !$r->{$e}
			}
			else {
				push @$r, $e if !grep /^\Q$e\E$/i, @$r
			}
		}
	}
 }
 $r =do{use locale; [sort {lc($a) cmp lc($b)} @$r]} if ref($r) eq 'ARRAY';
 $r
}


sub udisp {	# display user name
 !defined($_[1]) || $_[1] eq ''
 ? ''
 : $_[0]->{-AuthUserFile}
 ? $_[1]
 : $_[0]->{-c}->{-udisp}
 ? $_[0]->{-c}->{-udisp}->{lc($_[1])}
	||(!$_[0]->{-udispq} && ($^O eq 'MSWin32') && w32udisp(@_))
	||$_[1]
 : $_[0]->{-udispq} && ref($CACHE) && $CACHE->{-udisp}
 ? do {	$_[0]->{-c}->{-udisp} =$CACHE->{-udisp};
	$_[0]->{-c}->{-udisp}->{lc($_[1])} ||$_[1];
	}
 : ref($_[0]->{-udisp})
 ? do {	my $v =&{$_[0]->{-udisp}}(@_);
	if (ref($v)) {
		$_[0]->{-c}->{-udisp} =$v;
		$CACHE->{-udisp} =$_[0]->{-c}->{-udisp}
			if $_[0]->{-udispq} && ref($CACHE);
		$v =$_[0]->{-c}->{-udisp}->{lc($_[1])};
	}
	$v 	||(!$_[0]->{-udispq} && ($^O eq 'MSWin32') && w32udisp(@_))
		||$_[1]
   }
 : do {	$_[0]->{-c}->{-udisp} =$_[0]->uglist(
			 (!$_[0]->{-udisp} ? '-ud' : $_[0]->{-udisp} =~/\w/ ? '-ud' .$_[0]->{-udisp} : '-ugdc')
			, {});
	$CACHE->{-udisp} =$_[0]->{-c}->{-udisp}
		if $_[0]->{-udispq} && ref($CACHE);
	$_[0]->{-c}->{-udisp}->{lc($_[1])}
		||(!$_[0]->{-udispq} && ($^O eq 'MSWin32') && w32udisp(@_, !$_[0]->{-udisp} ? () : $_[0]->{-udisp} =~/\w/ ? '-ud' .$_[0]->{-udisp} : '-ugdc')) 
		||$_[1]
   }
}


sub udispq {	# display user name quick
   !defined($_[1]) || $_[1] eq ''
 ? ''
 : $_[0]->{-AuthUserFile}
 ? $_[1]
 : $_[0]->{-c}->{-udisp}
 ? $_[0]->{-c}->{-udisp}->{lc($_[1])} ||$_[1]
 : ref($CACHE) && $CACHE->{-udisp}
 ? $CACHE->{-udisp}->{lc($_[1])} ||$_[1]
 : (do{	my $v =udisp(@_);
	$CACHE->{-udisp} =$_[0]->{-c}->{-udisp} if ref($CACHE);
	$v})
}


sub ugfile {	# Users/groups caching, 'AuthGroupFile' file write/refresh
		# (?self, call, filesystem, mandatory op, args)
		# $mo: false, 'q'ueued, 's'pawn
 my ($s, $call, $fs, $mo, @arg) =@_;
 $fs =$s->pthForm('var') if !$fs;			# filesystem
 my $fg =$fs .'/' .'uagroup';				# file 'group'
 my $fl =$fs .'/' .'ualist';				# file list
 return(1) 						# update frequency
	if (-f $fg)
	&& (time() -[stat($fg)]->[9] <60*60*4);
 @arg =	  $call eq 'ugf_w32'				# call args
	? ($s->{-udflt} ||sub{1})	# domain filter sub{}()
	: $call eq 'ugf_w32ldap'
	? ($s->{-w32ldap})		# adsi ldap [[?domain=>path],...]
	: $call eq 'ugf_ldap'
	? ()				# ldap support
	: ()
	if ref($_[0]) && (!$mo ||($mo eq 's'));
 $mo ='q' if $mo && ($mo eq 's');
 if (!$mo) {						# check mode
	if (!-f $fg) {			# immediate interactive
		$s->logRec('ugfile','new',$fg);
	}
	elsif ($mo =$s && $s->{-endh}) {# end request handlers
		if ($mo->{ugfile}) {
		}
		elsif (($^O eq 'MSWin32') && eval('use Win32::Process; 1')) {
			if ((!$s->{-w32IISdpsn} || !$s->{-c}->{-RevertToSelf})) {
				$mo->{ugfile} =sub{1};
				my @cmd =(
				$^X =~/^(.+)([\\\/])[^\\\/]+\.dll$/i 
				? $1 .$2 .'perl.exe'
				: $^X =~/.dll$/i
				? 'perl.exe'
				: "$^X"
				,$0,'-call','ugfile',$call,$fs,'s');
				$s->logRec('ugfile','spawn','uagroup');
				Win32::Process::Create($Win32::Process::Create::ProcessObj
				, $cmd[0], join(' ', @cmd)
				, 0, &DETACHED_PROCESS | &CREATE_NO_WINDOW,'.')
				|| $s->logRec('error','Win32::Process::Create','ugfile',(Win32::GetLastError() +0) .'. ' .Win32::FormatMessage( Win32::GetLastError()));
			}
		}
		else {
			$s->logRec('ugfile','queue','uagroup');
			$mo->{ugfile} =sub{ugfile($_[0],$call,$fs,'q',@arg)};
		}
		return(1)
	}
 }
 elsif ($mo eq 'q') {					# queued mode
	if (ref($s)			# reverted reject
	&&  $s->{-w32IISdpsn} && ($s->{-w32IISdpsn} <2)
	&&  $s->{-c}->{-RevertToSelf}) {
		return(0)
	}
	elsif (1) {			# inline
	}
	elsif (eval("use Thread; 1")	# threads
	&& ($mo =eval{Thread->new(sub{ugfile($call=~/^(?:ugf_ldap)$/ ? $s : undef
					, $call, $fs, 't', @arg)})})
		) {
		$s->logRec('ugfile','thread',$mo);
		$mo->detach;
		return(1);
	}
	elsif ($mo =fork) {		# fork parent success
		$SIG{CHLD} ='IGNORE';
		$s->logRec('ugfile','fork',$mo);
		return(1);
	}
	elsif (!defined($mo)) {		# fork error, immediate interactive
	}
	else {				# fork child
		$mo ='f';
		ugfile($call=~/^(?:ugf_ldap)$/ ? $s : undef
			, $call, $fs, $mo, @arg);
		exit(0);
	}
 }
 my @tm=(time());
 local(*FG, *FL, *FW);
 open(FG, "+>>$fg.tmp")
	|| ($s && &{$s->{-die}}($s->lng(0, 'ugfile') .": open('$fg.tmp') -> $!" .$s->{-ermd}))
	|| croak("open('<$fg.tmp') -> $!");
 open(FL, "+>>$fl.tmp")
	|| ($s && &{$s->{-die}}($s->lng(0, 'ugfile') .": open('$fl.tmp') -> $!" .$s->{-ermd}))
	|| croak("open('<$fl.tmp') -> $!");
 while (!flock(FG,LOCK_EX|LOCK_NB) ||!flock(FL,LOCK_EX|LOCK_NB)) {
	next if !-f $fg;
	flock(FG,LOCK_UN); close(FG);
	flock(FL,LOCK_UN); close(FL);
	return(1)
 }
 truncate(FG,0); truncate(FL,0);
 seek(FG,0,0); seek(FL,0,0);

 if	($call eq 'ugf_w32')	{ugf_w32 ($s, \*FG, \*FL, \@tm, @arg)}
 elsif	($call eq 'ugf_w32ldap'){ugf_w32ldap($s, \*FG, \*FL, \@tm, @arg)}
 elsif	($call eq 'ugf_ldap')	{ugf_ldap($s, \*FG, \*FL, \@tm, @arg)}
 # my ($s, $tm, $df);
 # local (*FG, *FL);
 # ($s, *FG, *FL, $tm, @arg) =@_;
 # ualist/ugf_w32, used in uglist(), ":\t" delimited:
 # domain?\user : user@domain : ADsPath : 'User' : FullName : email : Description
 # domain?\group: group@domain: ADsPath : 'Group': 	    : email : Description : members
 # uagroup/ugf_w32, used in uglist(), "\t" delimited:
 # ?group : members		#  ?name	domain\name	name@domain
 # domain\group : members
 # group@domain : members
 #
 # ugf_w32, used in uglist():
 # standalone host:	local users, local groups
 # domain member:	domain users, local member groups, domain groups
 # domain controller:	domain users, local domain groups, domain groups
 # local member groups unqualified always (using simple 'fullname' without '@')
 # local controller groups unqualified usually

 seek(FG,0,0); seek(FL,0,0);
 open(FW, "+>>$fg") && flock(FW,LOCK_EX)
 	&& truncate(FW,0) && seek(FW,0,0)
	&& (do {while(my $rr =readline *FG){print FW $rr}; 1})
	&& flock(FW,LOCK_UN) && close(FW)
	|| ($s && $s->die($s->lng(0, 'ugfile') .": open('$fg') -> $!"))
	|| croak("open('<$fg') -> $!");
 flock(FG,LOCK_UN); close(FG); unlink("$fg.tmp");
 open(FW, "+>>$fl") && flock(FW,LOCK_EX) 
 	&& truncate(FW,0) && seek(FW,0,0)
	&& (do {while(my $rr =readline *FL){print FW $rr}; 1})
	&& flock(FW,LOCK_UN) && close(FW)
	|| ($s && $s->die($s->lng(0, 'ugfile') .": open('$fl') -> $!"))
	|| croak("open('<$fl') -> $!");
 flock(FL,LOCK_UN); close(FL); unlink("$fl.tmp");
 push @tm, time();
 $s->logRec('ugfile','timing',join('-', map {$tm[$_] -$tm[$_-1]} (1..$#tm)),'sec')
	if $s;
 1;
}


sub ugf_w32 {	# ugfile() module using Win32 ADSI WinNT://
 my ($s, $FG, $FL, $tm, $df) =@_;
 eval('use Win32::OLE'); Win32::OLE->Option('Warn'=>0);
 eval('use Win32::OLE::Enum');
 my $od =Win32::OLE->GetObject('WinNT://' .(Win32::NodeName()) .',computer');
 my $hdu=$od	&& $od->{Name}		|| ''; 		# host domain name
 my $hdn=$od	&& lc($od->{Name})	|| ''; 		# host domain name
 my $hdp=$od	&& $od->{ADsPath}	|| '';		# host domain path
 my $hdc=lc($hdp);					# host domain comparable
 my $ldp=$od	&& $od->{Parent}	|| '';		# local domain path
    $od =Win32::OLE->GetObject("$ldp,domain");
 my $ldu=$od	&& $od->{Name}		|| '';		# local domain name
 my $ldn=$od	&& lc($od->{Name})	|| '';		# local domain name
 my $ldc=lc($ldp);					# local domain comparable
 my $lds =$ldu && w32isDC($s) && $ldn	|| '';		# local DC service?
 $s->logRec('ugfile','ugf_w32','host',$hdp,'dc',$lds,'domain',$ldp)
	if $s;
 my %dnl=(!$hdn ||$lds ?() :($hdn=>1), !$ldn ?() :($ldn=>1));	# domains to list
 my @dnl=(!$hdu ||$lds ?() :$hdu, !$ldu ?() :$ldu);		# domains to list
 my $fgm;						# group lister/unfolder
    $fgm=sub{	return('') if !$_[1];
		my $om =$_[1]->{Members};
		return('') if !$om;
		my @rv;
		my $oi;
		$om->{Filter} =['User'];
		$oi =Win32::OLE::Enum->new($om);
		while (defined($oi) && defined(my $oe =$oi->Next())) {
			if (!$oe || !$oe->{Class} || !$oe->{Name}
				|| substr($oe->{Name},-1,1) eq '$'
				|| substr($oe->{Name},-1,1) eq '&') {
			}
			else {
				my $dn =$oe->{Parent} =~/([^\\\/]+)$/ ? $1 : $oe->{Parent};
				push @rv
				, map {$_ # $_ ne lc($_) ? ($_, lc($_)) : $_
					} lc($oe->{Parent}) ne ($ldn ? $ldc : $hdc)
					? ($dn . '\\' .$oe->{Name})
					: ($oe->{Name}, ($dn . '\\' .$oe->{Name}))
					, $oe->{Name} .'@' .$dn;
			}
		}
		$om->{Filter} =['Group'];
		$oi =Win32::OLE::Enum->new($om);
		while (defined($oi) && defined(my $oe=$oi->Next())) {
			if (!$oe || !$oe->{Class} || !$oe->{Name} || !$oe->{groupType}
				|| substr($oe->{Name},-1,1) eq '$' 
				|| substr($oe->{Name},-1,1) eq '&') {
			}
			else {
				if ($oe->{groupType} eq '2') {	# 2 -global; 8 -universal
					my $du =$oe->{Parent} =~/([^\\\/]+)$/ 
						? $1 
						: $oe->{Parent};
					my $dn =lc($du);
					if (!$dnl{$dn} && $dn !~/^(?:nt authority|builtin)$/) {
						$dnl{$dn} =1;
						push @dnl, $du;
					}
				}
				push @rv, &$fgm($_[0], $oe);
			}
		}
		join("\t", @rv)
	};
 for (my $di =0; $di <=$#dnl; $di++) {
	my $du =$dnl[$di];
	local $_ =$du;
	next if !$du ||!&$df($s, $du);
	push @$tm, time();
	$s->logRec('ugfile','ugf_w32','domain',$du) if $s;
	my $dn =lc($du);
	$od =Win32::OLE->GetObject("WinNT://$du");
	next if !$od || !$od->{Class};
	# standalone host:	local users, local groups
	# domain member	:	domain users, local member groups, domain groups
	# domain controller:	domain users, local domain groups, domain groups
	my $dp =$dn eq $ldn || $dn eq $hdn ? '' : $du;
	unless ($hdn && $ldn && ($dn eq $hdn)) {
		# omited default domain part
		$od->{Filter} =['User'];
		my $oi =Win32::OLE::Enum->new($od);
		while (defined($oi) && defined(my $oe=$oi->Next())) {
			next if !$oe || !$oe->{Class} || !$oe->{Name} || substr($oe->{Name},-1,1) eq '$' || substr($oe->{Name},-1,1) eq '&';
			next if $oe->{AccountDisabled};
			next if $oe->{Name} =~/^(?:SYSTEM|INTERACTIVE|NETWORK|IUSR_|IWAM_|HP ITO |opc_op|patrol|SMS |SMS&_|SMSClient|SMSServer|SMSService|SMSSvc|SMSLogon|SMSInternal|SMS Site|SQLDebugger|sqlov|SharePoint|RTCService)/i;
			print $FL $dp ? "$dp\\" : '', $oe->{Name}
			,":\t", $oe->{Name} .'@' .$du
			,":\t", $oe->{ADsPath}
			,":\t", $oe->{Class}
			,":\t", $oe->{FullName}||''
			,":\t", ''
			,":\t", $oe->{Description}||''
			, "\n";
		}
	}
	unless (0) {
		$od->{Filter} =['Group'];
		my $oi =Win32::OLE::Enum->new($od);
		while (defined($oi) && defined(my $oe=$oi->Next())) {
			next	if !$oe || !$oe->{Class} 
				|| !$oe->{Name} 
				|| substr($oe->{Name},-1,1) eq '$' 
				|| substr($oe->{Name},-1,1) eq '&';
			next	if ($dn ne ($lds ||$hdn))
				&& ($oe->{groupType} eq '4');	# local
			next if $oe->{Name} =~/^(?:Domain Controllers|Domain Computers|Pre-Windows 2000|RAS and IAS Servers|MTS Trusted|SMSInternal|NetOp Activity)/i;
			my $sgm =&$fgm($_[0], $oe);
			print $FL $dp ? "$dp\\" : '', $oe->{Name}
			,":\t", $oe->{Name}
				.(($oe->{groupType} ne '4')
 						? '@' .$du : '')
			,":\t", $oe->{ADsPath}
			,":\t", $oe->{Class}
			,":\t", ''
			,":\t", ''
			,":\t", $oe->{Description}||''
			, "\n";
			print $FG !$dp ? ($oe->{Name}, ":\t", $sgm, "\n") : ()
			, $du, '\\', $oe->{Name}, ":\t", $sgm, "\n"
			, $oe->{Name}, '@', $du, ":\t", $sgm, "\n"
			;
		}
	}
 }
 1
}


sub ugf_w32ldap { # ugfile() module using Win32 ADSI LDAP:// and WinNT://
 my ($s, $FG, $FL, $tm, $aq) =@_;
 my $hn ={};	# dn -> name
 my $hm ={};	# group dn -> members
 eval('use Win32::OLE'); Win32::OLE->Option('Warn'=>0);
 eval('use Win32::OLE::Enum');
 my $ll =w32isDC($s);	# local DC
 my $ld =w32domain($s);
 my $lh =Win32::NodeName();
 my $ae;
    $ae =sub{	return(undef) if !$_[0];
		my $oi =Win32::OLE::Enum->new($_[0]);
		while (defined($oi) && defined(my $oe=$oi->Next())) {
			if (!ref($oe) ||!$oe->{Class} ||!($oe->{cn} ||$oe->{Name})) {
			}
			elsif ($oe->{Class} =~/^(?:container|organizationalUnit|builtinDomain)$/i) {
				&$ae($oe, @_[1..$#_])
			}
			elsif (($oe->{sAMAccountName} ||$oe->{cn} ||$oe->{Name} ||'') =~/\$$/) {
			}
			elsif ($oe->{Class} =~/^(?:user|group)$/i) {
				&{$_[1]}($oe)
			}
		}
	};
 my $am;
    $am =sub{	return('') if !$hm->{$_[0]};
		my $hg =$_[1] ||{};
		join("\t"
			, map {	if ($hg->{$_}) {
					()
				}
				elsif (!$hm->{$_}) {
					$hg->{$_} =1;
					my $v =$hn->{$_} ||$_;
					$v =~/^$ld\\/i ? ($',$v,"$'\@$ld") : $v =~/\\/ ? ($v, "$'\@$`") : $ll ? ($v, "$ld\\$v", "$v\@$ld") : ($v)
				}
				else {
					$hg->{$_} =1;
					my $v =$hn->{$_} ||$_;
					my $a =&$am($_, $hg);
					(($v =~/^$ld\\/i ? ($',$v,"$'\@$ld") : $v =~/\\/ ? ($v, "$'\@$`") : $ll ? ($v, "$ld\\$v", "$v\@$ld") : ($v))
					,$a ? $a : ())
				}} @{$hm->{$_[0]}})
	};
 foreach my $e ($ll ? () : '', ref($aq) ? @$aq : $aq) {
	my ($pw, $pl) =ref($e) ? @$e : ('', $e);
	# $pw eq ''	- local domain - $ld, 'LDAP://'
	# $ll		- local DC, 'LDAP://'
	# $pl eq ''	- local server - Win32::NodeName(), 'WinNT://'
	my $pi = $pl=~/\bDC=/ ? join('.', split /,DC=/, $') : '';
	$s->logRec('ugfile', 'ugf_w32ldap', 'domain', $pw||$ld, $pi, $pl||$lh)
		if $s;
	my $od =$pl
		? Win32::OLE->GetObject("LDAP://$pl")
		: Win32::OLE->GetObject("WinNT://$lh");
	if (!ref($od)) {
		$s
		? $s->warn("Win32::OLE->GetObject('LDAP://$pl') -> $@")
		: carp("Win32::OLE->GetObject('LDAP://$pl') -> $@");
		next;
	}
	&$ae($od,sub{	my $oe =$_[0];
			return(0)	if !$oe->{GUID};
			return(0)	if $pl && ($pw || !$ll)
					&& ($oe->{Class} =~/^(?:group)$/i)
					&& (($oe->{groupType}||0) & 0x00000004);
					# ADS_GROUP_TYPE_LOCAL_GROUP
			my $id =($pl ? $oe->{GUID} : ($oe->{sAMAccountName} ||$oe->{cn} ||$oe->{Name}));
			my $en =($pw ? $pw .'\\' : '')
				.($oe->{sAMAccountName} ||$oe->{cn} ||$oe->{Name});
			$hn->{$id} =$en;
			if ($oe->{Class} =~/^(?:group)$/i) {
				$hm->{$en} =$hm->{$id} =[];
				my $on =undef;	# 'foreignSecurityPrincipal'->'foreignIdentifier' may be empty
				my $oi =Win32::OLE::Enum->new($oe->{Members});
				while (defined($oi) && defined(my $om=$oi->Next())) {
					if	(!$om ||!$om->{Class}) {()}
					elsif	($om->{Class} =~/^(foreignSecurityPrincipal)$/) {
						if ($om->{foreignIdentifier}) {
							push @{$hm->{$id}}, $om->{foreignIdentifier}
						}
						else {
							$on =1;						}
					}
					else {
						push @{$hm->{$id}}
						, $pl 
						? $om->{GUID}
						: ((($om->{Parent}=~/([^\\\/]+)$/) && (lc($1) ne lc($lh)) ? "$1\\" : '')
						 .($om->{sAMAccountName} ||$om->{cn} ||$om->{Name}));
					}
				}
				if ($on) {
					$on ='WinNT://' .($pw||$ld||$lh) .'/' .($oe->{sAMAccountName} ||$oe->{cn} ||$oe->{Name});
					my $og =Win32::OLE->GetObject($on);
					return($s
						? $s->warn("Win32::OLE->GetObject('$on') -> $@")
						: carp("Win32::OLE->GetObject('$on') -> $@")
						) if !$og;
					$on =$hm->{$oe->{GUID}};
					my $oi =Win32::OLE::Enum->new($og->{Members});
					while (defined($oi) && defined(my $om=$oi->Next())) {
						# GUIDs different in 'WinNT://' and 'LDAP://'; GUID formats different also.
						# "User Naming Attributes": objectGUID is a 128-bit GUID structure stored as an OctetString.
						# typedef struct _GUID {  DWORD Data1;  WORD Data2;  WORD Data3;  BYTE Data4[8];} GUID;
						# my $k =$om->{GUID};
						# next if grep /^\Q$k\E$/, @$on;
						# push @$on, $k;
						my $k = $om->{Parent}=~/([^\\\/]+)$/ ? $1 : '???';
						push @$on, $k .'\\' .($om->{sAMAccountName} ||$om->{Name})
							if $k && (lc($k) ne lc($pw||$ld));
					}
				}
			}
	});
 }
 foreach my $e ($ll ? () : '', ref($aq) ? @$aq : $aq) {
	my ($pw, $pl) =ref($e) ? @$e : ('', $e);
	my $pi = $pl=~/\bDC=/ ? join('.', split /,DC=/, $') : '';
	$s->logRec('ugfile', 'ugf_w32ldap', 'domain', $pw ||$ld, $pi, $pl||$lh)
		if $s;
	my $od =$pl
		? Win32::OLE->GetObject("LDAP://$pl")
		: Win32::OLE->GetObject("WinNT://$lh");
	if (!ref($od)) {
		$s
		? $s->warn("Win32::OLE->GetObject('LDAP://$pl') -> $@")
		: carp("Win32::OLE->GetObject('LDAP://$pl') -> $@");
		next;
	}
	&$ae($od,sub{	my $oe =$_[0];
			return(0)	if !$oe->{GUID};
			return(0)	if !$pl
					&& ($oe->{Class} =~/^(?:user)$/i);
			return(0)	if $pl && ($pw || !$ll)
					&& ($oe->{Class} =~/^(?:group)$/i)
					&& (($oe->{groupType}||0) & 0x00000004);
					# ADS_GROUP_TYPE_LOCAL_GROUP
			my $id =($pl ? $oe->{GUID} : ($oe->{sAMAccountName} ||$oe->{cn} ||$oe->{Name}));
			my $en =$hn->{$id} ||$oe->{sAMAccountName} ||$oe->{cn} ||$oe->{Name};
			return(0)	if $en =~/^(?:Domain Controllers|Domain Computers|Pre-Windows 2000|RAS and IAS Servers|MTS Trusted|SMSInternal|NetOp Activity)/i;
			return(0)	if $en =~/^(?:SYSTEM|INTERACTIVE|NETWORK|IUSR_|IWAM_|HP ITO |opc_op|patrol|SMS |SMS&_|SMSClient|SMSServer|SMSService|SMSSvc|SMSLogon|SMSInternal|SMS Site|SQLDebugger|sqlov|SharePoint|RTCService)/i;
			my $ef =($oe->{sAMAccountName}||$oe->{cn}||$oe->{Name}||'')
				.(!($oe->{Class} =~/^(?:group)$/i) 
					|| !($oe->{groupType} & 0x00000004)
						? '@' .($pi ||$lh) : '');
			my $el =&$am($id);
			print $FL $en
				,":\t", $ef
				,":\t", $oe->{ADsPath}		||''
				,":\t", ucfirst($oe->{Class})	||''
				,":\t", $oe->{FullName}		||''
				,":\t", $oe->{EmailAddress}	||''
				,":\t", $oe->{Description}	||''
				, "\n";
			print $FG $en, ":\t", $el, "\n"
				if $el;
			print $FG "$ld\\$en", ":\t", $el, "\n"
				, "$en\@$ld", ":\t", $el, "\n"
				if $el && !$pw && $pl;
			print $FG "$lh\\$en", ":\t", $el, "\n"
				, "$en\@$lh", ":\t", $el, "\n"
				if $el && !$pw && !$pl;
			print $FG $ef, ":\t", $en
				, !$pw ? ("\t", "$ld\\$en") : ()
				, $el ? ("\t", $el) : ()
				, "\n"
				if $pl;
	});
 }
 1
}


sub ugf_ldap {	# ugfile() module using Net::LDAP
 my ($s, $FG, $FL, $tm, $ha) =@_;
 $s =$ha if !$s;
 my $hn ={};	# dn -> name
 my $hm ={};	# group dn -> members
 my $a  =$ha && $ha->{-ldapattr} ||$s->{-ldapattr};
 my $qf =($s->{-ldapfu} && $s->{-ldapfg}
	? '(|' .$s->{-ldapfu} .$s->{-ldapfg} .')'
	: '' # : '(|(objectClass=organizationalPerson)(objectClass=groupOfNames))'
	);
    $qf =$qf ? {'filter'=>$qf} : {};
 my $q  =$s->ldapSearch(%$qf);
 push @$tm, time();
 for(my $i =0; $i < $q->count; $i++) {
	my $dn =$q->entry($i)->get_value('dn') ||$q->entry($i)->get_value('distinguishedName');
	$hn->{$dn} =utf8dec($s, $q->entry($i)->get_value($a->[0])||'');
	$hm->{$dn} =[$q->entry($i)->get_value('member')]
		if $q->entry($i)->get_value('member');
 }
 my $ae;
    $ae=sub{
	return('') 
		if !$hm->{$_[0]};
	my $hg =$_[1] ||{};
	join("\t"
		,map {	if ($hg->{$_}) {
				()
			}
			elsif (!$hm->{$_}) {
				$hg->{$_} =1;
				$hn->{$_} ? utf8dec($s, $hn->{$_}) : utf8dec($s, $_)
			}
			else {	$hg->{$_} =1;
				my $a =&$ae($_, $hg);
				($hn->{$_} ? utf8dec($s, $hn->{$_}) : ()
				,$a ? $a : ())
			}} @{$hm->{$_[0]}})
	};
 push @$tm, time();
 $q  =$s->ldapSearch(%$qf);
 push @$tm, time();
 for(my $i =0; $i < $q->count; $i++) {
	my $dn =$q->entry($i)->get_value('dn') ||$q->entry($i)->get_value('distinguishedName');
	my $en =utf8dec($s, $q->entry($i)->get_value($a->[0])||'');
	my @en =$q->entry($i)->get_value($a->[0]); shift @en;
	my $ef ='';
	my $ep =utf8dec($s, $dn);
	my $em =utf8dec($s, $q->entry($i)->get_value('mail')||'');
	my $ec =utf8dec($s, $q->entry($i)->get_value('objectClass')||'')
			=~/person|user/i ? 'User' : 'Group';
	my $ed =utf8dec($s, $q->entry($i)->get_value($a->[1]||$a->[0])||'');
	my $ei =utf8dec($s, $q->entry($i)->get_value('info')||'');
	   $ei =join('; ', map {my $v =$q->entry($i)->get_value($_);
				  !$v
				? ()
				: (utf8dec($s, $v))
			} qw(title company department physicalDeliveryOfficeName telephoneNumber))
		if !$ei;
	   $ei =~s/[\n\r]/ /g;
	my $el =$hm->{$dn} ? &$ae($dn) : undef;
	print $FL $en
		,":\t", $ef ||$em ||$en ||''
		,":\t", $ep ||''
		,":\t", $ec ||''
		,":\t", $ed ||''
		,":\t", $em ||''
		,":\t", $ei ||''
		, "\n";
	print $FG $en, ":\t", $el, "\n"
		if $el;
	print $FG map {utf8dec($s, $_) .":\t"
			.$en
			.($el ? "\t" .$el : '')
			."\n"
			} @en
		if @en;
 }
 1
}



sub w32IISdpsn {# deimpersonate Microsoft IIS impersonated process
		# !!!Future: Problems may be. Implement '-fswtr' login also?
		# 'Win32::API' module used, not in ActiveState package.
		# Set 'IIS / Home Directory / Application Protection' = 'Low (IIS Process)'
		# or see 'Administrative Tools / Component Services'.
		# Do not use quering to 'Index Server'.
		# See also FastCGI for another ways:
		# http://php.weblogs.com/fastcgi_with_php_and_iis
		# http://www.caraveo.com/fastcgi/
		# http://www.cpan.org/modules/by-module/FCGI/
 return(undef)	if (defined($_[0]->{-w32IISdpsn}) && !$_[0]->{-w32IISdpsn})
		|| $_[0]->{-c}->{-RevertToSelf}
		|| ($^O ne 'MSWin32')
		|| !(($ENV{SERVER_SOFTWARE}||'') =~/IIS/)
	#	|| $ENV{'GATEWAY_INTERFACE'}
		|| $ENV{'FCGI_SERVER_VERSION'};
 $_[0]->user();
 $_[0]->{-c}->{-RevertToSelf} =1;
 if (0 && $ENV{GATEWAY_INTERFACE} && ($ENV{GATEWAY_INTERFACE} =~/PerlEx/)
 && $_[0]->w32ufswtr()) {
	$_[0]->{-debug} && $_[0]->logRec('w32IISdpsn','w32ufswtr');
	return(1)
 }
 my $o =eval('use Win32::API; new Win32::API("advapi32.dll","RevertToSelf",[],"N")');
 my $l =eval{Win32::LoginName()} ||'';
 $o && $o->Call() && ($l ne (eval{Win32::LoginName()} ||''))
 ? ($_[0]->{-debug}) && $_[0]->logRec('w32IISdpsn')
 : &{$_[0]->{-die}}($_[0]->lng(0, 'w32IISdpsn') .": Win32::API('RevertToSelf') -> " .join('; ', map {$_ ? $_ : ()} $@,$!,$^E) .$_[0]->{-ermd})
}


sub w32ufswtr {	# Win32 filesystem writer or System user?
 return(undef)	if $^O ne 'MSWin32';
 my $u =lc(Win32::LoginName());
 if (ref($_[0]->{-fswtr})) {
	foreach my $e (@{$_[0]->{-fswtr}}) {return(1) if $u eq lc($e)}
 }
 elsif ($_[0]->{-fswtr} && ($u eq lc($_[0]->{-fswtr}))) {
	return(1)
 }
 return(1)	if $u eq 'system';
 if (($] >=5.008) && eval('use Win32; 1') && Win32::IsAdminUser()) {
		my ($dom, $sid, $sit);
		if (Win32::LookupAccountName('', $u , $dom, $sid, $sit)) {
			# SidTypeWellKnownGroup == 5; S-1-5-18 == system
			# sprintf '%vlx',$sid
			return(1) if $sit eq '5';
		}
 }
 undef;
}


sub w32adhi {	# Win32 AD Host Info
 $_[0]->{'ADSystemInfo'} 
 || ($_[0]->{'ADSystemInfo'} =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); Win32::OLE->CreateObject("ADSystemInfo")'))
}


sub w32domain {	# Win32 domain name (or node name if no domain)
 w32adhi($_[0])->{DomainShortName} || eval{Win32::NodeName()} || $ENV{COMPUTERNAME}
}


sub w32isDC {	# Win32 is on domain controller, not srvr or wrkstation
 eval('use Win32::OLE'); Win32::OLE->Option('Warn'=>0);
 Win32::OLE->GetObject('LDAP://' .Win32::NodeName()) && 1
}


sub w32user {	# Win32 user object
	eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0)');
	my ($dn, $gn) =	$_[1] =~/^([^\\]+)\\(.+)/ 
			? ($1,$2) 
			: $_[1] =~/^([^@]+)@(.+)/ 
			? ($2,$1) 
			: (Win32::NodeName(),$_);
	Win32::OLE->GetObject("WinNT://$dn/$gn");
}


sub w32udisp {	# Win32 user display name
		# (self, user, ?opt)
	return($_[1]) if $^O ne 'MSWin32';
	return('') if !defined($_[1]) || $_[1] eq '';
	my ($dn, $gn) =	$_[1] =~/^([^\\]+)\\(.+)/ 
			? ($1,$2) 
			: $_[1] =~/^([^@]+)@(.+)/ 
			? ($2,$1) 
			: (Win32::NodeName(),$_[1]);
	my $o =eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0); 1')
		&& Win32::OLE->GetObject("WinNT://$dn/$gn");
	!$o
	? $_[1]
	: $o->{Class} eq 'User'
	? $o->{FullName} ||$_[1]
	: $_[2] && ($_[2] =~/c/) && ($o->{Class} eq 'Group')
	? $o->{Description} ||$_[1]
	: $_[1]
}


sub w32ugrps {	# Win32 user groups, optional usage, interesting legacy code
 my $uif =$_[1];		# user input full name
 my $uid ='';			# user input domain name
 my $uin ='';			# user input name shorten
 eval('use Win32::OLE'); Win32::OLE->Option('Warn'=>0);
 if	($uif =~/^([^\\]+)\\(.+)/)	{ $uid =$1;	$uin =$2 }
 elsif	($uif =~/^([^@]+)\@(.+)/)	{ $uid =$2;	$uin =$1 }
 else					{ $uin =$uif;	$uid =Win32::OLE->CreateObject('ADSystemInfo')->{DomainShortName} ||Win32::NodeName()}
 my $gn =[];			# group names
 my $gp =[];			# group paths
 my $oh =Win32::OLE->GetObject('WinNT://' .Win32::NodeName() .',computer');
 return($gn) if !$oh;
 my $ou =Win32::OLE->GetObject("WinNT://$uid/$uin,user");
 return($gn) if !$ou;
 my $dp =			# domain prefix for global groups, optional
	  lc($oh->{Parent}) eq lc($ou->{Parent})
	? ''
	: $ou->{Parent} =~/([^\\\/]+)$/
	? $1 .'\\'
	: '';
 foreach my $og (Win32::OLE::in($ou->{Groups})) { # global groups from user's domain
	next if !$og || !$og->{Class} || $og->{groupType} ne '2';
	push @$gn, $dp .$og->{Name};
	push @$gp, $og->{ADsPath};
 }
 my $uc =lc($ou->{ADsPath});	# user compare
 my $gc =[map {lc($_)} @$gp];	# group compare
 $oh->{Filter} =['Group'];
 foreach my $og (Win32::OLE::in($oh)) {
	next if !$og || !$og->{Class} || $og->{groupType} ne '4';
	foreach my $om (Win32::OLE::in($og->{Members})) {
		next if !$om || !$om->{Class} || ($om->{Class} ne 'User' && $om->{Class} ne 'Group');
		my $mc =lc($om->{ADsPath});
		foreach my $p (@$gc) {
			next if $p ne $mc;
			push @$gn, $og->{Name};
			push @$gp, $og->{ADsPath};
			$mc =undef;
			last;
		}
		last if !$mc;
		if ($mc eq $uc) {
			push @$gn, $og->{Name};
			push @$gp, $og->{ADsPath};
			last;
		}
	}
 }
 $gn;
}

sub w32umail {
	umail(@_)
}


sub umail {	# E-mail address(es) of user(s) given
 my($s, $u) =@_[0,1];	# (self, ?user(s) string) -> email
	$u  =$s->user() if !$u;
 my $d =$s->{-smtpdomain};
 my $h =$s->uglist('-ug@c',{});
 join(', '
	, map {	my ($v, $o) =($_);
		!$v
		? ()
		: $v && $d && ($v =~/\@\Q$d\E/i)
		? $v
		: $h && $h->{lc $v}
		? $h->{lc $v}
		: ($v !~/[\@\\]/)
		? $v
		: $v
		} split /\s*[,;]\s*/, $u)
}


sub ldap {	# LDAP connection
 return($_[0]->{-c}->{-ldap}) if $_[0]->{-c}->{-ldap};
 my $s =$_[0];
 my $a =$s->{-ldapsrv} ||$s->{-ldap};
 return	(&{$s->{-die}}('LDAP connection undefined' .$s->{-ermd}))
	if !$a;
 my $r;
 if(ref($a) eq 'CODE') {
 }
 else {
	$s->logRec('ldap','Net::LDAP->new');
	eval('use Net::LDAP; 1')
	|| return (&{$s->{-die}}("use Net::LDAP -> $@" .$s->{-ermd}));
	$r =Net::LDAP->new(ref($a) eq 'ARRAY' ? @$a : ref($a) eq 'HASH' ? %$a : $a);
	return	(&{$s->{-die}}("Net::LDAP->new -> $@" .$s->{-ermd}))
		if !$r;
	$a =$s->{-ldapbind}; # "user",password=>"passw", version=>3
	$r->bind(ref($a) eq 'ARRAY' ? @$a : ref($a) eq 'HASH' ? %$a : !$a ? (version=>3) : $a)
	|| return (&{$s->{-die}}("Net::LDAP->bind -> $@" .$s->{-ermd}));
 }
 $_[0]->{-c}->{-ldap} =$r;
}


sub ldapSearch {# LDAP search
		# (self, option=>value)
 my %a =(@_[1..$#_]);
 my $f =$_[0]->{-ldapsearch} && $_[0]->{-ldapsearch}->{filter} && $a{filter}
	? '(&' .$a{filter} .$_[0]->{-ldapsearch}->{filter} .')'
	: $a{filter}
	? $a{filter}
	: $_[0]->{-ldapsearch}->{filter}
	? $_[0]->{-ldapsearch}->{filter}
	: '';
 $_[0]->ldap;
 $_[0]->logRec('ldap','search',$f);
 my %a1=($_[0]->{-ldapsearch} ? %{$_[0]->{-ldapsearch}} : ()
	,%a, $f ? (filter=>$f) : ());
 my $r =$_[0]->ldap->search(%a1);
 return	(&{$_[0]->{-die}}("ldapSearch(" .join(',', map{"$_=>" .$a1{$_}} keys %a1) .') ->' .$r->error .$_[0]->{-ermd}))
	if $r->code;
 $r
}


sub ldapEntry {	# LDAP search and return entry
		# (entry name) -> entry
 my $r =$_[0]->ldapSearch($#_ <2 
	? ('filter'=>	$_[1] !~/[=]/
			? $_[0]->{-ldapattr}->[0] .'=' .utf8enc($_[0],$_[1])
			: $_[1])
	: @_[1..$#_]);
 return	(&{$_[0]->{-die}}('ldapRead('. join(', ',@_[1..$#_]) .'-> sevaral entries found' .$_[0]->{-ermd}))
	if $r->count >1;
 $r->entry(0);
}


sub ldapVal {	# LDAP entry get value and decode it
		# (entry, attr name) -> value
 my $v =ref($_[1]) ? $_[1]->get_value($_[2..$#_]) : $_[0]->ldapEntry($_[1])->get_value($_[2..$#_]);
 !defined($v)
 ? ($v)
 : ref($v) eq 'ARRAY'
 ? [map {utf8dec($_[0], $_)} @$v]
 : utf8dec($_[0], $v)
}


sub ldapLst {	# LDAP list	# may be useful instead of 'ugf_ldap'
		# self, '-ug<>', ?user|group|filter, ?container, ?fields
 my($s,$o,$f,$r,$a) =@_;
 $o ='-ug'	if !$o;
 $r =[]		if !$r;
 $a =$s->{-ldapattr}	if !$a;
 my $fq =($f =~/[=]/	? $f
	: ($o =~/ug/)
	|| ($o!~/[ug]/)	? ($s->{-ldapfu} && $s->{-ldapfg}
				? '(|' .$s->{-ldapfu} .$s->{-ldapfg} .')'
				: '')
	: $o =~/u/	? $s->{-ldapfu} ||'(objectClass=organizationalPerson)'
	: $o =~/g/	? $s->{-ldapfg} ||'(objectClass=groupOfNames)'
	: '');
 my $fc=ref($f) eq 'CODE' ? $f : undef;
 my $fm=ref($f) ? undef : $f =~/[=]/ ? undef
	: $f && $o !~/u/ ? $s->ugroups($f)
	: $f;
 $fq =$fq
	? ('&(member=' .utf8enc($s,$fm) .")$fq")
	: ('(member=' .utf8enc($s,$fm) .')')
	if $fm && !ref($fm);
 my $q =$s->ldapSearch($fq ? ('filter'=>$fq) : ());
 $s->logRec('ldap','list');
 if (ref($r) eq 'ARRAY') {
	for(my $i =0; $i < $q->count; $i++) {
		my $v =utf8dec($s, $q->entry($i)->get_value($a->[0])||'');
		next if ref($fm) && !grep /^\Q$v\E$/i, @$fm;
		push @$r, $v
	}
 }
 else {
	for(my $i =0; $i < $q->count; $i++) {
		my $v =utf8dec($s, $q->entry($i)->get_value($a->[0]) ||'');
		my $v1=utf8dec($s, $q->entry($i)->get_value($a->[1] ||$a->[0]) ||'');
		next if ref($fm) && !grep /^\Q$v\E$/i, @$fm;
		$r->{$v} =($v1 ||$v) .($o=~/[<>]/ ? ' <' .($v ||$v1) .'>' : '');
	}
 }
 $r
}


sub ldapUgroups { # LDAP user groups	# replaced with 'ugf_ldap'
		# (user) -> groups
 my($s,$u,$g) =@_;
 my $n =ref($u) ? $u->get_value('dn') : $s->ldapEntry($u)->get_value('dn');
 my $q =$s->ldapSearch("member=$n");
 $g =[] if !$g;
 for(my $i =0; $i < $q->count; $i++) {
	push @$g, utf8dec($s, $q->entry($i)->get_value($s->{-ldapattr}->[0])||'');
	ldapUgroups($s, $q->entry($i), $g);
 }
 $g
}




#########################################################
# Database methods
#########################################################


sub mdeTable {	# Table MetaData Element
		# (self, table name) -> table metadata
						# Cached
 return	($_[0]->{-table}->{$_[1]})
	if $_[0]->{-table}->{$_[1]}
	&& $_[0]->{-table}->{$_[1]}->{'.mdeTable'};

 my ($s, $tn) =@_;
						# Generate table
						# table factory may be developed
 &{$s->{-mdeTable}}($s, $tn)
	if $s->{-mdeTable} && !$s->{-table}->{$tn};
 return	(&{$s->{-die}}('mdeTable(' .$tn .') -> not described table' .$s->{-ermd}))
	if !$s->{-table}->{$tn};
						# Organize table metadata
 $s->logRec('mdeTable', $tn);
 my $tm =$s->{-table}->{$tn};
 $tm->{'.mdeTable'} =1;				# flag of organized
 $tm->{-mdefld} ={};				# hash of fields
 if (ref($tm->{-field}) eq 'ARRAY') {
	foreach my $f (@{$tm->{-field}}) {	# field flags setup
		next if !ref($f) ||ref($f) ne 'HASH';
		$tm->{-mdefld}->{$f->{-fld}} =$f
			if $f->{-fld};
		$f->{-flg} ='a'			# 'a'll
			if !exists($f->{-flg});
		if ($f->{-flg} =~/k/) {
			if (!$tm->{-key}) {	# 'k'ey
				$tm->{-key} =[$f->{-fld}]
			}
			elsif (!grep {$_ eq $f->{-fld}} @{$tm->{-key}}) {
				push @{$tm->{-key}}, $f->{-fld}
			}
		}
		if ($f->{-flg} =~/w/) {		# 'w'here
			if (!$tm->{-wkey}) {
				$tm->{-wkey} =[$f->{-fld}]
			}
			elsif (!grep {$_ eq $f->{-fld}} @{$tm->{-wkey}}) {
				push @{$tm->{-wkey}}, $f->{-fld}
			}
		}
		$f->{-flg} ='w' .$f->{-flg}	# 'w'here
			if $f->{-flg} !~/w/ && $tm->{-wkey} && grep {$_ eq $f->{-fld}} @{$tm->{-wkey}};
		$f->{-flg} ='k' .$f->{-flg}	# 'k'ey
			if $f->{-flg} !~/k/ && $tm->{-key} && grep {$_ eq $f->{-fld}} @{$tm->{-key}};
		$f->{-flg}.='e'			# 'e'dit
			if $f->{-flg} !~/e/ && $f->{-edit};
	 }
 }
 $tm
}


sub mdlTable {	# Tables List
 sort(	  $_[0]->{-mdlTable}
	?(keys %{$_[0]->{-table}}
		, grep {!$_[0]->{-table}->{$_}} &{$_[0]->{-mdlTable}})
	: keys %{$_[0]->{-table}})
}


sub mdeQuote {	# Quote field value if needed
		# self, table, field, value
  my $t =ref($_[1]) eq 'HASH' ? $_[1] : mdeTable($_[0], !ref($_[1]) ? $_[1] : ref($_[1]->[0]) ? $_[1]->[0]->[0] : $_[1]->[0]);
    !ref($t) || !$t->{-mdefld} || !$t->{-mdefld}->{$_[2]} || !$t->{-mdefld}->{$_[2]}->{-flg}
  ? (	  !defined($_[3])
	? 'NULL'
	: ($_[3] =~/\d+/) && ($_[3] =~/^[+-]{0,1}[\d]+(?:\.[\d]+){0,1}$/)
			  ## ($_[3] =~/^[+-]{0,1}[\d ,]+(?:.[\d ,]+){0,1}$/)
	? $_[3]
	: !$_[0]->{-dbi}
	? strquot($_[0], $_[3])
	: $_[0]->{-dbi}->quote($_[3])
	)
  : $t->{-mdefld}->{$_[2]}->{-flg} =~/["']/
  ? (!$_[0]->{-dbi} ? strquot($_[0], $_[3]) : $_[0]->{-dbi}->quote($_[3]))
  : $t->{-mdefld}->{$_[2]}->{-flg} =~/[9n]/
  ? $_[3]
  : !defined($_[3])
  ? 'NULL'
  : ($_[3] =~/\d/) && ($_[3] =~/^[+-]{0,1}[\d]+(?:\.[\d]+){0,1}$/)
		   ## ($_[3] =~/^[+-]{0,1}[\d ,]+(?:.[\d ,]+){0,1}$/)
  ? $_[3]
  : !$_[0]->{-dbi}
  ? strquot($_[0], $_[3])
  : $_[0]->{-dbi}->quote($_[3])
}


sub mdeSubj {	# Subject generalized of record
		# (self, data) | (self, meta, data) -> subject
 if ($#_ >1) {
 }
 (      ref($_[0]->{-tn}->{-ridSubject}) eq 'CODE'
	? &{$_[0]->{-tn}->{-ridSubject}}(@_)
	: join(' ', map {
				!defined($_[1]->{$_}) || ($_[1]->{$_} eq '')
				? ()
				: ($_[1]->{$_})
					} @{$_[0]->{-tn}->{-ridSubject}}))
	||''
}


sub mdeReaders {# Table readers fields
		# self, table
 my $r =!$_[0]->{-rac} || $_[0]->uadmrdr()
 ?      undef
 :	ref($_[1])
 ?	[@{$_[1]->{-racReader} ||$_[0]->{-racReader} ||[]}
	,@{$_[1]->{-racWriter} ||$_[0]->{-racWriter} ||[]}]
 :	[@{$_[0]->{-table}->{$_[1]}->{-racReader} ||$_[0]->{-racReader}||[]}
	,@{$_[0]->{-table}->{$_[1]}->{-racWriter} ||$_[0]->{-racWriter}||[]}];
#$_[0]->logRec('mdeReaders',@_[1..$#_],$r);
 ref($r) && @$r ? $r : undef
}


sub mdeWriters {# Table writers fields
		# self, table
 	!$_[0]->{-rac} || $_[0]->uadmwtr()
 ?      undef
 :	ref($_[1])
 ?	$_[1]->{-racWriter} ||$_[0]->{-racWriter} ||undef
 :	$_[0]->{-table}->{$_[1]}->{-racWriter} ||$_[0]->{-racWriter} ||undef
}


sub mdeRAC {	# Table record access control condition
		# self, table/form, ? option switch
 if ($_[2]) {
	my $m =ref($_[1]) ? $_[1] : ($_[0]->{-form}->{$_[1]} ||$_[0]->{-table}->{$_[1]} ||{});
	return(undef) if exists($m->{$_[2]}) && !$m->{$_[2]};
 }
 my $m =(ref($_[1])
	? ($_[1]->{-table} ? $_[0]->{-table}->{$_[1]->{-table}} : $_[1])
	:  $_[0]->{-form}->{$_[1]}
	? ($_[0]->{-form}->{$_[1]}->{-table} ? $_[0]->{-table}->{$_[0]->{-form}->{$_[1]}->{-table}} : $_[0]->{-form}->{$_[1]})
	:  $_[0]->{-table}->{$_[1]}
	) ||{};
	( $m->{-racActor}	||$_[0]->{-racActor} 
	||$m->{-racManager}	||$_[0]->{-racManager}
	||$m->{-racPrincipal}	||$_[0]->{-racPrincipal}
	||$m->{-racUser}	||$_[0]->{-racUser}
	||$m->{-racWriter}	||$_[0]->{-racWriter} 
	||$m->{-rvcUpdBy}	||$_[0]->{-rvcUpdBy}
	) && $m
}


sub mdeRole {	# Table user role fields list
		# self, table, role, ? altrole
 my $m =ref($_[1]) ? $_[1] : $_[0]->{-table}->{$_[1]};
 my $r =$_[2] eq 'all'
 ?	undef
 :	$_[2] eq 'creator'
 ?	[$m->{-rvcInsBy} ||$_[0]->{-rvcInsBy} ||()]
 :	$_[2] eq 'updater'
 ?	[$m->{-rvcUpdBy} ||$_[0]->{-rvcUpdBy} ||()]
 :	$_[2] eq 'author'
 ?	[$m->{-rvcInsBy} ||$_[0]->{-rvcInsBy} ||()
	,$m->{-rvcUpdBy} ||$_[0]->{-rvcUpdBy} ||()]
 :	$_[2] eq 'authors'
 ?	$m->{-racWriter} ||$_[0]->{-racWriter} 
		|| mdeRole($_[0], $m, $_[3] ||'author')
 :      $_[2] eq 'actor'
 ?	$m->{-racActor} &&[$m->{-racActor}->[0]] 
		|| $_[0]->{-racActor} &&[$_[0]->{-racActor}->[0]] 
		||mdeRole($_[0], $m, $_[3] ||'actors')
 :	$_[2] eq 'actors'
 ?	$m->{-racActor} ||$_[0]->{-racActor} 
		|| ($_[3] ? mdeRole($_[0], $m, $_[3]) : undef)
		|| ($m->{-rvcUpdBy}	&& [$m->{-rvcUpdBy}])
		|| ($_[0]->{-rvcUpdBy}	&& [$_[0]->{-rvcUpdBy}])
		|| mdeRole($_[0], $m, 'authors')
 :      $_[2] eq 'manager'
 ?	$m->{-racManager} &&[$m->{-racManager}->[0]] 
		|| $_[0]->{-racManager} &&[$_[0]->{-racManager}->[0]] 
		||mdeRole($_[0], $m, $_[3] ||'managers')
 :	$_[2] eq 'managers'
 ?	$m->{-racManager} ||$_[0]->{-racManager}
		|| ($_[3] ? mdeRole($_[0], $m, $_[3]) : undef)
		|| ($m->{-rvcInsBy}	&& [$m->{-rvcInsBy}])
		|| ($_[0]->{-rvcInsBy}	&& [$_[0]->{-rvcInsBy}])
		|| mdeRole($_[0], $m, 'author')
 :      $_[2] eq 'principal'
 ?	$m->{-racPrincipal} &&[$m->{-racPrincipal}->[0]] 
		|| $_[0]->{-racPrincipal} &&[$_[0]->{-racPrincipal}->[0]]
		|| mdeRole($_[0], $m, $_[3] ||'principals')
 :	$_[2] eq 'principals'
 ?	$m->{-racPrincipal} ||$_[0]->{-racPrincipal}
		|| ($_[3] ? mdeRole($_[0], $m, $_[3]) : undef)
		|| ($m->{-rvcInsBy}	&& [$m->{-rvcInsBy}])
		|| ($_[0]->{-rvcInsBy}	&& [$_[0]->{-rvcInsBy}])
		|| mdeRole($_[0], $m, 'author')
 :      $_[2] eq 'user'
 ?	$m->{-racUser} &&[$m->{-racUser}->[0]]
		|| $_[0]->{-racUser} &&[$_[0]->{-racUser}->[0]] 
		|| mdeRole($_[0], $m, $_[3] ||'users')
 :	$_[2] eq 'users'
 ?	$m->{-racUser} ||$_[0]->{-racUser}
		|| mdeRole($_[0], $m, $_[3] ||'principals')
 :	mdeRole($_[0], $m, 'authors');
 ref($r) && @$r ? $r : undef
}


sub mdeRoles {	# Table user roles list
		# self, table/form ||0, ? pass value
 return(qw(all author authors actor actors manager managers principal principals user users))
	if !$_[1];
 my $m =!$_[1] ? $_[1] : (mdeRAC(@_) ||{});
 my $v;
 my @l =('all'
	#,!$m ||$m->{-rvcInsBy}	||$_[0]->{-rvcInsBy}	? ('creator')	: ()
	#,!$m ||$m->{-rvcUpdBy}	||$_[0]->{-rvcUpdBy}	? ('updater')	: ()
	,!$m ||$m->{-rvcInsBy}	||$_[0]->{-rvcInsBy}	||
	 !$m ||$m->{-rvcUpdBy}	||$_[0]->{-rvcUpdBy}	? ('author')	: ()
	,!$m ||$m->{-racWriter}	||$_[0]->{-racWriter}	? ('authors')	: ()
	,(!($v =!$m ||$m->{-racActor}||$_[0]->{-racActor})
		? () : $#$v >0 ? (qw(actor actors)) : qw(actor))
	,(!($v =!$m ||$m->{-racManager}||$_[0]->{-racManager})
		? () : $#$v >0 ? (qw(manager managers)) : qw(manager))
	,(!($v =!$m ||$m->{-racPrincipal}||$_[0]->{-racPrincipal})
		? () : $#$v >0 ? (qw(principal principals)) : qw(principal))
	,(!($v =!$m ||$m->{-racUser}||$_[0]->{-racUser})
		? () : $#$v >0 ? (qw(user users)) : qw(user))
	);
 push @l, $_[2] if $_[2] && !grep {$_ eq $_[2]} @l;
 @l
}


sub mdeFldIU {	# Field of Inserters/Updaters
    $_[2]	# self, table meta, field
&&(($_[1]->{-rvcInsBy} && ($_[1]->{-rvcInsBy} eq $_[2]))
|| ($_[0]->{-rvcInsBy} && ($_[0]->{-rvcInsBy} eq $_[2]))
|| ($_[1]->{-rvcUpdBy} && ($_[1]->{-rvcUpdBy} eq $_[2]))
|| ($_[0]->{-rvcUpdBy} && ($_[0]->{-rvcUpdBy} eq $_[2])))
}


sub mdeFldRW {	# Field of Readers/Writers
		# self, table meta, field
 return(undef)	if !$_[2] 
		|| !($_[1]->{-racReader} ||$_[0]->{-racReader} ||$_[1]->{-racWriter} ||$_[0]->{-racWriter});
 foreach my $e (  $_[1]->{-racReader} ? @{$_[1]->{-racReader}} : $_[0]->{-racReader} ? @{$_[0]->{-racReader}} : ()
		, $_[1]->{-racWriter} ? @{$_[1]->{-racWriter}} : $_[0]->{-racWriter} ? @{$_[0]->{-racWriter}} : ()) {
	return($_[2]) if $e eq $_[2]
 }
 return(undef)
}


sub mddUrole {	# Display UROLE
 my ($s, $m, $n) =@_;	# self, meta, role
 $m =$s->mdeTable($m->{-table}) if $m->{-table};
 my $l =$s->mdeRole($m, $n);
 join(', '
	, $l
	? (map {$_ && $m && $m->{-mdefld} && $m->{-mdefld}->{$_}
	#	&& ($s->lngslot($m->{-mdefld}->{$_},'-lbl') || $s->lng(0,$_))
		&& $s->lnglbl($m->{-mdefld}->{$_},'-fld')
		|| $_
		} @$l)
	: ()
	, $n =~/^(?:manager|principal|user)$/i
	? '! ' .$s->mddUrole($m, 'actor')
	: $n =~/^(?:managers|principals|users)$/i
	? '! ' .$s->mddUrole($m, 'actors')
	: ()
	) || $n
}


sub recType {   # Record type or table name
 $_[1]->{-table}
 || ($_[1]->{-form} && $_[0]->{-form}->{$_[1]->{-form}} && $_[0]->{-form}->{$_[1]->{-form}}->{-table})
 || (ref($_[2]) ne 'HASH' && substr($_[2], 0, index($_[2],'='))) # class name
}


sub recFields { # Field names in the record hash
		# !!! sort degradation, needed to use 'recValues'
 sort grep {substr($_,0,1) ne '-' && substr($_,0,1) ne '.'} keys %{$_[1]}
}


sub recValues { # Field values in the record hash
 map {$_[1]->{$_}} recFields($_[0], $_[1])
}


sub recData {   # Field name => value hash ref
 return({map {($_=> $_[1]->{$_})} recFields($_[0], $_[1])})
}


sub recKey {	# Record's key: field => value hash ref
		# self, table name, record
 my $m =$_[0]->{-table}->{$_[1]} ||$_[0]->{-form}->{$_[1]};
   $m && $m->{-key}
 ? {map {($_=>$_[2]->{$_})}  @{$m->{-key}}}
 : $_[2]->{'id'}		# 'id' field present
 ? {'id'=>$_[2]->{'id'}}
 : {}
}


sub recWKey {	# Record's optimistic key: field => value hash ref
		# self, table name, record
 my $m =$_[0]->{-form}->{$_[1]} ||$_[0]->{-table}->{$_[1]};
 return(recKey(@_)) if !$m;
 my $r ={};
 if	($m->{-wkey}) {
	$r ={map {($_=>$_[2]->{$_})
		}  grep {defined($_[2]->{$_})
			} @{$m->{-wkey}}}
 }
 %$r ? $r : recKey(@_)
}


sub rmlClause { # Command clause words and values list from record's hash ref
		# (record manipulation language)
		# !!! sort degradation, for nice display
 map {($_=>$_[1]->{$_})} sort grep {substr($_,0,1) eq '-'} keys %{$_[1]}
}


sub rmlKey {  # Record's '-key' clause value
                # ($self, {command}, {data})
   $_[1]->{-key} && !ref($_[1]->{-key})		# should be translated
 ? {'id'=>rmlIdSplit(@_[0,1],$_[1]->{-key})}
 : $_[1]->{-key}				# already exists
 ? $_[1]->{-key}
 : $_[1]->{-where}				# not needed using '-where'
 ? $_[1]->{-key}
 : $_[1]->{-table}				# key described
	&& $_[0]->{-table}->{$_[1]->{-table}}->{-key}
 ? {(map {($_=>$_[2]->{$_})} 
	@{$_[0]->{-table}{$_[1]->{-table}}->{-key}})}
 : $_[2]->{'id'}				# 'id' field present
 ? {'id'=>rmlIdSplit(@_[0,1],$_[2]->{'id'})}
 : undef
}


sub rmlIdSplit {# Split record ID into table name and real ID
		# ($self, {command}, key value)
  !$_[0]->{-idsplit} 
 ? $_[2]
 : ref($_[0]->{-idsplit}) 
 ? &{$_[0]->{-idsplit}}(@_)
 : $_[2] =~m/([^\Q$RISM0\E]+)\Q$RISM1\E((?:.(?!\Q$RISM1\E))+)$/
	# !!! optimize: 'database $RISM0 table $RISM1 rowid'
 ? eval{$_[1]->{-table}=$1; $2}	# 'table//rowid', table !~m!/!, rowid !~m!//!
 : $_[2]
}


sub rmiTrigger {# Execute trigger
		# (record manipulation internal)
                # self, {command}, {data}, {record}, trigger names
 my $tbl =$_[1]->{-table} && $_[0]->{-table}->{$_[1]->{-table}};
 my $frm =$_[1]->{-form} && $_[0]->{-form} && $_[0]->{-form}->{$_[1]->{-form}};
 local $_[1]->{-cmdt} =$tbl || $frm;	# table metadata
 local $_[1]->{-cmdf} =$frm || $tbl;	# form  metadata
 local $_[0]->{-affect}	=undef;
 local $_[0]->{-rac}	=undef;
 foreach my $t (@_[4..$#_]) {
	$_[0]->logRec('rmiTrigger'
		, (caller(1))[3] =~/([^:]+)$/ ? $1 : (caller(1))[3]
		, -cmd=>$_[1]->{-cmd} || 'undef'
		, $tbl && $_[1]->{-table} ? (-table=>$_[1]->{-table}) : ()
		, $frm && $_[1]->{-form}  ? (-form=>$_[1]->{-form}) : ()
		, $_[1]->{-key} ? (-key=>$_[1]->{-key}) : ()
	#	, $_[2] ? (-data=>$_[2]) : ()
		, join(' ',@_[4..$#_])
		) if 0;
	&{$_[0]->{$t}}($_[0], $_[1], $_[2], $_[3]) if $_[0]->{$t} && !($t eq '-recInsID' && $tbl && $tbl->{$t});
	&{$tbl->{$t}} ($_[0], $_[1], $_[2], $_[3]) if $tbl && $tbl->{$t};
	&{$frm->{$t}} ($_[0], $_[1], $_[2], $_[3]) if $frm && $frm->{$t} && ($frm->{$t} ne $tbl->{$t});
 }
 $_[0]
}


sub rmiIndex {  # Index record
		# {-table=>name}, {newData=>value}, {oldData=>value}
 my ($s, $a, $d, $r) =@_;
 my  $n =$d; # {%$r} ||{}; @{$n}{keys %$d} =values %$d;
 my  @q =([undef,'-'],[undef,'+']);
 local $s->{-affect}	=undef;
 local $s->{-rac}	=undef;
 if (my $m =$s->{-table}->{$a->{-table}}->{-recIndex0R}) {
	&$m($s, $a, $d, $r)
 }
 foreach my $x (keys %{$s->{-table}}) {
	next if !ref($s->{-table}->{$x}->{-ixcnd});
	my $i =$s->{-table}->{$x};
	$q[0]->[0] =$r && &{$i->{-ixcnd}}($s, $a, $r) ? $r : 0; # delete
	$q[1]->[0] =$d && &{$i->{-ixcnd}}($s, $a, $n) ? $n : 0; # insert/update
	foreach my $q (@q) {
		next if !$q->[0];
		my $v =	  $i->{-ixrec} 
			? &{$i->{-ixrec}}($s, $a, $q->[0], $q->[1])
			: $i->{-field} && ref($i->{-field}) eq 'ARRAY'
			? {map {$q->[0]->{$_}} grep {ref($_) && $_->{-fld}} @{$i->{-field}}}
			: $i->{-field} && ref($i->{-field}) eq 'HASH'
			? {map {$q->[0]->{$_}} keys %{$i->{-field}}}
			: undef;
		foreach my $r (!ref($v) ? () : ref($v) eq 'ARRAY' ? @$v : ($v)) {
			my $k =rmlKey($s, {-table=>$x}, $r);
			$q->[1] eq '-'
			? $s->dbiDel({-table=>$x, -key=>$k}, $r)
			: 1 && eval{$s->dbiIns({-table=>$x, -key=>$k}, $r)}
			? 0	# !!! dbiIns better, dbiUpd safer
			: $s->dbiUpd({-table=>$x, -key=>$k, -save=>1}, $r, $d);
		}
	}
 }
 $d
}


sub recIndex {	# Update/delete index entry, for calls from '-recIndex0R'
		# index name, {key}, {data}||undef
 !$_[0]->{-table}->{$_[1]}->{-ixcnd}
 ? &{$_[0]->{-die}}('recIndex(' .$_[1] .') -> not described index' .$_[0]->{-ermd})
 : $_[3]
 ? $_[0]->dbiUpd({-table=>$_[1], -key=>$_[2], -save=>1}, $_[$#_])
 : $_[0]->dbiDel({-table=>$_[1], -key=>$_[2]});
}


sub recReindex{	# Reindex database
		# self, clear, indexes
 my ($s, $c, @i) =@_;
 $s->varLock();
 my @t =grep {!$s->{-table}->{$_}->{-ixcnd}} $s->mdlTable();
    @i =grep { $s->{-table}->{$_}->{-ixcnd}} keys %{$s->{-table}} if !@i;
 if ($c) {
	foreach my $i (@i) {
		$s->dbiTrunc($i);
	}
 }
 foreach my $t (@t) {
	$s->logRec('recReindex', $t);
	my $a ={-table=>$t,-version=>1};
	my $c =$s->recSel(%$a);
	my $r;
	while ($r =$c->fetchrow_hashref()) {
		$s->logRec('recReindex',$r);
		$s->rmiIndex($a, $r)
	}
 }
 $s
}


sub rfdName {	# Record's files directory name
		# self, command |table name, record data, subdirectory,...
 my $t =ref($_[1]) ? $_[1]->{-table} : $_[1];
 my $m =$_[0]->{-table}->{$t};
 join('/'
	, $_[0]->{-cgibus}
	? ($t
	  ,$_[2]->{$m->{-rvcActPtr} ||$_[0]->{-rvcActPtr} ||'-none'} ? 'ver' : 'act')
	: ($_[2]->{$m->{-rvcActPtr} ||$_[0]->{-rvcActPtr} ||'-none'} ? 'v'   : 'a'
	  ,$t)
	, &{$m->{-rfdName} 
	||$_[0]->{-rfdName} 
	||sub{		my $r ='';
			foreach my $e (@_[1..$#_]) {
				for (my $i =0; $i <=length($e); $i +=3) {
					my $v =substr($e, $i, 3);
					# $v =~s/([,;+:'"?*%\/\\])/uc sprintf("%%%02x",ord($1))/eg;
					$v =~s/([^a-z0-9_-])/uc sprintf("%%%02x",ord($1))/eg;
					$r .=$v .'/'
				}
			}
			chop($r);
			$r
		}}(
		$_[0]
		, map {	defined($_[2]->{$_}) ? $_[2]->{$_} : $_[1]->{-key}->{$_}
			} @{$m->{-key}})
	. $RISM2
	, map {	my $v =$_; 
		$v =~s/([,;+:'"?*%])/uc sprintf("%%%02x",ord($1))/eg;
		$v} @_[3..$#_]	# encoding as 'rfaUpload'
	)
}


sub rfdPath {	# Record's files directory path
		# self, -path|-url|-urf, rfdName |{data} |({command}|table, {data}), ?subdirectory...
 return(undef)	if !$_[0]->{$_[1]};
 join('/'
	, $_[0]->{-cgibus}
	? ($_[1] eq '-path' 
		? $_[0]->{-cgibus} 
		: $_[1] ne '-urf'
		? $_[0]->{$_[1]}
		: !$_[0]->{$_[1]}	# !!! lost code, for example
		? (($ENV{REMOTE_ADDR}||'') ne '127.0.0.1' ? $_[0]->{-url} : $_[0]->{-path})
		: $_[0]->{$_[1]})
	: $_[1] ne '-urf'
	? $_[0]->{$_[1]} .'/rfa' # -url, -path
	: !$_[0]->{$_[1]}		# !!! lost code, for example
	? (($ENV{REMOTE_ADDR}||'') ne '127.0.0.1' ? $_[0]->{-url} : $_[0]->{-path}) .'/rfa'
	: ($_[0]->{-urf} eq $_[0]->{-url}) 
		|| (substr($_[0]->{-urf},7) eq $_[0]->{-path})
	? $_[0]->{-urf} .'/rfa'
	: $_[0]->{-urf}
	, !ref($_[3]) # rfdName, !ref($_[2]) && !ref($_[3])
	? ((ref($_[2]) 
		? $_[2]->{-file} 
		|| return(&{$_[0]->{-die}}('rfdPath(' .$_[0]->strdata(@_) .') -> no file attachments' .$_[0]->{-ermd})||'')
		: $_[2])
	  ,map {my $v =$_;
		$v =~s/([,;+:'"?*%])/uc sprintf("%%%02x",ord($1))/eg;
		$v} @_[3..$#_])	# encoding as 'rfdName' and 'rfaUpload'
	: rfdName($_[0],@_[2..$#_]))
}


sub rfdEdmd {	# Record's files directory editing allowed?
		# self, command |table name, record data
 my $m =$_[0]->{-table}->{
		ref($_[1]) 
		? ($_[1]->{-table} || $_[1]->{-form} && $_[0]->{-form}->{$_[1]->{-form}}->{-table})
		: ($_[0]->{-table}->{$_[1]} && $_[1] ||$_[0]->{-form}->{$_[1]}->{-table})
		};
 my $u =$m->{-rvcChgState}	||$_[0]->{-rvcChgState};
 my $v =$m->{-rvcActPtr}	||$_[0]->{-rvcActPtr};
 my $r =$_[2];
 !$v || ($u && ($r->{$u->[0]} && grep {$r->{$u->[0]} eq $_} @{$u}[1..$#$u]))
}


sub rfdTime {	# mtime of record files directory
		# self, (command |table name, record data) |rfdName
 (stat(rfdPath($_[0], -path=>$_[2] ? rfdName(@_[0..2]) : $_[1])))[9];
}


sub rfdStamp {	# Stamp record with files directory name, create if needed
		# self, command |table name, record data, acl set
 my $d =rfdName(@_[0..2]);
 my $p =rfdPath($_[0],-path=>$d);
 my $e =rfdEdmd(@_[0..2]);
 my $r =$_[2];
 my $w =$_[3];

 if ($e && !-d $p) {
	$_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
	$_[0]->pthMk($p);
 }	

 if (-d $p)	{ $r->{-file} =$d; $r->{-fupd} =$d if $e}
 else		{ delete $r->{-file}; delete $r->{-fupd}}

 if ($r->{-file} && $w) {	# set ACL
	$_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
	my $s =$_[0];
	my $m =$s->{-table}->{ref($_[1]) ? $_[1]->{-table} : $_[1]};
	my $wr=$m->{-racReader} ||$s->{-racReader};
	   $wr=[map {defined($r->{$_}) ? (split /\s*[,;]\s*/i, $r->{$_}) : ()} @$wr] if $wr;
	my $ww=$m->{-racWriter} ||$s->{-racWriter};
	   $ww=[map {defined($r->{$_}) ? (split /\s*[,;]\s*/i, $r->{$_}) : ()} @$ww] if $ww;
	if ($wr ||$ww) {
		my $ld=$^O eq 'MSWin32' && $s->w32domain() || '';
		my @wa=	map {$_ =~s/ /_/g; $_}
			map {$_ =~/^([^\\@]+)([\\@])([^\\@]+)$/ 
				? ($_, $3 .($2 eq '@' ? '\\' : '@') .$1) 
				: $ld
				? ($_, $ld .'\\' .$_, $_ .'@' .$ld)
				: $_}
			(map {!$_ ? () : ref($_) ? @$_ : ($_)
				} $s->{-fswtr}, $s->{-fsrdr}, $ww, $wr);
					# ||getlogin()
		my $wf=$s->hfNew('+>',"$p/.htaccess");
		$wf->store('<Files "*">', "\n"
			,"require user\t"	.join(' ',@wa), "\n"
			,"require group\t"	.join(' ',@wa), "\n"
			,'</Files>',"\n");
		$wf->close();
	}
	if (($wr ||$ww) && $^O eq 'MSWin32' && Win32::IsWinNT()) { # $ENV{OS} && $ENV{OS}=~/Windows_NT/i
		# !!! WMI may be better/faster for all filesystem security
		# MSDN:	WMI Security Descriptor Objects
		#	Win32_LogicalFileSecuritySetting
		#	Win32_LogicalFileSecuritySetting.GetSecurityDescriptor
		#	Win32_LogicalFileSecuritySetting.SetSecurityDescriptor
		#	Win32_SecurityDescriptor
		#	Win32_ACE	# how to create?
		#	Win32_Trustee	# how to create?
		# $wmiobj=Win32::OLE->GetObject("winmgmts:Win32_LogicalFileSecuritySetting.path='$obj'")
		# $out=$wmiobj->ExecMethod_("GetSecurityDescriptor");
		# die if !$out ||$out->{ReturnValue};
		# $out->{Descriptor}->{Owner}->{Domain}
		# 	.'\\' .$out->{Descriptor}->{Owner}->{Name};
		# $dacl=$out->{Descriptor}->{DACL};
		# die if !$dacl;
		# foreach my $k (@$dacl) {
		# $k->{Trustee}->{Domain}
		# $k->{Trustee}->{Name}
		# $k->{AceType}
		#	0 ADS_ACETYPE_ACCESS_ALLOWED
		#		=| $k->{AccessMask}
		#	1 ADS_ACETYPE_ACCESS_DENIED
		# 		=& $k->{AccessMask}
		# %permf=('FULL'=>2032127,'CHANGE'=>1245631,'ADD&READ&EXECUTE'=>1180095,'ADD&READ'=>1180063,'READ&EXECUTE'=>1179817,'READ'=>1179785,'ADD'=>1048854);
		# %permd=('FULL'=>2032127,'CHANGE'=>1245631,'ADD&READ'=>1180095,'READ'=>1179817,'LIST'=>1179785,'ADD'=>1048854);
		# $k->{AccessMask} >=$perm{$k->{AccessMask}}
		# xcacls.vbs
		# objLocator.ConnectServer.Get("Win32_SecurityDescriptor").Spawninstance_
		#
		$p =~s/\//\\/g;
		$s->pthStamp($p);			# access control
		delete $s->{-c}->{-pthStamp};
		if ($e && $ww) {
			foreach my $u (map {m/([^@]+)\@([^@]+)/ ? "$2\\$1" : $_} @$ww) {
				$s->osCmd('-i'
				, $s->{-w32xcacls} ? 'xcacls' : 'cacls'
				, "\"$p\""
				, '/E','/T','/C','/G'
				, ($u =~/\s/ ? "\"$u\"" : $u) .':F'
				, $s->{-w32xcacls} ? '/Y' : ())
			}
			foreach my $u (map {m/([^@]+)\@([^@]+)/ ? "$2\\$1" : $_} $wr ? @$wr : ()) {
				$s->osCmd('-i'
				, $s->{-w32xcacls} ? 'xcacls' : 'cacls'
				, "\"$p\""
				, '/E','/T','/C','/G'
				, ($u =~/\s/ ? "\"$u\"" : $u) .':R'
				, $s->{-w32xcacls} ? '/Y' : ())
			}
		}
		else {
			foreach my $u (map {m/([^@]+)\@([^@]+)/ ? "$2\\$1" : $_
					} map {$_ ? @$_ : ()} $ww, $wr) {
				$s->osCmd('-i'
				, $s->{-w32xcacls} ? 'xcacls' : 'cacls'
				, "\"$p\""
				, '/E','/T','/C','/G'
				, ($u =~/\s/ ? "\"$u\"" : $u) .':R'
				, $s->{-w32xcacls} ? '/Y' : ())
			}
		}
	}
	if ($w && ($w =~/^\d+$/)) {
		my $wa =(stat($p))[8];
		$s->logRec('utime', $s->strtime($wa||$w), $s->strtime($w), $r->{-file});
		utime($wa ||$w, $w, $p);
	}
 }

 $r->{-file}
}


sub rfdCp {	# Copy record's files directory to another record
		# self, source {record} |rfdName, dest {command} |table, {record}
 $_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
 my $fd =ref($_[1]) ? $_[1]->{-file} : $_[1];
    return(0) if !$fd;
 my $fp =rfdPath($_[0],-path=>$fd);
    return(0) if ! -d $fp;
 my $td =rfdName($_[0], @_[2..$#_]);
 my $tp =rfdPath($_[0],-path=>$td);
 $_[0]->pthCp('-rdp*',$fp,$tp)
 && ($_[3]->{-file} =$td);
}


sub rfdRm {	# Remove record's files directory
		# self, rfdName |{record} |({command} |table, {record})
 $_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
 my $p =rfdPath($_[0], -path=>ref($_[1]) && $_[1]->{-file} ? $_[1]->{-file} : @_[1..max($_[0], 2, $#_)]);
    $p =-d $p ? $_[0]->pthRm('-r', $p) && $_[0]->pthCln($p) : $p;
 delete $_[1]->{-file} if $p && ref($_[1]);
 $p
}


sub rfdCln {	# Clean record's files directory, delete if empty
		# self, rfdName |{record} |({command} |table, {record})
 $_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
 my $p =rfdPath($_[0], -path=>ref($_[1]) && $_[1]->{-file} ? $_[1]->{-file} : @_[1..max($_[0], 2, $#_)]);
    $p =$_[0]->pthCln($p);
 delete $_[1]->{-file} if $p && ref($_[1]) && !-d $p;
 $p
}


sub rfdGlobn {	# Glob record's files directory, return attachments names
		# self, rfdName |{record} |({command} |table, {record}), subdirectory...
 $_[0]->pthGlobn($_[0]->rfdPath(-path=>@_[1..$#_]) .'/*')
}


sub rfaRm {	# Delete named attachment(s) in record's files directory
		# self, rfdName |{record} |({command} |table, {record}), attachment|[attachments]
 $_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
 grep {$_[0]->pthRm('-r',$_[0]->rfdPath(-path=>@_[1..$#_-1], $_))
	} ref($_[$#_]) ? @{$_[$#_]} : $_[$#_]
}


sub rfaUpload {	# Upload named attachment into record's files directory
		# self, rfdName |{record} |({command} |table, {record}), cgi file
 $_[0]->w32IISdpsn()	if $_[0]->{-w32IISdpsn} && !$_[0]->{-c}->{-RevertToSelf};
 my $fn =$_[0]->cgi->param($_[$#_]);
    $fn =$fn =~/[\\\/]([^\\\/]+)$/ ? $1 : $fn;
    $fn =~s/([,;+:'"?*%])/uc sprintf("%%%02x",ord($1))/eg;
 my $fh =$_[0]->cgi->upload($_[$#_])
        ||return(&{$_[0]->{-die}}($_[0]->lng(0,'rfaUpload') ."('" .$_[$#_] ."') CGI::upload -> " .$_[0]->lng(1,'rfaUplEmpty') ."\n"));
 binmode($fh);
 eval('use File::Copy');
 File::Copy::copy($fh, $_[0]->rfdPath(-path=>@_[1..$#_-1], $fn))
 || &{$_[0]->{-die}}($_[0]->lng(0,'rfaUpload') ."('" .$_[$#_] ."'): File::Copy::copy -> $!\n");
 eval{close($fh)};
}


sub recActor {	# User's role ('admin','owner','-...', field); cached using -editable
		# (table|command, record, ?db record , role | field | 0,...) -> boolean
 return(1)	if $_[0]->uadmin();
 return(recActor($_[0],$_[1],$_[3]||$_[2],@_[4..$#_]))
		if ref($_[3]) ||(!$_[3] && ($#_ >3));
 return(undef)	if !$_[3]
		|| !ref($_[2]);
 return($_[2]->{-editable})
		if exists($_[2]->{-editable}) 
		&& (!$_[2]->{-editable} || !$_[3]);
 return(scalar(grep {recActor($_[0],$_[1],$_[2],$_)} @_[3..$#_]))
		if $#_ >3;
 return($_[2]->{-editable}->{$_[3]})
		if ref($_[2]->{-editable})
		&& exists($_[2]->{-editable}->{$_[3]});
 my ($s,$f,$r,$n) =@_;
 if (!ref($f)) {}
 elsif ($f->{-cmdt})	{$f =$f->{-cmdt}}
 elsif ($f->{-table})	{$f =$f->{-table}}
 if (!exists($r->{-editable})) {
	my $mt=ref($f) ? $f : !$f ? undef : $s->mdeTable($f);
	return(undef)	if !$mt;
	my $w =mdeWriters($s, $mt);
	$r->{-editable} =!$w ||$s->ugmember(map {$r->{$_}} @$w);
	return(undef)	if !$r->{-editable};
 }
 return($_[2]->{-editable})	if !$n;
 $r->{-editable} ={} if !ref($r->{-editable});
 if ($n =~/^(-racOwner)$/) {	# 'owner' role
	my $n =$1;
	my $mt =ref($f) ? $f : !$f ? undef : $s->mdeTable($f);
	$r->{-editable}->{$n} =1;
	foreach my $k (qw(-rvcInsBy -rvcUpdBy)) {
		my $nf=($mt && $mt->{$k}) || ($s->{$k}) || ($s->{-tn}->{$k});
		next	if !$nf || !exists($r->{$nf})
			|| (lc($r->{$nf}) eq lc($s->user()));
		$r->{-editable}->{$n} =undef;
		last
	}
 }
 elsif (substr($n,0,1) eq '-') {	# -racReader, -racWriter; -racActor, -racManager, -racPrincipal, -racUser
	my $mt =ref($f) ? $f : !$f ? undef : $s->mdeTable($f);
	$r->{-editable}->{$n} =$s->ugmember(
			map {$r->{$_} ? $r->{$_} : ()
				} @{($mt && $mt->{$n}) || $s->{$n} ||[]})
 }
 else {					# field name
	$r->{-editable}->{$n} =!defined($r->{$n}) || ($r->{$n} eq '') 
				? undef 
				: $s->ugmember($r->{$n})
 }
#$s->logRec('recActor',$n) if $r->{-editable}->{$n};
 $r->{-editable}->{$n}
}


sub recActLim {	# Bound fields
 my ($s, $c, $rn, $rb, $fo, @fn) =@_;	# (cmd, new data, db data, opt, fld names | -recDel)
 my $rr =ref($rn) ? $rn : $rb;		# 1-'v'iew, 2-e'x'clude
 return(undef)	if !ref($rr);		# []-restrict values; '-recRead'
 $s->logRec('recActLim',$c->{-cmd},$fo, @fn);
 if ($fo eq '-recRead') {
	delete $rr->{-editable};
	return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,$c->{-cmd}) .": " .$s->lng(1,'recUpdAclStp') .$s->{-ermd}) && undef)
		if $c->{-cmd}
		&& ($c->{-cmd} !~/^(?:recRead)$/);
	return(1)
 }
 delete $rr->{-editable}  if ref($rr->{-editable}) && exists($rr->{-editable}->{-racWriter}) && !$rr->{-editable}->{-racWriter};
 $s->recActor($c, $rr, 0) if !$rr->{-editable};
 return(undef)	if !$rr->{-editable} && !$rr->{-new};
 return(!$c->{-cmdt}
	? return(&{$s->{-die}}($s->lng(0,'recActLim') ." no {-cmdt}" .$s->{-ermd}) && undef)
	: $s->recActLim($c, $rn, $rb, $1
	, (map{  my $n =(ref($_) ne 'HASH') ||!$_->{-fld}
				||(exists($_->{-edit}) && (!$_->{-edit} || ref($_->{-edit})))
				||($_->{-flg} && ($_->{-flg}!~/[aeu]/))
			? '' : $_->{-fld};
		  !$n
		? ()
		: !(grep {$n eq $_} @_[5..$#_])
		? ($n)
		: ()
		} @{$c->{-cmdt}->{-field}})))
	if $fo =~/^(\w)!/;
 $rr->{-editable} ={} if !ref($rr->{-editable});
 $rr->{-editable}->{-fr} ={} if !$rr->{-editable}->{-fr};
 $fo = $fo eq 'v' ? 1 : $fo eq 'x' ? 2 : 1
	if $fo && !ref($fo) && $fo =~/\w/;
 my $fh =$rr->{-editable}->{-fr};	# fields restrictions hash
 my $ds =undef;				# delete restriction
 if ($c->{-cmd} && ($c->{-cmd} =~/^(?:recRead|recForm)$/)
 && !$c->{-edit} ) {
	$fh->{-recDel} =$ds =1	if grep /^-recDel$/, @fn;
 }
 elsif ($c->{-cmd} && ($c->{-cmd} =~/^(?:recNew|recRead|recForm|recDel)$/)) {
	foreach my $fn (@fn) {
		$fh->{$fn} =$fo;
		if (ref($fo) && $rn && defined($rn->{$fn})
		&& !grep {$rn->{$fn} eq $_} @$fo) {
			$rn->{$fn} =$fo->[0];
		}
		$ds =1	if $fn eq '-recDel';
	}
 }
 else {
	foreach my $fn (@fn) {
		$fh->{$fn} =$fo;
		$ds =1	if $fn eq '-recDel';
		if	(!$fo
		||	(substr($fn,0,1) eq '-')
				) {
		}
		elsif (ref($fo)) {	# restricted values
			if (ref($rn) && (ref($fo) eq 'ARRAY')) {
				return(&{$s->{-die}}($s->{-ermu} 
					.$s->lng(0,'recUpd')
					." ('$fn', "
					.join(', ', map {defined($_) ? "'$_'" : 'undef'
							} $rn->{$fn}, @$fo)
					."): " .$s->lng(1,'recUpdAclStp') .$s->{-ermd}) && undef)
					if !defined($rn->{$fn})
					|| !(grep {$rn->{$fn} eq $_} @$fo);
			}
		}
		if (ref($rn) && ref($rb)) {
			if	($fo ==1) {	# view only
				return(&{$s->{-die}}($s->{-ermu}
					.$s->lng(0,'recUpd') 
					." ('$fn', "
					.join(', ', map {defined($_) ? "'$_'" : 'undef'
							} $rn->{$fn}, $rb->{$fn})
					."): " .$s->lng(1,'recUpdAclStp') .$s->{-ermd}) && undef)
					if (defined($rn->{$fn}) ? $rn->{$fn} : '')
					ne (defined($rb->{$fn}) ? $rb->{$fn} : '');
			}
			elsif	($fo ==2) {	# exclude
				delete $rn->{$fn}
			}
		}
		elsif (!$rb) {
			if	($fo ==1) {	# view only
			}
			elsif	($fo ==2) {	# exclude
				delete $rn->{$fn}
			}
		}
	}
 }
 if ($ds) {
	$ds =$c->{-cmdt} && $c->{-cmdt}->{-rvcDelState} ||$s->{-rvcDelState};
	$fh->{$ds->[0]} =[grep {  $_ ne $ds->[1]
				} ref($fh->{$ds->[0]})
				? @{$fh->{$ds->[0]}}
				: @{$c->{-cmdt}->{-mdefld}->{$ds->[0]}->{-inp}->{-values}}
				]
		if $ds
		&& (!$fh->{$ds->[0]} || (ref($fh->{$ds->[0]}) eq 'ARRAY'))
		&& $c->{-cmdt}->{-mdefld} && $c->{-cmdt}->{-mdefld}->{$ds->[0]}
		&& $c->{-cmdt}->{-mdefld}->{$ds->[0]}->{-inp}
		&& (ref($c->{-cmdt}->{-mdefld}->{$ds->[0]}->{-inp}->{-values}) eq 'ARRAY');
	return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recDel') .": " .$s->lng(1,'recDelAclStp') .$s->{-ermd}) && undef)
		if ($c->{-cmd} && ($c->{-cmd} eq 'recDel'))
		|| ($c->{-cmd} && ($c->{-cmd} !~/^(?:recRead|recForm)$/)
			&& $ds && $rn && $rn->{$ds->[0]}
			&& ($rn->{$ds->[0]} eq $ds->[1]));
 }
 1
}


sub recNew {    # Create new record to be inserted into database
		# -table=>name, field=>value || -data=>{values}
		# -key=>prototype record key, -proto=>{values}
 my	$s =$_[0];
	$s->logRec('recNew', @_[1..$#_]);
 my	$a =(@_< 3 && ref($_[1]) ? {%{$_[1]}} : {@_[1..$#_]});
 my	$d =$a->{-data} ? {%{$a->{-data}}} : exists($a->{-data}) ? {} : $a;
 my	$r =$d;
	$a->{-cmd}  ='recNew';
	$a->{-table}=recType ($s, $a, $d);
	$a->{-key}  =rmlKey($s, $a, {});
 my	$m =mdeTable($s,$a->{-table});
 foreach my $w (qw(-rvcInsBy -rvcUpdBy)) {foreach my $c ($m, $s) {
	next if !$c->{$w}; $r->{$c->{$w}} =$s->user; last
 }}
 foreach my $w (qw(-rvcInsWhen -rvcUpdWhen)) {foreach my $c ($m, $s) {
	next if !$c->{$w}; delete $r->{$c->{$w}}; last
 }}
 foreach my $w (qw(id -file -fupd)) {
	delete $r->{$w};
 }
 $r->{-new} =$s->strtime();
 $r->{-editable} =1 if $s->{-rac} && ($m->{-racWriter}||$s->{-racWriter});
 rmiTrigger($s, $a, $r, undef, qw(-recForm0C));
 my $p =$a->{-proto} || ((grep {$_} values %{$a->{-key}}) ? $s->recRead_($m, {%$a, -data=>undef, -test=>1}) : {});
 rmiTrigger($s, $a, $r, $p, qw(-recNew0C));
 rmiTrigger($s, $a, $r, undef,	qw(-recForm0R -recFlim0R -recEdt0R -recNew0R -recNew1C -recForm1C));
 $r
}


sub recForm {   # Recalculate record - new or existing
		# -table=>name, field=>value || -data=>{values}
		# -key=>original
 my	$s =$_[0];
	# $s->logRec('recForm', @_[1..$#_]);
 my	$a =(@_< 3 && ref($_[1]) ? {%{$_[1]}} : {@_[1..$#_]});
 my	$d =$a->{-data} ? {%{$a->{-data}}} : exists($a->{-data}) ? {} : $a;
	$a->{-cmd}  ='recForm';
	$a->{-table}=recType ($s, $a, $d);
	$a->{-key}  =rmlKey($s, $a, $d);
 my	$m =mdeTable($s,$a->{-table});
 rmiTrigger($s, $a, $d, undef, qw(-recForm0C));
 my	$r =(!$d->{-new} && (grep {$_} values %{$a->{-key}}) && $s->recRead_($m, {%$a,-data=>undef,-test=>1}))
		||undef;
	map {$d->{$_} =$r->{$_} if !exists($d->{$_})} keys %$r	if $r;
 foreach my $w (qw(-rvcInsBy -rvcUpdBy)) {foreach my $c ($m, $s) {
	next if !$c->{$w}; $d->{$c->{$w}} =$s->user if !$d->{$c->{$w}}; last
 }}
 $d->{-editable} =1 
	if ($r && $r->{-editable})
	|| ($d->{-new} && $s->{-rac} && ($m->{-racWriter}||$s->{-racWriter}));
 rmiTrigger($s, $a, $d, $r, qw(-recForm0R -recFlim0R -recEdt0R -recForm1C));
 $d
}


sub recIns {    # Insert record into database
		# -table=>table, field=>value || -data=>{values}
		# -key=>{sample}, -from=>cursor
 my	$s =$_[0];
	$s->varLock if $s->{-serial} && $s->{-serial} ==2;
	$s->logRec('recIns', @_[1..$#_]);
 my	$a =(@_< 3 && ref($_[1]) ? {%{$_[1]}} : {@_[1..$#_]});
 my	$d =$a->{-data} ? {%{$a->{-data}}} : exists($a->{-data}) ? {} : $a;
	$a->{-cmd}  ='recIns';
	$a->{-table}=recType ($s, $a, $d);
	$a->{-key}  =rmlKey($s, $a, $d);
 my	$m =mdeTable($s,$a->{-table});
 my	$v =$m->{-rvcActPtr}	||$s->{-rvcActPtr};
 my	$b =$m->{-rfa}	||$s->{-rfa};
 my	$tu=time();

 foreach my $w (qw(-rvcInsBy -rvcUpdBy)) {foreach my $c ($m, $s) {
	next if !$c->{$w}; $d->{$c->{$w}} =$s->user; last
 }}
 foreach my $w (qw(-rvcInsWhen -rvcUpdWhen)) {foreach my $c ($m, $s) {
	next if !$c->{$w}; $d->{$c->{$w}} =$s->strtime($tu); last
 }}

 rmiTrigger($s, $a, $d, undef, qw(-recForm0C -recIns0C));
 my	$r =undef;
 my	$p =(grep {$_} values %{$a->{-key}}) && $s->recRead_($m,{%$a, -data=>undef, -test=>1});
 if ($p) {		# form record with prototype
    my $t =recData($s, $p);
    delete $t->{$v};
    @{$t}{keys %$d} =values %$d;
    if ($a eq $d)	{$a =$d =$t}
    else		{$d =$t}
 }

 # !!! Permissions should be checked in -recIns0C trigger, no other way
 if ($a->{-from}) {	# insert from cursor
	my $j =0;
	while (my $e =$a->{-from}->fetchrow_hashref()) {
		my $t ={%$e};	# readonly hash
		rfdStamp($s, $a, $t) if $b;
		@{$t}{recFields($s, $d)} =recValues($s, $d);
		rmiTrigger($s, $a, $t, undef, qw(-recForm0R -recFlim0R -recEdt0R -recChg0R -recIns0R -recInsID -recChg0W));
		rfdCp	  ($s, $t->{-file}, $a, $t) if !$a->{-file} && $t && $t->{-file};
		rfdCp	  ($s, $p->{-file}, $a, $t) if !$a->{-file} && $p && $p->{-file};
		rfdCp	  ($s, $a->{-file}, $a, $t) if  $a->{-file};
		rmiIndex  ($s, $a, $t) if $m->{-index} ||$s->{-index};
		$r =$s->dbiIns($a, $t);
		rfdStamp($s, $a, $r, $tu) if $t && $t->{-file} || $p && $p->{-file};
		rmiTrigger($s, $a, $r, undef, qw(-recIns1R)) if $r;
		$j++;
	}
	$s->{-affected} =$j;
	rmiTrigger($s, $a, $r, undef, '-recIns1C', $j ==1 ? ('-recForm1C') : ())
			if $r;
	$r =$r ||$d;
 }
 else {			# insert single record
	rmiTrigger($s, $a, $d, undef, qw(-recForm0R -recFlim0R -recEdt0R -recChg0R -recIns0R -recInsID -recChg0W));
	rfdCp	  ($s, $p, $a, $d)		if !$a->{-file} && $p && $p->{-file};
	rfdCp	  ($s, $a->{-file}, $a, $d)	if  $a->{-file};
	rmiIndex  ($s, $a, $d, undef)		if $m->{-index} ||$s->{-index};
	$r =$s->dbiIns($a, $d);
	rfdStamp  ($s, $a, $r, $tu);
	$r->{-editable} =1 if $r && $s->{-rac} && ($m->{-racWriter}||$s->{-racWriter});
	$s->{-affected} =1;
	do {	local $a->{-cmd}  ='recRead';
		local $a->{-edit} =undef;
		rmiTrigger($s, $a, $r, $r, qw(-recForm0R -recFlim0R -recRead0R -recIns1R -recRead1R))
		}
		if $r;
	rmiTrigger($s, $a, $r, undef, qw(-recIns1C -recRead1C -recForm1C))
		if $r;
 }
 return($r)
}


sub dbiTblExpr {# DBI / SQL table name expression
  !$_[0]->{-table}->{$_[1]} || !$_[0]->{-table}->{$_[1]}->{-expr} 
 ? $_[1]
 : $_[0]->{-table}->{$_[1]}->{-expr} =~/\s/ 
 ? $_[0]->{-table}->{$_[1]}->{-expr}
 : $_[0]->{-table}->{$_[1]}->{-expr} .' AS ' .$_[1]
}


sub dbiTblExp1 {# DBI / SQL first table expression for insert/update/delete
  !$_[0]->{-table}->{$_[1]} || !$_[0]->{-table}->{$_[1]}->{-expr} 
 ? $_[1]
 : $_[0]->{-table}->{$_[1]}->{-expr} =~/^([^\s]+\s+AS\s+[^\s]+)/i
 ? $1
 : $_[0]->{-table}->{$_[1]}->{-expr} =~/\s/ 
 ? $`
 : $_[0]->{-table}->{$_[1]}->{-expr} # .' AS ' .$_[1] # sql syntax
}


sub dbiIns {    # Insert record into database
		# -table=>table, field=>value
		# -save=>boolean, -sel=>boolean
 my ($s, $a, $d) =@_;
 my  $f =$a->{-table};
 my  @c;
 my  $r =$a;
     $s->{-affected} =0;
 if (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi') {
	my $db=$s->dbi();
	my @a =recFields($s,$d);
	my @v;
	@c=( 'INSERT INTO ' 
		.dbiTblExp1($s, $f)
		.' (' .join(',', @a) 
		.') VALUES ('
		.join(','
			, $s->{-dbiph}
			? map {'?'} @a
		 	: map {mdeQuote($s, $s->{-table}->{$f}, $_, $d->{$_})
						} @a)
		.')'
		, $s->{-dbiph} ? ({}, map {$d->{$_}} @a) : ()
	);
	$s->logRec('dbiIns', @c);
	$db->do(@c)|| return(&{$s->{-die}}($s->lng(0,'dbiIns') .": do() -> " .($DBI::errstr ||'Unknown') .$s->{-ermd}) && undef);
	$s->{-affected} =$DBI::rows;
	$s->{-affected} =-$s->{-affected} if $s->{-affected} <0;
	return($d) if ($s->{-affected} >1) ||$a->{-save};
	return($d) if defined($a->{-sel}) && !$a->{-sel};
	if ($s->{-dbiph}) {
		@a =grep {defined($d->{$_})} @a;
		@v =map  {$d->{$_}} @a;
	}
	@c =('SELECT * FROM ' .dbiTblExp1($s, $f) .' WHERE '
		.join(' AND '
			, $s->{-dbiph}
			? map {"$_=?"} @a
			: map {defined($d->{$_})
				? ($_ .'=' .mdeQuote($s, $s->{-table}->{$f}, $_, $d->{$_}))
				: ()
				} @a));
	$s->logRec('dbiIns', @c, @v ? {} : (), @v);
	$f =$db->prepare(@c);
	$r =$f && $f->execute(@v) && $f->fetchrow_hashref() || return(&{$s->{-die}}($s->lng(0,'dbiIns') .": selectrow_hashref() -> " .($DBI::errstr||'Empty result set') .$s->{-ermd}) && undef);
 }
 elsif (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbm') {
	@c =	([map {$d->{$_}} 
			@{$s->{-table}->{$f}->{-key}}]
		,($r =recData($s, $d)));
	$s->logRec('dbiIns','kePut', $f, @c);
	$s->dbmTable($f)->kePut(@c) || return(&{$s->{-die}}($s->lng(0,'dbiIns') .": kePut() -> $@" .$s->{-ermd}) && undef);
	$s->{-affected} =1;
 }
 elsif (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'xmr') {
 }
 $r
}


sub dbiExplain {# Explain DML plan
 my $s =shift;
 return() if !$s->{-debug} || (defined($s->{-dbiexpl}) && !$s->{-dbiexpl});
 my $i =ref($_[0]) ? shift : $s->dbi;
 my $q =shift;
 eval {
   my $c =$i->prepare("explain $q");
       $c->execute;
    my $r;
    while ($r =$c->fetchrow_hashref()) {
      $s->logRec('dbiExplain', join(', ', map {"$_=> " .$s->strquot($r->{$_})} @{$c->{NAME}}));
    }
 }
}


sub recUpd {    # Update record(s) in database
		# -table=>table, field=>value || -data=>{values}
		# -key=>{field=>value}, -where=>'condition', -version=>'+'|'-'
		# -optrec=>boolean, -sel=>boolean
 my	$s =$_[0];
	$s->varLock if $s->{-serial} && $s->{-serial} ==2;
	$s->logRec('recUpd', @_[1..$#_]);
 my	$a =(@_< 3 && ref($_[1]) ? {%{$_[1]}} : {@_[1..$#_]});
 my	$d =$a->{-data} ? {%{$a->{-data}}} : exists($a->{-data}) ? {} : $a;
	$a->{-cmd}  ='recUpd';
	$a->{-table}=recType ($s, $a, $d);
	$a->{-key}  =rmlKey  ($s, $a, $d);
 my	$m =mdeTable($s,$a->{-table});
 my	$r =undef;
 my	$w =mdeWriters($s, $m);
 my	$u =$m->{-rvcChgState}	||$s->{-rvcChgState};
 my	$o =$m->{-rvcCkoState}	||$s->{-rvcCkoState};
 my	$x =$m->{-rvcDelState}	||$s->{-rvcDelState};
 my	$v =$m->{-rvcActPtr}	||$s->{-rvcActPtr};
 my	$tu=time();
 my	$t1=$m->{-rvcUpdWhen}	||$s->{-rvcUpdWhen};
 my	$t2=$m->{-rvcVerWhen}	||$s->{-rvcVerWhen};
 my	$i =$m->{-index}	||$s->{-index};
 my	$b =$m->{-rfa}		||$s->{-rfa};
 my	$e;
 local  $a->{-version}= ref($a->{-version})
			? $a->{-version}
			: $v && (!$a->{-version} ||$a->{-version} eq '-')
			? [$v, @{$x||[]}]
			: ($a->{-version} ||'+');
 foreach my $w (qw(-rvcInsBy -rvcInsWhen)) {foreach my $c ($m, $s) {
	next if !$c->{$w}; delete $d->{$c->{$w}}; last
 }}
 foreach my $c ($m, $s) {
	next if !$c->{-rvcUpdBy}; $d->{$c->{-rvcUpdBy}} =$s->user; last
 }
 $d->{$t1} =$s->strtime($tu) if $t1;
 rmiTrigger($s, $a, $d, undef, qw(-recForm0C -recUpd0C));
 if ($w ||$o ||$v ||$i ||grep {$s->{$_} || $m->{$_}} qw(-recForm0R -recFlim0R -recEdt0R -recChg0R -recUpd0R -recChg0W -recUpd1R)) {
	my $c =$s->recSel(rmlClause($s, $a), -data=>undef);
	my $j =0;
	while ($r =$c->fetchrow_hashref()) {
		$j++; return(&{$s->{-die}}($s->lng(0,'recUpd') .": $j ". $s->lng(1,'-affected') .$s->{-ermd}) && undef)
			if $s->{-affect} && $j >$s->{-affect};
		# $r ={%$r};	# readonly hash, should be considered below
		return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recUpd') .': ' .$s->lng(1,'recUpdAclStp') .$s->{-ermd}) && undef)
			if $w && !$s->ugmember(map {$r->{$_}} @$w);
		rfdStamp($s, $a, $r) if $b;
		my ($n, $p);
		if (($v	&& $r->{$v}			# prohibit version
			&& (!$o || (defined($r->{$o->[0]})
					&& ($r->{$o->[0]} ne $o->[1]))))
		||  ($x && defined($r->{$x->[0]})
			&& ($r->{$x->[0]} eq $x->[1])
			&& (!defined($d->{$x->[0]}) 
					|| ($d->{$x->[0]} eq $x->[1])))
					) {
			return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recUpd') .': ' .$s->lng(1,'recUpdVerStp') .$s->{-ermd}) && undef)
		}
		elsif ($o  				# check-in
			&& (($r->{$o->[0]}||'') eq $o->[1])
			&& defined($d->{$o->[0]})
			&& ($d->{$o->[0]} ne $o->[1])
			&& (!$x || (defined($d->{$x->[0]}) 
					&& ($d->{$x->[0]} ne $x->[1])))
			&& $r->{$v}) {
			my $t =$r->{'id'};
			$e =$s->recUpd(%$r, %{recData($s,$d)}
					, 'id'=>$r->{$v}
					, $v=>undef
					, -table=>$a->{-table}
					, -key=>{'id'=>$r->{$v}});
			rfdRm	($s, $a->{-table}, $r)	if $r->{-file};
			rmiIndex($s, $a, undef, $r)	if $i;
			$s->dbiDel({-table=>$a->{-table}, -key=>{'id'=>$t}});
			$n =undef;
		}
		elsif ($o				# check-out
			&& (($r->{$o->[0]}||'') ne $o->[1])
			&& (($d->{$o->[0]}||'') eq $o->[1])) {
			$n ={%$r}; @{$n}{recFields($s, $d)} =recValues($s, $d);
			$n->{$v} =$r->{'id'};
			rmiTrigger($s, $a, $n, $n, qw(-recForm0R -recFlim0R -recEdt0R -recChg0R -recUpd0R -recInsID -recChg0W));
			rfdCp	  ($s, $r->{-file}, $a, $n)	if $r->{-file};
			rfdStamp  ($s, $a, $n, $tu)		if $r->{-file};
			rmiIndex  ($s, $a, $n, undef)		if $m->{-index} ||$s->{-index};
			$e =$s->dbiIns($a, $n);
			$e->{-file} =$n->{-file}		if $n->{-file};
			$n =undef;
		}
		elsif ($v && (!$u			# version
				|| (defined($r->{$u->[0]})
				   && !grep {$r->{$u->[0]} eq $_
					} @{$u}[1..$#$u]))) {
			$n ={%$r}; @{$n}{recFields($s, $d)} =recValues($s, $d);
			$p ={%$r, $v=>$r->{'id'}, -table=>$a->{-table}};
			rmiTrigger($s, $a, $n, $r, qw(-recForm0R -recFlim0R -recEdt0R -recChg0R -recUpd0R  -recChg0W));
			rmiTrigger($s, $a, $p, undef, qw(-recInsID));
			do {	rfdCp	($s, $r->{-file}, $a, $p);
				rfdStamp($s, $a, $p, rfdTime($s, $a, $n)||'+');
				}
					if $r 
					&& $r->{-file}
					&& (!$u 
					   || $a->{-file}
					   || ($d->{$u->[0]}
						&& grep {$d->{$u->[0]} eq $_
							} @{$u}[1..$#$u]));
			do {	rfdRm  ($s, $a->{-table}, $n);
				rfdCp  ($s, $a->{-file},  $a->{-table}, $n);
				rfdCln ($s, $a->{-table}, $n)
				}
					if $a->{-file}
					&& (!$r->{-file} || $r->{-file} ne $a->{-file});
			rfdStamp  ($s, $a, $n, rfdTime($s, $a, $n)||'+');
			$p->{$t2} =$d->{$t1}
				if $t2 && $t1 
				&& (exists($r->{$t2}) 
					|| ($m->{-mdefld} && $m->{-mdefld}->{$t2})
					|| (($m->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbm'));
			rmiIndex  ($s, $a, $n, $r) if $i;
			rmiIndex  ($s, $a, $p)	   if $i;
			$p =$s->dbiIns({-table=>$a->{-table}, -save=>1}, $p);
		}
		else {					# update only
			$n ={%$r}; @{$n}{recFields($s, $d)} =recValues($s, $d);
			rmiTrigger($s, $a, $n, $r, qw(-recForm0R -recFlim0R -recEdt0R -recChg0R -recUpd0R -recChg0W));
			do {	rfdRm  ($s, $a->{-table}, $n);
				rfdCp  ($s, $a->{-file},  $a->{-table}, $n);
				}
				if $a->{-file}
				&& (!$r->{-file} || ($r->{-file} ne $a->{-file}));
			rfdStamp  ($s, $a, $n, $tu) 
				if $r && $r->{-file};
			rfdCln	  ($s, $a, $n)
				if $r && $r->{-file} 
				&& $u 
				&& $n->{$u->[0]} 
				&& !grep {$n->{$u->[0]} eq $_
						} @{$u}[1..$#$u];
			rmiIndex  ($s, $a, $n, $r)  if $i;
		}
		if (1 && $n) {
			$s->logRec('dbiUpd','SINGLE') if $j ==1;
			$e =$s->dbiUpd({ -table=>$a->{-table}
					,-key=>$s->recWKey($a->{-table}, $r)
						# recKey, recWKey
				}, $n, $r || {});
			$s->{-affected} =$j if $s->{-affected};
		}
	} 
	$r =$e || $s->dbiUpd($a, $d);
 }
 else {
	$r =$s->dbiUpd($a, $d);
 }
 return(&{$s->{-die}}($s->lng(0,'recUpd') .': ' .($s->{-affected}||0) .' ' .$s->lng(1,'-affected') .$s->{-ermd}) && undef)
	if $s->{-affect} && (($s->{-affected}||0) != $s->{-affect});
 if ($r && ($s->{-affected}||0) ==1) {
	rfdStamp($s, $a, $r) 
			if $b;
	$r->{-editable} =$w ? $s->ugmember(map {$r->{$_}} @$w) : 1
			if $s->{-rac};
	{	local $a->{-cmd}  ='recRead';
		local $a->{-edit} =undef;
		rmiTrigger($s, $a, $r, $r, qw(-recForm0R -recFlim0R -recRead0R -recRead1R))
	};
	rmiTrigger($s, $a, $r, undef, qw(-recUpd1C -recRead1C -recForm1C));
 }
 elsif ($r) {
	rmiTrigger($s, $a, $r, undef, qw(-recUpd1C))
 }
 $r
}



sub recUtr {    # Translate values in database
		# (table || {cmd} ||false, field, new, old)
		#	{-table, -version}
		# or recUpd() args
 my	$s =$_[0];
 my	$n =$_[1];
	$n =$s->{-pcmd}->{-table} ||$s->{-pcmd}->{-form}	if !$n;
	$n->{-table} = $s->{-pcmd}->{-table}	if ref($n) && !$n->{-table};
 my	$a;
	if ($n && ($n !~/^-/)) {
		$a ={-table=>ref($n) ? $n->{-table} : $n
			, -key=>{}, -data=>{}, -sel=>0};
		if (!$_[4] && ref($_[2]) && ref($_[3])) {	# {new}, {old}
			$a->{-data}=$_[2];
			$a->{-key} =$_[3];
		}
		elsif (!$_[2] && ref($_[3]) && ref($_[4])) {	# !, {new}, {old}
			$a->{-data}=$_[3];
			$a->{-key} =$_[4]
		}
		elsif (ref($_[2]) eq 'HASH') {			# {field/src}
			foreach my $k (keys %{$_[2]}) {
				if (ref($_[2]->{$k})) {	# {field=>[new, old]}
					$a->{-data}->{$k} =$_[2]->{$k}->[0];
					$a->{-key}->{$k}  =$_[2]->{$k}->[1]
				}
				else {			# {src fld=>tgt fld}, {new}, {old}
					$a->{-data}->{$_[2]->{$k}} =$_[3]->{$k};
					$a->{-key}->{$_[2]->{$k}}  =$_[4]->{$k};
				}
			}
		}
		elsif (ref($_[2])) {		# [fields], [new], [old]
			for (my $i=0; $i <=$#{$_[2]}; $i++) {
				$a->{-data}->{$_[2]->[$i]} =$_[3]->[$i];
				$a->{-key}->{$_[2]->[$i]}  =$_[4]->[$i]
			}
		}
		elsif ($_[2] && !ref($_[2])) {	# field, new, old
			$a->{-data}->{$_[2]}=$_[3];
			$a->{-key}->{$_[2]} =$_[4];
		}
		else {
			return(&{$s->{-die}}("'recUtr' parameters unknown" .$s->{-ermd}) && undef);
		}
		if ((grep {!defined($a->{-data}->{$_})} keys %{$a->{-data}})
			|| (grep {!defined($a->{-key}->{$_})}  keys %{$a->{-key}})){
			return(undef)
		}
	}
	else {
		$a = (@_< 3 && ref($n) ? {%{$n}} : {@_[1..$#_]});
	}
	$s->varLock if $s->{-serial} && $s->{-serial} ==2;
	$s->logRec('recUtr', @_[1..$#_]);
 my	$d =$a->{-data} ? {%{$a->{-data}}} : exists($a->{-data}) ? {} : $a;
	$a->{-cmd}  ='recUtr';
	$a->{-table}=recType ($s, $a, $d);
	$a->{-key}  =rmlKey  ($s, $a, $d);
 my	$m =mdeTable($s,$a->{-table});
 my	$x =$m->{-rvcDelState}	||$s->{-rvcDelState};
 my	$v =$m->{-rvcActPtr}	||$s->{-rvcActPtr};
 local	$a->{-version}= ref($n) 
			? $n->{-version} ||'-' : '-'; # !!! ignoring chk-out
	$a->{-version}= ref($a->{-version})
			? $a->{-version}
			: $v && (!$a->{-version} ||$a->{-version} eq '-')
			? [$v, @{$x||[]}]
			: ($a->{-version} ||'+');
	if (ref($n) && $n->{-excl} && $n->{-version} && $v && $a->{-version}
	&& (ref($_[4]) eq 'HASH')) {
		my $kv =$s->recKey($a->{-table}, $_[3]);
		$a->{-where} =
			join(' AND '
				, map { defined($kv->{$_})
					? ('(' .$_ .'!=' .$s->mdeQuote($a->{-table},$_,$kv->{$_}) .')'
					  ,"($v IS NULL OR " . $v .'!=' .$s->mdeQuote($a->{-table},$_,$kv->{$_}) .')')
					: ()
						} keys %$kv);
	}
 local	$s->{-rac} =undef;
 $s->dbiUpd($a, $d);
}




sub dbiUpd {    # Update record(s) in database
		# -table=>table, field=>value || -data=>{values}
		# -key=>{field=>value}, -where=>'condition'
		# -save=>boolean, -optrec=>boolean, -sel=>boolean
		# $d && $dp - single record full new && prev data
 my ($s, $a, $d, $dp) =@_;
 my  $f =$a->{-table};
 my  @c;
 my  $r =undef;
     $s->{-affected} =0;
 if (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi') {
	$d ={map {	(defined($dp->{$_}) && defined($d->{$_}) && ($dp->{$_} eq $d->{$_}))
			|| (!defined($dp->{$_}) && !defined($d->{$_}))
			? ()
			: ($_ => $d->{$_}) } keys %$d}
		if $dp;
	$d =$dp if $dp && !scalar(keys(%$d));
	my $db =$s->dbi();
	my @cn =!$a->{-key} ? () : $s->{-dbiph} ? sort keys %{$a->{-key}} : keys %{$a->{-key}};
	my(@a, @v); @a =recFields($s,$d) if $s->{-dbiph};
	@c=('UPDATE '
		.dbiTblExp1($s, $f)
		.' SET '
		.join(','
		, $s->{-dbiph}
		? (map {"$_=?"} @a)
		: (map {$_ .'=' .mdeQuote($s, $s->{-table}->{$f}, $_, $d->{$_})
			} recFields($s,$d)))
		." WHERE "
		.join(' AND '	
			, dbiKeyWhr($s, 1, $a, @cn)	# Key condition
			, $a->{-where} 
			? '(' .$a->{-where} .')' 	# Where condition 
			: ()
			, ref($a->{-version})		# Version control $f.
			? ("(( " .$a->{-version}->[0] .' IS NULL'
			." OR  " .$a->{-version}->[0] ."='')"
			.($a->{-version}->[1] 
				? ' AND ' .$a->{-version}->[1] ." <> '" .$a->{-version}->[2] ."')"
				: ')'))
			: ()
			, dbiACLike($s, 1, $f, undef	# Access control
				,mdeWriters($s, $f), $s->ugnames())
			)
		,$s->{-dbiph} ? ({}, (map {$d->{$_}} @a), (map {ref($a->{-key}->{$_}) ? @{$a->{-key}->{$_}} : $a->{-key}->{$_}} @cn)) : ()
	);
	$s->logRec('dbiUpd', @c);
	$db->do(@c) || return(&{$s->{-die}}($s->lng(0,'dbiUpd') .": do() -> " .($DBI::errstr||'Unknown') .$s->{-ermd}) && undef);
	$s->{-affected} =$DBI::rows;
	$s->{-affected} =-$s->{-affected} if $s->{-affected} <0;
	$s->logRec('dbiUpd','AFFECTED',$s->{-affected});
	return($s->dbiIns($a, $d)) 
		if !$s->{-affected} 
		&& ($a->{-save}
		||  $s->{-table}->{$f}->{-ixcnd});
	return($s->recIns($a, $d))
		if !$s->{-affected}
		&& ($a->{-optrec}
		||  $s->{-table}->{$f}->{-optrec});
	return($d) if ($s->{-affected} >1) ||$a->{-save};
	return($d) if defined($a->{-sel}) && !$a->{-sel};
	return($d) if !$s->{-affect} && $DBI::rows <=0;
	if ($s->{-dbiph}) {
		@cn =grep {defined($d->{$_}) 
			|| !exists($d->{$_}) && defined($a->{-key}->{$_})
				} @cn;
		@v  =map  {defined($d->{$_}) ? $d->{$_} : $a->{-key}->{$_}
				} @cn;
	}
	@c =('SELECT * FROM ' .dbiTblExp1($s, $f) .' WHERE '
		.join(' AND '	
			, $s->{-dbiph}
			? (map {  "$_=?" } @cn)
			: (map {  defined($d->{$_})
				? ($_ .'=' .mdeQuote($s, $s->{-table}->{$f}, $_, $d->{$_}))
				: exists($d->{$_})
				? ()
				: defined($a->{-key}->{$_})
				? ($_ .'=' .mdeQuote($s, $s->{-table}->{$f}, $_, $a->{-key}->{$_}))
				: ()
				} @cn)
			, $a->{-where} ? '(' .$a->{-where} .')' : ())
	);
	$s->logRec('dbiUpd', @c, @v ? {} : (), @v);
	$f =$db->prepare(@c);
	$r =$f && $f->execute(@v) && $f->fetchrow_hashref() || return(&{$s->{-die}}($s->lng(0,'dbiUpd') .": selectrow_hashref() -> " .($DBI::errstr||'Empty result set') .$s->{-ermd}) && undef);
 }
 elsif (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbm') {
	my ($j, $h, @f, @v);
	$j =0;
	$h =$s->dbmTable($f);
	if (!$dp) {
		@f =recFields($s,$d);
		@v =recValues($s,$d);
	}
	$s->{-affected} =
	!$dp
	? $s->dbmSeek($a, sub{
			$j++;
			return(&{$s->{-die}}($s->lng(0,'dbiUpd') .": $j ". $s->lng(1,'-affected') .$s->{-ermd}) && undef)
				if $s->{-affect} && $j >$s->{-affect};
			if (!$dp)	{ $r =$_[2]; @{$r}{@f} =@v }
			else		{ $r =$d }
			my $k =[map {$r->{$_}} @{$s->{-table}->{$f}->{-key}}];
			$s->logRec('dbiUpd','kePut', $f, $k, $_[1], $r);
			$h->kePut($k, $_[1], $r);
		})
	: do {		my $k =[map {$d->{$_}} @{$s->{-table}->{$f}->{-key}}];
			my $kp=[map {$dp->{$_}} @{$s->{-table}->{$f}->{-key}}];
			$s->logRec('dbiUpd','kePut', $f, $k, $kp, $d);
			$h->kePut($k, $kp, $d);
			$r =$d;
			1
		};
	if (!$s->{-affected}) {
		return($s->dbiIns($a, $d)) 
			if $a->{-save} || $s->{-table}->{$f}->{-ixcnd};
		return($s->recIns($a, $d))
			if $a->{-optrec} || $s->{-table}->{$f}->{-optrec};
		return(&{$s->{-die}}($s->lng(0,'dbiUpd') .": dbiSeek() -> " .($@ ||'not found') .$s->{-ermd}) && undef)
	}
	$r =$s->{-affected} >1 ? $d : $r;
 }
 $r
}


sub dbmSeek {	# Select records from dbm file using -key and -where
 my ($s, $a, $e) =@_;
 my $m =$s->{-table}->{$a->{-table}};			# metadata
 my $i =$m->{-key};					# index
 my $k =($a->{-key}					# key index part
	? [map {!exists($a->{-key}->{$_})
		? ()
		: ref($a->{-key}->{$_})
		? ()
		: ($a->{-key}->{$_})
		} @$i]
	: []);
 my $ko=$s->{-keyqn};					# key compare opt	
 my $wk={ $a->{-key}					# key where part
	? (map {($_=>$a->{-key}->{$_})
			} (grep {	my $v =$_; 
					ref($a->{-key}->{$v})
					|| !grep {$v eq $_
							} @$i
				} keys %{$a->{-key}}))
	: ()
	};
    $wk=undef if !%$wk;
 my $o =($a->{-keyord} ||$a->{-orderby} ||$a->{-order})	# order request
	|| (!$e && (!@$k) ? $KSORD : '-aeq');
    $o ='-' .$o if substr($o,0,1) ne '-';
 my $ox=@$k						# order execute
	? $o 
	: $e 
	? $o 
	: $o =~/^-[af]/ 
	? '-aall' 
	: '-dall';
 my $ws;						# 'where' key cond
 if ($wk) {			# !!! without [{}] syntax
	$ws =substr($o, 2);	# of cgiForm(recQBF)/cgiQkey
	$ws =0 ? undef
	: $ws eq 'eq' || $ws eq 'all'
		      ? sub{my($k,$v,$d); foreach $k (keys %$wk) {
				$v =$wk->{$k};	$d =$_[2]->{$k}; 
				return(undef) if
				$ko && (!defined($v) || ($v eq ''))
				?  defined($d) && $d ne ''
				: !defined($d)	? defined($v)
				: !defined($v)	? defined($d)
				: ref($v)
				? !grep {$d eq $_} @$v
				: $d =~/^[\d\.]+\$/ && $v =~/^[\d\.]+\$/
				? $d != $v	: $d ne $v;
			}; 1}
	: $ws eq 'ge' ? sub{my($k,$v,$d); foreach $k (keys %$wk) {
				$v =$wk->{$k};	$d =$_[2]->{$k}; 
				return(undef) if
				$ko && (!defined($v) || ($v eq ''))
				?  defined($d) && ($d lt '')
				: !defined($d)	? defined($v)
				: !defined($v)	? 0
				: ref($v)
				? !grep {$d ge $_} @$v
				: $d =~/^[\d\.]+\$/ && $v =~/^[\d\.]+\$/
				? $d < $v	: $d lt $v;
			}; 1}
	: $ws eq 'gt' ? sub{my($k,$v,$d); foreach $k (keys %$wk) {
				$v =$wk->{$k};	$d =$_[2]->{$k}; 
				return(undef) if
				$ko && (!defined($v) || ($v eq ''))
				? !defined($d) || ($d le '')
				: !defined($d)	? 1
				: !defined($v)	? !defined($d)
				: ref($v)
				? !grep {$d gt $_} @$v
				: $d =~/^[\d\.]+\$/ && $v =~/^[\d\.]+\$/
				? $d <= $v	: $d le $v;
			}; 1}
	: $ws eq 'le' ? sub{my($k,$v,$d); foreach $k (keys %$wk) {
				$v =$wk->{$k};	$d =$_[2]->{$k}; 
				return(undef) if
				$ko && (!defined($v) || ($v eq ''))
				?  defined($d) && ($d gt '')
				: !defined($d)	? 0
				: !defined($v)	? defined($d)
				: ref($v)
				? !grep {$d le $_} @$v
				: $d =~/^[\d\.]+\$/ && $v =~/^[\d\.]+\$/
				? $d > $v	: $d gt $v;
			}; 1}
	: $ws eq 'lt' ? sub{my($k,$v,$d); foreach $k (keys %$wk) {
				$v =$wk->{$k};	$d =$_[2]->{$k}; 
				return(undef) if
				$ko && (!defined($v) || ($v eq ''))
				? !defined($d) || ($d ge '')
				: !defined($d)	? !defined($v)
				: !defined($v)	? 0
				: ref($v)
				? !grep {$d lt $_} @$v
				: $d =~/^[\d\.]+\$/ && $v =~/^[\d\.]+\$/
				? $d >= $v	: $d ge $v;
			}; 1}
	: undef
 }

 my $wr=$a->{-urole} 					# 'where' role cond
	&& mdeRole($s, $m, $a->{-urole});
 if ($wr) {
	my $wl	=$wr;
	my $wn	=$a->{-uname} ? $s->ugnames($a->{-uname}) : $s->ugnames();
	my $wx	=$a->{-urole} =~/^(?:manager|principal|user)$/i
		? mdeRole($s, $m, 'actor') 
		: $a->{-urole} =~/^(?:managers|principals|users)$/i
		? mdeRole($s, $m, 'actors') 
		: [];
	$wr	=sub{	foreach my $n (@$wn) {
				foreach my $v (@$wx) {
					return(undef) if $_[2]->{$v} =~/(?:^|,|;)\s*\Q$n\E\s*(?:,|;|$)/i
				}
				foreach my $v (@$wl) {
					return($n) if $_[2]->{$v} =~/(?:^|,|;)\s*\Q$n\E\s*(?:,|;|$)/i
				}
			}
			undef
	}
 }
 my $wa=$a->{-urole} && !$a->{-uname} 			# 'where' access cond
	? undef 
	: mdeReaders($s, $m);

 my $wv=$a->{-version};					# 'where' version cond
    $wv=undef if !ref($wv) || !@$wv;
 my $ft=$a->{-ftext};					# full-text find
 my $wf=$a->{-filter};					# 'where' filter expr
 my $wc=$a->{-where};					# 'where' condition
 my $we=$wc;						# 'where' cond source
 if (defined($wc) && !ref($wc) && $wc) {		# ... from string
	# !!! SQL perl operations incompatible with perl
	my $wm =$we; $we =''; 
	my ($wa, $wt, $wq);
	while (length($wm)) {
		$wa =!$wa;
		if ($wm =~/(?<!\\)((?:\\\\)*["'])/) {	# ... unescaped quote
			$wt =$`; $wm =$'; $wq =$1;
		}
		else {
			$wt =$wm; $wm =''; $wq ='';
		}
		if ($wa) {				# ... translate expr
			$wt =~s/((?<![><=])=)/'=' .$1/ge;
			$wt =~s/({\w+\})/'$_->' .$1/ge;
			$wt =~s/\b((?<!\{)\w{1,}(?!\s*\())\b/my $v =$1; $v !~\/^(?:and|or|eq|ge|gt|le|lt)$\/i ? '$_->{' .$v .'}' : $v/ge;
		}					# !!! good expr syntax?
		$we .=$wt .$wq;
	}
	$wc =$s->ccbNew($we);
 }
 my $w =sub{local $_ =$_[2];				# 'where' construct
	   (!$wv || (!$_[2]->{$wv->[0]} && (!$wv->[1] ||!$_[2]->{$wv->[1]} ||($_[2]->{$wv->[1]} ne $wv->[2]))))
	&& (!$ws || &$ws(@_))
	&& (!$wc || &$wc(@_))
	&& (!$wa || ugmember($s, map {$_[2]->{$_}} @$wa))
	&& (!$wr || &$wr(@_))
	&& (!$ft || grep {defined($_[2]->{$_}) && $_[2]->{$_} =~/\Q$ft\E/i} keys %{$_[2]})
	&& (!$wf || &$wf(@_))
	};
 $s->logRec('dbiSeek'
	, $a->{-table}, $ox, $k
	, $wv	? (-version=> $wv)	: ()
	, $wk	? ('-' .substr($o, 2)=>$wk)	 : ()
	, $we	? (-where=>$we)		: ()
	, $wa	? (-rac	=>$wa)		: ()
	, $wr	? (-urole=>$a->{-urole}, -uname=>$a->{-uname}||'') : ()
	, $ft	? (-ftext=>$ft)		: ()
	, $wf	? (-filter=>$wf)	: ()
	, $e	? (-subw=>$e)		: ()
	);
 !$s->{-c}->{-dbmSeek} 
 ? $s->dbmTableFlush($a->{-table})	# !!! for proper seek by DB_File
 : $s->dbmTable($a->{-table})->sync();
 local $s->{-c}->{-dbmSeek} =1;
 $s->dbmTable($a->{-table})->keSeek($ox,$k,$w,$e);
}


sub dbiKeyWhr {	# SQL -key -order query condition
		# self, tbl alias off, {command}, key field names
 my ($s, $t, $a, @cn)=@_;
    @cn =!$a->{-key} ? () : $s->{-dbiph} ? sort keys %{$a->{-key}} : keys %{$a->{-key}}
	if !@cn;
   !@cn && return(@cn);
 my $kc =$a->{-keyord} ||$a->{-order};
    $kc =!$kc || ref($kc) || substr($kc,0,1) ne '-'
	? ''
	: {'eq'=>'=','ge'=>'>=','gt'=>'>','le'=>'<=','lt'=>'<'}->{substr($kc,2)}||'=';
    $kc	='' if $kc eq '=';
 my $db =$s->dbi();
 my $f  =ref($a->{-table}) ? $a->{-table}->[0] : $a->{-table};
    $f  =$1 if $f=~/^([^\s]+)/;
 my $m  =$s->{-table} && $s->{-table}->{$f};
 $t	=!$t && $m ? $f .'.' : ''; 
 $s->{-dbiph}
 ?(map {my $ce =$m && $m->{-mdefld} && $m->{-mdefld}->{$_}
		&& $m->{-mdefld}->{$_}->{-expr} || ($t .$_);
		# expression may not be in select list
	  ref($a->{-key}->{$_})
	? do{	my $n =$_;
		@{$a->{-key}->{$_}}
		? ('(' .join(' OR '
			, map {	  ref($_)
				? (do {	local $a->{-key} =$_;
					local $_ =$_;
					local $s->{-dbiph} =undef;
					my @v =dbiKeyWhr(@_[0..2]);
					@v ? '(' .join(' AND ', @v) .')' : ()
					})
				: $s->{-keyqn} && (!defined($_) || ($_ eq ''))
				? (!$kc ? '(' .$ce .' IS NULL OR ' .$ce ."='' OR " .$ce .'=?)' : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc ."'' OR " .$ce .$kc .'?)' : ('(' .$ce .$kc ."'' OR " .$ce .$kc .'?)'))
				: !defined($_)
				? (!$kc ? '(' .$ce .' IS ?)' : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc .'?)' : ('(' .$ce .$kc .'?)'))
				: ('(' .$ce .($kc  ||'=') .'?)')
				} @{$a->{-key}->{$_}}) .')')
		: ()
		}
	: $s->{-keyqn} && (!defined($a->{-key}->{$_}) || ($a->{-key}->{$_} eq ''))
	? (!$kc ? '(' .$ce .' IS NULL OR ' .$ce ."='' OR " .$ce .'=?)' : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc ."'' OR " .$ce .$kc .'?)' : ('(' .$ce .$kc ."'' OR " .$ce .$kc .'?)'))
	: !defined($a->{-key}->{$_})
	? (!$kc ? '(' .$ce .' IS ?)' : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc .'?)' : ('(' .$ce .$kc .'?)'))
	: ('(' .$ce .($kc  ||'=') .'?' .')')
	} @cn)
 :(map {my $ce =$m && $m->{-mdefld} && $m->{-mdefld}->{$_}
		&& $m->{-mdefld}->{$_}->{-expr} || ($t .$_);
		# expression may not be in select list
	  ref($a->{-key}->{$_})
	? do{	my $n =$_;
		@{$a->{-key}->{$_}}
		? ('(' .join(' OR '
			, map {	  ref($_)
				? (do {	local $a->{-key} =$_;
					local $_ =$_;
					my @v =dbiKeyWhr(@_[0..2]);
					@v ? '(' .join(' AND ', @v) .')' : ()
					})
				: $s->{-keyqn} && (!defined($_) || ($_ eq ''))
				? (!$kc ? '(' .$ce .' IS NULL OR ' .$ce ."='')" : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc ."'')" : ('(' .$ce .$kc ."'')"))
				: !defined($_)
				? (!$kc ? '(' .$ce .' IS NULL)' : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc .'NULL)' : ($t .$n .$kc .'NULL'))
				: ('(' .$ce .($kc  ||'=') .mdeQuote($s, $m, $n, $_) .')')
				} @{$a->{-key}->{$_}}) .')')
		: ()
		}
	: $s->{-keyqn} && (!defined($a->{-key}->{$_}) || ($a->{-key}->{$_} eq ''))
	? (!$kc ? '(' .$ce .' IS NULL OR ' .$ce ."='')" : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc ."'')" : ('(' .$ce .$kc ."'')"))
	: !defined($a->{-key}->{$_})
	? (!$kc ? '(' .$ce .' IS NULL)' : $kc =~/=/ ? '(' .$ce .' IS NULL OR ' .$ce .$kc .'NULL)' : ('(' .$ce .$kc .'NULL)'))
	: ('(' .$ce .($kc  ||'=') .mdeQuote($s, $s->{-table}->{$f}, $_, $a->{-key}->{$_}) .')')
	} @cn);
}


sub dbiACLike {	# SQL Access Control LIKE / RLIKE
		# self, tbl alias off, table, operation, [fields], [values], ?filter
 return(!$_[3] ? () : '') if !$_[4] ||!$_[5] || !@{$_[4]} ||!@{$_[5]};
				# RLIKE method detect / construct
 my $o	= ($_[0]->{-table}	&& $_[0]->{-table}->{$_[2]} 
				&& $_[0]->{-table}->{$_[2]}->{-dbiACLike})
	|| $_[0]->{-dbiACLike} ||''; 
	# rlike regexp ~* similar regexp_like like eq|=; lc|lower; filter|sub
  # $o	= 'eq lc';
 my $t  = !$_[1] && $_[0]->{-table} && $_[0]->{-table}->{$_[2]} && ($_[2] .'.')
		||'';
 my $e  = $_[0]->dbiEng();
    $e	= 0
	? ''
	: ($o =~/\b(?:rlike|regexp)\b/i)|| (!$o && ($e =~/\bDBI:(?:mysql)\b/i))
	? 'RLIKE'	# MySQL, case insensitive for not binary strings
	: ($o =~/~\*/i)		|| (!$o && ($e =~/\bDBI:(?:pg|postgresql)\b/i))
	? '~*'		# PostgreSQL, case insensitive
	: ($o =~/\b(?:similar)\b/i)
	? 'SIMILAR TO'	# SQL99, PostgreSQL: '%[[:<:]](|)[[:>:]]%'
	: ($o =~/\b(?:regexp_like)/i)
	? 'REGEXP_LIKE'	# Oracle 10: REGEXP_LIKE(zip, '[^[:digit:]]')
	: '';
 my $l	= !$e || ($o =~/\b(?:like|eq|=)\b/i)
	? $_[5]
	: ($e eq 'SIMILAR TO'
	  ? $_[0]->dbi->quote('%[[:<:]](' 
		.join('|', map {$_[0]->dbiLikesc($_)} @{$_[5]}) 
		.')[[:>:]]%')
	  : $e eq 'RLIKE'
	  ? $_[0]->dbi->quote( '(^|,|;)[:blank:]*(' 
		.join('|', map {$_[0]->dbiLikesc($_)} @{$_[5]}) 
		.')[:blank:]*(,|;|$)')
	  : $_[0]->dbi->quote( '[[:<:]](' 
		.join('|', map {$_[0]->dbiLikesc($_)} @{$_[5]}) 
		.')[[:>:]]')
	  );
    $l	= ref($l)
	? (!$o || ($o =~/\b(?:lc|lower)\b/i) ? [map {lc($_)} @$l] : $l)
	: $e =~/\b(?:regexp_like)/i
	? (',' .($o =~/\b(?:lc|lower)\b/i ? lc($l) : $l) .')')
	: (' ' .$e .' ' .($o =~/\b(?:lc|lower)\b/i ? lc($l) : $l));

 if (ref($l) &&(@_ >6)		# LIKE method '-filter' constructor
 && (!$o || ($o =~/\b(?:filter|sub)\b/i))) {
	my $w =$_[0];
	my $e =$_[6];
	my $f =$_[4];
	$_[6] =$_[3] && $_[3] =~/not/i
		? sub{	foreach my $v (@$f) {
				next	if !exists($_[3]->{$v});
				foreach my $n (@$l) {
					return(undef) 
						if defined($_[3]->{$v})
						&& $_[3]->{$v} =~/(?:^|,|;)\s*\Q$n\E\s*(?:,|;|$)/i
				}
			} !$e || &$e(@_) }
		: sub{	foreach my $v (@$f) {
				if (!exists($_[3]->{$v})) {
					if ($w) {
					#	&{$w->{-warn}}("dbiACLike ACL filter ignoring due to ACL field(s) missing from SELECT list\n");
						CORE::warn("dbiACLike ACL filter ignoring due to ACL field(s) missing from SELECT list\n");
						$w =undef;
					}
					return(!$e || &$e(@_))
				}
				foreach my $n (@$l) {
					return(!$e || &$e(@_))
						if defined($_[3]->{$v})
						&& $_[3]->{$v} =~/(?:^|,|;)\s*\Q$n\E\s*(?:,|;|$)/i
				}
			} undef }
 }
 ' ' .($_[3] ? $_[3] .' ' : '')	# RLIKE / LIKE assembly
	.(!defined($l)		# !!! ignored -expr of field
	? ''
	: !ref($l) && ($e =~/\b(?:regexp_like)\b/i)
	? '('	.( $o =~/\b(?:lc|lower)\b/i
		 ? join(' OR ', map {$e .'(LOWER(' .$t .$_ .')' .$l} @{$_[4]})
		 : join(' OR ', map {$e .'(' .$t .$_ .$l} @{$_[4]})
		) .')'
	: !ref($l)
	? '('	.( $o =~/\b(?:lc|lower)\b/i
		 ? join(' OR ', map {'LOWER(' .$t .$_ .')' .$l} @{$_[4]})
		 : join(' OR ', map {$t .$_ .$l} @{$_[4]})
		) .')'
	: $o =~/\b(?:eq|=)\b/i
	? '(' .join(' OR '
		, map {	my $f =($o =~/\b(?:lc|lower)\b/i ? 'LOWER(' .$t .$_ .')' : ($t .$_));
			map {$f .'=' .$_[0]->dbi->quote($_)
				} @$l
			} @{$_[4]}) .')'
	: '(' .join(' OR '	# !!! like precession, see -filter above
		, map {	my $f =(!$o || ($o =~/\b(?:lc|lower)\b/i) ? 'LOWER(' .$t .$_ .')' : ($t .$_));
			map {$f .' LIKE ' .$_[0]->dbi->quote('%' .$_ .'%')
				} @$l
			} @{$_[4]}) .')'
	);
}


sub recDel {    # Delete record(s) in database
		# -table=>table
		# -key=>{field=>value}, -where=>'condition', -version=>'+'|'-'
 my	$s =$_[0];
	$s->varLock if $s->{-serial} && $s->{-serial} ==2;
	$s->logRec('recDel', @_[1..$#_]);
 my	$a =(@_< 3 && ref($_[1]) ? {%{$_[1]}} : {@_[1..$#_]});
 my	$d =$a->{-data} ? {%{$a->{-data}}} : exists($a->{-data}) ? {} : $a;
	$a->{-cmd}  ='recDel';
	$a->{-table}=recType($s, $a, $d);
	$a->{-key}  =rmlKey($s, $a, $d);
 my	$m =mdeTable($s,$a->{-table});
 my	$r =undef;
 my	$w =mdeWriters($s, $m);
 my	$x =$m->{-rvcDelState}	||$s->{-rvcDelState};
 my	$i =$m->{-index}	||$s->{-index};
 my	$b =$m->{-rfa}		||$s->{-rfa};
 rmiTrigger($s, $a, $d, undef, qw(-recForm0C -recDel0C));
 if ((($w||$i) && !$x) ||grep {$s->{$_} || $m->{$_}} qw(-recDel0R -recDel1R)) {
	my $c =$s->recSel(rmlClause($s, $a), -data=>undef);
	my $j =0;
	while ($r =$c->fetchrow_hashref()) {
		$j++; return(&{$s->{-die}}($s->lng(0,'recDel') .": $j ". $s->lng(1,'-affected') .$s->{-ermd}) && undef)
			if $s->{-affect} && $j >$s->{-affect};
		# $r ={%$r};	# readonly hash, should be considered below
		return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recDel') .': ' .$s->lng(1,'recDelAclStp') .$s->{-ermd}) && undef)
			if $w && !$s->ugmember(map {$r->{$_}} @$w);
		return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recDel') .': ' .$s->lng(1,'recUpdVerStp') .$s->{-ermd}) && undef)
			if $x && defined($r->{$x->[0]}) 
			&& ($r->{$x->[0]} eq $x->[1]);
		rfdStamp  ($s, $a, $r)		if $b;
		rmiTrigger($s, $a, undef, $r, qw(-recForm0R -recFlim0R -recDel0R));
		rfdRm	  ($s, $r)		if !$x && $r->{-file};
		rmiIndex  ($s, $a, undef, $r)	if !$x && $i;
	}
	$r =($x ? $s->recUpd((map {$a->{$_} ? ($_=>$a->{$_}) : ()
				} qw(-table -key -where -version)), @$x)
		: $s->dbiDel($a, $d));
 }
 else {
	$r =($x	? $s->recUpd((map {$a->{$_} ? ($_=>$a->{$_}) : ()
				} qw(-table -key -where -version)), @$x)
		: $s->dbiDel($a, $d));
 }
 return(&{$s->{-die}}($s->lng(0,'recDel') .': ' .($s->{-affected}||0) .' ' .$s->lng(1,'-affected') .$s->{-ermd}) && undef)
	if $s->{-affect} && (($s->{-affected}||0) != $s->{-affect});
 rmiTrigger($s, $a, $d, undef, qw(-recDel1C)) if $r;
 $r
}


sub dbiDel {    # Delete record(s) in database
		# -table=>table
		# -key=>{field=>value}, -where=>'condition'
 my ($s, $a, $d) =@_;
 my $f =$a->{-table};
 my @c;
 my $r;
     $s->{-affected} =0;
 if (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi') {
	@c =('DELETE FROM ' 
		.dbiTblExp1($s, $f)
		.' WHERE '
		.join(' AND '
			, dbiKeyWhr($s, 1, $a)		# Key condition
			, $a->{-where} 
			? '(' .$a->{-where} .')' 	# Where condition
			: ()
			, dbiACLike($s, 1, $f, undef	# Access control
				, mdeWriters($s, $f), $s->ugnames())
			)
		, $s->{-dbiph} && $a->{-key} 
		? ({}, map {ref($a->{-key}->{$_}) ? @{$a->{-key}->{$_}} : $a->{-key}->{$_}} sort keys %{$a->{-key}}) 
		: ()
	);
	$s->logRec('dbiDel', @c);
	$s->dbi->do(@c) || return(&{$s->{-die}}($s->lng(0,'dbiDel') .": do() -> " .($DBI::errstr||'Unknown') .$s->{-ermd}) && undef);
	$s->{-affected} =$DBI::rows;
	$s->{-affected} =-$s->{-affected} if $s->{-affected} <0;
	$s->logRec('dbiDel','AFFECTED',$s->{-affected});
	return($s->{-affected} && $a);
 }
 elsif (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbm') {
	my $h =$s->dbmTable($f);
	my $j =0;
	$s->{-affected} =
	$s->dbmSeek($a, sub{
		$j++; return(&{$s->{-die}}($s->lng(0,'dbiDel') .": $j " .$s->lng(1,'-affected') .$s->{-ermd}) && undef)
			if $s->{-affect} && $j >$s->{-affect};
                $s->logRec('dbiDel', 'keDel', $f, $_[1]);
		$h->keDel($_[1]);
	});
	return(&{$s->{-die}}($s->lng(0,'dbiDel') .": dbiSeek() -> $@" .$s->{-ermd}) && undef) 
		if !defined($s->{-affected});
 }
 $s->{-affected} && $a
}


sub dbiTrunc {	# Clear all records in the datafile
		# self, datafile name
 my ($s, $f) =@_;
 my @c;
 if (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi') {
     @c =('TRUNCATE TABLE ' .dbiTblExp1($s, $f));
     $s->logRec('dbiTrunc', @c);
     $s->dbi->do(@c) || return(&{$s->{-die}}($s->lng(0,'dbiTrunc') .": do() -> " .($DBI::errstr||'Unknown') .$s->{-ermd}) && undef);
 }
 elsif (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbm') {
	my $n =$s->pthForm('dbm',($s->{-table}->{$f} && $s->{-table}->{$f}->{-expr} ||$f));
	if (-e $n) {
		$s->logRec('dbiTrunc','unlink', $n);
		unlink($n)
		|| return(&{$s->{-die}}($s->lng(0,'dbiTrunc') .": unlink('$n') -> $!" .$s->{-ermd}) && undef)
	}
 }
 $s
}


sub recSel {    # Select records from database
		# see 'dbiSel'
 my	$s =$_[0];
 my	$a =@_< 3 && ref($_[1]) ? dsdClone($s, $_[1]) : {map {ref($_) ? dsdClone($s, $_) : $_} @_[1..$#_]};
	$a->{-table}=recType($s, $a, $a);
 local	$s->{-affect}=undef;
 my	$m =mdeTable($s,$a->{-table});
	$a->{-cmd}    ='recSel';
	$a->{-version}= ref($a->{-version})
			? $a->{-version}
			: $m && (!$a->{-version} ||$a->{-version} eq '-')
			? [ ($m->{-rvcActPtr}   ||$s->{-rvcActPtr}   ||())
			  ,@{$m->{-rvcDelState} ||$s->{-rvcDelState} ||[]}]
			: ($a->{-version} ||'+');
 local	$a->{-urole}= !$a->{-urole} ||($a->{-urole} eq 'all') ? undef : $a->{-urole};
#$s->logRec('recSel', $a);
 $s->{-fetched} =0;
 rmiTrigger($s, $a, undef, undef, qw(-recSel0C));
 my $r =$s->dbiSel($a);
 $r->{-query} =$a;
 $r
}


sub recList {	# List records from database
 recSel(@_)	# - reserved to be redesigned
}


sub recRead {   # Read one record from database
		# -key=>{field=>value}, see 'dbiSel'
		# -wikn=>value, instead of -key
		# -optrec=>boolean, -test=>boolean
		# -version=>'+'
 my	$s =$_[0];
 my	$a =@_< 3 && ref($_[1]) ? dsdClone($s, $_[1]) : {map {ref($_) ? dsdClone($s, $_) : $_} @_[1..$#_]};
 my	$d ={};
 local	$s->{-affect}=1;
	$a->{-cmd}  ='recRead';
	$a->{-table}=recType($s, $a, $d);
	$a->{-key}  =rmlKey($s, $a, $d);
	$a->{-data} =ref($a->{-data}) ne 'ARRAY' ? undef : $a->{-data};
 my	$m =mdeTable($s,$a->{-table});
 my	$r =undef;
 $a->{-version}= [ ($m->{-rvcActPtr}   ||$s->{-rvcActPtr}   ||())
		 ,@{$m->{-rvcDelState} ||$s->{-rvcDelState} ||[]}]
		if defined($a->{-version}) && !ref($a->{-version})
		&& $m && (!$a->{-version} || ($a->{-version} eq '-'));
 rmiTrigger($s, $a, $d, undef, qw(-recForm0C -recRead0C));
 $r =$s->recRead_($m, $a);
 rmiTrigger($s, $a, $r, $r, qw(-recForm0R -recFlim0R -recRead0R -recRead1R -recRead1C -recForm1C))
	if $r;
 $r
}


sub recRead_ {	# recRead internal use, without triggers
 my ($s, $m, $a) =@_;
 my $r =$s->dbiSel($a)->fetchrow_hashref();
 if ($r) {
	$s->{-affected} =1;
	$s->{-fetched}  =1;
 }
 else {
	$s->{-affected} =0;
	$s->{-fetched}  =0;
	return(undef)
		if $a->{-test};
 	return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recRead') .': ' .($s->{-affected}||0) .' ' .$s->lng(1,'-affected') .$s->{-ermd}) && undef)
		if !$a->{-optrec}
		|| !$m->{-optrec};
	return($s->recNew(map {($_=>$a->{$_})} grep {$a->{$_}} qw(-table -form)));
 }
 if ($r && $s->{-rac}) {
	return(&{$s->{-die}}($s->{-ermu} .$s->lng(0,'recRead') .': '. $s->lng(1,'recReadAclStp') .$s->{-ermd}) && undef)
	if !$s->uadmrdr() 
	&&($m->{-racWriter} ||$s->{-racWriter} ||$m->{-racReader} ||$s->{-racReader})
	&& !$s->ugmember(map {$r->{$_}}	 @{$m->{-racWriter} ||$s->{-racWriter}||[]}
					,@{$m->{-racReader} ||$s->{-racReader}||[]});
	$r->{-editable} =1
		if $s->uadmwtr()
		|| $s->ugmember(map {$r->{$_}} @{$m->{-racWriter} || $s->{-racWriter}||[]})
 }
 rfdStamp($s, $a, $r) if $m->{-rfa} ||$s->{-rfa};
 $r
}


sub recWikn {	# Find record by name
		# (wikiname)
 my	($s, $val, $qry) =@_;
 my	$rk;
 my	$rl=0;
 my	$ru='';
 $qry ='' if $qry && ($qry eq 'default');

 $s->logRec('recWikn',$val, $qry);
 if ($qry && $s->{-wikq} && !$s->{-table}->{$qry}) {
	$rk =&{$s->{-wikq}}($s, $val, $qry);
	return($rk) if $rk;
 }
 foreach my $tn (keys %{$s->{-table}}) {
	next if $qry && ($tn ne $qry);
	my $tm =$s->mdeTable($tn);
	next if defined($tm->{-wikn}) && !$tm->{-wikn};
	next if !$tm->{-wikn} && !$s->{-wikn};
	my $fn;
	foreach my $f ($tm->{-wikn} 
			? (ref($tm->{-wikn}) ? @{$tm->{-wikn}} : $tm->{-wikn})
			: (ref($s->{-wikn})  ? @{$s->{-wikn}}  : $s->{-wikn})) {
		next if !$tm->{-mdefld}->{$f};
		$fn =$f;
		last
	}
	next if !$fn;
	my $fv =$tm->{-rvcActPtr}	||$s->{-rvcActPtr};
	my $fu =$tm->{-rvcUpdWhen}	||$s->{-rvcUpdWhen};
	my $ti =$s->recSel(-table=>$tn
			, -version=>'+'
			, -key=>{$fn=>$val}
			, -keyord=>'dall');
	my $rr;
	while ($rr=$ti->fetchrow_hashref()) {
		if ($rr->{$fv}) {
			next if $fu
				? $ru gt ($rr->{$fu}||'')
				: $rl;
			$rk ={-table=>$tn, -key=>$s->recKey($tn,$rr)};
			$ru =$rr->{$fu}||'';
			$rl =1;
		}
		else {
			next if $fu
				? $ru gt ($rr->{$fu}||'')
				: $rl >1;
			$rk ={-table=>$tn, -key=>$s->recKey($tn,$rr)};
			$ru =$rr->{$fu}||'';
			$rl =2; # last
		}
	}
	last if $rl==2;
 }
 $rk->{-cmd} ='recRead' if ref($rk) && !$rk->{-cmd};
 $rk
}


sub recHist {	# History of changes of record
		# -table=>name, -key=>{}
 my	$s =$_[0];
 my	$a =@_< 3 && ref($_[1]) ? dsdClone($s, $_[1]) : {map {ref($_) ? dsdClone($s, $_) : $_} @_[1..$#_]};
 my	$d ={};
 local	$s->{-affect}=undef;
	$a->{-cmd}  ='recRead';
	$a->{-table}=recType($s, $a, $d);
	$a->{-key}  =rmlKey($s, $a, $d);
 my	$m =mdeTable($s,$a->{-table});
 $s->logRec('recHist',%$a);
 my %rvc =map {($_ => $m->{$_} ||$s->{$_})
		} qw(-rvcInsBy -rvcInsWhen -rvcUpdBy -rvcUpdWhen -rvcActPtr);
 return(undef)
	if !$rvc{-rvcActPtr} || !$rvc{-rvcUpdWhen};
 $rvc{-key} =$m->{-key} ||$s->{-key} ||$s->{-tn}->{-key};
 $rvc{-key} =$rvc{-key}->[0] if ref($rvc{-key});
 my $rva =$m->{-rvcActPtr} ||$s->{-rvcActPtr};
 my %rvx =map {($m->{$_} ||$s->{$_} => 1) # may be included: -key, -rvcActPtr
		} qw(-rvcUpdBy -rvcUpdWhen -rvcActPtr);
 $rvx{$rvc{-key}} =1;
 $rvx{-fupd} =1;
 $rvx{-editable} =1;
 $a->{-key}	={$rvc{-key} => [$a->{-key}->{$rvc{-key}}
			, {$rvc{-rvcActPtr} => $a->{-key}->{$rvc{-key}}}
			]};
 $a->{-version}	='+';
 $a->{-order}	=$rvc{-rvcUpdWhen};
 $a->{-keyord}	='-aeq';
 # $s->logRec('recHist', %$a, {%rvc});
 $s->{-affected}=0;
 $s->{-fetched} =0;
 my $l =0;	# length
 my $r =[];	# return list
 my $pv={};	# previous values: field => value
 my $c =$s->recSel(%$a);
 my($r0, $r1) =($pv);
 while (my $rr =$c->fetchrow_hashref()) {	# collect versions
	$r1 =$rr;
	if ($l >1024*1024*10) {
		push @$r, [$a->{-key}->{$rvc{-key}}
			, '...'
			, '...'
			, {}];
		while (my $v =$c->fetchrow_hashref()) {$r1 =$v};
	}
	$s->{-fetched}++; $s->{-affected}++;
	$s->rfdStamp($a->{-table}, $r1) if $m->{-rfa} ||$s->{-rfa};
	rmiTrigger($s, $a, $r1, $r1, qw(-recForm0R -recRead0R -recRead1R -recRead1C -recForm1C));
	push @$r, [	 $r1->{$rvc{-key}}
			,$r1->{$rvc{-rvcUpdWhen}}
			,$r1->{$rvc{-rvcUpdBy}}
			,{}];
	foreach my $v (@{$r->[$#$r]}) {
		$l +=length($v) if !ref($v) && defined($v)
	}
	my $cf =$r->[$#$r]->[3];
	foreach my $f (keys %$r1) {
		next	if $rvx{$f}
			|| (!defined($pv->{$f}) && !defined($r1->{$f}));
		next	unless	($f ne $rva) 
			?	(!defined($pv->{$f}) &&  defined($r1->{$f}))
			||	( defined($pv->{$f}) && !defined($r1->{$f}))
			||	($pv->{$f} ne $r1->{$f}) 
			: 1;
		
		my $cv =$r1->{$f};	# change value
		if (!$cv) {}
		elsif (	(length($cv) >255)
		||	($cv =~/[\n\r]/)
		||	($m->{-mdefld}
				&& $m->{-mdefld}->{$f}
				&& $m->{-mdefld}->{$f}->{-inp}
				&& (grep {$m->{-mdefld}->{$f}->{-inp}->{$_}
						} qw(-rows -arows -htmlopt)))
			) {
			if ($m->{-mdefld} && $m->{-mdefld}->{$f}
				&& $m->{-mdefld}->{$f}->{-inp}
				&& $m->{-mdefld}->{$f}->{-inp}->{-htmlopt}) {
				$cv =$s->strDiff('-hbr', $pv->{$f}, $cv);
			}
			else {
				$cv =$s->strDiff('-br', $r0->{$f}, $cv);
			}
		}
		$cf->{$f} =$cv;
		$l +=length($cv) if defined($cv);
		# $s->logRec('recHist', $r1->{$rvc{-rvcUpdBy}}, $r1->{$rvc{-rvcUpdWhen}}, $f, $cv);
		$pv->{$f} =$r1->{$f};
	}
 }
 # return($r);
 if (1) {		# arrange attachments if possible
	my($fn, $ft);	# folder name, folder time
	for (my $i=$#$r; $i >=0; $i--) {
		if ($fn && (	    $r->[$i]->[3]->{-file}
				|| ($r->[$i]->[1] lt $ft)) ){
			$r->[$i+1]->[3]->{-file} =$fn;
			$fn =$ft =undef;
		}
		if ($r->[$i]->[3]->{-file}) {
			$fn =$r->[$i]->[3]->{-file};
			$ft =$s->strtime($s->rfdTime($fn)||0);
			delete($r->[$i]->[3]->{-file});
		}
	}
	$r->[0]->[3]->{-file} =$fn if $fn;
 }
 # $s->logRec('recHist', @$r);
 $r
}


sub recLast {   # Last record lookup for values
		# self, table/command ||false, record data, key fields,... target
		#	{-table, -version, -excl}
 my	$s =$_[0];
 my	$n =$_[1]; 
	$n =$s->{-pcmd}->{-table} ||$s->{-pcmd}->{-form}	if !$n;
	$n->{-table} = $s->{-pcmd}->{-table}	if ref($n) && !$n->{-table};
 my	$d =$_[2];
 my	$a ={-cmd=>'recLast'
		, -table=>ref($n) ? $s->recType($n, $d) : $n};
 my	$m =mdeTable($s,$a->{-table});
 my	$r =undef;
 return($r)
	unless ($m->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi';
 local	$s->{-affect}=1;
 $a->{-version}	= ref($n->{-version})
		? $n->{-version}
		: $m && (!$n->{-version} ||$n->{-version} eq '-')
		? [ ($m->{-rvcActPtr}   ||$s->{-rvcActPtr}   ||())
		  ,@{$m->{-rvcDelState} ||$s->{-rvcDelState} ||[]}]
		: ($n->{-version} ||'+');
 if ($n->{-excl}) {
	my $kv =$s->recKey($a->{-table}, $_[2]);
	$a->{-where} =
		join(' AND '
			, map { defined($kv->{$_})
				? $_ .'!=' .$s->mdeQuote($a->{-table},$_,$kv->{$_})
				: ()
				} keys %$kv);
 }
 foreach my $c ($m, $s) {
	next if !$c->{-rvcUpdWhen}; 
	$a->{-order} =[[$c->{-rvcUpdWhen},'desc']];
	last
 }
 for (my $i =$#_; $i >2; $i--) {
	next if ref($_[$i]) ne 'ARRAY';
	$a->{-key} ={};
	for (my $j =3; $j <=$i; $j++) {
		foreach my $f (@{$_[$j]}) {
			next if !defined($d->{$f}) || ($d->{$f} eq '');
			$a->{-key}->{$f} =$d->{$f};
		}
	}
	next if !%{$a->{-key}};
	$s->logRec('recLast',$i
			, (map {($_=>$s->strdata($a->{$_}))} sort keys %$a)
			, @_[3..$#_]);
	rmiTrigger($s, $a, $d, $r, qw(-recForm0C -recRead0C));
	$r =$s->dbiSel($a)->fetchrow_hashref();
	next if !$r;
	# $s->{-affected} =$s->{-fetched} =1;
	rmiTrigger($s, $a, $r, $r, qw(-recForm0R -recRead0R -recRead1R -recRead1C -recForm1C));
	if	(ref($_[$#_]) eq 'CODE') {
		$r =$r && &{$_[$#_]}($s,$r);
	}
	elsif	(ref($_[$#_]) eq 'ARRAY') {
		foreach my $f (@{$_[$#_]}) {
			$d->{$f} =$r->{$f} if defined($r->{$f});
		}
		# $s->logRec('recLast', $i, map {($_=>$d->{$_})} @{$_[$#_]});
	}
	last;
 }
 $r
}


sub recUnion {	# UNION cursor / container operation
		# (self, option=>value,... {hash}||[array]||cursor,...)
	DBIx::Web::dbcUnion->new(@_[1..$#_])
}


sub dbiWsubst {	# WHERE substitution for '#funct'
		# (''|char, expr string, dbiSel vars) -> translated
 my ($s, $c, $q, $f, $a, $cf) =@_;
 my $r ='';
 if (!$c) {
	return($q) if $q !~/#[\w]+[\w\d]+\(/;
	while ($q =~/^(.*?)(['"]|#[\w]+[\w\d]+\()(.*)/) {
		$r .=$1;
		$q  =$3;
		if (substr($2,0,1) eq '#') {
			my $c1 =substr($2,1,-1);
			my $q1 =dbiWsubst($s, '(', $q);
			   $q1 =$1 if $q1 =~/^\(\s*(.*?)\)\s*$/;
			my @q1 =dbiWsubst($s, ',', $q1);
			if ($c1 =~/^(?:ftext|fulltext|qftext)$/i) {
				my $qs =!defined($q1[0])
					? '%'
					: $q1[0] =~/^['"](.*?)['"]$/ 
					? dbiQuote($s, '%' .$1 .'%') 
					: $q1[0];
				$r .=dbiWSft($s, $f, $qs);
			}
			elsif ($c1 =~/^(?:urole)$/i) {
				my ($v, $u) =(dbiUnquote($s,$q1[0]), dbiUnquote($s,$q1[1]));
				$v ='authors' if !$v;
				$r .=join(' AND ', dbiWSur($s, $f, $v, $u, $_[5]));
			}
			else {
				$r .=$c1 .'(' .(!defined($q1[0]) ? '' : $q1[0]) .')'
			}
		}
		else {
			$r .=dbiWsubst($s, $2, $q)
		}
	}
	$r .=$q
 }
 elsif ($c eq '(') {
	$r =$c;
	while ($q =~/^(.*?)([()'"])(.*)/) {
		$q  =$3;
		$r .=$1;
		if ($2 eq ')')	{$r .=$2; last}
		else		{$r .=dbiWsubst($s, $2, $q)}
	}
	$_[2] =$q;
 }
 elsif ($c =~/['"]/) {
	my $cq =$s->dbiQuote($c);
	$cq =substr($cq,1,-1);
	$r =$c;
	while ($q =~/^(.*?)(\Q$c\E|\Q$cq\E)(.*)/) {
		$q =$3;
		$r .=$1 .$2;
		last if $2 eq $c;
	}
	$_[2] =$q;
 }
 elsif ($c eq ',') {
	my @r;
	while ($q =~/^(.*?)(['"(]|\Q$c\E)(.*)/i) {
		$q =$3;
		$r .=$1;
		if ($2 eq $c) {
			push @r, ($r =~/^\s*(.*?)\s*$/ ? $1 : $r);
			$r ='';
		}
		else {
			$r .=dbiWsubst($s, $2, $q);
		}
	}
	$r .=$q;
	push @r, ($r =~/^\s*(.*?)\s*$/ ? $1 : $r) if $r ne '';
	return(@r)
 }
 else {
	$r =$c .$q
 }
 $r
}


sub dbiWSft {	# Full text search condition substitution
 my($s, $f, $v) =@_;
return(
 $s->{-table}->{$f}->{-ftext}
 ? '(' .join(' OR '
	, map {	($_ =~/\./ ? $_ : "$f.$_")
		.' LIKE '
		. $v
		} @{$s->{-table}->{$f}->{-ftext}}
   ) .')'
 : $s->{-table}->{$f}->{-field}
 ? '(' .join(' OR '
	, map {	( $_->{-expr}
		? $_->{-expr}
		: $_->{-fld} =~/\./
		? $_->{-fld}
		: ($f .'.' .$_->{-fld})	)
		.' LIKE '
		.$v
		} grep {ref($_) eq 'HASH' 
			&& $_->{-fld} 
			&& ($_->{-flg}||'') =~/[akwuql]/
			&& (!$_->{-expr} ||($_->{-expr} !~/[-+*\/!|&%\s()]/))
			} @{$s->{-table}->{$f}->{-field}}
   ) .')'
 : ref($a->{-data}) eq 'ARRAY'
 ? '(' .join(' OR '
	, map {	(!ref($_)
		?($_ =~/\./ ? $_ : "$f.$_")
		: ref($_) ne 'HASH'
		? $_->[1]
		: (defined($_->{-expr})
			? $_->{-expr}
			: $_->{-fld} =~/\./
			? $_->{-fld}
			: ($f .'.' .$_->{-fld})
			))
		. ' LIKE ' 
		.$v
		} grep {$_ 
			&& ((ref($_) ne 'HASH') 
			   || ($_->{-fld} 
				&& (!$_->{-expr} 
				   ||($_->{-expr} !~/[-+*\/!|&%\s()]/))))
			} @{$a->{-data}}
	, $s->{-table}->{$f}->{-ftext}
	? map {	($_ =~/\./ ? $_ : "$f.$_")
		.' LIKE '
		.$v
		} @{$s->{-table}->{$f}->{-ftext}}
	: ()
   ) .')'
 : '')
}


sub dbiWSur {	# User role condition substitution
 my($s, $f, $r, $u) =@_;
 return(dbiACLike($s, 0, $f, undef
			, mdeRole($s, $f, $r)
			,($u
			? $s->ugnames($u)
			: $s->ugnames())
			, $_[4])
	, $r =~/^(?:manager|principal|user)$/i
	? dbiACLike($s, 0, $f, 'NOT'
			, mdeRole($s, $f, 'actor')
			,($u
			? $s->ugnames($u)
			: $s->ugnames())
			, $_[4])
	: $r =~/^(?:managers|principals|users)$/i
	? dbiACLike($s, 0, $f, 'NOT'
			, mdeRole($s, $f, 'actors')
			,($u
			? $s->ugnames($u)
			: $s->ugnames())
			, $_[4])
	: ())
}


sub dbiSel {    # Select records from database
		# -select	=>ALL, DISTINCT, DISTINCTROW, STRAIGHT_JOIN, HIGH_PRIORITY, SQL_SMALL_RESULT
		# -data		=>[fields] | [field, [field=>alias], {-fld=>alias, -expr=>formula,..}]
		# -table	=>[tables] | [[table=>alias], [table=>alias,join]]
		# -join[01]	=>string
		# -join		=>string
		# -join2	=>string
		# -key		=>{field=>value}
		# -where	=>string   | [strings]
		# -ftext	=>string
		# -version	=>0|1
		# -order	=>string   | [field, [field=>order]]
		# -keyord	=>-(a|f|d|b)(all|eq|ge|gt|le|lt)
		# -group	=>string   | [field, [field=>order]]
		# -filter	=>sub{}(cursor, undef, {field=>value,...})
 my ($s, $a) =@_;
 my  $t =$a->{-table};
 my  $f =ref($t) ? $t->[0] : $t; $f =$1 if $f=~/^([^\s]+)/;
 my  @c;
 my  $r;
 if (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi') {
	# local $s->{-dbiph} =1 if !exists($s->{-dbiph});
	my @cn =!$a->{-key} ? () 
		: $s->{-dbiph} ? sort keys %{$a->{-key}} 
		: keys %{$a->{-key}};
	my @cv =!$a->{-key} ? () 
		: $s->{-dbiph} ? map {ref($a->{-key}->{$_}) 
					? grep {!ref($_)} @{$a->{-key}->{$_}}
					: $a->{-key}->{$_}} @cn
		: ();
	my $kn =$s->{-table}->{$f} && $s->{-table}->{$f}->{-key} ||[];
	my $tf =$s->{-table}->{$f} && $s->{-table}->{$f}->{-mdefld};
	my $cf =$a->{-filter};
	@c =('SELECT '
		. ($a->{-select} ? $a->{-select} .' ' : '')
		. (!$a->{-data}		? ' * '			# Data
		: !ref($a->{-data})	? ' ' .$a->{-data} .' '
		: ref($a->{-data}) ne 'ARRAY' ? ' * '
		: join(', '
			, map { my $v =ref($_) && $_ || $tf && $tf->{$_} || $_;
				!ref($v) 
				? ($v =~/\./
					? $v
					: "$f.$v AS $v")
				: ref($v) ne 'HASH'
				? join(' AS ', @$v[0..1])
				: (defined($v->{-expr}) 
					? $v->{-expr} .' AS ' .$v->{-fld} 
					: $v->{-fld} =~/\./
					? $v->{-fld}
					: ($f .'.' .$v->{-fld} .' AS ' .$v->{-fld})
					)
				} @{$a->{-data}}))
		. ' FROM '					# From
		. ( $a->{-join0} ? $a->{-join0} .' ' : '')
		. (ref($t) 
			? join(' '
				, (map {!ref($_) 
					? ($_,',') 
					: (@$_, $_->[$#_] =~/(JOIN|,)$/i 
						? () 
						: ',')} @$t)[0..-1])
			: dbiTblExpr($s, $t)
			)
		. ( $a->{-join1} ? $a->{-join1} : '')
		. join(''
			, map {	my $v =ref($a->{$_}) ? &{$a->{$_}}($s,$a) : $a->{$_};
				!$v
				? ()
				: $v =~/^\s*(?:,|CROSS|JOIN|INNER|STRAIGHT_JOIN|LEFT|NATURAL|RIGHT|OUTER)\b/i
				? (' ' .$v .' ')
				: (', ' .$v .' ')
				} qw(-join -join2)
			)
		. ' WHERE '					# Where
		. join(' AND '
			, dbiKeyWhr($s, 0, $a, @cn)		# Key condition
			,($a->{-where}				# Where condition
			? '(' .$s->dbiWsubst(''
				,(!ref($a->{-where}) 
				? $a->{-where} 
				: join(' AND ', map {$_
					} @{$a->{-where}})), $f, $a, $cf)
			  .')'
			: ())
			,(ref($a->{-version})			# Version switch
			? ('((' .$f .'.' .$a->{-version}->[0]
				.' IS NULL OR ' .$f .'.' .$a->{-version}->[0] 
				."='')"
				.($a->{-version}->[1]
					? " AND $f."
						.$a->{-version}->[1] ." <> '"
						.$a->{-version}->[2] ."')"
					: ')'))
			: ())
			,(($a->{-urole} && !$a->{-uname})	# Access control
			|| $s->uadmrdr()
			? ()
			: dbiACLike($s, 0, $f, undef
				, mdeReaders($s, $f), $s->ugnames(), $cf)
				)
			,(!$a->{-urole}				# Role filter
			 ? ()
			 : dbiWSur($s,$f,$a->{-urole},$a->{-uname},$cf)
				)
			,(!$a->{-ftext}				# Full-text
				? ()
				: $s->dbiWSft($f,$s->dbi->quote('%' .$a->{-ftext} .'%'))
				)
			,(scalar(@cn) ||$a->{-where} ||ref($a->{-version})
				||$a->{-urole} ||$a->{-ftext} 
			? ()
			: ('1=1')) # !!! TRUE may be? But database dependent!
			)
		. ($a->{-group}					# Group by
		  ? ' GROUP BY '
			.(ref($a->{-group})
			? join(', ', map {!ref($_) ? $_ : join(' ',@$_)} @{$a->{-group}})
			: $a->{-group})
		  : '')
		. ($a->{-order}					# Order by
		  ? ' ORDER BY '
			.(ref($a->{-order})
			? join(', '
				,map {	  ref($_) 
					? join(' ',@$_) 
					: $_ !~/[\s,]/
					? $_ .($a->{-keyord} && ($a->{-keyord} =~/^-[db]/) ? ' desc' : '')
					: $_
					} @{$a->{-order}})
			: $a->{-order} =~/^-[db]/
			? join(',', map {"$_ desc"} @$kn)
			: substr($a->{-order},0,1) eq '-' # $a->{-order}=~/^-[af]/
			? join(',', @$kn)
			: $a->{-order} !~/[\s,]/
			? $a->{-order} .($a->{-keyord} && ($a->{-keyord} =~/^-[db]/) ? ' desc' : '')
			: $a->{-order})
		  : $a->{-keyord}				# -keyord
		  ? ' ORDER BY '
			.($a->{-keyord} =~/-[db]/
			? join(',', map {"$_ desc"} @$kn)
			: join(',', @$kn))
		  : '')
		. ($a->{-having}				# Having
		  ? ' HAVING ' .$a->{-having}
		  : ''
		. ($a->{-limit}					# Limit
		  && $s->dbiEng('mysql')
		  ? ' LIMIT ' .$a->{-limit}
		  : '')
		)
	);
	$s->logRec('dbiSel', @c, @cv ? {} : (), @cv);
	$r =$s->dbi->prepare(@c) || return(&{$s->{-die}}($s->lng(0,'dbiSel') .": prepare() -> " .($DBI::errstr||'Unknown') .$s->{-ermd}) && undef);
	$r->execute(@cv) || return(&{$s->{-die}}($s->lng(0,'dbiSel') .": execute() -> " .($DBI::errstr||'Unknown') .$s->{-ermd}) && undef);
	$r =DBIx::Web::dbiCursor->new($r, -flt=>$cf) 
		if $cf || 1;	# !!! DBI::st hides keys!
	$r->{-rec} ={map {($_ => undef)} @{$r->{NAME}}};
	$r->{-rfr} =[map {\($r->{-rec}->{$_})} @{$r->{NAME}}];
	$r->{-flt} =$cf;
	$r->bind_columns(undef, @{$r->{-rfr}});
	$s->logRec('dbiSel', 'FETCH')	if !$s->{-affect} || ($s->{-affect} >1);
	$s->dbiExplain(@c) if $s->{-debug} && $s->dbiEng('mysql');
 }
 elsif (($s->{-table}->{$f}->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbm') {
	$r =$s->dbmSeek($a);
	return(&{$s->{-die}}($s->lng(0,'dbiSel') .": dbiSeek() -> $@" .$s->{-ermd}) && undef) if !defined($r);
	if	($a->{-data} && (ref($a->{-data}) eq 'ARRAY')) {
		$r->setcols($a->{-data})
	}
	elsif	(my $m =$s->{-table}->{$f}->{-field}) {
		$r->setcols(ref($m) eq 'HASH' 
			? keys %$m
			: map {$_->{-fld}} grep {(ref($_) eq 'HASH') && $_->{-fld}} @$m)
	}
 }
 $r
}


sub recCommit {	# commit changes in the database
 $_[0]->logRec('recCommit');
 if ($_[0]->{-dbi}) {
	$_[0]->{-dbi}->commit 
	|| ($DBI::errstr && return(&{$_[0]->{-die}}($_[0]->lng(0,'recCommit') .": commit() -> " .($DBI::errstr||'Unknown') .$_[0]->{-ermd}) && undef))
 }
 $_[0]
}


sub recRollback {# rollback changes in the database
 $_[0]->logRec('recRollback');
 if ($_[0]->{-dbi}) {
	$_[0]->{-dbi}->rollback
	|| ($DBI::errstr && return(&{$_[0]->{-die}}($_[0]->lng(0,'recRollback') .": rollback() -> " .($DBI::errstr||'Unknown') .$_[0]->{-ermd}) && undef))
 }
 $_[0]
}


#########################################################
# CGI User Interface
#########################################################


sub cgiRun {	# Execute CGI query
 my $s =$_[0];
 my $r;
 local($s->{-pcmd}, $s->{-pdta}, $s->{-pout});
		# Automatic upgrade
 if ($s->{-setup} && !$ARGV[0]
 && (!$s->{-diero} ||($s->{-diero} ne 'e'))) {
 	my $ds =(stat(main::DATA))[9] ||0;
	my $dv =($ds && (stat($s->varFile()))[9])||0;
	$ARGV[0] ='-setup' if $ds >$dv;
 }
		# Command line service options
 if ($ARGV[0] && ($ARGV[0] =~/^-/)) {
	$s->start();
	print "Content-type: text/plain\n\n";
	print "'$0' service operation: '" .$ARGV[0] ."'...\n";
	if ($ARGV[0] eq '-reindex') {
		$r =$s->recReindex(1);
	}
	elsif ($ARGV[0] eq '-setup') {
		$r =$s->setup();
		$s->varStore();
	}
	elsif ($ARGV[0] eq '-call') {
		$r =$ARGV[1];
		$r =$s->$r(@ARGV[2..$#ARGV]);
	}
	# print "'$0' service operation: '" .$ARGV[0] ."'->$r\n";
	$s->end();
	return($s)
 }
		# Error display handler
 $s->{-ermu} ='/*User*/ ';
 $s->{-ermd} =' /*Trace*/ ';
 local $SELF =$s;
 my $he =sub{
	my $s =$SELF;
	if (!$s 
	||$s->ineval()) {
		if ($s && $s->{-diero} && ($s->{-diero} eq 'o')) {
			CORE::die(@_)
		}
		return
	}
	delete $s->{-pcmd}->{-xml} if $s->{-pcmd};
	my $e =join('',@_); chomp($e);
	my $ermu =$s->{-ermu};
	if ($ermu && ($e =~/^\Q$ermu\E(.*)/))	{$e =$1}
	else					{$ermu =undef}
	eval{$s->logRec('Die', $e)} if !$ermu;
	eval{$s->recRollback()};
	$s->{-c}->{-httpheader} =$s->{-c}->{-httpheader} ||"Content-type: text/html\n\n"
		if *fatalsToBrowser{CODE};
	eval{	$s->output($s->htmlStart());
		local $s->{-pcmd}->{-cmd}	='frmErr';
		local $s->{-pcmd}->{-cmg}	='frmHelp';
		local $s->{-pcmd}->{-backc}	=0;
		$s->output($s->htmlHidden(),$s->htmlMenu());
		}
		if !$s->{-c}->{-htmlstart};
	eval{	my $h2;
		my $ermd =$s->{-ermd};
		if ($e =~/\Q$ermd\E/) {
			$h2 =$`;
			$e  =$';
		}
		elsif ($e =~/[\n\r]/) {
			$h2 =$`;
			$e  =$';
			if ($h2 =~/\s+(?:at\s+)*line\s+\d+\s+at\s+[^\s]+?\s+line\s+\d+\s*$/) {
				$h2 =$`;
				$e  =$& ."\n\r" .$e
			}
			elsif ($h2 =~/\s+at\s+[^\s]+?\s+line\s+\d+$/) {
				$h2 =$`;
				$e  =$& ."\n\r" .$e
			}
		}
		else {
			$h2 =$e;
			$e  ='';
		}
		$e =~s/[\n\r]/<br \/>\n/g;
		$s->output('<span class="ErrorMessage"><hr class="ErrorMessage" />'
		,'<h1 class="ErrorMessage">'
		, htmlEscape($s, lng($s, 0,'Error')), ' '
		, htmlEscape($s, lng($s, 0, ($s->{-pcmd} && $s->{-pcmd}->{-cmd})||'Open'))
		, '@'
		, htmlEscape($s, lng($s, 0, ($s->{-pcmd} && $s->{-pcmd}->{-cmg})||'Start'))
		, "</h1>\n"
		, $h2
		? '<h2 class="ErrorMessage">'
			.$h2
			."</h2>\n"
		: ()
		, $e, "</span>\n");
	     $s->cgiFooter();
	     $s->output("<hr />\n",$s->htmlEnd())};
	eval{$s->end()};
	if ($s->{-diero} && ($s->{-diero} eq 'o')) {
		if ($ermu)	{goto cgiRunEND}
		else		{CORE::die(@_)}
	}};
 if ($s->{-diero}) {
 }
 elsif (1 && ($ENV{MOD_PERL} || (($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/))) {
	local $s->{-diero} ='e';
	$SIG{__DIE__}='DEFAULT';
	# $s->{-serial}	=0 if $s->{-serial};
	my $r =eval{$s->cgiRun(); 1};
	local $CACHE->{-destroy} =0;
	if (!$r) {
		&$he($@);
		$s->DESTROY();
		return(undef);
	}
	else {
		$s->DESTROY();
		return($s);
	}
 }
 elsif (0 && ($ENV{GATEWAY_INTERFACE} && ($ENV{GATEWAY_INTERFACE} =~/PerlEx/))) {
	# !!! Remove this obsolette fix code and clean above
	$s->{-diero}	='o';
	$s->{-die}	=$he;
	$SIG{__DIE__}	='DEFAULT';
	if (*fatalsToBrowser{CODE})	{
		!*CGI::Carp::set_message{CODE} && eval('use CGI::Carp');
		CGI::Carp::set_message($he);
	}
	if ($s->{-serial}) {	# prevent locking buzz
		$s->logRec('cgiRun', 'PerlEx', -serial =>0);
		$s->{-serial}	=0;
	}
 }
 elsif (*fatalsToBrowser{CODE})	{
	!*CGI::Carp::set_message{CODE} && eval('use CGI::Carp');
	$SIG{__DIE__}	=\&CGI::Carp::die;
	CGI::Carp::set_message($he);
 }
 else {
	$SIG{__DIE__} =$he;
 }

		# Start operation
 $s->start();
 $s->set(-autocommit=>0);
 local $s->{-affect} =1;

 # cmg transitions:
 # global       commands
 # -------      --------
 # recList:	recList,	  recForm, recQBF->
 # recQBF:	recQBF,  	  recForm, recList->
 # recNew:	recNew,  	  recForm, recIns->
 # recRead:	recRead, recEdit, recForm, recIns, recUpd, recDel->, recNew->
 # recDel:			  recForm
 # recForm?			  recForm

		# Accept & parse CGI params, find form, command, global command, key...
 $s->cgiParse();
 local $s->{-pcmd}->{-ui} =1;
 my $oa =$s->{-pcmd}->{-cmd};
 my $og =$s->{-pcmd}->{-cmg}  ||$oa;
 my $on =$s->{-pcmd}->{-form} ||'default';
 my ($om, $oc);

		# Login redirection, if needed
 if ($s->{-pcmd}->{-login} && $s->uguest()) {
	print $s->cgi->redirect(-uri=>$s->urlAuth(), -nph=>(($ENV{SERVER_SOFTWARE}||'') =~/IIS/) ||($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER}));
	$s->end();
	return($s);
 }

			# Navigation Search Pane or LEFT / RIGHT Frameset
 if ($s->{-pcmd}->{-search} && (length($s->{-pcmd}->{-search}) >1)) {
	$s->{-c}->{-search} =$s->{-pcmd}->{-search}
 }
 elsif ($s->{-search}) {
	$s->{-c}->{-search} =ref($s->{-search}) ? &{$s->{-search}}($s,$s->{-pcmd}) : $s->{-search};
	delete $s->{-c}->{-search}
		if !defined($s->{-c}->{-search})
		|| (($s->{-c}->{-search} =~/\b_frame=RIGHT\b/)
			&& !$s->{-pcmd}->{-search}
			&& ($on !~/^(?:default|start|index)$/));
 }
 if ($s->{-pcmd}->{-search} && ($s->{-c}->{-search} =~/\b_frame=RIGHT\b/)) {
	my $sch =$s->{-c}->{-search};
	$sch =~s/\b_search=1\b/_search=0/;
	$sch =$s->url .$sch	if $sch =~/^?/;
	$s->output(''
		, $s->cgi->header(-charset => $s->charset()
		,-type => 'text/html')
		,'<html xmlns="http://www.w3.org/1999/xhtml"' 
			.($s->{-lang} ? ' lang="' .$s->lang(0,'-lang') .'"' : '')
			.">\n<head>\n"
		,'<title>'
		,$s->{-title} ||$s->cgi->server_name()
		,"</title>\n"
		,'<meta http-equiv="Content-Type" content="text/html; charset=' .$s->charset() .'">' ."\n"
		,'</head>',"\n"
		,'<frameset cols="15%,*">'
		,'<frame name="LEFT" src="'
		,$s->htmlEscape($sch)
		,'">'
		,'<frame name="RIGHT" src="' 
		,$s->urlOpt(-search=>0)
		,'">'
		,'</frameset>'
		,'</html>',"\n");
	$s->end();
	return($s)
 }

		# TOP / BOTTOM Frameset
 if ($s->{-pcmd}->{-frame} && ($s->{-pcmd}->{-frame} eq 'set')) {
	delete $s->{-pcmd}->{-frame};
	$s->output(''
		, $s->cgi->header(-charset => $s->charset()
				,-type => 'text/html')
		,'<html xmlns="http://www.w3.org/1999/xhtml"' 
			.($s->{-lang} ? ' lang="' .$s->lang(0,'-lang') .'"' : '')
			.">\n<head>\n"
		,'<title>'
		,$s->{-title} ||$s->cgi->server_name()
		,"</title>\n"
		,'<meta http-equiv="Content-Type" content="text/html; charset=' .$s->charset() .'">' ."\n"
		,'</head>',"\n"
		,'<frameset rows="50%,*">',"\n"
		,'<frame name="TOP" src="' 
			.($s->{-pcmd}->{-form} eq 'default'
			? $s->htmlEscape($s->urlCmd('',-frame=>'BOTTOM'))
			: $s->htmlEscape($s->urlOpt(-frame=>'BOTTOM',
				uc($ENV{REQUEST_METHOD}||'') ne 'GET'
				? ()
				: ('_all'=>1)))
			)			# !!! Mozilla no OnLoad target
			.'">',"\n"
		,'<frame name="BOTTOM" src="' 
			.$s->urlCat($s->url)
			.'">',"\n"
		,'</frameset>',"\n"
		,'</html>',"\n");
	return($s);
 }

 if (($on =~/\.psp$/i)	# Perlscript file immediate
 &&  ($oa =~/^(?:frmCall|recForm|recList)$/)) {
 	return(&{$s->{-die}}($s->lng(0,'cgiRun') .": Operation object '$on' illegal" .$s->{-ermd}) && undef) 
		if $on =~/[\\\/]\.+[\\\/]/;
 	my $f =$0 =~/^(.+[\\\/])[^\\\/]+$/ ? $1 .$on : $on;
	$s->psEval('-', $f, undef, $on, $om, $s->{-pcmd}, $s->{-pdta});
	$s->end();
	return($s);
 }

		# Wikiname
 if ($s->{-pcmd}->{-wikn}) {
	my $v =$s->recWikn($s->{-pcmd}->{-wikn},$s->{-pcmd}->{-wikq} ||$s->{-pcmd}->{-form} ||$s->{-pcmd}->{-table});
	if ($v) {
		foreach my $k (keys %$v) {
			$s->{-pcmd}->{$k} =$v->{$k}
		}
		$on =$s->{-pcmd}->{-form} =$v->{-table};
		$oa =$og =$s->{-pcmd}->{-cmd} =$s->{-pcmd}->{-cmg}
			=$s->{-pcmd}->{-cmh} =$v->{-cmd}
			if $v->{-cmd};
	}
 }
		# Encoded form / table
 if ((!$s->{-pcmd}->{-form} || ($s->{-pcmd}->{-form} eq 'default')) 
 &&  ($s->{-pcmd}->{-key} || $s->{-pdta})) {
	$s->rmlKey($s->{-pcmd}, $s->{-pdta});
	$on =$s->{-pcmd}->{-form} if $s->{-pcmd}->{-form};
 }

		# Determine / Delegate operation object requested / Execute
 while (1) {
	if	($s->{-form}  && $s->{-form}->{$on})	{$oc ='f'; $om =$s->{-form}->{$on}}
	elsif	($s->{-table} && $s->mdeTable($on))	{$oc ='t'; $om =$s->mdeTable($on)}
	else						{$oc ='' ; $om =undef}
	return(&{$s->{-die}}($s->lng(0,'cgiRun') .": Operation object '$on' not found" .$s->{-ermd}) && undef) 
			if !$om;
	$s->{-pcmd}->{-table} =($oc eq 't' ? $on : $om->{-table});

					# translation trigger
	&{$s->{-cgiRun0A}}($s,$s->{-pcmd})
		if $s->{-cgiRun0A};
	&{$s->{-table}->{$s->{-pcmd}->{-table}}->{-cgiRun0A}}($s,$s->{-pcmd})
		if $s->{-table} 
		&& $s->{-pcmd}->{-table} 
		&& $s->mdeTable($s->{-pcmd}->{-table})
		&& $s->{-table}->{$s->{-pcmd}->{-table}}->{-cgiRun0A};
	&{$om->{-cgiRun0A}}($s,$s->{-pcmd})
		if $om && $om->{-cgiRun0A};

					# redirectional implemtation: '-cgcURL'
	foreach my $e (map {$om->{$_}} ('-cgcURL', '-redirect')) {
		next if !defined($e);
		last if !$e;
		last if $oa eq 'frmHelp';
		print $s->cgi->redirect(-uri=>$e, -nph=>(($ENV{SERVER_SOFTWARE}||'') =~/IIS/) ||($ENV{MOD_PERL} && !$ENV{PERL_SEND_HEADER}));
		$s->end();
		return($r);
	}
					# external implemtation: '-cgcXXX'
	foreach my $e (map {$om->{"-cgc$_"}}
			 $oa =~/^rec(.+)/ ? $1 : $oa
			,$og =~/^rec(.+)/ ? $1 : $og, 'Call') {
		next if !defined($e);
		last if !$e;
		last if $oa eq 'frmHelp';
		$s->cgibus(1);
		$s->{-pcmd}->{-form} =$on	if !ref($e);
		$e =$` .$e	if !ref($e) && !-f $e && ($0=~/[^\\\/]+$/);
		$_ =$s;
		$r =	ref($e) 
			? &$e($s, $on, $om, $s->{-pcmd}, $s->{-pdta})
			: $e =~/\.psp$/i
			? $s->psEval('-', $e, undef, $on, $om, $s->{-pcmd}, $s->{-pdta})
			: do($e);
		$s->end();
		return($r)
	}

	my $nxt;			# delegation - substitute object
	foreach my $v (map {$om->{"-$_"}} 
			 'subst', $oa
			, $og =~/rec(New|Read|Del|QBF)/ 
			? ($og, 'recForm') 
			: $og) {
		next if !defined($v) || ref($v);
		last if !$v;
		$on = $nxt =$v;
		last
	}
	$on =$nxt =$s->{-pcmd}->{-form} =$om->{-table}
		if !$nxt
		&& ($og eq 'recNew') && ($oc eq 'f')
		&& !exists($om->{-recNew}) && !exists($om->{-recForm})
		&& !$om->{-field}
		&& $om->{-table} && $s->mdeTable($om->{-table})
		&& !$s->{-table}->{$om->{-table}}->{-ixcnd};
	next if $nxt;
	last;
 }

		# Execute action
 $s->cgibus(1);
 if	(ref(my $e =$om->{"-$oa"}) eq 'CODE') {
	$s->{-pout} =&$e($s, $on, $om, $s->{-pcmd}, $s->{-pdta});
 }
 else	{
	$s->{-pout} =$s->cgiAction($on, $om, $s->{-pcmd}, $s->{-pdta});
 }

		# Reassign form if changed
 $s->{-pcmd}->{-form} =(isa($s->{-pout}, 'HASH') && $s->{-pout}->{-form})
			|| $s->{-pcmd}->{-form} ||$on;

		# Execute external presentation '-cgvXXX'
 foreach my $e (map {$om->{"-cgv$_"}}
		 $oa =~/^rec(.+)/ ? $1 : $oa
		,$og =~/^rec(.+)/ ? $1 : $og, 'Call') {
	next if !defined($e);
	last if !$e;
	last if $oa eq 'frmHelp';
	$_ =$s;
	$r =	  ref($e)
		? &$e($s, $on, $om, $s->{-pcmd}, $s->{-pout})
		: $e =~/\.psp$/i 
		? $s->psEval('-', $e, undef, $on, $om, $s->{-pcmd}, $s->{-pout})
		: do($e);
	$s->end();
	return($r);
 }

		# Execute predefined presentation implementation
 $s->output(
	 $s->htmlStart($s->{-pcmd}->{-form}, $om)	# HTTP/HTML/Form headers
	,$s->htmlHidden($s->{-pcmd}->{-form}, $om)	# common hidden fields
	,$s->htmlMenu($on, $om)				# Menu bar
	);
 $s->cgiForm($on, $om, $s->{-pcmd}, $s->{-pout}) if $s->cgiHook('recFormRWQ');
 $s->cgiList($on, $om, $s->{-pcmd}, $s->{-pout}) if $s->cgiHook('recList');
 $s->cgiHelp($on, $om, $s->{-pcmd}, $s->{-pout}) if $s->cgiHook('frmHelp');
 $s->recCommit();
 $s->cgiFooter();
 $s->output($s->htmlEnd());
 $s->end();
 cgiRunEND:
 $s
}


sub cgiParse {	# Parse CGI call parameters
 my ($s) =@_;
 my $g =$s->cgi;
 my $d =$g->Vars;
 $s->{-pcmd} ={};
 $s->{-pdta} ={};
 $s->{-lng} =$g->http('Accept_language')||'';
 $s->set(-lng =>lc($s->{-lng} =~/^([^ ;,]+)/ ? $1 : $s->{-lng}));
 foreach my $k (keys %$d) {
	next if !defined($d->{$k} || $d->{$k} eq '');
	if($k =~/^_(quname)__S$/) {		# cgiDDLB choise
		$s->{-pcmd}->{"-$1"} =$d->{'_' .$1 .'__L'};
		$s->{-pdta}->{$k} =$d->{$k};
		$d->{_cmd} =$s->{-pcmd}->{-cmd} ='recForm';
	}
	elsif($k =~/^(.+)__S$/) {		# cgiDDLB choise
		$s->{-pdta}->{$1} =$d->{$1 .'__L'};
		$s->{-pdta}->{$k} =$d->{$k};
		$d->{_cmd} =$s->{-pcmd}->{-cmd} ='recForm';
	}
	elsif($k =~/^(.+)__R$/) {		# cgiDDLB reset
		$s->{-pdta}->{$1} =undef;
		$s->{-pdta}->{$1 .'__S'} =$d->{$k};
		$d->{_cmd} =$s->{-pcmd}->{-cmd} ='recForm';
	}
	elsif($k =~/^(.+)__O$/) {		# cgiDDLB open
		$s->{-pdta}->{$k} =$d->{$k};
		$d->{_cmd} =$s->{-pcmd}->{-cmd} ='recForm';
	}
	elsif($k =~/^_(new|file)$/) {		# record attribute
		$s->{-pdta}->{"-$k"} =$d->{$k}
	}
	elsif ($k =~/^_(cmd|cmg|frmCall|frmName\d*|frmLso|frmLsc|frmHelp|recNew|recRead|recPrint|recXML|recHist|recEdit|recIns|recUpd|recDel|recForm|recList|recQBF|submit.*|app.*|form|key|wikn|wikq|proto|urm|qjoin|qkey|qwhere|qurole|quname|qftext|qversion|version|qorder|qkeyord|qlist|qlimit|qdisplay|qftwhere|qftord|qftlimit|edit|backc|login|print|xml|hist|refresh|style|frame|search)(?:\.[xXyY]){0,1}$/i) {
		my ($c, $v) =($1, $d->{$k});	# command
		$v =$1	if ($k !~/^_(key|proto|qkey|qftext)/i)
			&& ($v =~/^\s*(.+?)\s*$/);
		if ($k =~/^(.+)\.[xXyY]$/) {
			$g->param($1, 1);
			$g->delete($k);
			$v=1;
		}
		if ($c =~/^(?:rec|frmCall|frmHelp|submit)/i) {
			$s->{-pcmd}->{-cmd} =$c
		}
		elsif (($c eq 'frmLso') && ($v =~/,/)) {
			$s->{-pcmd}->{"-$c"}=[split /\s*,\s*/, $v];
		}
		else {
			$s->{-pcmd}->{"-$c"}=$v
		}
	}
	else {					# data
		$s->{-pdta}->{$k} =$d->{$k}
	}
 }
 my $c =$s->{-pcmd};

 $c->{-cmg} ='recList' 
		if !$c->{-cmg} && !$c->{-cmd};
 $c->{-cmd} =!$c->{-cmg}? 'frmCall' 
			: $c->{-cmg} eq 'recList' ? 'recList' : 'recForm'
		if !$c->{-cmd};
 $c->{-cmg} =$c->{-cmd} eq 'recForm' ? 'recList' : $c->{-cmd}
		if !$c->{-cmg};

 map {$c->{$_} =datastr($s, $c->{$_})
	} grep {$c->{$_}} qw(-key -qkey -proto);
 $c->{-key} =$s->rmlKey($c, $s->{-pdta})
		if $c->{-key} && !ref($c->{-key}) && $s->{-idsplit};
 $c->{-form}=$c->{-table}
		if !$c->{-form} && $c->{-table};

 if ($c->{-frmLso} && $c->{-frmLso} eq 'recQBF') {
	$c->{-cmd} =$c->{-frmLso};
	delete $c->{-frmLso};
	$g->delete('_frmLso');
 }
 if	($c->{-cmd} eq 'frmCall') {
	my $frm =($c->{-frmName1} ||$c->{-frmName} ||$c->{-form} ||'default');
	if ($frm eq '-frame=set') {
		$c->{-frame} ='set';
		$c->{-form}  =$c->{-form} ||'default';
	}
	else {
		$c->{-cmd}  =$c->{-cmg} =($frm =~/[+]+\s*$/
					? 'recNew'
					: $frm =~/[&.^]+\s*$/
					? 'recForm'
					: 'recList');
		$frm =($frm=~/^(.+)(?:\s*[+&.^]+\s*)$/ ? $1 : $frm);
		if ($frm ne ($c->{-form}||'')) {
			# !!! query parameters for current view only, not table
			map {delete $c->{$_}
				} qw (-frmLso -frmLsc -qjoin -qkey -qwhere -qurole -quname -qversion -qorder -qkeyord);
			$g->delete('_frmLso');
			delete $c->{-key}
				if ($c->{-cmd} eq 'recList')
				|| ($c->{-cmg} eq 'recList');
			$c->{-backc} =0;
		}
		$c->{-form}  =$frm;
	}
 }

 if	($c->{-cmd} eq 'recNew') {
	$c->{-edit} =1;
	$c->{-backc}=0;
 }
 elsif	($c->{-cmd} eq 'recEdit') {
	$c->{-edit} =1;
	$c->{-cmd}  ='recRead'
 }
 elsif	($c->{-cmd} eq 'recQBFReset') {
	foreach my $k (qw(-qjoin -qkey -qwhere -qurole -quname -frmLso -frmLsc)) {
		delete $c->{$k};
	}
	$c->{-cmd}  ='recList';
	$c->{-cmg}  ='recList';
	$c->{-form} =$c->{-qlist} || $c->{-form};
	$c->{-backc}=0;
 }
 elsif	($c->{-cmd} eq 'recPrint') {
	$c->{-print} =1;
	$c->{-cmd}  ='recRead'
 }
 elsif	($c->{-cmd} eq 'recXML') {
	$c->{-xml} =1;
	$c->{-cmd} =$c->{-cmg} ||'recRead';
	$c->{-cmd} ='recList' if $c->{-cmd} =~/^(?:recXML|recQBF)$/;
 }
 elsif	($c->{-cmd} eq 'recHist') {
	$c->{-hist} =1;
	$c->{-cmd} ='recRead';
	# $c->{-backc}=0;
 }
 elsif	($c->{-cmd} eq 'frmHelp') {
	$c->{-edit} =undef;
	$c->{-backc}=0 if ($c->{-cmg} ne $c->{-cmd});
 }
 elsif	($c->{-cmd} !~/^(recIns|recUpd|recForm)/) {
	$c->{-edit} =undef
 }

 if	($c->{-cmd} =~/recList/ and $c->{-key}) {
	$c->{-qkey} =$c->{-key};
	delete $c->{-key};
 }

 if	($c->{-cmd} =~/recList/ and $c->{-cmg} =~/recQBF/) {
	$c->{-qkey} =$s->cgiQKey($c->{-form}, undef, $s->{-pdta});
	$c->{-qkey} ='' if !%{$c->{-qkey}};
	foreach my $k (qw(-frmLso -frmLsc)) {delete $c->{$k} if !$c->{$k}};
	$c->{-form} =$c->{-qlist} || $c->{-form};
	$c->{-backc}=0;
 }
 elsif	($c->{-cmd} =~/recQBF/ && $c->{-cmg} =~/recList/) {
	$c->{-edit} =1;
        $s->{-pdta} ={};
	map {	$s->{-pdta}->{$_} =$c->{-qkey}->{$_}
			if defined($c->{-qkey}->{$_})
			&& $c->{-qkey}->{$_} ne ''
		} keys %{$c->{-qkey}} 
			if ref($c->{-qkey});
	$c->{-qlist}=$c->{-form};
	$c->{-backc}=0;
 }

 if ($c->{-cmd} !~/recList/) {
	delete $c->{-refresh};
 }
 $c->{-backc} =(    ($c->{-cmd} eq 'recForm')
		||  ($c->{-cmd} eq 'recIns')
		||  ($c->{-cmd} eq 'frmHelp')
		|| (($c->{-cmd} eq 'recRead') || ($c->{-cmg} eq 'recRead'))
		|| (($c->{-cmd} eq 'recList') || ($c->{-cmg} eq 'recList'))
		? ($c->{-backc}||0) +1
		: 1);
 $c->{-cmh} =$c->{-cmg};		# history general command
 $c->{-cmg} =$s->cgiHook('cmgNext');	# actual  general command
 $s
}


sub cgiHook {	# HTML generation hook condition
 $_[0]->cgiParse() if !$_[0]->{-pcmd}->{-cmd};
 my $c =$_[0]->{-pcmd};
 return($c->{-cmd}) if !$_[1];
   ($_[1] eq $c->{-cmd})		# current operation
 ? $c->{-cmd}
 : ($_[1] eq 'recOp')			# record operation (exept 'recList')
	&& ($c->{-cmd} =~/^rec(New|Form|Read|Edit|Ins|Upd|Del)/)
 ? $c->{-cmd}
 : ($_[1] eq 'cmgNext')			# next global command to output as hidden
 ? (      $c->{-cmd} eq 'recForm' 
	? $c->{-cmg}
	: (grep {$c->{-cmd} eq $_} qw(recIns recUpd))
	? 'recRead'
	: $c->{-cmd} eq 'recDel'
	? $c->{-cmd}
	: $c->{-cmd})
 : ($_[1] =~/^recForm/)			# generate HTML form of record
	&&($c->{-cmd} !~/app|Help/)
	&&( $_[1] !~/^recForm([RWDQL]+)/
	 ||($_[1] =~/[WR]/ && $c->{-cmg} =~/^rec(Form|Read)/)
	 ||($_[1] =~/[W]/  && $c->{-cmg} =~/^rec(New|Form|Read|Ins|Upd)/)
	 ||($_[1] =~/[D]/  && $c->{-cmg} =~/^rec(Del)/)
	 ||($_[1] =~/[Q]/  && $c->{-cmg} eq 'recQBF')
	 ||($_[1] =~/[L]/  && $c->{-cmg} eq 'recList')
	  )
 ? $c->{-cmd}
 : ($_[1] eq 'recList')			# generate HTML list of records
	&& ($c->{-cmd} eq 'recList')
 ? $c->{-cmd}
 : ($_[1] eq 'recCommit')		# commit database operation
	&& ($c->{-cmd} =~/^rec(New|Form|Read|Ins|Upd|Del|List)/)
 ? $c->{-cmd}
 : ''
}


sub urlAuth {	# Login URL
 my $s =$_[0];
 my $u =$s->{-login};
 if ($u =~/\/$/) {
	my $u0=$u;
	my $u1=$s->cgi->self_url;	#url(-absolute=>1);
	   $u1=($u1=~/^\w+:\/\/[^\/]+(.+)/ ? $1 : $u1);
	my $i;
	while (($i =index($u0, '/')) >=0 and substr($u0,0,$i) eq substr($u1,0,$i)) {
		$u0 =substr($u0, $i+1); $u1 =substr($u1, $i+1);
	}
	$u .=$u1
 }
 $u
}



sub urlOptl {	# Option URL arg list
 my $s =$_[0];
 my %v =();
 my $l =0;
 my $m =800;	# query length limit, was 100
		# MSDN: METHOD Attribute | method Property:
		# the URL cannot be longer than 2048 bytes
 for (my $i =1; $i <$#_; $i+=2) {
	next if !defined($_[$i+1]) ||($_[$i+1] eq '');
	$v{$_[$i] =~/^-/ ? '_' .substr($_[$i],1) : $_[$i]}
		=ref($_[$i+1]) ? $s->strdata($_[$i+1]) : $_[$i+1];
 };
 if ($v{'_all'}) {$m =0; delete $v{'_all'}};
 foreach my $k (keys %v) {$l +=length($k) +length($v{$k}||0)};
 ((map {	my $n =$_;
		my $v;
		if (	defined($s->{-pcmd}->{$_})
			&& ($s->{-pcmd}->{$_} ne '')
			&& ($n =$_ =~/^-/ ? '_' .substr($_,1) : $_)
			&& ($n !~/_(?:frmName|cmg|cmh|cmdf|cmdt|backc|ui)/i)
			&& !exists($v{$n})	) {
			$v =ref($s->{-pcmd}->{$_}) 
				? $s->strdata($s->{-pcmd}->{$_}) 
				: $s->{-pcmd}->{$_};
			$l +=length($n) +length($v);
			$v =undef if $m && ($l >$m);
		}
		defined($v) ? ($n => $v) : ()
	} sort keys %{$s->{-pcmd}}), %v)
}


sub urlOpt {	# Option URL
 $_[0]->urlCat($_[0]->url, $_[0]->urlOptl(@_[1..$#_]))
}


sub psParse {	# PerlScript Parse Source
 my $s  =shift;	# (?options, perl script source, base URL)
 my $opt=substr($_[0],0,1) eq '-' ? shift : '-';
 my $i  =$_[0];	# input source
 my $b  =$_[1];	# base URL
 my $o  ='';	# output source
 my ($ol,$or) =('','');
 my ($ts,$tl,$ta,$tc) =('','','','');
 if ($i =~/<(!DOCTYPE|html|head)/i && $`) {
     $i ='<' .$1 .$'
 }
 if ($b && $i =~m{(<body[^>]*>)}i) {
	my ($i0,$i1) =($` .$1 ,$');
	$i =$i0 .('<base href="'. $s->htmlEscape($b) .'/" />') .$i1
 }
 if ($opt =~/e/i && $i =~m{<body[^>]*>}i) {	# '-e'mbeddable html
	$i =$';
	$i =$` if $i =~m{</body>}i
 }
 while ($i) {
	if (not $i =~/<(\%@|\%|script)\s*(language\s*=\s*|)*\s*(PerlScript|Perl|)*\s*(runat\s*=\s*Server|)*[\s>]*/i) {
		$ol =$i; $i ='';
		$ts ='';
	}
	elsif (($2 && !$3) || (!$3 && $tl eq '1')) {
		$ol =$` .$&;
		$i  =$';
		$tl =1;
		$tc =$ts ='';
	}
	elsif ($1) {
		$ol =$`; $i =$';
		$ts =uc($1||''); $tl =($2 && $3)||''; $ta=$4||'';
		if ($i =~/\s*(\%>|<\/script\s*>)/i)	{$tc =$`; $i =$'}
		else					{$tc =''}
	}
	else {
		$ol =$i; $i ='';
	}
	$ol =~s/(["\$\@%\\])/\\$1/g;
	$ol =~s/[\n]/\\n");\n\$_[0]->output("/g;
	$o .= "\$_[0]->output(\"$ol\\n\");\n";
	next if !$ts || !$tc || $ts eq '%@';
	$tc =~s/\&lt;?/</g;
	$tc =~s/\&gt;?/>/g;
	$tc =~s/\&amp;?/\&/g;
	$tc =~s/\&quot;?/"/g;
	if    ($ts eq '%')	{ $o .= "\$_[0]->output($tc);\n" }
	elsif ($ts eq 'SCRIPT')	{ $o .= $tc .";\n"}
 }
 $o;
}


sub psEval {	# Evaluate perl script file
 my $s =shift;	# (?options, filename, ?base URL,...)
 my $o =substr($_[0],0,1) eq '-' ? shift : '-';
 my $f =shift;		# filename
 my $u =shift;		# base URL
 my $c =undef;		# code
 if ($f !~/^(\/|\w:[\\\/])/ && !-e $f) {
	$f =$s->{-path} .'/psp/' .$f;
	$u =$s->{-url}  if !$u;
 }
 my $h =$s->hfNew($f); $h->read($c, -s $f); $h->close();
 $s->output($s->{-c}->{-httpheader} =$s->cgi->header(
		  -charset => $s->charset()
	#	, -expires => 'now'
		, uc($ENV{REQUEST_METHOD}||'') ne 'POST' ? (-expires=>'now') : ()
		, ref($s->{-httpheader})
		? %{$s->{-httpheader}}
		: ()))
          if $o !~/e/;  # '-e'mbeddable html
 local $SELF =$s;
 $c =eval('sub{' .$s->psParse($o, $c, $u, @_) .'}');
 return(&{$s->{-die} }("psParse($o, $f)->$@" .$s->{-ermd}) && undef) if !$c;
 local $_ =$s;
 eval{&$c($s, $o, $f, @_)};
 return(&{$s->{-die} }("psEval($o, $f)->$@" .$s->{-ermd}) && undef) if $@;
 $s
}


sub cgiAction {	# cgiRun Action Executor encapsulated
		# self, obj name, ?obj meta, ?command, ?data
 my ($s, $on, $om, $oc, $od) =@_;
    $om =$s->{-form}->{$on}||$s->mdeTable($on) if !$om;
    $oc =$s->{-pcmd} if !$oc;
    $od =$s->{-pdta} if !$od;
 my $oa =$s->{-pcmd}->{-cmd};
 my $og =$oc->{-cmg};
 if	($oc->{-table} && $oa =~/^rec/) {
	if	($oa =~/^recList/) {
		$s->{-pout} =$s->cgiQuery($on, $om)
	}
	elsif	($oa =~/^recQBF/ ||$og =~/^rec(?:List|QBF)/) {
		$s->{-pout} ={%{$od}};
	}
	elsif	($oa =~/^rec(?:Read)/) {
		$s->rmiTrigger($oc, $od, undef, qw(-recTrim0A -recForm0A));
		if (ref($oc->{-key})) {
			my $m =$s->{-table}->{$oc->{-table}} ||$s->{-form}->{$oc->{-table}};
			if ($m && $m->{-key}) {
				my ($f, %v) =(1);
				foreach my $e (@{$m->{-key}}) {
					if (exists($oc->{-key}->{$e})) {
						$v{$e} =$oc->{-key}->{$e}
					}
					else {
						$f =undef;
					}
				}
				%{$oc->{-key}} =%v if $f
			}
		}
		$s->{-pout} =$s->recRead(
				(map {($_=>$oc->{$_})
				  } grep {defined($oc->{$_}) 
					&& $oc->{$_} ne ''
					}  qw(-table -key -wikn -wikq -form -edit -ui -version))
				, ref($om->{-recRead}) eq 'HASH' 
				? %{$om->{-recRead}} 
				: ());
	}
	else {
		$s->rmiTrigger($oc, $od, undef, qw(-recTrim0A))
			if $oa =~/^rec(?:New|Form|Ins|Upd|Del)/;
		$s->rmiTrigger($oc, $od, undef, qw(-recForm0A -recEdt0A))
			# uncleaned data may be needed for -recEdt0A
			if $oa =~/^rec(?:Form|Ins|Upd|Del)/;
		$od =$s->cgiDBData($on, $om, $oc, $od);
		$s->{-pout} =$s->$oa(-data=>$od
				, $oa =~/^rec(?:Upd|Del)/ ? (-version =>'+') : ()
				,(map {($_=>$oc->{$_})
				} grep {defined($oc->{$_}) 
					&& $oc->{$_} ne ''
					}  qw(-table -form -edit -ui -key -proto)));
	}
	$oc->{-key} =$s->recKey($oc->{-table}, $s->{-pout})
		if $oa =~/^rec(?:Read)/
		&& !$oc->{-edit};
	$oc->{-key} =$s->recWKey($oc->{-table}, $s->{-pout})
		if $oa =~/^rec(?:Read|Ins|Upd)/
		&& $oc->{-edit};
	delete $oc->{-key}
		if $oa =~/^rec(?:New)/;
	delete $oc->{-edit}
		if $oc->{-edit}
		&& $oa =~/^rec(?:Ins|Upd|Del)/;
	$s->{-pout} =$s->recRead(
			 (map {($_=>$oc->{$_})
				} grep {defined($oc->{$_}) 
					&& $oc->{$_} ne ''
					}  qw(-table -key -form -ui))
			, %{$om->{-recRead}})
		if ref($om->{-recRead}) eq 'HASH'
		&& $oa =~/^rec(?:Ins|Upd)/;
	$s->rmiTrigger($oc, $s->{-pout}, undef, qw(-recForm0A -recEdt0A))
		if $oc->{-edit} && ($oa =~/^rec(?:Read|New)/);
	$s->rmiTrigger($oc, $s->{-pout}, undef, qw(-recEdt1A))
		if $oa =~/^rec(?:Ins|Upd)/;
	$s->rmiTrigger($oc, $s->{-pout}, undef, qw(-recForm1A))
		if $oa =~/^rec(?:New|Form|Ins|Upd|Read)/;
 }
 elsif	($oa =~/^(recForm|frmHelp)/) {
	# nothing needed
 }
 else	{
	return(&{$s->{-die}}($s->lng(0,'cgiRun') .": Action '$oa\@$og' not found" .$s->{-ermd}) && undef)
 }
 $s->{-pout}
}


sub htmlStart {	# HTTP/HTML/Form headers
 my ($s,$on,$om)=@_;	# (object name, object meta)
 $on =$s->{-pcmd}->{-form} ||$s->{-pcmd}->{-table} ||'default'
	if !$on;
 my $cs	= $s->{-c}->{-htmlclass}
	= $s->{-pcmd}->{-xml}
	? undef
	: ref($s->{-htmlstart}) && $s->{-htmlstart}->{-class}
	? $s->{-htmlstart}->{-class}
	: $s->cgiHook('recOp')
	? 'Form' .($on ? ' ' .$on : '')
	: $s->cgiHook('recFormQ')
	? 'Form' .($on ? ' ' .$on : '') .' QBF' .($on ? ' ' .$on .'__QBF' : '')
	: $s->cgiHook('frmHelp')
	? 'Form Help' .($on ? ' ' .$on .'__Help' : '')
	: 'Form' .($on ? ' ' .$on : '') .' List' .($on ? ' ' .$on .'__List' : '');
 my $r	=join(""
	, $s->{-c}->{-httpheader}
	? ()
	: do{$s->{-c}->{-httpheader} =$s->cgi->header(
		-charset => $s->charset()
	#	, -expires => 'now'
		, uc($ENV{REQUEST_METHOD}||'') ne 'POST' ? (-expires=>'now') : ()
		, ref($s->{-httpheader}) 
		? %{$s->{-httpheader}} 
		: ()
		, $s->{-pcmd}->{-xml}
		? (-type => 'text/xml')
		: ()
		)}
	, $s->{-c}->{-htmlstart}  =
		  $s->{-pcmd}->{-xml}
		? (ref($s->{-xmlstart})
			? $s->xmlsTag($s->{-xmlstart})
			: ($s->{-xmlstart} 
			||('<?xml version="1.0"'
				.(!$s->{-charset}
				 ? ''
				 : ' encoding="' .$s->charset() .'"')
			  .' ?>'))
		  .($s->{-pcmd}->{-style}
		   ? '<?xml:stylesheet href="' .$s->{-pcmd}->{-style} .'" type="text/css" ?>'
		   : '')
		  )
		: $s->cgi->start_html(
			 -head	=> '<meta http-equiv="Content-Type" content="text/html; charset=' .$s->charset() .'">'
				.($s->{-pcmd}->{-refresh} 
					? '<meta http-equiv="refresh" content=' .$s->{-pcmd}->{-refresh} .'>' 
					: '')
			,-lang	=> $s->lang(0,'-lang')
			,-encoding => $s->charset()
			,-style	=> {-code=>''
				.".Body {font-size: 70%; font-family: Verdana, Helvetica, Arial, sans-serif; }\n"
				.".Input {font-size: 100%; font-family: Verdana, Helvetica, Arial, sans-serif; }\n"
				.".Form {margin-top:0px; }\n"
				."td.Form {border-style: none; border-width: 0px; padding: 0px;}\n"
				."th.Form {border-style: none; border-width: 0px; padding: 0px;}\n"
				."table.ListTable {border-collapse: collapse; }\n"
				."th.ListTable {border-style: inset; border-color: buttonface; border-width: 0px; border-bottom-width: 1px; }\n"
				."td.ListTable {border-style: inset; border-color: buttonface; border-width: 0px; border-bottom-width: 1px; padding: 0px; padding-left: 2px; padding-right: 1px; padding-top: 2px;}\n"
				.".ListTableFocus {background-color: buttonface;}\n"
				#.".MenuArea {background-color: navy; color: white;}\n"
				.".MenuButton {background-color: buttonface; color: black; text-decoration:none; font-size: 7pt}\n"
				.".MenuInput {font-size: 8pt}\n"
				.".htmlMQHsel {text-decoration: none; font-weight: bolder; border-style: inset;}\n"
				}
			,-title	=> 
				(do{	my $v =($s->{-pcmd} && $s->{-pcmd}->{-cmd} ||'') eq 'frmHelp'
						? $s->lng(0,'frmHelp')
						: (eval{$om && $s->lnglbl($om)});
					$v ? $v .' - ' : ''})
				.($s->{-title} ||$s->cgi->server_name())
			,-class	=> "Body $cs"
			,$s->{-pcmd}->{-frame}
			? (-target=>$s->{-pcmd}->{-frame})
			: $s->cgiHook('recFormRWQ') && $s->{-pcmd}->{-edit}
			? (-target=>'_blank')
			: (-target=>'_self')
			,ref($s->{-htmlstart}) 
			? %{$s->{-htmlstart}}
			: ()
			,$s->{-pcmd}->{-style}
			? (-style=>{'src'=>$s->{-pcmd}->{-style}})
			: ())
	, "\n"
	, $s->{-pcmd}->{-xml}
		? $s->xmlsTag($s->{-pcmd}->{-form}||'default'
			, (map { defined($s->{-pcmd}->{$_}) && ($s->{-pcmd}->{$_} ne '')
				? ((substr($_,0,1) eq '-' ? substr($_,1) : $_)
				 ,$s->{-pcmd}->{$_})
				: ()
				} sort keys %{$s->{-pcmd}})
			, 'xmlns'=>$s->url
			, '0')
		: $s->cgi->start_multipart_form(-method=>($s->{-pcmd}->{-refresh} ? 'get' : 'post')
			,-class	=> "$cs"
			,-action=> $s->url
			,-target=> '_self'
			,-name=>'DBIx_Web'
			# !!! 'DBIx_Web.' or 'forms[0].' syntax inflexible
			)
 ) ."\n";
 eval{warningsToBrowser(1)} if *warningsToBrowser{CODE};
 $r;
}


sub htmlEnd {	# End of HTML/HTTP output
 my ($s) =@_;
 if ($s->{-pcmd}->{-xml}) {		
	return("\n</" .$s->xmlTagEscape($s->{-pcmd}->{-form}||'default') .">\n")
 }
 else {
	return($s->cgi->endform()
	,"\n"
	,$s->htmlOnLoadW(
		(!$s->{-c}->{-jswload}
		|| !(grep {($_=~/\.target/) && ($_=~/'BASE'/)} @{$s->{-c}->{-jswload}})
		? "{var e=document.getElementsByTagName('BASE'); if(e && e[0] && (e[0].target=='_self')){e[0].target=(self.name=='BOTTOM' ? 'TOP1' : self.name=='TOP' ? 'BOTTOM'"
			.($s->{-pcmd}->{-frame}
				? " : self.name=='" .$s->{-pcmd}->{-frame} ."' ? 'TOP1'"
				 ." : self.name!='" .$s->{-pcmd}->{-frame} ."' ? '" .$s->{-pcmd}->{-frame} ."'"
				: '')
			." : e[0].target)}}"
		: ())
		,($s->{-pcmd}->{-search} && $s->{-c}->{-search}
		? ("{window.document.open('" 
			.($s->{-c}->{-search} =~/^\?/
			? $s->url() .$s->{-c}->{-search}
			: $s->{-c}->{-search}) ."','_search','',true)}")
		: ())
		)
	,$s->cgi->end_html())
 }
}


sub htmlOnLoad {# OnLoad event JavaScript store
	$_[0]->{-c}->{-jswload} =[] if !$_[0]->{-c}->{-jswload};
	push @{$_[0]->{-c}->{-jswload}}, @_[1..$#_];
	''
}


sub htmlOnLoadW {# OnLoad event JavaScript write
 $_[0]->htmlOnLoad(@_[1..$#_]) if $#_;
 return() if !$_[0]->{-c}->{-jswload};
 my $v ="<script for=\"window\" event=\"onload\">\n"
	.join("\n", @{$_[0]->{-c}->{-jswload}})
	."\n</script>\n";
 delete $_[0]->{-c}->{-jswload};
 $v
}


sub htmlHidden {# Common hidden fields
 my ($s, $on, $om) =@_;
 return('') if $s->{-pcmd}->{-xml} ||$s->{-pcmd}->{-print};
 $on =$s->{-pcmd}->{-form} ||$s->{-pcmd}->{-table} ||''
	if !$on;
 join("\n"
	,'<input type="hidden" name="_form" value="' .$s->htmlEscape($on) .'" />'
	,'<input type="hidden" name="_cmd"  value="" />'
	,'<input type="hidden" name="_cmg"  value="' .$s->htmlEscape($s->{-pcmd}->{-cmg}) .'" />'
	,(map { !defined($s->{-pcmd}->{"-$_"})
			|| (($s->{-pcmd}->{"-$_"} eq '') 
				&& ($_ !~/^(?:qkey|qwhere|qurole)$/))
		? ()
		: ('<input type="hidden" name="_' .$_ .'" value="'
		  .$s->htmlEscape(!defined($s->{-pcmd}->{"-$_"})
			? ''
			: ref($s->{-pcmd}->{"-$_"})
			? strdata($s, $s->{-pcmd}->{"-$_"})
			: $s->{-pcmd}->{"-$_"})
		  .'" />')
		} qw(edit backc key style frame)
		,($s->{-pcmd}->{-cmg} ne 'recQBF'
		? qw(qkey qjoin qwhere qurole quname qversion qorder qkeyord qlimit qdisplay)
		: qw(qlist))
		)
	) ."\n"
}


sub htmlMenu {	# Screen menu bar
 my ($s,$on,$om) =@_;
 return('') if $s->{-pcmd}->{-xml} ||$s->{-pcmd}->{-print};
 $on =$s->{-pcmd}->{-form} ||$s->{-pcmd}->{-table} ||''
	if !$on;
 $om =$on && $s->{-form}->{$on}||$s->mdeTable($on) if !$om;
 my $ot=$om && $om->{-table} && $s->mdeTable($om->{-table}) || $om;
 my $c =$s->{-pcmd};
 my $a =$c->{-cmd} ||'';
 my $g =$c->{-cmg} ||'';
 my $e =$c->{-edit};
 my $d =$s->{-pdta};
 my $n =$d->{-new} ||($c->{-cmg} eq 'recNew');
 my $cs=join(' '
	,$s->{-c}->{-htmlclass} ? $s->htmlEscape($s->{-c}->{-htmlclass}) : ()
	,'MenuArea');
 local $c->{-cmdt} =$ot || $om;	# table metadata
 local $c->{-cmdf} =$om || $ot;	# form  metadata
 my @r =();
 if	($s->{-logo}) {			# Logotype
	push @r, htmlMB($s, 'logo');
 }
 elsif	($s->{-icons}) {		# Home
	push @r, htmlMB($s, $s->{-c}->{-search}	? 'schpane' : 'home');
 }
 if	(1) {				# 'back' js button
	push @r, htmlMB($s, 'back'
		, $g ne 'recList'
		? $s->urlCmd('',-form=>$on, -cmd=>'recList', $c->{-frame} ? (-frame=>$c->{-frame}) : ())
		: $s->urlCmd('',$c->{-frame} ? (-frame=>$c->{-frame}) : ())
		, ($c->{-backc}||1));
 }
 if	($s->uguest()
	&& $s->{-login}) {		# Login
	push @r,htmlMB($s, 'login', $s->urlAuth());
 }
 if	($g eq 'recList') {		# View menu items
	local @{$s}{-menuchs, -menuchs1} =@{$s}{-menuchs, -menuchs1};
	$s->htmlMChs()
		if !$s->{-menuchs};
      # push @r, htmlMB($s, 'recForm');
	push @r, htmlML($s, 'frmName',  $s->{-menuchs}
			, !$c->{-frame} || ($c->{-frame} =~/^(?:TOP|BOTTOM)$/)
				? '-frame=set'
				: ()
			)	if $s->{-menuchs};
	push @r, htmlML($s, 'frmLso'
			, ref($om->{-frmLso}) eq 'CODE'
				? &{$om->{-frmLso}}($s, $on, $om, $c, exists($c->{-frmLso}) ? $c->{-frmLso} ||'' : ())
				: $om->{-frmLso}
			) if $om->{-frmLso};
	push @r, htmlMB($s,  htmlField($s, '_qftext', lng($s,1,'-qftext'), {-asize=>5, -class=>'Input ' .$cs .' MenuInput'}, $s->{-pcmd}->{-qftext}))
							if $s->{-menuchs};
	push @r, htmlML($s, 'frmName1', $s->{-menuchs1})if $s->{-menuchs1};
	local $c->{-frame} =undef;
	push @r, htmlMB($s, 'frmCall',	['', $s->urlOptl(-cmd=>'frmCall')])
							if $s->{-menuchs};
	push @r, htmlMB($s, 'recXML',	['', $s->urlOptl(-cmd=>'frmCall',-xml=>1)]);
	push @r, htmlMB($s, 'recQBF');
	if ($s->uguest) {}
	elsif ($om->{-recNew} || $om->{-recForm}
	|| ($on && (grep {(	!ref($_)
				? $_
				: ref($_) eq 'HASH'
				? $_->{-val}
				: $_->[0]) =~/^\Q$on\E\+/
		} @{$s->{-menuchs1} ||$s->{-menuchs} ||[]})) ) {
		push @r, htmlMB($s, 'recNew')
	}
	elsif (	$om->{-table}
	&&	!$om->{-field}
	&&	$s->{-table}->{$om->{-table}}
	&&	!$s->{-table}->{$om->{-table}}->{-ixcnd}
	&&	do{my $on =$om->{-table};
		grep {(	!ref($_)
				? $_
				: ref($_) eq 'HASH'
				? $_->{-val}
				: $_->[0]) =~/^\Q$on\E\+/
		} @{$s->{-menuchs1} ||$s->{-menuchs} ||[]}} ){
		push @r, htmlMB($s, 'recNew')
	}
 }
 elsif	($g eq 'recQBF') {		# QBF menu items
	push @r, htmlMB($s, 'recForm',	'');
	push @r, htmlMB($s, 'recQBFReset' );
	push @r, htmlMB($s, 'recList',	'');
	push @r, htmlMB($s, 'recXML',	'');
 }
 elsif	($g eq 'recDel') {		# Deleted record menu items
 }
 elsif	($s->cgiHook('recOp')) {	# Record menu items
	my $ea =(!$s->{-rac} ||$s->{-pout}->{-editable}) &&!$s->uguest
			&& ((ref($s->{-pout}->{-editable}) && $s->{-pout}->{-editable}->{-fr}) ||1);
	my @rk =('','_form'=>$_[0]->{-pcmd}->{-form}, '_key'=>strdata($_[0], $_[0]->{-pcmd}->{-key}));
	my $ll =$s->lnghash();
	local	$ll->{'recIns'} = $e && $n
				? [$ll->{'recUpd'}->[0], $ll->{'recIns'}->[1]]
				: $ll->{'recIns'};
	local	$IMG->{'recIns'}= $e && $n
				? $IMG->{'recUpd'}
				: $IMG->{'recIns'};
	push @r, htmlMB($s, 'recRead',	[@rk, '_cmd'=>'recRead'])
					if !$n;
	push @r, htmlMB($s, 'recPrint',	[@rk, '_cmd'=>'recRead', '_print'=>1])
					if !$n && !$e;
	push @r, htmlMB($s, 'recXML',	[@rk, '_cmd'=>'recRead', '_xml'=>1])
					if !$n && !$e;
	push @r, htmlMB($s, 'recHist',	[@rk, '_cmd'=>'recRead', '_hist'=>1])
					if !$n && !$e
					&& ($ot->{-rvcActPtr} ||$s->{-rvcActPtr});
	push @r, htmlMB($s, 'recEdit',	[@rk, '_cmd'=>'recEdit'])
					if !$n && !$e && $ea;
	push @r, htmlMB($s, 'recForm',	'')	if $e;
	push @r, htmlMB($s, 'recUpd',	'')	if $e && !$n;
	push @r, htmlMB($s, 'recNew'	# ,undef)
				,['','_cmd'=>'recNew','_form'=>$_[0]->{-pcmd}->{-form}
				, '_proto'=>strdata($_[0], $_[0]->{-pcmd}->{-key})])
					if !$n && !$e && !$s->uguest;
	push @r, htmlMB($s, 'recIns',	'')	if $e;
	push @r, htmlMB($s, 'recDel',	'')	if !$n && $ea
						&& (!ref($ea) ||!$ea->{-recDel});
 }
 if ($a ne 'frmHelp') {			# Help button
	push @r, htmlMB($s, 'frmHelp');
	# push @r, htmlMB($s, 'frmHelp', ['','_cmd'=>'frmHelp','_form'=>$_[0]->{-pcmd}->{-form}]);

 }
 delete $c->{-htmlMQH};
 my $mi	='[\'<i>'	.htmlEscape($s,lng($s, 0, $c->{-cmd}))
	.'\'@\''	.htmlEscape($s,lng($s, 0, $c->{-cmg}))
	.'\',  '	.htmlEscape($s, $s->user()) .'</i>]';
 my $mh =htmlEscape($s
		,($a eq 'frmHelp' 
			? $s->lng(0, 'frmHelp')
			: $s->lngcmt($om, $ot))
		 || (($s->{-title} ||$s->cgi->server_name() ||'') .' - ' .($c->{-form} ||'')));
 my $mc =$g ne 'recList'
	? ''
	: join("; "
	, grep {$_
		} 
		  (defined($c->{-qkey})
			? $c->{-qkey}
			: ($om->{-query} && $om->{-query}->{-qkey}))
		? do {	my $kq =$c->{-qkey} ||($om->{-query} && $om->{-query}->{-qkey});
			my $ko =$c->{-qkeyord}
				|| ($c->{-qorder} && (substr($c->{-qorder},0,1) eq '-') && $c->{-qorder})
				|| '-aeq';
			   $ko ={'eq'=>'=','ge'=>'>=','gt'=>'>','le'=>'<=','lt'=>'<'}->{substr($ko,2)}||'=';
			$s->htmlEscape(
				join(', ', map { "$_ $ko " 
						.dsdQuot($s," $ko ",$kq->{$_})
					} sort keys %$kq))
			}
		: ()
		, ($c->{-qkeyord} ? htmlEscape($s, lng($s, 0, '-qkeyord')  .' ' .lng($s, 0, $c->{-qkeyord} =~/^-*[db]/ ? 'desc' : 'asc')) : '')
		, (!$c->{-qwhere} 
				? ''
				: $c->{-qwhere} =~/^(?:\[\[\]\]|\/\*\*\/)+(.*)/
				? htmlEscape($s, $1)
				: htmlEscape($s, $c->{-qwhere}))
		, ($c->{-qjoin}	  ? htmlEscape($s, ($c->{-qjoin} =~/^\s*(?:CROSS|JOIN|INNER|STRAIGHT_JOIN|LEFT|NATURAL|RIGHT|OUTER)\b/i ? '' : (lng($s, 0, '-qjoin') .' ')) .$c->{-qjoin}) : '')
		, ($c->{-qurole}  ? htmlEscape($s, lng($s, 0, '-qurole')   .' ' .$c->{-qurole} .' /*' .$s->mddUrole($om, $c->{-qurole}) .'*/') : '')
		, ($c->{-quname}  ? htmlEscape($s, lng($s, 0, '-quname')   .' ' .$c->{-quname}) : '')
		, ($c->{-qftext}  ? htmlEscape($s, lng($s, 0, '-qftext')   .' ' .$c->{-qftext}) : '')
		, ($c->{-qversion}? htmlEscape($s, lng($s, 0, '-qversion') .' ' .$c->{-qversion}) : '')
		, ($c->{-qorder}  ? htmlEscape($s, lng($s, 0, '-qorder')	  .' ' .($c->{-qorder} !~/^-/ ? $c->{-qorder} : lng($s, 0, $c->{-qorder} =~/^-[db]/ ? 'desc' : 'asc'))) : '')
	);
    $mc = ($g eq 'recList') && ($om->{-frmLso1C} ||($ot->{-frmLso1C} && !exists($om->{-frmLso1C})))
	? &{$om->{-frmLso1C}||$ot->{-frmLso1C}}($s,$on,$om,$c,$mc)
	: $mc;

 ($s->{-banner}
	? (do{	my $v =ref($s->{-banner}) ? &{$s->{-banner}}($s,$on,$om) : $s->{-banner};
		$v
		? "\n<div class=\"$cs BannerDiv\">$v</div>"
		: ''
		})
	: '')
 .(!$s->{-icons}
 ?  "\n<div class=\"$cs MenuDiv\">" .join("\n", @r, $mi, '<br />', $mh, '<br />', $mc ? ($mc, '<br />') : ()) ."</div>\n\n"
 : ("\n<div class=\"$cs MenuDiv\"><table class=\"$cs\" cellpadding=\"0\"><tr>\n"
	# cellspacing=\"1px\"
	# style=\"position: absolute; top: 0; left: 0;\" # scrolled up
	# <br /><br />
	# scrollHeight
	.join("\n", @r)
	."\n" .'<td class="' .$cs .' MenuCell" valign="middle"><nobr>'
	. $mi .'</nobr></td></tr>'
	."\n" 
	."</table>\n<table class=\"$cs\" cellpadding=0  cellspacing=0 width=100%>"
		# margin-top: 0px; margin-bottom: 0px; padding: 0px
	.'<tr><th class="' .$cs .' MenuHeader" align="left" valign="top" colspan=20>' 
	.$mh .'</th></tr>'
	.(!$mc 	? ''
		: ("\n" .'<tr><td class="' .$cs .' MenuComment" align="left" valign="top" colspan=20>'
			.$mc 
			.'</td></tr>'))
	."\n</table></div>\n"
	.(0 && ($s->user() =~/diags/i) ? $s->diags('-html') : '')
	.(!$c->{-refresh} 
	? $s->htmlOnLoad('{var w=window.document.getElementsByTagName(\'table\')[' .($e ? 1 : 0) .']; if(w){w.focus()}}')
	: '')
	.(0	# scrollTop==0
	? '<script for="window" event="onscroll">{var w=window.document.getElementsByTagName(\'table\')[0]; window.status=document.body.scrollTop; if (!w) {} else if(document.body.scrollTop >(w.height||0)){w.style.position="absolute"; w.style.top=document.body.scrollTop} else {w.style.position="static"} return(true)}</script>' ."\n" 
	: '')
	."\n"))
}


sub htmlMB {	# CGI menu bar button
		# self, command, url, back|
 my $cs =($_[0]->{-c}->{-htmlclass} ? $_[0]->htmlEscape($_[0]->{-c}->{-htmlclass}) .' ' : '')
	.'MenuArea MenuButton';
 my $td0='<td class="' .$cs .'" valign="middle" style="border-width: thin; border-style: outset;" '; 
 my $tdb=($ENV{HTTP_USER_AGENT}||'') =~/MSIE/ 
	? ' onmousedown="if(window.event.button==1){this.style.borderStyle=&quot;inset&quot;}" onmouseup="this.style.borderStyle=&quot;outset&quot;" onmouseout="this.style.borderStyle=&quot;outset&quot;" onmousein="this.style.cursor=&quot;hand&quot"'
	: ' onmousedown="if(event.which==1){this.style.borderStyle=&quot;inset&quot;}" onmouseup="this.style.borderStyle=&quot;outset&quot;" onmouseout="this.style.borderStyle=&quot;outset&quot;"';
 if (!$_[0]->{-icons}) {
	if ($_[1] =~/^</) {
		$_[1]
	}
	elsif ($_[1] eq 'logo') {
		ref($_[0]->{-logo}) eq 'CODE' 
		? &{$_[0]->{-logo}}(@_) 
		: $_[0]->{-logo}
	}
	elsif ($_[1] eq 'login') {
		$_[1]
	}
	elsif ($_[1] eq 'back') {
		 '<input type="submit" class="Input ' .$cs .'" name="_' .$_[1] .'" '
		.' value="' .htmlEscape($_[0],lng($_[0], 0, $_[1])) .'" '
		.' onclick="{'
		.(!$_[3] ||$_[3] <2
			? 'window.history.back()'
			: 'window.history.go(-' .($_[3]-1) .'); window.history.back()')
		.'; return(false)}" '
		.' title="' .htmlEscape($_[0],lng($_[0], 1, $_[1])) .'" />'
	}
	else {
		 '<input type="submit" class="Input ' .$cs .'" name="_' .$_[1] .'" '
		.' value="' .htmlEscape($_[0],lng($_[0], 0, $_[1])) .'" '
		.' title="' .htmlEscape($_[0],lng($_[0], 1, $_[1])) .'" />'
	}
 }
 elsif ($_[1] =~/^</) {
	$td0 ."><nobr>\n" .$_[1] ."\n</nobr></td>"
 }
 elsif ($_[1] eq 'logo') {
	$_[0]->{-logo}
	? $td0 ."><nobr>\n"
	  .(	  ref($_[0]->{-logo}) eq 'CODE' 
		? &{$_[0]->{-logo}}(@_) 
		: $_[0]->{-logo}) ."\n</nobr></td>"
	: htmlMB($_[0],'home')
 }
 elsif ($_[1] eq 'login') {
	my $jc =' onclick="{window.location.replace(&quot;'
		.htmlEscape($_[0], $_[2])
		.'&quot;); return(false)}" ';
	my $tl =htmlEscape($_[0], lng($_[0], 1, 'login'));
	$td0  .' title="' .$tl .'"'
	.($tdb ? $tdb .$jc : '') ."><nobr>\n"
	.'<a href="' .$_[2] .'" '
	.' title="' .$tl .'" '
	.' class="' .$cs .'" target="_self" '
	.($tdb ? '' : $jc)
	.' ><img src="' .$_[0]->{-icons} .'/' .$IMG->{'login'} 
	.'" border=0  align="bottom" height="22" class="' .$cs .'" />'
	.htmlEscape($_[0], lng($_[0], 0, 'login')) ."</a>\n</nobr></td>"
 }
 elsif ($_[1] eq 'schpane') {
	my $pu =$_[0]->{-c}->{-search};
	my $fr =$pu=~/\b_frame=RIGHT\b/;
	my $su =$fr ? $_[0]->urlOpt(-search=>1) : $_[0]->{-c}->{-search};
	my $tl =htmlEscape($_[0], lng($_[0], 1, 'schpane'));
        $td0 
	.$tdb
	.' title="' .$tl .'"'
	.'><a href="' .$su .'" '
	.' title="' .$tl .'"'
	.' class="' .$cs .'"'
	.' target="' .($fr ? '_top' : '_search') .'"><img src="' 
	.$_[0]->{-icons} .'/' .($fr ? $IMG->{'schframe'} : $IMG->{'schpane'}) .'" border=0 align="bottom" class="' .$cs .'" '
	.' /></a>' ."\n</nobr></td>"
 }
 elsif ($_[1] eq 'home') {
	my $jc =' onclick="{window.document.open(\'' 
		.$_[0]->urlCat($_[0]->url,$_[0]->{-pcmd}->{-frame} ? ('_frame'=>$_[0]->{-pcmd}->{-frame}) : ())
		."','_self','',false); return(false)}\" ";
	my $tl =htmlEscape($_[0], lng($_[0], 1, 'home'));
        $td0 
	.($tdb ? $tdb .$jc : '')
	.' title="' .$tl .'"'
	.'><a href="' .($_[2] ||$_[0]->url) .'" '
	.($tdb ? '' : $jc)
	.' title="' .$tl .'"'
	.' class="' .$cs .'" target="_self"><img src="' .$_[0]->{-icons} .'/' .$IMG->{'home'} .'" border=0 align="bottom" class="' .$cs .'" '
	.' /></a>' ."\n</nobr></td>"
 }
 elsif ($_[1] eq 'back') {
	my $jc =' onclick="{'
		.(!$_[3] ||$_[3] <2
			? 'window.history.back(); '
			: ($ENV{HTTP_USER_AGENT}||'') =~/MSIE/
			?('window.history.go(-' .($_[3]-1) 
				.'); window.history.back(); ')
			: 1	# !!! Non MSIE backwarding omission
			?("window.document.open('" .htmlEscape($_[0],$_[2]) ."','_self','',false); ")
			:('window.history.back();' x $_[3])
				)
		.'return(false)}" ';
	my $jo =$jc =~/window\.document\.open/i;
	my $tl =htmlEscape($_[0], (!$jo ? '<-' .($_[3]||1) .'- ' : '') .lng($_[0], 1, 'back'));
	$td0 
	.' title="' .$tl .'"'
	.($tdb ? $tdb .$jc : '') ."><nobr>\n"
	.'<a href="' .($jo ? $_[2] ||$_[0]->url : $_[0]->url) .'" '
	.($tdb ? '' : $jc)
	.' title="' .$tl .'"'
	.' class="' .$cs .'" target="_self"><img src="' .$_[0]->{-icons} .'/' .$IMG->{'back'} .'" border=0 align="bottom" height="22" class="' .$cs .'" '
	.' /></a>' ."\n</nobr></td>"
 }
 else {
	my $hl =defined($_[2]) && !$_[2]
		? undef
		: urlCat($_[0], !$_[2] 
				? ('', '_form'=>$_[0]->{-pcmd}->{-form},'_cmd'=>$_[1]) 
				: ref($_[2]) ? @{$_[2]} : $_[2]);
	my $jc =' onclick="{'
		.(!$hl
		? ''
		: $_[1] =~/^(?:recRead|recPrint|recXML|recHist|recEdit|recNew|frmHelp)$/
		? "if((self.name=='BOTTOM') || (self.name=='TOP') ||document.getElementsByName('_frame').length){window.document.open('"
			.(($_[1] =~/^(?:recNew)$/ && ($hl =~/_proto=/))
			? (do {my $v=$hl; $v =~s/([?&;])_proto=/${1}_key=/; $v})
			: $hl)
			."','_blank','',false); return(false)}\n"
		: '')
		.'window.document.DBIx_Web._cmd.value=&quot;' .$_[1] .'&quot;; window.document.DBIx_Web.submit(); return(false)}" ';
	my $tl =htmlEscape($_[0],lng($_[0], 1, $_[1]));
	$td0 .' title="' .$tl .'"'
	.($tdb ? $tdb .$jc : '') ."><nobr>\n"
	.'<input type="image" name="_' .$_[1] .'" '
	.' src="' .$_[0]->{-icons} .'/' .($IMG->{$_[1]}||'none') .'" '
	.' align="bottom" title="' .$tl .'" class="' .$cs .'" style="cursor: default;"/>'
	.(!$hl
	?('<span class="' .$cs .'" style="cursor: default;"'
	 .' title="' .$tl .'">' .htmlEscape($_[0],lng($_[0], 0, $_[1])) .'</span>')
	 .($tdb ? '' : $jc)
	:('<a tabindex=-1 href="' .$hl .'" class="' .$cs .'" target="_self" '
	 .($tdb ? '' : $jc)
	 .' title="' .$tl .'">'
	 .htmlEscape($_[0],lng($_[0], 0, $_[1]))
	 .'</a>'))
	."\n</nobr></td>"
 }
}


sub htmlML {	# CGI menu bar list
 use locale;	# (self, name, values, ? add values)
 my $cs =join(' '
	,'Input'
	,$_[0]->{-c}->{-htmlclass} ? $_[0]->htmlEscape($_[0]->{-c}->{-htmlclass}) : ()
	,'MenuArea');
 my $i =  $_[1] eq 'frmName'
	? $_[0]->cgi->param('_'  .$_[1]) 
	||$_[0]->{-pcmd}->{'-' .$_[1]}
	||$_[0]->{-pcmd}->{-form} ||''
	: $_[1] eq 'frmLso'
	? (($_[0]->{-pcmd}->{'-' .$_[1]} ||'') eq '-all'
		? ''
		: ($_[0]->{-pcmd}->{'-' .$_[1]} ||''))
	: '';
 my $li =$_[3];
 my $f1 =undef;
 ($_[0]->{-icons}
	? '<td class="' .$cs .' MenuButton" valign="middle" title="'
		.$_[0]->htmlEscape(lng($_[0], 1, $_[1]))
		.'" style="border-width: thin; border-style: outset;" >' 
	: '')
 .do{$cs .=' MenuInput'; ''}
 .'<select name="_' .$_[1]
 .'" class="' .$cs .'" onchange="{'
 .( $_[1] eq 'frmLso'
  ? 'if (_frmLso.value==&quot;recQBF&quot;) {window.document.DBIx_Web._cmd.value=_frmLso.value; _frmLso.value=&quot;' .$_[0]->htmlEscape($i) .'&quot;; window.document.DBIx_Web.submit(); return(true);} else {window.document.DBIx_Web._cmd.value=&quot;frmCall&quot;; window.document.DBIx_Web.submit(); return(false);}}">'
  : 1 && ($_[1] eq 'frmName1')
  ? ("var v=_frmName1.value; _frmName1.value=''; document.body.style.cursor=_frmName1.style.cursor='wait'; window.document.open('" .$_[0]->url ."?_cmd=frmCall;_frmName1=' +encodeURIComponent(v)"
	.",self.name.match(/^(?:TOP|BOTTOM)\$/) || document.getElementsByName('_frame').length ? '_blank' : '_self'"
	.", '', false); document.body.style.cursor=_frmName1.style.cursor='auto'; return(true);}\">")
  : 1 && ($_[1] eq 'frmName')
  ? ('window.document.DBIx_Web._cmd.value=&quot;frmCall&quot;; '
	.($_[0]->{-menuchs1} && ($_[1] eq 'frmName') 
		? '_frmName1.value=&quot;&quot;; ' 
		: '')
	."if((_frmName.value=='-frame=set') && (self.name.match(/^(?:TOP|BOTTOM)\$/) || document.getElementsByName('_frame').length)){window.document.DBIx_Web.target='_parent'; _frmName.value=_form.value ? _form.value : ''; if (document.getElementsByName('_frame').length) {_frame.value=''}}"
	."else if(_frmName.value.match(/[+^]\$/) && (self.name.match(/^(?:TOP|BOTTOM)\$/) || document.getElementsByName('_frame').length)){var v=_frmName.value; _frmName.value=_form.value ? _form.value : ''; window.document.open('" .$_[0]->url ."?_cmd=frmCall;_frmName=' +encodeURIComponent(v), '_blank', '', false); return(true)}"
	#."else {var v=_frmName.value; document.body.style.cursor=_frmName.style.cursor='wait'; _frmName.value=_form.value ? _form.value : ''; window.document.open('" .$_[0]->url ."?_cmd=frmCall;_frmName=' +encodeURIComponent(v) +(document.getElementsByName('_frame').length ? ';_frame=' +_frame.value : '') +((v=='-frame=set') && _form.value ? ';_form=' +_form.value : ''), '_self', '', false); document.body.style.cursor=_frmName.style.cursor='auto'; return(true)};"
	."else {var v=_frmName.value; _frmName.value=_form.value ? _form.value : ''; _frmName.disabled=true; window.document.open('" .$_[0]->url ."?_cmd=frmCall;_frmName=' +encodeURIComponent(v) +(document.getElementsByName('_frame').length ? ';_frame=' +_frame.value : '') +((v=='-frame=set') && _form.value ? ';_form=' +_form.value : ''), '_self', '', false); _frmName.disabled=false; return(true)};"
	.'window.document.DBIx_Web.submit(); return(false);}">')
  : 'return(true)}')
 ."\n\t"
 .join("\n\t"
	, map { my ($n, $l) =!ref($_) 
			? ($_ , $_[1] !~/^frmName/
				? ucfirst($_[0]->lng(0, $_))
				: !$_
				? '--- ' .$_[0]->lng(0, 'frmCallNew') .' ---'
				: (do {	my($n, $x) =/([+&.^]*)$/ ? ($`, $1) : ($_,'');
					my $o =$_[0]->{-form}->{$n} ||$_[0]->{-table}->{$n};
					$o =$_[0]->lngslot($o,'-lbl') if $o;
					$o =&$o($_[0]) if ref($o);
					($o || ucfirst($_[0]->lng(0, $n)))
					.(!$f1 && $x && (substr($x,0,1) eq '+') ? " $x$x" : '')
					}))
			: ref($_) eq 'ARRAY'
			? ($_->[0]
				, (ref($_->[1]) ? $_[0]->lnglbl($_->[1]) : $_->[1])
				|| ucfirst($_[0]->lng(0, $_->[0])))
			: ($_->{-val}||$_->{-lbl}, $_[0]->lnglbl($_) ||ucfirst($_[0]->lng(0, $_->{-val})));
		$f1 =1	if (!$_ || !$n) && ($_[1] =~/^frmName/);
		'<option ' 
			.($i && ($n eq $i) 
			? do{$i =''; 'selected'}
			: '') 
		.(($n eq '') || ($l =~/^[-]+/)
		 ?(' class="' .$cs .' MenuInputSeparator"')
		 :(' class="' .$cs .'"'))
		.' value="' 
		.htmlEscape($_[0], $n)
		.'">' 
		.htmlEscape($_[0], $l)
		.'</option>'
		} $li
		? (map {if (!(!ref($_) ? $_ : ref($_) eq 'ARRAY' ? $_->[0] : $_) && $li) {
				my $v =$li;
				$li =undef;
				(ref($v) eq 'ARRAY' ? @$v : $v, $_)
			}
			else {
				($_)
			}} @{$_[2]})
		: @{$_[2]}
		, !$li ? () : ref($li) eq 'ARRAY' ? @{$li} : ($li)
	)
 .($i eq ''
  ? ''
  :('<option selected class="' .$cs
	.(($i eq '') || ($i =~/^[-]+/)
	 ? ' MenuSeparator'
	 : '')
	.'" value="'
	.htmlEscape($_[0], $i) .'">' 
		.htmlEscape($_[0]
			, $_[1] =~/^frmName/
			? ($_[0]->{-form} && $_[0]->{-form}->{$i} && $_[0]->lnglbl($_[0]->{-form}->{$i}))
			||($_[0]->{-table} && $_[0]->{-table}->{$i} && $_[0]->lnglbl($_[0]->{-table}->{$i}))
			||$_[0]->lng(0, $i)
			: $_[0]->lng(0, $i))
	.'</option>'))
 ."\n</select>"
 .($_[0]->{-icons} ? '</td>' : '')
}


sub htmlMChs {	# Adjust CGI forms list
 if (!$_[0]->{-menuchs}) {
 $_[0]->{-menuchs} =[];
 if	($_[0]->{-form}) {
	push @{$_[0]->{-menuchs}},
		map {[$_, ($_[0]->lnglbl($_[0]->{-form}->{$_},$_)||$_)]
			} grep {($_ ne 'default')
				&& ((ref($_[0]->{-form}->{$_}) ne 'HASH')
					|| !$_[0]->{-form}->{$_}->{-hide})
				} keys %{$_[0]->{-form}}
 }
 if	($_[0]->{-table}) {
	push @{$_[0]->{-menuchs}},
	map {[$_, ($_[0]->lnglbl($_[0]->{-table}->{$_},$_)||$_)]
		} grep {(ref($_[0]->{-table}->{$_}) ne 'HASH')
					|| !$_[0]->{-table}->{$_}->{-hide}
				} keys %{$_[0]->{-table}}
 }
 @{$_[0]->{-menuchs}} =sort {lc(ref($a) && $a->[1] || $a) cmp lc(ref($b) && $b->[1] || $b)
				} @{$_[0]->{-menuchs}};
 if ($_[0]->{-menuchs} && !$_[0]->uguest()) {
	my @a =( ['','--- ' .lng($_[0], 0, 'frmCallNew') .' ---']
		, map {[$_->[0] .'+', $_->[1] ] # .' ++' # also $f1 in htmlML()
			} grep { my $m;
				  ($m =$_[0]->{-form}->{$_->[0]})
				?  $m->{-field}
				: ($m =$_[0]->{-table}->{$_->[0]})
				? !$m->{-ixcnd}
				: 0
				} @{$_[0]->{-menuchs}}
		);
	if (@{$_[0]->{-menuchs}} <6)	{push @{$_[0]->{-menuchs}}, @a}
	else				{$_[0]->{-menuchs1} =[@a]}
 }}
 if ($_[0]->{-menuchs1}
 && (!ref($_[0]->{-menuchs1}->[0])
	? $_[0]->{-menuchs1}->[0]
	: ref($_[0]->{-menuchs1}->[0]) eq 'HASH'
	? $_[0]->{-menuchs1}->[0]->{-val}
	: $_[0]->{-menuchs1}->[0]->[0])) {
	unshift @{$_[0]->{-menuchs1}}, ['', '--- ' .lng($_[0], 0, 'frmCallNew') .' ---']
 }
 $_[0]->{-menuchs}
}


sub cgiDBData {	# Database data fields/values
		# self, form, meta, value hash
 my ($s, $n, $m, $c, $v) =@_;
     $m =$s->{-form}->{$n}||$s->{-table}->{$n} if !$m;
 my  $mt=$m->{-field}||($m->{-table} && $s->{-table}->{$m->{-table}}->{-field})||[];
 my  $mn=exists($m->{-null}) ? $m->{-null} : $m->{-table} ? $s->{-table}->{$m->{-table}}->{-null} : undef;
 my  $cc=($c && $c->{-cmd} ||'');
 my  @xx;
 my  $r ={};
 local $_;
 if (($c && $c->{-cmg} ||'') eq 'recNew') {
	$r->{-new} =$s->strtime;
 }
 foreach my $f (@$mt) {
	next if ref($f) ne 'HASH';
	$r->{$f->{-fld}} =!defined($v->{$f->{-fld}})
			? $v->{$f->{-fld}}
			: exists($f->{-null})
			? (defined($f->{-null}) && ($v->{$f->{-fld}} eq $f->{-null})
				?  undef : $v->{$f->{-fld}})
			: defined($mn)
			? ($v->{$f->{-fld}} eq $mn ? undef : $v->{$f->{-fld}})
			: $v->{$f->{-fld}}
		if exists ($v->{$f->{-fld}})
		&& (!defined($f->{-flg})
		||   $f->{-flg} =~/[aeu]/);	# 'a'll, 'e'dit, 'u'pdate
	if ($cc =~/^rec(?:Ins|Upd)/) {
		push @xx
			, ("'"	.$s->lnglbl($f,'-fld')
				."' - " .$s->lng(0,'fldReqStp'))
			if $f->{-flg} && ($f->{-flg} =~/[m]/)
			&& (!defined($r->{$f->{-fld}}) || ($r->{$f->{-fld}} eq ''));
		if ($f->{-chk}) {
			$_ =$r->{$f->{-fld}}; $@ ='';
			&{$f->{-chk}}($s,$m,$f,$r);
			if ($@)	{push @xx, ("'"	.$s->lnglbl($f,'-fld') ."' - "
						.$@ .' - ' .$s->lng(0,'fldChkStp'))}
			else	{$r->{$f->{-fld}} =$_}
		}
	}
 }
 return(&{$s->{-die}}($s->{-ermu} .join("\n",@xx). "\n\n") && undef)
	if scalar(@xx);
 %$r ? $r : undef
}


sub cgiForm {	# Print CGI screen form
		# self, form name, form meta, command, data
 my ($s, $n, $m, $c, $d) =@_;
    $m =$s->{-form}->{$n}||$s->mdeTable($n) if !$m;
    $c =$s->{-pcmd} if !$c;
    $d =$s->{-pout} if !$d;
 return($s) if ($c->{-cmg}||'') eq 'recDel';

 my $qm=($c->{-cmg}||'') eq 'recQBF';
 my $em=$c->{-edit} || $qm;
 my $fm=($em || $qm ? 'e' : '') .($qm ? 'q' : '') .($c && $c->{-print} ? 'p' : '');
 my $fr=ref($d) && ref($d->{-editable}) && $d->{-editable}->{-fr};

 my $mt=$m->{-table} ? $s->mdeTable($m->{-table}) : $m;
 local $c->{-cmdt} =$mt || $m;	# table metadata
 local $c->{-cmdf} =$m  || $mt;	# form  metadata
 local $s->{-pout} =$s->{-pout};

 my $lt =$c->{-xml} ? 1 : 0;	# 1 - closed table, 2 - table & labels
 my $lr =1;			# 1 - nxt row before
 my $hide =0;			# 1 - field hidden, 2 - hidden left
 my $edit =0;			# 1 - field editable

 if($qm) {
	$s->cgiQDflt($n, $m, $c);
	$d =$c->{-qkey} && {%{$c->{-qkey}}} || {} if (!$d ||!%$d);
	map {	$d->{$_} =ref($d->{$_})
			? $s->dsdQuot($d->{$_})
			: $d->{$_}
		} keys %$d;
	$c->{-frmLso} ='' if $c->{-frmLso} && ($c->{-frmLso} =~/^-/);
 }

 $s->output('<table>'
		# cellspacing="0" cellpadding="0"
		# margin + left + border + padding ["Measuring Element Dimension and Location"]
	, $qm && $c->{-frmLso}
	? ("\n<tr>\n"
		, '<th valign="top" align="left" title="' ,$s->lng(1,'frmLso'),'"><nobr>'
		, $s->lng(0,'frmLso')
		, "\n</nobr></th>\n"
		, '<td valign="top" align="left" colspan="10">'
		, $c->{-frmLso}
		? $s->htmlField('_frmLso', $s->lng(1,'frmLso')
			, {-labels=>
				{ref($c->{-frmLso}) eq 'ARRAY'
				? ($c->{-frmLso}->[0]=>$s->lng(0,$c->{-frmLso}->[0]))
				: ($c->{-frmLso}=>$s->lng(0,$c->{-frmLso}))
				}}
			, ref($c->{-frmLso}) eq 'ARRAY'
			? $c->{-frmLso}->[0]
			: $c->{-frmLso})
		: ()
		, "\n</td>\n</tr>\n"
		)
	: ()
	,"\n<tr>\n")
	if !$c->{-xml};

 # form additions	- using sub{} fields
 # file attachments	- using 'tfdRFD' / 'htmlRFD'
 # versions		- using sub{} fields with queries
 # embedded views	- using sub{} fields with queries
 foreach my $rhe ($c->{-hist}		# history loop
		 ? @{$s->recHist(-key=>$s->recKey($c->{-table}, $d)
				,-table=>$c->{-table})}
		 : $d) {
	next if !$rhe;
	if ($c->{-hist}) {
		$d =$s->{-pout} =$rhe->[3];
		$s->output("<tr>\n"
			,'<th valign="top" align="left"><nobr>'
			,'<a href="?_cmd=recRead' 
			,$HS ,'_form=', $s->htmlEscape($n) 
			,$HS ,'_key=', $s->htmlEscape($rhe->[0]), '"'
			,' title="', $s->htmlEscape($s->lng(1,'utime')), '"'
			,'>', $s->htmlEscape($rhe->[1]), "</a></nobr></th>\n"
			,'<td valign="top" align="left"'
			,' title="', $s->htmlEscape($s->lng(1,'updater')),,'"'
			,'><nobr>'
			,$s->htmlEscape($s->udisp($rhe->[2])), "</nobr></td>\n"
			,"</tr>\n");
	}
 foreach my $v (@{$m->{-field}		# field loop
		||($m->{-query} && $m->{-query}->{-data})
		||($m->{-table} && $s->mdeTable($m->{-table})->{-field})
		}) {
	my $f =(ref($v) && $v) || ($mt->{-mdefld} && $mt->{-mdefld}->{$v}) || $v;
	if	($c->{-xml})	{
		next if !ref($f);
		if	(ref($f) eq 'CODE')		{next}
		elsif	($f->{-inp}
			&& $f->{-inp}->{-rfd}
			&& $s->{-pout}->{-file})	{
			my $u =$s->rfdPath(-url=>$s->{-pcmd}, $s->{-pout});
			   $u =$s->url(-base=>1) .$u if $u !~/\/\/\w+:/;
			my $v =join("\n", map { $u .'/' .$_
				} $s->rfdGlobn($s->{-pcmd}, $s->{-pout}));
			$s->output($s->xmlsTag('files',''=>$v),"\n");
			next
		}
		elsif	(!$f->{-fld}
			||!defined($d->{$f->{-fld}})
			||($d->{$f->{-fld}} eq ''))	{next}
		my $v =$d->{$f->{-fld}};
		if	($f->{-inp} && $f->{-inp}->{-htmlopt}
			&& $s->ishtml($v))	{
			$s->output('<',$f->{-fld},'>'
			,$s->trURLhtm($v, sub{$_[1]}
			, sub{	  $_[1] =~/^[\w-]{3,7}:\/{2}/
				? $_[1]
				: $_[1] =~/^\//
				? $_[0]->url(-base=>1) .$_[1]
				: $_[0]->url .$_[1]
				})
			,'</',$f->{-fld},">\n");
		}
		elsif	($f->{-inp} && $f->{-inp}->{-hrefs}) {
			$v =$s->trURLtxt($v
			, sub{$_[1]}
			, sub{	  $_[1] =~/^[\w-]{3,7}:\/{2}/
				? $_[1]
				: $_[1] =~/^\//
				? $_[0]->url(-base=>1) .$_[1]
				: $_[0]->url .$_[1]
				});
			$s->output($s->xmlsTag($f->{-fld}, ''=>$v), "\n")
		}
		else	{
			$s->output($s->xmlsTag($f->{-fld}, ''=>$v), "\n")
		}
		next
	}
	elsif	($c->{-hist}) {
		next if ref($f) ne 'HASH';
		next if $f->{-inp} && $f->{-inp}->{-rfd}
			? (!$d->{-file})
			: (!$f->{-fld} || !exists($d->{$f->{-fld}}));
	}
	elsif	($f eq '')	{			# next col
		$lr =$hide && ($hide ==2) ? 1 : 0;
		$hide =0;
		next
	}
	elsif	($f =~/^(\n*)(\t*)$/)	{
		$lr =0;
		if	($1)		{		# new lines
			$s->output((!$lt ? "\n</tr>\n<tr>\n" : "\n<br />\n") 
					x (length($1)/length("\n")));
			$lr =1;
		}
		if	($2)		{		# skip cells
			$s->output($lr ? "\n</tr>\n<tr>\n" : ''
				, "<td> </td>\n" x length($2))
				if !$lt;
			$lr =0;
		}
		next;
	}
	elsif	($f eq "\f")		{		# close table
		$s->output("\n</tr>\n</table>\n") if !$lt;
		$lt =1; $lr =1;
		next
	}
	elsif	($f eq '</table>')		{	# close table & labels
		$s->output("\n</tr>\n</table>\n") if !$lt;
		$lt =2; $lr =1;
		next 
	}
	elsif	(!$f)			{next}
	elsif	(!ref($f))		{$s->output($f); next}
	elsif	(ref($f) eq 'CODE')	{$c->{-mail} && 1
					? eval{	$s->output(&$f($s,$n,$m,$c,$d))}
					: 	$s->output(&$f($s,$n,$m,$c,$d));
					next}
	else				{}

	local  $_=$d->{$f->{-fld}};
	$hide =    $qm && ($f->{-flg}||'') =~/[aq]/	# 'a'll, 'q'uery
		 ? 0
		 : $fr && $fr->{$f->{-fld}} && !ref($fr->{$f->{-fld}}) && ($fr->{$f->{-fld}} >1)
		 ? 1
		 : ((ref($f->{-hide})  eq 'CODE' ? &{$f->{-hide}} ($s,$f,$fm,$d) && 1 : $f->{-hide}  && 1)
		 || (ref($f->{-hidel}) eq 'CODE' ? &{$f->{-hidel}}($s,$f,$fm,$d) && 2 : $f->{-hidel} && 2)
		 || (defined($f->{-flg}) 
			 && (!$f->{-flg} ||($f->{-flg}=~/[-]/)) && 1)
		 || ($qm && !$f->{-fld} && 1)
		 || ($qm &&  defined($f->{-flg}) && ($f->{-flg} !~/[aq]/) && 1)
		 || ($qm &&  $f->{-inp}
			 && (ref($f->{-inp}) eq 'HASH') 
			 && (grep {$f->{-inp}->{$_}
					} qw(-rows -arows -hrefs -rfd)) 
			 && 1));
	$edit =  !$em
		? $qm
		: $fr && $fr->{$f->{-fld}} && !ref($fr->{$f->{-fld}})
		? 0
		: ref($f->{-edit})  eq 'CODE'
		? $qm || &{$f->{-edit}}($s,$f,$fm,$d)
		: exists($f->{-edit})
		? $qm ||  $f->{-edit}
		: $f->{-flg}		# 'a'll, 'e'dit', 'q'uery
		? ($f->{-flg}=~/[ae]/) || ($qm && ($f->{-flg}=~/[aeq]/))
		: defined($f->{-flg}) && (!$f->{-flg} ||($f->{-flg}=~/[-]/))
		? 0
		: 1;

	my $fuc =!$hide && $f->{-fld} && $s->mdeFldIU($mt, $f->{-fld});
	my $lbl =$s->htmlEscape($s->lnglbl($f,'-fld'));
	my $cmt =($s->lngcmt($f) ||$s->lng(1, $f->{-fld})) .' [' .$f->{-fld} .($f->{-flg} ? ': ' .$f->{-flg} : '') .']';
	$_=$d->{$f->{-fld}};
	my $rid =$hide || (exists($f->{-fvhref}) && !$f->{-fvhref})
		? undef
		: $f->{-fvhref} && !$c->{-print}
		? do{	my $v =$s->urlCmd(&{$f->{-fvhref}}($s,$f,$fm,$d));
			$v
			? '<a href="' .$v .'"' .($c->{-mail} ? ' target="_blank"': '') .' >'
			: undef}
		: $edit && !$c->{-print}
		  && $f->{-ddlb} && !ref($f->{-ddlb}) && ($f->{-ddlb} !~/\s/)
		  && (!defined($_) || ($_ eq ''))
		? '<a href="?_cmd=recList'
			.$HS .'_form=' .$s->htmlEscape($f->{-ddlb})
			.'">'
		: !defined($_) || ($_ eq '')
			|| (exists($f->{-form}) && !$f->{-form})
		? undef
		: !$c->{-print} && ref($f->{-form})
		? do {	$_=$d->{$f->{-fld}};
			my $v =ref($f->{-form}) eq 'CODE' 
			? &{$f->{-form}}($s,$f,$fm,$d) 
			: ref($f->{-form})
			? $s->urlCmd(''
				, !defined($_) || ($_ eq '')
				? (-form=> $f->{-form}->[0] || $m->{-table} || $n
				  ,-cmd => 'recList')
				: ($f->{-form}->[2] || '') eq '-wikn'
				? ($f->{-form}->[0] ? (-form=>$f->{-form}->[0]) : ()
				  , -cmd=>'recRead'
				  ,-wikn => $_)
				: (-form=> $f->{-form}->[0] || $m->{-table} || $n
				  ,-cmd => $f->{-form}->[1] || '' # 'recList'
				  ,-key =>{$f->{-form}->[2] || $f->{-fld} => $_}
				  ,-version=>'-')
				)
			: $f->{-form};
			$v =$s->urlCmd(@$v) if ref($v);
			$v
			? '<a href="' .$v .'"' .($c->{-mail} ? ' target="_blank"': '') .' >'
			: undef
			}
		: !$c->{-print}
		  && (	   $f->{-form} 
			|| (($f->{-flg}||'')=~/[h]/)
			|| $fuc
			|| (	(($f->{-flg}||'')=~/[aiuq]/)
				&&	($f->{-ddlb} 
					&& (!$f->{-ddlbtgt}
					   ? 1
					   : !ref($f->{-ddlbtgt})
					   ? ($f->{-ddlbtgt} !~/^<+/) 
						|| ($d->{$f->{-fld}} !~/[,;]/)
					   : !ref($f->{-ddlbtgt}->[0])
					   ? !$f->{-ddlbtgt}->[0]
						|| ($f->{-ddlbtgt}->[0] !~/^<+/)
						|| ($d->{$f->{-fld}} !~/[,;]/)
					   : !$f->{-ddlbtgt}->[0]->[2] 
						|| ( $f->{-ddlbtgt}->[0]->[2] =~/\d/ 
						   ? $d->{$f->{-fld}} !~/[,;]/
						   : index($d->{$f->{-fld}}, $f->{-ddlbtgt}->[0]->[2]) <0)
						)
					|| $f->{-inp} 
					&& ($f->{-inp}->{-values} 
						||$f->{-inp}->{-labels}))
				))
		? '<a href="?'
			.($f->{-form} ? '' : '_cmd=recList' .$HS)
			.'_form=' .$s->htmlEscape(
					   $f->{-form} && ($f->{-form} !~/^[\dy]$/i) 
					&& $f->{-form}
					|| $m->{-table} ||$n)
			.$HS .'_key='  .$s->htmlEscape($s->strdatah($f->{-fld} => $d->{$f->{-fld}}))
			.'"' .($c->{-mail} ? ' target="_blank"': '') .' >'
		: $qm
		? undef
		: (!$c->{-print} ||$c->{-mail})
		  && (($m->{-ridRef} ||$s->{-ridRef})
			&& (grep {$f->{-fld} eq $_
				} @{$m->{-ridRef}||$s->{-ridRef}})
			|| ($f->{-fld} eq ($m->{-rvcActPtr}
						||$s->{-rvcActPtr}||'"'))
			|| ($f->{-fld} eq ($m->{-key} && @{$m->{-key}} <2 
						&& $m->{-key}->[0]))
			)
		  && (!$f->{-inp} 
			|| !(grep {$f->{-inp}->{$_}
					} qw(-arows -rows -cols -hrefs -htmlopt)))
		? '<a href="?_cmd=recRead' 
		  .( $d->{$f->{-fld}} !~/\Q$RISM1\E/ 
		   ? $HS .'_form=' .$s->htmlEscape($n) 
		   : '')
		  .$HS .'_key=' .$s->htmlEscape($d->{$f->{-fld}}) 
		  .'"' .($c->{-mail} ? ' target="_blank"': '') .' >'
		: undef;

	$_=$d->{$f->{-fld}};
	my $rfn =$hide ||$c->{-print}
		? undef
		: $f->{-fnhtml}
		? &{$f->{-fnhtml}}($s,$f,$fm,$d) ||''
		: $f->{-fnhref}
		? do {	my $v =$s->urlCmd(&{$f->{-fnhref}}($s,$f,$fm,$d));
			$v 
			? "<a href=\"$v\"" 
			 .($c->{-mail} ? ' target="_blank"': '')
			 .' style="text-decoration: none; font-weight: bolder;" > *</a>'
			: ''
			}
		: undef;

	$_=$d->{$f->{-fld}};
	if	($hide)	{$lbl =' '}
	elsif	(defined($f->{-lblhtml})) {
		my $l =$f->{-lblhtml};
		$l =&$l($s,$f,$fm,$d) if ref($l) eq 'CODE';
		$l =~s/<\s*input[^<>]*>//ig if !$em;
		$l =~s/\$_/$lbl/;
		$lbl =$l
	}
	$lbl	=$rid .$lbl .'</a>'
		if $rid && $em && $edit && $lbl !~/<a\s+href\s*=\s*/i;
	$lbl	=$lbl .$rfn
		if $rfn && $em && $edit;
	$lbl	=$hide && ($hide ==2)
		? $lbl
		: $lt >1 && (!$f->{-inp} || !$f->{-inp}->{-rfd})
		? ''
		: $lt
		? '<span' 
			.($f->{-fhclass} ? ' class="' 
						.(ref($f->{-fhclass})
						? &{$f->{-fhclass}}($s,$f,$fm,$d)
						: $f->{-fhclass}) .'"' : '')
			.($f->{-fhstyle} ? ' style="'
						.(ref($f->{-fhstyle})
						? &{$f->{-fhstyle}}($s,$f,$fm,$d)
						: $f->{-fhstyle}) .'"' : '')
			.' title="' .htmlEscape($s,$cmt) .'"'
			.($f->{-fhprop} ? ' ' .$f->{-fhprop} : '')
			.'>' .$lbl .'</span>'
		: $lbl =~/^\s*<t[dh]\b/i 
		? $lbl 
		:('<th align="left" valign="top"'
			.($f->{-fhclass} ? ' class="'
						.(ref($f->{-fhclass})
						? &{$f->{-fhclass}}($s,$f,$fm,$d)
						: $f->{-fhclass}) .'"'
					 : '')
			.($f->{-fhstyle} ? ' style="'
						.(ref($f->{-fhstyle})
						? &{$f->{-fhstyle}}($s,$f,$fm,$d)
						: $f->{-fhstyle}) .'"'
					 : '')
					# style="padding-left: 0; padding: 0; margin-left: 0; margin: 0; border-left-width: 0; border-width: 0; layout-grid-mode: none;"
			.' title="' .htmlEscape($s,$cmt) .'"'
			.($f->{-fhprop} ? ' ' .$f->{-fhprop} : '')
			.'>' .$lbl .'</th>');
	if ($f->{-lblhtbr} && !$c->{-hist}) {
		$lbl =(!$lr ? '' : "\n</tr>\n<tr>\n") 
			.$lbl
			."\n</tr>\n</table>\n"
			if !$lt;
		$lt =$f->{-lblhtbr} eq '</table>' ? 2 : 1;
		$lr =0;
	}

	$_=$d->{$f->{-fld}};
	my $wgp = $hide
		? ''
		: $edit
		? htmlField($s, $f->{-fld}, $cmt
			, $fr && ref($f->{-inp}) && ref($fr->{$f->{-fld}})
			? (ref($fr->{$f->{-fld}}) eq 'HASH'
				? $fr->{$f->{-fld}}
				: {%{$f->{-inp}}, -values=>$fr->{$f->{-fld}}})
			: $f->{-inp}
			, $d->{$f->{-fld}})
		: $f->{-inp} && ($f->{-inp}->{-labels} || $f->{-inp}->{-hrefs} || $f->{-inp}->{-htmlopt})
		? htmlField($s, '', $cmt, $f->{-inp}, $d->{$f->{-fld}})
		: $fuc || $s->mdeFldRW($mt, $f->{-fld})
		? $s->htmlEscape($s->udisp($d->{$f->{-fld}}))
		: htmlField($s, '', $cmt, $f->{-inp}, $d->{$f->{-fld}});
	$wgp ='<input type="hidden" name="' .$s->htmlEscape($f->{-fld}) .'" value="' .$s->htmlEscape($_) .'" />'
		.$wgp
		if $em && !$qm && !$edit && !$hide && defined($_) && ($_ ne '')
		# && $fr # !!! commented 2007-04-08 to remove
		&& (!defined($f->{-flg}) ||($f->{-flg} =~/[aeu]/)); # as cgiDBData()
	if (!$hide && defined($f->{-inphtml})) {
		my $wgh	=$f->{-inphtml};
		$wgh	=&$wgh($s,$f,$fm,$d) if ref($wgh) eq 'CODE';
		$wgh	=~s/<\s*input[^<>]*>//ig if !$edit;
		$wgh	=~s/\$_/$wgp/;
		$wgp	=$wgh
	}
	$wgp	=$rid .$wgp .'</a>'
		if $rid && !$edit && $wgp !~/<a\s+href\s*=\s*/i;
	$wgp	=$wgp .$rfn
		if $rfn && !$edit;
	$wgp	='<td valign="top" align="left"'
		.($f->{-colspan} ? ' colspan=' .$f->{-colspan} :'')
		.($f->{-fdclass} ? ' class="'  .(ref($f->{-fdclass})
						? &{$f->{-fdclass}}($s,$f,$fm,$d)
						: $f->{-fdclass}) .'"' : '')
		.($f->{-fdstyle} ? ' style="'   .(ref($f->{-fdstyle})
						? &{$f->{-fdstyle}}($s,$f,$fm,$d)
						: $f->{-fdstyle}) .'"' : '')
		.($f->{-fdprop}	 ? ' ' .$f->{-fdprop} : '')
		.'>' .$wgp .'</td>'
		if $wgp !~/^\s*<t[dh]\b/i 
		&& !$lt
		&& !($hide && ($hide ==2));

	$_=$d->{$f->{-fld}};
	if	(!$lt) {
		if ($hide && ($hide ==2)) {
		}
		elsif ($f->{-ddlb} && $em && $edit && !$hide) {
			my $wg1='';
			($wgp, $wg1) =($`, $1) if $wgp =~/(<\/t[dh]>)$/i;
			$s->output((!$lr ? '' : "\n</tr>\n<tr>\n"), $lbl, $wgp);
			$s->cgiDDLB($f, $fm, $d, $d);
			$s->output($wg1, "\n");
			$wgp .=$wg1
                }
		else {
			$s->output((!$lr ? '' : "\n</tr>\n<tr>\n"), $lbl, $wgp, "\n");
		}
	}
	elsif	(!$hide) {
		if ($f->{-ddlb} && $em) {
			$s->output($lbl, ' ', $wgp);
			$s->cgiDDLB($f, $fm, $d, $d);
			$s->output("<br />\n")
		}
		elsif ($wgp ne '')  {
			$s->output($lbl, ' ', $wgp
				, $wgp =~/<(\/p|br\s*\/)>[\s\r\n]*$/i
				? "\n" : "<br />\n")
		}
		elsif ($f->{-lblhtbr} && ($lbl =~/<\/table>[\r\n]*$/i) && !$c->{-hist}) {
			$s->output("\n</tr>\n</table>\n")
		}
	}
	elsif ($f->{-lblhtbr} && ($lbl =~/<\/table>[\r\n]*$/i) && !$c->{-hist}) {
			$s->output("\n</tr>\n</table>\n")
	}
	$lr =1
 }}

 if ($qm) {	# Query condition fields
	my $q =($c->{-qlist} && $s->{-form}->{$c->{-qlist}} && $s->{-form}->{$c->{-qlist}}->{-query})
		|| ($c->{-qlist} && $s->{-table}->{$c->{-qlist}} && $s->{-table}->{$c->{-qlist}}->{-query})
		|| $m->{-query} ||{};
	$s->output($lt
		? "<hr />\n<table cellpadding=0>\n"
		: "<tr><td colspan=10><hr /></td></tr>\n"
		);
	$lt =0; $lr =1;
	my $th =sub{'<tr><th align="left" valign="top" title="' 
			.htmlEscape($_[0], lng($_[0], 1 ,$_[1]))
			.'">'
			.htmlEscape($_[0], lng($_[0], 0, $_[1]))
			.'</th>'
			};
	my $td ='<td align="left" valign="top" colspan=10>';
	my $de =$s->{-table}->{$m->{-table}||$n};
	   $de =($de && $de->{-dbd})||$s->{-tn}->{-dbd};
	my $qo ={qw (all all eq == ge >= gt > le <= lt <)};
	   $qo ={map {("-a$_", 'asc ' .$qo->{$_}, "-d$_", 'dsc ' .$qo->{$_})} keys %$qo};
	my $qk =1; # -qkeyord switch
	$s->{-pcmd}->{-qkey} =$s->cgiQKey($n,$m
		,{map {	$_ =~/^_q/ ? () : ($_ => $s->{-pdta}->{$_})
			} keys %{$s->{-pdta}}});
	$s->output(&$th($s, '-qkeyord'), $td
		, htmlField($s, '_qkeyord', lng($s,1,'-qkeyord')
			, {-labels=>$qo}
			, $c->{-qkeyord}||'')
		, '<font style="font-size: smaller;" title="default">'
		, $q->{-keyord} || ($de eq 'dbm')
		? htmlEscape($s, '(' .($q->{-keyord} && $qo->{$q->{-keyord}} ||$q->{-keyord} ||($de eq 'dbm' ? $qo->{$KSORD} ||$KSORD : '') ||'') .')')
		: ()
		, '</font>'
		, "</td></tr>\n")
		if $qk;
	$s->output(&$th($s, '-qjoin'), $td
		, htmlField($s, '_qjoin', lng($s,1,'-qjoin')
			, {-size=>50}
			, $c->{-qjoin})
		, "</td></tr>\n")
		if $de eq 'dbi';
	$s->output(&$th($s, '-qwhere'), $td
		, htmlField($s, '_qwhere'
			, $s->lng(0,"-qwhere$de") .': ' .$s->lng(1,"-qwhere$de")
			, {-arows=>1,-cols=>45}
			, $c->{-qwhere})
		, '<font style="font-size: smaller;" title="additional">'
		, !$q->{-where}
		? ()
		: ref($q->{-where}) eq 'ARRAY' 
		? htmlEscape($s, ' AND ' .join(' AND ', @{$q->{-where}}))
		: ref($q->{-where})
		? htmlEscape($s, '(' .$q->{-where} .')')
		: htmlEscape($s, ' AND ' .$q->{-where})
		, $q->{-filter}
		? htmlEscape($s, ' FILTER ' .$q->{-filter})
		: ()
		, $m && $m->{-qfilter}
		? htmlEscape($s, ' FILTER ' .$m->{-qfilter})
		: ()
		, "</font></td></tr>\n");
	if ($s->mdeRAC($m)) {
		$s->output(&$th($s, '-qurole'), $td
		, htmlField($s, '_qurole', lng($s,1,'-qurole')
			, {-values=>[$s->mdeRoles($mt)]}, $c->{-qurole})
		, htmlField($s, '_quname', lng($s,1,'-quname'), undef, $c->{-quname})
			);
		$_ =$c->{-quname};
		$s->cgiDDLB({-fld=>'_quname', -ddlb=>sub{$_[0]->uglist({})}}, 'eq', $c, $c);
		$s->output("</td></tr>\n");
	}
	$s->output(&$th($s, '-qftext'), $td
		, htmlField($s, '_qftext', lng($s,1,'-qftext')
			, {-size=>50}
			, $c->{-qftext})
		, "</td></tr>\n");
	$s->output(&$th($s, '-qversion'), $td
		, htmlField($s, '_qversion', lng($s,1,'-qversion'), {-values=>['-','+']}, $c->{-qversion})
		, '<font style="font-size: smaller;" title="default">('
		, $q->{-version} || '-', ')</font>'
		, "</td></tr>\n");
	$s->output(&$th($s, '-qorder'), $td
		, htmlField($s, '_qorder', lng($s,1,'-qorder')
			, {$de eq 'dbm' 
			  ? (-labels=>$qo)
			  :(-asize=>50)}
			, $c->{-qorder}||'')
		, '<font style="font-size: smaller;" title="default">'
		, $q->{-order} 
		? htmlEscape($s, '(' .($qo->{$q->{-order}} ||$q->{-order} ||$qo->{$q->{-keyord}} ||$q->{-keyord}) .')')
		: $de eq 'dbm'
		? htmlEscape($s, '(' .($qo->{$KSORD}||$KSORD) .')')
		: ()
		, '</font>'
		, "</td></tr>\n")
		if !$qk;
	$s->output(&$th($s, '-qorder'), $td
		, htmlField($s, '_qorder', lng($s,1,'-qorder')
			, {-asize=>50}
			, $c->{-qorder}||'')
		, '<font style="font-size: smaller;" title="default">'
		, $q->{-order}
		? htmlEscape($s, '(' .($qo->{$q->{-order}} ||$q->{-order}) .')')
		: ()
		, '</font>'
		, "</td></tr>\n")
		if $qk && ($de eq 'dbi');
	$s->output(&$th($s, '-qdisplay'), $td
		, $c->{-frmLsc}
		? $s->htmlField('_frmLsc', $s->lng(1,'-frmLsc')
			, {-labels=>{$c->{-frmLsc} => $s->lnglbl($m->{-mdefld} && $m->{-mdefld}->{$c->{-frmLsc}}, $mt->{-mdefld} && $mt->{-mdefld}->{$c->{-frmLsc}}) 
							||$s->lng(0,$c->{-frmLsc})}}
			, $c->{-frmLsc})
		: ()
		, !$q->{-group}
		? htmlField($s, '_qdisplay', lng($s,1,'-qdisplay')
			, {-arows=>1,-cols=>45}
			, $c->{-qdisplay})
		: ()
		, "</td></tr>\n") if $c->{-frmLsc} || !$q->{-group};
	$s->output(&$th($s, '-qlimit'), $td
		, htmlField($s, '_qlimit', lng($s,1,'-qlimit')
			, {-values=>[128,256,512,1024,2048,4096]}
			, $c->{-qlimit}||'')
		, '<font style="font-size: smaller;" title="default">('
		, $q->{-limit}||$m->{-limit}||$s->{-limit}||$LIMRS
		, ')</font>'
		, "</td></tr>\n");
	$s->output(&$th($s, '-style'), $td
		, htmlField($s, '_style', lng($s,1,'-style'), {-size=>50}, ($c->{-style}||'') =~/\x00/ ? $c->{-style} =$' : $c->{-style})
		, htmlField($s, '_xml', lng($s,1,'-xml'), {-labels=>{''=>'','yes'=>'xml'}})
		, "</td></tr>\n"
		) if 0;
	my $u =htmlEscape($s, $s->urlCat($s->url(-relative=>1)
			, '_cmd'=>'recList', '_form'=>$c->{-form}
			, !(grep {defined($c->{$_}) && ($c->{$_} ne '')
					} qw (-qkey -qwhere -qurole))
			? ('_qkey'=>'')
			: ()
			, map { !defined($c->{"-$_"}) ||($c->{"-$_"} eq '')
				? ()
				: ("_$_"
				  , ref($c->{"-$_"})
				  ? $s->strdata($c->{"-$_"})
				  : $c->{"-$_"})
				} qw(qkey qkeyord qjoin qwhere qurole quname qftext qversion qorder qlimit qdisplay frmLso frmLsc style xml)

		  ));
	$s->output(&$th($s, '-qurl')
		, $td
		, '<a href="', $u, '">', $u, '</a>'
		, "</td></tr>\n");
 }
 else {		# Read/Edit, should be nothing
 }

 $s->output(!$lt ? "</table>\n" : "\n")
	if !$c->{-xml};
 $s
}


sub htmlField {	# Generate field widget HTML
		# self, field name, title, meta, value
 my ($s, $n, $t, $m, $v) =@_;
 my $wgp ='';
 my $cs =$n && $s->{-c}->{-htmlclass} ? 'Input ' .$s->{-c}->{-htmlclass} : 'Input';
 $v ='' if !defined($v);
 if	(!$n)	{				# View only
	if	(ref($m) ne 'HASH')	{			# Textfield
		$wgp  =htmlEscape($s, $v) 
	}
	elsif	($m->{-htmlopt} && $s->ishtml($v))	{	# HTML Text
		$wgp =$s->trURLhtm($v,sub{$_[1]},sub{$_[1]})
	}
	elsif	($m->{-hrefs})	{				# Text & Hyperlinks
		$wgp =$s->trURLtxt($v
		, sub{	my $v =$_[1];
			$v =htmlEscape($_[0], $_[1]);
			$v =~s/( {2,})/'&nbsp;' x length($1)/ge;
			$v =~s/\n/<br \/>\n/g; 
			$v =~s/\r//g;
			$v
			}
		, \&trURLhref);
		$wgp =	$s->htfrDiff($wgp)
			if $s->{-pcmd} 
			&& $s->{-pcmd}->{-hist};
		# $wgp ='<code>' .$wgp .'</code>' if $v =~/ {2,}/;
	}
	elsif	(grep {exists($m->{$_})} qw(-arows -rows -cols)) {# Resizeable text
		$v =htmlEscape($s,$v); 
		$v =~s/( {2,})/'&nbsp;' x length($1)/ge; 
		$v =~s/\n/<br \/>\n/g; 
		$v =~s/\r//g;
		# $v ="<code>$v</code>" if $v =~/&nbsp;&nbsp/;
		$wgp  =$v;
	}
	elsif	($m->{-values} ||$m->{-labels}) {		# Listbox
		my $l =lngslot($s, $m, '-labels') 
			|| (ref($m->{-values}) eq 'HASH') && $m->{-values};
		$l    =&{$l}($s)	if ref($l) eq 'CODE';
		$v    =$l->{$v}		if $l && defined($l->{$v});
		$wgp  =htmlEscape($s, $v)
	}
	elsif	($m->{-rfd}) {					# RFD Filebox
		$wgp =$s->htmlRFD()
	}
	else {							# Textfield
		$wgp =htmlEscape($s, $v)
	}
 }
 elsif	(!$m) {					# Default text field
	my $l =defined($v) ? length($v) : 0;
	   $l =$l <20 ? 20 : $l >80 ? 80 : $l;
	$wgp  ='<input type="text" name="' .$n
		.'" title="'	.htmlEscape($s, $t)
		.'" size="'	.$l
		.'" value="'	.htmlEscape($s, $v)
		.($cs ? '" class="' .htmlEscape($s,$cs) : '')
		.'" />'
 }
 elsif (ref($m) eq 'HASH') {
	if	(exists $m->{-arows} 
		|| grep {$m->{$_}} qw(-rows -cols -hrefs)) {	# Textarea
		my $a ={%$m}; delete @$a{-hrefs, -arows};
		if (exists($m->{-arows})) {
			my $ar =0;
			$a->{-cols} =20 if !$a->{-cols};
			if ($a->{-wrap} && lc($a->{-wrap}) eq 'off') {
				my @a =split /\n/, $v;
				$ar =scalar(@a)
			}
			else {
				foreach my $r (split /\n/, $v) {
					$ar +=1 +(length($r) >$a->{-cols} 
					? int(length($r)/$a->{-cols}) +1 
					:0);
				}
			}
			$a->{-rows} =($m->{-arows} >$ar ? $m->{-arows} : $ar);
			$a->{-rows} =20 if $a->{-rows} >30;
		}
		if (defined($m->{-hrefs})) {
			my $h =$s->ishtml($v) 
				? $s->trURLhtm($v, undef, \&trURLhref)
				: $s->trURLtxt($v, undef, \&trURLhref);
			$wgp .=join(';&nbsp; ', @$h);
			$wgp .='<br />' if $wgp;
		}
		$wgp .=$s->cgi->textarea(
			 ($cs ? (-class=>$cs) : ())
			,(map {($_ =>	(ref($a->{$_}) eq 'CODE' 
					? &{$a->{$_}}($s,$a,local($_)=$v)
					: $a->{$_}))} keys %$a)
			,-name=>$n, -title=>$t, -default=>$v, -override=>1);
		$wgp .="<input type=\"submit\" name=\"${n}__b\" value=\"R\" "
		."title=\"Rich/Text edit: ^Bold, ^Italic, ^Underline, ^hyperlinK, Enter/shift-Enter, ^(shift)T ident, ^Z undo, ^Y redo.\" "
		.($cs ? 'class="' .htmlEscape($s,$cs) .'" ': '')
		."style=\"font-style: italic;\" "
		."onclick=\"{if(${n}__b.value=='R') {${n}__b.value='T'; $n.style.display='none'; "
		."\n var r; r =document.createElement('<span contenteditable=true id=&quot;${n}__r&quot; title=&quot;MSHTML Editing Component&quot; ondeactivate=&quot;{$n.value=${n}__r.innerHTML}&quot;></span>'); ${n}__b.parentNode.insertBefore(r, $n)\n"
		."r.contentEditable='true'; r.style.borderStyle='inset'; r.style.borderWidth='thin'; r.normalize; r.innerHTML =!$n.value ? ' ' : $n.value; r.focus();}\n"
		."else {${n}__b.value='R'; $n.value=!${n}__r.innerHTML ? '' : ${n}__r.innerHTML.substr(0,1)!='&lt;' && ${n}__r.innerHTML.indexOf('&lt;')>=0 ? '&lt;span&gt;&lt;/span&gt;' +${n}__r.innerHTML : ${n}__r.innerHTML; ${n}__r.removeNode(true); $n.style.display='inline'; $n.focus();};\n"
				#${n}__r.innerHTML ? ${n}__r.innerHTML : ''; ${n}__r.removeNode(true); $n.style.display='inline'; $n.focus();};\n"
		." return(false)}\" />\n"
		#MSHTML Edit Control for IE5.5
		if $m->{-htmlopt} && ($ENV{HTTP_USER_AGENT}||'') =~/MSIE/;
	}
	elsif	(exists $m->{-asize}) {			# Textfield
		$wgp  =$s->cgi->textfield(
			 ($cs ? (-class=>$cs) : ())
			,(map {	  $_ ne '-asize'
				? ($_=>ref($m->{$_}) ne 'CODE' 
					? $m->{$_} 
					: &{$m->{$_}}($s,$m,local($_)=$v))
				: ('-size'=>do {
					my $z =$m->{-asize};
					   $z =(ref($z) ne 'CODE' 
						? $z 
						: &$z($s,$m,local($_)=$v)) ||20;
					my $l =defined($v) ? length($v) : 0;
					$l < $z ? $z : $l >80 ? 80 : $l;
					})
				} keys %$m)
			,-name=>$n
			,-title=>$t
			,-override=>1
			,-default=>$v)
	}
	elsif	($m->{-values} ||$m->{-labels}) {	# Listbox
		my $tv	=$m->{-values};
		   $tv	=&$tv($s) if ref($tv) eq 'CODE';
		my $tl	=$s->lngslot($m, '-labels');
		   $tl	=&$tl($s) if ref($tl) eq 'CODE';
		$tv	=do{use locale; [sort {$tl->{$a} cmp $tl->{$b}} keys %$tl]}
			if !$tv && $tl;
		unshift @$tv, $v if defined($v) && ($v ne '') && !grep {$_ eq $v} @$tv;
		unshift @$tv, '' if $s->{-pcmd}->{-cmg} eq 'recQBF';
		$wgp	=$s->cgi->popup_menu(
			 ($cs ? (-class=>$cs) : ())
			,($m->{-ddlbloop} ? !ref($m->{-ddlbloop}) || &{$m->{-ddlbloop}}($s) : 0)
			||($m->{-loop} ? !ref($m->{-loop}) || &{$m->{-loop}}($s) : 0)
				? (-onchange => '{window.document.DBIx_Web._cmd.value="recForm"; window.document.DBIx_Web.submit(); return(false)}')
				: ()
			,(map {	!defined($m->{$_}) || ($_=~/^(?:-ddlbloop|loop)$/)
				? ()
				: ref($m->{$_}) eq 'CODE'
				? (do {	my $n =$_; local $_ =$v;
					($n => &{$m->{$n}}($s,$m,$_))
					})
				: ($_ => $m->{$_})} keys %$m)
			,-name=>$n, -title=>$t
			, $tv ? (-values=>$tv) : ()
			, $tl ? (-labels=>$tl) : ()
			,-override=>1,-default=>$v)
	}
	elsif	($m->{-rfd}) {				# RFD Filebox
		$wgp =$s->htmlRFD()
	}
	else {						# Textfield
		$wgp =$s->cgi->textfield(
			 ($cs ? (-class=>$cs) : ())
			,(map {($_ =>	(ref($m->{$_}) eq 'CODE' 
					? &{$m->{$_}}($s,$m,local($_)=$v)
					: $m->{$_}))} keys %$m)
			,-name=>$n,-title=>$t,-override=>1,-default=>$v)
	}
 }
 elsif (ref($m) eq 'CODE') {			# Any other...
	$wgp =&$m(@_)
 }
 $wgp
}



sub trURLtxt {	# Translate text with URLs
		# (text, sub{} txt, sub{} url) -> txt || [url]
		# !!! restricted -cgibus special urls translation:
		# _tcb_cmd=	-> _cmd=
		# =-sel		-> =recRead
		# 		-> _form=...
		# id=		-> _key=...
 my($s, $vt, $ct, $cu) =@_;
 my $vr=$ct ? '' : [];
 my $f;
 while ($vt =~/(\[{2}[\w-]{3,7}:\/\/[^\n\r]+?\]{2}|\b[\w-]{3,7}:\/\/[^\s\t,()<>\[\]"']+[^\s\t.,;()<>\[\]"'])/) {
	my($u0,$u,$u1) =($1,$1);
	$vt =$';
	$vr .=&$ct($s,$`) if !ref($vr);
	if ($u =~/^\[{2}(.+?)\]{2}$/) {
		$u =$u0 =$1;
		if ($u =~/(?:\]\[|[|])/) {
			$u =$`; $u1 =$'; $u0 =$u
		}
		$u =$u0 =htmlEscape($s,$u) if $u =~/\s/;
	}
	if ($s->{-cgibus} && ($u =~/^(?:url|urlr):/)) {
		$u =~s/_tcb_cmd=-sel/'_cmd=recRead&_form=' .$s->{-pcmd}->{-form}/ge;
		$u =~s/_tcb_cmd=-lst/'_cmd=recList&_form=' .$s->{-pcmd}->{-table}/ge;
		$u =~s/_tsw_FTEXT=/_qftext=/;
		$u =~s/_tsw_WHERE=/_qwhere=/;
		$u =~s/&id=/&_key=/g;
	}
	if ($u =~/^(?:host|urlh):\/{2,}/) {
		$u ='/' .$'
	}
	elsif ($u =~/^(?:url|urlr):\/{2,}/) {
		$u =$'
	}
	elsif ($u =~/^(?:fsurl|urlf):\/{2,}/) {
		$f =$s->rfdPath(-url=>$s->{-pcmd}, $s->{-pdta})
			||$s->rfdPath(-urf=>$s->{-pcmd}, $s->{-pdta})
			if !$f;
		$u =~s/^(?:fsurl|urlf):\/{2,}/$f .'\/'/e;
	}
	elsif ($u =~/^(?:key|id):\/{2,}/) {
		my $n =$';
		$u ='?_cmd=recRead' .$HS .'_key=' .($n !~/\Q$RISM1\E/ ? ($s->{-pcmd}->{-table} || $s->{-pcmd}->{-form}) .$RISM1 .$n : $n);
		$u1=urlUnescape($s,$n) if !$u1;
	}
	elsif ($u =~/^(?:wikn|name|wiki):\/{2,}/) {
		my $n=$';
		$u ='?_cmd=recRead' .$HS .'_wikn=' .$n;
		$u1=urlUnescape($s,$n) if !$u1;
	}
	if (ref($vr))	{push @$vr, $cu ? &$cu($s,$u,$u1,$u0) : $u}
	else		{$vr .=&$cu($s,$u,$u1,$u0)}
 }
 $vr .=&$ct($s,$vt) if !ref($vr);
 $vr
}


sub trURLhtm {	# Translate text with URLs
		# (text, sub{} txt, sub{} url) -> html || [url]
 my($s, $vt, $ct, $cu) =@_;
 my $vr=$ct ? '' : [];
 my $f;
 while ($vt =~/(\s+(?:href|src)\s*=\s*")([^"]+)/i) {
	my($u0,$u,$u1) =($2,$2);
	$vt =$';
	$vr .=&$ct($s,$` .$1) if !ref($vr);
	if ($s->{-cgibus} && ($u =~/^(?:url|urlr)/)) {
		$u =~s/_tcb_cmd=-sel/'_cmd=recRead&_form=' .$s->{-pcmd}->{-form}/ge;
		$u =~s/_tcb_cmd=-lst/'_cmd=recList&_form=' .$s->{-pcmd}->{-table}/ge;
		$u =~s/_tsw_FTEXT=/_qftext=/;
		$u =~s/_tsw_WHERE=/_qwhere=/;
		$u =~s/&id=/&_key=/g;
	}
	if ($u =~/^(?:host|urlh):\/{2,}/) {
		$u ='/' .$'
	}
	elsif ($u =~/^(?:url|urlr):\/{2,}/) {
		$u =$'
	}
	elsif ($u =~/^(?:fsurl|urlf):\/{2,}/) {
		$f =$s->rfdPath(-url=>$s->{-pcmd}, $s->{-pdta})
			||$s->rfdPath(-urf=>$s->{-pcmd}, $s->{-pdta})
			if !$f;
		$u =~s/^(?:fsurl|urlf):\/{2,}/$f .'\/'/e;
	}
	elsif ($u =~/^(?:key|id):\/{2,}/) {
		$u1=$';
		chop($u1) if $u1 =~/\/$/;
		$u ='?_cmd=recRead' .$HS .'_key=' .($u1 !~/\Q$RISM1\E/ ? ($s->{-pcmd}->{-table} || $s->{-pcmd}->{-form}) .$RISM1 .$u1 : $u1);
	}
	elsif ($u =~/^(?:wikn|name|wiki):\/{2,}/) {
		$u1=$';
		chop($u1) if $u1 =~/\/$/;
		$u ='?_cmd=recRead' .$HS .'_wikn=' .$u1;
	}
	if (ref($vr))	{push @$vr, $cu ? &$cu($s,$u,$u1,$u0) : $u}
	else		{$vr .=&$cu($s,$u,$u1,$u0)}
 }
 $vr .=&$ct($s,$vt) if !ref($vr);
 $vr
}


sub trURLhref {	# Translate URL to hyperlink
		# (url,label,original) -> html
 my $s=$_[0];
 defined($_[2])
 ? ('<a href="' .$_[1] .'" target ="_blank">'
		.htmlEscape($_[0], $_[2])
		.'</a>')
 : ('<a href="' .$_[1] .'" target ="_blank">'
	.htmlEscape($_[0]
		, do {	my $v =
			  $_[1] =~/^\?_cmd=recRead[;&]_form=([^;&]+)[;&]_key=/
			? $1 .'/' .$'
			: $_[1] =~/^\?_cmd=recRead;/
			? $'
			: $_[3] =~/^(?:fsurl|urlf):\/{2,}/
			? $'
			: $_[1];
			$v =~s/;_urm=[^;&]+// if $_[1] =~/^\?/;
			length($v) >49 
			? substr($v,0,47) .'...'
			: $v
			})
	.'</a>')
}


sub htmlFVUT {	# HTML of text field value with URLs embedded
	my $v =$_[3];	# (self, table, record, value)
	$_[0]->rfdStamp($_[1],$_[2])
		if !exists($_[2]->{-file})
		&& ($v =~/\b(?:fsurl|urlf):\/{2,}/);
	$_[0]->trURLtxt($v
		, sub{	my $v =$_[1];
			$v =htmlEscape($_[0], $_[1]);
			$v =~s/( {2,})/'&nbsp;' x length($1)/ge;
			$v =~s/\n/<br \/>\n/g; 
			$v =~s/\r//g;
			$v
			}
		, \&trURLhref);
}


sub htmlFVUH {	# HTML of html field value with URLs embedded
	my $v =$_[3];	# (self, table, record, value)
	$_[0]->rfdStamp($_[1],$_[2])
		if !exists($_[2]->{-file})
		&& ($v =~/\b(?:fsurl|urlf):\/{2,}/);
	$_[0]->trURLhtm($v,sub{$_[1]},sub{$_[1]})
}



sub htmlRFD {	# RFD widget html
 my ($s, $n, $m, $c, $d) =@_;
     $n =$s->{-pcmd}->{-form} if !$n || $n=~/^\d*$/;
     $m =$s->{-form}->{$n}||$s->{-table}->{$n} if !$m;
     $c =$s->{-pcmd} if !$c;
     $d =$s->{-pout} if !$d;
 return('') if !$d->{-file};
 my  $edt=$s->{-pcmd}->{-edit} && $d->{-file} && $d->{-fupd};
 my  $pth=$s->rfdPath(-path=>$d->{-file});
 my  $urf=$s->rfdPath(-urf=>$d->{-file});
 my  $url=$s->rfdPath(-url=>$d->{-file});
 my  $fnu='_file_u';
 my  $fnc='_file_c';
 my  $fnf='_file_f';
 my  $fnl='_file_l';
 my  $fno='_file_o';
 my  $g =$s->cgi();
 my  $r ='';
 if ($edt && $s->cgi->param($fnu)) {	# Upload
	$s->rfaUpload($c, $d, $fnu);
 }
 if ($edt && $urf 			# Close
 &&  $s->cgi->param($fnc)) {
	$s->nfclose($pth, [$s->cgi->param($fnc)])
 }
 if ($edt && $s->cgi->param($fnf)) {	# Delete
	$s->rfaRm($c, $d, [$s->cgi->param($fnl)])
 }

 if ($edt) {				# Edit widget
	my $fo =($s->cgi->param($fno)||$s->cgi->param($fnc))
		&& $s->nfopens($pth,{});
	my $cs =$s->{-c}->{-htmlclass} ? 'Input ' .$s->{-c}->{-htmlclass} : 'Input';
	$r .=$s->cgi->filefield(-name=>$fnu
		,($cs ? (-class=>$cs) : ())
		, -title=>$s->htmlEscape($s->lng(1,'rfauplfld')))
	.$s->cgi->submit(-name=>$fnf
		,($cs ? (-class=>$cs) : ())
		, -value=>$s->lng(0,'rfaupdate')
		, -title=>$s->lng(1,'rfaupdate')
		, -style=>"width: 3em;")
	.(!$fo && $^O eq 'MSWin32'
		? $s->htmlSubmitSpl(-name=>$fno
			,($cs ? (-class=>$cs) : ())
			, -value=>$s->lng(0,'rfaopen')
			, -title=>$s->lng(1,'rfaopen')
			, -style=>"width: 2em;")
		: '')
	.($fo	? $s->cgi->scrolling_list(-name=>$fnc, -override=>1, -multiple=>'true'
			, -title=>$s->lng(1,'rfaopen')
			,($cs ? (-class=>$cs) : ())
			, -values=>	['--- ' .$s->lng(0,'rfaclose') .' ---'
					,ref($fo) eq 'HASH' ? sort keys %$fo : @$fo]
			, ref($fo) eq 'HASH' ? (-labels=>$fo) : ())
		: '');
	if ($urf && $urf =~/^file:(.*)/i) {
		my $fs =$1; $fs =~s/\//\\/g;
		$r .="\n<font style=\"font-size: smaller;\">[ <span "
		# .' onclick="window.event.srcElement.select" '
		# .' oncopy="{window.clipboardData.setData(\'Text\',\'' .$s->htmlEscape($fs) .'\'); return(false)}" '
		# window.event.srcElement
		# document.selection.empty(); 
		.' title="' .$s->htmlEscape($s->lng(1,'rfafolder') .' ') .'">'
		.$g->a({-href=>$urf, -target=>'_blank'}
				, $s->htmlEscape($fs))
		."</span> ]</font><br />\n";
	}
	else {
		$r .="\n&nbsp;&nbsp;&nbsp;\n"
	}
	my $v= eval{join('; ',
		map {	my $f =$_; $f=~s/([%])/uc sprintf("%%%02x",ord($1))/ge;
			'<input type="checkbox" name="' .$fnl .'" value="' 
			.$s->htmlEscape($_) .'" title="' .$s->htmlEscape($s->lng(1,'rfadelm'))
			.'"' .($cs ? ' class="' .$cs .'"' : '') .'/>'
			.'<a href="' .$s->htmlEscape("$url/$f") .'" target="_blank"'
			.' title="' .$s->htmlEscape($_) .'"'
			.($cs ? ' class="' .$cs .'"' : '') .'>'
			.$s->htmlEscape($_) .'</a>'
		} $s->pthGlobns($pth .'/*'))};
	$r .=(defined($v)
		? $v
		: ('<span class="ErrorMessage"><hr class="ErrorMessage" /><b>'
			.$s->htmlEscape($s->lng(0, 'Error')) .':</b> '
			.$s->htmlEscape($@)
			."</b></span>\n"))
 }
 else	{				# View widget
	my $v =eval{join('; ',
		map {	my $f =$_; $f=~s/([%])/uc sprintf("%%%02x",ord($1))/ge;
			$_ eq '.htaccess'
			? ()
			: ($g->a({-href=>"$url/$f",-target=>'_blank'}
				, $s->htmlRFDimg($_,$pth,$url)
				. $s->htmlEscape($_)))
		} $s->pthGlobns($pth .'/*'))};
	$r .=' '
		.(defined($v)
		? $v
		: ('<span class="ErrorMessage"><hr class="ErrorMessage" /><b>'
			.$s->htmlEscape($s->lng(0, 'Error')) .':</b> '
			.$s->htmlEscape($@)
			."</b></span>\n"))
 }
 $r
}


sub htmlRFDimg { # RFD item image HTML
 my ($s,$f,$d,$u) =@_;	# (file, directory, url) -> img tag
 return('') if !$s->{-icons};
 my $p ="$d/$f";
 '<img border=0  align="bottom" height="16"'
.' src="'
.( -d $p
 ? $s->{-icons} .'/' .'dir.gif'
 : 0 && ($f =~/\.(?:gif)$/)
 ? $u .'/' .$f
 : ($s->{-icons} .'/' .(
   (-x $p) || ($f=~/\.(?:bin|com|cpl|exe|sys)$/i)
 ? 'small/binary.gif'
 : $f=~/\.(?:bat|c|class|cpp|cmd|h|phh|mod|pas|pl|pm|py|sh|xml)$/i
 ? 'small/patch.gif' # 'script.gif'
 : $f=~/\.(?:tgz|tar|gz|z|zip|ace|ain|arj|bzip|cab|jar|lzh|pak|rar)$/i
 ? 'small/compressed.gif'
 # documents common
 : $f=~/\.(?:txt)$/i
 ? 'small/text.gif'
 : $f=~/\.(?:html|htm|chm|sgl|sxg|odm)$/i
 ? 'small/doc.gif' # 'layout.gif'
 : $f=~/\.(?:doc|dot|rtf|wri|wps|sdw|sxw|stw|odt|ott|ods|ots)$/i
 ? 'small/doc.gif'
 : $f=~/\.(?:dat|db|dbf|csv|dif|xls|xlw|xlt|wk1|wks|123|ods|ots|sxc|stc|sdc)$/i
 ? 'small/index.gif'
 # documents individual
 : $f=~/\.(?:pdf)$/i
 ? 'small/doc.gif' # 'pdf.gif'
 : $f=~/\.(?:ps)$/i
 ? 'small/ps.gif'
 : $f=~/\.(?:tex)$/i
 ? 'small/doc.gif' # 'tex.gif'
 # graphics, music, movies
 : $f=~/\.(?:vsd|odg|sxg)$/i
 ? 'small/image.gif'
 : $f=~/\.(?:ppt|pps|pot|odp|otp|sxi)$/i
 ? 'small/image2.gif' # 'box1.gif'
 : $f=~/\.(?:bmp|gif|jpg|jpeg|png|tif)$/i
 ? 'small/image2.gif'
 : $f=~/\.(?:mid|midi|wav|mp2|mp3)$/i
 ? 'small/sound2.gif'
 : $f=~/\.(?:avi|mpeg|mpg|wmv)$/i
 ? 'small/movie.gif'
 : 'small/generic.gif'
 ))) .'" />'
}


sub cgiDDLB {	# CGI Drop-down list box
		# ({field}, 'eqp', {data})
 my ($s, $f, $fm, $rd) =@_;
 my $v_=$_;
 my $d =$f->{-ddlb};
 my $mv=$f->{-ddlbmult};
 my $tg=$f->{-ddlbtgt} ||$f->{-fld};
 my $ml=!ref($tg) 
	? defined($tg) && $tg =~/[+,;]/
	: !ref($tg->[0])
	? defined($tg->[0]) && $tg->[0] =~/[+,;]/
	: $tg->[0]->[2];
 my $nf=$f->{-fld};
 my $nl=$nf .'__L';	# List
 my $no=$nf .'__O';	# Open	button
 my $nc=$nf .'__C';	# Close	button
 my $ne=$nf .'__S';	# Set	button
 my $nr=$nf .'__R';	# Reset	button
 my $rf=undef;		# Rows fetched
 my $cs =$s->{-c}->{-htmlclass} ? 'Input ' .$s->{-c}->{-htmlclass} : 'Input';
 my $csc=($cs ? 'class="' .htmlEscape($s, $cs) .'"' : '');

 if	($s->{-pdta}->{$ne}) {		# real assignment in 'cgiParse'
	if ($tg =~/^_(quname)/) {
		$s->{-pcmd}->{$tg} =$s->{-pdta}->{$nl};
	}
	else {
		$s->{-pout}->{$tg} =$s->{-pdta}->{$nl};
	}
 }
 if	($s->{-pdta}->{$ne}  ||$s->{-pcmd}->{$ne} ||$s->{-pdta}->{$nc}) {
	$s->output($s->htmlOnLoad("{window.document.DBIx_Web.${nf}.focus()}"));
 }
 if	(!$s->{-pdta}->{$no}		# open button & exit
	&& ($f->{-ddlbloop} ? !$s->{-pdta}->{$ne} && !$s->{-pdta}->{$nr}: 1)
	) {
	if ($f->{-ddlbmsab} && $s->cgi->user_agent('MSIE')) {
	$s->output("<script language=\"jscript\"></script><script language=\"VBScript\">
	function ${no}O(fldnme)
	Dim Users1
	Dim t
	Dim item
	Dim field
	${no}O =\"\"
	On Error Resume Next
	rem EnsureImport()
	Set field =Document.getElementsByName(fldnme)(0)
	Set t = CreateObject(\"MsSvAbw.AddrBookWrapper\")
	if Err <> 0 then
		Err.Clear
		set t = CreateObject(\"MsoSvAbw.AddrBookWrapper\")
	end if
	if IsObject(t) then
		t.AddressBook \"Microsoft Address Book\", 1, \"\", \"\", \"\", Users1
		if Err = 0 or Err <> 0 then
			For each item in Users1
				if len(field.value) <> 0 then
					field.value =field.value & \", \" & item.SMTPAddress
				else
					field.value =item.SMTPAddress
				end if
			Next
			rem MsgBox(field.value)
			${no}O =\"fldnme\"
		else
			MsgBox(\"Error=\" & Err.Description)
			Err.Clear
		end if
	end if
	End function"
	,"</script><script language=\"jscript\"></script>");
	}
	$s->output($s->htmlSubmitSpl(-name=>$no
	,($cs ? (-class=>$cs) : ())
	, $f->{-ddlbmsab} && $s->cgi->user_agent('MSIE')
		? (-OnClick=>"if(${no}O('$nf')) {return(false)};")
		: ()
	, -value=>$s->lng(0, $f->{-ddlbloop} ? 'ddlbopenl' : 'ddlbopen')
	, -title=>$s->lng(1, $f->{-ddlbloop} ? 'ddlbopenl' : 'ddlbopen')
	, -style=>"width: 2em;"
	));
	return('');
 }
 my $ek =$s->cgi->user_agent('MSIE') ? 'window.event.keyCode' : 'event.which';
 my $fs =sub{
	'{var k;'
	."var l=window.document.DBIx_Web.$nl;"
	."if(l.style.display=='none'){"
	.($_[0] eq '4' ? '' : 'return(true)') .'}else{'
	.(!$_[0]	# onkeypess - input
	? "k=window.document.DBIx_Web.$nf.value +String.fromCharCode($ek);"
	: $_[0] eq '1'	# onkeypess - list -> input (first char)
	? "window.document.DBIx_Web.$nf.focus(); k=window.document.DBIx_Web.$nf.value =String.fromCharCode($ek); "
	: $_[0] eq '2'	# onkeypess - list -> prompt (selected char)
	# ? "k=prompt('Enter search string',String.fromCharCode($ek));"
	? "k =String.fromCharCode($ek); for (var i=0; i <l.length; ++i) {if (l.options.item(i).value.toLowerCase().indexOf(k)==0 || l.options.item(i).text.toLowerCase().indexOf(k)==0){l.selectedIndex =i; break;}}; var q=prompt('Continue search string',''); k=q ? k +q : q; "
	: $_[0] eq '3'	# button - '..'
	? "k=prompt('Enter search substring',''); $nl.focus();"
	: $_[0] eq '4'	# onload - document
	? "k=window.document.DBIx_Web.$nf.value; window.document.DBIx_Web.$nl.focus();"
	: ''
	)
	.'if(k){'
	.'k=k.toLowerCase();'
	.'for (var i=0; i <l.length; ++i) {'
	.($_[0] eq '4'
	? 'if (l.options.item(i).value.toLowerCase() ==k){'
	: $s->cgi->user_agent('MSIE')
	? "if (l.options.item(i).innerText !='' ? l.options.item(i).innerText.toLowerCase().indexOf(k)"
		.($_[0] eq '3' ?'>=' :'==') .'0 : l.options.item(i).value.toLowerCase().indexOf(k)'
		.($_[0] eq '3' ?'>=' :'==') .'0){'
	: "if (l.options.item(i).text !='' ? l.options.item(i).text.toLowerCase().indexOf(k)"
		.($_[0] eq '3' ?'>=' :'==') .'0  : l.options.item(i).value.toLowerCase().indexOf(k)'
		.($_[0] eq '3' ?'>=' :'==') .'0){')
	.'l.selectedIndex =i; break;};}};'
	.($_[0] && ($_[0] ne '4') 
	 ? 'return(false);' 
	 : $_[0] && ($_[0] eq '2')
	 ? 'return(false);'
	 : '')
	.'}}'};
 $s->output('<script for="' .$nf .'" event="onkeypress" >' .&$fs(0) ."</script>")
	if !$ml;
 $s->output($s->cgi->submit(-name=>$nr
		,($cs ? (-class=>$cs) : ())
		, -value=>$s->lng(0,'ddlbreset')
		, -title=>$s->lng(1,'ddlbreset')
		, -style=>"width: 2em;"))
		if $f->{-ddlbloop}
		&& (defined($s->{-pout}->{$nf}) && ($s->{-pout}->{$nf} ne ''));
 $s->output($s->cgi->submit(-name=>$nc
		,($cs ? (-class=>$cs) : ())
		, -value=>$s->lng(0,'ddlbclose')
		, -title=>$s->lng(1,'ddlbclose')
		, -style=>"width: 2em;")
		, "<br />\n");
 my $sl='<select name="' .$nl . '" size="10"'
	." $csc"
	#.' style=>"width: 20em;"'
	.' ondblclick="{' 
		.($ml	
		? ($ne . '.click();') 
		: !ref($tg)
		? ($ne .'.focus();' .$ne .'.click();') 
		: ($ne . ".click(); window.document.DBIx_Web.submit();")) 
		.' return(true)}"'
	.(!$ml	&& $s->cgi->user_agent('MSIE')
		? ' onkeypress="'
		 .($s->cgi->user_agent('MSIE') ? &$fs(1) : &$fs(2)) .'"' 
		: '')
	.'>';
 my $fmt =sub{length($_[0]) >60 ? substr($_[0],0,60) .'...' : $_[0]};

 local $_=$f->{-ddlbloop} && !$s->{-pdta}->{$ne} ? undef : $v_;
 $d =ref($d) eq 'CODE' ? &$d(@_) : $d;

 if	(ref($d) eq 'ARRAY') {
	my $qs =!$ml && ref($rd) && $nf && defined($rd->{$nf}) ? lc($rd->{$nf}) : undef;
	$s->output($sl, "\n");
	$rf =0;
	for(my $i =0; $i <=$#$d; $i++) {
		my $e =$d->[$i];
		next if !defined(ref($e) ? $e->[0] : $e);
		output($s
		,'<option ', $csc
		,(ref($e)
			? ((defined($qs) && ($e->[0] eq $qs)
				? ' selected ' : ())
			,' value="', htmlEscape($s, $e->[0]), '">'
			,htmlEscape($s, &$fmt(join(' - ', @$e))))
			: ((defined($qs) && ($e eq $qs)
				? ' selected ' : ())
			,' value="', htmlEscape($s, $e), '">'
			,htmlEscape($s, &$fmt($e))))
		,"</option>\n");
		$rf +=1
	}
	$s->output("</select>");
 }
 elsif	(ref($d) eq 'HASH') {
	$s->output($sl, "\n");
	use locale;
	$rf =0;
	my $qs =!$ml && ref($rd) && $nf && defined($rd->{$nf}) ? lc($rd->{$nf}) : undef;
	foreach my $e (sort {lc(ref($d->{$a}) ? join(' - ',@{$d->{$a}}) : $d->{$a}) 
			cmp  lc(ref($d->{$b}) ? join(' - ',@{$d->{$b}}) : $d->{$b})}
			keys %$d) {
		output($s
		,'<option ', $csc
		,(defined($qs) && (lc($e) eq $qs) ? ' selected ' : ())
		,' value="', htmlEscape($s, $e), '">'
		,htmlEscape($s, &$fmt(ref($d->{$e}) ? join(' - ', @{$d->{$e}}) : $d->{$e}))
		,"</option>\n");
		$rf +=1
	}
	$s->output("</select>");
 }
 elsif	($d &&
	($s->{-form} && $s->{-form}->{$d} 
	|| eval{$s->mdeTable($d)})) {
	local $s->{-limit} =$s->{-limlb} ||$s->{-limit} || $LIMLB;
	$s->cgiList($d, undef, undef, undef, $sl);
	$rf =$s->{-fetched}
 }
 else {
	local $s->{-limit} =$s->{-limlb} ||$s->{-limit} || $LIMLB;
	$s->cgiList('', {}, {}, $d, $sl);
	$rf =$s->{-fetched}
 }
 if (1 && $f->{-ddlbloop} && defined($_) && ($_ ne '')
 && defined($rf) && !$rf && $s->{-pdta}->{$ne}) {
	$s->output($s->htmlOnLoad("{window.document.DBIx_Web.${nl}.style.display=\"none\"}"));
	return($s)
 }
 $s->output("<br />\n");
 if (ref($tg)) {
	my $n1 =$ne;
	foreach my $b (ref($tg) ? @$tg : $tg) {
		my ($n, $l, $m) =ref($b) ? @$b : ($b,$b,($b||'') =~/[+,;]/);
		   $n =$f->{-fld} if !defined($n);
		   $l =($m ? '<+' : '<') 
			.($s->lnglbl($s->{-pcmd} && $s->{-pcmd}->{-cmdf} && $s->{-pcmd}->{-cmdf}->{-mdefld} && $s->{-pcmd}->{-cmdf}->{-mdefld}->{$n}
				, $s->{-pcmd} && $s->{-pcmd}->{-cmdt} && $s->{-pcmd}->{-cmdt}->{-mdefld} && $s->{-pcmd}->{-cmdt}->{-mdefld}->{$n})
			 || $s->lng(0, $n))
			if !defined($l);
		my $w =($n =~/^[<+-]*(.+)/ ? $1 : $n);
		   $m =', ' if $m && $m =~/^\d*$/;
		$s->output($s->cgi->button(
		  -value=>$l
		,$n1 ? (-name => $n1) : ()
		, -title=>$s->lng(1,'ddlbsubmit')
		,($cs ? (-class=>$cs) : ())
		, -onClick=>"{var fs =window.document.DBIx_Web.$nl; "
			."var ft =window.document.DBIx_Web.$w; "
			."var i  =fs.selectedIndex; i =i <0 ? 0 : i; "
			.($s->cgi->user_agent('MSIE')
			?(!$m	? "ft.value =(fs.options.item(i).value ==\"\" ? fs.options.item(i).text : fs.options.item(i).value);}"
				: "ft.value =(ft.value ==\"\" ? \"\" : (ft.value +\"$m\")) +(fs.options.item(i).value ==\"\" ? fs.options.item(i).text : fs.options.item(i).value);}")
			:(!$m	? "ft.value =fs[i].value;}"
				: "ft.value =(ft.value ==\"\" ? \"\" : (ft.value +\"$m\")) +fs[i].value;}")
			)
		));
		$n1 =undef;
	}
 }
 else {
	$s->output($s->cgi->submit(-name=>$ne
		,($cs ? (-class=>$cs) : ())
		, -value=>$s->lng(0,'ddlbsubmit')
		, -title=>$s->lng(1,'ddlbsubmit')));
 }
 $s->output($s->cgi->button(-value=>$s->lng(0,'ddlbfind')
		,($cs ? (-class=>$cs) : ())
		,-title=>$s->lng(1,'ddlbfind')
		,-onClick=>&$fs(3)
		,-style=>"width: 2em;"
	));
 $s->output($s->cgi->submit(-name=>$nr
		,($cs ? (-class=>$cs) : ())
		, -value=>$s->lng(0,'ddlbreset')
		, -title=>$s->lng(1,'ddlbreset')
		, -style=>"width: 2em;"))
		if $f->{-ddlbloop}
		&& (defined($s->{-pout}->{$nf}) && ($s->{-pout}->{$nf} ne ''));
 $s->output($s->cgi->submit(-name=>$nc
		,($cs ? (-class=>$cs) : ())
		, -value=>$s->lng(0,'ddlbclose')
		, -title=>$s->lng(1,'ddlbclose')
		, -style=>"width: 2em;"),"\n");
 $s->output($s->htmlOnLoad(!$ml ? &$fs(4) : "{window.document.DBIx_Web.${nl}.focus()}"));
}


sub cgiQKey {	# Make Query Key from fields filled
 my ($s, $n, $m, $v) =@_;
     $m =$s->{-form}->{$n}||$s->{-table}->{$n} if !$m;
 my $k ={};
 if	($m->{-query} && $m->{-query}->{-data}) {
	map {$k->{$_} =$v->{$_}
		} grep { defined($v->{$_}) && ($v->{$_} ne '')
			} map {$_->{-fld}
				} grep {ref($_) eq 'HASH'
					} @{$m->{-query}->{-data}}
 }
 elsif	($m->{-field}) {
	map {$k->{$_} =	$v->{$_}
		} grep { defined($v->{$_}) && ($v->{$_} ne '')
			} map {$_->{-fld}
				} grep {ref($_) eq 'HASH' && ($_->{-flg}||'') =~/[aql]/
					} @{$m->{-field}}
 }
 if (!%$k) {
	map {$k->{$_} =$v->{$_}
		} grep { defined($v->{$_}) && ($v->{$_} ne '')
			} keys %{$v};
 }
 foreach my $e (keys %$k) {	# cgiForm/recQBF translation pair
	next	if !$k->{$e}
		|| ($k->{$e} !~/^[\[].+[\]]$/);
	no warnings;
	$k->{$e} =
		eval('sub{' .$k->{$e} .'}')
		&& eval{$s->dsdParse($k->{$e})} 
		|| $k->{$e}
 }
 $k
}


sub cgiQuery {	# Query records
	# -query: rows & columns specs	; display specs
	#	+  resSel defaults		    for	recSel
	#	+ -qkey/key, -qwhere/where		cgiQuery
	#	+ -frmLso				cgiQuery
	#	- -frmLso, -frmLsc			cgiQuery
	#	+ -meta, -field				cgiSel: -data, -display
	#	+ -display	(,-data)		cgiList
	#       - -qhref, -qhrcol, -qfetch, -qfilter	cgiList
 my ($s, $n, $m, $c) =@_;
     $c =$s->{-pcmd}	if !$c;
     $n =$c->{-table} ||$c->{-form} || $s->{-pcmd}->{-table} || $s->{-pcmd}->{-form}
			if !$n;
     $m =$s->{-form}->{$n} ||$s->mdeTable($n) 			# object meta
		if !$m;
 my  $q =$m->{-query};						# query
 my  $t =$m->{-table} && $s->mdeTable($m->{-table}) || $m;	# table  meta
 local $c->{-cmdf} =$m || $t;					# object meta
 local $c->{-cmdt} =$t || $m;					# table  meta
						# Inherit query specs
 $s->cgiQDflt($n, $m, $c);
 local @$q{qw(-meta -field -data -display -order -keyord)} =@$q{qw(-meta -field -data -display -order -keyord)};
 $s->cgiQInherit($q, $m, $t);
						# Form Display Options Default
 if (exists($m->{-frmLso}) && !$m->{-frmLso}
 || ref($m->{-frmLso})) {
 }
 elsif (exists($t->{-frmLso}) 
 &&	!$t->{-frmLso}) {
 }
 elsif (ref($t->{-frmLso})) {
	$m->{-frmLso} =$t->{-frmLso}
 }
 elsif ($s->mdeRAC($m,'-qurole') 
 ||	$t->{-rvcDelState} || $s->{-rvcDelState} ||$t->{-rvcCkoState} ||$s->{-rvcCkoState}) {
	my $oe =($t->{-rvcChgState} ||$s->{-rvcChgState}) && $s->tn('-rvcChgState')->[1] ||'';
	my $oo =($t->{-rvcCkoState} ||$s->{-rvcCkoState}) && $s->tn('-rvcCkoState')->[1] ||'';
	my $od =($t->{-rvcDelState} ||$s->{-rvcDelState}) && $s->tn('-rvcDelState')->[1] ||'';
	my $ov =($t->{-rvcActPtr}   ||$s->{-rvcActPtr})   && 'tvmVersions';
	my $of =$oe && $od;
	my $ob =$t->{-rvcUpdWhen} && (($t->{-dbd} ||$s->{-dbd} ||$s->{-tn}->{-dbd}) eq 'dbi')
		&& (($q->{-order}||'') ne ($t->{-rvcUpdWhen} .' desc'));
	my $ou =[$s->mdeRoles($t)];
	my $oa =!(exists($m->{-frmLsoAdd}) && !$m->{-frmLsoAdd}) && ($m->{-frmLsoAdd}||$t->{-frmLsoAdd});
	my $off=$s->lng(0,'frmLsoff') ||'-------------';
	$m->{-frmLso} =
		[(1 && @$ou 
		?(['-urole'		=>$off]) : ())
		,(grep {$_ ne 'all'} @$ou)
		,(1 && ($oe ||$oo ||$od ||$of ||$ov)
		?(['-todo'		=>$off]) : ())
		,($of ? (['todo'])	:())
		,($oe ? ([$oe])		:())
	#	,($oo ? ([$oo])		:())
		,($of ? (['done'])	:())
		,($od ? ([$od])		:())
		,($ov ? ([$ov])		:())
	#	,['recQBF' =>'...']
		];
	if (ref($oa) eq 'CODE') {
		&{$m->{-frmLsoAdd}||$t->{-frmLsoAdd}}($s, $n, $m, $c, exists($c->{-frmLso}) ? $c->{-frmLso}||'' : ())
	}
	elsif (ref($oa) eq 'ARRAY') {
		push @{$m->{-frmLso}}
			,(substr(ref($oa->[0]) eq 'HASH' ? $oa->[0]->{-val}||$oa->[0]->{-lbl} : $oa->[0]->[0], 0, 1) 
				ne '-'
			? (['-add'	=>$off])
			: ())
			, @$oa
	}
 }
						# Form Display Options Parser
 if ($m->{-frmLso}   ||($t->{-frmLso}   && !exists($m->{-frmLso}))
 ||  $m->{-frmLso0A} ||($t->{-frmLso0A} && !exists($m->{-frmLso0A}))) {
	my $ml =$m->{-frmLso} ||$t->{-frmLso};
	my $oe =($t->{-rvcChgState} ||$s->{-rvcChgState}) && $s->tn('-rvcChgState')->[1] ||'';
	my $oo =($t->{-rvcCkoState} ||$s->{-rvcCkoState}) && $s->tn('-rvcCkoState')->[1] ||'';
	my $od =($t->{-rvcDelState} ||$s->{-rvcDelState}) && $s->tn('-rvcDelState')->[1] ||'';
	my $ov =($t->{-rvcActPtr}   ||$s->{-rvcActPtr})   && 'tvmVersions';
	my $oa =($m->{-frmLsoAdd}||$t->{-frmLsoAdd});
	my $qo =($c->{-qkeyord} ||$q->{-keyord} ||'');
	my $qq =$c->{-qwhere}
		&& (	($c->{-qwhere} =~/^(\[\[.*?\]\])/)
		   ||	($c->{-qwhere} =~/^(\/\*.*?\*\/)/))
		&& $1;
	$c->{-frmLso} =$c->{-qurole}
			if !exists($c->{-frmLso})
			&& !$s->uguest()
			&& $c->{-qurole};
	$c->{-frmLso} ='tvmVersions'
			if !exists($c->{-frmLso})
			&& $ov && $c->{-qversion} && ($c->{-qversion} !~/-/);
	$c->{-frmLso} =''
			if !exists($c->{-frmLso});
	foreach my $lso (ref($c->{-frmLso}) 
			? @{$c->{-frmLso}} 
			: !exists($c->{-frmLso}) || !defined($c->{-frmLso}) 
			? ''
			: $c->{-frmLso}) {
	if ($m->{-frmLso0A}
	&& &{$m->{-frmLso0A}}($s, $n, $m, $c, exists($c->{-frmLso}) ? $lso||'' : ())) {
	}
	elsif ($t->{-frmLso0A} && ($m ne $t)
	&& &{$t->{-frmLso0A}}($s, $n, $t, $c, exists($c->{-frmLso}) ? $lso||'' : ())) {
	}
	elsif ($lso eq '-all') { # elsif (!$lso && exists($c->{-frmLso})) {
		delete $c->{-qurole} if !$c->{-quname};
		delete $c->{-qorder} if $t->{-rvcUpdWhen};
		foreach my $v	(map {$t->{$_} ||$s->{$_} ||$s->tn($_)
				} qw (-rvcChgState -rvcCkoState -rvcDelState -rvcFinState)) {
			if	(!ref($v) || !$c->{-qkey} || !defined($c->{-qkey}->{$v->[0]})) {}
			else	{
				delete $c->{-qkey}->{$v->[0]};
				delete $c->{-qversion};
				delete $c->{-qkeyord};
			}
		}
		delete $c->{-qversion};
		foreach my $e (ref($ml) eq 'ARRAY' 
				? @$ml
				: ref($ml) eq 'CODE'
				? @{&$ml($s, $n, $m, $c, exists($c->{-frmLso}) ? $c->{-frmLso} ||'' : ())}
				: ()) {
			next	if !ref($e);
			my $x =ref($e) eq 'HASH' ? $e->{-cmd} : $e->[2];
			next	if !$x
				|| (ref($x) ne 'HASH');
			delete @{$c}{keys %$x};
			delete @{$c->{-qkey}}{keys %{$x->{-qkeyadd}}}
				if $c->{-qkey} && $x->{-qkeyadd};
		}
	}
	elsif (do{	my $rv =undef;	
			foreach my $e (ref($ml) eq 'ARRAY' 
				? @$ml
				: ref($ml) eq 'CODE'
				? @{&$ml($s, $n, $m, $c, exists($c->{-frmLso}) ? $c->{-frmLso} ||'' : ())}
				: ()) {
				next	if !ref($e)
					|| ($lso ne (ref($e) eq 'HASH' ? $e->{-val} ||$e->{-lbl} : $e->[0]));
				my $x =ref($e) eq 'HASH' ? $e->{-cmd} : $e->[2];
				next	if !$x;
				$rv =$x;
				last
			}
			if (ref($rv) eq 'CODE') {
				&$rv($s, $n, $m, $c, exists($c->{-frmLso}) ? $lso||'' : ())
			}
			elsif (ref($rv) eq 'HASH') {
				@{$c}{keys %$rv} =values %$rv;
				$c->{-qwhere} =$qq .$rv->{-qwhere}
					if $qq && $rv->{-qwhere};
				if ($c->{-qkeyadd}) {
					$c->{-qkey} ={}	if !$c->{-qkey};
					@{$c->{-qkey}}{keys %{$c->{-qkeyadd}}}
							=values %{$c->{-qkeyadd}};
					delete $c->{-qkeyadd}
				}
			}
			$rv
		}) {
	}
	elsif ($lso eq '-urole') {
		delete $c->{-qurole};
		delete $c->{-quname};
	}
	elsif ($s->grep1(sub{$lso eq $_}, $s->mdeRoles(0))) {
		$c->{-qurole}=$lso
	}
	elsif ($lso eq '-todo') {
		foreach my $v	(map {$t->{$_} ||$s->{$_} ||$s->tn($_)
				} qw (-rvcChgState -rvcCkoState -rvcDelState -rvcFinState)) {
			if	(!ref($v) || !$c->{-qkey} || !defined($c->{-qkey}->{$v->[0]})) {}
			else	{
				delete $c->{-qkey}->{$v->[0]};
				delete $c->{-qversion};
				delete $c->{-qkeyord};
			}
		}
		delete $c->{-qversion};
	}
	elsif ($lso eq 'todo') {
		delete $c->{-qversion};
		my $f =$t->{-rvcFinState} ||$s->{-rvcFinState} ||$s->tn('-rvcFinState');
		my $v =ref($f)
			? [$f->[0]
			  ,grep { my $v =$_; !grep {$v eq $_} @$f
				} @{$t->{-rvcAllState} ||$s->{-rvcAllState} ||$s->tn('-rvcAllState') ||[]}]
			: ($t->{-rvcChgState} ||$s->{-rvcChgState} ||$s->tn('-rvcChgState'));
		$c->{-qkey} ={}			if $v && !$c->{-qkey};
		$c->{-qkey}->{$v->[0]} =[@{$v}[1..$#$v]]	if $v;
		$c->{-qkeyord} ='-aeq'	if $qo;
	}
	elsif ($lso eq 'done') {
		delete $c->{-qversion};
		my $v =$t->{-rvcFinState} ||$s->{-rvcFinState} ||$s->tn('-rvcFinState');
		if (!ref($v)) {
			my $f =[@{$t->{-rvcChgState} ||$s->{-rvcChgState} ||$s->tn('-rvcChgState') ||[]}, @{$t->{-rvcDelState} ||$s->{-rvcDelState} ||$s->tn('-rvcDelState') ||[]}];
			$v =[$f->[0]
			    ,grep { my $v =$_; !grep {$v eq $_} @$f
				} @{$t->{-rvcAllState} ||$s->{-rvcAllState} ||$s->tn('-rvcAllState') ||[]}]
		}
		$c->{-qkey} ={}			if $v && !$c->{-qkey};
		$c->{-qkey}->{$v->[0]} =[@{$v}[1..$#$v]]	if $v;
		$c->{-qkeyord} ='-deq'	if $qo;
	}
	elsif ($oe && ($lso eq $oe)) {
		$c->{-qversion} ='+';
		my $v =$t->{-rvcChgState} ||$s->{-rvcChgState} ||$s->tn('-rvcChgState');
		$c->{-qkey} ={}			if $v && !$c->{-qkey};
		$c->{-qkey}->{$v->[0]} =[@{$v}[1..$#$v]]	if $v;
		$c->{-qkeyord} ='-deq'	if $qo;
	}
	elsif ($oo && ($lso eq $oo)) {
		$c->{-qversion} ='+';
		my $v =$t->{-rvcCkoState} ||$s->{-rvcCkoState} ||$s->tn('-rvcCkoState');
		$c->{-qkey} ={}			if $v && !$c->{-qkey};
		$c->{-qkey}->{$v->[0]} =[@{$v}[1..$#$v]]	if $v;
		$c->{-qkeyord} ='-deq'	if $qo;
	}
	elsif ($od && ($lso eq $od)) {
		$c->{-qversion} ='+';
		my $v =$t->{-rvcDelState} ||$s->{-rvcDelState} ||$s->tn('-rvcDelState');
		$c->{-qkey} ={}			if $v && !$c->{-qkey};
		$c->{-qkey}->{$v->[0]} =[@{$v}[1..$#$v]]	if $v;
		$c->{-qkeyord} ='-deq'	if $qo;
	}
	elsif ($ov && ($lso eq $ov)) {
		$c->{-qversion} ='+';
		if ($c->{-qkey}) {
			foreach my $k (qw(-rvcFinState -rvcChgState -rvcCkoState -rvcDelState)) {
				my $v =$t->{$k} ||$s->{$k} ||$s->tn($k);
				delete $c->{-qkey}->{$v->[0]} if $v;
			}
		}
	}
	elsif ($lso eq '-add') {
		foreach my $e (ref($oa) eq 'ARRAY' ? @$oa : ()) {
			next	if !ref($e);
			my $x	=ref($e) eq 'HASH' ? $e->{-cmd} : $e->[2];
			next	if !$x || (ref($x) ne 'HASH');
			delete @{$c}{keys %$x};
			delete @{$c->{-qkey}}{keys %{$x->{-qkeyadd}}}
				if $c->{-qkey} && $x->{-qkeyadd};
		}
		$c->{-qwhere} =$qq		if $qq;
	}}
	$c->{-frmLso} =$c->{-frmLso}->[0]	if ref($c->{-frmLso});
 }

 my  %a =$q ? %$q : ();				# Query Arguments
						# Query Key
 $a{-key} 	={}		if $q->{-key}	||  $c->{-qkey};
 @{$a{-key}}{keys %{$q->{-key}}}	=values %{$q->{-key}}	  if $q->{-key};
 @{$a{-key}}{keys %{$c->{-qkey}}}	=values %{$c->{-qkey}}	  if $c->{-qkey};

						# Query Where
 if	(!$c->{-qwhere})		{}
 elsif	(!$a{-where})			{$a{-where} =$c->{-qwhere}}
 elsif	(ref($a{-where}) eq 'ARRAY')	{push @{$a{-where}}, $c->{-qwhere}}
 elsif	(ref($a{-where}))		{$a{-where} =$c->{-qwhere}}
 else					{$a{-where} ='(' .$a{-where} .') and (' .$c->{-qwhere} .')'}

 $a{-meta}	=$m;                            # Query Other Clauses
 $a{-table}	=$m->{-table} ||$n	if !$a{-table};
 $a{-join2}	=$c->{-qjoin}		if exists($c->{-qjoin}) && $c->{-qwhere};
 $a{-urole}	=$c->{-qurole}		if exists($c->{-qurole});
 $a{-uname}	=$c->{-quname}		if $c->{-quname};
 $a{-ftext}	=$c->{-qftext}		if exists($c->{-qftext});
 $a{-version}	=$c->{-qversion}	if $c->{-qversion};
 $a{-order}	=$c->{-qorder}		if $c->{-qorder};
 $a{-keyord}	=$c->{-qkeyord}		if $c->{-qkeyord};
 $a{-limit}	=$c->{-qlimit}		if $c->{-qlimit};
 $a{-display}	=ref($c->{-qdisplay})
		? $c->{-qdisplay}
		: [split /\s*[,;]\s*/, $c->{-qdisplay}]
					if $c->{-qdisplay};
 $a{-datainc}	=ref($c->{-qdatainc})
		? $c->{-qdatainc}
		: [split /\s*[,;]\s*/, $c->{-qdatainc}]
					if $c->{-qdatainc};

 if (exists($m->{-frmLsc}) ? $m->{-frmLsc} : ($m->{-frmLsc} ||$t->{-frmLsc})) {
	my $lsc =$m->{-frmLsc} ||$t->{-frmLsc};
	my $lsq =$c->{-frmLsc} ||(ref($lsc->[0]) eq 'HASH' ? $lsc->[0]->{-val} : $lsc->[0]->[0]);
	my $e;
	foreach my $v (@$lsc) {
		if ($lsq eq (ref($v) eq 'HASH' ? $v->{-val} : $v->[0])) {
			$e =$v;
			last
		}
	}
	if (!$e && $t->{-mdefld}->{$lsq}) {
		push @$lsc, [$lsq];
		$e =$lsc->[$#$lsc];
	}
	my $x =$e && (ref($e) eq 'HASH' ? $e->{-cmd} : $e->[2]);
	if (ref($x) eq 'CODE') {
		&$x($s, $n, $m, \%a, $lsq);
	}
	elsif ($e) {
		if (!$x) {
			my $v =(ref($e) eq 'HASH' ? $e->{-val} : $e->[0]);
			$a{-display}->[0] =$v	if ref($a{-display});
			push @{$a{-data}}, $v	if ref($a{-data})
						&& !grep {$_ && ($v eq $_)} @{$a{-data}};
			$a{-order} =$v		if !ref($a{-order});
			$a{-order}->[0] =$v	if ref($a{-order});
		}
		else {
			@a{keys %$x} =values %$x;
			if ($x->{-keyadd}) {
				$a{-key} ={}	if !$a{-key};
				@{$a{-key}}{keys %{$x->{-keyadd}}}
						=values %{$x->{-keyadd}};
				delete $a{-keyadd}
			}
		}
		foreach my $k (qw(-qhref -qhrcol)) {
			next if !$a{$k};
			$c->{$k} =$a{$k};
			delete $a{$k}
		}
	}
 }

   $m->{-frmLso0C}
 ? &{$m->{-frmLso0C}}($s, $n, $m, \%a, exists($c->{-frmLso}) ? $c->{-frmLso}||'' : ())
 : $t->{-frmLso0C} && !exists($m->{-frmLso0C})
 ? &{$t->{-frmLso0C}}($s, $n, $t, \%a, exists($c->{-frmLso}) ? $c->{-frmLso}||'' : ())
 : undef;

 $s->cgiSel(\%a);
}


sub cgiSel {	# Select records from database
 my $q =ref($_[1]) ? $_[1] : {@_[1..$#_]};
 local @$q{qw(-meta -field -data -display -order -keyord)} =@$q{qw(-meta -field -data -display -order -keyord)};
 $_[0]->cgiQInherit($q);
 local $q->{-where} =$q->{-where};
	if ($q->{-where} && !ref($q->{-where}) && ($q->{-where} =~/^(?:\[\[|\/\*)/)) {
		my $a ='';
		while (($q->{-where} =~/^\[\[(.*?)\]\]/) ||($q->{-where} =~/^\/\*(.*?)\*\//)) {
			$a =!$1 ? $a : $a ? "$a AND ($1)" : "($1)";
			$q->{-where} =$'
		}
		$q->{-where} =join(' AND ', $a ? ($a) : (), $q->{-where} ? ('(' .$q->{-where} .')') : ())
	}
 $_[0]->recSel($q);
}


sub cgiQueryFv {	# Query field values
			# (self, form ||{cmd} ||false, field ||[fields], ?{query})
 my ($s, $w, $f, $q) =@_;
 return($s->cgiQuery(ref($w) ? $w->{-table} : $w
	,{	 -table=>ref($w) ? $w->{-table} : $w
		,-query=>{-data=>ref($f) ? $f : [$f]
			, -display=>ref($f) ? $f : [$f]
			, -order=>$f
			, -group=>$f
			, -keyord=>'-aall'}
		,-qhref=>{-key=>[ref($f) ? $f->[0] : $f]
			, -form=>ref($w) ? $w->{-table} : $w
			, -cmd=>'recList'}}
	,$q ||{}
	))
}



sub cgiQDflt {	# Default query arguments fulfill
 my($s, $n, $m, $c) =@_;	# (self, name, meta, command)
 $c =$s->{-pcmd} if !$c;
 unless (defined($c->{-qkey}) ||defined($c->{-qwhere}) ||defined($c->{-qurole})) {
	$m =$s->{-form}->{$n ||$c->{-form} ||$c->{-table}} 
			||$s->mdeTable($n ||$c->{-table} ||$c->{-form})
			if !$m;
	my $q =$m->{-query};
	$c->{-qjoin} =	  defined($c->{-qwhere}) && defined($c->{-qjoin})
			? $c->{-qjoin}
			: ($q &&( ref($q->{-qjoin}) eq 'CODE'
			? &{$q->{-qjoin}}($s, $n, $m, $c)
			: $q->{-qjoin}));
	$c->{-qkey}	= defined($c->{-qkey})
			? $c->{-qkey}
			: ref($q->{-qkey}) eq 'CODE'
			? &{$q->{-qkey}}($s, $n, $m, $c)
			: ref($q->{-qkey})
			? {%{$q->{-qkey}}}
			: $q->{-qkey};
	$c->{-qwhere} =	  defined($c->{-qwhere})
			? $c->{-qwhere}
			: ($q &&( ref($q->{-qwhere}) eq 'CODE'
			? &{$q->{-qwhere}}($s, $n, $m, $c)
			: $q->{-qwhere}));
	$c->{-qurole} =	  defined($c->{-qurole}) 
			? $c->{-qurole}
			: $q->{-urole};
	$c->{-quname} =	  defined($c->{-quname})
			? $c->{-quname}
			: $c->{-qurole}
			? $q->{-uname}
			: '';
	$c->{-qftext} =	  defined($c->{-qftext})
			? $c->{-qftext}
			: $q->{-ftext};
	$c->{-frmLso} 	= defined($c->{-frmLso})
			? $c->{-frmLso}
			: ref($q->{-frmLso}) eq 'CODE'
			? &{$q->{-frmLso}}($s,$n,$m,$c)
			: ref($q->{-frmLso})
			? [grep {my $v =$_;
				$s->uguest()
				? !grep /^$v$/, $s->mdeRoles(0)
				: 1
				} @{$q->{-frmLso}}]
			: $s->uguest() && $q->{-frmLso}
				&& do { my $v =$q->{-frmLso};
					grep /\Q$v\E/, $s->mdeRoles(0)}
			? undef
			: $c->{-qurole} && !$s->uguest() && !$c->{-quname}
			? $c->{-qurole}
			: $q->{-frmLso};
	$c->{-frmLsc} 	= defined($c->{-frmLsc})
			? $c->{-frmLsc}
			: ref($q->{-frmLsc}) eq 'CODE'
			? &{$q->{-frmLsc}}($s,$n,$m)
			: ref($q->{-frmLsc})
			? [@{$q->{-frmLsc}}]
			: $q->{-frmLsc};
	foreach my $k (qw(-qjoin -qkey -qwhere -qurole -quname -qftext -frmLso -frmLsc)) {
		delete $c->{$k} if !defined($c->{$k});
	}
 }
 $s
}


sub cgiQInherit { # Inherit cgi query attributes if needed
 my($s, $q, $qm, $tm) =@_;	# (self, query, meta, table meta, table query)
 # use local @$q{qw(-meta -field -data -display -order -keyord)} =@$q{qw(-meta -field -data -display -order -keyord)};
 #  meta - process -query specification - fill inheritance for formulas
 # !meta - process request formed - fill metadata for cgiList
 $tm =	  !$q->{-table}
	? $tm
	: !ref($q->{-table}) && ($q->{-table} =~/^([^\s]+)/)
	? $_[0]->{-form}->{$1} || $_[0]->mdeTable($1)
	: ref($q->{-table}->[0])
	? $_[0]->mdeTable($q->{-table}->[0]->[0])
	: ($q->{-table}->[0] =~/^([^\s]+)/)  && $_[0]->mdeTable($1)
	if !$tm;
 # return(&{$s->{-die}}("cgiQInherit -> no table meta" .$s->{-ermd})) if !$tm;
 $q->{-meta} =
	   (ref($q->{-meta}) && $q->{-meta}) 
	|| ($q->{-meta} && ($_[0]->{-form}->{$q->{-meta}} || $_[0]->mdeTable($q->{-meta})))
	|| $tm
	if !$qm;
 my $qmv =$qm ||$q->{-meta};
 # return(&{$s->{-die}}("cgiQInherit -> no query meta" .$s->{-ermd})) if !$qmv;
 if ($qm) {
	foreach my $n (qw(-data -display -order)) {
		next if !ref($q->{$n});
		$q->{$n} =[@{$q->{$n}}];
	}
 }
 foreach my $m ($q, $qmv, ($qmv ne $tm) ? $tm : ()) {
	next	if !$m;
	if (!$q->{-data}) {
	$q->{-field}=$m->{-field}
		if !$q->{-field};
	$q->{-data} =
		   ($m->{-data} && [@{$m->{-data}}])
		|| ($m->{-query} && $m->{-query}->{-data} && [@{$m->{-query}->{-data}}])
		|| ($m->{-field}
		&& [grep {(ref($_) eq 'HASH')
			&& $_->{-fld}
			&& (	  (($_->{-flg}||'') =~/[akwqlf]/)
				||(!defined($_->{-flg})
					&& (ref($_->{-inp}) ne 'HASH'
					   ? 1 
					   : !(   $_->{-inp}->{-rows}
						||$_->{-inp}->{-arows}
						||$_->{-inp}->{-hrefs}
						||$_->{-inp}->{-rfd}))
						)
					)
			} @{$m->{-field}}])
		if !$q->{-data};
	delete $q->{-data}
		if !$q->{-data}	|| !@{$q->{-data}};
	$q->{-display}=
		   ($m->{-display} && [@{$m->{-display}}])
		|| ($m->{-query} && $m->{-query}->{-display} && [@{$m->{-query}->{-display}}])
		|| ($q->{-data}
			&& [map {  (ref($_) ne 'HASH') 
				|| (($_->{-flg}||'') !~/[al]/i)
				|| !$_->{-fld}
				? ()
				: $_->{-fld}
				} @{$q->{-data}}])
		if !$q->{-display};
	delete $q->{-display}
		if !$q->{-display} || !@{$q->{-display}};
	}
	if (!$q->{-order}) {
		$q->{-order} =
			($m->{-order} && (ref($m->{-order}) ? [@{$m->{-order}}] : $m->{-order}))
			|| ($m->{-query} && $m->{-query}->{-order} && (ref($m->{-query}->{-order}) ? [@{$m->{-query}->{-order}}] : $m->{-query}->{-order}));
		$q->{-keyord} =$m->{-keyord} ||($m->{-query} && $m->{-query}->{-keyord})
			if !$q->{-keyord};
	}
 }
 delete $q->{-meta}	if !$q->{-meta}		|| $qm;
 delete $q->{-field}	if !$q->{-field}	|| !@{$q->{-field}} || $qm;
 delete $q->{-data}	if !$q->{-data}		|| !@{$q->{-data}};
 delete $q->{-display}	if !$q->{-display}	|| !@{$q->{-display}};
 delete $q->{-order}	if !$q->{-order};
 delete $q->{-keyord}	if !$q->{-keyord};
 if ($q->{-data} && ($q->{-display} || $q->{-datainc})) {
	foreach my $e ($q->{-display} ? @{$q->{-display}}: ()
			,$q->{-datainc} ? @{$q->{-datainc}}: ()) {
		my $n =	  !ref($e) ? $e 
			: ref($e) eq 'HASH'	? $e->{-fld}
			: ref($e) eq 'ARRAY'	? $e->[0]
			: undef;
		next	if !$n
			|| (grep {!ref($_)	
				? $_ eq $n
				: ref($_) eq 'HASH'
				? ($_->{-fld}||'') eq $n
				: ref($_) eq 'ARRAY'
				? ($_->[0]||'') eq $n
				: 0
				} @{$q->{-data}});
		push @{$q->{-data}}, $tm && $tm->{-mdefld}->{$e} || $e;
	}
 }
 $q
}



sub htmlMQH {	# Menu Query Hyperlink
 # -label / -html
 # -title, -style, -class, -target; reserved/ignored -tdstyle, -tdclass
 # -qwhere, -qkey, -qurole, -quname, -qorder, -qkeyord
 # -xpar=>0 | 1 | 2 | name | [list]
 # -xkey=>name | [list]
 # -ovw=>sub{}($s, match?, htmlMQH args, query inbound, query formed)
 my $s =$_[0];
 my $a =$#_ ==1 ? $_[1] : {@_[1..$#_]};
 my $qf=	# full inbound query to match required
	$s->{-c}->{-htmbHref}	||do {$s->{-c}->{-htmbHref} =
	{(map {	my $v =$s->{-pcmd}->{$_} ;
		! defined($v) 
		? () 
		: ($_ => $v)
		} qw (-qwhere -qkey -frmLsc -frmLso))
	,(map {	my $v =$s->{-pcmd}->{"-q$_"} 
		|| ($s->{-pcmd}->{-cmdf} && $s->{-pcmd}->{-cmdf}->{-query} && $s->{-pcmd}->{-cmdf}->{-query}->{"-$_"})
		|| ($s->{-pcmd}->{-cmdt} && $s->{-pcmd}->{-cmdt}->{-query} && $s->{-pcmd}->{-cmdt}->{-query}->{"-$_"});
		! defined($v)
		? () 
		: ref($v) eq 'CODE'
		? ("-q$_" => &$v($s, $s->{-pcmd}->{-form}||$s->{-pcmd}->{-table}||'', $s->{-pcmd}->{-cmdf}, $s->{-pcmd}))
		: ("-q$_" => $v)
		} qw (urole uname order keyord))
		}};
 my $qq=	# query reqired
	{map {	($_ =~/^-(?:q|frmLso|frmLsc)/) && defined($a->{$_}) 
			? ($_ => $a->{$_})
			: () 	} keys %$a};
 my $qw=	# writing query joining required
	{ -form => $a->{-form} ||$s->{-pcmd}->{-form}
	, (map {$a->{$_} ? ($_ => $a->{$_}) : ()
		} qw (-cmd -urm))
	, !defined($a->{-xpar}) || ($a->{-xpar} eq '1')	# excluding some
	? (map {$s->{-pcmd}->{$_}
		? ($_ => $s->{-pcmd}->{$_})
		: ()	} qw (-qftext -frmLsc))
	: !$a->{-xpar} || ($a->{-xpar} !~/^\d/)		# excluding list
	? (map {($_ =~/^-(?:q|frmLsc|frmLso)/) && $s->{-pcmd}->{$_}
		? ($_ => $s->{-pcmd}->{$_})
		: () 	} keys %{$s->{-pcmd}})
	: ()};						# excluding all

 if($a->{-xpar} && ($a->{-xpar} !~/^\d/)) {
	delete @$qw{ref($a->{-xpar}) ? @{$a->{-xpar}} : $a->{-xpar}};
 }
 if ($a->{-xkey} && $qw->{-qkey}) {
	$qw->{-qkey} ={%{$qw->{-qkey}}};
	delete @{$qw->{-qkey}}{ref($a->{-xkey}) ? @{$a->{-xkey}} : $a->{-xkey}};
 }
 if (!$qq->{-qwhere} && $qw->{-qwhere}
 && (($qw->{-qwhere} =~/^\[\[(.*?)\]\]/) ||($qw->{-qwhere} =~/^\/\*(.*?)\*\//))
	) {
	$qw->{-qwhere} =$'
 }

 my $ql=800;	# query length limit, was 200
		# MSDN: METHOD Attribute | method Property:
		# the URL cannot be longer than 2048 bytes
 if (length($s->urlCmd('', %$qw)) >$ql) {
	delete $qw->{-qkey};
 }
 if (length($s->urlCmd('', %$qw)) >$ql) {
	delete $qw->{-qwhere};
	delete $qw->{-qjoin};
 }

 my $qm=1;	# query match
 foreach my $k (keys %$qq) {
	next if !defined($qq->{$k});
	my ($vf, $vq) =($qf->{$k}, $qq->{$k});
	if ($qm) {
		$qm =0	if !defined($vf)
			? ( $k eq '-quname'
			  ? !grep /^\Q$vq\E$/i, @{$s->ugnames()}
			  : ($k eq '-frmLso') && defined($qf->{-qurole})
			  ? $vq ne $qf->{-qurole}
			  : 1)
			: $k eq '-qwhere'
			? $vf !~/\Q$vq\E/
			: !ref($vq) && !ref($vf)
			? $vq ne $vf
			: (ref($vq) eq 'ARRAY') || (ref($vf) eq 'ARRAY')
			? (do {	my $v =$s->strdata($vq);
				$s->strdata($vf) !~/^\Q$vq\E/})
			: (ref($vq) eq 'HASH') && (ref($vf) eq 'HASH')
			? (grep {!defined($vf->{$_})
				|| ($s->strdata($vq->{$_}) ne $s->strdata($vf->{$_}))
					} keys %$vq)
			: (ref($vq) xor ref($vf))
			? $s->strdata($vq) ne $s->strdata($vf)
			: $vq ne $vf;
	}
	$qw->{$k} =$k eq '-qkey'
		? ($qw->{$k} && $vq
			? {%{$qw->{$k}}, %$vq}
			: $vq)
		: $k eq '-qwhere'
		? (	 !$vf
			? $vq
			: $vf =~/\Q$vq\E/
			? $vf
			: $vq =~/^(?:\[\[|\/\*)/
			? (do{	$vf =($vf =~/^\[\[(.*?)\]\]/) ||($vf =~/^\/\*(.*?)\*\//)
					? $'
					: $vf;
				$vq .$vf
				})
			: $vq)
		: $vq;
	$qw->{$k} =$vq if length($s->urlCmd('', %$qw)) >$ql;
 }
 $s->{-pcmd}->{-htmlMQH} = $a		if $qm;
 &{$a->{-ovw}}($s,$qm,$a,$qf,$qw)	if $a->{-ovw};
 local $a->{-href}  = $s->urlCmd('', %$qw);
 local $a->{-OnClick}=$s->urlCmd('', %$qw
			, $s->{-pcmd}->{-frame}
			? (-frame=>$s->{-pcmd}->{-frame})
			: ());		# !!! Mozilla no OnLoad target
 local $a->{-target}= '_self'
		if !$a->{-target};
 local $a->{-class} =
	join(' '
		,($s->{-c}->{-htmlclass} ? $s->htmlEscape($s->{-c}->{-htmlclass}) : ())
		,('MenuArea MenuComment')
		,($s->{-uiclass} ? ' ' .$s->{-uiclass} : ())
		,($a->{-class} ? $a->{-class} : ())
		,($qm 
		? 'htmlMQH htmlMQHsel' 
		: 'htmlMQH')
		);
 local $a->{-style} =
	join('; '
		,($s->{-c}->{-htmlstyle} ? $s->htmlEscape($s->{-c}->{-htmlstyle}) : ())
		,($qm && 0
		? 'text-decoration: none; font-weight: bolder; border-style: inset;' 
		: ())
		,($s->{-uistyle} ? ' ' .$s->{-uistyle} : ())
		,($a->{-style} ? $a->{-style} : ())
		);

 $s->cgi->a({(map {$a->{$_} ? ($_ => $a->{$_}) : ()
		} qw (-class -style -target -href -title))
		, $a->{-OnClick}
		? (-OnClick=>"window.document.open('" 
			.$a->{-OnClick} ."','_self','',false); return(false)"
			)
		: ()}
	, defined($a->{-html}) 
	? $a->{-html} 
	: defined($a->{-label}) 
	? '<nobr>' .$s->htmlEscape($a->{-label}) .'</nobr>'
	: ($a->{-html} ||$a->{-label}))
}


sub cgiList {	# List queried records
		# self, ?options, form name, ?metadata, ?command, ?iterator, ?borders
 my ($s, $o, $n, $m, $c, $i, $b) =($_[0], substr($_[1],0,1) eq '-' ? @_[1..$#_] : ('-', @_[1..$#_]));
    $m  =$s->{-form}->{$n}||$s->mdeTable($n)||{} if !$m;
    $c  =$s->{-pcmd}||{} if !$c;
 my $mt =$m->{-table} && $s->mdeTable($m->{-table}) || $m;
 my $mf =$c->{-field} || $m->{-field} || $mt->{-field};
 local $c->{-cmdt} =$mt || $m;	# table  meta
 local $c->{-cmdf} =$m  || $mt;	# object meta
 $i =	  !$i
	? $s->cgiSel(%{$m->{-query}}, -form=>$n)
	: ref($i) eq 'HASH'
	? (!($i->{-form} ||$i->{-table})
		? $s->cgiSel(-form=>$n, %$i)
		: $s->cgiSel($i))
	: ref($i) eq 'ARRAY'
	? eval{my $a =$i; DBIx::Web::ccbHandle->new(sub{shift @$a})}
	: ref($i) eq 'CODE'
	? DBIx::Web::dbmCursor->new($i)
	: $i;
 $i ||return(&{$s->{-die}}('cgiList(' .strdata(@_) .') -> cursor undefined' .$s->{-ermd}));
 my $xml=$c->{-xml};
 my $hcls  ='class="'
 		.($s->{-c}->{-htmlclass} ? $s->htmlEscape($s->{-c}->{-htmlclass}) .' ' : '')
		.(!$b ? 'ListTable' : 'ListList')
		.($s->{-uiclass} ? ' ' .$s->{-uiclass} : '');
 my $hstl  =$hcls
		.'"'
		.($s->{-uistyle} ? ' style="' .$s->{-uistyle} .'"' : '');
 my $disp  =$c->{-qdisplay}	|| ($i && $i->{-query} && $i->{-query}->{-display})
				|| $m->{-qdisplay};
    $disp  =[split /\s*[,;]\s*/, $disp] if !ref($disp) && defined($disp);
 my $href  =$c->{-qhref} ||$m->{-qhref} ||{};
    $href->{-form} =$m->{-table}||$n	if (ref($href) eq 'HASH') && !$href->{-form};
    $href->{-cmd}  ='recRead'		if (ref($href) eq 'HASH') && !$href->{-cmd};

	# -formfld, -key
 my $hrcol =(defined($c->{-qhrcol}) ? $c->{-qhrcol} : $m->{-qhrcol}) || 0;
 my @colf  =();		# col fields: name, number, heading, td, struct
 my $coln  =sub{return($_[1]) if !$i->{NAME};
		my $n =lc(ref($_[0]) ? $_[0]->{-fld} : $_[0]);
		for(my $k =0; $k <=$#{$i->{NAME}}; $k++) {
			return($k) if $n eq lc($i->{NAME}->[$k])};
		$#{$i->{NAME}} +1};
 my $qflgh =($o =~/!.*h/) && ($c->{-qflghtml} || $m->{-qflghtml});
    $qflgh =$c->{-qflghtml} if $c->{-qflghtml};
    $qflgh ="<span $hstl>" .$qflgh .'</span>' if $qflgh && $hstl;
 my $tstrt =undef;
 my $fetch =$c->{-qfetch} || $m->{-qfetch};
 my $limit =$c->{-qlimit} || ($m->{-query} && $m->{-query}->{-limit}) ||$m->{-limit} ||$s->{-limit} ||$LIMRS;
 my $tcf0 ='<script language="Javascript">var DBIxWebListTableTCFv;'
	.'function DBIxWebListTableTCF(tc){'
	#."if(DBIxWebListTableTCFv){var o; o=DBIxWebListTableTCFv; o.className=o.className.replace(' ListTableFocus', ''); o.className=o.className.replace('ListTableFocus', '')};"
	#."tc.className=tc.className +' ' +'ListTableFocus';"
	."if(DBIxWebListTableTCFv){var o; o=DBIxWebListTableTCFv; o.className=''};"
	."tc.className='ListTableFocus';"
	."DBIxWebListTableTCFv=tc;"
	."return(true)}</script>\n";
 my $tcf1 ='onclick="DBIxWebListTableTCF(this)"'; # onfocus=
 $b =	# bondaries:
	# 0<table>  1<tr>  2<td> 3<url>  4</url> 5' '  6'' 7</td> 8</tr> 9</table>
	# 0<table>  1<tr>  2<td> 3<a"    4">     5</a> 6'' 7</td> 8</tr> 9</table>
	# 0<select> 1<opt" 2''   3">     4''     5''   6-  7' '   8</op> 9</select>
	# !$b->[2] == <select>
	  $xml
	? ["\n<table>\n"
		,"<tr>\n", '<td>', '<url>', '</url>', ' ', '', "</td>\n", "</tr>\n", "</table>\n"]
	: !$b
	? ["\n$tcf0<table $hstl >\n"
		, "<tr $tcf1>\n"
		, "<td align=\"left\" valign=\"top\" $hstl>"
		, "<a $hstl href=\"", '">'
		, '</a>', '', "</td>\n", "</tr>\n", "</table>\n"]
	: $b =~/<select/ # !"</select>\n"
	? [$b, '<option ' .($b =~/\b(class\s*=\s*"[^"]+")/i ? "$1 " : '')
		.'value="', '',	'">', '', '', ' - ', '', "</option>\n", "</select>"]
	: ["<span $hstl>", ' ', ' ', " <a $hstl href=\"",'">', '</a> ', '', ' ', "$b\n", "</span>\n"]
	if !ref($b);
 my $fmt =((ref($b) ? $b->[0] : $b) ||'') =~/<select/
	? sub{length($_[0]) >60 ? substr($_[0],0,60) .'...' : $_[0]}
	: undef;

 if (ref($href) eq 'HASH') {
	if	(!$href->{-key}) {		# Hyperlink key
		$href->{-key} =[];
		my $j =0;
		my $k =(ref($m->{-key}) eq 'ARRAY') && $m->{-key};
		foreach my $f (@$mf) {
			next if ref($f) ne 'HASH' ||!$f->{-fld};
			push @{$href->{-key}}, [$f->{-fld} =>&$coln($f,$j)]
				if ($f->{-flg}||'') =~/[k]/	# 'k'ey
				|| ($k
				&&  grep {$f->{-fld} eq $_} @$k);
			$j++
		}
	}
	elsif((ref($href->{-key}) eq 'ARRAY') || !ref($href->{-key})) {
		foreach my $k (ref($href->{-key}) ? @{$href->{-key}} : ($href->{-key})) {
			next if ref($k);
			if ($i->{NAME}) {
				$k =ref($href->{-key}) ? [$k, &$coln($k)] : &$coln($k);
				next
			}
			my $j =0;
			foreach my $f (@$mf) {
				next if ref($f) ne 'HASH' ||!$f->{-fld};
				if ($k eq $f->{-fld}) {
					$k =ref($href->{-key}) ? [$k, $j] : $j;
					last
				}
				$j++
			}
		}
	}
	if	(!$href->{-urm}) {		# Hyperlink unread mark
		$href->{-urm} =[];
		my $j =0;
		my $k =((ref($m->{-urm})  eq 'ARRAY') && $m->{-urm})
		    || ((ref($mt->{-urm}) eq 'ARRAY') && $mt->{-urm})
		    || ((ref($m->{-wkey}) eq 'ARRAY') && $m->{-wkey});
		foreach my $f (@$mf) {
			next if ref($f) ne 'HASH' ||!$f->{-fld};
			push @{$href->{-urm}}, [$f->{-fld} =>&$coln($f,$j)]
				if $k
				? (grep {$f->{-fld} eq $_} @$k)
				: (   ($f->{-flg}||'') =~/[w]/	# 'w'here key
				   && ($f->{-flg}||'') !~/[k]/	# 'k'ey
					);
			$j++
		}
	}
	elsif ((ref($href->{-urm}) eq 'ARRAY') || !ref($href->{-urm})) {
		foreach my $k (ref($href->{-urm}) ? @{$href->{-urm}} : $href->{-urm}) {
			next if ref($k);
			if ($i->{NAME}) {
				$k =ref($href->{-urm}) ? [$k, &$coln($k)] : &$coln($k);
				next
			}
			my $j =0;
			foreach my $f (@$mf) {
				next if ref($f) ne 'HASH' ||!$f->{-fld};
				if ($k eq $f->{-fld}) {
					$k =ref($href->{-urm}) ? [$k, $j] : $j;
					last
				}
				$j++
			}
		}
	}
	if	($href->{-formfld}) {		# Hyperlink form
		my $j =0;
		if ($i->{NAME}) { 
			$j =&$coln($href->{-formfld});
			$href->{-form} =sub{$_[1]->[$j]}
		}
		else {	foreach my $f (@$mf) {
				next if ref($f) ne 'HASH' ||!$f->{-fld};
				if (($f->{-fld}||'') eq $href->{-formfld}) {
					$href->{-form} =sub{$_[1]->[$j]};
					last
				}
				$j++
			}
		}
	}
	elsif	(defined($href->{-formfld})) {
		$href->{-form} =''
	}
	if	(1) {				# Hyperlink sub{}
		my $hr	=$href;
		$href	=sub{
			 '?' .'_cmd='  .urlEscape($_[0]
				, ref($hr->{-cmd})  ne 'CODE' 
				? $hr->{-cmd}  : (&{$hr->{-cmd}}(@_)))
			.$HS .'_form=' .urlEscape($_[0]
				, ref($hr->{-form}) ne 'CODE' 
				? $hr->{-form} : (&{$hr->{-form}}(@_)))
			.$HS .'_key='  .urlEscape($_[0]
				, !ref($hr->{-key})
				? $_[1]->[$hr->{-key}]
				: ref($hr->{-key}) ne 'CODE'
				? strdatah($_[0], map {($_->[0] => $_[1]->[$_->[1]])} @{$hr->{-key}})
				: &{$hr->{-key}}(@_))
			.$HS .'_urm='  .urlEscape($_[0]
				, !ref($hr->{-urm})
				? $_[1]->[$hr->{-urm}]
				: ref($hr->{-urm}) ne 'CODE'
				? join(',',map {$_[1]->[$_->[1]] ? ($_[1]->[$_->[1]]) : ()} @{$hr->{-urm}})
				: &{$hr->{-urm}}(@_))
		};
	}
 }
 $href =sub{''} if !$href;

 if (!@colf)	{				# Display column numbers
	my $j =0;
	foreach my $e ($disp ? @$disp : $i->{NAME} ? @{$i->{NAME}} : @$mf) {
		my $f =undef;
		if ($disp || $i->{NAME}) {
			foreach my $v (@$mf) {
				next	if ref($v) ne 'HASH' 
					||!$v->{-fld}
					||lc($v->{-fld}) ne $e;
				$f =$v;	last
			}
			$f ={-fld=>$e} if !$f
		}
		else {
			next if ref($e) ne 'HASH' ||!$e->{-fld};
			$f =$e
		}
		$j =&$coln($f, $j);
		push @colf	# name, number/-lsthtml, heading/-ldclass, td, struct
		, [$f->{-fld} || ''
		, ref($f->{-lsthtml}) eq 'CODE'
		? do{	my($i, $c) =($j, $f->{-lsthtml});
			sub{local $_=ref($_[4]) ? $_[4]->[$i] : $_[4]; &$c}
			}
		: $f->{-inp} && !$xml && (ref($s->lngslot($f->{-inp}, '-labels')) eq 'HASH')
		? do{	my($i, $c) =($j, $s->lngslot($f->{-inp}, '-labels'));
			$c = {map {$c->{$_} && ($c->{$_} =~/^[_\s]+/)
					? ($_ => $')
					: ($_ => $c->{$_})
					} keys %$c} if $c;
			sub{	local $_=ref($_[4]) ? $_[4]->[$i] : $_[4];
				htmlEscape(undef, defined($c->{$_}) && defined($c->{$_}) ? $c->{$_} : $_)}
			}
		: $j
		, $s->lnglbl($f, '-fld')||''	# heading
		, !$b->[2]	|| $xml		# <td>
				|| (!$f->{-ldclass} && !$f->{-ldstyle} && !$f->{-ldprop})
				|| ($b->[2] !~/^<.*>$/)
		? $b->[2]
		: do {	my $v =$b->[2];		# <td>
			if (ref($f->{-ldclass})) {
				my($i,$cs,$w) =($j, $f->{-ldclass}, $v);
				$v =sub{my $v =ref($w) ? &$w : $w;
					local $_=ref($_[4]) ? $_[4]->[$i] : $_[4];
					$v =~/\sclass\s*=\s*"/
					? $v =~s/\sclass\s*=\s*"([^"]*)"/' class="' .$1 .'; ' .&$cs .'"'/ie
					: $v =~s/^(.+)(>)$/$1 .' class="' .&$cs .'"' .$2/ie;
					$v}
			}
			elsif ($f->{-ldclass}) {
				$v =~/\sclass\s*=\s*"/
				? $v =~s/\sclass\s*=\s*"([^"]*)"/' class="' .$1 .' ' .$f->{-ldclass} .'"'/ie
				: $v =~s/^(.+)(>)$/$1 .' class="' .$f->{-ldclass} .'"' .$2/ie
			}
			if (ref($f->{-ldstyle})) {
				my($i,$cs,$cp,$w) =($j, $f->{-ldstyle}, $f->{-ldprop}, $v);
				$v =sub{my $v =ref($w) ? &$w : $w;
					local $_=ref($_[4]) ? $_[4]->[$i] :$_[4];
					$v =~/\sstyle\s*=\s*"/
					? $v =~s/\sstyle\s*=\s*"([^"]*)"/' style="' .$1 .'; ' .&$cs .'"'/ie
					: $v =~s/^(.+)(>)$/$1 .' style="' .&$cs .'"' .$2/ie;
					$v =~s/^(.+)(>)$/$1 .' ' .(ref($cp) ? &$cp : $cp) .'>'/ie
						if $cp;
					$v}
			}
			elsif ($f->{-ldstyle}) {
				$v =~/\sstyle\s*=\s*"/
				? $v =~s/\sstyle\s*=\s*"([^"]*)"/' style="' .$1 .'; ' .$f->{-ldstyle} .'"'/ie
				: $v =~s/^(.+)(>)$/$1 .' style="' .$f->{-ldstyle} .'"' .$2/ie;
				$v =~s/^(.+)(>)$/$1 .' ' .$f->{-ldprop} .'>'/ie
					if $f->{-ldprop};
			}
			elsif ($f->{-ldprop}) {
				$v =~s/^(.+)(>)$/$1 .' ' .$f->{-ldprop} .'>'/ie
			}
			else {
			}
			$v }
		, $f]
		if $disp || $f->{-lsthtml} || (($f->{-flg}||'') =~/[l]/);
		$j++
	}
	if (!@colf && isa($i, 'HASH'))	{
		@colf	=map {[$i->{NAME}->[$_], $_, $i->{NAME}->[$_]
				, $b->[2]	# <td>
				, {}]} (0..$#{$i->{NAME}});
		foreach my $h (@colf) {
			foreach my $f (@$mf) {
				next	if (ref($f) ne 'HASH')
					|| !$f->{-fld} 
					|| ($f->{-fld} ne $h->[2]);
				$h->[2] =$s->lnglbl($f,'-fld')||''
			}
		}
	}
 }

 $tstrt =sub{					# Table start sub{}
	$s->output($b->[0]);	# <table>
	if ($xml || !@colf || $b->[0] !~/<table/i) {
	}
	elsif ($o !~/!.*h/) {			# Table header
		my $tho;
		if ($m->{-frmLsc}
		|| ($mt->{-frmLsc} && !exists($m->{-frmLsc}))) {
			my $lsc =$m->{-frmLsc} ||$mt->{-frmLsc};
			my $lsf =$mt->{-mdefld} ||{};
			my $hstl1 =$hstl =~/(class=")/ ? $` .$1 .'Input ' .$' : $hstl;
			$tho =[@{$colf[0]}];
			$tho->[2] = sub{
				use locale;
				my $lsq =$_[0]->{-pcmd}->{-frmLsc} 
					||(ref($lsc->[0]) eq 'HASH' 
						? $lsc->[0]->{-val} 
						: $lsc->[0]->[0]);
				'<select name="_frmLsc" '
				.$hstl1
				."onchange=\"{window.document.DBIx_Web._cmd.value='recList'; window.document.DBIx_Web.submit()}\">\n"
				.join('', map {	
					my ($v,$l) =ref($_) eq 'HASH' 
						? ($_->{-val}, $_[0]->lnglbl($_)) 
						: ($_->[0], $_->[1]);
					$l =ucfirst($lsf->{$v}
						&& $_[0]->lnglbl($lsf->{$v})
						|| $_[0]->lng(0,$v))
						if !$l;
					'<option'
					.($v eq $lsq ? ' selected' : '')
					.' ' .$hstl1
					.' value="'
					.$_[0]->htmlEscape($v)
					.'">'
					.$_[0]->htmlEscape($l)
					."</option>\n"} @$lsc)
				."</select>\n"
			}
		}
		elsif ($m->{-frmLso2C}
		|| ($mt->{-frmLso2C} && !exists($m->{-frmLso2C}))) {
			$tho =[@{$colf[0]}];
			$tho->[2] =$m->{-frmLso2C} ||$mt->{-frmLso2C};
		}
		$s->output("<tr>\n"
		, (map {('<th align="left" valign="top" ' .$hcls
			.($_->[4]->{-lhclass} ? ' ' .$_->[4]->{-lhclass} .'"': '"')
			.($_->[4]->{-lhstyle} ? ' style="' .$_->[4]->{-lhstyle} .'"' : '')
			.' title="' .htmlEscape($s, lngcmt($s, $_->[4]) ||$s->lng(1, $_->[0]) ||$_->[2]) .'"'
			.($_->[4]->{-lhprop} ? ' ' .$_->[4]->{-lhprop} : '')
			.'>'
			,ref($_->[2]) 
			? &{$_->[2]}($s, $n, $m, $c)
			: htmlEscape($s, $_->[2])
			,"</th>\n")} $tho ? ($tho, @colf[1..$#colf]) : @colf)
		, "</tr>\n")
	}
	elsif (0 && $b->[0] =~/<table/i) {	# Compatible empty header
		$s->output("<tr>\n"	
		, (map {('<th align="left" valign="top" ' .$hcls
			.($_->[4]->{-lhclass} ? ' ' .$_->[4]->{-lhclass} .'"': '"')
			.($_->[4]->{-lhstyle} ? ' style="' .$_->[4]->{-lhstyle} .'"' : '')
			.($_->[4]->{-lhprop}  ? ' ' .$_->[4]->{-lhprop} : '')
			,"></th>\n")} @colf)
		, "</tr>\n")
	}
 };

 if (ref($fetch) ne 'CODE') {			# Fetch sub{}
	my $ft	=$fetch;
	my $hrc1=$hrcol+1; # $b->[4] || $#colf ? $hrcol+1 : $hrcol;
	my $cargo;
	$fetch  =
	  $xml
	? sub {	my $r;
		while($r =$i->fetch()) {
			last	if !$m->{-qfilter} 
				|| &{$m->{-qfilter}}($s, $n, $m, $c, $i->{-rec})
		}
		return(undef)	if !$r;
		if ($qflgh) {
			$s->output((ref($qflgh) eq 'CODE' ? &$qflgh($s) : $qflgh));
			&$tstrt();
			$qflgh =undef
		}
		my $h =&$href($s, $r);
		output($s, ''
		, xmlsTag($s, 'tr', 'href'=>$s->url .'/' .$h, '0')
		, "\n"
		, (map {	ref($_->[1])
				? ('<', $_->[0], '>'
				, &{$_->[1]}($s, $cargo, undef, $i, $r)
				, '</', $_->[0], ">\n")
				: xmlsTag($s, $_->[0]
				, ''=>	  ref($_->[1])
					? &{$_->[1]}($s, $cargo, undef, $i, $r)
					: ref($r)
					? $r->[$_->[1]]
					: $r
				, "\n")
			} @colf)
		,$b->[8])					# </tr>
		}
	: $fmt
	? sub {	my $r;
		while($r =$i->fetch()) {
			last	if !$m->{-qfilter} 
				|| &{$m->{-qfilter}}($s, $n, $m, $c, $i->{-rec})
		}
		return(undef)	if !$r;
		if ($qflgh) {
			$s->output((ref($qflgh) eq 'CODE' ? &$qflgh($s) : $qflgh));
			&$tstrt();
			$qflgh =undef
		}
		my $h =&$href($s, $r);
		output($s, $b->[1]				# <option value="
		, (map {(	  (ref($_->[3]) ? &{$_->[3]}($s, $cargo, $h, $i, $r) : $_->[3])
					||htmlEscape($s, ref($r) ? $r->[$_->[1]] : $r)
				, $b->[3]			# ">
				)} @colf[0..$hrcol])
		, &$fmt(join($b->[6]				# ' - '
			,map {(
			( ref($_->[3])
			? &{$_->[3]}($s, $cargo, undef, $i, $r)
			: $_->[3])
			.(ref($_->[1])
			? &{$_->[1]}($s, $cargo, undef, $i, $r)
			: htmlEscape($s, ref($r) ? $r->[$_->[1]] : $r))
			)} @colf[0..$#colf]))
		,$b->[8])					# </option>
		}
	: sub {	my $r;
		while($r =$i->fetch()) {
			last	if !$m->{-qfilter} 
				|| &{$m->{-qfilter}}($s, $n, $m, $c, $i->{-rec})
		}
		return(undef)	if !$r;
		if ($qflgh) {
			$s->output((ref($qflgh) eq 'CODE' ? &$qflgh($s) : $qflgh));
			&$tstrt();
			$qflgh =undef
		}
		my $h =&$href($s, $r);
		output($s, $b->[1]				# <tr>||<opt"
		, (map {(	  (ref($_->[3]) ? &{$_->[3]}($s, $cargo, $h, $i, $r) : $_->[3])
					||htmlEscBlnk($s, ref($r) ? $r->[$_->[1]] : $r)
				, $b->[3]			# <a" || ">
				, $b->[4] && $h, $b->[4]	# ">  || ''
				, ref($_->[1])
				? &{$_->[1]}($s, $cargo, $h, $i, $r)
				: htmlEscBlnk($s, ref($r) ? $r->[$_->[1]] : $r)
				, $b->[5], $b->[7]		# </a></td>||'_
				)} @colf[0..$hrcol])
		, (map {($b->[6]				# '' || ' - '
			,  ref($_->[3])
			? &{$_->[3]}($s, $cargo, undef, $i, $r)
			: $_->[3]  # $b->[2]
			, ref($_->[1])
			? &{$_->[1]}($s, $cargo, undef, $i, $r)
			: htmlEscBlnk($s, ref($r) ? $r->[$_->[1]] : $r)
			, $b->[7]				# </td>
			)} @colf[$hrc1..$#colf])
		,$b->[8])					# </tr>
		};
 }

 &$tstrt() if !$qflgh;				# Table start

 my $j =0;
 while (&$fetch($s, $i, $b)) {			# Fetch data
	$j++;
	last if $j >$limit;
 }
 $s->{-fetched} =$j;
 $s->{-limited} =$limit;
 eval {$i->finish};

 $s->output($b->[9]) if !$qflgh;		# Table end
}


sub cgiLst {	# Simplified 'cgiList' to embed into 'cgiForm'
 my $s =shift;	# (?options, view, ? query)
 my $o =$_[0] =~/^-/ ? shift : '-!h';
 my ($f, $q) =@_;
 return($s->cgiList($o, $f, undef, {}
		,$s->cgiQuery($f, undef, {}))
	) if !$q;
 $q ={%$q};
 foreach my $k (qw(urole uname)) {
	$q->{"-q$k"} =$q->{"-$k"} if exists($q->{"-$k"}) && !exists($q->{"-q$k"})
 }
 foreach my $k (qw(key where ftext version order keyord limit display datainc)) {
	$q->{"-q$k"} =$q->{"-$k"} if $q->{"-$k"} && !$q->{"-q$k"}
 }
 $s->cgiList($o, $f, undef, $q ||{}
		,$s->cgiQuery($f, undef, $q))
}


sub cgiHelp {	# Print CGI Help screen form
		# self, form name, form meta, command, data
 my ($s, $n, $m, $c, $d) =@_;
    $m =$s->{-form}->{$n}||eval{$s->mdeTable($n)} if !$m;
    $c =$s->{-pcmd} if !$c;
    $d =$s->{-pout} if !$d;
 my $mt=ref($m) && $m->{-table} ? eval{$s->mdeTable($m->{-table})} : $m;
 my $cs  =join(' '
		,$s->{-c}->{-htmlclass} ? $s->htmlEscape($s->{-c}->{-htmlclass}) : ()
		,$s->{-uiclass} ? $s->{-uiclass} : ());
 my $cs1 =$cs ? 'class="' .$cs .'"' : '';
 my $cs2 =$cs ? 'class="' .$cs .'"' : '';
 my $th1 ="<th align=\"left\" valign=\"top\" style=\"text-decoration: underline\" nowrap=true $cs1>";
 my $td1 ="<td align=\"left\" valign=\"top\" $cs2>";
 my $th2 ="<th align=\"left\" valign=\"top\" $cs2>";
 my $td2 ="<td align=\"left\" valign=\"top\" $cs2>";
 my $th3 =$th2;
 my $td3 =$td2;
 my $cfs ='<div style="margin-left: 3em;"><code>';
 my $cfe ='</code></div>';
 my ($th, @td);

 my $hl  =$LNG->{$s->{-lng}} || $LNG->{''};
 my $cl  =sub{	my $t =$_[0];
		my ($c, $v);
		$c =$t;
		$v =$c && $hl->{$c} && $hl->{$c}->[0];
		return($v) if $v;
		$c =substr($t,0,1) eq '-' ? substr($t,1) : $t;
		$v =$c && $hl->{$c} && $hl->{$c}->[0];
		return($v) if $v;
		$t #ucfirst($c)
		};
 my $cv  =sub{	my $v =$_[0];
		  !defined($v)
		? 'undef'
		: $v eq ''
		? $s->dsdQuot($v)
		: ref($v) eq 'CODE'
		? 'CODE()'
		: ref($v)
		? $s->dsdQuot($v)
		: $v};
 my $cf;
    $cf  =sub{	# (meta, name)
		return(join(', ', map {&$cf($_[0],$_,$#_ >1 ? @_[2..$#_] : ())
					} @{$_[1]})
			) if ref($_[1]) eq 'ARRAY';
		my $f =!$_[1]
			? undef
			: (($_[0]->{-mdefld} && $_[0]->{-mdefld}->{$_[1]})
				|| ($mt && $mt->{-mdefld} && $mt->{-mdefld}->{$_[1]}));
		$_[2] && $f
		? $s->htmlEscape($s->lngcmt($f) ||$s->lng(1,$_[1]))
		: $_[2]
		? ''
		: $f 
		? '<span title="' 
		 .$s->htmlEscape($s->lngcmt($f) ||$s->lng(1,$_[1]))
		 .'">'
		 .$s->htmlEscape($s->strquot($s->lnglbl($f) ||$s->lng(0,$_[1])))
		 .'</span>'
		: (wantarray() ? () : $s->htmlEscape($s->strquot($_[1])))
		};
 my $hff={	 'a'	=>"all"
		,'k'	=>"key"
		,'w'	=>"wkey"
		,'e'	=>"edit"
		,'u'	=>"update"
		,'m'	=>"mandatory"
		,'h'	=>"hyperlik"
		,'q'	=>"query"
		,'l'	=>"list"
		,'f'	=>"fetch"
		,'n'	=>"numeric"
		,'9'	=>"numeric"
		,'"'	=>"string"
		};
 my $cff=sub{	return('') if !$_[0];
		join(', '
			, map {	$hff->{$_} ? $hff->{$_} : $_
				} split / */, $_[0])
		};
 my $ce =sub{	my $v =$s->htmlEscape(@_);
		$v =~s/[\r\n]+/<br \/>/g;
		$v
		};
 my $ch =sub{	my $v =ref($_[0]) ? &{$_[0]}($s) : $_[0];
		return $v if ($s->ishtml($v));
		&$ce($v)
		};
 my ($om, $on);

 $s->output("\n<table $cs2>\n");
 if ($s->lngslot($s,'-help')) {
	$s->output("<tr>"
		,$th1
		,''
		,'</th>', $td1
		,&$ch($s->lngslot($s,'-help'))
		,"<hr /></td></tr>\n"
		);
 }
 if (1) {
	$s->htmlMChs() if !$s->{-menuchs};
	if ($s->{-menuchs}) {
		$s->output(
		"<tr>", $th1, '','</th>'
		, $td1
		, join(',&nbsp;'
			, map {
				my ($on, $ol, $ot) =ref($_) eq 'ARRAY' ? (@$_) : ($_);
				$on =$' if $on =~/[.^&+]+$/;
				my $o =$s->{-form}->{$on} ||$s->{-table}->{$on};
				if ($o && !$ol) {
					$ol=$_[0]->lngslot($o,'-lbl') if $o;
					$ol=&$ol($_[0]) if ref($ol);
					$ol =$ol ||$on;
				}
				if ($o) {
					$ot=$_[0]->lngslot($o,'-cmt');
					$ot=&$ot($_[0]) if ref($ot);
					$ot =$ot ||$on;
				}
				$ol
				? '<nobr><a href="'
					.$s->urlCmd('',-form=>$on
						, -cmd=>'frmHelp'
						, $c && $c->{-backc} ? (-backc => $c->{-backc}, -urm=>time()) : ())
					."\" class=\"$cs\""
					.($on eq $n 
					? ' style="font-weight: bolder;"'
					: '"')
					.' title="' .$s->htmlEscape($ot)
					.'">'
					.$s->htmlEscape($ol)
					.'</a></nobr>'
				: ()
				} @{$s->{-menuchs}})
		, "<hr /></td></tr>\n"
		);
	}
 }

 foreach my $oc ('f','t') {
	if ($oc eq 'f') {
		$on =$n;
		$om =$s->{-form}->{$n};
	}
	elsif ($oc eq 't') {
		$om =$s->{-form}->{$n};
		$om =!$om ? eval{$s->mdeTable($on =$n)} : $om->{-table} ? eval{$s->mdeTable($on =$om->{-table})} : eval{$s->mdeTable($on =$n)};
	}
	next if !$om;
	$s->output("<tr>"
		,$th1, "<br />"
		,$s->htmlEscape($s->lnglbl($om)||'')
		,'</th>'
		,$td1, "<br />"
		,&$ce($s->lngcmt($om)||'')
		,"</td></tr>\n"
		);
	$s->output("<tr>"
		,$th2
		,'</th>'
		,$td2
		,&$ch($s->lngslot($om,'-help')||'')
		,"</td></tr>\n"
		) if $s->lngslot($om,'-help');
	$th =join(' ', $on ? $on : ());
	$th =join('; '
		, $th ? $th : ()
		, map { !exists($om->{$_}) && !exists($s->{$_})
			? ()
			: $s->htmlEscape($_
				.'=> ' 
				.&$cv(exists($om->{$_}) 
					? $om->{$_} 
					: $s->{$_}))
			} ($om->{-table} && !ref($om->{-table}) ? qw(-table) : ())
			, qw(-expr -null)
			, (grep {/^-(?:cgc|cgv|subst|redirect)/
			} sort keys %$om));
	$s->output("<tr>",$th2,'</th>',$td2,$cfs,$th,"$cfe</td></tr>\n")
		if $th;

	($th, @td) =($s->htmlEscape(&$cl('-key')));
	foreach my $k (   qw(-key)
			, $oc eq 't' ? qw(-wikn) : ()
			, qw(-wkey)
			, $oc eq 't' ? qw(-ridRef) : ()) {
		next	if !exists($om->{$k}) && !exists($s->{$k});
		my $td =&$cf($om, $om->{$k} ||$s->{$k});
		$td .=($hl->{$k} && $hl->{$k}->[1]
			 ? ' - ' .$s->htmlEscape($hl->{$k}->[1])
			 : '')	if $td;
		push @td, $td	if $td;
	}
	$s->output("<tr>",$td1,$th,'</td>',$td2,join("</td></tr>\n<tr>$td1</td>$td2", @td),"</td></tr>\n")
		if @td;

	($th, @td) =($s->htmlEscape(&$cl('-rvcActPtr')));
	foreach my $k (	$oc eq 't' && ($om->{-rvcActPtr} ||$s->{-rvcActPtr})
			? qw(-rvcChgState -rvcCkoState -rvcDelState)
			: ()) {
		next	if !exists($om->{$k}) && !exists($s->{$k});
		my $td =$om->{$k}->[0] && &$cf($om,$om->{$k}->[0]);
		next	if !$td;
		my $f =($om->{-mdefld} && $om->{-mdefld}->{$om->{$k}->[0]})
			|| ($mt->{-mdefld} && $mt->{-mdefld}->{$om->{$k}->[0]});
		my $l =$s->lngslot($f->{-inp},'-labels') ||$f->{-inp}->{-labels}
			if $f && $f->{-inp};
		   $l =undef
			if ref($l) ne 'HASH';
		$f = ref($f->{-inp}->{-values}) eq 'ARRAY'
			? {map {($_=>$l && $l->{$_} ||$s->lng(0,$_) ||$_)
				} @{$f->{-inp}->{-values}}}
			: $l
			if $f && $f->{-inp};
		my $v =join(', '
		, map{	  !$f
			? $s->strquot($s->lng(0,$_)||$_)
			: $f->{$_}
			? $s->strquot($f->{$_})
			: ()
			} @{$om->{$k}}[1..$#{$om->{$k}}]);
		$td =$v ? $td .' = ' .$v : '';
		next	if !$td;
		$td .=($hl->{$k} && $hl->{$k}->[1]
			 ? ' - ' .$s->htmlEscape($hl->{$k}->[1])
			 : '');
		push @td, $td	if $td;
	}
	{	my $k ='-rvcActPtr';
		my $v =&$cf($om, $om->{$k} ||$s->{$k});
		$v .=$hl->{$k} && $hl->{$k}->[1]
			? ' - ' .$s->htmlEscape($hl->{$k}->[1])
			: ''	if $v;
		unshift @td, $v	if $v && @td;
	}
	$s->output("<tr>",$td1,$th,'</td>',$td2,join("</td></tr>\n<tr>$td1</td>$td2", @td),"</td></tr>\n")
		if @td;

	($th, @td) =($s->htmlEscape(&$cl('-racUser')));
	foreach my $k ( $oc eq 't'
			?($s->{-rac} ? qw(-racWriter -racReader) : ()
			, qw(-racActor -racManager -racPrincipal -racUser))
			: ()) {
		next	if !exists($om->{$k}) && !exists($s->{$k});
		my $td =&$cf($om, $om->{$k} ||$s->{$k});
		$td .=($hl->{$k} && $hl->{$k}->[1]
			 ? ' - ' .$s->htmlEscape($hl->{$k}->[1])
			 : '')	if $td;
		push @td, $td	if $td;
	}
	$s->output("<tr>",$td1,$th,'</td>',$td2,join("</td></tr>\n<tr>$td1</td>$td2", @td),"</td></tr>\n")
		if @td;

	($th, @td) =($s->htmlEscape(&$cl('-query')));	# no -frmLso -frmLsoAdd
	foreach my $k (qw(-query)
			) {
		next	if !exists($om->{$k}) && !exists($s->{$k});
		my $td =$cfs
			.$s->htmlEscape(&$cv(exists($om->{$k}) ? $om->{$k} : $s->{$k}))
			.$cfe;
		push @td, $s->lng(1,$k) .':', $td	if $td;
		my @td1 =map {$_ eq 'all'
				? ()
				: $s->htmlEscape($s->strquot($s->lng(0,$_))
					# .($s->lng(1,$_) ? ' - ' .$s->lng(1,$_) : '')
					)
				} $s->mdeRoles($mt)
				if $td;
		push @td, &$cl('-frmLso')
			. ': ' .join(', ', @td1)
			if @td && @td1
	}
	$s->output("<tr>",$td1,$th,'</td>',$td2,join("</td></tr>\n<tr>$td1</td>$td2", @td),"</td></tr>\n")
		if @td;

	($th, @td) =($s->htmlEscape(&$cl('-frmLsc')));
	foreach my $k (qw(-frmLsc)
			) {
		next	if !exists($om->{$k}) && !exists($s->{$k});
		my $td =join('<br />'
			, map {	my ($e, $el, $ec) =$_;
				if (ref($e) eq 'HASH') {
					$el =$s->htmlEscape($s->lngslot($e,'-lbl'))
						|| $e->{-val}
						&& &$cf($om,$e->{-val});
					$ec =$s->htmlEscape($s->lngslot($e,'-cmt'))
						|| $e->{-val}
						&& &$cf($om,$e->{-val},1);
				}
				elsif (ref($e) eq 'ARRAY') {
					$el =$s->htmlEscape($e->[1]) ||&$cf($om,$e->[0]);
					$ec =&$cf($om,$e->[0],1);
				}
				  $el && $ec ? $el .' - ' .$ec
				: $el ? $el
				: ()
				} @{$om->{$k}});
		push @td, $td	if $td;
	}
	$s->output("<tr>",$td1,$th,'</td>',$td2,join("</td></tr>\n<tr>$td1</td>$td2", @td),"</td></tr>\n")
		if @td;

	if ($om->{-field} && (ref($om->{-field}) eq 'ARRAY')) {
		foreach my $f (@{$om->{-field}}) {
			next if ref($f) ne 'HASH';
			$s->output("<tr>"
				,$th2
				,$s->htmlEscape($s->lnglbl($f) ||($f->{-fld} && $s->lng(0,$f->{-fld})) ||'')
				,'</th>'
				,$td2
				,&$ce($s->lngcmt($f) ||($f->{-fld} && $s->lng(1,$f->{-fld})) ||'')
				,"</td></tr>\n"
				);
			$s->output("<tr>"
				,$th2
				,'</th>'
				,$td2
				,&$ce($s->lngslot($f,'-help')||'')
				,"</td></tr>\n"
				) if $s->lngslot($f,'-help');
			$th =join(' '
				, $f->{-fld} ? $s->htmlEscape(&$cv($f->{-fld})) : ()
				, $f->{-flg} ? $s->htmlEscape("(" .&$cff($f->{-flg}) .")") : ()
				);
			$th =join('; '
				, $th ? $th : ()
				, map { !exists($f->{$_})
					? ()
					: $s->htmlEscape($_ .'=> ' .&$cv($f->{$_}))
					} qw(-expr -null -edit -hide -hidel -inp -ddlb -ddlbmult -ddlbtgt)
				);
			$s->output("<tr>",$th2,'</th>',$td2,$cfs,$th,"$cfe</td></tr>\n")
				if $th;
			$s->output("<tr>"
				,$th2
				,'</th>'
				,$td2
				,$s->htmlEscape($s->lng(1,'-htmlopt'))
				,"</td></tr>\n"
				) if $f->{-inp} && $f->{-inp}->{-htmlopt};
			$s->output("<tr>"
				,$th2
				,'</th>'
				,$td2
				,$s->htmlEscape($s->lng(1,'-hrefs'))
				,"</td></tr>\n"
				) if $f->{-inp} && $f->{-inp}->{-hrefs};
			$s->output(map {
				("<tr>"
				,$td2
				,'<nobr>', '&nbsp;' x 3, $s->htmlEscape($_->[0]), '</nobr>'
				,'</td>'
				,$td2
				,$s->htmlEscape($_->[1])
				,"</td></tr>\n")} @{$s->lng(2,'-hrefs')}
				) if $f->{-inp} && $f->{-inp}->{-hrefs};
		}
	}
 }
 if ($om) {
	 $s->output("<tr>"
		,$th1, "<br /><br />"
		,$s->htmlEscape($s->lng(0,'recQBF')||'')
		,'</th>'
		,$td1, "<hr /><br />"
		,&$ce($s->lng(1,'recQBF')||'')
		,"</td></tr>\n"
		);
	my $de =$s->{-table}->{$m->{-table}||$n};
	   $de =($de && $de->{-dbd})||$s->{-tn}->{-dbd};
	foreach my $k (qw(frmLso -qkeyord)
			,$de eq 'dbi' ? qw(-qjoin) : ()
			,qw(-qwhere)
			,$s->mdeRAC($m) ? qw(-qurole -quname) : ()
			,qw(-qftext -qversion -qorder -qlimit -qdisplay -qurl)) {
		 $s->output("<tr>"
			,$th2
			,$s->htmlEscape($s->lng(0,$k)||'')
			,'</th>'
			,$td1
			,&$ce($s->lng(1,$k)||'')
			,"</td></tr>\n"
			);
		 $s->output("<tr>"
			,$td1
			,''
			,'</td>'
			,$td1
			,$s->htmlEscape($s->lng(0, "-qwhere$de")||'')
			,': '
			,$s->htmlEscape($s->lng(1, "-qwhere$de")||'')
			,"</td></tr>\n"
			) if ($k eq '-qwhere') && $s->lng(0, "-qwhere$de");
		 $s->output(map {"<tr>"
			,$td1
			,'<nobr>', '&nbsp;' x 3, $s->htmlEscape($_->[0]), '</nobr>'
			,'</td>'
			,$td1
			,$s->htmlEscape($_->[1])
			,"</td></tr>\n"} @{$s->lng(2, "-qwhere$de")}
			) if 1 && ($k eq '-qwhere') && ref($s->lng(2, "-qwhere$de"));
	}
 }	
 $s->output("\n</table>\n");
 $s
}


sub cgiFooter {	# Footer of CGI screen
 my ($s) =@_;
 my $cs  =($s->{-c}->{-htmlclass} ? $s->htmlEscape($s->{-c}->{-htmlclass}) .' ' : '')
		.'FooterArea';
 return(undef) if $s->{-pcmd}->{-xml} ||$s->{-pcmd}->{-print};
 if ($s->{-cgi} && $s->{-cgi}->{'.cgi_error'}
 && (($s->{-c}->{'.cgi_error'} ||'') ne $s->{-cgi}->{'.cgi_error'})) {
	$_[0]->logRec('error','CGI', $s->{-cgi}->{'.cgi_error'})
 }

 $s->output("\n"
	,'<span class="', $cs, '" onclick="{var e=document.getElementById(\'_FooterArea\'); e.style.display=(e.style.display==\'none\' ? \'inline\' : \'none\')}"'
		.(($ENV{HTTP_USER_AGENT}||'') =~/MSIE/ 
			? ' style="cursor: hand;"'
			: (' title="' .$s->htmlEscape($s->lng(0,'ddlbopen')) .'"'))
		.'>'
	,'<hr class="', $cs, '" />'
	,"\n"
	,($s->cgiHook('recList') && defined($s->{-fetched})
	? ('<b>',$s->{-limited} && ($s->{-limited} <=$s->{-fetched})
		?($s->{-limited}, ' / ?')
		:($s->{-fetched}||0)
		,' ', $s->lng(1, '-fetched'),"</b><br />\n")
	: defined($s->{-affected})
	? ('<b>',$s->{-affected}||0, ' ', $s->lng(1, '-affected'),"</b><br />\n")
	: ())
	,"</span>\n"
	,'<span id="_FooterArea" class="', $cs ,'" style="display: ' .($s->{-debug} && $s->{-debug} >1 ? 'inline' : 'none') .'; font-size: smaller; ">'
	,"<br />\n"
	,$s->{-c}->{-logm} && $s->{-debug}
	? join(";<br /><br />\n",
		map {	  !defined($_)
			? ()
			: $_ =~/^([()\s\d\.,]*(?:WARN|WARNING|DIE|ERROR)[:.,\s]+)(.*)$/i
			? '<strong class="FooterArea ErrorMessage">' .htmlEscape($s, $1) .'</strong>' .htmlEscape($s, $2)
			: htmlEscape($s, $_)
			} @{$s->{-c}->{-logm}}
		)
	: ()
	,(0 && ($s->user() =~/diags/i) ? ("<br />\n" x 2, $s->diags('-html,all')) : '')
	,"</span>\n");
}


#########################################################
# Templates or Default Data Definitions
#########################################################


sub tn {	# Template Naming
		# (self, metaname) -> name
   (($#_ <1) && $_[0]->{-tn})
|| ($_[0]->{-tn}->{$_[1]})
|| (substr($_[1],0,1) eq '-' ? substr($_[1],1) : $_[1])
}


sub tfoShow {	# Template Field Option '-lblhtml' to Show all details absent
		# (self, ? input name, ? [detail fields], ? html pattern)
 my ($s, $n, $d, $h) =@_;
 sub{	my $x =!$h ? '$_' : ref($h) eq 'CODE' ? &$h(@_) : $h;
	   $_[3]
	|| $_[0]->{-pdta}->{$n||'tfoShow_'}
	|| ($d && !(grep {!$_[0]->{-pout}->{$_}} @$d))
	? $x
	: ($x
	  .$s->htmlSubmitSpl(-name=>($n||'tfoShow_')
		,$s->{-c}->{-htmlclass} ? (-class=>$s->{-c}->{-htmlclass}) : ()
		,-value=>$_[0]->lng(0,'ddlbopen')
		,-title=>$_[0]->lng(1,'ddlbopen')
		,-style=>'width: 2em;'))
 }
}


sub tfoHide {	# Template Field Option '-hide' details absent
		# (self, ? input name)
 my ($s, $n) =@_;
 sub{!($_ || $_[0]->{-pdta}->{$n||'tfoShow_'} ||$_[3])}
}



sub tfdRFD {	# Template Field Definition for Record File Directory
		# self, ? definition
 my ($s) =@_; return
 {-fld=>''
 ,-flg=>'e'	# 'e'dit
 ,-lbl=>sub{$_[0]->lng(0,'rfafolder')}
 ,-cmt=>sub{$_[0]->lng(1,'rfafolder')}
 ,-lblhtml=> sub{
	return('') if !$_[0]->{-pout}->{-file};
	'<a href="' 
	.(	  $_[0]->rfdPath(-urf=>$_[0]->{-pout}->{-file})
		||$_[0]->rfdPath(-url=>$_[0]->{-pout}->{-file}))
	.'" target="_blank" '
	.' title="' .$s->htmlEscape($s->lng(1,'rfafolder')) .'"'
	.($_[0]->cgi->user_agent('MSIE')
	 ? ' style="behavior:url(\'#default#httpFolder\')"'
	 : '')
	.'>'
	.($_[0]->{-icons} && $IMG->{'rfafolder'}
	 ? '<img src="' .$_[0]->{-icons} .'/' .$IMG->{'rfafolder'} .'" border=0'
		.($_[0]->cgi->user_agent('MSIE')
		 ? ' style="behavior:url(\'#default#httpFolder\')"'
		 : '')
		.'/></a> '
	 : $_[0]->htmlEscape($_[0]->lng(0,'rfafolder')) .'</a>: ');
 }
 ,-inp=>{-rfd=>1}
 ,@_ > 1 ? @_[1..$#_] : ()
 }
}


sub ttoRVC {	# Template Table Option for Record Version Control
	my $s =$_[0];
	my $tn=$s->{-tn};
	(-key		=> $tn->{-key}
	,-rvcInsBy	=> $tn->{-rvcInsBy}
	,-rvcInsWhen	=> $tn->{-rvcInsWhen}
	,-rvcUpdBy	=> $tn->{-rvcUpdBy}
	,-rvcUpdWhen	=> $tn->{-rvcUpdWhen}
	,-rvcActPtr	=> $tn->{-rvcActPtr}
	,-rvcVerWhen	=> $tn->{-rvcVerWhen}
	,-rvcChgState	=> $tn->{-rvcChgState}
	,-rvcCkoState	=> $tn->{-rvcCkoState}
	,-rvcDelState	=> $tn->{-rvcDelState}
	,@_ > 1 ? @_[1..$#_] : ())
}


sub tvmVersions {	# Template for Materialized View of Versions of records
			# 'versions' materialized view default definition
			# self, ? fields add, ? definitions add
	my $s =$_[0]; 
	my $tn=$s->{-tn};
	return($tn->{'tvmVersions'}=>
	{-lbl	=>	sub{$_[0]->lng(0,'tvmVersions')}
	,-cmt	=>	sub{$_[0]->lng(1,'tvmVersions')}
	,-field	=>	[
		 {-fld=>'table',		-edit=>0, -flg=>'uql'}
		,{-fld=>$tn->{-rvcActPtr},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>'id',			-edit=>0, -flg=>'uql'}
		,{-fld=>$tn->{-rvcInsWhen},	-edit=>0, -flg=>'uq'}
		,''
		,{-fld=>$tn->{-rvcInsBy},	-edit=>0, -flg=>'uq'}
		,{-fld=>$tn->{-rvcUpdWhen},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>$tn->{-rvcUpdBy},	-edit=>0, -flg=>'uql'}
		,{-fld=>$tn->{-rvcState},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>'subject',		-edit=>0, -flg=>'uql'}
		,{-fld=>'readers',		-edit=>0, -flg=>'u'}
		,{-fld=>'cargo',		-edit=>0, -flg=>'u'}
		,ref($_[1]) eq 'ARRAY' ? @{$_[1]} : ()
		]
	,-key	=>	['table',$tn->{-rvcActPtr},'id']
	,-racReader=>	['readers']
	,-rvcInsBy=>	$tn->{-rvcInsBy}
	,-rvcUpdBy=>	$tn->{-rvcUpdBy}
	,-rvcActPtr=>	$tn->{-rvcActPtr}
	,-query	=>	{-version=>'+'}
	,-ixcnd	=>	sub{$_[2]->{'id'}}
	,-ixrec	=>	sub{my $m =$_[0]->{-table}->{$_[1]->{-table}};
		return(
		{'table'		=>$_[1]->{-table}
		,$tn->{-rvcActPtr}	=>$m->{-rvcActPtr} && $_[2]->{$m->{-rvcActPtr}}
		,'id'			=>$_[2]->{'id'}
		,$tn->{-rvcInsWhen}	=>$m->{-rvcInsWhen} && $_[2]->{$m->{-rvcInsWhen}}
		,$tn->{-rvcInsBy}	=>$m->{-rvcInsBy}   && $_[2]->{$m->{-rvcInsBy}}
		,$tn->{-rvcUpdWhen}	=>$m->{-rvcUpdWhen} && $_[2]->{$m->{-rvcUpdWhen}}
		,$tn->{-rvcUpdBy}	=>$m->{-rvcUpdBy}   && $_[2]->{$m->{-rvcUpdBy}}
		,$tn->{-rvcState}	=>$m->{-rvcChgState}&& $_[2]->{$m->{-rvcChgState}->[0]}
		,'subject'	=>mdeSubj($_[0],$_[2])
		,'readers'	=>join(',', map {$_[2]->{$_}||''} 
				grep {$_[2]->{$_}} 
				@{$m->{-racReader}||$_[0]->{-racReader}||[]}
				, @{$m->{-racWriter}||$_[0]->{-racWriter}||[]})
		,'cargo'	=>join("\t",map {$_[2]->{$_}||''} 
				grep {$_[2]->{$_}} keys %{$_[2]})
		})}
	,-qhref	=>	{-formfld	=>'table'
			,-key		=>['id']	# [['id'=>2]]
			}
	,@_ > 2 ? @_[2..$#_] : ()
	})
}


sub tfvVersions {	# Template for Field View of Versions of records
 my ($s, $f, @a) =@_;	# (self, ? fields add, ? definitions add | sub{}(self, table, definitions add))
 sub{
	return('')	if ($_[0]->{-pcmd}->{-cmg} eq 'recQBF')
			|| !$_[0]->{-pcmd}->{-table}
			|| !$_[0]->{-pout}->{'id'}
			|| $_[0]->{-pcmd}->{-print};
	my $v =$_[0]->{-tn}->{'tvmVersions'};
	my $q =($_[0]->{-table}->{$_[0]->{-pcmd}->{-table}}->{-dbd} ||$_[0]->{-dbd}) eq 'dbi';
	$v =$_[0]->{-pcmd}->{-table} if $q;
	my @o =ref($a[0]) eq 'CODE' ? &{$a[0]}($_[0], $v, @a[1..$#a]) : @a;
	my $u= $q
		? {-key=>{$_[0]->{-tn}->{-rvcActPtr}=>$_[0]->{-pout}->{'id'}}
		  ,-version=>1} 
		: {-key=>{$q 
			 ? () 
			 : ('table'=>$_[0]->{-pcmd}->{-table})
			 , $_[0]->{-tn}->{-rvcActPtr}=>$_[0]->{-pout}->{'id'}}
		  ,-order=>'-deq'
		  ,-version=>1};
	my $h = $u
		?($_[0]->cgi->hr()
		. $_[0]->cgi->a({-title=>$_[0]->lng(1,'recQBF')
			,-href=>$_[0]->urlCmd('',-cmd=>'recList'
				,-form=>$v
					,map {	/^-/
						? ('-q' .$' => $u->{$_})
						: ()
						} keys %$u)}
			,$_[0]->lng(0,'tvmVersions') .':') .' ')
		: $_[0]->cgi->hr();
	local $_[0]->{-uiclass} ='tfvVersions';
	local $_[0]->{-uistyle} ='font-size: small' if 0;
	$_[0]->cgiList('-!h'
		,$v
		,undef
		,{-qhrcol=>1, -qflghtml=>$h, $_[0]->shiftkeys(\@o,'-qhrcol|-qflghtml')}
		,{$u ? %$u : ()
		 ,-table=>$v
		 ,-order=>$q ? $_[0]->{-tn}->{-rvcUpdWhen} . ' desc' : '-deq'
		 ,-version=>1
		 ,-data=>[$q 
			?('id', $_[0]->{-tn}->{-rvcUpdBy}, $_[0]->{-tn}->{-rvcUpdWhen})
			:({-fld=>'table',			-flg=>'q'}
			 ,{-fld=>'id',				-flg=>'q'}
			 ,{-fld=>$_[0]->{-tn}->{-rvcUpdBy},	-flg=>'ql'}
			 ,{-fld=>$_[0]->{-tn}->{-rvcUpdWhen},	-flg=>'ql'})
			 ,ref($f) eq 'ARRAY' ? @$f : ()]
		 ,-display=>[$_[0]->{-tn}->{-rvcUpdBy}, $_[0]->{-tn}->{-rvcUpdWhen}]
		 ,@o
		 },'; ');
	''
 }
}


sub tvmHistory {	# Template for Materialized View of database History
			# 'history' materialized view default definition
			# self, ? fields add, ? definitions add
	my $s =$_[0]; 
	my $tn=$s->{-tn};
	return($tn->{'tvmHistory'}=>
	{-lbl	=>	sub{$_[0]->lng(0,'tvmHistory')}
	,-cmt	=>	sub{$_[0]->lng(1,'tvmHistory')}
	,-field	=>	[
		 {-fld=>$tn->{-rvcInsWhen},	-edit=>0, -flg=>'uq'}
		,''
		,{-fld=>$tn->{-rvcInsBy},	-edit=>0, -flg=>'uq'}
		,{-fld=>$tn->{-rvcUpdWhen},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>$tn->{-rvcUpdBy},	-edit=>0, -flg=>'uql'}
		#	,{-fld=>'table', -edit=>0, -flg=>'uq'}
		#	,''
		,{-fld=>'id',			-edit=>0, -flg=>'uq'}
		,{-fld=>$tn->{-rvcState},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>$tn->{-rvcActPtr},	-edit=>0, -flg=>'uq'}
		,{-fld=>'subject',		-edit=>0, -flg=>'uql'}
		,{-fld=>'auser',		-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>'arole',		-edit=>0, -flg=>'uql'}
		,{-fld=>'puser',		-edit=>0, -flg=>'uq'}
		,''
		,{-fld=>'prole',		-edit=>0, -flg=>'uq'}
		,{-fld=>'readers',		-edit=>0, -flg=>'u'}
		,{-fld=>'cargo',		-edit=>0, -flg=>'u'}
		,ref($_[1]) eq 'ARRAY' ? @{$_[1]} : ()
		]
	,-key	=>	[$tn->{-rvcUpdWhen},$tn->{-rvcUpdBy},'id']
					# ,'table'
	,-racReader=>	['readers']
	,-racPrincipal=>['puser','prole']
	,-racActor=>	['auser','arole']
	,-rvcInsBy=>	$tn->{-rvcInsBy}
	,-rvcUpdBy=>	$tn->{-rvcUpdBy}
	,-rvcActPtr=>	$tn->{-rvcActPtr}
	,-ixcnd	=>	sub{$_[2]->{'id'} && $_[2]->{$tn->{-rvcUpdWhen}}}
	,-ixrec	=>	sub{
		my $m	=$_[0]->{-table}->{$_[1]->{-table}};
		my $ra	= mdeRole($_[0], $m, 'authors');
		my $rp	= mdeRole($_[0], $m, 'principals','users');
		return(
		{'id'		=>$_[1]->{-table} .$RISM1 .$_[2]->{'id'}
		#'table'	=>$_[1]->{-table}
		#'id'		=>$_[2]->{'id'}
		,$tn->{-rvcInsWhen}	=>$m->{-rvcInsWhen} && $_[2]->{$m->{-rvcInsWhen}}
		,$tn->{-rvcInsBy}	=>$m->{-rvcInsBy}   && $_[2]->{$m->{-rvcInsBy}}
		,$tn->{-rvcUpdWhen}	=>$m->{-rvcUpdWhen} && $_[2]->{$m->{-rvcUpdWhen}}
		,$tn->{-rvcUpdBy}	=>$m->{-rvcUpdBy}   && $_[2]->{$m->{-rvcUpdBy}}
		,$tn->{-rvcState}	=>$m->{-rvcChgState}&& $_[2]->{$m->{-rvcChgState}->[0]}
		,$tn->{-rvcActPtr}	=>$m->{-rvcActPtr}  && $_[2]->{$m->{-rvcActPtr}}
		,'subject'	=>mdeSubj($_[0],$_[2])
		,'auser'	=>(!$ra 		? undef
				: !ref($ra)		? $_[2]->{$ra}
				: @$ra && $ra->[0]	? $_[2]->{$ra->[0]}
				: undef)
				|| $_[2]->{$m->{-rvcUpdBy} ||$_[0]->{-rvcUpdBy} ||''}
		,'arole'	=>!ref($ra) || $#$ra <1
				? undef
				: join(',', map {!$_[2]->{$_} ? () : ($_[2]->{$_})
					} @$ra[1..$#$ra])
		,'puser'	=>(!$rp 		? undef
				: !ref($rp)		? $_[2]->{$rp}
				: @$rp && $rp->[0]	? $_[2]->{$rp->[0]}
				: undef)
				|| $_[2]->{$m->{-rvcInsBy} ||$_[0]->{-rvcInsBy} ||''}
		,'prole'	=>!ref($rp) || $#$rp <1
				? undef
				: join(',', map {!$_[2]->{$_} ? () : ($_[2]->{$_})
					} @$rp[1..$#$rp])
		,'readers'	=>join(',', map {$_[2]->{$_}||''} 
				grep {$_[2]->{$_}} 
				@{$m->{-racReader}||$_[0]->{-racReader}||[]}
				, @{$m->{-racWriter}||$_[0]->{-racWriter}||[]})
		,'cargo'	=>join("\t",map {$_[2]->{$_}||''} 
				grep {$_[2]->{$_}} keys %{$_[2]})
		})}
	,-qhref	=>	{-formfld	=>''	# 'table'
			,-key		=>'id'	# ['id'] # [['id'=>3]]
			}
	,-query	=>	{-order		=>'-dall'}
	,@_ > 2 ? @_[2..$#_] : ()
	})
}



sub tvmReferences {	# Template for Materialized View of References to records
			# 'references' materialized view default definition
			# self, ? fields, ? definition
	my $s =$_[0]; 
	my $tn=$s->{-tn};
	return ($tn->{'tvmReferences'}=>
	{-lbl	=>	sub{$_[0]->lng(0,'tvmReferences')}
	,-cmt	=>	sub{$_[0]->lng(1,'tvmReferences')}
	,-field	=>	[
		 {-fld=>'ir',			-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>'id',			-edit=>0, -flg=>'uql'}

		,{-fld=>$tn->{-rvcInsWhen},	-edit=>0, -flg=>'uq'}
		,''
		,{-fld=>$tn->{-rvcInsBy},	-edit=>0, -flg=>'uq'}
		,{-fld=>$tn->{-rvcUpdWhen},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>$tn->{-rvcUpdBy},	-edit=>0, -flg=>'uq'}

		,{-fld=>$tn->{-rvcState},	-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>$tn->{-rvcActPtr},	-edit=>0, -flg=>'uq'}
		,{-fld=>'subject',		-edit=>0, -flg=>'uql'}
		,{-fld=>'auser',		-edit=>0, -flg=>'uql'}
		,''
		,{-fld=>'arole',		-edit=>0, -flg=>'uql'}
		,{-fld=>'puser',		-edit=>0, -flg=>'uq'}
		,''
		,{-fld=>'prole',		-edit=>0, -flg=>'uq'}
		,{-fld=>'readers',		-edit=>0, -flg=>'u'}
		,ref($_[1]) eq 'ARRAY' ? @{$_[1]} : ()
		]
	,-key	=>	['ir',$tn->{-rvcUpdWhen},'id']
	,-qhrcol=>	1
	,-racReader=>	['readers']
	,-racPrincipal=>['puser','prole']
	,-racActor=>	['auser','arole']
	,-rvcInsBy=>	$tn->{-rvcInsBy}
	,-rvcUpdBy=>	$tn->{-rvcUpdBy}
	,-rvcActPtr=>	$tn->{-rvcActPtr}
	,-ixcnd	=>	sub{$_[2]->{'id'} 
			&& ($_[0]->{-table}->{$_[1]->{-table}}->{-ridRef}
				||$_[0]->{-ridRef})}
	,-ixrec	=>	sub{
		my $s  =$_[0];
		my $m  =$s->{-table}->{$_[1]->{-table}};
		my $ir =[];
		my $id =$_[1]->{-table} .$RISM1 .$_[2]->{'id'};
		foreach my $f (@{$m->{-ridRef} ||$s->{-ridRef}}) {
			if (!$_[2]->{$f}) {
				next
			}
			elsif ($_[2]->{$f} =~/[\s,.?]/) {
				my $v =$_[2]->{$f};
				while ($v =~/(?:_key=id%3D|_key=)([\w\d]+\Q$RISM1\E[\w\d]+)/i) {
					push @$ir, $1;
					$v =$'
				}
			}
			elsif (length($_[2]->{$f}) >$NLEN *3) {
				next
			}
			elsif ($_[2]->{$f} =~/\Q$RISM1\E/) {
				push @$ir, $_[2]->{$f}
			}
			else {
				push @$ir, $_[1]->{-table} .$RISM1 .$_[2]->{$f}
			}
		}
		return($ir) if !@$ir;
		my $ra	= mdeRole($_[0], $m, 'authors');
		my $rp	= mdeRole($_[0], $m, 'principals','users');
		my $rv	=
		{'id'		=>$id
				# below alike 'tvmHistory'
		,$tn->{-rvcInsWhen}	=>$m->{-rvcInsWhen} && $_[2]->{$m->{-rvcInsWhen}}
		,$tn->{-rvcInsBy}	=>$m->{-rvcInsBy}   && $_[2]->{$m->{-rvcInsBy}}
		,$tn->{-rvcUpdWhen}	=>$m->{-rvcUpdWhen} && $_[2]->{$m->{-rvcUpdWhen}}
		,$tn->{-rvcUpdBy}	=>$m->{-rvcUpdBy}   && $_[2]->{$m->{-rvcUpdBy}}
		,$tn->{-rvcState}	=>$m->{-rvcChgState}&& $_[2]->{$m->{-rvcChgState}->[0]}
		,$tn->{-rvcActPtr}	=>$m->{-rvcActPtr}  && $_[2]->{$m->{-rvcActPtr}}
		,'subject'	=>mdeSubj($_[0],$_[2])
		,'auser'	=>(!$ra 		? undef
				: !ref($ra)		? $_[2]->{$ra}
				: @$ra && $ra->[0]	? $_[2]->{$ra->[0]}
				: undef)
				|| $_[2]->{$m->{-rvcUpdBy} ||$_[0]->{-rvcUpdBy} ||''}
		,'arole'	=>!ref($ra) || $#$ra <1
				? undef
				: join(',', map {!$_[2]->{$_} ? () : ($_[2]->{$_})
					} @$ra[1..$#$ra])
		,'puser'	=>(!$rp 		? undef
				: !ref($rp)		? $_[2]->{$rp}
				: @$rp && $rp->[0]	? $_[2]->{$rp->[0]}
				: undef)
				|| $_[2]->{$m->{-rvcInsBy} ||$_[0]->{-rvcInsBy} ||''}
		,'prole'	=>!ref($rp) || $#$rp <1
				? undef
				: join(',', map {!$_[2]->{$_} ? () : ($_[2]->{$_})
					} @$rp[1..$#$rp])
		,'readers'	=>join(',', map {$_[2]->{$_}||''} 
				grep {$_[2]->{$_}} 
				@{$m->{-racReader}||$s->{-racReader}||[]}
				, @{$m->{-racWriter}||$s->{-racWriter}||[]})
		};
		map {$_ ={'ir'=>$_, %$rv}} @$ir;
		$ir}
	,-qhref	=>	{-formfld	=>''
			,-key		=>'id'
			}
	,-query	=>	{-order		=>'-dall'}
	,@_ > 2 ? @_[2..$#_] : ()
	})
}



sub tfvReferences {	# Template for Field embedded View of References to record
 my ($s, $f, @a) =@_;	# (self, ? fields add, ? definitions add | sub{}(self, table, definitions add))
 sub{
	return('')
		if ($_[0]->{-pcmd}->{-cmg} eq 'recQBF')
		|| !$_[0]->{-pcmd}->{-table}
		|| !$_[0]->{-pout}->{'id'};
	my $v =$_[0]->{-tn}->{'tvmReferences'};
	my $q =(($_[0]->{-table}->{$_[0]->{-pcmd}->{-table}}->{-dbd} ||$_[0]->{-dbd}) 
			eq 'dbi')
		&& !$_[0]->{-table}->{$v};
	$v =$_[0]->{-pcmd}->{-table} if $q;
	my @o =ref($a[0]) eq 'CODE' ? &{$a[0]}($_[0], $v, @a[1..$#a]) : @a;
	my %o =$_[0]->splicekeys(\@o,'-where|-key|-order|-keyord');
	my $qe =$_[0]->{-pout}->{comment} && $_[0]->{-table}->{$v} && $_[0]->{-table}->{$v}->{-mdefld} && $_[0]->{-table}->{$v}->{-mdefld}->{comment};
	   $qe =$qe && $qe->{-inp} && ($qe->{-inp}->{-htmlopt} || $qe->{-inp}->{-hrefs}) 
		&& $_[0]->{-pout}->{comment};
	   $qe =$qe && ($qe =~/^<(?:where|qwhere)>(.+?)<\/(?:where|qwhere)>/i) && $1;
	return('')
		if $q 
		? !$_[0]->{-table}->{$v}->{-ridRef}
		: !$_[0]->{-table}->{$v};
	my $u =$q
		? {-where=>join(' OR '
			, $qe ? "($qe)" : ()
			, map { $v .'.' .$_ .'=' .$_[0]->dbi->quote($_[0]->{-pout}->{'id'})
				} @{$_[0]->{-table}->{$v}->{-ridRef}}
			)
		  ,%o}
		: {-key=>{'ir'=>$_[0]->{-pcmd}->{-table} .$RISM1 .$_[0]->{-pout}->{'id'}}
		  ,-order=>'-deq'
		  ,%o};

	my $h =	$_[0]->{-pcmd}->{-print}
		? $_[0]->cgi->hr()
		: $u
		?($_[0]->cgi->hr()
		#. '<div align="right" style="font-size: smaller;">'
		. $_[0]->cgi->a({-title=>$_[0]->lng(1,'recQBF')
				,-href=>$_[0]->urlCmd('',-cmd=>'recList'
					,-form=>$v
						,map {	/^-/
							? ('-q' .$' => $u->{$_})
							: ()
							} keys %$u)}
			,$_[0]->lng(0,'tvmReferences') .':'))
		#. '</div>'
		: $_[0]->cgi->hr();
	local $_[0]->{-uiclass} ='tfvReferences';
	local $_[0]->{-uistyle} ='font-size: small' if 0;
	$_[0]->cgiList('-!h'
	,$v
	,undef
	,{-qhrcol=>0, -qflghtml=>$h, $_[0]->splicekeys(\@o,'-qhrcol|-qflghtml')}
	,{$u ? %$u : ()
	 ,-table=>$v
	 ,-version=>0
	 , $q
	 ?(
	   (map {$_[0]->{-table}->{$v}->{-query} && $_[0]->{-table}->{$v}->{-query}->{$_}
			? ($_ => $_[0]->{-table}->{$v}->{-query}->{$_})
			: ()
			} qw (-display -data -datainc -order -keyord))
	# ,-order=>$_[0]->{-tn}->{-rvcUpdWhen}
	# ,-keyord=>'-dall'
	  ,$_[0]->splicekeys(\@o,'-display|-data|-datainc|-where|-key|-order|-keyord')
	  ,%o
		)
	 :(-field=>[{-fld=>'ir',			-flg=>'q'}
		 ,{-fld=>'id',				-flg=>'q'}
		 ,{-fld=>$_[0]->{-tn}->{-rvcUpdWhen},	-flg=>'ql'}
		 ,{-fld=>$_[0]->{-tn}->{-rvcState},	-flg=>'ql'}
		 ,{-fld=>'subject',			-flg=>'ql'}
		 ,{-fld=>'auser',			-flg=>'ql'}
		 ,{-fld=>'arole',			-flg=>'ql'}
		,ref($f) eq 'ARRAY' ? @$f : ()
		]
	  ,-order=>'-deq'
		)
	,@o
	});
	''
 }
}



sub tvdIndex {	# Template View Definition for Index page
 my $s =$_[0]; return ($s->{-tn}->{'tvdIndex'}=>
 {-lbl		=>sub{$_[0]->lng(0,'tvdIndex')}
 ,-cmt		=>sub{$_[0]->lng(1,'tvdIndex')}
 ,-cgcCall	=>sub{
	my $s =$_[0];
	$s->{-fetched}	=undef;
	$s->{-affected}	=undef;
	local @{$s}{-menuchs, -menuchs1} =@{$s}{-menuchs, -menuchs1};
	$s->htmlMChs()	if !$s->{-menuchs};
	$s->output($s->htmlStart(@_[1,2])	# HTTP/HTML/Form headers
		,$s->htmlHidden(@_[1,2])	# common hidden fields
		,!$s->{-pcmd}->{-print}
		&& $s->htmlMenu(@_[1,2])	# Menu bar
		,"\n<table class=\"ListTable\">\n"
		);
	$s->htmlOnLoad("{var e=document.getElementsByTagName('BASE'); if(e && e[0] && (self.name.match(/^(?:TOP|BOTTOM)\$/) || document.getElementsByName('_frame').length)){e[0].target='_blank'}}");
	foreach my $e	(($s->{-menuchs} ? @{$s->{-menuchs}} : ())
			,($s->{-menuchs1}? @{$s->{-menuchs1}}: ())
			) {
		my ($n, $l) = ref($e) ? @$e : ($e, $e);
		$l ='--- ' .$_[0]->lng(0, 'frmCallNew') .' ---' if !$n && !$l;
		next if $n eq '-frame';
		my ($o, $a) = $n =~/^(.+?)([+&.]+)$/ ? ($1, $2) : ($n, $n);
		my $l0 =$s->lnglbl($s->{-form}->{$o} ||$s->{-table}->{$o} ||{}, $o)||'';
		my $l1 =$s->lngcmt($s->{-form}->{$o} ||$s->{-table}->{$o} ||{}, $o)||'';
		my $ur1=$s->urlCat('','_form'=>$n,'_cmd'=>'frmCall');
		my $ur2=$s->{-pcmd}->{-frame}
			? $s->urlCat('','_form'=>$n,'_cmd'=>'frmCall','_frame'=>$s->{-pcmd}->{-frame})
			: $ur1;
		$s->output('<tr><th align="left" valign="top"><nobr>'
			, $n
			? $s->cgi->a({-href=>$ur1
				,-title=>  $a =~/[+]/ 
					? $s->lng(1,'frmCallNew') ." '$l0'"
					: $a =~/[&.]/
					? $s->lng(0,'frmCallOpn') ." '$l0'"
					: $s->lng(0,'frmCallOpn') ." '$l0'"
				, $a =~/[+]/		# form
				? (-OnClick=>"window.document.open('$ur1', self.name.match(/^(?:TOP|BOTTOM)\$/) || document.getElementsByName('_frame').length ? '_blank' : '_self','',false); return(false)"
					# or "this.target = self.name.match(/^(?:TOP|BOTTOM)\$/) || document.getElementsByName('_frame').length ? '_blank' : '_self'; return(true)";
					)
				: (-target=>'_self'	# list
				  ,-OnClick=>"window.document.open('$ur2', self.name=='TOP' ? '_self': self.name=='BOTTOM' ? 'TOP' : '_self','',false); return(false)"
					# or "this.target = self.name=='TOP' ? '_self' : self.name=='BOTTOM' ? 'TOP' : '_self'; return(true)";
					)
				}
				,(!$s->{-icons}
				? ''
				: '<img border="0" src="' .$s->{-icons} .'/'
				. ( $a =~/[+]/  ? $IMG->{'recNew'}
				  : $a =~/[&.]/ ? $IMG->{'frmCall'}
				  : $IMG->{'recList'}
				  ) .'" />')
				. $s->htmlEscape($l0))
			: $s->htmlEscape($l)
			, "</nobr></th>\n"
			, '<td>&nbsp;</td><td align="left" valign="bottom">'
			, $s->htmlEscape( !$l1 || $l1 ne $l0
					? $l1||''
					: 1
					? $l1||''
					: $a =~/[+]/ 
					? $s->lng(0,'frmCallNew') ." '$l0'"
					: $a =~/[&.]/
					? $s->lng(0,'frmCallOpn') ." '$l0'"
					: $s->lng(0,'frmCallOpn') ." '$l0'"
					)
			, "</td></tr>\n"
			)
		}
	$s->output("\n</table>\n");
	# $s->recCommit();
	$s->cgiFooter() if !$s->{-pcmd}->{-print};
	$s->output($s->htmlEnd());
	$s->end();
	}
	,@_ > 1 ? @_[1..$#_] : ()
 })
}



sub tvdFTQuery {	# Template View Definition for Full-Text Query
 my $s =$_[0]; return ($s->{-tn}->{'tvdFTQuery'}=>
 {-lbl		=>sub{$_[0]->lng(0,'tvdFTQuery')}
 ,-cmt		=>sub{$_[0]->lng(1,'tvdFTQuery')}
 ,-cgcCall	=>sub{
	my $s =$_[0];
	my $g =$s->cgi();
	$s->{-fetched}	=0;
	$s->{-affected}	=undef;
	$s->{-pcmd}->{-cmd} =$s->{-pcmd}->{-cmg} ='recQBF';
	$s->output($s->htmlStart(@_[1,2])	# HTTP/HTML/Form headers
		,$s->htmlHidden(@_[1,2])	# common hidden fields
		,!$s->{-pcmd}->{-print}
		&& $s->htmlMenu(@_[1,2])	# Menu bar
		,"\n"
		);
	$s->die('Microsoft IIS required')	if ($ENV{SERVER_SOFTWARE}||'') !~/IIS/;
	$s->die('Impersonation required')	if (($ENV{GATEWAY_INTERFACE}||'') =~/PerlEx/i)
						&& ($s->{-c}->{-RevertToSelf}
							||$s->w32ufswtr());
	$g->param('_qftwhere'
		, defined($g->param('_qftwhere')) && ($g->param('_qftwhere') ne '')
		? $g->param('_qftwhere')
		: defined($g->param('_qftext')) && ($g->param('_qftext') ne '')
		? $g->param('_qftext')
		: '');
	$s->output($g->textfield(-name=>'_qftwhere', -size=>70, -title=>$s->lng(1,'-qftwhere'))
		, '<br />'
		, $g->popup_menu(-name=>'_qftord'
			,-values=>['write','hitcount','vpath','docauthor']
			,-labels=>{
				 'write'	=>'Chronologically'
				,'hitcount'	=>'Ranked'
				,'vpath'	=>'by Name'
				,'docauthor'	=>'by Author'
				}
			,-default=>'write')
		, $g->popup_menu(-name=>'_qlimit'
			,-values=>['',128,256,512,1024,2048,4096]
			,-labels=>{
				 ''  =>"$LIMRS default"
				,128 =>'128  max'
				,256 =>'256  max'
				,512 =>'512  max'
				,1024=>'1024 max'
				,2048=>'2048 max'
				,4096=>'4096 max'
				}
			,-default=>$LIMRS)
		, $g->submit(-name =>'tvdFTQuery_'
			,-value=>$s->lng(0,'recList')
			,-title=>$s->lng(1,'recList'))
		, '' && $g->a({-href=>
			-e ($ENV{windir} .'/help/ix/htm/ixqrylan.htm')
			? '/help/microsoft/windows/ix/htm/ixqrylan.htm'
			: '/help/microsoft/windows/isconcepts.chm' # .'::/ismain-concepts_30.htm'
			}, '?')
		, "<br />\n");

	if ($g->param('_qftwhere') ne '') {
		eval('use Win32::OLE; Win32::OLE->Option("Warn"=>0)');
		Win32::OLE->Initialize();
		# Win32::OLE->Initialize(&Win32::OLE::COINIT_OLEINITIALIZE);
		# Search MSDN for 'ixsso.Query'
		my $oq =Win32::OLE->CreateObject("ixsso.Query");
		!$oq && $s->die("'OLE->CreateObject(ixsso.Query)' failed '$!'/'$@'/" .Win32::OLE->LastError);
		my $ou =Win32::OLE->CreateObject("ixsso.util");
		!$oq && $s->die("'OLE->CreateObject(ixsso.util)' failed '$!'/'$@'/" .Win32::OLE->LastError);
		my $qs =[];
		my $qt =[];
		$oq->{Query} =$g->param('_qftwhere') =~/^(@\w|\{\s*prop\s+name\s+=)/i
				? $g->param('_qftwhere')
				: ('@contents ' .$g->param('_qftwhere'));
		$oq->{Catalog}    ='Web';
		$oq->{MaxRecords} =$g->param('_qlimit') ||$LIMRS;
		$oq->{MaxRecords} =4096 if $oq->{MaxRecords} >4096;
		$oq->{SortBy}     =$g->param('_qftord') ||'write';
		$oq->{SortBy}    .=$oq->{SortBy} =~/^(write|hitcount)$/i 
				? '[d],docauthor[a]' 
				: '[a],write[d]';
		$oq->{Columns}    ='vpath,path,filename,hitcount,write,doctitle,docauthor,characterization';
		$oq->{LocaleID}   =1049; # ru

		my $ol =eval {$oq->CreateRecordset('sequential')}; # 'nonsequential'
		!$oq && $s->die("'OLE->CreateRecordset(sequential)' failed '$!'/'$@'/" .Win32::OLE->LastError);
		$s->output('No records found') if $ol->{EOF};

		my ($rcf, $rct, $rcd) =(0, 0, 0);
		while (!$ol->{EOF}) {
			my $vp =$ol->{vPath}->{Value};
			$rcf +=1;
			if (!$vp) {
				$rct +=1;
			}
			if ($vp) {
				$rcd +=1;
				my $vt =$g->escapeHTML($ol->{DocTitle}->{Value});
				$vt = ($vt ? '$vt' .'&nbsp;&nbsp;' : '')
				. '(' .$g->escapeHTML($ol->{DocAuthor}->{Value}) .')'
					if $ol->{DocAuthor}->{Value};
				$vt = ($vt ? $vt .'&nbsp;&nbsp;&nbsp;(' : '')
					. $g->escapeHTML($vp) .')';
				$s->output($g->a({-href=>$vp||$ol->{Path}->{Value}
						,-title=>$ol->{HitCount}->{Value}
						.': ' .$ol->{Path}->{Value}}
						, $vt)
					, $ol->{Characterization}->{Value}
					? '<br />' .$g->escapeHTML($ol->{Characterization}->{Value})
					: ''
					, "<br /><br />\n");
			}
			if (!eval {$ol->MoveNext; 1}) {
				$s->output('Bad query');
				last
			}
		}
		Win32::OLE->FreeUnusedLibraries;
		# Win32::OLE->Uninitialize;
		$s->{-fetched}	=$rcd;
		$s->{-affected}	=$rcf;
		$s->logRec('FTQuery',-fetched=>$rcd, -found=>$rcf, -vpathgen=>$rct, -max=>($oq->{MaxRecords}||'undef'));
	}
	else  {
		$s->output('Enter query condition')
	}
	$s->{-pcmd}->{-cmd} =$s->{-pcmd}->{-cmg} ='recList';
	$s->cgiFooter() if !$s->{-pcmd}->{-print};
	$s->output($s->htmlEnd());
	$s->end();
 }
 ,@_ > 1 ? @_[1..$#_] : ()})
}


sub ttsAll {	# Template Tables Set of All generally used views
 return(	# - to add to '-table'
	 $_[0]->tvmVersions()
	,$_[0]->tvmHistory()
	,$_[0]->tvmReferences()
 )
}


sub tfsAll {	# Template Fields Set for All generally used fields
 return(	# - to add to '-field'
	 $_[0]->tfdRFD()
	,"\f"
	,$_[0]->tfvVersions()
	,$_[0]->tfvReferences()
 )
}


#########################################################
# File Handle Object
#########################################################



package DBIx::Web::FileHandle;
use strict;
use Symbol;
use Fcntl qw(:DEFAULT :flock :seek :mode);

sub new {
  my ($c, %o) =@_;
  my $s ={-name  =>''       # file name
         ,-mode  =>'<'      # file open mode
         ,-parent=>undef    # parent object
         ,-handle=>undef    # Symbol::gensym on file open
         ,-lock  =>LOCK_UN  # lock level
         ,-lcks  =>{}       # locks
       # ,-new   =>undef    # new file created
       # ,-buf   =>undef    # file contents from 'loadXX' calls
       # ,-ret   =>undef    # data to return, for external programming
         };
  foreach my $k (keys(%o)) {$s->{$k} =$o{$k}}
  bless $s, $c;
  $s->open() if defined($s->{-name}) && $s->{-name} ne '';
  $s
}


sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($s, %o) =@_;
 foreach my $k (keys(%o)) {$s->{$k} =$o{$k}};
 $s
}


sub parent {
 $_[0]->{-parent}
}


sub open {
 my $s =shift;
 if    (!@_) {}
 elsif ($_[0] =~/^-(name|mode)$/) {$s->set(@_)}
 else  {foreach my $k ('-mode','-name') {$s->{$k} =shift if defined($_[0])}}
 $s->{-new} =!-e $s->{-name};
 $s->{-lcks}={};
 if (!CORE::open($s->{-handle} =Symbol::gensym, $s->{-mode}, $s->{-name})) {
    $s->{-handle} =undef;
    return(&{$s->{-parent} ? $s->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
           ("File: open('" .($s->{-mode}||'') ."','" .($s->{-name}||'') ."') -> $!"
		.($s->{-parent} && $s->{-parent}->{-ermd} ||'')
		) ||undef)
 }
 $s
}


sub opent {
 return($_[0]) if $_[0]->{-handle};
 $_[0]->open() || return(undef);
 $_[0]->lock($_[0]->{-lock}) if $_[0]->{-lock} ne LOCK_UN;
 $_[0]
}


sub binmode {
 CORE::binmode($_[0]->{-handle}); $_[0]
}

sub close {
 return($_[0]) if !$_[0]->{-handle};
 $_[0]->lock(LOCK_UN |LOCK_NB) if $_[0]->{-lock} ne LOCK_UN;
 $_[0]->{-lcks}={};
 CORE::close($_[0]->{-handle}); 
 $_[0]->{-handle} =undef;
 $_[0]
}


sub destroy {
 eval{$_[0]->close()} if $_[0]->{-handle};
 $_[0]->{-parent} =undef;
 $_[0]
}


sub DESTROY {
 destroy(@_)
}


sub lock  { # ?lock value, ?lock key
 # LOCK_SH ==1; LOCK_EX ==2, or LOCK_UN ==8, LOCK_NB ==4 
 return($_[0]->{-lock}) if !defined($_[1]);
 my $l =!$_[1] ? LOCK_UN : $_[1];
 my $lv=$l | LOCK_NB ^ LOCK_NB;
 $_[0]->opent() if !$_[0]->{-handle};
 if ($_[0]->{-lock} ne $lv) {
    if ($lv eq LOCK_UN) {
       CORE::flock($_[0]->{-handle}, $_[0]->{-lock} =LOCK_UN);
       if (!defined($_[2])) { $_[0]->{-lcks} ={} }
       else                 { delete $_[0]->{-lcks}->{$_[2]} }
       $l =0; map {$l =$_ if $l <$_} values %{$_[0]->{-lcks}};
       $_[0]->{-lock} =$lv =$l if $l && CORE::flock($_[0]->{-handle}, $l);
    }
    else {
       CORE::flock($_[0]->{-handle}, $_[0]->{-lock} =LOCK_UN);
       $_[0]->{-lock} =$lv if CORE::flock($_[0]->{-handle}, $l);
    }
 }
 if    (!defined($_[2]))	{ $_[0]->{-lcks} ={} }
 elsif ($lv eq LOCK_UN
    ||  $_[0]->{-lock} ne $lv )	{ delete $_[0]->{-lcks}->{$_[2]} }
 else				{ $_[0]->{-lcks}->{$_[2]} =$lv }
 $_[0]->{-lock} eq $lv ? $_[0] : undef
}


sub seek {
  # WHENCE: 0 - SEEK_SET - to set the new position to POSITION, 
  #         1 - SEEK_CUR - to set it to the current position plus POSITION, 
  #         2 - SEEK_END - to set it to EOF plus POSITION 
  return(CORE::tell($_[0]->{-handle})) if @_ <2;
  CORE::seek($_[0]->{-handle}, $_[1], defined($_[2]) ?$_[2] :SEEK_SET) 
   ? $_[0] 
   : (&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
      ("File: seek('" .($_[0]->{-name}||'') ."') -> $!"
	.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
	) ||undef)
}


sub read {
 my $r =CORE::read($_[0]->{-handle}, $_[1], $_[2], $_[3]||0);
 return(&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
        ("File: read('" .($_[0]->{-name}||'') ."') -> $!"
	.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
	) ||undef)
     if !defined($r);
 $r
}


sub readline {
 CORE::readline($_[0]->{-handle})
}


sub print {
 my $s =shift;
 my $h =$s->{-handle};
 return(&{$s->{-parent} ? $s->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
        ("File: print('" .($s->{-name}||'') ."') -> $!"
	.($s->{-parent} && $s->{-parent}->{-ermd} ||'')
	) ||undef)
     if !CORE::print $h @_;
 $s
}

sub load {
 my $b ='';
 my $l =$_[0]->{-lock};
 $_[0]->opent() if !$_[0]->{-handle};
 $_[0]->lock(LOCK_SH) if $l eq LOCK_UN;
 $_[0]->{-buf} =defined($_[0]->seek(0)->read($b, -s $_[0]->{-handle})) ? $b : undef;
 $_[0]->lock(LOCK_UN) if $l eq LOCK_UN;
 defined($_[0]->{-buf}) ? $_[0] : undef;
}


sub store {
 my $s =shift;
 my $l =$s->{-lock};
 $s->opent() if !$s->{-handle};
 $s->lock(LOCK_EX) if $l eq LOCK_UN;
 $s->select(sub{$|=1});
 my $r =$s->seek(0)->print(@_ ? @_ : $s->{-buf}); # !!! simple, may be unsafe
 truncate($s->{-handle}, CORE::tell($s->{-handle}));
 $s->lock(LOCK_UN) if $l eq LOCK_UN;
 $r
}


sub select {
 my $r;
 ref($_[1]) eq 'CODE'
 ? select((select($_[0]->{-handle}), $r =&{$_[1]}(@_))[0]) && $r
 : select($_[0]->{-handle})
}



#########################################################
# DB_File ISAM Handle Object
#########################################################



package DBIx::Web::dbmHandle;
use strict;
use Symbol;
use Fcntl qw(:DEFAULT :flock :seek :mode);

# my	$NLEN	=20;		# length to pad left index numbers

sub new {
  my ($c, %o) =@_;
  my $s ={-name  =>''		# file name
	 ,-mode  =>O_CREAT|O_RDWR
	 ,-parent=>undef	# parent object
	#,-table =>undef	# data table description
	 ,-handle=>undef	# tied object ref
	#,-data  =>undef	# tied data hash ref
	#,-new   =>undef	# new file created
	#,-fh    =>undef	# file handle
	 ,-lock  =>LOCK_UN	# lock level
	 ,-lcks  =>{}		# locks
	 ,-pair  =>[]		# current key/value
         };
  foreach my $k (keys(%o)) {$s->{$k} =$o{$k}}
  bless $s, $c;
  $s->open if defined($s->{-name}) && $s->{-name} ne '';
  $s
}


sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($s, %o) =@_;
 foreach my $k (keys(%o)) {$s->{$k} =$o{$k}};
 $s
}


sub parent {
 $_[0]->{-parent}
}


sub open {
 eval('use DB_File');
 my $s =shift;
 if    (!@_) {}
 elsif ($_[0] =~/^-(name|mode)$/) {$s->set(@_)}
 else  {foreach my $k ('-mode','-name') {$s->{$k} =shift if defined($_[0])}}

 my %hash;
 my $par =eval('new DB_File::BTREEINFO');
 if ($s->{-table} && $s->{-table}->{-keycmp}) {
    my $t =$s->{-table}->{-keycmp};
    $par->{'compare'} =sub{&t($s, map {[map {m/^ *(.*)$/ ? $1 : $_} split /\x00/, $_]} @_)}
                                  # see keyUnescape below
 }
 $s->{-new}    =!-e $s->{-name};
 $s->{-handle} =tie %hash, 'DB_File', $s->{-name}, $s->{-mode}, 0x666, $par;
 $s->{-data}   =\%hash;
 $s->{-lcks}   ={};

 if (!$s->{-handle}) {
    $s->{-handle} =$s->{-data} =undef;
    return(&{$s->{-parent} ? $s->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
           ("DBFile: open('" .($s->{-mode}||'') ."','" .($s->{-name}||'') ."') -> $!"
		.($s->{-parent} && $s->{-parent}->{-ermd} ||'')
		) ||undef)
 }
 $s
}


sub opent {
 return($_[0]) if $_[0]->{-handle};
 $_[0]->open || return(undef);
 $_[0]->lock($_[0]->{-lock}) if $_[0]->{-lock} ne LOCK_UN;
 $_[0]
}


sub close {
 return($_[0]) if !$_[0]->{-handle};
 $_[0]->lock(LOCK_UN) if $_[0]->{-lock} ne LOCK_UN;
 close($_[0]->{-fh})  if $_[0]->{-fh};
 my $h =$_[0]->{-data};
 $_[0]->{-data}   =undef;
 $_[0]->{-handle} =undef;
 $_[0]->{-fh}     =undef;
 $_[0]->{-lcks}   ={};
#eval {untie %$h}; # warning if another reference exists
 $_[0]
}


sub sync {
 return($_[0]) if !$_[0]->{-handle};
 $_[0]->{-handle}->sync();
}


sub destroy {
 eval{$_[0]->close} if $_[0]->{-handle};
 $_[0]->{-parent} =undef;
 $_[0]->{-table}  =undef;
 $_[0]
}


sub DESTROY {
 destroy(@_)
}


sub lock  { # lock value, ?lock key
 # LOCK_SH ==1; LOCK_EX ==2, or LOCK_UN ==8, LOCK_NB ==4 
 return($_[0]->{-lock}) if !defined($_[1]);
 my $l =!$_[1] ? LOCK_UN : $_[1];
 my $lv=$l | LOCK_NB ^ LOCK_NB;
 if (!$_[0]->{-fh} && !CORE::open($_[0]->{-fh} =Symbol::gensym, '+<&=' .$_[0]->{-handle}->fd)) {
    $_[0]->{-fh} =undef;
    return(&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
           ("DBFile: open('+<&=','" .($_[0]->{-name}||'') ."') -> $!"
		.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
		) ||undef)
 }
 if ($_[0]->{-lock} ne $lv) {
    $_[0]->{-handle}->sync;
    if ($lv eq LOCK_UN) {
       CORE::flock($_[0]->{-fh}, $_[0]->{-lock} =LOCK_UN);
       if (!defined($_[2])) { $_[0]->{-lcks} ={} }
       else                 { delete $_[0]->{-lcks}->{$_[2]} }
       $l =0; map {$l =$_ if $l <$_} values %{$_[0]->{-lcks}};
       $_[0]->{-lock} =$lv =$l if $l && CORE::flock($_[0]->{-fh}, $l);
    }
    else {
       CORE::flock($_[0]->{-fh}, $_[0]->{-lock} =LOCK_UN);
       $_[0]->{-lock} =$lv if CORE::flock($_[0]->{-fh}, $l);
    }
    $_[0]->{-handle}->sync;
 }
 if    (!defined($_[2]))	{ $_[0]->{-lcks} ={} }
 elsif ($lv eq LOCK_UN
    ||  $_[0]->{-lock} ne $lv )	{ delete $_[0]->{-lcks}->{$_[2]} }
 else				{ $_[0]->{-lcks}->{$_[2]} =$lv }
 $_[0]->{-lock} eq $lv ? $_[0] : undef
}



sub keyGet {
 return($_[0]->{-pair}->[1]) if @_ <2;
 my $v; $_[0]->{-handle}->get($_[1], $v) ? undef : $v
}


sub keyPut {
 $_[0]->{-handle}->put($_[1], $_[$#_])
 ? (&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
    ("DBFile: keyPut('" .($_[0]->{-name}||'') ."','" .$_[1] ."') -> $!"
	.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
	) ||undef)
 : (@_ >3) && ($_[1] ne $_[2]) && $_[0]->{-handle}->del($_[2])
 ? (&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
    ("DBFile: keyDel('" .($_[0]->{-name}||'') ."','" .$_[2] ."') -> $!"
	.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
	) ||undef)
 : $_[$#_]
}


sub keyDel {
 $_[0]->{-handle}->del(@_[1..$#_]) ? undef : $_[0]
}


sub keyFind {
 my ($s, $k, $v) =@_; 
 $s->{-handle}->seq($k, $v, R_CURSOR()) ? undef : (@{$s->{-pair}}[1,0]=($k,$v))[0]
}


sub keyFirst {
 my ($s, $k, $v) =@_; 
 $s->{-handle}->seq($k, $v, R_FIRST())  ? undef : (@{$s->{-pair}}[1,0]=($k,$v))[0]
}


sub keyLast {
 my ($s, $k, $v) =@_;
 $s->{-handle}->seq($k, $v, R_LAST())   ? undef : (@{$s->{-pair}}[1,0]=($k,$v))[0]
}


sub keyPrev {
 my ($s, $k, $v) =@_;
 $s->{-handle}->seq($k, $v, R_PREV())   ? undef : (@{$s->{-pair}}[1,0]=($k,$v))[0]
}


sub keyNext {
 my ($s, $k, $v) =@_;
 $s->{-handle}->seq($k, $v, R_NEXT())   ? undef : (@{$s->{-pair}}[1,0]=($k,$v))[0]
}


sub krEscape {
 join "\x00"
 ,map {	my $v =$_; 
	return('') if !defined($v);		# !!! lost undefined values
	$v =~s/^ *(.*?) *$/$1/;			# !!! lost extra blanks
      # $v =~s/\000/\\000/g;			# !!! key compare problem
	$v =~s/\000//g;				# !!! lost \x00 chars
	$v =' ' x ($NLEN -length($v)) .$v 	# !!! $NLEN-sign numbers
	   if $v =~/^[\d .,]+$/m && length($v) <$NLEN;
	$v
      } @{$_[1]}
}


sub krEscapeMv {
 my $r =[''];
 foreach my $v (@{$_[1]}) {
   if    (!ref($v)) {
       $v ='' if !defined($v);			# !!! lost undefined values
       $v =~s/^ *(.*?) *$/$1/;			# !!! lost extra blanks
       $v =~s/\000//g;				# !!! lost \x00 chars
       $v =' ' x ($NLEN -length($v)) .$v	# !!! $NLEN-sign numbers
          if $v =~/^[\d .,]+$/m && length($v) <$NLEN;
       map {$_ .=$v ."\x00"} @$r
   }
   elsif (ref($v) eq 'ARRAY') {
     my $r0 =$r; $r =[];
     my $a  =$v;
     foreach my $k (@$a) {
       foreach my $e (@{krEscapeMv($_[0],$k)}) {
         foreach my $v (@$r0) { push @$r, "$v$e\x00" }
       }
     }
   }
   elsif (ref($v) eq 'HASH') {
     my $r0 =$r; $r =[];
     my $h  =$v;
     foreach my $k (keys %$h) {
       my $v =$k;
       $v ='' if !defined($v);		# !!! lost undefined values
       $v =~s/^ *(.*?) *$/$1/;		# !!! lost extra blanks
       $v =~s/\000//g;			# !!! lost \x00 chars
       foreach my $e (@{krEscapeMv($_[0], $h->{$k})}) {
         foreach my $v (@$r0) { push @$r, $v . "$k=>$e\x00" }
       }
     }
   }
 }
 map {chop $_} @$r;
 $r
}


sub krUnescape {
	[map {m/^ *(.*)$/ ? $1 : $_} split /\x00/, $_[$#_]]
}


sub klUnescape {
	map {m/^ *(.*)$/ ? $1 : $_} split /\x00/, $_[$#_]
}


sub hrEscape {		# freeze($_[$#_])
	ref($_[$#_]) ne 'ARRAY'
	? '{' .join(','
		, map {	my ($k, $v) =($_, $_[$#_]->{$_});
			$k =~s/([,=%\\\]\[\{\}])/sprintf("\\x%02x",ord($1))/eg;
			if	(ref($v)) {$v =hrEscape($v)}
			else	{$v =~s/([,=%\\\]\[\{\}])/sprintf("\\x%02x",ord($1))/eg}
			"$k=$v"
			} grep {defined($_[$#_]->{$_})
				} keys %{$_[$#_]}) .'}'
	: '[' .join(','
		, map {	my $k =$_;
			$k =~s/([,=%\\\]\[\{\}])/sprintf("\\x%02x",ord($1))/eg;
			$k
			} grep {defined($_)
				} @{$_[$#_]}) .']'
}

sub hrUnescape {	# thaw($_[$#_])
	$_[$#_] =~/^\{/ ? {hlUnescape(@_)} : $_[$#_] =~/^\[/ ? [hlUnescape(@_)] : $_[$#_]
}

sub hlUnescape {	# %{thaw($_[$#_])}
 if (ref($_[$#_])) {
	my $k;
	while ($k =each %{$_[$#_]}) {$_[$#_]->{$k} =undef};
	$k =undef;
	foreach (split / *[,=] */, ($_[$#_-1] =~/^[\{\[]/ ? substr($_[$#_-1], 1, -1) : $_[$#_-1])) {
			/^\[\{\[]/
			? hrUnescape($_[0], $_)
			: s/\\x([0-9a-fA-F]{2})/chr hex($1)/eg;
		if ($k)	{$_[$#_]->{$k} =$_; $k =undef}
		else	{$k =$_}
	}
	$_[$#_];
 }
 else {	
	$_[$#_] =~/^[\{\[]/
	? (map {	/^\[\{\[]/
			? hrUnescape($_[0], $_)
			: s/\\x([0-9a-fA-F]{2})/chr hex($1)/eg;
		} split / *[,=] */, substr($_[$#_], 1, -1))
	: ($_[$#_])
 }	
}


sub keGet {
 return($_[0]->{-pair}->[1]) if @_ <2;
 my $v; $_[0]->{-handle}->get(krEscape($_[0], $_[1]), $v) ? undef : hrUnescape($v)
}


sub kePut {
 my $r =0;
 my $d =hrEscape($_[$#_]);
 if (@_ >3) {
	my $kn =krEscapeMv($_[0], $_[1]);
	my $ko =krEscapeMv($_[0], $_[2]);
	foreach my $k (@$kn) {
		$_[0]->{-handle}->put($k, $d)
		&& (&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
		("DBFile: kePut('" .($_[0]->{-name}||'') ."','$k') -> '$!'"
			.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
			) ||undef);
		$r +=1;
	}
	foreach my $k (grep {my $v =$_; !grep {$v eq $_} @$kn} @$ko) {
		$_[0]->{-handle}->del($k)
	}
 }
 else {
	foreach my $k (@{krEscapeMv($_[0], $_[1])}) {
		$_[0]->{-handle}->put($k, $d)
		&& (&{$_[0]->{-parent} ? $_[0]->{-parent}->{-die} : $DBIx::Web::LNG->{-die}}
		("DBFile: kePut('" .($_[0]->{-name}||'') ."','$k') -> '$!'"
			.($_[0]->{-parent} && $_[0]->{-parent}->{-ermd} ||'')
			) ||undef);
		$r +=1;
	}
 }
 $r
}


sub keDel {
 my $r =0;
 foreach my $k (@{krEscapeMv($_[0], $_[1])}) {
    $_[0]->{-handle}->del($k) ||($r +=1)
 }
 $r ||undef
}



sub keSeek {
 my ($s, $flg, $sca, $subf, $subw) =@_;
    # dir/cmp, keyArray, subFilter, subEval
 my $p   =$s->parent;
 my $val =undef;
 my $dbh =$s->{-handle};
 my $dbs =0;
 my @kds =map {!ref($_) ? $_ : $_->[0]} @{$s->{-table}->{-key}} # , '_rid'
          if $s->{-table} && $s->{-table}->{-key};
 my ($r, $k) =({}, []); # record hash & key array refs
 my $ca  =0;
 my $subr=sub{undef};

 foreach my $sck (@{$s->krEscapeMv($sca)}) {
   my $key =$sck;
   my $scl =length($sck);
   if    ($flg =~/^-*[af]eq/i)    { # forward  eq
         $dbs =$dbh->seq($key, $val, R_CURSOR());
         $subr=sub{do {	return(undef) unless !$dbs && (defined($key) ? $sck eq substr($key, 0, $scl) : 0);
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_NEXT());
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[af]g[te]/i) { # forward  g[te]
         $key .="\x01" if $flg =~/gt$/i;
	 $dbs =$dbh->seq($key, $val, R_CURSOR());
         $subr=sub{do {	return(undef) unless !$dbs;
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_NEXT());
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[af]l[te]/i) { # forward  l[te]
	 $dbs =$dbh->seq($key, $val, R_FIRST());
         $subr=sub{do {	return(undef) unless !$dbs
			&& (!defined($key) ? 0 
  			   :  $flg=~/lt$/i ? $sck lt substr($key, 0, $scl) 
  					   : $sck le substr($key, 0, $scl));
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_NEXT());
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[af]all/i) {   # forward  all
	 $dbs =$dbh->seq($key, $val, R_FIRST());
         $subr=sub{do {	return(undef) unless !$dbs;
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_NEXT());
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[bd]eq/i)    { # backward eq
         $key .="\x01";
         $dbs =$dbh->seq($key, $val, R_CURSOR());
	 $dbs =$dbh->seq($key, $val, R_PREV());
         $subr=sub{do {	return(undef) unless !$dbs
			&& (defined($key) ? $sck eq substr($key, 0, $scl) : 0);
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_PREV())
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[bd]l[te]/i) { # backward l[te]
         $key .="\x01" if $flg =~/le$/i;
         $dbs =$dbh->seq($key, $val, R_CURSOR());
	 $dbs =$dbh->seq($key, $val, R_PREV());
         $subr=sub{do {	return(undef) unless !$dbs;
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_PREV())
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[bd]g[te]/i) { # backward g[te]
	 $dbs =$dbh->seq($key, $val, R_LAST());
         $subr=sub{do {	return(undef) unless !$dbs
			&& (!defined($key) ? 0 
  			   :  $flg=~/gt$/i ? $sck gt substr($key, 0, $scl) 
  					   : $sck ge substr($key, 0, $scl));
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_PREV())
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
   elsif ($flg =~/^-*[bd]all/i) {   # backward all
	 $dbs =$dbh->seq($key, $val, R_LAST());
         $subr=sub{do {	return(undef) unless !$dbs;
			$r =hlUnescape($s, $val, $r);
			@$k=klUnescape($s, $key);
			@$r{@kds}=@{$k} if @kds && !@$r{@kds};
			$dbs     =$dbh->seq($key, $val, R_PREV())
		} while  ($subf && !&$subf($s, $k, $r))
		     ||  ($subw && ++$ca && &$subw($s, $k, $r));
	  	$r }
   }
 }
 $subr =DBIx::Web::dbmCursor->new($subr, -rec=>$r, -key=>$k);
 if ($subw) {$subr->call; $subr =$ca};
 $subr
}


sub keScan {
 &{shift->parent->{-die}}("DBFile: 'keScan' not implemented yet!")
}



#########################################################
# Condition code block object, use isa($object,'CODE') !
#########################################################


package DBIx::Web::ccbHandle;
use strict;

sub new {
  my ($c, $e) =@_;
  if (!ref($e)) { # string to safe evaluate
     my $c =$e;
     my $m =eval('use Safe; Safe->new()');
	eval{local $^W =0; $m->permit_only(qw(:default :base_core :browse))};
        eval{local $^W =0; $m->share('@_', '$DBIx::Web::SELF')};
     my $o =$DBIx::Web::SELF;
     $e =sub{	local ($DBIx::Web::SELF, $^W) =($o, 0);
		$m->reval($c)};
  }
  bless $e, $c;
  $e
}


sub call { &{$_[0]}(@_[1..$#_]) }

sub fetch{ &{$_[0]}(@_[1..$#_]) }

sub eval { CORE::eval{&{$_[0]}(@_[1..$#_])} }



#########################################################
# DBM Cursor object
#########################################################


package DBIx::Web::dbmCursor;
use strict;

sub new {
  my ($c, $e) =@_;
  my $s={''=>$e, -rfl=>undef, @_[2..$#_]};
	# -rec=>{}, -key=>[], -rfr=>[]; -query=>{}
  bless $s, $c;
  $s
}

sub setcols {
 $_[0]->{NAME_db} =[map {!ref($_) ? $_ : ref($_) ne 'HASH' ? $_->[0] : (defined($_->{-expr}) ? $_->{-expr} : $_->{-fld})} ref($_[1]) ? @{$_[1]} : @_[1..$#_]];
 $_[0]->{NAME}	  =[map {!ref($_) ? $_ : ref($_) ne 'HASH' ? $_->[1] : $_->{-fld}} ref($_[1]) ? @{$_[1]} : @_[1..$#_]];
 $_[0]->{-rfr}	  =[map {$_[0]->{-rec}->{$_} =undef if !exists($_[0]->{-rec}->{$_});
			 \($_[0]->{-rec}->{$_})
			} @{$_[0]->{NAME_db}}] if $_[0]->{-rec};
 $_[0]->{-rfl}	  =[];	# record fields list
 $_[0]
}

sub call { 
	&{$_[0]->{''}}(@_[1..$#_])
}

sub eval { 
	CORE::eval{&{$_[0]->{''}}(@_[1..$#_])}
}

sub fetch { 
	my $v =&{$_[0]->{''}}(@_[1..$#_]);
	if ($v) {@{$_[0]->{-rfl}} =map {$$_} @{$_[0]->{-rfr}}; $_[0]->{-rfl}}
	else	{@{$_[0]->{-rfl}} =(); undef}
}

sub fetchrow_arrayref {
	my $v =&{$_[0]->{''}}(@_[1..$#_]);
	if ($v) {@{$_[0]->{-rfl}} =@${v}{@{$_[0]->{NAME_db}}}; $_[0]->{-rfl}}
	else	{@{$_[0]->{-rfl}} =(); undef}
}

sub fetchrow_hashref {
	$_[0]->{-rec} =&{$_[0]->{''}}(@_[1..$#_]);
}

sub finish {
 $_[0]->{''} =undef;
}

sub close {
 $_[0]->{''} =undef;
}


#########################################################
# DBI Cursor object implementing filtering sub{}
#########################################################


package DBIx::Web::dbiCursor;
use strict;
use vars qw($AUTOLOAD);

sub new {
  my ($c, $i) =@_;
  my $s={''=>$i, @_[2..$#_]};
	# -rec=>{}, -rfr=>[], -flt=>sub{}; -query=>{}
  eval{$s->{'NAME'}=$s->{''}->{'NAME'}} 
	if ref($s->{''});
  bless $s, $c;
  $s
}


sub fetch { 
	return($_[0]->{''}->fetch(@_[1..$#_])) if !$_[0]->{-flt};
	my ($r, $k);
	while (1) {
		while ($k = each %{$_[0]->{-rec}}) {$_[0]->{-rec}->{$k} =undef};
		$r =$_[0]->{''}->fetch(@_[1..$#_]);
		last	if !$r || !$_[0]->{-flt} 
			|| &{$_[0]->{-flt}}($_[0],undef,$_[0]->{-rec})
	}
	$r
}

sub fetchrow_arrayref {
	return($_[0]->{''}->fetchrow_arrayref(@_[1..$#_])) if !$_[0]->{-flt};
	my ($r, $k);
	while (1) {
		while ($k = each %{$_[0]->{-rec}}) {$_[0]->{-rec}->{$k} =undef};
		$r =$_[0]->{''}->fetchrow_arrayref(@_[1..$#_]);
		last	if !$r || !$_[0]->{-flt} 
			|| &{$_[0]->{-flt}}($_[0],undef,$_[0]->{-rec})
	}
	$r
}

sub fetchrow_hashref {
	return($_[0]->{''}->fetchrow_hashref(@_[1..$#_])) if !$_[0]->{-flt};
	my ($r, $k);
	while (1) {
		while ($k = each %{$_[0]->{-rec}}) {$_[0]->{-rec}->{$k} =undef};
		$r =$_[0]->{''}->fetchrow_hashref(@_[1..$#_]);
		last	if !$r || !$_[0]->{-flt} 
			|| &{$_[0]->{-flt}}($_[0],undef,$_[0]->{-rec})
	}
	$r
}


sub finish {
 $_[0]->{''}->finish(@_[1..$#_])
}


sub close {
	eval {$_[0]->{''}->finish(@_[1..$#_])};
	$_[0]->{''}=undef;
}


sub AUTOLOAD {
	my $m =substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
	confess("!object in AUTOLOAD of $AUTOLOAD") if !ref($_[0]);
	$_[0]->{''}->$m(@_[1..$#_])
}


#########################################################
# UINION cursor/container operation cursor
#########################################################


package DBIx::Web::dbcUnion;
use strict;

sub new {	# UNION peration cursor
 my $c =shift;	# (option=>value,...{hash data} || [array data] || cursor,...)
 my $s={ -i	=>[]		# cursors or arrays, hashes are sorted to arrays
	,-j	=>[]		# indexes of arrays
	,-d 	=>[]		# data buffers
	,-asc 	=>1		# ascending order
	,-lc	=>1		# lowercase order compare
	,-rl	=>undef		# right to left compare (for internal/external values)
	,-all	=>undef		# non unique, records may be duplicated
	,-rec	=>{}		# out record as hash
	,-rfr	=>[]		# out record as array
	,0	=>undef		# inited mark
	,'NAME'	=>undef		# column names, may be obtained from cursor or not used
	};
 while (defined($_[0])) {
	if (!ref($_[0])) {
		$s->{shift(@_)} =shift(@_)
	}
	else {
		push @{$s->{-i}}, shift(@_)
	}
 }
 if (!$s->{'NAME'}) {
	foreach my $e (@{$s->{-i}}) {
		next if !$e || (ref($e) =~/^(?:ARRAY|HASH)$/);
		eval{$s->{'NAME'}=$e->{'NAME'} if ref($e->{'NAME'})};
		last if $s->{'NAME'}
	}
 }
 if (ref($s->{'NAME'})) {eval{
	@{$s->{-rec}}[@{$s->{NAME}}] =();
	@{$s->{-rfr}} =map {\($s->{-rec}->{$_})} @{$s->{NAME}};
 }}
 bless $s, $c;
 $s
}


sub fetch { 
 my $s =$_[0];
 return(undef) if !defined($s->{-i}) || !defined($s->{-rfr});
 if (!$s->{0}) {	# init processing
	$s->{0} =1;
	for (my $i =0; $i <=$#{$s->{-i}}; $i++) {
		if (ref($s->{-i}->[$i]) eq 'HASH') {
			use locale;
			my $h =$s->{-i}->[$i];
			$s->{-i}->[$i] =[
				map {[$_, $h->$_]
					} sort { $s->{-asc}
						? lc($h->{$a}) cmp lc($h->{$b})
						: lc($h->{$b}) cmp lc($h->{$a})
						} keys %$h
				];
			$s->{-rl} =1 if !defined($s->{-rl});
		}
		if (ref($s->{-i}->[$i]) eq 'ARRAY') {
			$s->{-d}->[$i]		=[];
			@{$s->{-d}->[$i]}	=ref($s->{-i}->[$i]->[0])
						? @{$s->{-i}->[$i]->[0]}
						: $s->{-i}->[$i]->[0];
			$s->{-j}->[$i]		=0;
		}
		elsif ($s->{-i}->[$i]) {
			if (!$s->{'NAME'}) {
				eval{$s->{'NAME'}=$s->{-i}->[$i]->{'NAME'} if ref($s->{-i}->[$i]->{'NAME'})};
				if (ref($s->{'NAME'})) {eval{
					@{$s->{-rec}}[@{$s->{NAME}}] =();
					@{$s->{-rfr}} =map {\($s->{-rec}->{$_})} @{$s->{NAME}};
				}}
			}
			$s->{-d}->[$i] =$s->{-i}->[$i]->fetch(@_[1..$#_]);
		}
		else {
			$s->{-d}->[$i] =undef;
		}
	}
 }
 my $m =undef;
 for (my $i =0; $i <=$#{$s->{-i}}; $i++) {
	if (!defined($s->{-d}->[$i])) {
		next
	}
	elsif (!defined($m)) {
		$m =$i;
		next;
	}
	my ($vm, $vc) =($s->{-d}->[$m], $s->{-d}->[$i]);
	my ($ce, $cc) =(1, 0);
	my $j =$s->{-rl} ? $#{$vc} : 0;
	{use locale;
	while(1) {
		$ce =0 	if $ce 
			&& (	  !defined($vm->[$j]) && !defined($vc->[$j])
				? undef
				: !defined($vm->[$j]) || !defined($vc->[$j])
				? 1
				: ($vm->[$j] ne $vc->[$j]));
		$cc =1	if !$cc
			&& ($s->{-asc}
			   ? (	  !defined($vc->[$j]) && !defined($vm->[$j])
				? undef
				: !defined($vc->[$j])
				? 1
				: !defined($vm->[$j])
				? undef
				: ($vc->[$j] =~/^\d+$/) && ($vm->[$j] =~/^\d+$/)
				? $vc->[$j] < $vm->[$j]
				: $s->{-lc}
				? lc($vc->[$j]) lt lc($vm->[$j])
				: $vc->[$j] lt $vm->[$j])
			   : (	  !defined($vc->[$j]) && !defined($vm->[$j])
				? undef
				: !defined($vc->[$j])
				? undef
				: !defined($vm->[$j])
				? 1
				: ($vc->[$j] =~/^\d+$/) && ($vm->[$j] =~/^\d+$/)
				? $vc->[$j] > $vm->[$j]
				: $s->{-lc}
				? lc($vc->[$j]) gt lc($vm->[$j])
				: $vc->[$j] gt $vm->[$j])
			   );
		last if $cc;
		if ($s->{-rl})	{	$j--; last if $j <0		}
		else		{	$j++; last if $j >$#{$vc}	}
	}}
	# print '[', join(';' , map {$_ ? join(',',@$_) : 'u'} @{$s->{-d}}), ']',
	#	$ce || 'ne', $cc ||'nc',"\n";
	if ($cc) {
		$m =$i
	}
	elsif ($ce && $s->{-all}) {
	}
	elsif ($ce) {
		if (ref($s->{-i}->[$i]) ne 'ARRAY') {
			$s->{-d}->[$i] =$s->{-i}->[$i]->fetch(@_[1..$#_])
		}
		elsif (++$s->{-j}->[$i] >$#{$s->{-i}->[$i]}) {
			$s->{-d}->[$i] =undef;
			$s->{-j}->[$i] =$#{$s->{-i}->[$i]} +1;
		}
		elsif (ref($s->{-i}->[$i]->[$s->{-j}->[$i]])) {
			@{$s->{-d}->[$i]} =@{$s->{-i}->[$i]->[$s->{-j}->[$i]]}
		}
		else {
			$s->{-d}->[$i]->[0] =$s->{-i}->[$i]->[$s->{-j}->[$i]]
		}
	}
 }	
 if (!defined($m)) {
	return($s->{-rfr} =undef)
 }
 else {
		@{$s->{-rfr}}	=@{$s->{-d}->[$m]};
		# $s->{-rfr}->[0] =$m .' ' .$s->{-rfr}->[0];
		# @{$s->{-rec}}[@{$s->{'NAME'}}] =@{$s->{-d}->[$m]}
		#		if $s->{'NAME'};
		my $i =$m;
		if (ref($s->{-i}->[$i]) ne 'ARRAY') {
			$s->{-d}->[$i]	=$s->{-i}->[$i]->fetch(@_[1..$#_])
		}
		elsif (++$s->{-j}->[$i] >$#{$s->{-i}->[$i]}) {
			$s->{-d}->[$i] =undef;
			$s->{-j}->[$i] =$#{$s->{-i}->[$i]} +1;
		}
		elsif (ref($s->{-i}->[$i]->[$s->{-j}->[$i]])) {
			@{$s->{-d}->[$i]} =@{$s->{-i}->[$i]->[$s->{-j}->[$i]]}
		}
		else {
			$s->{-d}->[$i]->[0] =$s->{-i}->[$i]->[$s->{-j}->[$i]]
		}
	return($s->{-rfr})
 }
}


sub fetchrow_arrayref {
	$_[0]->fetch(@_[1..$#_])
}


sub fetchrow_hashref {
	$_[0]->fetch(@_[1..$#_])
	&& $_[0]->{-rec}
}


sub finish {
 my $s=$_[0];
 return($s) if !$s->{-i};
 foreach my $e (@{$s->{-i}}) {
	eval{$e->finish()} if $e && (ref($e) !~/^(?:ARRAY|HASH)$/)
 }
 $s
}


sub close {
 $_[0]->finish();
 $_[0]->{-i} =undef;
 $_[0]
}


sub DESTROY {
 eval{$_[0]->close()}
}
