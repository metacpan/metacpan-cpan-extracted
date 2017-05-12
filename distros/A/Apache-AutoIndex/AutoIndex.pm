#$Id: AutoIndex.pm,v 1.1 1999/06/29 14:09:25 gozer Exp $
package Apache::AutoIndex;

use strict;
use Apache::Constants qw(:common OPT_INDEXES DECLINE_CMD REDIRECT DIR_MAGIC_TYPE);
use DynaLoader ();
use Apache::Util qw(ht_time size_string);
use Apache::ModuleConfig;
use Apache::Icon;
use Apache::Language;

use vars qw ($VERSION);
$VERSION="0.08";

#Configuration constants
use constant FANCY_INDEXING 	=> 1;
use constant ICONS_ARE_LINKS 	=> 2;
use constant SCAN_HTML_TITLES 	=> 4;
use constant SUPPRESS_LAST_MOD	=> 8;
use constant SUPPRESS_SIZE  	=> 16;
use constant SUPPRESS_DESC 	=> 32;
use constant SUPPRESS_PREAMBLE 	=> 64;
use constant SUPPRESS_COLSORT 	=> 128;
use constant THUMBNAILS 	=> 256;
use constant SHOW_PERMS         => 512;
use constant NO_OPTIONS		=> 1024;

use vars qw(%GenericDirectives);
%GenericDirectives = 
(      
fancyindexing         =>  FANCY_INDEXING,
iconsarelinks         =>  ICONS_ARE_LINKS,
scanhtmltitles        =>  SCAN_HTML_TITLES,
suppresslastmodified  =>  SUPPRESS_LAST_MOD,
suppresssize          =>  SUPPRESS_SIZE,
suppressdescription   =>  SUPPRESS_DESC,
suppresshtmlperamble  =>  SUPPRESS_PREAMBLE,
suppresscolumnsorting =>  SUPPRESS_COLSORT,
thumbnails            =>  THUMBNAILS,
showpermissions       =>  SHOW_PERMS,
);

#Default values
use constant DEFAULT_ICON_WIDTH => 20;
use constant DEFAULT_ICON_HEIGHT=> 22;
use constant DEFAULT_NAME_WIDTH => 23;
use constant DEFAULT_ORDER	=> "ND";

#Global Options/Congiguration Directives
use vars qw($config);
$config->{debug}=0;  
             
use vars qw(%sortname);
%sortname =
( 	
'N'=>'Name' ,
'M'=>'LastModified',
'S'=>'Size',
'D'=>'Description',
);
			
#Statistics variables
use vars qw($nDir $nRedir $nIndex $nThumb);
$nDir=0;
$nRedir=0;
$nIndex=0;
$nThumb=0;


if ($ENV{MOD_PERL}){
	no strict;
	@ISA=qw(DynaLoader);
	__PACKAGE__->bootstrap($VERSION);
	if (Apache->module('Apache::Status')){
		Apache::Status->menu_item('AutoIndex' => 'Apache::AutoIndex status', \&status);
		}
}

sub dir_index {
	my($r) = @_;
	my $lang = new Apache::Language ($r);
	my %args = $r->args;
	my $name = $r->filename;
	my $cfg = Apache::ModuleConfig->get($r);
	my $subr;
	$r->filename("$name/") unless $name =~ m:/$:; 
        
	unless (opendir DH, "$name"){
		$r->log_reason( __PACKAGE__ . " Can't open directory for index", $r->uri . " (" . $r->filename . ")");
	return FORBIDDEN;
	}
	$nDir++;
    
    if ($cfg->{options} & THUMBNAILS){
        use Storable;
	#should check if Storable loaded ok.. Or is it part of the Perl dist??
        $config->{cache_dir} = $r->dir_config("IndexCacheDir") || ".thumbnails";
        $config->{dir_create} = $r->dir_config("IndexCreateDir") || 1;
        
        my $cachedir = $r->filename .  $config->{cache_dir} ;          
        stat $cachedir;
        $config->{cache_ok} = (-e _ && ( -r _ && -w _)) || ((not -e _) && $config->{dir_create} && mkdir $cachedir, 0755);
        

        my $oldopts;
        if ($config->{cache_ok} && -e "$cachedir/.config" && -r _){
            $oldopts = retrieve ("$cachedir/.config");
            }
        
        $config->{thumb_max_width} = $r->dir_config("ThumbMaxWidth") || DEFAULT_ICON_WIDTH*4;
        $config->{thumb_max_height} = $r->dir_config("ThumbMaxHeight")|| DEFAULT_ICON_HEIGHT*4;
        
        $config->{thumb_max_size} = $r->dir_config("ThumbMaxSize") || 500000;
        $config->{thumb_min_size} = $r->dir_config("ThumbMinSize") || 5000;
      
        $config->{thumb_width} = $r->dir_config("ThumbWidth");
        $config->{thumb_height} = $r->dir_config("ThumbHeight");
       
        $config->{thumb_scale_width} = $r->dir_config("ThumbScaleWidth");
        $config->{thumb_scale_height} = $r->dir_config("ThumbScaleHeight");
       
        $config->{changed} = 0;
        
        foreach (keys %$config){
            next unless /^thumb/;
            if ($config->{$_} != $oldopts->{$_})
                {
                $config->{changed} = 1;
                last;
                }
            }
        
	 
        unless ($config->{cache_ok} && ((not -e "$cachedir/.config") || -w _) && store $config, "$cachedir/.config"){
                $config->{changed} = 0;
                };
        }           
    
	print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<HTML><HEAD>\n<TITLE>" . $lang->message("Header") . $r->uri . "</TITLE></HEAD>";
    
    if($r->dir_config("IndexHtmlBody")){
        eval 'print "' . $r->dir_config("IndexHtmlBody") . '"';
        
        }
    else {
        print "<BODY>";
        }
    
    if (not $cfg->{options} & FANCY_INDEXING){
        print "<UL>\n";
        foreach my $file ( readdir DH ){
            print "\t<LI><A HREF=\"$file\">$file</A></LI>\n";
            }
        print "</UL></BODY></HTML>\n";
    return OK;
    }

    #HOME
    $r->subprocess_env(upper => "<BR>");
    $r->subprocess_env(center => "<CENTER><BIG>" . $r->uri . "</BIG></CENTER>");
    $r->subprocess_env(notes => "<I><SMALL>Generated by <A HREF=\"http://ectoplasm.dyndns.com/~gozer/perl/\">Apache::AutoIndex</A></SMALL></I>");
    $r->subprocess_env(counter => "none.dat");
    ##HOME
    
    if ($r->dir_config("IndexHtmlHead")){
        $subr = $r->lookup_uri($r->dir_config("IndexHtmlHead"));
        $subr->run;
        }
    
    print "<H2>" . $lang->{"Header"} . $r->uri . "</H2>\n" ;
	
    place_doc($r, $cfg, 'header');
	
    $config->{table_html} = $r->dir_config("IndexHtmlTable") || 'BORDER="0"';
    
    print "<HR><TABLE ". $config->{table_html} ."><TR>";
 	
    my $list = read_dir( $r, \*DH );
   
    %args = {} if ($cfg->{options} & SUPPRESS_COLSORT);
   
    my $listing = do_sort($list, \%args, $cfg->{default_order});
    
    if ($cfg->{options} & SHOW_PERMS) {
        print "<TH>Perms</TH>" ;
        }
    
 	foreach ('N', 'M', 'S', 'D'){
        next if( $cfg->{options} & SUPPRESS_LAST_MOD && $_ eq 'M');
        next if( $cfg->{options} & SUPPRESS_SIZE && $_ eq 'S');
        next if( $cfg->{options} & SUPPRESS_DESC && $_ eq 'D');
        
        my $th = "<TH>";
        $th = "<TH COLSPAN=2>" if $_ eq 'N';
        print $th;
 	    
        if (not $cfg->{options} & SUPPRESS_COLSORT){
            if ($args{$_}){
 	            my $query = ($args{$_} eq "D") ? 'A' : 'D';
 	            print "<A HREF=\"?$_=$query\"><I>" . $lang->{$sortname{$_}} . "</I></A>";
            } else {
 	            print "<A HREF=\"?$_=D\">" . $lang->{$sortname{$_}} . "</A>";
 	            }
            }
        else {
            print $lang->{$sortname{$_}};
            }
        print "</TH>";
    }
    print "</TR>";
    
	for my $entry (@$listing) {
	    my $img = $list->{$entry}{icon};
 		my $label = $entry eq '..'  ? $lang->message('Parent') : $entry;

	    print qq{<TR valign="center">};

        #Permissions
        print "<TD>" . $list->{$entry}{mode} . "</TD>" if ($cfg->{options} & SHOW_PERMS);

        #Icon
	    print "<TD>";
        if ($cfg->{options} & ICONS_ARE_LINKS) {
            print "<TD><a href=\"$entry";
	        print "/" if $list->{$entry}{sizenice} eq '-';
	        print "\">";
            }
        print "<img width=\"" . $list->{$entry}{width} . "\" height=\"". $list->{$entry}{height} . "\" src=\"$img\" alt=\"[$list->{$entry}{alt}]\" BORDER=\"0\">";
        print "</A>" if ($cfg->{options} & ICONS_ARE_LINKS);
        print "</TD>";
        
        #Name
        print "<TD><a href=\"$entry";
	    print "/" if $list->{$entry}{sizenice} eq '-';
	    print "\">$label</a></TD>";

        #Last Modified
	    print "<TD>$list->{$entry}{modnice}</TD>" unless ( $cfg->{options} & SUPPRESS_LAST_MOD );

        #Size
	    print "<TD ALIGN=\"center\">" . $list->{$entry}{sizenice} . "</TD>" unless ( $cfg->{options} & SUPPRESS_SIZE );

        #Description
	    print "<TD>". $list->{$entry}{desc} . "</TD>" unless ( $cfg->{options} & SUPPRESS_DESC );

        print "</TR>\n";	  
    }
	
    print "</TABLE>\n";
	
    place_doc($r, $cfg, 'readme');
	
    print " <HR>" . $ENV{'SERVER_SIGNATURE'};
	
    if ($config->{debug}) {
		use Data::Dumper;
		print "<PRE>";
		print "<HR>\%list<BR><BR>";
		print Dumper \%$list;
		print "<HR>\$cfg<BR><BR>";
		print Dumper $cfg;
		}
	
    
    if ($r->dir_config("IndexHtmlFoot")){
        $subr = $r->lookup_uri($r->dir_config("IndexHtmlFoot"));
        $subr->run;
        }
    
    print "</BODY></HTML>";

return OK
}

	
sub read_dir {
    my ($r, $dirhandle) = @_;
    my $cfg = Apache::ModuleConfig->get($r);
    my @listing;
    my %list;
    my @accept;
   
    if($cfg->{options} & THUMBNAILS){
        #Decode the content-encoding accept field of the client
        foreach (split(',\s*',$r->header_in('Accept'))){
           push @accept, $_ if m:^image/:;
           }
        }
	
    while (my $file = readdir $dirhandle) {
		if ($file eq '..')
			{
			push @listing, $file;
			next;
			}
		foreach (@{$cfg->{ignore}}) {
			if ($file =~ m/^$_$/){
				$file = '.';
				last;
				}
			}
		next if $file eq '.';
        	push @listing, $file;
		}
   
	foreach my $file (@listing){
		my $subr = $r->lookup_file($file);
		stat $subr->finfo;
		$list{$file}{size} = -s _;
		if (-d _){
            		$list{$file}{size} = -1;
            		$list{$file}{sizenice} = '-';
		        }
        else {
            $list{$file}{sizenice} = size_string($list{$file}{size});
            $list{$file}{sizenice} =~ s/\s*//;    
                }
        $list{$file}{mod}  = (stat _)[9];
        $list{$file}{modnice} = ht_time($list{$file}{mod}, "%d-%b-%Y %H:%M", 0);
        $list{$file}{modnice} =~ s/\s/&nbsp;/g;
		
        $list{$file}{mode} = write_mod((stat _)[2]);
    	
        $list{$file}{type}  = $subr->content_type;
	    
        if(($list{$file}{type} =~ m:^image/:) && ($cfg->{options} & THUMBNAILS ) && Apache->module("Image::Magick"))
            {
            if ($config->{cache_ok}){
                ($list{$file}{icon},$list{$file}{width},$list{$file}{height}) = get_thumbnail($r, $file, $list{$file}{mod}, $list{$file}{type}, @accept);
               }
            }
        $list{$file}{height} ||= $cfg->{icon_height};
        $list{$file}{width} ||= $cfg->{icon_width};
        #icons size might be calculated on the fly and cached...
        
        my $icon = Apache::Icon->new($subr);
		$list{$file}{icon} ||= $icon->find;           
	    if (-d _) {	
			$list{$file}{icon} ||= $icon->default('^^DIRECTORY^^');	
			$list{$file}{alt} = "DIR";
			}	    
		$list{$file}{icon} ||= $icon->default;
		
        $list{$file}{alt} ||= $icon->alt; 
		$list{$file}{alt} ||= "???"; 
	 	
        foreach (keys %{$cfg->{desc}}){
            $list{$file}{desc} = $cfg->{desc}{$_} if $subr->filename =~ /$_/;
            }
        
        if ($list{$file}{type} eq "text/html" and ($cfg->{options} & SCAN_HTML_TITLES) and not $list{$file}{desc}){
            use HTML::HeadParser;
            my $parser = HTML::HeadParser->new;
            open FILE, $subr->filename;
            while (<FILE>){
                last unless $parser->parse($_);
                }
            $list{$file}{desc} = $parser->header('Title');
            close FILE;
            }
        
        $list{$file}{desc} ||= "&nbsp;";
        }
return \%list;
}    

sub transhandler {
    my $r = shift;
   return DECLINED unless $r->uri =~ /\/$/;
    #This is not 100% right at this stage.
    #This has to happend at this stage so there is no need to use internal_redirect or a subr
    #But Location/Directory configuration isn't accessible yet... In the TODO
    
    my $cfg = Apache::ModuleConfig->get($r);
    
    foreach (@{$cfg->{indexfile}}){
       my $subr = $r->lookup_uri($r->uri . $_);
        last if ($subr->path_info);
        if (stat $subr->finfo){
            $nIndex++;
            $r->uri($subr->uri);
            last;
            }
        }
return DECLINED;
}

sub handler {
	my $r = shift;
	return DECLINED unless $r->content_type and $r->content_type eq DIR_MAGIC_TYPE;
    
	my $cfg = Apache::ModuleConfig->get($r);
	$config->{debug} = $r->dir_config('AutoIndexDebug');
	
	
    
    	unless ($r->path_info){
        	#Issue an external redirect if the dir isn't tailed with a '/'
        	my $uri = $r->uri;
        	my $query = $r->args;
        	$query = "?" . $query if $query;
        	$r->header_out(Location => "$uri/$query");
        	$nRedir++;
        	return REDIRECT;
        	}
     
 
	if($r->allow_options & OPT_INDEXES) {
	    $r->send_http_header("text/html");
	    return OK if $r->header_only;
	    return dir_index($r);
	
	} else {
		$r->log_reason( __PACKAGE__ . " Directory index forbidden by rule", $r->uri . " (" . $r->filename . ")");
	return FORBIDDEN;
	}
}


sub do_sort {
    my ($list, $query, $default) = @_;
    my @names = sort keys %$list;
    shift @names;                   #removes '..'
    
    #handle default sorting
	unless ($query->{N} || $query->{S} || $query->{D} || $query->{M})
		{
		$default =~ /(.)(.)/;
		$query->{$1} = $2;
		}
	
	if ($query->{N}) {
		@names = sort @names if $query->{N} eq "D";
		@names = reverse sort @names if $query->{N} eq "A";
	} elsif ($query->{S}) {
		@names = sort { $list->{$b}{size} <=> $list->{$a}{size} } @names if $query->{S} eq "D";
		@names = sort { $list->{$a}{size} <=> $list->{$b}{size} } @names if $query->{S} eq "A";
	} elsif ($query->{M}) {
		@names = sort { $list->{$b}{mod} <=> $list->{$a}{mod} } @names if $query->{M} eq "D";
		@names = sort { $list->{$a}{mod} <=> $list->{$b}{mod} } @names if $query->{M} eq "A";		
	} elsif ($query->{D}) {
		@names = sort { $list->{$b}{desc} cmp $list->{$a}{desc} } @names if $query->{D} eq "D";
		@names = sort { $list->{$a}{desc} cmp $list->{$b}{desc} } @names if $query->{D} eq "A";		
		}
	
unshift @names, '..';           #puts back '..' on top of the pile
return \@names;
}

sub get_thumbnail {
    my ($r, $filename, $mod, $content, @accept) = @_; 
    my $accept = join('|', @accept);
    my $dir = $r->filename;
    #these should sound better.
    my $cachedir = $config->{cache_dir};
   
    my $xresize;
    my $yresize;
    
    my $img = Image::Magick->new;
    my($imgx, $imgy, $img_size, $img_type) = split(',', $img->Ping($dir . $filename));
    #Is the image OK?
    return "/icons/broken.gif" unless ($imgx && $imgy);
    
    if (($content =~ /$content/) && ($img_type =~ /JPE?G|GIF|PNG/i)){
        #We know that what we'll generate will be seen.
        if ($dir =~ /$cachedir\/$/){
            #Avoiding recursive thumbnails from Hell
            return $filename, $imgx, $imgy 
            }
        #The image is way too big to try to process...
        return undef if $img_size > $config->{thumb_max_size};
    
        if (defined $config->{thumb_scale_width} || defined $config->{thumb_scale_height})
            {
            #Factor scaling
            $xresize = $config->{thumb_scale_width} * $imgx if defined $config->{thumb_scale_width};
            $yresize = $config->{thumb_scale_height} * $imgy if defined $config->{thumb_scale_height};           
            }
       
        elsif(defined $config->{thumb_width} || defined $config->{thumb_height}){
            #Absolute scaling
            $xresize = $config->{thumb_width}  if defined $config->{thumb_width};
            $yresize = $config->{thumb_height} if defined $config->{thumb_height};           
            }
       
        #preserve ratio if we can
        $xresize ||= $yresize * ($imgx/$imgy);
        $yresize ||= $xresize * ($imgy/$imgx);   
        
        #default if values are missing.
        $xresize ||= DEFAULT_ICON_WIDTH;
        $yresize ||= DEFAULT_ICON_HEIGHT;
        
        #round off for picky browsers
        $xresize = int($xresize);
        $yresize = int($yresize);
       
        #Image is too small to actually resize.  Simply resize with the WIDTH and HEIGHT attributes of the IMG tag
        return ($filename, $xresize , $yresize) if $img_size < $config->{thumb_min_size};
       
        if ($config->{changed} || $mod > (stat "$dir$cachedir/$filename")[9]){
            #We should actually resize the image
            if ($img->Read($dir . $filename)){
                #Image is broken
                return "/icons/broken.gif";
                }
            $nThumb++;
            $img->Sample(width=>$xresize, height=>$yresize);
            $img->Write("$dir$cachedir/$filename");       
            }
        return "$cachedir/$filename", $xresize , $yresize;
        }   
    return undef;
    }

sub place_doc {
	my ($r, $cfg, $type) = @_;
	foreach (@{$cfg->{$type}}) {
    		my $subr = $r->lookup_uri($r->uri . $_);
    		
			if (stat $subr->finfo) {
    			print "<HR>" if $type eq "readme";
    			print "<PRE>" unless m/\.html$/;
			$subr->run;
       		     	print "</PRE>" unless m/\.html$/;
       		     	print "<HR>" if $type eq "header";
			}
    		else	{
    			$subr = $r->lookup_uri($r->uri . $_ . ".html");
    			if (stat $subr->finfo) {
    				print "<HR>";
    				$subr->run;
    				}
    			}
    	}
}

sub write_mod {
    my $mod = shift ;
    $mod = $mod & 4095;
    my $letters;
    my %modes = (
                1   =>  'x',
                2   =>  'w',
                4   =>  'r',
                );
    foreach my $f (64,8,1){
        foreach my $key (4,2,1){
            if ($mod & ($key * $f)){
                $letters .= $modes{$key};
                }
            else {
                $letters .= '-';
                }
            }
    }
return $letters;
}

#Configuration Stuff
sub patternize{
	my $pattern = shift;
	$pattern =~ s/\./\\./g;
    	$pattern =~ s/\*/.*/g;
	$pattern =~ s/\?/./g;
	return $pattern;
}

sub push_config{
	my ($cfg, $parms, $value) = @_;
	my $key = $parms->info;
	if ($key eq 'ignore'){
		$value = patternize($value);
		}
	push @ {$cfg->{$key}}, $value;
return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub DirectoryIndex($$$;*){
	my ($cfg, $parms, $files, $cfg_fh) = @_;
	for my $file (split /\s+/, $files){
		push @{$cfg->{indexfile}}, $file;
	}
return DECLINE_CMD if Apache->module('mod_dir.c');
}

sub IndexOptions($$$;*){
	my ($cfg, $parms, $directives, $cfg_fh) = @_;
	foreach (split /\s+/, $directives){
		my $option;
		(my $action, $_) = (lc $_) =~ /(\+|-)?(.*)/;

		if (/^none$/){
			die "Cannot combine '+' or '-' with 'None' keyword" if $action;
			$cfg->{options} = NO_OPTIONS;
			$cfg->{options_add} = 0;
			$cfg->{options_del} = 0;
			}
		elsif (/^iconheight(=(\d*$|\*$)?)?(.*)$/){
			 warn "Bad IndexOption $_ directive syntax" if ($3 || ($1 && !$2));
			if ($2) {
				die "Cannot combine '+' or '-' with IconHeight" if $action;
				$cfg->{icon_height} = $2;
				}
			else 	{
				if ($action eq '-') {
					$cfg->{icon_height} = DEFAULT_ICON_HEIGHT;
					}
				else    {
					$cfg->{icon_height} = 0;
					}
				}
			}
		elsif (/^iconwidth(=(\d*$|\*$)?)?(.*)$/){
 			warn "Bad IndexOption $_ directive syntax" if ($3 || ($1 && !$2));
			if ($2) {
				die "Cannot combine '+' or '-' with IconWidth" if $action;
				$cfg->{icon_width} = $2;
				}
			else 	{
				if ($action eq '-') {
					$cfg->{icon_width} = DEFAULT_ICON_WIDTH;
					}
				else    {
					$cfg->{icon_width} = 0;
					}
				}
			}
		
		elsif (/^namewidth(=(\d*$|\*$)?)?(.*)$/){
			warn "Bad IndexOption $_ directive syntax" if ($3 || ($1 && !$2));
			if ($2) {
				die "Cannot combine '+' or '-' with NameWidth" if $action;
				$cfg->{name_width} = $2;
				}
			else 	{
				die "NameWidth with no value can't be used with '+'" if ($action ne '-');
				$cfg->{name_width} = 0;
				}
			}
		
        	else {
			foreach my $directive (keys %GenericDirectives){
                	if (/^$directive$/){
                    		$option = $GenericDirectives{$directive};
                    		last;                
                    		}
                	}
		 warn "IndexOptions unknown/unsupported directive $_" unless $option;
		}
		
		if (! $action) {
			$cfg->{options} |= $option;
			$cfg->{options_add} = 0;
			$cfg->{options_del} = 0;
			}
		elsif ($action eq '+') {
			$cfg->{options_add} |= $option;
			$cfg->{options_del} &= ~$option;
			}
		elsif ($action eq '-') {
			$cfg->{options_del} |= $option;
			$cfg->{options_add} &= ~$option;
			}
		if (($cfg->{options} & NO_OPTIONS) && ($cfg->{options} & ~NO_OPTIONS)) {
			die "Cannot combine other IndexOptions keywords with 'None'";
			}
	}
return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

# e.g. DirectoryIndex index.html index.htm index.cgi 

sub AddDescription($$$;*){
    #this is not completely supported.  
    #Since I didn't take the time to fully check mod_autoindex.c behavior,
    #I just implemented this as simplt as I could.
    #It's in my TODO
    my ($cfg, $parms, $args, $cfg_fh) = @_;
	my ($desc, $files) = ( $args =~ /^\s*"([^"]*)"\s+(.*)$/);
	my $file = join "|", split /\s+/, $files;
	$file = patternize($file);
    $cfg->{desc}{$file} = $desc; 
return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub IndexOrderDefault($$$$){
	my ($cfg, $parms, $order, $key) = @_;
	die "First Keyword must be Ascending or ending" unless ( $order =~ /^(de|a)scending$/i);
	die "First Keyword must be Name, Date, Size or Description" unless ( $key =~ /^(date|name|size|description)$/i);
	if ($key =~ /date/i){
		$key = 'M';
		}
	else {
	    $key =~ s/(.).*$/$1/;
	}
	$order =~ s/(.).*$/$1/;
	$cfg->{default_order} = $key . $order;

return DECLINE_CMD if Apache->module('mod_autoindex.c');
}

sub FancyIndexing ($$$) {
	my ($cfg, $parms, $opt) = @_;
	die "FancyIndexing directive conflicts with existing IndexOptions None" if ($cfg->{options} & NO_OPTIONS);
	$cfg->{options} = ( $opt ? ( $cfg->{options} | FANCY_INDEXING ) : ($cfg->{options} & ~FANCY_INDEXING ));
return DECLINE_CMD if Apache->module('mod_autoindex.c');
}
	
sub DIR_CREATE {
	my $class = shift;
	my $self = $class->new;
	$self->{icon_width} = DEFAULT_ICON_WIDTH;
	$self->{icon_height} = DEFAULT_ICON_HEIGHT;
	$self->{name_width} = DEFAULT_NAME_WIDTH;
	$self->{default_order} = DEFAULT_ORDER;
	$self->{ignore} = [];
	$self->{readme} = [];
	$self->{header} = [];
	$self->{indexfile} = [];
	$self->{desc} = {};
	$self->{options} = 0;
	$self->{options_add} = 0;
	$self->{options_del} = 0;
return $self;
}

sub new { 
	return bless {}, shift;
	}

sub DIR_MERGE {
	my ($parent, $current) = @_;
	my %new;
    	$new{options_add} = 0;
    	$new{options_del} = 0;
	$new{icon_height} = $current->{icon_height} ? $current->{icon_height} : $parent->{icon_height};
	$new{icon_width} = $current->{icon_width} ? $current->{icon_width} : $parent->{icon_width};
	$new{name_width} = $current->{name_width} ? $current->{name_width} : $parent->{name_width};
	$new{default_order} = $current->{default_order} ? $current->{default_order} : $parent->{default_order};
	$new{readme} = [ @{$current->{readme}}, @{$parent->{readme}} ];
	$new{header} = [ @{$current->{header}}, @{$parent->{header}} ];
	$new{ignore} = [ @{$current->{ignore}}, @{$parent->{ignore}} ];
	$new{indexfile} = [ @{$current->{indexfile}}, @{$parent->{indexfile}} ];
	
    	$new{desc} = {% {$current->{desc}}};    #Keep descriptions local
	
	if ($current->{options} & NO_OPTIONS){
        	#None override all directives
		$new{options} = NO_OPTIONS;
		}
	else {
		if ($current->{options} == 0) {
            		#Options are all incremental, so combine them with parent's values
			$new{options_add} = ( $parent->{options_add} | $current->{options_add}) & ~$current->{options_del};
			$new{options_del} = ( $parent->{options_del} | $current->{options_del}) ;
			$new{options} = $parent->{options} & ~NO_OPTIONS;
			}
		else {
            		#Options weren't all incremental, so forget about inheritance, simply override
			$new{options} = $current->{options};
			}
		
        	$new{options} |= $new{options_add};
		$new{options} &= ~ $new{options_del};
		}
return bless \%new, ref($parent);
}


sub status {
	my ($r, $q) = @_;
	my @s;
	my $cfg = Apache::ModuleConfig->get($r);
	push (@s, "<B>" , __PACKAGE__ , " (ver $VERSION) statistics</B><BR>");

	push (@s , "Done " . $nDir . " listings so far<BR>");
	push (@s , "Done " . $nRedir . " redirects so far<BR>");
	push (@s , "Done " . $nIndex. " indexes so far<BR>");
    	push (@s , "Done " . $nThumb. " thumbnails so far<BR>");

	use Data::Dumper;
	my $string = Dumper $cfg;
	push (@s, $string);
	
return \@s;
}

1;

__END__

=head1 NAME

Apache::AutoIndex - Perl replacment for mod_autoindex and mod_dir Apache module

=head1 SYNOPSIS

  PerlModule Apache::Icon
  PerlModule Apache::AutoIndex
  (PerlModule Image::Magick) optionnal
  PerlTransHandler Apache::AutoIndex::transhandler
  PerlHandler Apache::AutoIndex

=head1 DESCRIPTION

This module can replace completely mod_dir and mod_autoindex
standard directory handling modules shipped with apache.
It can currently live right on top of those modules, but I suggest
simply making a new httpd without these modules compiled-in.

To start using it on your site right away, simply preload
Apache::Icon and Apache::AutoIndex either with:

  PerlModule Apache::Icon
  PerlModule Apache::AutoIndex

in your httpd.conf file or with:

   use Apache::Icon ();
   use Apache::AutoIndex;
 
in your require.pl file.

Then it's simply adding

    PerlTransHandler Apache::Autoindex::transhandler
    PerlHandler Apache::AutoIndex 

somewhere in your httpd.conf but outside any Location/Directory containers.


=head2 VIRTUAL HOSTS

If used in a server using virtual hosts, since mod_perl doesn't have configuration merging routine for virtual hosts, you'll have to put the PerlHandler and PerlTransHandler directives in each and every <VHOST></VHOST> 
section you wish to use Apache::AutoIndex with.

=head1 DIRECTIVES

It uses all of the Configuration Directives defined by mod_dir and mod_autoindex.  

Since the documentation about all those directives can be found
on the apache website at:

 http://www.apache.org/docs/mod/mod_autoindex.html 
 http://www.apache.org/docs/mod/mod_dir.html

I will only list modification that might have occured in this
perl version.

=head2 SUPPORTED DIRECTIVES

=over

=item *

AddDescription

=item *

DirectoryIndex

=item *

FancyIndexing - should use IndexOptions FancyIndexing since 1.3.2

=item *

IndexOptions  - All directives are currently supported. And a few were added

=item *

HeaderName  - It can now accept a list of files instead of just one

=item *

ReadmeName  - It can now accept a list of files instead of just one

=item *

IndexIgnore

=item *

IndexOrderDefault

=back

=head2 NEW DIRECTIVES

=over

=item * IndexOptions

Thumbnails - Lisitng will now include thumbnails for pictures.  Defaults to false.

ShowPermissions - prints file permissions. Defaults to false.

=item * PerlSetVar IndexHtmlBody 'expression'

This is an expression that should producea complete <BODY> tag when eval'ed.  One
example could be :

 PerlSetVar IndexHtmlBody '<BODY BACKGROUND=\"$ENV{BACKGROUND}\">'

=item * PerlSetVar IndexHtmlTable value

This is a string that will be inserted inside the table tag of the listing like 
so : <TABLE $value>

=item * PerlSetVar IndexHtmlHead value

This should be the url (absolute/relative) of a ressource that would be inserted right
after the <BODY> tag and before anything else is written.

=item * PerlSetVar IndexHtmlFoot value

This should be the url (absolute/relative) of a ressource that would be inserted right
before the </BODY> tag and after everything else is written.

=item * PerlSetVar IndexDebug [0|1]

If set to 1, the listing displayed will print usefull (well, to me)
debugging information appended to the bottom. The default is 0.

=back

=head2 UNSUPPORTED DIRECTIVES

=over

=item * - Hopefully none :-)

=back

=head1 THUMBNAILS

Since version 0.07, generation of thumbnails is possible.  This means that listing a
directory that contains images can be listed with little reduced thumbnails beside each
image name instead of the standard 'image' icon.

To enable this you simply need to preload Image::Macick in Apache.  The IndexOption option
Thumbnails controls thumbnails generation for specific directories like any other IndexOption
directive.

=head2 USAGE

The way thumbnails are generated/produced can be configured in many ways, but here is a general
overview of the procedure.

For each directory containing pictures, there will be a .thumbnails directory in it that will
hold the thumbnails.  Each time the directory is accessed, and if thumbnail generation is
active, small thumbnails will be produced, shown beside each image name, instaed of the normal
, generic, image icon.

That can be done in 2 ways.  In the case the image is pretty small, no actual thumbnail will
be created.  Instead the image will be resized with the HEIGHT and WIDTH attributes of the IMG 
tag.

If the image is big enough, it is resized with Image::Magick and saved in the .thumbnails directory
for the next requests.

Change in the configuration of the indexing options will correctly refresh the thumbnails stored.
Also if an original image is modified, the thumbnail will be modified accordingly.  Still, the
browser might screw things up if it preserves the cached images.  

The behaviour of the Thumbnail generating code can be customized with these PerlSetVar variables:

=head2 DIRECTIVES

=over

=item * IndexCacheDir dir

This is the name of the directory in wich generated thumbnails will be created.  Make sure the
user under wich the webserver runs has read and write privileges.  Defaults to .thumbnails

=item * IndexCreateDir 0|1

Specifies that when a cache directory isn't found, should an attempt to create it be done.
Defaults to 1(true), meaning if possible, missing cache directories will be created. 

=item * ThumbMaxFilesize bytes

This value fixes the size of an image at wich thumbnail processing isn't even attempted.
Since trying to process a few very big images could bring a server down to it's knees.
Defaults to 500,000

=item * ThumbMinFilesize bytes

This value fixes the size of an image at wich thumbnail processing isn't actually done.
Since trying to process already very small images could would be an overkill, the image is
simply resized withe the size attributes of the IMG tag.  Defaults to 5,000.

=item * ThumbMaxWidth pixels

This value fixes the x-size of an image at wich thumbnail processing isn't actually done.
Since trying to process already very small images could would be an overkill, the image is
simply resized withe the size attributes of the IMG tag.  Defaults to 4 times the default
icon width.

=item * ThumbMaxHeight pixels

This value fixes the y-size of an image at wich thumbnail processing isn't actually done.
Since trying to process already very small images could would be an overkill, the image is
simply resized withe the size attributes of the IMG tag.  Defaults to 4 times the default
icon height

=item * ThumbScaleWidth scaling-factor

This value fixes an x-scaling factor between 0 and 1 to resize the images with.  The image ratio will be
preserved only if there is no scaling factor for the other axis of the image. 

=item * ThumbScaleHeight scaling-factor

This value fixes an y-scaling factor between 0 and 1 to resize the images with.  The image ratio will be
preserved only if there is no scaling factor for the other axis of the image. 

=item * ThumbWidth pixels

This value fixes a fixed x-dimension to resize the image with.  The image ratio will be
preserved only if there is no fixed scaling factor for the other axis of the image.  This has no
effect if a scaling factor is defined.

=item * ThumbHeight pixels

This value fixes a fixed x-dimension to resize the image with.  The image ratio will be
preserved only if there is no fixed scaling factor for the other axis of the image.  This has no
effect if a scaling factor is defined.

=back

=head1 TODO

The transhandler problem should be fixed.

Some minor changes to the thumbnails options will still have the thumbnails re-generated.  This 
should be avoided by checking the attributes of the already existing thumbnail.

Some form of garbage collection should be performed or cache directories will fill up.

Find new things to add...

=head1 SEE ALSO

perl(1), L<Apache>(3), L<Apache::Icon>(3), L<Image::Magick>(3) .

=head1 SUPPORT

Please send any questions or comments to the Apache modperl 
mailing list <modperl@apache.org> or to me at <gozer@ectoplasm.dyndns.com>

=head1 NOTES

This code was made possible by :

=over

=item Doug MacEachern 

<dougm@pobox.com>  Creator of Apache::Icon, and of course, mod_perl.

=item Rob McCool

who produced the final mod_autoindex.c I copied, hrm.., well, translated to perl.

=item The mod_perl mailing-list 

at <modperl@apache.org> for all your mod_perl related problems.

=back

=head1 AUTHOR

Philippe M. Chiasson <gozer@ectoplasm.dyndns.com>

=head1 COPYRIGHT

Copyright (c) 1999 Philippe M. Chiasson. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
