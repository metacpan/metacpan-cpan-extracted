#!perl -w
#
# User Personal WorkSpace
#
# <Directory />
# DirectoryIndex cgi-bin/cgi-bus/upws.cgi index.html
# </Directory>
#
use vars qw($s);
$s = do("../config.pl");
$s->set('-htmlstart')->{-title}  =$s->server_name() .' - WorkSpace';

$s->upws->set(-logo   =>undef            # logotype
             ,-index  =>'/index.html'    # site index
           # ,-uspath =>$s->hpath        # users sites base path, autodetect
           # ,-usurl  =>$s->hurl         # users sites base URL
           # ,-uspurf =>$s->hurf         # users sites publish filesystem URL
             ,-usfirst=>sub{/manager/i}  # dirs to sort first
             );

$s->upws->set(-indexes=>[                # most common URLs
 #'FAQ|' .$s->burl('notes.cgi','_tcb_cmd'=>'-lst','_tsw_LIST'=>'AllHier')
  $s->a({-href=>$s->burl('notes.cgi','_tcb_cmd'=>'-lst','_tsw_LIST'=>'AllHier'), -title=>'Frequently Asked Questions'}
       ,'<img src="/icons/small/unknown.gif" border=0 />FAQ')
  ]);
 
$s->upws->set(-urlst=>[                  # most common URLs
  'Notes|'     .$s->burl('notes.cgi')
 ,'Organizer|' .$s->burl('gwo.cgi')
  ]);

$s->upws->set(-urls=>[                   # most common URLs
  ]);


$s->upws->evaluate;

