#!perl -w
#http://localhost/cgi-bin/web.cgi
BEGIN {
#push @INC, $1 .'sitel/lib' if !(grep /sitel/i, @INC) && ($INC[0] =~/(.+?[\\\/])lib$/i)
}
$ENV{HTTP_ACCEPT_LANGUAGE} ='';
my $wsdir =$^O eq 'MSWin32' ? Win32::GetFullPathName($0) : $0;
   $wsdir =~s/\\/\//g;
   $wsdir =	  $wsdir =~/^(\w:\/inetpub)\//i
		? $1
		: $wsdir =~/\/cgi-bin\//i
		? $`
		: $ENV{DOCUMENT_ROOT} && $ENV{DOCUMENT_ROOT} =~/[\\\/]htdocs/i
		? $`
		: '../';
   $wsdir =	  $wsdir =~/^(\w:\/inetpub)\//i ? "$wsdir/wwwroot" : "$wsdir/htdocs";

use DBIx::Web;
my $w =DBIx::Web->new(
  -title	=>'DBIx-Web'	# title of application
#,-logo		=>''		# logo html/image
 ,-debug	=>2		# debug level
 ,-serial	=>2		# serial operation level
 ,-dbiarg	=>undef
#,-dbiph	=>1		# dbi placeholders usage
#,-dbiACLike	=>'eq lc'	# dbi access control comparation
 ,-keyqn	=>1		# key query null comparation
#,-path		=>"$wsdir/dbix-web"
#,-url		=>'/dbix-web'	# filestore URL
 ,-urf		=>'-path'	# filestore filesystem URL
#,-fswtr	=>''		# filesystem writers (default is process account)
#,-AuthUserFile	=>''		# apache users file
#,-AuthGroupFile=>''		# apache groups file
#,-login	=>/cgi-bin/ntlm/# login URL
#,-userln	=>0		# short local usernames (0 - off, 1 - default)
 ,-ugadd	=>['Everyone','Guests']		# additional user groups
#,-rac		=>0		# record access control (0 - off, 1 - default)
#,-racAdmRdr	=>''		# record access control admin reader
#,-racAdmWtr	=>''		# record access control admin writer
#,-rfa		=>0		# record file attachments (0 - off, 1 - default)
#,-w32xcacls	=>1		# use 'xcacls' instead of 'cacls'
#,-httpheader	=>{}		# http header arguments
#,-htmlstart	=>{}		# html start arguments
	);

my ($r, $c);
$w->set(-table=>{
	'note'=>{
		 -lbl		=>'Notes'
		,-cmt		=>'Notes'
		,-lbl_ru	=>'Заметки'
		,-cmt_ru	=>'Заметки'
		,-field		=>[
			 {-fld=>'id'
				,-flg=>'kwq'
				,-lblhtml=>$w->tfoShow('id_',['idrm','idpr'])
				}, ''
			,{-fld=>$w->tn('-rvcActPtr')
				,-flg=>'q'
				,-hidel=>$w->tfoHide('id_')
				}
			,{-fld=>'idrm'
				,-flg=>'euq'
				,-hidel=>$w->tfoHide('id_')
				}, ''
			,{-fld=>'idpr'
				,-flg=>'euq'
				,-hidel=>$w->tfoHide('id_')
				}
			,{-fld=>$w->tn('-rvcInsWhen')
				,-flg=>'q'
				}, ''
			,{-fld=>$w->tn('-rvcInsBy')
				,-flg=>'q'
				}
			,{-fld=>$w->tn('-rvcUpdWhen')
				,-flg=>'wql'
				}, ''
			,{-fld=>$w->tn('-rvcUpdBy')
				,-edit=>0
				,-flg=>'wql'
				}
			,{-fld=>'authors'
			,-flg=>'euq'
			,-ddlb=>sub{$_[0]->uglist({})}
			,-ddlbtgt=>[[undef,undef,','],['readers',undef,',']]
			 	}, ''
			,{-fld=>'readers'
			,-flg=>'euq'
			,-ddlb=>sub{$_[0]->uglist({})}
			,-ddlbtgt=>[[undef,undef,','],['authors',undef,',']]
				 }
			,{-fld=>$w->tn('-rvcState')
			,-inp=>{-values=>$w->tn('-rvcAllState')}
			,-flg=>'euql', -null=>undef
				}
			,{-fld=>'subject'
			,-flg=>'euqlm'
			,-colspan=>4
			,-inp=>{-asize=>60}
			# ,-ddlb=>[[1,'one'],2,3,'qw']	# test
				 }
			,"</table>"
			,{-fld=>'comment'
			,-flg=>'eu'
			,-lblhtml=>'<b>$_</b><br />'
			,-inp=>{-htmlopt=>1, -hrefs=>1, -arows=>5, -cols=>70}
				 }
			,$w->tfsAll()
		]
		,$w->ttoRVC()
		,-racReader	=>[qw(readers)]
		,-racWriter	=>[$w->tn('-rvcUpdBy'), $w->tn('-rvcInsBy'), 'authors']
		,-ridRef	=>[qw(idrm idpr comment)]
		,-rfa		=>1
		,-recNew0R	=>sub{	$_[2]->{'idrm'} =$_[3] && $_[3]->{'id'}||'';
					foreach my $n (qw(authors readers)) {
						$_[2]->{$n} =$_[3]->{$n} 
							if $_[3] && $_[3]->{$n};
						$_[0]->recLast($_[1],$_[2],[$_[0]->tn('-rvcUpdBy')],[$n])
							if !$_[2]->{$n};
					}
					$_[2]->{$_[0]->tn('-rvcState')} ='ok';
					$_[0]
				}
		,-query		=>{-order=>'-dall'
				# ,-frmLso=>['author','hierarchy']
				  }
		,-frmLsoAdd	=>[['hierarchy',undef,{-qkeyadd=>{'idrm'=>undef}}]
				  ]
		,-dbd		=>'dbm'
	}
	,$w->ttsAll()
	});

$w->set(-form=>{
	 'default'	=>{-subst=>'index'}
	,$w->tvdIndex()
	,$w->tvdFTQuery()
	,1 ? ('notehier'	=>{
		 -lbl		=>'Notes hierarchy'
		,-cmt		=>'Notes hierarchy'
		,-lbl_ru	=>'Заметки иерархически'
		,-cmt_ru	=>'Иерархия заметок'
		,-table		=>'note'
		,-query		=>{-order=>'-dall'} # -key=>{'idrm'=>undef}
		,-qfilter	=>sub{!$_[4]->{'idrm'}}
		,-frmLsoAdd	=>undef
		}) : ()
	});
$w->set(-index=>1);
$w->set(-setup=>1);
$w->cgiRun();

##############################
# Setup Script
##############################
__END__
#
# Connect as root to mysql, once creating database and user:
#{$_->{-dbi} =undef; $_->{-dbiarg} =['DBI:mysql:mysql','root','password']; $_->dbi; <STDIN>}
#
# Reconnect as operational user, creating or upgrading tables:
#{$_->{-dbi} =undef; $_->{-dbiarg} =$_->{-dbiargpv}; $_->dbi; <STDIN>}
#
# Reindex database:
{$s->recReindex(1)}
#
#
