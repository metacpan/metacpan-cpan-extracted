package Apache::MP3::Skin;
# Subclasses Apache::MP3::Playlist and through the magic
# of HTML::Template allows Apache::MP3 to be skinned.

use strict;
use HTML::Template;
use Apache::Constants qw(:common REDIRECT HTTP_NO_CONTENT DIR_MAGIC_TYPE);
use constant COVERIMAGE   => 'cover.jpg';
use CGI qw(param escape);
use Apache::MP3::Playlist;
use Apache::File ();
use Apache::URI ();
use File::Basename 'dirname','basename';


use vars qw(@ISA $VERSION);
@ISA = 'Apache::MP3::Playlist';

$VERSION = '0.91';

sub process_playlist {
  my $self = shift;
  my $r = $self->r;
  my (@playlist,$changed);

  if (my $cookies = CGI::Cookie->parse($r->header_in('Cookie'))) {
    my $playlist = $cookies->{playlist};
    @playlist = $playlist->value if $playlist;
    if ($playlist[-1] && 
	$r->lookup_uri($playlist[-1])->content_type ne 'audio/mpeg') {
      $self->{possibly_truncated}++;
      pop @playlist;  # get rid of the last
    }
  }

  if (param('Clear All')) {
    @playlist = ();
    $changed++;
  }

  if (param('Clear Selected')) {
    my %clear = map { $_ => 1 } param('file') or return HTTP_NO_CONTENT;
    @playlist = grep !$clear{$_},@playlist;
    $changed++;
  }

  if (param('Add All to Playlist')) {
    my %seen;
    @playlist = grep !$seen{$_}++,(@playlist,@{$self->find_mp3s});
    $changed++;
  }

  if (param('Add to Playlist')) {
    my $dir = dirname($r->uri);
    my @new = param('file') or return HTTP_NO_CONTENT;
    my %seen;
    # The line below is the only line that's different than SUPER::process_playlist
    @playlist = grep !$seen{$_}++,(@playlist,map {(m/^\//) ? "$_" : "$dir/$_" } @new);
    $changed++;
  }

  if (param('Play Selected') and param('playlist')) {
    my @uris = param('file') or return HTTP_NO_CONTENT;
    return $self->send_playlist(\@uris);
  }
  
  if (param('Shuffle All') and param('playlist')) {
    return HTTP_NO_CONTENT unless @playlist;
    return $self->send_playlist(\@playlist,'shuffle');
  }

  if (param('Play All') and param('playlist')) {
    return HTTP_NO_CONTENT unless @playlist;
    return $self->send_playlist(\@playlist);
  }

  if ($changed) {
    my $c = CGI::Cookie->new(-name  => 'playlist',
			     -value => \@playlist);
    tied(%{$r->err_headers_out})->add('Set-Cookie' => $c);
    (my $uri = $r->uri) =~ s!playlist\.m3u$!!;
    $self->path_escape(\$uri);
    $r->err_header_out(Location => $uri);
    return REDIRECT;
  }

  $self->playlist(@playlist);
  return;
}


sub run {
  my $self = shift;
  my $r = $self->r;

  if (param('Shuffle Selected')) {
    return HTTP_NO_CONTENT unless my @files = param('file');
    $self->shuffle(\@files);
    my $uri = dirname($r->uri);
    $self->send_playlist([map { (m/^\//) ? "$_" : "$uri/$_" } @files]);
    return OK;
  }  
  
  return $self->SUPER::run();
  
}



# override the list_directory in Apache::MP3, see if there's a skin file.
# if there's a skin file, we'll handle it otherwise pass it back (SUPER)
# to Apache::MP3 
sub list_directory {
  my $self = shift;
  my $dir  = shift;
  return DECLINED unless my ($directories,$mp3s,$playlists) 
    = $self->read_directory($dir);

  if ($self->r->header_only) {
    $self->r->send_http_header('text/html');
    return OK;
  }
  
  my $skin = $self->get_skin_path($dir);
  
  if ($skin) {
    $self->r->send_http_header('text/html');
    
    # open the html template
    my $template = HTML::Template->new(filename => $skin, die_on_bad_params=>0, loop_context_vars=>1);
    
    $self->set_template_params($template, $dir, $directories, $mp3s);
    # print the template
    my $page = $template->output;

    #add the javascript tag
    my $script_tag = "<SCRIPT language=\"JavaScript\" src=\"".$self->default_dir."/apache_mp3_skin.js\"></SCRIPT>";

    
    $page =~ s!(</HEAD[^>]*>)!$script_tag$1!oi;
    $page =~ s!(<BODY[^>]*>)!$1<FORM NAME="apache_mp3_skin">!oi;
    $page =~ s!(</BODY[^>]*>)!</FORM>$1!oi;
    
    print $page;

  } else {
    return $self->SUPER::list_directory($dir);
  }

  return OK;
}



sub set_template_params {
  my ($self, $template, $dir, $directories, $mp3s) = @_;
  my @inner_loops;
  my $params_ref = $self->set_dir_context_params($template, $dir, $self->r->uri, $directories, $mp3s, \@inner_loops);
  $template->param( $params_ref );
  return;
}



sub set_dir_context_params {
  my ($self, $template, $dir, $uri, $directories, $mp3s, $inner_loops, $count) = @_;
  
  # Warning: Hack following.  A double '//' is creeping into $uri.  Remove it.  
  if ($uri) {
    $uri =~ s/\/\//\//g;
  }
  my @param_names;
  my @inners = @$inner_loops;
  if ($#inners > -1) {
    @param_names = $template->query(loop => $inner_loops);
  } else {
    @param_names = $template->query();  
  }

  my %params;
    
  foreach (@param_names) {
    my $p = lc $_;
    if ($p =~ m/^__\S*__$/) {
        $params{$_} = $self->set_loop_params($p,$count);
	} elsif ($p eq "is_dir") {
  	    $params{$_} = "1";
	} elsif ($p eq "is_mp3") {
  	    $params{$_} = "0";
    } else {
        $params{$_} = $self->set_context_params($p, $template, $dir, $uri, $directories, $mp3s, $inner_loops);    
    }
  }
  return \%params;
}




sub set_mp3_context_params {
  my ($self, $template, $dir, $uri, $directories, $mp3s, $inner_loops, $song_file, $song, $count, $on_playlist) = @_;
  
  # Warning: Hack following.  A double '//' is creeping into $uri.  Remove it.  
  if ($uri) {
    $uri =~ s/\/\//\//g;
  }
  
  my @param_names;
  my @inners = @$inner_loops;
  if ($#inners > -1) {
    @param_names = $template->query(loop => $inner_loops);
  } else {
    @param_names = $template->query();  
  }

  my %params;
    
  foreach (@param_names) {
    my $p = lc $_;
    if (defined $$song{$_}) {
      $params{$_} = $$song{$_};
      next;
    }

    if ($p =~ m/^__\S*__$/) {
        $params{$_} = $self->set_loop_params($p,$count);
    } elsif (($p eq "is_dir") && (not $on_playlist)) {
  	    $params{$_} = "0";
    } elsif (($p eq "is_mp3") && (not $on_playlist)) {
  	    $params{$_} = "1";
    } elsif ($p eq "fetch_url") {
        if ($self->download_ok) {
        	$params{$_} = ($on_playlist) ? escape($song_file) : $uri.escape($song_file);
		} else {
		    $params{$_} = "";
		}
    } elsif (($p eq "add_to_playlist_url") && (not $on_playlist)) {
        $params{$_} = $self->r->uri."playlist.m3u?Add+to+Playlist=1;file=".$uri.escape($song_file);
	} elsif (($p eq "remove_from_playlist_url") && ($on_playlist)) {
	    $params{$_} = $self->r->uri."playlist.m3u?Clear+Selected=1;playlist=1;file=".escape($song_file);
    } elsif ($p eq "play_url") {
        if ($self->stream_ok) {
            $params{$_} = ($on_playlist) ?  escape($song_file)."?play=1;" : $uri . escape($song_file) . "?play=1;";
            $params{$_} =~ s/(\.[^.]+)?$/.m3u?play=1/;
		} else {
		    $params{$_} = "";
        }
	} elsif ($p eq "checkbox") {
	    $params{$_} = ($on_playlist) ? "<input type=\"checkbox\" name=\"pl\"  value=\"$song_file\" />":
	                                   "<input type=\"checkbox\" name=\"mp3\" value=\"$uri/$song_file\" />";
    } else {
        $params{$_} = $self->set_context_params($p, $template, $dir, $uri, $directories, $mp3s, $inner_loops);    
    }
  }
  return \%params;
}






sub set_loop_params {
	# NOTE THAT __FIRST__, __LAST__, and __INNER__ are handled by HTML::Template not here.
	
	my ($self, $p, $count) = @_;    

	if ($p eq "__count__") {
	    return $count;
	} elsif ($p eq "__count_base_zero__") {
	    return $count - 1;
	} elsif ($p eq "__odd__") {
	    return ($count % 2) ? "1" : "0";
	} elsif ($p eq "__even__") {
	    return ($count % 2) ? "0" : "1";
	} elsif ($p =~ m/__first_col_(\d+)__/) {
	    if ($1 < 1) { return "0"; }
	    my $x = ($count + $1) % $1;
	    return ( $x = 1 ) ? "1" : "0";
	} elsif ($p =~ m/__last_col_(\d+)__/) {
	    if ($1 < 1) { return "0"; }
	    my $x = ($count + $1) % $1;
	    return ( $x = 0 ) ? "1" : "0";
	} elsif ($p =~ m/__inner_col_(\d+)__/) {
	    if ($1 < 1) { return "0"; }
	    my $x = ($count + $1) % $1;
	    return ( $x > 1 ) ? "1" : "0";
	}
	return ""; 
}






sub set_context_params {
    my ($self, $p, $template, $dir, $uri, $directories, $mp3s, $inner_loops) = @_;
    
    if ($p eq "allow_stream") { return ($self->stream_ok) ? "1" : "0";  }
    
    if ($p eq "allow_download") { return ($self->download_ok) ? "1" : "0"; }
    
    if ($p eq "base_dir") { return $self->default_dir; }
    
    if ($p eq "stream_timeout") { return ($self->stream_timeout) ? $self->stream_timeout : ""; }
    
    if ($p eq "skin") { return $self->skin_filename; }
    
    if ($p eq "sort") { return (param('sort') || ""); }
    
    if ($p eq "home_label") { return $self->home_label; }
    
    if ($p eq "home_path") { return $self->home_path; }
    
    if (m/^is_sort_(\S*)$/) {
	    return ((($1 eq "DEFAULT") ? undef : lc $1) eq (lc param('sort'))) ? "1" : "0";
	}
	
    if (m/^param_(\S*)$/) {
	    return param($1);
	}
	
	if ($p eq "contains_playlist") {
	    my @songs = $self->playlist();
	    #my @songs = $self->{playlist} ? @{$self->{playlist}} : ();
	    return $#songs + 1;
	} 
	
	if ($p eq "is_long_page") { return ($self->file_list_is_long < keys %$mp3s) ? "1" : "0"; }
	
	if ($p eq "contains_mp3s") {
	    unless ($mp3s) { ($directories,$mp3s, undef) = $self->read_directory($dir) }
	    my %songs = %$mp3s;
	    return scalar %songs;
	} 
	
	if ($p eq "contains_dirs") {
	    unless ($directories) { ($directories,$mp3s, undef) = $self->read_directory($dir) }
	    my @dirs = @$directories;
	    return $#dirs + 1;
	} 
	
	if ($p eq "is_home") {  return ($dir eq $self->r->document_root.$self->home_path) ? "1" : "0";	}
	
	if ($p eq "cover") {
  		my $coverimg = $self->r->dir_config('CoverImage') || COVERIMAGE;
  		return (-e "$dir/$coverimg") ? $uri."/".$coverimg : "";
  	}
  	
  	if ($p eq "dir") {
  	    my @parts = split "/", $self->r->uri;
  	    return pop @parts;
  	}
  	
  	if ($p eq "url") { return $self->r->uri; }
  	
	if ($p eq "this_dir") {
  	    if ($uri eq $self->home_path) {
  	        return $self->home_label;
		} else {		
  	      my @parts = split "/", $uri;
  	      return pop @parts;
		}
  	}
  	
  	if ($p eq "this_url") { return $uri; }
  	
  	if ($p eq "is_dir_this_dir") {
  	    return ($uri."/" eq $self->r->uri) ? "1" : "0";
  	}
  	
  	if ($p eq "is_dir_inside_this_dir") {
  	    my $ind = index $self->r->uri, $uri;
  	    return ($ind )? "0" : "1";
  	}
  	
  	if ($p eq "parent_dir") {
  	    my @parts = split "/", $uri;
  	    pop @parts;
  	    return pop @parts;
  	}
  	
  	if ($p eq "parent_url") {
  	    my @parts = split "/", $uri;
  	    pop @parts;
  	    return join "/", @parts;
  	} 
  	
  	if ($p eq "play_all_this_dir_recursive_url") { return $uri."playlist.m3u?Play+All+Recursive=1"; }
  	
  	if ($p eq "shuffle_all_this_dir_recursive_url") { return $uri."playlist.m3u?Shuffle+All+Recursive=1"; }
  	
  	if ($p eq "play_all_this_dir_url") { return $uri."playlist.m3u?Play+All=1"; }
  	
  	if ($p eq "shuffle_all_this_dir_url") { return $uri."playlist.m3u?Shuffle+All=1"; }
  	
  	if ($p eq "play_all_script") { return "play_all();"; }
  	
  	if ($p eq "shuffle_all_script") { return "shuffle_all();"; }
  	
  	if ($p eq "play_selected_script") { return "play_selected();"; }
  	
  	if ($p eq "shuffle_selected_script") { return "shuffle_selected();"; }
  	
##  	if ($p eq "add_to_playlist_all_this_dir_url") { return $self->r->uri."/playlist.m3u?Add+All+to+Playlist?dir=$uri"; }
  	
##  	if ($p eq "add_to_playlist_all_this_dir_recursive_url") { return $self->r->uri."/playlist.m3u?Add+All+to+Playlist+Recursive?dir=$uri"; }
  	
  	if ($p eq "add_to_playlist_all_script") { return "add_all();"; }
  	
  	if ($p eq "add_to_playlist_selected_script") { return "add_selected();"; }
  	
  	if ($p eq "play_all_playlist_url") { return $uri."/playlist.m3u?Play+All=1;playlist=1"; }
  	
  	if ($p eq "shuffle_all_playlist_url") { return $uri."/playlist.m3u?Shuffle+All=1;playlist=1"; }
  	
  	if ($p eq "clear_all_playlist_url") { return $uri."/playlist.m3u?Clear+All=1;playlist=1"; }
  	
  	if ($p eq "clear_selected_playlist_script") { return "clear_selected_playlist();"; }
  	
  	if ($p eq "play_selected_playlist_script") { return "play_selected_playlist();"; }
  	
  	if ($p eq "select_all_mp3s_script") { return "select_all_mp3s();";	}
  	
  	if ($p eq "unselect_all_mp3s_script") { return "unselect_all_mp3s();"; }
  	
  	if ($p eq "select_all_playlist_script") { return "select_all_playlist();";	}
  	
  	if ($p eq "unselect_all_playlist_script") { return "unselect_all_playlist();"; }  	
  	
  	if ($p eq "home_dirs") { return $self->loop_home_dirs($template, $inner_loops); }
  	
  	if ($p eq "dirs") { return $self->loop_dirs($template, $inner_loops, $dir, $uri, $directories); }
  	
  	if ($p eq "path_forward") { return $self->loop_path($template, $inner_loops, $dir, $uri, "forward"); }
  	
  	if ($p eq "path_backward") { return $self->loop_path($template, $inner_loops, $dir, $uri, "backward"); }
  	
  	if ($p eq "mp3s") { return $self->loop_mp3s($template, $inner_loops, $dir, $uri, $mp3s); }
  	
  	if ($p eq "dirs_and_mp3s") { return $self->loop_dirs_and_mp3s($template, $inner_loops, $dir, $uri, $mp3s, $directories, 1); }
  	
  	if ($p eq "mp3s_and_dirs") { return $self->loop_dirs_and_mp3s($template, $inner_loops, $dir, $uri, $mp3s, $directories, 0); }

  	if ($p eq "playlist") { 
  	    return $self->loop_playlist($template, $inner_loops, $dir, $uri);
  	}

  	  	
  	# need to make sure it's a tmpl_var before returning...
    return "";
}


sub loop_dirs_and_mp3s {
  my ($self, $template, $inner_loops, $dir, $uri, $mp3s, $dirs_ref, $dirs_first) = @_;
  my @inner_loops = @$inner_loops;
  if ($dirs_first) { push @inner_loops, "dirs_and_mp3s"; }
  else { push @inner_loops, "mp3s_and_dirs"; }
  
  my @params;
  my $count = 1;
  
  if ($dirs_first) {
      my $x = $self->iterate_dirs($template, $dir, $uri, \@inner_loops, $dirs_ref, $count);
      push @params, @$x;
  }
  my @songs = $self->sort_mp3s($mp3s);
    
  foreach (@songs) {
    my ($directories, $mp3s, undef) = $self->read_directory($dir);
    push @params, $self->set_mp3_context_params($template, $dir, $uri, $directories,$mp3s, \@inner_loops, $_, $mp3s->{$_}, $count, 0);
    $count++;
  }
  if (not $dirs_first) {
      my $x = $self->iterate_dirs($template, $dir, $uri, \@inner_loops, $dirs_ref, $count);
      push @params, @$x;
  }
  return \@params;

}

sub loop_home_dirs {
	my ($self, $template, $inner_loops) = @_;
	my @inner_loops = @$inner_loops;
	push @inner_loops, "home_dirs";
	my $dir = $self->r->document_root.$self->home_path;
 	my ($directories, undef, undef) = $self->read_directory($dir);
	return $self->iterate_dirs($template, $dir, $self->home_path, \@inner_loops, $directories, 1);
}

sub loop_dirs {
	my ($self, $template, $inner_loops, $dir, $uri, $dirs_ref) = @_;
	my @inner_loops = @$inner_loops;
	push @inner_loops, "dirs";
	return $self->iterate_dirs($template, $dir, $uri, \@inner_loops, $dirs_ref, 1);
}

sub iterate_dirs {
 	my ($self, $template, $dir_prefix, $uri_prefix, $inner_loops, $dirs, $count) = @_;
 	my @dir_params;
 	foreach (@$dirs) {
 	    my ($directories,$mp3s, undef) = $self->read_directory($dir_prefix."/".$_);
 	    push @dir_params, $self->set_dir_context_params($template, $dir_prefix."/".$_, $uri_prefix."/".$_, $directories,$mp3s, $inner_loops, $count);    
 	    $count++;
	}
	return \@dir_params; #, $count; 
}

sub loop_path {
    my ($self, $template, $inner_loops, $dir, $uri, $direction) = @_;
    my @inner_loops = @$inner_loops;
    push @inner_loops, "path_".$direction;
    
    my @dirs;
    my @parts = split "/", $uri;
    #shift @parts;

    while ($#parts > -1) {
    	my $path = "/". join "/", @parts;
    	$path =~ s/\/\//\//g;
    	push @dirs, $path;
    	if ($path eq $self->home_path) { last; }
    	my $trash = pop @parts;    
	}
	
	@dirs = reverse @dirs if ($direction eq "forward");
	my @dir_params;
	my $count = 1;
	foreach (@dirs) {
		my ($directories, $mp3s, undef) = $self->read_directory($self->r->document_root.$_);
 	    push @dir_params, 
 	       $self->set_dir_context_params(
 	          $template, $self->r->document_root.$_, $_, $directories,$mp3s, \@inner_loops, $count
 	        );    
    	$count++;
	}
	return \@dir_params;
}

sub loop_mp3s {
  my ($self, $template, $inner_loops, $dir, $uri, $mp3s) = @_;
  my @inner_loops = @$inner_loops;
  push @inner_loops, "mp3s";
  
  my @songs = $self->sort_mp3s($mp3s);
  my @song_params;
  my $count = 1;
  foreach (@songs) {
    # The next line kills performance.  Need to eliminate.
    my ($directories, $mp3s, undef) = $self->read_directory($dir);
    push @song_params, 
      $self->set_mp3_context_params(
        $template, $dir, $uri, $directories,$mp3s, \@inner_loops, $_, $mp3s->{$_}, $count, 0
      );
    $count++;
  }
  return \@song_params;
}


sub loop_playlist {
  my ($self, $template, $inner_loops, $dir, $uri) = @_;
  my @inner_loops = @$inner_loops;
  push @inner_loops, "playlist";
  
  my ($directories, $mp3s, undef) = $self->read_directory($dir);
  
  my @songs = $self->playlist();
  my @song_params;
  my $count = 1;  

  foreach (@songs) {

    my $info_hash = $self->fetch_info($self->r->document_root.$_);
    if (not $info_hash) { $info_hash = {}; }
    push @song_params, 
      $self->set_mp3_context_params(
        $template, $dir, $uri, $directories, $mp3s, \@inner_loops, $_, $info_hash, $count, 1
    );
    $count++;
  } 
  return \@song_params;  
    
}




### What's the name of the skin file for this request?
sub skin_filename { param('skin') || shift->r->dir_config('DefaultSkin') || 0 }
sub home_path { shift->r->dir_config('HomePath') || '/' }

### look for the skin file and return if found
sub get_skin_path {
  my ($self, $dir) = @_;
  
  # What's the skin's filename?
  my $skin_filename = $self->skin_filename || return undef;
  
  return $dir."/".$skin_filename if (-r $dir."/".$skin_filename);
  return $self->r->document_root.$self->default_dir."/".$skin_filename if (-r $self->r->document_root.$self->default_dir."/".$skin_filename);
  return undef;
}

1;

__END__

=head1 NAME

Apache::MP3::Skin - A subclass of Apache::MP3::Playlist with the ability to "skin"
the output using HTML::Template

=head1 SYNOPSIS

 # httpd.conf or srm.conf
 AddType audio/mpeg    .mp3 .MP3

 # httpd.conf or access.conf
 <Location /songs>
   SetHandler perl-script
   PerlHandler Apache::MP3::Skin
   PerlSetVar HomePath  /songs   # optional
   PerlSetVar DefaultSkin  default.tmpl   # required  

   # Without DefaultSkin being set to a valid file
   # Apache::MP3::Skin will be the same as Apache::MP3
 </Location>

=head1 DESCRIPTION

Apache::MP3::Skin subclasses Apache::MP3::Playlist enabling the use of skin files
which are html files with special tags enabled by HTML::Template.  See L<Apache::MP3>
for details on installing and using.

=head1 CUSTOMIZING WITH SKINS

The whole purpose of this class is to allow custom GUIs to be built upon
Apache::MP3::Playlist and subsequently Apache::MP3 itself.  Skin are just html files
that contain various tags in the form of <TMPL_blah,blah [ATTRIBUTE=value]>.  The filename 
of the skin to be used is set with PerlSetVar DefaultSkin and can be overridden by 
"?skin=someskin.tmpl" in the query string.  The skin file is first looked for in the 
directory of the request.  For example, if you were to go to /Songs/Rock, Apache::MP3::Skin
would first look for the skin file in /Songs/Rock.  If it didn't find one there, it'd look in 
the directory set by PerlSetVar BaseDir (usually, /apache_mp3).  In most cases you'll want
to keep all your skins in the BaseDir, but it is possible to have a different skin for each 
directory.

Complete documentation on these tags can be found at L<HTML::Template>, but
enough to get you started follows.

=over 4

=item <TMPL_VAR [ESCAPE="HTML" | ESCAPE="URL"] NAME=variable>

Tag is replace with the value of variable and optionally escaped making it html
or url compliant.

=item <TMPL_IF NAME=variable> html here 
	[ <TMPL_ELSE>  more here ] 
</TMPL_IF>

The value or variable is evaluated, and if it is not empty or "0" it is 
considered true and "some html" is outputed to the browser.  A <TMPL_ELSE>
can optionaly be specified.

=item <TMPL_UNLESS NAME=variable> html here 
    [ <TMPL_ELSE> more here ] 
</TMPL_UNLESS>

Similar to <TMPL_IF> but "html here" is outputed to the browser when variable
is either "" or "0".

=item <TMPL_LOOP NAME=loop_name> do this </TMPL_LOOP>

This tag is more complicated the others, but basically it outputs "do this"
multiple times.  The number of times is determined by loop_name.  Looping also
changes the context of some variable.  For example...
    
    <ul>
    <TMPL_LOOP NAME="MP3S"><li> <TMPL_VAR NAME="TITLE"> </TMPL_LOOP>
    </ul>
    
For each iteration of MP3S, TITLE will be different value.

Note: that variables can be used in TMPL_VAR, TMPL_UNLESS, and TMPL_IF, but not
in TMPL_LOOP which requires a loop_name.

=item <TMPL_INCLUDE NAME="filename.tmpl">

This tag includes a template directly into the current template at the 
point where the tag is found. The included template contents are used 
exactly as if its contents were physically included in the master template.

The file specified can be a full path - beginning with a '/'. If it isn't a 
full path, the path to the enclosing file is tried first.

=back

=head1 NESTING TEMPLATE TAGS

Yes.  All the tags can be nested in almost any way.  A few variables are
limited to be inside certain loops, but that's the only restriction.


=head1 VARIABLES

Variables can be used in TMPL_VAR, TMPL_UNLESS, and TMPL_IF, and they are grouped below
into for types: global, directory scoped, file scoped, and special loop variables.  At
last count there were 68 valid variables and some like PARAM_param and IS_SORT_sort can
take many forms.

=head2 Global Variables

These variables' values do not change during the parsing of a template and available 
everywhere.

=over 4

=item ADD_TO_PLAYLIST_ALL_SCRIPT

(string) JavaScript that will add all the MP3s currently listed on the page.  
Differs from ADD_TO_PLAYLIST_ALL_THIS_DIR_URL which is directory context 
sensitive.

=item ADD_TO_PLAYLIST_SELECTED_SCRIPT

(string) JavaScript to add the selected MP3S to the playlist.

=item ALLOW_DOWNLOAD

(1|0) Is streaming allowed?  Set by PerlSetVar AllowDownload.  It's good form to test
if streaming is allowed before using variables like FETCH_URL which will not work.

=item ALLOW_STREAM

(1|0) Is streaming allowed?  Set by PerlSetVar AllowStream.  It's good form to test
if streaming is allowed before using variables like PLAY_URL which will not work.

=item BASE_DIR

(string) path the base directory.  Set by PerlSetVar BaseDir and defaulted to 
/apache_mp3.

=item CLEAR_ALL_PLAYLIST_URL

(string) URL to remove all the files from the playlist.

=item CLEAR_SELECTED_PLAYLIST_SCRIPT

(string) JavaScript to remove all the selected files from the playlist. 

=item CONTAINS_PLAYLIST

(int) Return the number of songs on the current browsers playlist. Useful in 
TMPL_IF and TMPL_UNLESS tags as an empty playlist will contain 0 songs.

=item DIR

(string) The name of the directory that browser is looking at, similar to 
THIS_DIR except DIR's value does not change with the directory context.

=item HOME_LABEL

(string) The name of the top (or home) directory as defined by PerlSetVar.

=item HOME_PATH

(string) The hostname-relative PATH of the top (or home) directory as defined
by PerlSetVar HomePath.

=item IS_SORT_method

(1|0) Is the current page being sorted by method where method is 
title, album, artist, etc..  Default is the sort method defined by PerlSetVar 
SortFields.

=item PARAM_param

(string) Returns the value of the param named 'param' from the URL's query string.  For
example	if the current url is http://www.apachemp3.com/demo/pop?cartopen=yes then
<TMPL_VAR NAME=PARAM_CARTOPEN> would return "yes".  This can be useful for complicated
skins that need to maintain state.

=item PLAY_ALL_PLAYLIST_URL

(string) URL to play all files in the playlist in order.

=item PLAY_ALL_SCRIPT

(string) Javascript that will play all the MP3s currently listed on page.  
Differs	from PLAY_ALL_THIS_DIR_URL which is directory context sensitive.

=item PLAY_SELECTED_PLAYLIST_SCRIPT

(string) JavaScript that will play all the selected files in the playlist. 	

=item PLAY_SELECTED_SCRIPT

(string) Javascript that will play all selected songs.

=item SELECT_ALL_MP3S_SCRIPT

(string) JavaScript that checks all the checkboxes generated by 
<TMPL_VAR NAME=CHECKBOX> for MP3 files. 

=item SELECT_ALL_PLAYLIST_SCRIPT

(string) JavaScript that checks all the checkboxes generated by 
<TMPL_VAR NAME=CHECKBOX> in the playlist.

=item SORT

(string) The current sort method. Returns "" if default, otherwise returns the field name
currently being used to sort See L<Apache::MP3::Sorted> for appropriate values.
This is the same as PARAM_sort since the sort field is contained in the query 
string. Default sort is defined by PerlSetVar SortFiles.  

=item SHUFFLE_ALL_PLAYLIST_URL

(string) URL to play all files in the playlist in a random order.  		

=item SHUFFLE_ALL_SCRIPT

(string) Javascript that will play all the MP3s currently listed on a page 
in a random order.  Not directory context sensitive.

=item SHUFFLE_SELECTED_SCRIPT

(string) Javascript that will play all selected songs in a random 
order. 

=item SKIN

(string) The current skin.  Append to URLs in the form of ?skin=<TMPL_VAR NAME=SKIN>
to maintain your skin if it is not the default.  Useful in skins that require
multiple files for framesets.

=item STREAM_TIMEOUT

(int) If anything but 0, this returns the number in seconds of how long a file
will stream before timing out, otherwise returns an empty string.  Set by 
PerlSetVar StreamTimeout.  Used for demos or in cases when streaming an entire 
song would not be appropriate or illegal.

=item UNSELECT_ALL_MP3S_SCRIPT

(string) JavaScript that Unchecks all the checkboxes generated by 
<TMPL_VAR NAME=CHECKBOX> for all MP3 files.     

=item UNSELECT_ALL_PLAYLIST_SCRIPT

(string) JavaScript that unchecks all the checkboxes generated by 
<TMPL_VAR NAME=CHECKBOX> in the playlist.

=item URL

(string) The URL path to DIR.  Similar to THIS_URL but does not change with
the directory context

=back

=head2 Directory Scoped variables

These variables' values are determined by the current directory context.  In the 
context of a directory loop -- PATH_FORWARD, PATH_BACKWARD, HOME_DIRS, and DIRS -- 
the values are those of directory for that loop iteration.  Outside of loops, the
directory context is that of the current browser request. These varables are
available everywhere as there is always a directory context.

=over 4

=item IS_LONG_PAGE

(1|0) Does the current directory have more files than the defined value 
in PerlSetVar LongList. Useful for adding a second set of buttons on a long 
page.

=item CONTAINS_MP3S

(int) Return the number of MP3s in the current directory. Useful in IF and 
UNLESS commands to test existance of any MP3s.

=item CONTAINS_DIRS

(int) Return the number of sub-directories in the current directory. Useful in IF
and UNLESS commands to test existance of any sub-directories.

=item IS_HOME

(1|0) Is the current directory the top (or root) directory as defined by
PerlSetVar HomePath.

=item COVER

(string) The full src path of an image.  Returns an empty string if there is no image.
The empty string is useful to test the existance of a cover image.  The image
is looked for has the filename set by PerlSetVar CoverImage (dafault is cover.jpg)
in the current directory.


=item IS_DIR_INSIDE_THIS_DIR

(1|0) The key to understand this and the next two cryptic variables is to
rember that DIR and THIS_DIR are other variables.  If DIR, the directory
the browser is looking at, is inside THIS_DIR.  This is useful for determining
when creating global navigation and you want a certain tab (THIS_DIR) to be
highlighted if the browser is looking at a directory(DIR) beneath it.

=item IS_DIR_THIS_DIR

(1|0) Related to IS_DIR_INSIDE_THIS_DIR, this variable is 1 when the two are
the same.

=item THIS_DIR

(string) The name of the current directory.

=item THIS_URL

(string) The path part of the URL for the current directory.  Never just './' 
because the current directory in a loop, may not be the directory the browser
is looking at.  Use URL to return constant equivilant of "./".

=item PARENT_DIR

(string) The name of the parent directory, if the current directory is not 
the HomePath; otherwise, an empty string.

=item PARENT_URL	

(string) The path part of the URL for parent directory, if the current directory 
is not the HomePath; otherwise, an empty string.

=item PLAY_ALL_THIS_DIR_URL

(string) The URL to Play All songs in a the current directory.

=item SHUFFLE_ALL_THIS_DIR_URL

(string) The URL to Shuffle and Play All songs in the current directory.

=item PLAY_ALL_THIS_DIR_RECURSIVE_URL

(string) The URL to Play All songs in a the current directory and it 
directories recursively.

=item SHUFFLE_ALL_THIS_DIR_RECURSIVE_URL

(string) The URL to Shuffle and Play All songs in the current directory and 
its directories recursively.

=back

=head2 File Scope Variables

These may be used inside the MP3S loop, and also in  MP3_AND_DIRS 
and DIRS_AND_MP3S when the iteration is an MP3 -- Test with IS_MP3. Most but not
of them are also available inside PLAYLIST.  Those are noted.

=over 4

=item ALBUM

(string) The album name. Also available in PLAYLIST loop.

=item ARTIST

(string) The artist name. Also available in PLAYLIST loop.

=item BITRATE

(string) Streaming rate of song in kbps. Also available in PLAYLIST loop.

=item COMMENT

(string) The comment field. Also available in PLAYLIST loop.

=item DESCRIPTION

(string) Description, as controlled by DescriptionFormat. Also available 
in PLAYLIST loop.

=item DURATION

(string) Duration of the song in minute, second format. Also 
available in PLAYLIST loop.

=item FILENAME

(string) The physical name of the .mp3 file.  Also available in PLAYLIST 
loop.

=item GENRE

(string) The genre.  Also available in PLAYLIST loop.

=item SAMPLERATE

(string) Sample rate, in KHz.  Also available in PLAYLIST loop.

=item SECONDS

(string) Duration of the song in seconds.  Also available in PLAYLIST loop.

=item TITLE

(string) The title of the song.  Also available in PLAYLIST loop.

=item TRACK

(string) The track number.  Also available in PLAYLIST loop.

=item CHECKBOX

(string) The HTML for the form checkbox where the user can select a song.  
Related to PLAY_SELECTED_SCRIPT and other _SCRIPT variables.  Also available 
in PLAYLIST loop.

=item FETCH_URL

(string) The file's URL to fetch it from.  May be disabled with 
PerlSetVar AllowDownload no. Also available in PLAYLIST loop.

=item PLAY_URL

(string) The file's URL to stream it from.  May be disabled with
PerlSetVar AllowStream. Also available in PLAYLIST loop.

=item REMOVE_FROM_PLAYLIST_URL

(string) The URL to remove the file from the playlist. Only available inside 
PLAYLIST loop.

=item ADD_TO_PLAYLIST_URL

(string) The URL to add the current file to the users playlist. 
Not available inside PLAYLIST loop.

=back

=head2 Special Loop Variables

Inside a loop these varables are also available

=over 4

=item __COUNT__

(int) Starting with 1, this is the loop count.  It increases by 1
with each iteration.

=item __COUNT_BASE_ZERO__

(int) Useful for building JavaScript Object and Arrays, this is __COUNT__
minus 1.

=item __FIRST__

(1|0) Returns 1 if __COUNT__ is 1, otherwise it returns 0.  More simply,
it's 1 for the first iteration only.  Implemented by HTML::Template.

=item __LAST__

(1|0) Returns 1 on the last iteration only.  Implemented by HTML::Template.

=item __INNER__

(1|0) If an iteration is not first and not last, than __INNER__ is 1.
Implemented by HTML::Template.

=item __FIRST_COL_x__ 

(1|0) Where x is an integer.  For __FIRST_COL_3__, 1 would be returned on
 __COUNT__ values: 1, 4, 7, 10, etc.

=item __LAST_COL_x__

(1|0) Similar to __FIRST_COL_x__ but given x is 3, __LAST_COL_3__ 
would return 1, on the following iterations: 3, 6, 9, 12, etc.

=item __INNER_COL_x__

If an iteration is not a __FIRST_COL_x__ or a __LAST_COL_x__ it is an __INNER_COL_x__.

=item __ODD__

(1|0) Returns 1 on odd __COUNT__ values.

=item __EVEN__

(1|0) Returns 0 on even __COUNT__ values.

=item IS_MP3

(1|0) Useful in LOOP_MP3S_AND_DIRS and LOOP_DIRS_AND_MP3S this will return 1
if the current loop iteration is an mp3.	

=item IS_DIR

(1|0) Useful in LOOP_MP3S_AND_DIRS and LOOP_DIRS_AND_MP3S this will return 1
if the current loop iteration is a directory.

=back

=head2 About Variables Ending in _URL or _SCRIPT

Many of the TMPL_VAR variables below return URLs or JavaScript functions.  Variables that return
URLs, always end with _URL.  This value can be used as an href in an anchor tag. Or be included
in a javascript event like onClick.  Here's an example of use in a form button.

<BUTTON onClick="location=<TMPL_VAR NAME=SOME_URL>;">

and then a variable ending in _SCRIPT would be like this:

<BUTTON onClick="<TMPL_VAR NAME=SOME_SCRIPT>">

to use a _SCRIPT as part of a url do something like this:

<a href="javascript: <TMPL_VAR NAME=SOME_SCRIPT>">



=head1 LOOP NAMES

A variety of loops are possible, and all can be nested inside of each other for some 
interesting and sometimes useless effects. Note that when looping through a series of 
directories, the current directory context changes. So multiple nested DIRS loops would result
in a directory tree because DIRS loops through the current directory context, and inside 
iterations change that same context.

Valid loop names are:

=over 4

=item PATH_FORWARD

Iterate through the path from the top (or home) directory as
defined by PerlSetVar to the current Directory.  Useful for making
breadcrumb trails.

=item PATH_BACKWARD

Same as PATH_FORWARD but the loops starts with the current
directory and goes up the file tree to the top (or home) directory.

=item HOME_DIRS

Loop through all the directories in the top (or home) directory.
Useful for creating persistent global nav.

=item MP3S

Loop through all the MP3s in the current directory.

=item DIRS

Loop through all the DIRs in the current directory.

=item PLAYLIST

Loop through all the MP3s in the current browser's playlist.

=item DIRS_AND_MP3S

Loop through all the directories and then all the MP3s in the current directory. Use 
the IS_DIR variable to test whether a given iteration is a directory or MP3.

=item MP3S_AND_DIRS

Same and DIRS_AND_MP3S except all the MP3s come before directories.

=back

=head1 ABOUT FRAMES

A skin can be composed of multiple template files.  The default template should contain the 
framset and the source's for each from should end with "?skin=thisframe.tmpl" where 
thisframe.tmpl is the name of the file to be used to skin that frame.  Links inside 
thisframe.tmpl will also need to end in "?skin=thisframe.tmpl" to maintain their look.

=head1 ABOUT FORMS

A open form and closing form tag is automatically added to every page.  Do not include
any forms tags in your skin files.  You can include form input fields and they will be part
of the apache_mp3_skin form.  Use document.apache_mp3_skin to refer to the form object
in any JavaScript that you have.

=head1 METHODS

Apache::MP3::Skin overrides the following methods:

=over 4

=item list_directory() 

Checks to see if this is a skin file, if not hands off to SUPER::list_directory().
If there is a skin files, gets it, processes it, adds in the <SCRIPT> and <FORM> 
tags and the prints it.

=item run()

Looks for the "Shuffle Selected" parameter and handles the request if there is one.
Otherwise, sends to SUPER::run().

=item process_playlist()

Same as SUPER::process_playlist with only one line changed.  If there is an 'Add to
Playlist' param.  file param values that begin with '/' are not prepended with the
current uri and are treated as document root relative.

=back

And adds the following:

=over 4

=item set_template_params()

Called by list_directory, this begins the process of filling in the template params.
set_template_params sets the current directory context to the uri of the request and 
calls set_dir_context_params.

=item set_dir_context_params()

Loops through the parameters required for the template, sending special loop variables to
set_loop_params and most of the rest to set_context_params

=item set_mp3_context_params()

Called by loop_mp3s and loop_playlist, set_mp3_context_params iterates through the
parameters being requested in each loop iteration.  Those that are file context are handled,
special loop variables are sent to set_loop_params, and the rest go to set_context_params.

=item set_loop_params()

Called by set_mp3_context_params and set_dir_context_params, set_loop_params takes the
name of a special loop variable, and the current loop count and return the appropriate
value for the special loop variable.

=item set_context_params()

The workhorse. set_context_params takes in the name of the current parameter being queried
along with context information and returns the appropriate values.  Handles all global variables,
directory context variables, and loops.

=item loop_dirs_and_mp3s()

Called by set_context_params for the loops DIRS_AND_MP3S and MP3S_AND_DIRS.  Loops through
all the dirs and mp3s calling either iterate_dirs() or set_mp3_context_params()
for each as necessary.

=item loop_home_dirs()

Called by set_context_params for the HOME_DIRS loop.  Gets a list of directories in 
HomePath and send it to iterate_dirs().

=item loop_dirs()

Called by set_context_params for the DIRS loop.  Gets a list of directories in the current
directory and sends it to iterate_dirs().

=item loop_path()

Called by set_context_params for PATH_FORWARD and PATH_BACKWARDS loops.  Gets a list of 
directories from the HomePath to the current directory context.  Reverses them if necessary.
And then sends them to iterate_dirs().

=item iterate_dirs()

Called by loop_dirs_and_mp3s, loop_dirs, loop_home_dirs, and loop_path.  Takes a list of
directories and sends each to set_context_params().

=item loop_mp3s()

Called by set_context_params for MP3S loops.  Iterates through the .mp3 files in the current
directory context sending each to set_mp3_context_parameters().

=item loop_playlist()

Called by set_context_params for MP3S loops.  Iterates through the files in the browser's playlist.
Sends each to set_mp3_context_parameters().

=back


=head1 TO DO

=over 4

=item Support Playlist Files (.m3u)

Support for playlist files (.m3u).  These are supported by Apache::MP3, and ignored
by Apache::MP3::Skin.  I skipped over this because 1. I don't use them so it was the
last thing I need for my own skins 2. I'm not sure how to handle them when looping.
Include them in which loops?  3. I'd really like to be able to loop the contents of
the .m3u file to allow the skin access to the contents.

=item Two More Variables

Directory context sensitive variables that where planned implemented, and then 
unimplemented.

    ADD_TO_PLAYLIST_ALL_THIS_DIR_URL
        *** Not Implemented ***
        When completed this will add the current directory's MP3s to the Playlist.  For now, use 
        ADD_PLAYLIST_ALL_SCRIPT which in most cases will have a very similar outcome.  This is 
        tricky because the current methods of Apache::MP3::Playlist always Add the directory 
        the browser is looking at which may not always be the current directory context. 
    
    ADD_TO_PLAYLIST_ALL_THIS_DIR_RECURSIVE_URL
        *** Not Implemented ***
        When completed this will the current directory's MP3s to the Playlist recursing
        through sub-directories.  Not Implemented for the same reasons as  
        ADD_TO_PLAYLIST_ALL_THIS_DIR_URL.

=item RegEx Attributes

Possibly patch or subclass, HTML::Template adding a generalized RegEx attribute to 
TMPL_VAR tags. Sometimes Titles needs more than just HTML escaping they need "_" 
changed to " " or you may want to force something to all caps or truncate to a certain length.

=back

=head1 BUGS

Sure. Visit http://www.workingdemo.com/bugs.html for the lastest. Create an account or simply 
login in as guest/guest to report bugs.

=head1 AUTHOR

Copyright 2000, Robert Graff <rgraff@apachemp3.com>.

Visit me at workingdemo.com and robertscloset.com

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 ACKNOWLEDGEMENTS

Lincoln Stein <lstein@cshl.org> created Apache::MP3, Apache::MP3::Sorted,
and Apache::MP3::Playlist upon which this module is built. He also co-authored
a great book which taught me enough about mod_perl and Apache to attempt this.

Sam Tregar, sam@tregar.com wrote HTML::Template which set the stage quite nicely
for creating this module, as I didn't have to worry about parsing the template
just filling it.

=head1 SEE ALSO

L<Apache::MP3>, L<MP3::Info>, L<Apache> L<HTML::Template>



=cut
