package Apache2::EmbedMP3::Template;

use strict;
use warnings;

use Template;

my $default_template=<<EOF;
<html>
<head>
</head>
<body>
<style media="screen" type="text/css">
body {
background:#262523 none repeat scroll 0 0;
color:#DDDDCC;
font-family:"Trebuchet MS",Helvetica,Arial,sans-serif;
font-size:14px;
font-size-adjust:none;
font-stretch:normal;
font-style:normal;
font-variant:normal;
font-weight:normal;
line-height:1.5em;
}
/* Header */
#header {
margin: 1em auto;
width: 40em;
}

#header a, #header a:visited, #header a:active {
color: #eef;
text-decoration: none;
}

#header a:hover {
color: #ccb;
}
#posts {
	margin: 0 auto;
	width: 42em; 
}

   .post {
	background-color:#363B39;
	border:1px solid #494949;
     margin: 1.5em 0;
     padding: 1em; 
   }
   

h1 {
       font-size: 3em;
       font-weight: bold;
       line-height: 1em;
     }
.video{
	text-align:center;
}
</style>
<div id="header">
<h1>Apache2::EmbedMP3</h1>
<h2>[% artist %] - [% title %]</h2>
<h3>[% album %] ([% year %])</h3>
</div>

	<div id="posts">
	 <div class="post">
		<div class="video">
		[% player %]
		</div>
	 </div>
	 
	 <div class="post">
		<pre>
			[% lyrics %]
		</pre>
	 </div>
	</div>



<p align="center">Apache2::EmbedMP3 - <a href="http://axiombox.com/apache2-embedmp3">http://axiombox.com/apache2-embedmp3</a></p>
	
</body></html>
EOF

my $player = <<EOF;
	<script type="text/javascript" src="%%% js %%%"></script>

	<object 
		type="application/x-shockwave-flash"
		data="%%% wpaudioplayer %%%"
		id="audioplayer1"
		height="24"
		width="290">

	<param 
		name="movie" 
		value="%%% wpaudioplayer %%%">

	<param 
		name="FlashVars" 
		value="playerID=1&amp;soundFile=%%% url %%%">

	<param 
		name="quality" value="high">

	<param 
		name="menu" value="false">

	<param 
		name="wmode" value="transparent">
	
	</object> 

EOF

sub new {
	my $self = shift;
	return bless {};
}

sub process {
	my($self, %opts) = @_;
	my $opts = \%opts;

	if($opts->{template} and -r $opts->{template}) {
		open my $fh, "<", $opts->{template} or die $!;
		$default_template = "";
		while(<$fh>) {
			$default_template .= $_;
		}
		close $fh;
	}

	my $wpaudioplayer = "/wpaudioplayer.swf";
	$wpaudioplayer = $opts->{wpaudioplayer} if $opts->{wpaudioplayer};

  my $js = "/wpaudioplayer.js";
	$js = $opts->{js} if $opts->{js};

	my $url = $opts->{uri}."?".$opts->{md5};
	$player =~ s/%%% url %%%/$url/g;
	$player =~ s/%%% js %%%/$js/g;
	$player =~ s/%%% wpaudioplayer %%%/$wpaudioplayer/g;

	my $tt = Template->new;
	my $output;

	$tt->process(\$default_template, {
		player => $player,
		artist => $opts->{artist},
		title => $opts->{title},
		year => $opts->{year},
		album => $opts->{album},
		lyrics => $opts->{lyrics},
	}, \$output);
	
	return $output;

}

1;

__DATA__

