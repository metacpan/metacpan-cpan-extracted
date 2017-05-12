#!perl -w
#
# admiral 
# 30/01/2002
#
# 

package CGI::Bus::lngbase::CGI_Bus_wg_ru; # Language base
use CGI::Bus::lngbase::CGI_Bus_wg;
use strict;

1;

sub lngbase {
 my @msg =CGI::Bus::lngbase::CGI_Bus_wg::lngbase;
 push @msg,
 ('ddlbopen'     =>['...',   'открыть']
 ,'ddlbfind'     =>['..',    'найти']
 ,'ddlbclose'    =>['x',     'закрыть']
 ,'ddlbsetvalue' =>['<',     'присвоить значение']
 ,'Files'        =>['Файлы', 'Присоединенные файлы']
 ,'+|-'          =>['+/-',   'Добавить / Закрыть / Удалить']
 ,'fsopens'	 =>['...',   'Открытые файлы']
 ,'fsclose'	 =>['Закрыть','Закрыть выбранные файлы']
 ,'fsbrowse'	 =>['Выбрать','Выбрать присоединяемый файл']
 ,'fsdelmrk'	 =>['Удалить','Выбрать для удаления']
 );
 @msg
}

