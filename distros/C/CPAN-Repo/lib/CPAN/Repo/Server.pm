package CPAN::Repo::Server;
use CPAN::Repo;
use Dancer ':syntax';
our $REPO_ROOT;

get '/' => sub { # home page
    set content_type => 'text/html';
    my $ret = '<h1>list of available repos</h1>';
    my @l;	
    for my $i (<$REPO_ROOT/*>){
     next unless -d $i;
     s/.*\/// for $i;
     push @l, $i
    }
    $ret.='<ul>'.( join "\n", map  {"<li><a href=/repo/$_/>$_</a></li>"} @l ).'</ul>'.signature();
    return $ret;
    
};

get '/list/$' => sub { # list of repos (a-la rest api, called from in CPAN::Repo pluggins)
    set content_type => 'text/plain';
    # template 'index';
    my @l; 	
    for my $i (<$REPO_ROOT/*>){
     next unless -d $i;
     s/.*\/// for $i;
     push @l, $i
    }
    return join "\n", @l;
    
};

get qr{/(\S+)/packages\.txt} => sub { # repo packages.txt 
    set content_type => 'text/plain';
    my ($path) =  splat;
    my $ret;
    for my $p (split /\//, $path ){
	$ret.="# $p repository\n";
	if(open F, "$REPO_ROOT/$p/packages.txt"){
	 while (my $l = <F>){
	  $ret.="~$p/$l";
	 }; close F;
	}
	$ret.="\n";
    }
    return $ret;
};

get qr{^/repo/(\w+)/$} => sub { # repo index page
    set content_type => 'text/html';
    my ($cs_id) =  splat;
    my $ret = "<h1><a href='/'>$cs_id</a></h1>\n";
    $ret.="<i><a href='/$cs_id/packages.txt'>packages.txt</a></i><br><br>\n";
    for my $d (<$REPO_ROOT/$cs_id/*.gz>){
      (my $l = $d)=~s/.*\/(.*)/$1/;
      $ret.="<a href='~$cs_id/$l'>$l</a><br>\n";
    }
    $ret.=signature();
    return $ret;
};

get qr{/.*/~(\w+)/(.*\.tar\.gz)} => sub { # distros

    my ($cs_id,$distro) =  splat;
    redirect "$cs_id/$distro"
};

sub signature {
 return "\n\n<hr noshade>cpan repo server version $CPAN::Repo::VERSION</hr>\n\n";
}

1;

