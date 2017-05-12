#!perl -w
#
# admiral 
# 16/12/2001
#
# 

package CGI::Bus::lngbase::CGI_Bus_ru; # Language base
use CGI::Bus::lngbase::CGI_Bus;
use strict;


1;

sub lngbase {
 my @msg =CGI::Bus::lngbase::CGI_Bus::lngbase;
 push @msg,
 ('Warning' =>['Предупреждение', 'Предупреждение о неисправности']
 ,'Error'   =>['Ошибка',         'Ошибка пользователя или приложения']
 );
 @msg
}

