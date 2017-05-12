#!/usr/bin/perl
# Apache::ImgIndex

#
# James Pavlick, 2000
# mod_perl module for indexing directories of images
#

=head1 NAME

Apache::ImgIndex

=head1 SYNOPSIS

Add the following to your httpd.conf and restart. Then point your browser to
http://yoursite/photos


  <Location /photos>
    AllowOverride None
    #Options -Indexes -Includes -FollowSymLinks
    Order allow,deny
    Allow from all

    SetHandler perl-script
    PerlHandler Apache::ImgIndex
    PerlSetVar Rows 10
    PerlSetVar Cols 5
    PerlSetVar Thumb-size 50x20
    PerlSetVar Show-names 1
    PerlSetVar Hide-dirs 1
  </Location>

Make sure /photos contains the full size images that you want to display.

=head1 DESCRIPTION

I<Apache::ImgIndex> is a simple mod_perl application for displaying photos. 
I<Apache::ImgIndex> will automatically build thumbnails of the images. You 
can also rotate and scale the images from the web interface.

=head1 CAVEATS

=over 2

=item B<*> Lots of work still to do

=cut



package Apache::ImgIndex;
use strict;
use Apache2;
#use Apache::compat;
use Apache::RequestRec;
use Apache::RequestIO;
use Apache::Const qw(:common HTTP_OK);
use Apache::Log;
use APR::Const qw(:filetype);
use APR::Finfo;
use Image::Magick ();
use DirHandle ();
use FileHandle ();
use File::Basename qw(fileparse);

use vars qw(%gOptions @gOutput $gOutputStarted $VERSION);

$VERSION = 0.02;

%gOptions = (
	     'thumb-size' => '100x75',    # set thumbnail size
             'force'      => 0,           # always rebuild thumbnails
             'rows'       => 5,           # rows to display
             'cols'       => 4,           # columns to display
             'show-names' => 0,           # show thumbnail names
             'hide-dirs'  => 0,           # hide the photo directories list
             'filter'     => '.*',        # display only directories that match 
	    );



sub handler {
    my($r) = shift;

    # store output in this array
    @gOutput = ();

    $gOutputStarted = 0;

    # set config values
    my $val = '';
    $gOptions{'thumb-size'} = $val if($val = $r->dir_config('Thumb-size'));
    $gOptions{'force'}      = $val if($val = $r->dir_config('Force'));  
    $gOptions{'rows'}       = $val if($val = $r->dir_config('Rows'));
    $gOptions{'cols'}       = $val if($val = $r->dir_config('Cols'));
    $gOptions{'show-names'} = $val if($val = $r->dir_config('Show-names')); 
    $gOptions{'hide-dirs'}  = $val if($val = $r->dir_config('Hide-dirs'));
    $gOptions{'doc-root'}   = $r->document_root . $r->location;
    $gOptions{'base-url'}   = $r->location;
    $gOptions{'filter'}     = $val if($val = $r->dir_config('Filter'));


    # do processing for a directory of images
    if($r->finfo->filetype == DIR) {

        if($r->args =~ /name=/) {
           # show image detail html page
           showImgDetail($r);

        } else {
          # show the thumbnail index html page
          my ($name, $path, $ext) = fileparse($r->filename, qr{\.\w*$});
          mkdir("$path/.thumbs") unless(-d "$path/.thumbs");
          showImgThumbs($r);
        }
    }

    # do processing on the image file itself
    if($r->filename =~ /-thumb/) {
           showThumbFile($r);
    }

    if($r->finfo->filetype == REG) {
        if($r->content_type =~ m:^image/: && $r->args) {
           # rotate the image
           processImg($r);

        } else {
           #just pass the image down the chain
           return DECLINED;
        }
    }

    $r->print(@gOutput); 

    return OK;
}


# showImgThumbs
# 
# list the contents of a directory as an HTML thumbnail index
#
sub showImgThumbs {
    my($r) = shift;

    my($dir) = $r->filename;
    my($baseUri) = $r->uri;
    my(%in) = map { split('=', $_) } (split('&', $r->args));

    my($perpage) = $gOptions{'rows'} * $gOptions{'cols'};
    my $root = $gOptions{'doc-root'};
    my($start) = $in{'start'} || 0;

    # remove the base directory from the file path
    (my $dirName = $dir) =~ s/^$root//;

    my($dh) = DirHandle->new($dir) ||
                 $r->log_error("Can't open directory '$dir': $?");

    my(@filelist) = ();
    while( defined($_ = $dh->read) ) {
       next unless(/^(.+)\.(jpg|gif|png)$/i);
       next if(/^\./);
#       next if($1 =~ /thumb/);

       push(@filelist, $_);
    }

    $dh->close;


    # Output page to client
    $r->content_type('text/html');
    output(
           "<HTML>\n",
           "<HEAD>\n",
           "  <TITLE>Image Index: $dirName</TITLE>\n",
           "</HEAD>\n",
           qq|<BODY bgcolor="#DDDDDD">\n\n|,
           qq|<CENTER>\n|,
          );

    output(
           qq|<TABLE width="170" align="left" border="0">\n|,
           qq|  <TR><TD><b>Image Directories:</b></TD></TR>\n|,
           listDirectory($dir), 
           qq|</TABLE>\n\n|,
          ) unless($gOptions{'hide-dirs'});

    output(
           qq|<TABLE border=0 bgcolor="#CCCCCC">\n|,
           qq|  <TR><TD>\n|,
           qq|    <TABLE border=0 cellpadding=0 cellspacing=0 width="100%">\n|,
           qq|      <TR><TD align="center" bgcolor="#AAAAAA"><font size="+1"><b>$dirName</font></b></TD></TR>\n|,
           qq|    </TABLE>\n\n|,
          );


    my($w, $h) = split('x', $gOptions{'thumb-size'});

    ### Thumbnail image table
    output(qq|    <TABLE align="center" bgcolor="#CCCCCC" border="1" width="|, ($w + 25 )* $gOptions{'cols'}, qq|">\n|);

    if(@filelist) {
       my($counter) = 0;
       my @sorted = (sort @filelist);

       for(my $x = $start; $x < @sorted; $x++) {
          $sorted[$x] =~ /^(.+)\.(jpg|gif|png)$/i;
          my($name, $ext) = ($1, $2);

          # set the display name
          my $displayName = '';
          if($gOptions{'show-names'}) {
              ($displayName = $name) =~ s/[_\-]/\s/g;
              $displayName = substr($displayName, 0, 22) . "..." 
                   if(length $displayName >= 22);
          }

          my($thumbName) = "${name}-thumb.$ext";
 
          output("      <TR>\n") if( $counter == 0 || ($counter % $gOptions{'cols'}) == 0 );
          output(
                 "    ",
                 qq|        <TD align="center">|,
                 qq|<A href="./?start=$start&name=$name.$ext">|,
                 qq|<IMG src="./.thumbs/$thumbName" hspace="15" height="$h" width="$w"></A>|, 
                 qq|<BR>|,
                 $displayName,
                 qq|</TD>\n|, 
                );

          output("      </TR>\n") if( (($counter + 1) % $gOptions{'cols'}) == 0 );

          last if($counter == ($perpage - 1));
          $counter++;
       } 

    } else {
        output(      qq|<tr><td align="center"><font size="+2"><b>No Images Available</b></font</td></tr>\n|);
    }

    output(qq|    </TABLE>\n\n|,);



    ### Navigation bar table
    output(
           qq|    <TABLE bgcolor="#AAAAAA" cellpadding=0 cellspacing=0 border=0 width="100%">\n|,
           qq|      <TR>\n|
          );

    my($index) = 0;
    # previous page
    if($start - $perpage >= 0) {
       $index = $start - $perpage;
       output(qq|        <TD width=100 align="center"><A href="$baseUri?start=$index">[previous]</A></TD>\n|);

    } else {
       output(qq|        <TD width=100>&nbsp;</TD>\n|);
    }



    # page indexes
    if(@filelist) { 
       output(
              qq|        <TD align="center" valign="bottom">\n|,
              qq|          <FORM>\n|,
              qq|          <SELECT onChange="document.location='$baseUri?start=' + this.options[this.selectedIndex].value">\n|
             );
 
       for(my $y = 0; $y <= int((@filelist - 1)/$perpage); $y++) {
          $index = $perpage * $y;
          my $pagenum = $y + 1;

          ($index == $start) ?
              output(qq|              <option value="$index" selected>page $pagenum\n|):
              output(qq|              <option value="$index">page $pagenum\n|);
       }

       output(
              qq|          </SELECT><BR>\n|,
              qq|          <font size="-1"><i>Total: </i>|, scalar @filelist, qq| images</font>\n|,
              qq|          </FORM>\n|,
              qq|        </TD>\n|
             );
    }
    
    # next page
    if($start + $perpage < $#filelist) {
       $index = $start + $perpage; 
       output(qq|        <TD width=100 align="center"><A href="$baseUri?start=$index">[next]</A></TD>\n|);

    } else {
       output(qq|        <TD width=100>&nbsp;</TD>\n|);
    }


    output(
           "      </TR>\n",
           "    </TABLE>\n",
           "  </TD></TR>\n",
           "</TABLE>\n",
           "</CENTER>\n",
	   "</BODY>\n",
           "</HTML>\n"
          );

}



# showThumbFile
#
#
sub showThumbFile {
    my $r = shift || return;

    my %mimeType = 
       (jpg => 'image/jpeg', gif => 'image/gif', png => 'image/png');
    my ($name, $path, $ext) = fileparse($r->filename, qr{\.\w*$});
    my($w, $h) = split('x', $gOptions{'thumb-size'});

    $name =~ s/^\.//g;
    $path =~ s/\/$//g;
    $ext =~ s/^\.//g;
 
    (my $imgName = $name) =~ s/-thumb$//i;
    my($thumbName) = "$name.$ext";
    my($Img) = Image::Magick->new();
    my($tw, $th) = (0, 0);

    if(-f "$path/$thumbName") {
        ($tw, $th) = $Img->Ping("$path/$thumbName");
    }

    # build the thumbnail if it doesn't exist
    if( ($w != $tw && $h != $th) || $gOptions{'force'} ) {
        $Img->Read("$path/../$imgName.$ext");
        $Img->Resize(geometry=>"$gOptions{'thumb-size'}"); 
        $Img->Write("$path/$thumbName");
    }

    my $Fh = FileHandle->new();
    $Fh->open("$path/$thumbName") || die("Can't open image file $path/$thumbName");

    $r->content_type($mimeType{lc $ext});
    output(<$Fh>);

    undef $Img; 
    $Fh->close();
}



# showImgDetail
#
#
#
sub showImgDetail {
    my($r) = shift;

    my(%in) = map { my($key, $val) = split('=', $_); $key => $val } 
                  (split('&', $r->args));
    my($baseUri) = $r->uri; 

    # only rotate up to 360 degrees 
    if($in{'rot'} >= 360) { $in{'rot'} -= 360 };

    # only allow scaling to 25% and 200% of image size
    if($in{'scale'} < -75) { $in{'scale'} = -75 };
    if($in{'scale'} > 100) { $in{'scale'} = 100 };

    my $scale = $in{'scale'} + 100;

    my $rotText = ($in{'rot'}) ? "(Rotated: $in{'rot'}&deg;)" : ''; 
    my $scaleText = ($in{'scale'}) ? "(Scaled: $scale%)" : '';
 
    $r->content_type("text/html"); 
    output(
              "<HTML>\n",
              "<HEAD>\n",
              "  <TITLE>Image: $in{'name'} $rotText $scaleText</TITLE>\n",
              "</HEAD>\n",
              qq|<BODY bgcolor="#ffffff">\n\n|,
              "<CENTER>\n",
              qq|<TABLE border=1>\n|,
              qq| <TR><TD>&nbsp;</TD><TD align="center"><A href="$baseUri?start=$in{'start'}"><B>Image Index</B></A></TD><TD>&nbsp;</TR>\n|,
              qq| <TR><TD align="center"><A href="$baseUri?start=$in{'start'}&name=$in{'name'}&rot=|,
              $in{'rot'} + 270, qq|&scale=$in{'scale'}"><B>270</B></A></TD>|,
              qq|<TD align="center"><A href="$baseUri?start=$in{'start'}&name=$in{'name'}&rot=$in{'rot'}&scale=|, $in{'scale'} - 25, qq|">-</A> Zoom <A href="$baseUri?start=$in{'start'}&name=$in{'name'}&rot=$in{'rot'}&scale=|, $in{'scale'} + 25, qq|">+</A></TD>|,
              qq|<TD align="center"><A href="$baseUri?start=$in{'start'}&name=$in{'name'}&rot=|,
              $in{'rot'} + 90, qq|&scale=$in{'scale'}"><B>90</B></A></TD></TR>\n|,
              qq| <TR><TD>&nbsp;</TD><TD align="center"><A href="$baseUri?start=$in{'start'}&name=$in{'name'}&rot=|,
              $in{'rot'} + 180, qq|&scale=$in{'scale'}"><B>180</B></A></TD><TD>&nbsp;</TD></TR>\n|,
              "</TABLE>\n",
              qq|<TABLE border=1 width="100%">\n|,
            );


        output(qq|  <TR><TD align="center"><IMG src="$baseUri/$in{'name'}?|);
        output(qq|rot=$in{'rot'}|) if($in{'rot'});
        output(qq|&scale=$in{'scale'}|) if($in{'scale'});
        output(qq|" border=0></TD></TR>\n|);

    output(
           "</TABLE>\n",
           "</CENTER>\n",
           "</BODY>\n",
           "</HTML>\n",
          );
}


# processImg
#
#
#
sub processImg {
    my($r) = shift;

    my(%in) = map { my($key, $val) = split('=', $_); $key => $val }                             (split('&', $r->args));

    my($imgfile) = $r->filename;
    my ($name, $path, $ext) = fileparse($imgfile, qr{\..*});

    $path =~ s/\/$//g;
    $ext =~ s/^\.//g;

    # only rotate up to 360 degrees
    if($in{'rot'} >= 360) { $in{'rot'} -= 360 };


    # only allow scaling to 25% and 200% of image size
    if($in{'scale'} < -75) { $in{'scale'} = -75 };
    if($in{'scale'} > 100) { $in{'scale'} = 100 };

    if(%in) {
       my($tmpfile) = "/tmp/$name." . time . ".$$.$ext";
      
       my $scale = $in{'scale'} + 100; 
 
       my($Img) = Image::Magick->new;
       $Img->Read($imgfile);
       $Img->Rotate(degrees=>$in{'rot'}) if($in{'rot'});
       $Img->Scale(geometry=>"${scale}%x${scale}%") if($in{'scale'});
       $Img->Write("$tmpfile");

       my($fh)  = FileHandle->new("$tmpfile");

       unless($fh) {
          $r->log_error("Couldn't open file '$tmpfile'");
          return SERVER_ERROR;
       }
 
       local $/;
       output(<$fh>);
       $fh->close;

       unlink $tmpfile;

    } else {
       return DECLINED;
    }

}


# dirIndex
#
#
sub dirIndex {
   my($dirlist) = shift;
   my($dir) = shift;

   my($filter) = $gOptions{'filter'};
   my($dh) = DirHandle->new($dir);
   my(@contents) = $dh->read;
   $dh->close;  

   foreach my $item (sort @contents) {
       # skip directories containing .private files
       next if(-e "$dir/$item/.private");

       # skip files/directories starting with .
       next if($item =~ /^\.+/);

       # skip directories that aren't in the "filter" list 
       next unless("$dir/$item" =~ /$filter/);

       # Add the item to the the directory list if it's a directory 
       next unless(-d "$dir/$item");
       $dirlist->{"$dir/$item"}{'name'} = $item;
   }
}



# listDirectory
#
#
sub listDirectory {
    my($dir) = shift;

    my($dirlist) = {};
    my($root) = $gOptions{'doc-root'} || ''; 
    my($baseurl) = $gOptions{'base-url'} || '';
    my($subdir) = $dir;
    my $retval = '';

    # build a list of directories under the root
    while($subdir =~ /^$root/) {
       $subdir =~ s/\/+$//;
       dirIndex($dirlist, $subdir);
       $subdir = (fileparse($subdir))[1];
    }

 
    # translate directory names into urls
    foreach my $item (sort keys %$dirlist) {
       my($dirname) = $dirlist->{$item}{'name'};

       (my $url = $item) =~ s/^$root//;
       $url =~ s/^\/+//;
       $url =~ s/\/+$//;
       $url = join('/', $baseurl, $url);
       my $tab = '--' x ( split('/', $url)  - 3);
       $retval .= qq|  <tr><td>$tab<a href="$url/">$dirname</a><td></tr>\n|;
    }

    $retval;
}



sub output { push(@gOutput, @_); }



1;
