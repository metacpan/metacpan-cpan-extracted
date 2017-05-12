#!perl -w
#
#
BEGIN {}
#
# Common configuration for all CGI::Bus applications
#
# use findgrp.exe on Windows NT !!!
#
use CGI::Bus;
use vars qw($s $a);
$s =CGI::Bus->new($s);   # CGI::Bus object
$a ='';                  # root application directory

 $ENV{COMPUTERNAME} =eval{Win32::NodeName()} if $^O eq 'MSWin32' 
                                            and !$ENV{COMPUTERNAME};

 $s->set  (-iurl  => '/icons'                   # apache images
	# ,-tpath => "$a/tmp"                   # temporary files path
          ,-dpath => $a);                       # data files path
 $s->udata(-path=>$s->dpath('udata'));          # users data path

 $s->set  (-ppath => undef                      # publish path, unused yet
          ,-purl  => undef);                    # publish URL,  unused yet

 $s->set  (-fpath => "$a/files"                 # files attachments path, may be -ppath
          ,-furf  => 'file://' .($ENV{COMPUTERNAME} ||$s->server_name) .'/cgi-bus');
 $s->set  (-furl  => '/cgi-bus');               # files attachments URL

 $s->set  (-hpath => "$a/users"                 # users home dirs path
          ,-hurf  =>                            # home  dirs filesystem URL
                     'file://' .($ENV{COMPUTERNAME} ||$s->server_name) .'/users');
 $s->set  (-hurl  => '/users');                 # home  dirs URL

 $s->set  (-urfcnd=>                            # filesystem URLs usage condition
                     sub{$ENV{REMOTE_ADDR} =~/^(127)\./});

#$s->set  (-login=>'/cgi-bin/cgi-bus/auth/uauth.cgi'); # login script
 $s->set  (-login=>'/cgi-bin/cgi-bus/auth/');	# login directory


 $s->set  (-usercnv=>sub{lc($_[0]->usercn($_))} # user names conversion
        # ,-ugrpcnv=>sub{$_[0]->usercn($_)}     # group names conversion
	# ,-ugrpadd=>sub{['Everyone','Guests']}	# additional groups
          ,-uadmins=>[]                         # admin users
          );

 $s->set(-debug  =>1);                          # debug switch
#$s->set(-pushlog=>$s->tpath('pushlog.txt'));   # log file

 $s->set  (-import=>                            # DBI connect code
                     {-dbi => sub{$s->dbi("DBI:mysql:cgibus","cgibus","d95nfmJR971Yv3gVI40")}});

$s->set(-httpheader=>{                          # common http header
       #  -charset        => 'windows-1251'
       # '-cache-control' => 'no-cache'         # must-revalidate, max-age=sss
          -expires        => 'now'
       }
       ,-htmlstart=>{                           # common & default html header
          -head  => '<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">'
       # ,-lang  => 'ru-RU'
         ,-title => $s->server_name()
       }
       ,-htpnstart=>{                           # navigator pane html header
          -BGCOLOR => '#C0D9D9'
       }
       ,-htpgstart=>{                           # pages and lists html header
          -BGCOLOR => '#FFF5EE'
       }
       ,-htpfstart=>{                           # form pages html header
          -BGCOLOR => '#FFF5EE'
       }
       );


$s;                                             # return application object
