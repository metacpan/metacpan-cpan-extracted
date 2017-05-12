package Apache::MP3;
# $Id: MP3.pm,v 1.52 2006/01/03 19:37:52 lstein Exp $

use strict;
use warnings;

use Apache2::RequestRec ();
use Apache2::ServerRec ();
use Apache2::RequestIO ();
use Apache2::Access ();
use Apache2::SubRequest ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::Log ();
use Apache2::Const qw(:common REDIRECT HTTP_NO_CONTENT HTTP_NOT_MODIFIED);
use Apache::MP3::L10N;
use APR::Table;
use IO::File;
use Socket 'sockaddr_in';
use CGI qw(:standard *table *td *TR *blockquote *center center *h1);
use CGI::Carp 'fatalsToBrowser';

use File::Basename 'dirname','basename','fileparse';
use File::Path;
use vars qw($VERSION);

$VERSION = '3.06';
my $CRLF = "\015\012";

use constant DIR_MAGIC_TYPE => 'httpd/unix-directory';
use constant DEBUG => 0;

# defaults:
use constant BASE_DIR     => '/apache_mp3';
use constant STYLESHEET   => 'apache_mp3.css';
use constant PARENTICON   => 'back.gif';
use constant PLAYICON     => 'play.gif';
use constant SHUFFLEICON  => 'shuffle.gif';
use constant CDICON       => 'cd_icon.gif';
use constant CDLISTICON   => 'cd_icon_small.gif';
use constant PLAYLISTICON => 'playlist.gif';
use constant COVERIMAGE   => 'cover.jpg';
use constant COVERIMAGESMALL   => 'cover_small.jpg';
use constant PLAYLISTIMAGE=> 'playlist.jpg';
use constant SONGICON     => 'sound.gif';
use constant ARROWICON    => 'right_arrow.gif';
use constant SUBDIRCOLUMNS => 1; #was 3 -allen
use constant PLAYLISTCOLUMNS => 3;
use constant HELPIMGURL   => 'apache_mp3_fig1.gif:374x292';
my %FORMAT_FIELDS = (
		     a => 'artist',
		     c => 'comment',
		     d => 'duration',
		     f => 'filename',
		     g => 'genre',
		     l => 'album',
		     m => 'min',
		     n => 'track',
		     q => 'samplerate',
		     r => 'bitrate',
		     s => 'sec',
		     S => 'seconds',
		     t => 'title',
		     y => 'year',
		     );


my $NO  = '^(no|false)$';  # regular expression
my $YES = '^(yes|true)$';  # regular expression

sub handler : method {
  my $class = shift;
  my $obj = $class->new(@_) or die "Can't create object: $!";
  return $obj->run();
}

sub new {
  my $class = shift;
  my $r = shift if @_ == 1;
  my $self = bless {@_}, ref($class) || $class;
  $self->{r}   ||= $r if $r;

  my @lang_tags;
  push @lang_tags,split /,\s+/,$r->headers_in->{'Accept-language'}
    if $r->headers_in->{'Accept-language'};
  push @lang_tags,$r->dir_config('DefaultLanguage') || 'en-US';

  $self->{'lh'} ||=
    Apache::MP3::L10N->get_handle(@lang_tags)
	|| die "No language handle?";  # shouldn't ever happen!

  $self->{'supported_types'} =
    {
     # type                 condition                     handler method
     'audio/mpeg'        => eval "use MP3::Info; 1;"   && 'read_mpeg',
     'audio/mpeg4'       => eval "use MP4::Info; 1;"   && 'read_mpeg4',
     'application/x-ogg' => eval "use Ogg::Vorbis; 1;" && 'read_vorbis_ogg' ||
                            eval "use Ogg::Vorbis::Header::PurePerl; 1;" 
                                                       && 'read_vorbis_hp',
     'audio/x-wav'       => eval "use Audio::Wav; 1;"  && 'read_wav'
    };


  $self->{'suffixes'} = [ qw(.ogg .OGG .wav .WAV .mp3 .MP3 .mpeg .MPEG .m4a .mp4 .m4p)];

  return $self;
}

sub x {  # maketext plus maybe escape.  The "x" for "xlate"
  my $x = (my $lh = shift->{'lh'})->maketext(@_);
  $x =~ s/([^\x00-\x7f])/'&#'.ord($1).';'/eg
	if $x =~ m/[^\x00-\x7f]/ and $lh->must_escape;
  return $x;
}

sub lh { return shift->{lh} }  # language handle

sub aright { -align => shift->{lh}->right }
# align "right" (or, in case of Arabic (etc), really left).

sub aleft  { -align => shift->{lh}->left  }
# align "light" (or, in case of Arabic (etc), really right).

sub r { return shift->{r} }

sub html_content_type {
  my $self = shift;
  return 'text/html; charset=' . $self->lh->encoding
}

sub help_screen {
  my $self = shift;

  $self->r->content_type( $self->html_content_type );
  return OK if $self->r->header_only;

  print start_html(
		   -lang => $self->lh->language_tag,
		   -title => $self->x('Quick Help Summary'),
		   -dir => $self->lh->direction,
		   -head => meta({-http_equiv => 'Content-Type',
				  -content    => $self->html_content_type
				 }
				),
		   -script =>{-src=>$self->default_dir.'/functions.js'},
		  );

  my $help_img_url = $self->help_img_url;  # URL for the image
  my ($url,$width,$height) = $help_img_url=~/(.+):(\d+)x(\d+)/;
  $url    ||= $help_img_url;
  $width  ||= 500;
  $height ||= 400;

  print img({-src     => $url,
	     -alt     => "",
	     -height  => $height,
	     -width   => $width,
	     $self->aleft,
            }), "\n";
  print join "\n".br(),
    $self->help_figure_list
      ;
  print "\n", end_html();
  return;
}

sub help_figure_list {
  my $self = shift;
  # Provide a legend for the items in the figure
  return(
	 b("A"). $self->x("= Stream all songs"),
	 b("B"). $self->x("= Shuffle-play all Songs"),
	 b("C"). $self->x("= Stream all songs"),
	 b("D"). $self->x("= Go to earlier directory"),
	 b("E"). $self->x("= Stream contents"),
	 b("F"). $self->x("= Enter directory"),
	 b("G"). $self->x("= Stream this song"),
	 b("H"). $self->x("= Select for streaming"),
	 b("I"). $self->x("= Download this song"),
	 b("J"). $self->x("= Stream this song"),
	 b("K"). $self->x("= Sort by field"),
	);
}

sub run {
  my $self = shift;
  my $r = $self->r;

  my(undef,$uribase)  = fileparse($r->uri);
  my(undef,$filebase) = fileparse($r->filename);

  my $local = $self->playlocal_ok && $self->is_local;
  my $base = $self->stream_base;

  local $CGI::XHTML = 0;

  # check that we aren't running under PerlSetupEnv Off
  if ($ENV{MOD_PERL} && !$ENV{SCRIPT_FILENAME}) {
     warn "CGI.pm cannot run with 'PerlSetupEnv Off', please set it to On";
  }

  # this is called to show a help screen
  return $self->help_screen if param('help_screen');

  # generate directory listing
  return $self->process_directory($r->filename)
    if -d $r->filename;  # should be $r->finfo, but STILL problems with this

  # simple download of file
  return $self->download_file($r->filename) unless param;

  # this is called to stream a file
  if(param('stream')){
    return $self->stream;
  }

  # this is called to generate a playlist on the current directory
  return $self->send_playlist($self->find_mp3s)
    if param('Play All');

  # this is called to generate a playlist on the current directory
  # and everything beneath
  return $self->send_playlist($self->find_mp3s('recursive')) 
    if param('Play All Recursive') ;

  # this is called to generate a shuffled playlist of current directory
  return $self->send_playlist($self->find_mp3s,'shuffle')
    if param('Shuffle');

  # this is called to generate a shuffled playlist of current directory
  return $self->send_playlist($self->find_mp3s,'shuffle')
    if param('Shuffle All');

  # this is called to generate a shuffled playlist of current directory
  # and everything beneath
  return $self->send_playlist($self->find_mp3s('recursive'),'shuffle')
    if param('Shuffle All Recursive');

  # this is called to generate a playlist for one file
  if (param('play')) {
    my $dot3 = '.m3u|.pls';
    my($basename,$ext) = $r->uri =~ m!([^/]+?)($dot3)?$!;
    $basename = quotemeta($basename);
    my @matches;
    if (-e $self->r->filename) {
      # If the actual .m3u file exists (it's a playlist), then we read it
      # to get the list of files to send
      @matches = $self->load_playlist($self->r->filename);
    } else {
      # find the MP3 file that corresponds to basename.m3u
      @matches = grep { m!/$basename[^/]*$! } @{$self->find_mp3s};
    }
    if($r->content_type eq 'audio/x-scpls'){
      open(FILE,$r->filename) || return 404;
      $r->send_fd(\*FILE);
      close(FILE);
    } else {
      $self->send_playlist(\@matches);
    }

    $self->send_playlist();
    return OK;
  }

  # this is called to generate a playlist for selected files
  if (param('Play Selected')) {
    return HTTP_NO_CONTENT unless my @files = param('file');
    my $uri = dirname($r->uri);
    $uri =~ s!/?search/?!/!;
    $self->send_playlist([map { "$uri/$_" } @files]);
    return OK;
  }

  if (param('Shuffle Selected')) {
    return HTTP_NO_CONTENT unless my @files = param('file');
    my $uri = dirname($r->uri);
    $uri =~ s!/?search/?!/!;
        my $list = [map {"$uri/$_"} @files];
        $self->shuffle($list);
    $self->send_playlist($list);
    return OK;
  }

  # otherwise don't know how to deal with this
  $self->r->log_reason('Invalid parameters -- possible attempt to circumvent checks.');
  return FORBIDDEN;
}

sub escape {
  my $uri = CGI::escape(shift);
  # unescape slashes so directories work right with mozilla
  $uri =~ s!\%2F!/!gi;
  return $uri;
}

# this generates the top-level directory listing
sub process_directory {
  my $self = shift;
  my $dir = shift;

  return $self->list_directory($dir);
}

# this downloads the file
sub download_file {
  my $self = shift;
  my $file = shift;
  my $type = $self->r->content_type;

  my $is_audio = $self->supported_type ($self->r->content_type);

  if ($is_audio && !$self->download_ok) {

    $self->r->log_reason('File downloading is forbidden');
    return FORBIDDEN;
  } else {

    return DECLINED;  # allow Apache to do its standard thing
  }

}

# stream the indicated file
sub stream {
  my $self = shift;
  my $r = $self->r;

  return DECLINED unless -e $r->filename;  # should be $r->finfo

  unless ($self->stream_ok) {
    $r->log_reason('AllowStream forbidden');
    return FORBIDDEN;
  }

  if ($self->check_stream_client and !$self->is_stream_client) {
    my $useragent = $r->headers_in->{'User-Agent'};
    $r->log_reason("CheckStreamClient is true and $useragent is not a streaming client");
    return FORBIDDEN;
  }

  my $mime = $r->content_type;
  my $file = $r->filename;
  my $url  = $r->uri;

  my $info = $self->fetch_info($file,$mime);
  return DECLINED unless $info;  # not a legit mp3 file?
  my $fh = $self->open_file($file) || return DECLINED;
  binmode($fh);  # to prevent DOS text-mode foolishness

  my $size = -s $file;
  my $bitrate = $info->{bitrate};
  if ($self->can('bitrate') && $self->bitrate) {
    ($bitrate = $self->bitrate) =~ s/ kbps//i;
    # quick approximation
    $size = int($size * ($bitrate / $info->{bitrate}));
  }
  my $description = $info->{description};
  my $genre       = $info->{genre} || $self->lh->maketext('unknown');

  my $range = 0;
  $r->headers_in->{"Range"}
    and $r->headers_in->{"Range"} =~ m/bytes=(\d+)/
    and $range = $1
    and seek($fh,$range,0);

  # Look for a descriptive file that has the same base as the mp3 file.
  # Also look for various index files.
  my $icyurl = $self->stream_base(1);
  my $base   = basename($file);
  $base =~ s/\.\w+$//;  # get rid of suffix
  my $dirbase  = dirname($file);
  my $urlbase  = dirname($url);
  foreach ("$base.html","$base.htm","index.html","index.htm") {
    my $file = "$dirbase/$_";
    if (-r $file) {
      $icyurl .= "$urlbase/$_";
      last;
    }
  }

  $r->assbackwards(1);
  $r->connection->keepalive(1);
  $r->connection->keepalives($r->connection->keepalives+1);

  $r->print("ICY ". ($range ? 206 : 200) ." OK$CRLF");
  $r->print("icy-notice1: <BR>This stream requires a shoutcast/icecast compatible player.<BR>$CRLF");
  $r->print("icy-notice2: Apache::MP3<BR>$CRLF");
  $r->print("icy-name: $description$CRLF");
  $r->print("icy-genre: $genre$CRLF");
  $r->print("icy-url:$icyurl$CRLF");
  $r->print("icy-pub:1$CRLF");
  $r->print("icy-br:$bitrate$CRLF");
  $r->print("Accept-Ranges: bytes$CRLF");
  $r->print("Content-Range: bytes $range-" . ($size-1) . "/$size$CRLF")
    if $range;
  $r->print("Content-Length: $size$CRLF");
  $r->print("Content-Type: $mime$CRLF");
  $r->print("$CRLF");
  return OK if $r->header_only;

  if (my $timeout = $self->stream_timeout) {
    my $seconds  = $info->{seconds};
    $seconds ||= 60;  # shouldn't happen
    my $fraction = $timeout/$seconds;
    my $bytes    = int($fraction * $size);
    while ($bytes > 0) {
      my $data;
      my $b = read($fh,$data,2048) || last;
      $bytes -= $b;
      $r->print($data);
    }
    return OK;
  } else {
    my $data;
    $r->print($data) while read($fh,$data,2048);
  }

  return OK;
}


# this generates a playlist for the MP3 player
sub send_playlist {
  my $self = shift;
  my ($urls,$shuffle) = @_;

  return HTTP_NO_CONTENT unless $urls && @$urls;
  my $r    = $self->r;
  my $base = $self->stream_base;

  $r->content_type('audio/mpegurl');
  return OK if $r->header_only;

  # local user
  my $local = $self->playlocal_ok && $self->is_local;
  $self->shuffle($urls) if $shuffle;
  $r->print("#EXTM3U$CRLF");
  my $stream_parms = $self->stream_parms;
  foreach (@$urls) {
    $self->path_escape(\$_);
    my $subr = $r->lookup_uri($_) or next;
    my $file = $subr->filename;
    my $type = $subr->content_type;
    my $data = $self->fetch_info($file,$type);
    my $format = $self->r->dir_config('DescriptionFormat');
    if ($format) {
      $r->print('#EXTINF:' , $data->{seconds} , ',');
      (my $description = $format) =~ s{%([atfglncrdmsqS%])}
                                      {$1 eq '%' ? '%' : $data->{$FORMAT_FIELDS{$1}}}gxe;
      print $description;
      print $CRLF;
    } else {
      $r->print('#EXTINF:' , $data->{seconds} ,
                ',', $data->{title},
                ' - ',$data->{artist},
                ' (',$data->{album},')',
                $CRLF);
    }
    if ($local) {
      $r->print($file,$CRLF);
    } else {
      $r->print ("$base$_?$stream_parms$CRLF");
    }
  }
  return OK;
}

sub stream_parms {
  my $self = shift;
  return "stream=1";
}

# load the contents of a playlist (.m3u) from disk
sub load_playlist {
  my $self = shift;
  my $playlist = shift;
  my @mp3s = ();
  my $uri = dirname($self->r->uri);
  local $_;
  my $fh = IO::File->new($playlist)
    or die "Failed to open $playlist";
  while(<$fh>) {
    chomp;
    s/\#.*//;         # get rid of comment and hint lines
    s/\s+$//;         # get rid of whitespace at end of lines
    next unless $_;
    push @mp3s, "$uri/$_";
  }
  $fh->close;
  return @mp3s
}

# shuffle an array
sub shuffle {
  my $self = shift;
  my $list = shift;
  for (my $i=0; $i<@$list; $i++) {
    my $rand = rand(scalar @$list);
    ($list->[$i],$list->[$rand]) = ($list->[$rand],$list->[$i]);  # swap
  }
}

# top level for directory display
sub list_directory {
  my $self = shift;
  my $dir  = shift;

  return DECLINED unless -d $dir;

  my $last_modified = (stat(_))[9];

  $self->r->headers_out->add('ETag' => sprintf("%lx-%s", $last_modified, $VERSION));

  if (my $check = $self->r->headers_in->{"If-None-Match"}) {
    my ($time, $ver) = $check =~ /^([a-f0-9]+)-([0-9.]+)$/;

    if ($check eq '*' or (hex($time) == $last_modified and $ver == $VERSION)) {
      return HTTP_NOT_MODIFIED;
    }
  }

  return DECLINED unless my ($directories,$mp3s,$playlists,$txtfiles)
    = $self->read_directory($dir);

  $self->r->content_type( $self->html_content_type );
  return OK if $self->r->header_only;

  $self->page_top($dir);
  $self->directory_top($dir);

  print "\n<!-- begin main -->\n";
  if(@$directories) {
    print "\n<!-- begin subdirs -->\n";
    $self->list_subdirs($directories);
    print "\n<!-- end subdirs -->\n";
  }

  if(@$txtfiles) {
    print "\n<!-- begin txtfiles -->\n";
    $self->list_txtfiles($txtfiles);
    print "\n<!-- end txtfiles -->\n";
  }
  if(@$playlists) {
    print "\n<!-- begin playlists -->\n";
    $self->list_playlists($playlists);
    print "\n<!-- end playlists -->\n";
  }
  if(%$mp3s) {
    print "\n<!-- begin mp3s -->\n";
    $self->list_mp3s($mp3s);
    print "\n<!-- end mp3s -->\n";
  }
  print "\n<!-- end main -->\n";
  print hr                         unless %$mp3s;

  $self->directory_bottom($dir);

  return OK;
}

# print the HTML at the top of the page
sub page_top {
  my $self = shift;
  my $dir  = shift;
  my $title = $self->r->uri;
  print start_html(
		   -title => $title,
		   -head => meta({-http_equiv => 'Content-Type',
				  -content    => 'text/html; charset='
                                  . $self->html_content_type
				 }),
		   -lang  => $self->lh->language_tag,
		   -dir => $self->lh->direction,
		   -style => {-src=>$self->stylesheet},
		   -script =>{-src=>$self->default_dir.'/functions.js'},
		  );
}

# print the HTML at the top of a directory listing
sub directory_top {
  my $self = shift;
  my $dir  = shift;

  my $title = $self->r->uri;
  my $links;

  print start_table({-width => '100%'}), start_TR;
  print start_td({-width=>'100%'});

  if ($self->path_style eq 'staircase') {
    $links = $self->generate_navpath_staircase($title);
  } elsif ($self->path_style eq 'arrows') {
    $links = $self->generate_navpath_arrows($title);
  } elsif ($self->path_style eq 'slashes') {
    $links = $self->generate_navpath_slashes($title);
  }

  print a({-href=>'./playlist.m3u?Play+All+Recursive=1'},
	  img({-src => $self->cd_icon($dir), $self->aleft, -alt=>
	      $self->x('Stream All'),
	      -border=>0})),
	    $links,
	a({-href=>'./playlist.m3u?Shuffle+All+Recursive=1'},
	  font({-class=>'directory'}, '[',
	    $self->x('Shuffle All'),
	    ']'
	 ))
	.'&nbsp;'.
	a({-href=>'./playlist.m3u?Play+All+Recursive=1'},
	  font({-class=>'directory'}, '[',
	    $self->x('Stream All'),
	    ']'
	)),
	br({-clear=>'ALL'}),;

  if (my $t = $self->stream_timeout) {
    print p(strong(
        $self->x('Note:')
      ),' ',
      $self->x("In this demo, streaming is limited to approximately [quant,_1,second,seconds].", $t),
      "\n"
    );
  }

  print end_td;
  print end_TR, end_table;
}

# staircase style path
sub generate_navpath_staircase {
  my $self = shift;
  my $uri = shift;
  my $home =  $self->home_label;
  my $indent = 3.0;

  my @components = split '/',$uri;
  unshift @components,'' unless @components;
  my ($path,$links) = ('',br());
  my $current_style = "line-height: 1.2; font-weight: bold; color: red;";
  my $parent_style  = "line-height: 1.2; font-weight: bold;";

  for (my $c=0; $c < @components-1; $c++) {
    $path .= escape($components[$c]) ."/";
    my $idt = $c * $indent;
    my $l = a({-href=>$path},$components[$c] || ($home.br({-clear=>'all'})));
    $links .= div({-style=>"text-indent: ${idt}em; $parent_style"},
		  font({-size=>'+1'},$l))."\n";
  }
  my $idt = (@components-1) * $indent;
  $links .= div({-style=>"text-indent: ${idt}em; $current_style"},
		font({-size=>'+1'},$components[-1] || $home))."\n";
  return $links;
}

# alternative display on one line using arrows
sub generate_navpath_slashes {
  my $self = shift;
  my $uri = shift;
  my $home =  $self->home_label;
  my @components = split '/',$uri;
  unshift @components,'' unless @components;
  my $path;
  my $links = br . '&nbsp;&nbsp;' ; #start_h1();
  for (my $c=0; $c < @components-1; $c++) {
    $links .= '&nbsp;/&nbsp;' if $path;
    $path .= escape($components[$c]) . "/";
    $links .= a({-href=>$path},font({-size=>'+1'},$components[$c] || $home));
  }
  $links .= '&nbsp;/&nbsp;' if $path;
  $links .= font({-size=>'+1',-style=>'color: red'},($components[-1] || $home));
  $links .= br;
  return $links;
}

# alternative display on one line using arrows
sub generate_navpath_arrows {
  my $self = shift;
  my $uri = shift;
  my $home =  $self->home_label;
  my @components = split '/',$uri;
  unshift @components,'' unless @components;
  my $path;
  my $links = br . '&nbsp;&nbsp;' ; #start_h1();
  my $arrow = $self->arrow_icon;
  for (my $c=0; $c < @components-1; $c++) {
    $links .= '&nbsp;' . img({-src=>$arrow}) if $path;
    $path .= escape($components[$c]) . "/";
    $links .= '&nbsp;' . a({-href=>$path},$components[$c] || $home);
  }
  $links .= '&nbsp;' . img({-src=>$arrow}) if $path;
  $links .= "&nbsp;". ($components[-1] || $home);
  $links .= br;#end_h1();
  return $links;
}

# print the HTML at the bottom of the page
sub directory_bottom {
  my $self = shift;
  my $dir  = shift;  # actually not used
  my $mp3s = shift;

  #allow masking of 'Authored by Lincoln...' and helplink.
  return if $self->r->dir_config('SuppressCredits');

  print
    table({-width=>'100%',-border=>0},
	  TR(
	     td({$self->aleft},
		#address(  # Unpredictable and/or flaky rendering
		        $self  ->x( "_CREDITS_before_author" )
		        .
			a({-href=>'http://stein.cshl.org'},
			  $self->x( "_CREDITS_author" )
			)
			.
		        $self  ->x( "_CREDITS_after_author" )
		#)
		),
	     td({$self->aright},$self->get_help))
	     );
  print "<!--",
    sprintf("\n %s v%s", __PACKAGE__, $VERSION || '0'),
    (ref($self) eq __PACKAGE__) ? () :
    sprintf("\n %s v%s", ref($self), $self->VERSION || '0'),
    "\n ", $self->x('_VERSION'), " (", ref($self->lh), ")",
    "\n -->",
  ;
  print end_html();
}

# print the HTML at the top of the list of subdirs
sub subdir_list_top {
  my $self   = shift;
  my $subdirs = shift;  # array reference
  print "\n", hr;
  print "\n\n", h2({-class=>'CDdirectories'},
    $self->x('CD Directories ([_1])',
             scalar @$subdirs),
  ), "\n";
}

# print the HTML at the bottom of the list of subdirs
sub subdir_list_bottom {
  my $self   = shift;
  my $subdirs = shift;  # array reference
}

# print the HTML to format the list of subdirs
sub subdir_list {
  my $self   = shift;
  my $subdirs = shift; #array reference

  my @subdirs = $self->sort_subdirs($subdirs);

  my $cols = $self->subdir_columns;
  my $rows =  int(0.99 + @subdirs/$cols);

  print start_table({-border=>0,-id=>'diroutertable'}),"\n";

  if($self->subdir_columns == 1){
    my $statsheader = '';

    if($self->r->dir_config('CacheStats') && $self->r->dir_config('CacheDir')){
      $statsheader = td(b('Last Accessed')). td(b('Times Accessed'));
    }

    print TR(
	     td(b('Directory')),
	     td(b('Play Options')),
	     td(b('Last Modified')),
	     $statsheader,
	    );
  }

  for (my $row=0; $row < $rows; $row++) {
    print start_TR({-valign=>'BOTTOM',-align=>'LEFT'});
    for (my $col=0; $col<$cols; $col++) {
      my $i = $col * $rows + $row;
      my $contents = $subdirs[$i] ? $self->format_subdir($subdirs[$i]) : '&nbsp;';

      #only assume wrap in td() if multiple columns.  should td() be moved to format_subdir() ?
      print $self->subdir_columns == 1 ? $contents : td($contents);

    }
    print end_TR,"\n";
  }
  print end_table;
}

# given a list of CD directories, sort them
sub sort_subdirs {
  my $self = shift;
  my $subdirs = shift;
  return sort @$subdirs; # alphabetic sort by default
}

# format a subdir entry and return its HTML
sub format_subdir {
  my $self = shift;
  my $subdir = shift;

  my $subdirpath = $self->r->filename .'/'. $subdir;
  # special handling if subdir is fully pathed
  if (substr($subdir, -1) eq "/") {
    chop $subdir;
    $subdirpath = $self->r->lookup_uri($subdir)->filename;
  }
  my $nb = '&nbsp;';
  (my $title = $subdir) =~ s/\s/$nb/og;  # replace whitespace with &nbsp;
  $title =~ s!^.*(/[^/]+/[^/]+)$!...$1!;  # if dir is fully pathed, only keep 2 parts for title
  my $uri = escape($subdir);
  my $result;

  my($atime,$mtime) = (stat($subdirpath))[8,9];

  my($last,$times);
  if($self->r->dir_config('CacheStats')){
	($last,$times) = $self->stats($self->r->filename,$subdir);
  }

  if($self->subdir_columns == 1){
	$result = td(
				 a({-href=>$uri.'/playlist.m3u?Play+All+Recursive=1'},
				   img({-src=>$self->cd_list_icon($subdir),
						-align=>'ABSMIDDLE',
						-class=>'subdir',
						-alt=>$self->x('Stream'),
						-border=>0})),
				 a({-href=>$uri.'/'},font({-class=>'subdirectory'},$title))
				)
	         .td(
				 a({-class=>'subdirbuttons',
					-href=>$uri.'/playlist.m3u?Shuffle+All+Recursive=1'},
				   '[' .
				   $self->x('Shuffle')
				   .']')
				 .$nb.
				 a({-class=>'subdirbuttons',
					-href=>$uri.'/playlist.m3u?Play+All+Recursive=1'},
				   '['.
				   $self->x('Stream')
				   .']')."\n"
				)
			 .td(
				 scalar(localtime($mtime))
				);

	if($self->r->dir_config('CacheStats')){
	  $result .= td($last) . td($times);
	}

  } else {
	$result = start_table({-border=>0,-alight=>'LEFT'}).start_TR().td(
                  a({-href=>$uri.'/playlist.m3u?Play+All+Recursive=1'},
		    img({-src=>$self->cd_list_icon($subdir),
		         -align=>'LEFT',
			 -class=>'subdir',
			 -alt=>$self->x('Stream'),
		         -border=>0}))
                  ).td({-valign => 'CENTER', -align => 'LEFT'},
	          a({-href=>$uri.'/'},font({-class=>'subdirectory'},$title)).
	 	  br."\n".
		  a({-class=>'subdirbuttons',
		     -href=>$uri.'/playlist.m3u?Shuffle+All+Recursive=1'},
		     '['.$self->x('Shuffle').']')
		  .$nb.
		  a({-class=>'subdirbuttons',
		     -href=>$uri.'/playlist.m3u?Play+All+Recursive=1'},
		     '['.$self->x('Stream').']')."\n"
                  ).end_TR().end_table();
  }

  return $result;
}

sub last_accessed {
  my $self = shift;
  warn join ' ', @_;
}

sub times_accessed {
  my $self = shift;
  warn join ' ', @_;
}

sub playlist_list_top {
  my $self = shift;
  my $playlists = shift; # array ref
  print hr;
  print "\n\n", h2({-class=>'CDdirectories'}, 
        $self->x('Playlists ([_1])',
                 scalar @$playlists));
}

# print the HTML at the bottom of the list of playlists
sub playlist_list_bottom {
  my $self = shift;
  my $playlists = shift; # array ref
}

# print the HTML to format the list of playlists
sub playlist_list {
  my $self = shift;
  my $playlists = shift; # array ref

  my $cols = $self->playlist_columns;
  my $rows = int(0.99 + @$playlists / $cols);

#  print start_center;
   print start_table({-border => 0, -width => '95%'}), "\n";

  for(my $row = 0; $row < $rows; $row++) {
    print start_TR({-valign => 'BOTTOM'});
    for(my $col = 0; $col < $cols; $col++) {
      my $i = $col * $rows + $row;
      my $contents = $playlists->[$i]
        ? $self->format_playlist( $playlists->[$i] )
        : '&nbsp;';
      print td($contents);
    }
    print end_TR, "\n";
  }

  print end_table;
#  print end_center;
}

# format a playlist entry and return its HTML
sub format_playlist {
  my $self = shift;
  my $playlist = shift;
  my $nb = '&nbsp;';
  my $dot3 = '.m3u|.pls';
  my($param) = $playlist =~ /\.m3u$/ ? '?play=1' : '';
  (my $title = $playlist) =~ s/$dot3$//;
  $title =~ s/\s/$nb/og;
  my $url = escape($playlist) . $param;

  return p(a({-href => $url},
             img({-src => $self->playlist_icon,
                  -align => 'ABSMIDDLE',
                  -class => 'subdir',
                  -alt =>
                     $self->x('Playlist'),
                  -border => 0}))
           . $nb .
           a({-href => $url},
             font({-class => 'subdirectory'},
                  $title)));
}

# This generates the link for help
sub get_help {
  my $self = shift;
  return a({-href => "?help_screen=1",}, $self->x('Quick Help Summary'));
}

sub txtfile_list_top {
  my $self = shift;
  my $txtfiles = shift; # array ref
  print hr;
  print h2({-class=>'CDdirectories'}, 
           sprintf('Text Files (%d)', scalar @$txtfiles));
}

# print the HTML to format the list of playlists
sub txtfile_list {
  my $self = shift;
  my $txtfiles = shift; # array ref

  my $cols = $self->playlist_columns;
  my $rows = int(0.99 + @$txtfiles / $cols);

   print start_table({-border => 0, -width => '95%'}), "\n";

  for(my $row = 0; $row < $rows; $row++) {
    print start_TR({-valign => 'BOTTOM'});
    for(my $col = 0; $col < $cols; $col++) {
      my $i = $col * $rows + $row;
      my $contents = $txtfiles->[$i] ? $self->format_txtfile($txtfiles->[$i]) : '&nbsp;';
      print td($contents);
    }
    print end_TR, "\n";
  }

  print end_table;
#  print end_center;
}

# format a txtfile entry and return it's HTML
sub format_txtfile {
  my $self = shift;
  my $txtfile = shift;
  my $nb = '&nbsp;';
  (my $title = $txtfile) =~ s/\.(txt|nfo)$//;
  $title =~ s/\s/$nb/og;
  my $url = escape($txtfile);

  return p(a({-href => $url},
             img({-src => "/icons/text.gif", # $self->playlist_icon,
                  -align => 'ABSMIDDLE',
                  -class => 'subdir',
                  -alt => 'Text File',
                  -border => 0}))
           . $nb .
           a({-href => $url},
             font({-class => 'subdirectory'},
                  $title)));
}

# this is called to display the subdirs (subdirectories) within the current directory
sub list_subdirs {
  my $self   = shift;
  my $subdirs = shift;  # arrayref
  $self->subdir_list_top($subdirs);
  $self->subdir_list($subdirs);
  $self->subdir_list_bottom($subdirs);
}

# this is called to display the playlists within the current directory
sub list_playlists {
  my $self = shift;
  my $playlists = shift; # arrayref
  $self->playlist_list_top($playlists);
  $self->playlist_list($playlists);
  $self->playlist_list_bottom($playlists);
}

# this is called to display the text files within the current directory
sub list_txtfiles {
  my $self = shift;
  my $txtfiles = shift; # arrayref
  $self->txtfile_list_top($txtfiles);
  $self->txtfile_list($txtfiles);
  $self->playlist_list_bottom($txtfiles);
}

# this is called to display the MP3 files within the current directory
sub list_mp3s {
  my $self = shift;
  my $mp3s = shift;  #hashref
  my $mode = shift;  #how should we construct the urls?
  $mode ||= '';

  $self->mp3_list_top(   $mp3s,$mode);
  $self->mp3_list(       $mp3s,$mode);
  $self->mp3_list_bottom($mp3s,$mode);
}

# top of MP3 file listing
sub mp3_list_top {
  my $self = shift;
  my $mp3s = shift;  #hashref
  my $mode = shift;
  print hr;

  my $uri = $self->r->uri;  # for self referencing
  $uri =~ s!([^a-zA-Z0-9/])!uc sprintf("%%%02x",ord($1))!eg;

  # apache and/or mod_perl has some problem redirecting from POST requests...
  print start_form(-name=>'form',-action=>"${uri}playlist.m3u",-method=>'GET');

  my $count = keys %$mp3s;
  print
    "\n\n",
    h2({-class=>'SongList'},
        a({-name=>'cds'}, 
          $self->x("Song List ([_1])", $count),
        ),
    ),
    "\n",
    start_table({-border=>0,-cellspacing=>0,-width=>'100%'}),"\n";

  print  TR(td(),
	    td({$self->aleft,-colspan=>4},$self->control_buttons($mode)))
    if $self->stream_ok and keys %$mp3s > $self->file_list_is_long;

  $self->mp3_table_header;
}

sub control_buttons {
  my $self = shift;
  my $mode = shift;

  my $return;

  $return .= 
    sprintf('<input type="submit" name="Play Selected" value="%s" />',
      $self->x('Play Selected'),
    );

  $return .= 
    sprintf('<input type="submit" name="Shuffle Selected" value="%s" />',
			$self->x('Shuffle Selected'),
    );

  return $return;
}

sub mp3_table_header {
  my $self = shift;
  my $url = url(-absolute=>1,-path_info=>1);

  my @fields = $self->format_table_fields;

  print TR({-class=>'title',$self->aleft},
	   th(),
	   th(
	      $self->stream_ok ?
		checkbox(-onClick => 'toggleAll(this,document.form.file)',
			 -name=>'selectall',
			 -label=>'') .
		$self->x('Select')
		: ''
	     ),
	   th(\@fields)),"\n";
}

sub format_table_fields {
  my $self = shift;
  return map {
    $self->x(ucfirst($_))
  } $self->fields;
}

# bottom of MP3 file listing
sub mp3_list_bottom {
  my $self = shift;
  my $mp3s = shift;  #hashref
  my $mode = shift;
  print  TR(td(),
	    td({$self->aleft,-colspan=>10},$self->control_buttons($mode)))
    if $self->stream_ok;
  print end_table,"\n";
  print end_form;
  print hr;
}

# each item of the list
sub mp3_list {
  my $self = shift;
  my $mp3s = shift;  #hashref
  my $mode = shift;

  my @f = $self->sort_mp3s($mp3s);
  my $count = 0;
  for my $song (@f) {
    my $class = $count % 2 ? 'even' : 'odd';
    my $contents   = $self->format_song($song,$mp3s->{$song},$count,$mode);
    print TR({
	      -class       => $class,
	      -onMouseOver => "hiliteRow(this,true)",
	      -onMouseOut  => "hiliteRow(this,false)",
	      -onMouseDown => "toggleRow(this)",
	     },td($contents)), "\n";

	$count++;
  }
}

# return the contents of the table for each mp3
sub format_song {
  my $self = shift;
  my ($song,$info,$count,$mode) = @_;
  my @contents = ($self->format_song_controls($song,$info,$count,$mode),
		  $self->format_song_fields  ($song,$info,$count));
  return \@contents;
}

# Format the control part of each mp3 in the listing (checkbox, etc).
# Each list item becomes a cell in the table.
sub format_song_controls {
  my $self = shift;
  my ($song,$info,$count,$mode) = @_;

  my $song_title = sprintf("%3d. %s", $count, $info->{title} || $song);

  my $url = escape($song);
  #my $url = $song;

  warn $mode if DEBUG;

  (my $play = $url) =~ s/(\.[^.]+)?$/.m3u?play=1/;
  (my $urldir = $url) =~ s!/[^/]+$!/!;

  my $controls = '';
  my $cancel   = "event.cancelBubble='true'";
  $controls .= checkbox(-name     =>'file',
			-value    =>$song,
			-label    =>'',
			-onClick  => "toggleCheckbox(this)",     # works on most platforms
		       ) if $self->stream_ok;
  $controls  .= a({-href=>$url,-class => 'fetch',-onMouseDown=>$cancel}, b('&nbsp;['.
      $self->x('fetch')
      .']'
     ))
    if $self->download_ok;
  $controls  .= a({-href=>$play,-onMouseDown=>$cancel},b('&nbsp;['.   # TODO: make an nbsp joiner?
      $self->x('stream')
      .']'
     ))
    if $self->stream_ok;

  return (
	  $self->stream_ok ? a({-href=>$play},
	                       img({-src => $self->song_icon,-alt =>
	                           $self->x('stream'),
	                            -border => 0}))
	                   : img({-src => $self->song_icon})
	  , $controls
	 );
}

# format the fields of each mp3 in the listing (artist, bitrate, etc)
sub format_song_fields {
  my $self = shift;
  my ($song,$info,$count) = @_;
  return map { ($info->{lc($_)}||'') =~ /^\d+$/ ?
		 $info->{lc($_)} :   # Do NOT use p(), it makes the cells huge in some browsers.
		   ($info->{lc($_)} || '&nbsp;') } $self->fields;
}

# read a single directory, returning lists of subdirectories and MP3 files
sub read_directory {
  my $self      = shift;
  my $dir       = shift;

  my (@directories,%seen,%mp3s,@playlists,@txtfiles);

  opendir D,$dir or return;
  while (defined(my $d = readdir(D))) {
    next if $self->skip_directory($d);

    # skip if file is unreadable
    next unless -r "$dir/$d";

    my $mime = $self->r->lookup_file("$dir/$d")->content_type;

    push(@directories,$d) if !$seen{$d}++ && $mime eq DIR_MAGIC_TYPE;

    # .m3u files should be configured as audio/playlist MIME types in your apache .conf file
    push(@playlists,$d) if $mime =~ m!^audio/(playlist|x-mpegurl|mpegurl|x-scpls)$!;
    push(@txtfiles,$d) if $mime =~ m!^text/plain$!;

    next unless $self->supported_type ($mime);
    next unless $mp3s{$d} = $self->fetch_info("$dir/$d", $mime);
  }
  closedir D;
  return \(@directories,%mp3s,@playlists,@txtfiles);
}


# return title, artist, duration, and kbps
sub fetch_info {
  my $self = shift;
  my ($file,$type) = @_;

  return unless $self->supported_type ($type);

  warn "1 $file $type" if DEBUG;

  if (!$self->read_mp3_info) {  # don't read config info
    my $f = basename($file,$self->suffixes());
    return {
	    filename    => $f,
	    description => $f,
	   };
  }

  my %data = $self->read_cache($file);

  unless (%data and keys(%data) == keys(%FORMAT_FIELDS)) {
    my $handler = $self->supported_type ($type);
    $self->$handler($file,\%data);

    # fill in missing fields
    $data{filename} ||= basename($file);
    $data{title}    ||= basename($file,$self->suffixes());

    # Make sure that the data fields do not contain record seperator chars ($;) or newlines
    foreach my $key (keys %data) {
      $data{$key} =~ tr/\034\n/  /;
    }
    $self->write_cache($file => \%data);
  }


  if (my $blank = $self->missing_comment) {
    foreach (qw(artist duration genre album track)) {
      $data{$_} ||= $blank;
    }
  }

  $data{description} = $self->description(\%data);
  return \%data;
}

sub _stats {
  my $self = shift;
  my $dirname = shift;

  return unless my $cache = $self->cache_dir;
  my $cache_file = $cache.'/stats';

  if(!$self->{_stat}){
	#read stats
	if(-f $cache_file){
	  open(C, $cache_file) or die "couldn't open statscache for reading $cache_file: $!";
	  while(my $line = <C>){
		chomp $line;
		my($path,$last,$count) = split /\t/, $line;
		$self->{_stat}{$path}{last_accessed}  = $last;
		$self->{_stat}{$path}{times_accessed} = $count;
	  }
	  close(C);
	}

	#update stats
	$self->{_stat}{$dirname}{last_accessed}  = scalar(localtime());
	$self->{_stat}{$dirname}{times_accessed}++;

	#write stats
	open(C,">$cache_file") or die "couldn't open stats for writing: $!";
	foreach my $k (keys %{ $self->{_stat} }){
	  print C $k,"\t",$self->{_stat}{$k}{last_accessed},"\t",$self->{_stat}{$k}{times_accessed},"\n";
	}
	close(C);
  }

  return($self->{_stat}{$dirname}{last_accessed} || 'never', $self->{_stat}{$dirname}{times_accessed} || 'never');
}

sub stats {
  my $self    = shift;
  my $prefix  = shift;
  my $dirname = shift;

  #make sure we always call on the prefix first, to properly increment it's viewing.
  $self->_stats($prefix);

  return($self->_stats($prefix .'/'. $dirname));
}

# these methods are called to read the MIME types specified in
# $self->{'supported_types'}
sub read_mpeg {
  my $self = shift;
  my ($file,$data) = @_;

  return unless my $info = get_mp3info($file);

  my $tag  = get_mp3tag($file);
  my ($title,$artist,$album,$year,$comment,$genre,$track) = 
    @{$tag}{qw(TITLE ARTIST ALBUM YEAR COMMENT GENRE TRACKNUM)} if $tag;
  my $duration = sprintf "%d:%2.2d", $info->{MM}, $info->{SS};
  my $seconds  = ($info->{MM} * 60) + $info->{SS};

  my $dir = dirname ($file);
  if (basename ($file) =~ /^track-([0-9]+).mp3$/ && open INDEX, "<$dir/INDEX") {
      my $track_num = $1;
      while (my $line = <INDEX>) {
	  if ($line =~ /^DTITLE=(.+)$/) {
	      ($artist, $album) = split /\//, $1;
	  }
 	  if ($line =~ /^TTITLE([0-9]+)=(.+)$/ && $track_num == $1+1) {
 	      $title = $2;
 	  }
      }
      close INDEX;
  }

  #THESE ARE ALPHABETIZED.  KEEP THEM IN ORDER!
  %$data =(
	   album        => $album || ''    ,
	   artist       => $artist || ''   ,
	   bitrate      => $info->{BITRATE},
	   comment      => $comment || '',
	   duration     => $duration || '' ,
	   genre        => $genre || ''    ,
	   min          => $info->{MM},
	   samplerate   => $info->{FREQUENCY},
	   sec          => $info->{SS},
	   seconds      => $seconds,
	   title        => $title || '',
	   track        => $track || '',
	   year         => $year  || '',
	  );
}

sub read_mpeg4 {
  my $self = shift;
  my ($file,$data) = @_;

  return unless my $info = get_mp4info($file);

  my $tag  = get_mp4tag($file);
  my ($title,$artist,$album,$year,$comment,$genre,$track) = 
    @{$tag}{qw(TITLE ARTIST ALBUM YEAR COMMENT GENRE TRACKNUM)} if $tag;
  my $duration = sprintf "%d:%2.2d", $info->{MM}, $info->{SS};
  my $seconds  = ($info->{MM} * 60) + $info->{SS};

  my $dir = dirname ($file);
  if (basename ($file) =~ /^track-([0-9]+).m4a$/ && open INDEX, "<$dir/INDEX") {
      my $track_num = $1;
      while (my $line = <INDEX>) {
	  if ($line =~ /^DTITLE=(.+)$/) {
	      ($artist, $album) = split /\//, $1;
	  }
 	  if ($line =~ /^TTITLE([0-9]+)=(.+)$/ && $track_num == $1+1) {
 	      $title = $2;
 	  }
      }
      close INDEX;
  }

  #THESE ARE ALPHABETIZED.  KEEP THEM IN ORDER!
  %$data =(
	   album        => $album || ''    ,
	   artist       => $artist || ''   ,
	   bitrate      => $info->{BITRATE},
	   comment      => $comment || '',
	   duration     => $duration || '' ,
	   genre        => $genre || ''    ,
	   min          => $info->{MM},
	   samplerate   => $info->{FREQUENCY},
	   sec          => $info->{SS},
	   seconds      => $seconds,
	   title        => $title || '',
	   track        => $track || '',
	   year         => $year || '',
	  );
}

sub read_vorbis_ogg {
  my $self = shift;
  my ($file,$data) = @_;

  my $ogg = Ogg::Vorbis->new or return;
  my $oggfh = IO::File->new($file) || die "$file: $!";
  $ogg->open($oggfh);
  my $comments = $ogg->comment;
  my $info = $ogg->info;
  my $sec = int $ogg->time_total;

  # LS: it is unclear to me from the documentation at
  # http://xiph.org/ogg/vorbis/doc/v-comment.html
  # whether the fields are required to be case sensitive.  The patch
  # submitted by Devi Carraway used lower case, but is that  right
  # in general?

  #THESE ARE ALPHABETIZED.  KEEP THEM IN ORDER!
  %$data = (
	    album => $comments->{album}     || $comments->{ALBUM}   || '',
	    artist => $comments->{artist}   || $comments->{ARTIST}  || '',
	    bitrate => $ogg->bitrate/1000,
	    comment => $comments->{comment} || $comments->{COMMENT} || '',
	    duration => sprintf("%d:%2.2d", int($sec/60), $sec%60),
	    genre => $comments->{genre}     || $comments->{GENRE}   || '',
	    min => int $sec/60,
	    samplerate => $info->rate,
	    sec => $sec%60,
	    seconds => $sec,
	    title => $comments->{title}     || $comments->{TITLE}   || '',
	    track => $comments->{tracknumber} || $comments->{TRACKNUMBER} || '',
	    year => $comments->{year}       || $comments->{YEAR}    || '',
	   );
  close $oggfh;
}

{

  # Ogg::Vorbis::Header::PurePerl has a clumsy interface for getting
  # comments.  We fix it up as a simple hash.
  my $_comments = sub {
    my($self) = shift;
    my %comments = ();

    foreach my $comment ($self->comment_tags) {
      $comments{$comment} = join '', $self->comment($comment);
    }

    return \%comments;
  };

  sub read_vorbis_hp {
    my $self = shift;
    my ($file,$data) = @_;

    my $ogg = Ogg::Vorbis::Header::PurePerl->load($file) or return;
    my $comments = $ogg->$_comments;
    my $info = $ogg->info;
    my $sec = int $info->{length};

    #THESE ARE ALPHABETIZED.  KEEP THEM IN ORDER!
    %$data = (
              album => $comments->{album}     || $comments->{ALBUM}   || '',
              artist => $comments->{artist}   || $comments->{ARTIST}  || '',
              bitrate => int $info->{bitrate_nominal}/1000,
              comment => $comments->{comment} || $comments->{COMMENT} || '',
              duration => sprintf("%d:%2.2d", int($sec/60), $sec%60),
              genre => $comments->{genre}     || $comments->{GENRE}   || '',
              min => int $sec/60,
              samplerate => $info->{rate},
              sec => $sec%60,
              seconds => $sec,
              title => $comments->{title}     || $comments->{TITLE}   || '',
              track => $comments->{tracknumber} || $comments->{TRACKNUMBER} || '',
              year => $comments->{year}       || $comments->{YEAR}    || '',
             );

    return;
  }

}

sub read_wav {
  my $self = shift;
  my ($file,$data) = @_;
  my $wav = Audio::Wav->new;
  my $reader = $wav->read($file);
  my $comments = $reader->get_info() || {};
  my $details  = $reader->details()  || {};
  my $sec = $reader->length_seconds;

  #THESE ARE ALPHABETIZED.  KEEP THEM IN ORDER!
  %$data = (
	    album  => $comments->{album}  || $comments->{ALBUM}  || '',
	    artist => $comments->{artist} || $comments->{ARTIST} || '',
	    bitrate     => int($details->{bytes_sec}*8/1024),
	    comment => $comments->{comment} || $comments->{COMMENT} || '',
	    duration    => sprintf("%d:%2.2d", int $sec/60,$sec%60),
	    genre  => $comments->{genre}  || $comments->{GENRE}  || '',
	    min         => int $sec/60,
	    samplerate  => $details->{sample_rate},
	    sec         => $sec %60,
	    seconds     => $sec,
	    title  => $comments->{title}  || $comments->{TITLE}  || '',
	    track  => $comments->{tracknumber} || $comments->{TRACKNUMBER} || '',
	    year   => $comments->{year}   || $comments->{YEAR}   || '',
	   )
}

# a limited escape of URLs (does not escape directory slashes)
sub path_escape {
  my $self = shift;
  my $uri = shift;
  $$uri =~ s!([^a-zA-Z0-9_/.-])!uc sprintf("%%%02x",ord($1))!eg;
}

# get fields to display in list of MP3 files
sub fields {
  my $self = shift;
  my @f = split /\W+/,$self->r->dir_config('Fields')||'';
  return map { lc $_  } @f if @f;          # lower case
  return qw(title artist duration bitrate); # default
}

# read from the cache
sub read_cache {
  my $self = shift;
  my $file = shift;
  return unless my $cache = $self->cache_dir;
  my $cache_file = "$cache$file";
  my $file_age = -M $file;
  return unless -e $cache_file && -M $cache_file <= $file_age;
  return unless my $c = IO::File->new($cache_file);
  my ($data,$buffer);
  while (read($c,$buffer,4096)) {
    $data .= $buffer;
  }
  close $c;
  my @data = split $;,$data;
  push @data,'' if @data %2;  # avoid odd numbered hashes
  return @data;
}

# write to the cache
sub write_cache {
  my $self = shift;
  my ($file,$data) = @_;
  return unless my $cache = $self->cache_dir;
  my $cache_file = "$cache$file";

  # some checks and untaint
  return if $cache_file =~ m!/\.\./!; # no relative path tricks
  $cache_file =~ m!^(/.+)$! or return;
  $cache_file = $1;

  my $dirname = dirname($cache_file);
  -d $dirname || eval{mkpath($dirname)} || return;

  if (my $c = IO::File->new(">$cache_file")) {
    print $c join $;,%$data;
  }

  1;
}

# called to open the MP3 file
# can override to do downsampling, etc
sub open_file {
  my $self = shift;
  my $file = shift;
  return IO::File->new($file,O_RDONLY);
}

# find all playable files in current directory
sub find_mp3s {
  my $self    = shift;
  my $recurse = shift;

  #changing this so that it is possible to find mp3s from search page
  #  my $uri = dirname($self->r->uri);
  my $uri = dirname(shift || $self->r->uri);

  my $dir = dirname($self->r->filename);

  my @uris = $self->sort_mp3s($self->_find_mp3s($dir,$recurse));
  foreach (@uris) {
    # strip directory part
    substr($_,0,length($dir)+1) = '' if index($_,$dir) == 0;
    # turn into a URL
    $_ = "$uri/$_";
  }
  return \@uris;
}

# recursive find
sub _find_mp3s {
  my $self = shift;
  my ($d,$recurse) = @_;
  my ($directories,$files) = $self->read_directory($d);
  # Add the directory back onto each file
  unless ($d eq '.') {
    foreach my $k (keys %$files) {
      $files->{"$d/$k"} = $files->{$k};
      delete $files->{$k};
    }
  }

  if ($recurse) {
    foreach (@$directories) {
      my $f = $self->_find_mp3s("$d/$_",$recurse);
      # Add the new files to our main hash
      $files->{$_} = $f->{$_} foreach keys %$f;
    }
  }

  return $files;
}

# sort MP3s
sub sort_mp3s {
  my $self = shift;
  my $files = shift;
  return sort keys %$files;
}

#################################################
# interesting configuration directives start here
#################################################

#utility subroutine for configuration
sub get_dir {
  my $self = shift;
  my ($config,$default) = @_;
  my $dir = $self->r->dir_config($config) || $default;
  return $dir if $dir =~ m!^/!;       # looks like a path
  return $dir if $dir =~ m!^\w+://!;  # looks like a URL
  return $self->default_dir . '/' . $dir;
}

# return true if downloads are allowed from this directory
sub download_ok {
  my $d = shift->r->dir_config('AllowDownload') || '';
  return $d !~ /$NO/oi;
}

# return true if streaming is allowed from this directory
sub stream_ok {
  my $d = shift->r->dir_config('AllowStream') || '';
  return $d !~ /$NO/oi;
}

# return true if playing locally is allowed
sub playlocal_ok {
  my $d = shift->r->dir_config('AllowPlayLocally') || '';
  return $d =~ /$YES/oi;
}

# return true if we should check that the client can accomodate streaming
sub check_stream_client {
  my $d = shift->r->dir_config('CheckStreamClient') || '';
  return $d =~ /$YES/oi;
}

# return true if client can stream
sub is_stream_client {
  my $r = shift->r;
  my $h = $r->headers_in;

  $h->{'Icy-MetaData'}   # winamp/xmms
    || $h->{'Bandwidth'}   # realplayer
      || $h->{'Accept'} =~ m!\baudio/mpeg\b!  # mpg123 and others
	|| $h->{'User-Agent'} =~ m!^NSPlayer/!  # Microsoft media player
	  || $h->{'User-Agent'} =~ m!^xmms/!;
}

# whether to read info for each MP3 file (might take a long time)
sub read_mp3_info {
  my $d = shift->r->dir_config('ReadMP3Info') || '';
  return $d !~ /$NO/oi;
}

# whether to time out streams
sub stream_timeout {
  shift->r->dir_config('StreamTimeout') || 0;
}

# how long an album list is considered so long we should put buttons
# at the top as well as the bottom
sub file_list_is_long { shift->r->dir_config('LongList') || 10 }

sub home_label {
  my $self = shift;
  my $home = $self->r->dir_config('HomeLabel') ||
    $self->x('Home');
  return lc($home) eq 'hostname' ? $self->r->hostname : $home;
}

sub path_style {  # style for the path to parent directories
  lc(shift->r->dir_config('PathStyle')) || 'Staircase';
}

# where is our cache directory (if any)
sub cache_dir    {
  my $self = shift;
  return unless my $dir  = $self->r->dir_config('CacheDir');
  my $rootdir = Apache2::ServerUtil::server_root();
  return $dir if $dir =~ m!^/!;
  return "$rootdir/$dir";
}

# columns to display
sub subdir_columns {shift->r->dir_config('SubdirColumns') || SUBDIRCOLUMNS  }
sub playlist_columns {shift->r->dir_config('PlaylistColumns') || PLAYLISTCOLUMNS }

# various configuration variables
sub default_dir   { shift->r->dir_config('BaseDir') || BASE_DIR  }
sub stylesheet    { shift->get_dir('Stylesheet', STYLESHEET)     }
sub parent_icon   { shift->get_dir('ParentIcon',PARENTICON)      }
sub cd_list_icon  {
  my $self   = shift;
  my $subdir = shift;
  my $image = $self->r->dir_config('CoverImageSmall') || COVERIMAGESMALL;
  my $directory_specific_icon = $self->r->filename."/$subdir";
  my $uri = escape($subdir)."/$image";

  # override the icon filename if the dir is fully pathed
  if (substr($subdir, 0, 1) eq "/") {
    $directory_specific_icon = $self->r->lookup_uri($subdir)->filename;
  }
  $directory_specific_icon .= "/$image";
  
  return -e $directory_specific_icon 
    ? $uri
    : $self->get_dir('DirectoryIcon',CDLISTICON);
}
sub playlist_icon {
  my $self = shift; 
  my $image = $self->r->dir_config('PlaylistImage') || PLAYLISTIMAGE;
  my $directory_specific_icon = $self->r->filename."/$image";
  warn $directory_specific_icon if DEBUG;
  return -e $directory_specific_icon
    ? $self->r->uri . "/$image"
    : $self->get_dir('PlaylistIcon',PLAYLISTICON);
}
sub song_icon     { shift->get_dir('SongIcon',SONGICON)          }
sub arrow_icon    { shift->get_dir('ArrowIcon',ARROWICON)        }

sub help_url      { shift->get_dir('HelpURL',   HELPIMGURL)  }
sub help_img_url  { shift->get_dir('HelpImgURL',HELPIMGURL)  }

sub cd_icon {
  my $self = shift;
  my $dir = shift;
  my $coverimg = $self->r->dir_config('CoverImage') || COVERIMAGE;
  if (-e "$dir/$coverimg") {
    $coverimg;
  } else {
    $self->get_dir('TitleIcon',CDICON);
  }
}
sub missing_comment {
  my $self = shift;
  my $missing = $self->r->dir_config('MissingComment') || '';
  return if $missing eq 'off';
  $missing = $self->lh->maketext('unknown') unless $missing;
  $missing;
}

# create description string
sub description {
  my $self = shift;
  my $data = shift;
  my $description;
  my $format = $self->r->dir_config('DescriptionFormat');
  if ($format) {
    ($description = $format) =~ s{%([atfglncrdmsqS%])}
      {$1 eq '%' ? '%'
	 : $data->{$FORMAT_FIELDS{$1}}
       }gxe;
  } else {
    $description = $data->{title} || basename($data->{filename},
					      $self->suffixes());
    $description .= " - $data->{artist}" if $data->{artist};
    $description .= " ($data->{album})"  if $data->{album};
  }
  return $description;
}

sub stream_base {
  my $self = shift;
  my $suppress_auth = shift;
  my $r = $self->r;

  my $auth_info = '';
  # the check for auth_name() prevents an annoying message in
  # the apache server log when authentication is not in use.
  if ($r->auth_name && !$suppress_auth) {
    my ($res,$pw) = $r->get_basic_auth_pw;
    if ($res == 0) { # authentication in use
      my $user = $r->user;
      $auth_info = "$user:$pw\@";
    }
  }

  if ((my $basename = $r->dir_config('StreamBase')) && !$self->is_localnet()) {
    $basename =~ s!http://!http://$auth_info! if $auth_info;
    return $basename;
  }

  my $host = $r->hostname        || $r->server->server_hostname;
  my $port = $r->get_server_port || $r->server->port;
  $host .= ":$port" unless $port == 80;
  return "http://${auth_info}${host}";
}


# patterns to skip
sub skip_directory {
  my $self = shift;
  my $dir = shift;
  return 1 if $dir =~ /^\./;
  return 1 if $dir eq 'CVS';
  return 1 if $dir eq 'RCS';
  return 1 if $dir eq 'SCCS';
  undef;
}

# Checks if the requesting client is on the same machine as the server.
# If it is, then it points the playlist at the physical file, which
# allows the player to fast forward, pause, etc.
sub is_local {
  my $self = shift;
  my $r = $self->r;
  my ($serverport,$serveraddr) = sockaddr_in($r->connection->local_addr);
  my ($remoteport,$remoteaddr) = sockaddr_in($r->connection->remote_addr);
  return $serveraddr eq $remoteaddr;
}

# Check if the requesting client is on the local network, as defined by
# the LocalNet directive
sub is_localnet {
  my $self = shift;
  return 1 if $self->is_local;  # d'uh
  my @local = split /\s+/,$self->r->dir_config('LocalNet') or return;

  my $remote_ip = $self->r->connection->remote_ip . '.';
  foreach (@local) {
    $_ .= '.' unless /\.$/;
    return 1 if index($remote_ip,$_) == 0;
  }
  return;
}

sub supported_type {
   my $self = shift;
   my $type = shift;
   return $self->{'supported_types'}->{$type};
}

sub suffixes {
   my $self = shift;
   return @{ $self->{'suffixes'}};
}

1;

__END__

=head1 NAME

Apache::MP3 - Generate streamable directories of MP3 and Ogg Vorbis files

=head1 SYNOPSIS

 # httpd.conf or srm.conf
 AddType audio/mpeg     mp3 MP3
 AddType audio/playlist m3u M3U
 AddType audio/x-scpls  pls PLS
 AddType application/x-ogg ogg OGG

 # httpd.conf or access.conf
 <Location /songs>
   SetHandler perl-script
   PerlHandler Apache::MP3
 </Location>

  # Or use the Apache::MP3::Sorted subclass to get sortable directory listings
 <Location /songs>
   SetHandler perl-script
   PerlHandler Apache::MP3::Sorted
 </Location>

  # Or use the Apache::MP3::Playlist subclass to get persistent playlists
 <Location /songs>
   SetHandler perl-script
  PerlHandler Apache::MP3::Playlist
 </Location>

A B<demo version> can be browsed at http://www.modperl.com/Songs/.

=head1 DESCRIPTION

This module makes it possible to browse a directory hierarchy
containing MP3, Ogg Vorbis, or Wav files, sort them on various
fields, download them, stream them to an MP3 decoder like WinAmp, and
construct playlists.  The display is configurable and subclassable.

NOTE: This version of Apache::MP3 is substantially different from
the pre-2.0 version described in The Perl Journal.  Specifically, the
format to use for HREF links has changed.  See I<Linking> for details.

=head2 Installation

This section describes the installation process.

=over 4

=item 1. Prequisites

This module requires mod_perl, MP3::Info (to stream MP3 files),
Ogg::Vorbis (to stream OggVorbis files), and Audio::Wav (for Wave
files) all of which are available on CPAN.

The module will automatically adjust for the absence of one or more of
the MP3::Info, Ogg::Vorbis or Audio::Wav modules by inhibiting the
display of the corresponding file type.

=item 2. Configure MIME types

Apache must be configured to recognize the mp3 and MP3 extensions as
MIME type audio/mpeg.  Add the following to httpd.conf or srm.conf:

 AddType audio/mpeg mp3 MP3
 AddType audio/playlist m3u M3U
 AddType audio/x-scpls  pls PLS
 AddType application/x-ogg ogg OGG
 AddType audio/wav wav WAV

Note that you need extemely large amounts of bandwidth to stream Wav
files, and that few audio file players currently support this type of
streaming.  Wav file support is primarily intended to allow for
convenient downloads.

=item 3. Install icons and stylesheet

This module uses a set of icons and a cascading stylesheet to generate
its song listings.  By default, the module expects to find them at the
url /apache_mp3.  Create a directory named apache_mp3 in your document
root, and copy into it the contents of the F<apache_mp3> directory
from the Apache-MP3 distribution.

You may change the location of this directory by setting the
I<BaseDir> configuration variable.  See the I<Customizing> section for
more details.

=item 4. Set Apache::MP3 to be the handler for the MP3 directory

In httpd.conf or access.conf, create a E<lt>LocationE<gt> or
E<lt>DirectoryE<gt> section, and make Apache::MP3 the handler for this
directory.  This example assumes you are using the URL /Songs as the
directory where you will be storing song files:

  <Location /Songs>
    SetHandler perl-script
    PerlHandler Apache::MP3
  </Location>

If you would prefer an MP3 file listing that allows the user to sort
it in various ways, set the handler to use the Apache::MP3::Sorted
subclass instead.  A further elaboration is Apache::MP3::Playlist,
which uses cookies to manage a persistent playlist for the user.

=item 5. Load MP3::Info in the Perl Startup file (optional)

For the purposes of faster startup and memory efficiency, you may load
the MP3::Info module at server startup time.  If you have a mod_perl
"startup" file, enter these lines:

  use MP3::Info;
  use Apache::MP3;

=item 6. Set up MP3 directory

Create a directory in the web server document tree that will contain
the MP3 files to be served.  The module recognizes and handles
subdirectories appropriately.  I suggest organizing directories
hierarchically by artist and/or album name.

If you place a file named "cover.jpg" in any of the directories, that
image will be displayed at the top of the directory listing.  You can
use this to display cover art.

If you place a list of .mp3 file names in a file with the .m3u
extension, it will be treated as a playlist and displayed to the user
with a distinctive icon.  Selecting the playlist icon will download
the playlist and stream its contents.  The playlist must contain
relative file names, but may refer to subdirectories, as in this
example:

  # file: folk_favorites.m3u
  Never_a_Moment_s_Thought_v2.mp3
  Peter Paul & Mary - Leaving On A Jet Plane.mp3
  Simon and Garfunkel/Simon And Garfunkel - April Come She Will.mp3

Likewise, if you place a list of shoutcast URLs into a file with the
pls extension, it will be treated as a playlist and displayed to the
user with a distinctive icon.  Selecting the playlist icon will
contact the shoutcast servers in the playlist and stream their
contents.  The playlist syntax is as in this example:

  [playlist]
  numberofentries=2
  File1=http://205.188.245.132:8038
  Title1=Monkey Radio: Grooving. Sexy. Beats.
  Length1=-1
  File2=http://205.188.234.67:8052
  Title2=SmoothJazz
  Length2=-1
  Version=2

Example shoutcast files can be downloaded from http://www.shoutcast.com
You can find a lot of good MP3 broadcasts there, most of them
commercial-free.

Apache::MP3 permits you to directly use CDDB data without embedding it
in ID3 tags.  To take advantage of this feature, your MP3 files should
have file names of this form: track-XX.mp3.  Then, place a CDDB index
file in the same directory as the tracks and name it INDEX.  For
example, you might execute this command

  cddbcmd cddb read soundtrack cb115c11 > INDEX

to create an INDEX file for the Mulholland Drive soundtrack.  The
32-bit disc ID can be obtained with a program such as cd-discid.

=item 8. Set up an information cache directory (optional)

In order to generate its MP3 listing, Apache::MP3 must open each sound
file, extract its header information, and close it.  This is time
consuming, particularly when recursively generating playlists across
multiple directories.  To speed up this process, Apache::MP3 has the
ability cache MP3 file information in a separate directory area.

To configure this, choose a directory that the Web server has write
access for, such as /usr/tmp.  Then add a configuration variable like
the following to the <Location> directive:

 PerlSetVar  CacheDir       /usr/tmp/mp3_cache

If the designated directory does not exist, Apache::MP3 will attempt
to create it, limited of course by the Web server's privileges.  You
may need to create the mp3_cache directory yourself if /usr/tmp is not 
world writable.

=back

Open up the MP3 URL in your favorite browser.  You should be able to
see directory listings, and download and stream your songs.  If things
don't seem to be working, checking the server error log for messages.

=head1 CUSTOMIZING

Apache::MP3 can be customized in three ways: (1) by changing
per-directory variables; (2) changing settings in the Apache::MP3
cascading stylesheet; and (3) subclassing Apache::MP3 or
Apache::MP3::Sorted.

=head2 Per-directory configuration variables

Per-directory variables are set by I<PerlSetVar> directives in the
Apache::MP3 E<lt>LocationE<gt> or E<lt>DirectoryE<gt> section.  For
example, to change the icon displayed next to subdirectories of MP3s,
you would use I<PerlSetVar> to change the I<DirectoryIcon> variable:

  PerlSetVar DirectoryIcon big_cd.gif

This following table summarizes the configuration variables.  A more
detailed explanation of each follows in the subsequent sections.

Table 1: Configuration Variables

 Name                  Value	        Default
 ----                  -----            -------
 GENERAL OPTIONS
 AllowDownload	       yes|no		yes
 AllowStream	       yes|no		yes
 AllowPlayLocally      yes|no           yes
 CheckStreamClient     yes|no		no
 ReadMP3Info	       yes|no		yes
 StreamTimeout         integer          0

 DIRECTORY OPTIONS
 BaseDir	       URL		/apache_mp3
 CacheDir              path             -none-
 HelpImgURL            URL              apache_mp3_fig1.gif:374x292
 StreamBase            URL              -none-
 LocalNet              subnet           -none-

 DISPLAY OPTIONS
 ArrowIcon	       URL		right_arrow.gif
 CoverImage            filename         cover.jpg
 CoverImageSmall       filename         cover_small.jpg
 PlaylistImage         filename         playlist.jpg
 DescriptionFormat     string           -see below-
 DirectoryIcon	       URL		cd_icon_small.gif
 PlaylistIcon          URL              playlist.gif
 Fields                list             title,artist,duration,bitrate
 HomeLabel	       string		"Home" (or translation)
 LongList	       integer		10
 MissingComment        string           "unknown" (or translation)
 PathStyle             Staircase|Arrows|Slashes Staircase
 SongIcon	       URL		sound.gif
 SubdirColumns	       integer		1
 Stylesheet	       URL		apache_mp3.css
 TitleIcon	       URL		cd_icon.gif
 DefaultLanguage       languagetag      en-US

=head2 General Configuration Variables

=over 4

=item AllowDownload I<yes|no>

You may wish for users to be able to stream songs but not download
them to their local disk.  If you set AllowDownload to "no",
Apache::MP3 will not generate a download link for MP3 files.  It will
also activate some code that makes it inconvenient (but not
impossible) for users to download the MP3s.

The module recognizes the arguments "yes", "no", "true" and "false".
The default is "yes".

Note that this setting only affects MP3 files.  Other files, including
cover art and playlists, can still be downloaded.

=item AllowStream I<yes|no>

If you set AllowStream to "no", users will not be able to stream songs
or generate playlists.  I am not sure why one would want this feature,
but it is included for completeness.  The default is "yes."

=item AllowPlayLocally I<yes|no>

If you set AllowPlayLocally to "yes", then the playlists generated by
the module will point to the physical files when handling requests
from a user that happens to be working on the same machine.  This is
more efficient, and allows the user to pause playback, fast forward,
and so on.  Otherwise, the module will treat local users and remote
users the same.  The default is "no".

=item CheckStreamClient I<yes|no>

Setting CheckStreamClient to "yes" enables code that checks whether
the client claims to be able to accept streaming MPEG data.  This
check isn't foolproof, but supports at least the most popular MP3
decoders (WinAmp, RealPlayer, xmms, mpg123).  It also makes it harder
for users to download songs by pretending to be a streaming player.

The default is "no".

=item ReadMP3Info I<yes|no>

This controls whether to extract field information from the MP3
files.  The default is "yes".

If "no" is specified, all fields in the directory listing will be
blank except for I<filename> and I<description>, which will both be
set to the physical filename of the MP3 file.

=item StreamTimeout I<integer>

For demo mode, you can specify a stream timeout in seconds.
Apache::MP3 will cease streaming the file after the time specified.
Because this feature uses the average bitrate of the song, it may be
off by a second or two when streaming variable bitrate MP3s.

=back

=head2 Configuration Variables Affecting Paths and Directories

=over 4

=item BaseDir I<URL>

The B<BaseDir> variable sets the URL in which Apache::MP3 will look
for its icons and stylesheet.  You may use any absolute local or
remote URL. Relative URLs are not accepted.

The default is "/apache_mp3."

=item CacheDir I<path>

This variable sets the directory path for Apache::MP3's cache of MP3
file information.  This must be an absolute path in the physical file
system and be writable by Apache.  If not specified, Apache::MP3 will
not cache the file information, resulting in slower performance on
large directories.

=item HelpImgURL I<URL:widthxheight>

The URL of the image that's inlined on the page that appears
when the user presses the "Quick Help
Summary" link at the bottom of the page.  You can declare the
size of this image
by adding ":WxH" to the end of the URL, where W and H are the width
and height, respectively.

Default: apache_mp3_help.gif:614x498

Note: I prepared this image on an airplane, so it isn't as clean as I
would like.  Volunteers to make a better help page are welcomed!

=item StreamBase I<URL>

A URL to use as the base for streaming.  The default is to use the
same host for both directory listings and streaming.  This may be of
use when running behind a firewall and the web server can't figure out
the correct address for the playlist automatically.

Example:

If the song requested is http://www.foobar.com/Songs/Madonna_live.m3u?stream=1

and B<StreamBase> is set to I<http://streamer.myhost.net>, then the URL
placed in the playlist will be

 http://streamer.myhost.net/Songs/Madonna_live.m3u?stream=1

The path part of the URL is simply appended to StreamBase.  If you
want to do more sophisticated URL processing, use I<mod_rewrite> or
equivalent.

=item LocalNet I<URL>

This configuration variable is used in conjunction with B<StreamBase>
to disable B<StreamBase> for clients on the local network.  This is
needed for firewall configurations in which the web server is accessed
by one address & port by hosts behind the firewall, and by another
address & port by hosts outside the firewall.

The argument is a dotted subnet address, or a space-delimited list of
subnets.  For example:

  PerlSetVar LocalNet "192.168.1 192.168.2 127.0.0.1"

Address matching is done by matching the address from left to right,
with an implied dot added to the end of the subnet address.  More
complex subnet matching using netmasks is desirable, but not
implemented.

=back

=head2 Configuration Variables Affecting the Visual Display

=over 4

=item ArrowIcon I<URL>

Set the icon used for the arrows displayed between the components of
the directory path at the top of the directory listing.

=item CoverImage I<filename>

Before displaying a directory, Apache::MP3 will look inside the
directory for an image file.  This feature allows you to display
digitized album covers or other customized icons.  The default is
"cover.jpg", but the image file name can be changed with
I<CoverImage>.  If the file does not exist, the image specified by
I<TitleIcon> will be displayed instead.

=item CoverImageSmall I<filename>

Before displaying the list of subdirectories, Apache::MP3 will check
inside of each for an image file of this name.  If one is present, the
image will displayed rather than the generic I<DirectoryIcon>.  The
default is "cover_small.jpg".

=item DescriptionFormat I<string>

The "Description" field, which is used both in the Description column
of the directory index and in the metadata sent to the player during
streaming, has a default format of I<title>-I<artist>-I<album>.  The
description is constructed in such a way that the hyphen is omitted if
the corresponding field of the song's MP3 tag is empty.

You can customize this behavior by providing a I<DescriptionFormat>
string.  These strings combine constant characters with %x format
codes in much the way that sprintf() does.  For example, the directive
shown below will create descriptions similar to I<[Madonna] Like a
Virgin (1980)>.

  PerlSetVar DescriptionFormat "[%a] %t (%y)"

The full list of format codes follows:

Table 2: I<DescriptionFormat> Field Codes

  Code         Description
  ----         -----------

  %a	       Artist name
  %c	       Comment
  %d	       Duration, in format 00:00 (like 15:20 for 15 mins 20 sec)
  %f	       Name of physical file (minus path)
  %g	       Genre
  %l	       Album name
  %m	       Minutes portion of duration, usually used with %s
  %n	       Track number
  %q	       Sample rate, in kHz
  %r	       Bitrate, in kbps
  %s	       Seconds portion of duration, usually used with %m
  %S	       Duration, expressed as total seconds
  %t	       Title
  %y	       Year

=item DirectoryIcon I<URL>

Set the icon displayed next to subdirectories in directory listings,
"cd_icon_small.gif" by default.  This can be overridden on a
directory-by-directory basis by placing a I<CoverImageSmall> image
into the directory that you want to customize.

=item PlaylistIcon I<URL>

Set the icon displayed next to playlists in the playlist listings,
"playlist.gif" by default.  You can change this icon on a
directory-by-directory basis by placing a file with this name in the
current directory.

=item PlaylistImage I<filename>

Before displaying a playlist, the module will check inside the current
directory for an image file named "playlist.jpg" to use as its icon.
This directive changes the name of the playlist image file.  If no
image is found, the icon specified by I<PlaylistIcon> is used instead.

=item Fields I<title,artist,duration,bitrate>

Specify what MP3 information fields to display in the song listing.
This should be a list delimited by commas, "|" symbols, or any other
non-word character.

The following are valid fields:

Table 3: Field Names For use with the I<Fields> Configuration Variable 

    Field        Description
    -----        -----------

    album	 The album
    artist       The artist
    bitrate      The bitrate, expressed in kbps
    comment      The comment field
    duration     Duration of the song in hour, minute, second format
    description	 Description as specified by DescriptionFormat
    filename	 The physical name of the .mp3 file
    genre        The genre
    min          The minutes portion of the duration
    seconds      Total duration of the song in seconds
    sec          The seconds portion of the duration
    samplerate   The sampling rate, in KHz
    title        The title of the song
    track	 The track number
    year         The album year

Note that MP3 rip and encoding software differ in what fields they
capture and the exact format of such fields as the title and album.
Field names are case insensitive.

Previous versions of this module used "kbps" instead of "bitrate".
This has been changed.

=item HomeLabel I<string>

This is the label for the link used to return to the site's home
page.  You may use plain text or any fragment of HTML, such as an
<IMG> tag.

=item LongList I<integer>

The number of lines in the list of MP3 files after which it is
considered "long".  In long lists, the control buttons are placed at
the top as well as at the bottom of the table.  Defaults to 10.

=item MissingComment I<string>

This is the text string to use when an MP3 or Vorbis comment is missing;
it is "unknown" (or its translation) by default. For example, if the
module is configured to display the artist name, but a music file is
missing this field, "unknown" (or its translation) will be printed
instead. To turn this feature off, use an argument of "off"; missing
fields will then be blank.

  PerlSetVar MissingComment off

=item PathStyle I<Staircase|Arrows>

Controls the style with which the parent directories are displayed.
The options are "Staircase" (the default), which creates a
staircase-style display (each child directory is on a new line and
offset by 0.3 em).  The other is "Arrows", in which the entire
directory list is on a single line and separated by graphic arrows.
Try them both and choose the one you prefer.

=item SongIcon I<URL>

Set the icon displayed at the beginning of each line of the MP3 file
list, "sound.gif" by default.

=item SubdirColumns I<integer>

The number of columns in which to display subdirectories (the small
"CD icons").  A value other than 1 suppresses the display of
subdirectory access-time and modification-time info.  Default 1.

=item PlaylistColumns I<integer>

The number of columns in which to display playlists. Default 3.

=item Stylesheet I<URL>

Set the URL of the cascading stylesheet to use, "apache_mp3.css" by
default.  If the URL begins with a slash it is treated as an absolute
URL.  Otherwise it is interpreted as relative to the BaseDir
directory.

=item TitleIcon I<URL>

Set the icon displayed next to the current directory's name in the
absence of a coverimage, "cd_icon.gif" by default.  In this, and the
other icon-related directives, relative URLs are treated as relative
to I<BaseDir>.

=item DefaultLanguage I<languagetag>

This determines what language the interface should try appearing in,
if none of the languages from the browser's Accept-Language header
can be supported.  For information on language tags, see
L<I18N::LangTags::List>.  Example value: "zh-cn" for
PRC-style Chinese.

=back

=head2 Stylesheet-Based Configuration

You can change the appearance of the page by changing the cascading
stylesheet that accompanies this module, I<apache_mp3.css>.  The
following table describes the tags that can be customized:

Table 4: Stylesheet Class Names

 Class Name           Description
 ----------           ----------

 BODY                 General defaults
 H1                   Current directory path
 H2                   "CD Directories" and "Song List" headings
 TR.title             Style for the top line of the song listing
 TR.normal            Style for odd-numbered song listing lines
 TR.highlight         Style for even-numbered song listing lines
 .directory           Style for the title of the current directory
 .subdirectory        Style for the title of subdirectories
 P                    Ordinary paragraphs
 A                    Links
 INPUT                Fill-out form fields

=head2 Subclassing this Module

For more extensive customization, you can subclass this module.  The
Apache::MP3::Sorted module illustrates how to do this.  

Briefly, your module should inherit from Apache::MP3 (or
Apache::MP3::Sorted) either by setting the C<@ISA> package global or,
in Perl 5.6 and higher, with the C<use base> directive.  Your module
can then override existing methods and define new ones.

This module uses the I<mod_perl> method invocation syntax for handler
invocation.  Because of this, if you override the handler() method, be
sure to give it a prototype of ($$).  If you override new(), be sure
to place the Apache::Request object in an instance variable named 'r'.
See the MP3.pm module for details.

One implication of using the method invocation syntax is that the
Apache::MP3 object is created at server configuration time.  This
means that you cannot tweak the code and simply restart the server,
but must formally stop and relaunch the server every time you change
the code or install a new version.  This disadvantage is balanced by a
savings in memory consumption and performance.

See I<The Apache::MP3 API> below for more information on overriding
Apache::MP3 methods.

=head1 Linking to this module

You may wish to create links to MP3 files and directories manually.
The rules for creating HREFs are different from those used in earlier
versions of Apache::MP3, a decision forced by the fact that the
playlist format used by popular MP3 decoders has changed.

The following rules apply:

=over 4

=item Download an MP3 file

Create an HREF using the unchanged name of the MP3 file.  For example, 
to download the song at /songs/Madonna/like_a_virgin.mp3, use:

 <a href="/Songs/Madonna/like_a_virgin.mp3">Like a Virgin</a>

=item Stream an MP3 file

Replace the MP3 file's extension with .m3u and add the query string
"play=1".  Apache::MP3 will generate a playlist for the streaming MP3
decoder to load.  Example:

 <a href="/Songs/Madonna/like_a_virgin.m3u?play=1">
         Like a streaming Virgin</a>

=item Stream a directory

Append "/playlist.m3u?Play+All=1" to the end of the directory name:

 <a href="/Songs/Madonna/playlist.m3u?Play+All=1">Madonna Lives!</a>

The capitalization of "Play All" is significant.  Apache::Mp3 will
generate a playlist containing all MP3 files within the directory.

=item Stream a directory heirarchy recursively

Append "/playlist.m3u?Play+All+Recursive=1" to the end of the directory name:

 <a href="/Songs/HipHop/playlist.m3u?Play+All+Recursive=1">Rock me</a>

The capitalization of "Play All Recursive" is significant.
Apache::MP3 will generate a playlist containing all MP3 files within
the directory and all its subdirectories.

=item Shuffle and stream a directory

Append "/playlist.m3u?Shuffle+All=1" to the end of the directory name:

 <a href="/Songs/HipHop/playlist.m3u?Shuffle+All">Rock me</a>

Apache::MP3 will generate a playlist containing all MP3 files within
the directory and all its subdirectories, and then randomize its order.

=item Shuffle an entire directory heirarchy recursively

Append "/playlist.m3u?Shuffle+All+Recursive=1" to the end of the directory name:

 <a href="/Songs/HipHop/playlist.m3u?Shuffle+All+Recursive=1">Rock me</a>

Apache::MP3 will generate a playlist containing all MP3 files within
the directory and all its subdirectories, and then randomize its order.

=item Play a set of MP3s within a directory

Append "/playlist.m3u?Play+Selected=1;file=file1;file=file2..." to the 
directory name:

 <a
 href="/Songs/Madonna/playlist.m3u?Play+Selected=1;file=like_a_virgin.mp3;file=evita.mp3">
 Two favorites</a>

Again, the capitalization of "Play Selected" counts.

=item Display a sorted directory

Append "?sort=field" to the end of the directory name, where field is
any of the MP3 field names:

 <a href="/Songs/Madonna/?sort=duration">Madonna lives!</a>

=back

=head1 The Apache::MP3 API

The Apache::MP3 object is a blessed hash containing a single key,
C<r>, which points at the current request object.  This can be
retrieved conveniently using the r() method.

Apache::MP3 builds up its directory listing pages in pieces, using a
hierarchical scheme.  The following diagram summarizes which methods
are responsible for generating the various parts.  It might help to
study it alongside a representative HTML page:

 list_directory()
 -------------------------  page top --------------------------------
    page_top()
    directory_top()

    <CDICON> <DIRECTORY> -> <DIRECTORY> -> <DIRECTORY>
    [Shuffle All] [Stream All]

    list_subdirs()

         subdir_list_top()
         ------------------------------------------------------------
         <CD Directories (6)>

         subdir_list()
               <cdicon> <title>   <cdicon> <title>  <cdicon> <title>
               <cdicon> <title>   <cdicon> <title>  <cdicon> <title>

         subdir_list_bottom()  # does nothing
         ------------------------------------------------------------

    list_playlists()

         playlist_list_top()
         ------------------------------------------------------------
         <CD Playlists (6)>

         playlist_list()
               <cdicon> <title>   <cdicon> <title>  <cdicon> <title>
               <cdicon> <title>   <cdicon> <title>  <cdicon> <title>

         playlist_list_bottom()  # does nothing
         ------------------------------------------------------------

    list_mp3s()
         mp3_list_top()
         ------------------------------------------------------------
         <Song List (4)>

         mp3_list()
             mp3_list_top()
               mp3_table_header()
                  <Select>                  Title          Kbps

               format_song() # called for each row
                  <icon>[] [fetch][stream]  Like a virgin  128
                  <icon>[] [fetch][stream]  American Pie   128
                  <icon>[] [fetch][stream]  Santa Evita     96
                  <icon>[] [fetch][stream]  Boy Toy        168

             mp3_list_bottom()
               [Play Selected] [Shuffle Selected]

    directory_bottom()
 -------------------------  page bottom -----------------------------

=head2 Method Calls

This section lists each of the Apache::MP3 method calls briefly.

=over 4 

=item $response_code = handler($request)

This is a the standard mod_perl handler() subroutine.  It creates a
new Apache::MP3 object, and then invokes its run() method.

=item $mp3 = Apache::MP3->new(@args)

This is a constructor.  It stores the passed args in a hash and
returns a new Apache::MP3 object.  If a single argument is passed it
assumes that it is an Apache::Request object and stores it under the
key "r".  You should not have to modify this method.

=item $request = $mp3->r()

Return the stored request object.

=item $boolean = $mp3->is_local()

Returns true if the requesting client is on the same machine as the
server.

=item $response_code = $mp3->run()

This is the method that interprets the CGI parameters and dispatches
to the routines that draw the directory listing, generate playlists,
and stream songs.

=item $response_code = $mp3->process_directory($dir)

This is the top-level method for generating the directory listing.  It
performs various consistency checks on the passed directory URL and
returns an Apache response code.  The list_directory() method actually 
does most of the formatting work.

=item $response_code = $mp3->download_file($file)

This method is called to download a file (not stream it).  It is
passed the URL of the requested file and returns an Apache response
code.  It checks whether downloads are allowed and if so allows Apache 
to take its default action.

=item $response_code = $mp3->stream($file)

This method is called to stream an MP3 file.  It is passed the URL of
the requested file and returns an Apche response code.

=item $fh = $mp3->open_file($file)

This method is called by stream() to open the file to be streamed.  It
accepts a file path and returns a filehandle.  This can be overridden
to do interesting things to the MP3 file, such as resample it or
collect statistics.

=item $mp3->send_playlist($urls,$shuffle)

This method generates a playlist that is sent to the browser.  It is
called from various places.  C<$urls> is an array reference containing 
the MP3 URLs to incorporate into the playlist, and C<$shuffle> is a
flag indicating that the order of the playlist should be randomized
prior to sending it.  No return value is returned.

=item @urls = $mp3->sort_mp3s($mp3_info)

This method sorts the hashref of MP3 files returned from find_mp3s(),
returning an array.  The implementation of this method in Apache::MP3
sorts by physical file name only.  Apache::MP3::Sorted has a more
sophisticated implementation.

=item @mp3s = $mp3->load_playlist($playlist)

This method loads a playlist file (.m3u) from disk and returns a
list of MP3 files contained in the playlist.

=item $mp3->playlist_list_bottom($playlists)

This method generates the footer at the bottom of the list
of playlists given by C<$playlists>. Currently it does nothing.

=item $mp3->playlist_list($playlists)

This method displays the playlists given by C<$playlists> in a nicely
formatted table.

=item $html = $mp3->format_playlist($playlist)

This method formats the indicated playlist by creating a fragment of
HTML containing the playlist icon, the stream links and the playlist
name. It returns a HTML fragment used by playlist_list().

=item $response_code = $mp3->list_directory($dir)

This is the top level formatter for directory listings.  It is passed
the URL of a directory and returns an Apache response code.

=item $mp3->page_top($dir)

This method begins the HTML at the top of the page from the initial
<head> section through the opening <body>.

=item $mp3->directory_top($dir)

This method lists the top part of the directory, including the title,
the directory navigation list, and the big CD Icon in the upper left.

=item $mp3->generate_navpath_staircase($dir)

This method generates the list of parent directories, displaying them
as links so that the user can navigate.  It takes the URL of the
current directory and returns no result.

=item $mp3->generate_navpath_arrows($dir)

This method does the same, except that the parent directories are
displayed on a single line, separated by arrows.

=item $mp3->directory_bottom($dir)

This method generates the bottom part of the directory listing,
including the module attribution and help information.

=item $mp3->subdir_list_top($directories)

This method generates the heading at the top of the list of
subdirectories.  C<$directories> is an arrayref containing the
subdirectories to display.

=item $mp3->subdir_list_bottom($directories)

This method generates the footer at the bottom of the list of
subdirectories given by C<$directories>.  Currently it does nothing.

=item $mp3->subdir_list($directories)

This method invokes sort_subdirs() to sort the subdirectories given by
C<$directories> and displays them in a nicely-formatted table.

=item @directories = $mp3->sort_subdirs($directories)

This method sorts the subdirectories given in C<$directories> and
returns a sorted B<list> (not an arrayref).

=item $html = $mp3->format_subdir($directory)

This method formats the indicated subdirectory by creating a fragment
of HTML containing the little CD icon, the shuffle and stream links,
and the subdirectory's name.  It returns an HTML fragment used by
subdir_list().

=item $mp3->get_help

This subroutine generates the "Quick Help Summary" link at the bottom
of the page.

=item $mp3->list_subdirs($subdirectories)

This is the top-level subroutine for listing subdirectories (the part
of the page in which the little CD icons appears).  C<$subdirectories>
is an array reference containing the subdirectories to display

=item $mp3->list_playlists($playlists)

This is the top-level subroutine for listing playlists. C<$playlists>
is an array reference containing the playlists to display.

=item $mp3->list_mp3s($mp3s)

This is the top-level subroutine for listing MP3 files.  C<$mp3s> is a
hashref in which the key is the path of the MP3 file and the value is
a hashref containing MP3 tag info about it.  This generates the
buttons at the top of the table and then calls mp3_table_header() and
mp3_list_bottom().

=item $mp3->mp3_table_header

This creates the first row (table headers) of the list of MP3 files.

=item $mp3->mp3_list_bottom($mp3s)

This method generates the buttons at the bottom of the MP3 file
listing. C<$mp3s> is a hashref containing information about each file.

=item $mp3->mp3_list($mp3s)

This routine sorts the MP3 files contained in C<$mp3s> and invokes
format_song() to format it for the table.

=item @buttons = $mp3->control_buttons

Return the list of buttons printed at the bottom of the MP3 file listing.

=item $arrayref = $mp3->format_song($song,$info,$count)

This method is called with three arguments.  C<$song> is the path to
the MP3 file, C<$info> is a hashref containing tag information from
the song, and C<$count> is an integer containing the song's position
in the list (which currently is unusued).  The method invokes
format_song_controls() and format_song_fields() to generate a list of
elements to be incorporated into cells of the table, and returns an
array reference.

=item @array = $mp3->format_song_controls($song,$info,$count)

This method is called with the same arguments as format_song().  It
returns a list (not an arrayref) containing the "control" elements of
one row of the MP3 list.  The control elements are all the doo-dads on
the left-hand side of the display, including the music icon, the
checkbox, and the [fetch] and [stream] links.

=item @array = $mp3->format_song_fields($song,$info,$count)

This method is called with the same arguments as format_song().  It
returns a list (not an arrayref) containing the rest of a row of the
MP3 file display.  This will include the title, artist, and so forth,
depending on the values of the Fields configuration. variable.

=item ($directories,$mp3s) = $mp3->read_directory($dir)

This method reads the directory in C<$dir>, generating an arrayref
containing the subdirectories and a hashref containing the MP3 files
and their information, which are returned as a two-element list.

=item $hashref = $mp3->fetch_info($file)

This method fetches the MP3 information for C<$file> and returns a
hashref containing the MP3 tag information as well as some synthesized
fields.  The synthesized fields are I<track>, which contains the same
information as I<tracknum>; I<description>, which contains the title,
album and artist merged together; and I<duration>, which contains the
duration of the song expressed as hours, minutes and seconds.  Other
fields are taken directly from the MP3 tag, but are downcased (for
convenience to other routines).

=item Apache::MP3->path_escape($scalarref)

This is a limited form of CGI::escape which does B<not> escape the
slash symbol ("/").  This allows URIs that correspond to directories
to be escaped safely.  The escape is done inplace on the passed scalar
reference.


=item @fields = $mp3->fields

Return the fields to display for each MP3 file.  Reads the I<Fields>
configuration variable, or uses a default list.

=item $hashref = $mp3->read_cache($file)

Reads the cache for MP3 information about the indicated file.  Returns
a hashref of the same format used by fetch_info().

=item $boolean = $mp3->write_cache($file,$info)

Writes MP3 information to cache.  C<$file> and C<$info> are the path
to the file and its MP3 tag information, respectively.  Returns a
boolean indicating the success of the operation.

=item $boolean = $mp3->download_ok

Returns true if downloading files is allowed.

=item $boolean = $mp3->stream_ok

Returns true if streaming files is allowed.

=item $boolean = $mp3->check_stream_client

Returns true if the module should check the browser/MP3 player for
whether it accepts streaming.

=item $boolean = $mp3->is_stream_client

Returns true if this MP3 player can accept streaming.  Note that this
is not a foolproof method because it checks a variety of
non-standardized headers and user agent names!

=item $boolean = $mp3->read_mp3_info

Returns true if the module should read MP3 info (true by default).

=item $seconds = $mp3->stream_timeout

Returns the number of seconds after which streaming should time out.
Used for "demo mode".

=item $lines = $mp3->file_list_is_long

Returns the number of lines in the MP3 file listing after which the
list is considered to be "long".  When a long list is encountered, the 
module places the control buttons at both the top and bottom of the
MP3 file table, rather than at the bottom only.  This method 

=item $html = $mp3->home_label

Returns a fragment of HTML to use as the "Home" link in the list of
parent directories.

=item $style = $mp3->path_style

Returns the style of the list of parent directories.  Either "arrows"
or "staircase".

=item $path = $mp3->cache_dir

Returns the directory for use in caching MP3 tag information

=item $int = $mp3->subdir_columns

Returns the number of columns to use in displaying subdirectories
(little CD icons).  If the return value is 1, directory access-time
and modification-time are displayed.  If not equal to one, these
data are suppressed.

=item $dir = $mp3->default_dir

Returns the base directory used for resolving relative paths in the
directories to follow.

=item miscellaneous directories and files

The following methods return the values of their corresponding
configuration variables, resolved against the base directory, if need
be:

 stylesheet()   URI to the stylesheet file
 parent_icon()	URI to the icon to use to move up in directory
                     hierarchy (no longer used)
 cd_icon        URI for the big CD icon printed in the upper left corner
 song_icon	URI for the music note icons printed for each MP3 file
 arrow_icon	URI for the arrow used in the navigation bar
 help_url	URI of the document to display when user asks for help

The following methods return the values of their corresponding
configuration variables, resolved against the current directory, but if
that fails, against the base directory.  This is useful for customizing
the appearance icons on a per-directory basis.  For example, I like my
directories containing shoutcast playlists to appear differently than
my directories containing mp3 and m3u files.

 cd_list_icon   URI for the little CD icons in the subdirectory listing
 playlist_icon  URI for the playlist icon

=item $boolean = $mp3->skip_directory($dir)

This method is called during directory listings.  It returns true if
the directory should not be displayed.  Currently it skips directories
beginning with a dot and various source code management directories.
You may subclass this to skip over other directories.

=back

=head1 BUGS

Although it is pure Perl, this module relies on an unusual number of
compiled modules.  Perhaps for this reason, it appears to be sensitive
to certain older versions of modules.

=head2 Random segfaults in httpd children

Before upgrading to Apache/1.3.6 mod_perl/1.24, I would see random
segfaults in the httpd children when using this module.  This problem
disappeared when I installed a newer mod_perl.

If you experience this problem, I have found that one workaround is to
load the MP3::Info module at server startup time using the mod_perl
perl.startup script made the problem go away.  This is an excerpt from
my perl.startup file:

 # the !/usr/local/bin/perl
 ...
 use Apache::Registry ();
 use Apache::Constants();
 use MP3::Info;
 use Apache::MP3;
 use CGI();
 use CGI::Carp ();

=head2 Can't use -d $r->finfo

Versions of mod_perl prior to 1.22 crash when using the idiom -d
$r->finfo (or any other idiom).  Since there are many older versions
still out there, I have replaced $r->finfo with $r->filename and
marked their locations in comments.  To get increased performance,
change back to $r->finfo.

=head2 Misc

In the directory display, the alignment of subdirectory icon with the
subdirectory title is a little bit off.  I want to move the title a
bit lower using some stylesheet magic.  Can anyone help?

=head1 SEE ALSO

L<Apache::MP3::Sorted>, L<Apache::MP3::Playlist>, L<MP3::Info>, L<Apache>,
L<Apache::MP3::L10N>

=head1 ACKNOWLEDGEMENTS

Tim Ayers <tayers@bridge.com> found and fixed a misfeature in the way
that playlists were sorted.

Chris Nandor identified various bugs in the module and provided
patches.

Sean M. Burke (E<lt>sburkeE<64>cpan.orgE<gt>)
internationalized this module and coordinated the
translators/localizers.  Each translator/localizer/consultant is
thanked in the respective
C<Apache/MP3/L10N/I<langname>.pm> file.

Caleb Epstein E<lt>cae@bklyn.orgE<gt>), for generalizing the
resampling module.

Allen Day E<lt>allenday@ucla.eduE<gt>, for implementing MP3::Icecast

=head1 AUTHOR

Copyright 2000, Lincoln Stein <lstein@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=cut

