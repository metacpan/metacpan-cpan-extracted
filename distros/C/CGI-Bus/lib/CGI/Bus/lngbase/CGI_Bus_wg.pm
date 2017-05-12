#!perl -w
#
# admiral 
# 30/01/2002
#
# 

package CGI::Bus::lngbase::CGI_Bus_wg; # Language base
use strict;

1;

sub lngbase {
 ('ddlbopen'    =>['...',   'open']
 ,'ddlbfind'    =>['..',    'find']
 ,'ddlbclose'   =>['x',     'close']
 ,'ddlbsetvalue'=>['<',     'set value']
 ,'Files'       =>['Files', 'Files attached']
 ,'+|-'         =>['+/-',   'Add / Close / Delete']
 ,'fsopens'	=>['...',   'Files opened']
 ,'fsclose'	=>['Close', 'Close files choosen']
 ,'fsbrowse'	=>['Browse','Choose file to upload']
 ,'fsdelmrk'	=>['DelMark','Mark to delete']
 )
}

