#!perl -w
#
# Search with Microsoft Index Server
# (independent CGI script)
# (2002-10-25)
#
#
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
my $g =CGI->new;
die('Microsoft IIS required')  if  $ENV{SERVER_SOFTWARE} !~/IIS/;
die('Authentication required') if !$ENV{REMOTE_USER};
print $g->header(-charset => 'windows-1251', -expires => 'now')
    , $g->start_html(-head  => '<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">'
                    ,-lang  => 'ru-RU'
                    ,-title => $g->server_name())
    , $g->startform() # -action=>$g->url
    , $g->hidden('_run'   =>'SEARCH')
    , '<table width="100%"><tr><td>'
    , $g->h1('Поиск')
    , '</td><td align="left" valign="bottom">'
    , 'Поиск в файловой системе ' .$g->server_name() .' (' .($ENV{REMOTE_USER} ||'Guest') .')'
    , '</td></tr></table>'
    , $g->textfield(-name=>'query', -size=>70, -title=>'Условие или текст поиска')
    , $g->submit(-name =>'search'
                ,-value=>'Искать'
                ,-title=>'Искать')
    , '<br />'
    , $g->popup_menu(-name=>'querysort'
                    ,-values=>['write','hitcount','vpath','docauthor']
                    ,-labels=>{'write'    =>'Chronologically'
                              ,'hitcount' =>'Ranked'
                              ,'vpath'    =>'by Name'
                              ,'docauthor'=>'by Author'
                              }
                    ,-default=>'write')
    , $g->popup_menu(-name=>'querymarg'
                    ,-values=>[128,256,512,1024,2048]
                    ,-labels=>{128 =>'128  max'
                              ,256 =>'256  max'
                              ,512 =>'512  max'
                              ,1024=>'1024 max'
                              ,2048=>'2048 max'
                              }
                    ,-default=>256)
    , $g->a({-href=>
          -e ($ENV{windir} .'/help/ix/htm/ixqrylan.htm')
           ? '/help/microsoft/windows/ix/htm/ixqrylan.htm'
           : '/help/microsoft/windows/isconcepts.chm' # .'::/ismain-concepts_30.htm'
           }, '?')
    , $g->endform
    , "\n";


 if (defined($g->param('query')) && $g->param('query') ne '') {
       eval('use Win32::OLE');
       Win32::OLE->Initialize();
     # Win32::OLE->Initialize(&Win32::OLE::COINIT_OLEINITIALIZE);
       # Search MSDN for 'ixsso.Query'; See also:
       # Q248187 "HOWTO: Impersonate a User from Active Server Pages"
       # "Replace a process level token" right
       my $oq =Win32::OLE->CreateObject("ixsso.Query");
       if (!$oq) {
          print "'OLE->CreateObject(ixsso.Query)' failed '$!'/'$@'/",Win32::OLE->LastError;
          exit;
       }
       my $ou =Win32::OLE->CreateObject("ixsso.util");
       if (!$oq) {
          print "'OLE->CreateObject(ixsso.util)' failed '$!'/'$@'/",Win32::OLE->LastError;
          exit;
       }
       my $qs =[];
       my $qt =[];
       $oq->{Query}      =$g->param('query') =~/^(@\w|\{\s*prop\s+name\s+=)/i
                         ? $g->param('query')
                         : ('@contents ' .$g->param('query'));
       $oq->{Catalog}    ='Web';
       $oq->{MaxRecords} =$g->param('querymarg') ||256;
       $oq->{MaxRecords} =4096 if $oq->{MaxRecords} >4096;
       $oq->{SortBy}     =$g->param('querysort') ||'write';
       $oq->{SortBy}    .=$oq->{SortBy} =~/^(write|hitcount)$/i 
                         ? '[d],docauthor[a]' : '[a],write[d]';
       $oq->{Columns}    ='vpath,path,filename,hitcount,write,doctitle,docauthor,characterization';
       $oq->{LocaleID}   =1049; # ru

       my $ol =eval {$oq->CreateRecordset('sequential')}; # 'nonsequential'

       if (!$ol) {
          print "CreateRecordset failure '$@'"; 
          exit;
       }
       if ($ol->{EOF}) {
          print('No records found');
       }
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
            print $g->a({-href=>$vp||$ol->{Path}->{Value}
                        ,-title=>$ol->{HitCount}->{Value} 
                          .': ' .$ol->{Path}    ->{Value}}
                     , $vt)
                     , $ol->{Characterization}->{Value}
                     ? '<br />' .$g->escapeHTML($ol->{Characterization}->{Value})
                     : ''
                     , "<br /><br />\n"
         }
         if (!eval {$ol->MoveNext; 1}) {
            print('Bad query');
            last
         }
       }
       Win32::OLE->FreeUnusedLibraries;
     # Win32::OLE->Uninitialize;
       print $g->hr
           , "Records fetched = $rcd / found = $rcf, vpathgen = $rct / max=" .($oq->{MaxRecords}||'null')
           , "\n";
       eval{warningsToBrowser(1)};
 }
 else  {
   print 'Enter query condition'
 }

print $g->end_html;

