package Apache::ASP::Load;

use Apache::ASP;
use Apache::ASP::CGI::Table;

use strict;
no strict qw(refs);
use vars qw(@Days @Months $AUTOLOAD $LOADED $COUNT);
@Days = qw(Sun Mon Tue Wed Thu Fri Sat);
@Months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

# we need a different class from Apache::ASP::CGI because we don't
# want to force use of CGI & Class::Struct when loading ASP in Apache
# also a nasty bug doesn't allow us to eval require's or use's, we 
# get a can't start_mutex

sub new {
    my($file) = @_;
    bless {
	current_callback => 'PerlHandler',
	filename => $file,
	remote_ip => '127.0.0.1',
	user => undef,
	method => 'GET',
	NoState => 1,
	headers_in     => Apache::ASP::CGI::Table->new,
	headers_out    => Apache::ASP::CGI::Table->new,
	dir_config     => Apache::ASP::CGI::Table->new,
	subprocess_env => Apache::ASP::CGI::Table->new,
    };
}

sub AUTOLOAD {
    $AUTOLOAD =~ s/^(.*)::([^:]*)$/$2/;
    shift->{$AUTOLOAD};
}

sub log_error { 
    shift; 
    my @times = localtime;
    printf STDERR ('[%s %s %02d %02d:%02d:%02d %d] [error] %s'."\n",
		   $Days[$times[6]],
		   $Months[$times[4]],
		   $times[3],
		   $times[2],
		   $times[1],
		   $times[0],
		   $times[5] + 1900,
		   join('', @_),
		   );
}

sub connection { shift; }

sub Run {
    shift if(ref $_[0] or $_[0] eq 'Apache::ASP');

    local $SIG{__WARN__} = \&Apache::ASP::Warn;
    my($file, $match, %args) = @_;
    unless(-e $file) {
	warn("$file does not exist for loading");
	return;
    }
    $match ||= '.*'; # compile all by default

    # recurse down directories and compile the scripts
    if(-d $file && ! -l $file) {
	$file =~ s|/$||;
	opendir(DIR, $file) || die("can't open $file for reading: $!");
	my @files = readdir(DIR);
	close DIR;
	unless(@files) {
	    Apache::ASP::Load->log_error("[asp] $$ [WARN] can't read files in $file");
	    return;
	}

	my $top;
	if(! defined $LOADED) {
	    $top = 1;
	}
	defined $LOADED or (local $LOADED = 0);
	defined $COUNT or (local $COUNT = 0);
	
	for(@files) {
	    chomp;
	    next if /^\.\.?$/;
	    &Run("$file/$_", $match, %args);
	}
	if($top) {
	    Apache::ASP::Load->log_error("[asp] $$ (re)compiled $LOADED scripts of $COUNT loaded for $file");
	}
	return;
    } 

    # now the real work
    unless($file =~ /$match/) {
	if($args{Debug} and $args{Debug} < 0) {
	    Apache::ASP::Load->log_error("skipping compile of $file no match $match");
	}

	return;
    }

    unless($file =~ /$match/) {
       if($args{Debug} < 0) {
           warn("skipping compile of $file no match $match");
       }
       return;
    }

    my $r = Apache::ASP::Load::new($file);
    for my $key ( 
		 qw( Debug StatINC StatINCMatch ), 
		 @{Apache::ASP->CompileChecksumKeys} 
		) 
      {
	  $r->dir_config->set($key, $args{$key});
      }
    $r->dir_config->set('NoState', 1);

    # RegisterIncludes created for precompilation, on by default here
    $r->dir_config->set('RegisterIncludes', 1);
    if ((defined $args{'RegisterIncludes'})) {
	$r->dir_config->set('RegisterIncludes', $args{'RegisterIncludes'});
    }

    eval {
	$COUNT++;
	my $asp = Apache::ASP->new($r);    

	# if StatINC* is configured, run on first script
	if(($COUNT == 1) && ($asp->config('StatINC') || $asp->config('StatINCMatch'))) {
	    $asp->StatINC;
	}

	my $rv = $asp->CompileInclude($asp->{'basename'})
	  || die($@);

	if($args{'Execute'}) {
	    local $^W = 0;
	    local *Apache::ASP::Response::Flush = sub {};
	    $asp->Run;
	}
	$asp->DESTROY;
	$LOADED++;
    };
    $@ && warn($@);

    return $LOADED;
}

1;
