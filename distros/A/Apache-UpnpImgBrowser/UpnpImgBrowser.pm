#!/usr/bin/perl
# Apache::UpnpImgBrowser

#
# James Pavlick, 2007
# mod_perl module for browsing directories of images stored on a Upnp device
#

=head1 NAME

Apache::UpnpImgBrowser

=head1 SYNOPSIS

Add the following to your httpd.conf and restart. Then point your browser to
http://yoursite/photos


  <Location /photos>
    AllowOverride None
    #Options -Indexes -Includes -FollowSymLinks
    Order allow,deny
    Allow from all

    SetHandler perl-script
    PerlHandler Apache::UpnpImgBrowser
    PerlSetVar Basedir Photos/Folder
    PerlSetVar Rows 10
    PerlSetVar Cols 5
    PerlSetVar Thumb-size 50x20
    PerlSetVar Show-names 0
    PerlSetVar Hide-dirs 1
    PerlSetVar Filter  vacation
  </Location>

=head1 DESCRIPTION

I<Apache::UpnpImgBroswer> is a mod_perl application for displaying photos
hosted on a UPnPAV compliant Media Server. I<Apache::UpnpImgBroswer> will
automatically discover all these types of devices on your network.

=head1 CAVEATS

=over 2

=item B<*> Thumbnails only work with TwonkyVision

=item B<*> Lots of work still to do

=cut


package Apache::UpnpImgBrowser;
use strict;
use Apache2;
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
use Net::UPnP::ControlPoint;
use Net::UPnP::AV::MediaServer;
use SOAP::Lite maptype => {}; 
use XML::Simple;
use Data::Dumper;
use POSIX qw(strftime);
use Cache::FileCache;
use URI::Escape;
use LWP::Simple;



use vars qw(%gOptions @gOutput $gOutputStarted $gCp @gDeviceList $gLastDir $cache $VERSION);

$VERSION = 0.01;

%gOptions = (
	     'thumb-size' => '100x75',    # set thumbnail size
             'force'      => 0,           # always rebuild thumbnails
             'rows'       => 5,           # rows to display
             'cols'       => 4,           # columns to display
             'show-names' => 0,           # show thumbnail names
             'hide-dirs'  => 0,           # hide the photo directories list
             'filter'     => '.*',        # display only directories that match 
             'basedir'    => 'Photos',    # Base directory of the UPNP server
	    );

$cache = new Cache::FileCache( { 'namespace' => 'UpnpImgBrowser',
                                 'default_expires_in' => 600 } );


sub handler {
    my($r) = shift;

    $gCp =  $cache->get('cp');
    @gDeviceList = $cache->get('device');
 
    if (! defined $gCp) {
        $gCp = Net::UPnP::ControlPoint->new();
        $cache->set('cp', $gCp);
    }

    unless (grep ref $_ eq 'Net::UPnP::Device', @gDeviceList) { 
        @gDeviceList = (upnpInitDevice($r));
        $cache->set('device', @gDeviceList);
    }

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
    $gOptions{'basedir'}    = $val if($val = $r->dir_config('Basedir'));
    $gOptions{'filter'}     = $val if($val = $r->dir_config('Filter'));



    if($r->args =~ /image=/) {
       # show image detail html page
       showImgDetail($r);

     } elsif ($r->args =~ /target=/) {
        # proxy the image request
        proxyRequest($r);

    } else {
       # show the thumb nail page
       showImgThumbs($r);
    }

    $r->print(@gOutput); 

    return OK;
}



# upnpInitDevice
#
#
sub upnpInitDevice {
    my $r = shift;

    my @retval = ();
    my @device_list = $gCp->search(st => "urn:schemas-upnp-org:device:MediaServer:1", mx => 5);

    foreach my $device (@device_list) {
        my $udn = $device->getudn;
        next if grep($_->getudn eq $udn, @retval);
        push(@retval, $device);

        $r->log_error("Added name: " . $device->getfriendlyname() . " " .
                      $device->getudn . " type: " . $device->getdevicetype()
        );
    }

    @retval;
}



# upnpGetMetadata
#
#
sub upnpGetMetadata {
    my ($r, $device, $objid) = @_;

    $objid ||= 0;

    my(%retval) = ();

    my($basedir) = $gOptions{'basedir'} || '';
    my(%action_in_arg) = (
                'ObjectID' => $objid,
    );

    return undef unless ref $device eq 'Net::UPnP::Device';

    my $mediaServer = Net::UPnP::AV::MediaServer->new();
    $mediaServer->setdevice($device);

    my $action = $mediaServer->browsemetadata(%action_in_arg);
    my $action_out_arg = $action->getargumentlist();
    my $result = $action_out_arg->{'Result'};

    return undef unless $result;

    my $tree = XMLin($result, forcearray => ["container"]);

    foreach my $objectid (keys %{$tree->{container}}) {
        my $entry = $tree->{container}{$objectid};

        $retval{title} = $entry->{"dc:title"};
        $retval{date} = $entry->{"dc:date"};
        $retval{parent} = $entry->{"parentID"};
        $retval{childcount} = $entry->{"childCount"};
        $retval{id} = $objectid;
    }

    \%retval;
}


# upnpGetFileLis,
sub upnpGetFileList {
    my ($r, $device, $objid) = @_;

    $objid ||= 0;

    my($basedir) = $gOptions{'basedir'} || '';
    my(@retval) = ();
    my(%action_in_arg) = (
                'ObjectID' => $objid,
                'BrowseFlag' => 'BrowseDirectChildren',
                'Filter' => '*',
                'StartingIndex' => 0,
                'RequestedCount' => 0,
    );

    return undef unless ref $device eq 'Net::UPnP::Device';


    my $service = $device->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1');
    return undef unless $service;
    my $action = $service->postcontrol('Browse', \%action_in_arg);

    my $action_out_arg = $action->getargumentlist();

    my $result = $action_out_arg->{'Result'};
    return undef unless $result;

    my $tree = XMLin($result, forcearray => ["item"]);

    foreach my $objectid (keys %{$tree->{item}}) {
        my $entry = $tree->{item}{$objectid};
        my %item;

        # Only allow photo items
        next unless $entry->{'upnp:class'} eq 'object.item.imageItem.photo';

        $item{title} = $entry->{"dc:title"};
        $item{date} = $entry->{"dc:date"};
        $item{parent} = $entry->{"parentID"};
        $item{id} = $objectid;
        $item{res} = [];

        my @tmp = (ref $entry->{"res"} eq 'ARRAY') ? 
            @{$entry->{"res"}} : ($entry->{"res"}); 

        foreach my $res (@tmp) {
            my($w, $h) = split('x', $res->{'resolution'});
            my($size) = $res->{'size'}; #$w * $h;

            my($url) = $res->{'content'};
            my($contenttype) = $res->{'protocolInfo'};

            $contenttype =~ s/http-get:[^:]*:([^:]*):.*/$1/;
            next unless $contenttype =~ /^image/;  # only allow images

            $url =~ s/^http:\/\/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?\///;

            push(@{$item{res}}, 
                {
                  height => $h, 
                  width => $w, 
                  size => $size, 
                  url => $url, 
                  contenttype => $contenttype
                 });
        }

        push(@retval, \%item);
    }

    @retval;
}


# upnpGetDirectory
#
#
sub upnpGetDirectory{
    my ($r, $device, $objid) = @_;

    $objid ||= 0;

    my($basedir) = $gOptions{'basedir'} || '';
    my(@retval) = ();
    my(%action_in_arg) = (
                'ObjectID' => $objid,
                'BrowseFlag' => 'BrowseDirectChildren',
                'Filter' => '*',
                'StartingIndex' => 0,
                'RequestedCount' => 0,
                'SortCriteria' => '',
    );

    return undef unless ref $device eq 'Net::UPnP::Device';

    my $service = $device->getservicebyname('urn:schemas-upnp-org:service:ContentDirectory:1'); 
    return undef unless $service;

    my $action = $service->postcontrol('Browse', \%action_in_arg);

    my $action_out_arg = $action->getargumentlist();
    my $result = $action_out_arg->{'Result'};
    return undef unless $result;

    my $tree = XMLin($result, forcearray => ["container"]);

    foreach my $objectid (keys %{$tree->{container}}) {
        my $entry = $tree->{container}{$objectid};
        my %dir;

        $dir{title} = $entry->{"dc:title"};
        $dir{date} = $entry->{"dc:date"};
        $dir{parent} = $entry->{"parentID"};
        $dir{id} = $objectid;

        push(@retval, \%dir);
    }

    @retval;
}


# showImgThumbs
# 
# list the contents of a directory as an HTML thumbnail index
#
sub showImgThumbs {
    my($r) = shift;

    my(%in) = map { split('=', $_) } (split('&', $r->args));

    my($perpage) = $gOptions{'rows'} * $gOptions{'cols'};
    my($page) = $in{'page'} || 1;
    my($dir) = $in{dir} || 0;

    my($dev) = $in{'dev'} || $gDeviceList[0]->getudn;

    my(@filelist) = getFileList($r, $dir, $dev);
    my(@dirlist) = getDirectoryList($r, $dir, $dev);


    my $parentdir = getParentId($r, $dir); 
    my $parentname = getMetadata($r, $parentdir, $dev)->{title};
#    my $dirname = (grep $_->{id} eq $dir, @dirlist)[0]->{title};
    my $dirname = '';


    # Output page to client
    $r->content_type('text/html');
    output(
           "<html>\n",
           "<head>\n",
           "  <title>Image Browser</title>\n",
           qq|  <style type="text/css">\n|,
           "  <!--\n",
           "   a { text-decoration: none; }\n",
           "   .menu { color: orange; text-decoration: none; }\n", 
           "   #searchbox\n",
           "   {\n",
           "    text-align: left;\n",
           "    border: #DDDDDD 1px solid;\n",
           "    border-top: none;\n",
           "    padding-top: 6px;\n",
           "    padding-right: 2px;\n",
           "    border-left: none;\n",
           "    position: absolute;\n",
           "    left: 0px;\n",
           "    top: 0px;\n",
           "    width: 180px;\n",
           "   }\n",
           "   #leftcol\n",
           "   {\n",
           "    text-align: left;\n",
           "    border: #DDDDDD 1px solid;\n",
           "    border-top: none;\n",
           "    border-bottom: none;\n",
           "    padding-top: 6px;\n",
           "    padding-right: 2px;\n",
           "    padding-bottom: 10px;\n",
           "    border-left: none;\n",
           "    position: absolute;\n",
           "    left: 0px;\n",
           "    width: 180px;\n",
           "    height: 600px;\n",
           "   }\n",
           "  -->\n",
           "  </style>\n",
           "</head>\n",
           qq|<body bgcolor="#FFFFFF">\n\n|,
           qq|<center>\n|,
          );

    output(
           qq|<div id="searchbox">\n|,
           qq|<table width="170" align="left" border="0">\n|,
           qq|  <tr><td>\n|,
           qq|    <form method="get" action="./">\n|,
           qq|    <select name="dev" onchange="this.form.submit()">\n|,
    );


    # UPnP MediaServer List
    foreach my $device 
        (sort {$a->getfriendlyname cmp $b->getfriendlyname} @gDeviceList) {
        my $name = $device->getfriendlyname;
        my $udn = $device->getudn;
        my $selected = ($udn eq $dev) ? "selected" : "";

        output(qq|        <option value="$udn" $selected>$name\n|);
    }


    output(
           qq|    </select>\n|,
           qq|    </form></td></tr>\n|,
           qq|</table>\n|,
           qq|</div>\n\n|,
           qq|<br clear="all">\n\n|,
           qq|<div id="leftcol">\n|,
           qq|<table width="170" align="left" border="0">\n|,
           qq|  <tr><td>&nbsp;</td></tr>|,
           qq|  <tr><td><a href="./?dev=$dev"><span class="menu">Home</span></a>|,
    );


    # Back Button
    if ($dir == 0) {
        output(qq|</td></tr>\n|); 

    } else {
        output(
               qq| \| <a href="./?dir=$parentdir&dev=$dev"><span class="menu">Back ($parentname)</span></a></td></tr>\n|,
        );
    }



    # Directory List
    if(@dirlist && ! $gOptions{'hide-dirs'}) {

        output(
               qq|  <tr><td>&nbsp;</td></tr>|,
               qq|  <tr><td><b>Image Directories:</b></td></tr>\n|,
            );

        foreach my $dir (sort {$a->{title} cmp $b->{title}} @dirlist) {
           my($title) = $dir->{'title'};
           my($id) = $dir->{'id'};

           output(qq|  <tr><td>&nbsp;&nbsp;<a href="./?dir=$id&dev=$dev">$title</a><td></tr>\n|);
        }
    }



    output(
           qq|</table>\n|,
           qq|</div>\n\n|,
           qq|<br clear="all"\n\n|,
           qq|<table border=0 bgcolor="#CCCCCC">\n|,
           qq|  <tr><td>\n|,
           qq|    <table border=0 cellpadding=0 cellspacing=0 width="100%">\n|,
           qq|      <tr><td align="center" bgcolor="#AAAAAA"><font size="+1"><b>$dirname</font></b></td></tr>\n|,
           qq|    </table>\n\n|,
          );


    my($w, $h) = split('x', $gOptions{'thumb-size'});

    ### Thumbnail image table
    output(qq|    <table align="center" bgcolor="#CCCCCC" border="1" width="|, ($w + 25 )* $gOptions{'cols'}, qq|">\n|);


    # Thumbs List
    if(@filelist) {
       my($counter) = 0;
       my(@sorted) = (sort {$a->{title} cmp $b->{title}} @filelist);
       my($startIdx) = ($page - 1) * $perpage;
       my($endIdx) = ($page * $perpage < @filelist)? 
           $page * $perpage: scalar @filelist;

       for(my $x = $startIdx; $x < $endIdx; $x++) {
          my $thumburl = getThumbImgResource($sorted[$x])->{url};
#          my $thumburl = $sorted[$x]->{thumburl};
          my $url = getImgResource($sorted[$x])->{url};
#          my $url = $sorted[$x]->{url};
          my $title = $sorted[$x]->{title};
          my $contenttype = $sorted[$x]->{contenttype};

           $title = (length $title >= 12)? 
               substr($title, 0, 12) . "...": $title;

          output("      <tr>\n") if( ($counter % $gOptions{'cols'}) == 0 );

          output(
                 "    ",
                 qq|        <td align="center">|,
                 qq|<a href="./?dir=$dir&dev=$dev&page=$page&image=$url">|,
                 qq|<img src="./?target=$thumburl&dev=$dev" hspace="15" height="$h" width="$w"></A>|, 
                 qq|<br>|,
          );

          output($title) if($gOptions{'show-names'});

          output(
                 qq|</td>\n|, 
                );

          output("      </tr>\n") if( (($counter + 1) % $gOptions{'cols'}) == 0 );

          $counter++;
       } 

    } else {
        output(      qq|<tr><td align="center"><font size="+2"><b>No Images Available</b></font</td></tr>\n|);
    }

    output(qq|    </table>\n\n|,);



    ### Navigation bar table
    output(
           qq|    <table bgcolor="#AAAAAA" cellpadding=0 cellspacing=0 border=0 width="100%">\n|,
           qq|      <tr>\n|
          );

    # previous page
    if($page > 1) {
       my $pagenum = $page - 1;
       output(qq|        <td width=100 align="center"><a href="./?dir=$dir&dev=$dev&page=$pagenum">[previous]</A></td>\n|);

    } else {
       output(qq|        <td width=100>&nbsp;</td>\n|);
    }



    # page indexes
    if(@filelist) { 
       output(
              qq|        <td align="center" valign="bottom">\n|,
              qq|          <form>\n|,
              qq|          <select onChange="document.location='./?dir=$dir&dev=$dev&page=' + this.options[this.selectedIndex].value">\n|
             );
 
       for(my $y = 0; $y <= int((@filelist - 1)/$perpage); $y++) {
          my $pagenum = $y + 1;

          ($pagenum == $page) ?
              output(qq|              <option value="$pagenum" selected>page $pagenum\n|):
              output(qq|              <option value="$pagenum">page $pagenum\n|);
       }

       output(
              qq|          </select><br>\n|,
              qq|          <font size="-1"><i>Total: </i>|, scalar @filelist, qq| images</font>\n|,
              qq|          </form>\n|,
              qq|        </td>\n|
             );
    }
    
    # next page
    if( $page * $perpage < @filelist) {
       my $pagenum = $page + 1; 
       output(qq|        <td width=100 align="center"><a href="./?dir=$dir&dev=$dev&page=$pagenum">[next]</A></TD>\n|);

    } else {
       output(qq|        <td width=100>&nbsp;</td>\n|);
    }


    output(
           "      </tr>\n",
           "    </table>\n",
           "  </td></tr>\n",
           "</table>\n",
           "</center>\n",
	   "</body>\n",
           "</html>\n"
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

    my $image = $in{image};
    my $page = $in{page} || 1;
    my $dir = $in{dir};
    my $dev = uri_unescape($in{dev}) || $gDeviceList[0]->getudn;
    $dev =~ s/\+/ /g;

 
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
              "<html>\n",
              "<head>\n",
              "  <title>Image</title>\n",
              "</head>\n",
              qq|<body bgcolor="#ffffff">\n\n|,
              "<center>\n",
              qq|<table border=1>\n|,
              qq| <tr><td>&nbsp;</td><td align="center"><a href="./?dir=$dir&dev=$dev&page=$page"><b>Image Index</b></a></td><td>&nbsp;</tr>\n|,
#              qq| <TR><TD align="center"><A href="$baseUri?page=$in{'page'}&name=$in{'name'}&rot=|,
#              $in{'rot'} + 270, qq|&scale=$in{'scale'}"><B>270</B></A></TD>|,
#              qq|<TD align="center"><A href="$baseUri?page=$in{'page'}&name=$in{'name'}&rot=$in{'rot'}&scale=|, $in{'scale'} - 25, qq|">-</A> Zoom <A href="$baseUri?page=$in{'page'}&name=$in{'name'}&rot=$in{'rot'}&scale=|, $in{'scale'} + 25, qq|">+</A></TD>|,
#              qq|<TD align="center"><A href="$baseUri?page=$in{'page'}&name=$in{'name'}&rot=|,
#              $in{'rot'} + 90, qq|&scale=$in{'scale'}"><B>90</B></A></TD></TR>\n|,
#              qq| <TR><TD>&nbsp;</TD><TD align="center"><A href="$baseUri?page=$in{'page'}&name=$in{'name'}&rot=|,
#              $in{'rot'} + 180, qq|&scale=$in{'scale'}"><B>180</B></A></TD><TD>&nbsp;</TD></TR>\n|,
              "</table>\n",
              qq|<table border=0 width="100%">\n|,
            );


        output(qq|  <tr><td align="center"><img src="./?target=$image&dev=$dev|);
#        output(qq|rot=$in{'rot'}|) if($in{'rot'});
#        output(qq|&scale=$in{'scale'}|) if($in{'scale'});
        output(qq|" border=0></td></tr>\n|);

    output(
           "</table>\n",
           "</center>\n",
           "</body>\n",
           "</html>\n",
          );
}




# getThumbImgResource
#
#
sub getThumbImgResource {
    my $item = shift;

    return unless $item;

    my @res = sort {$a->{size} <=> $b->{size}} @{$item->{'res'}};

    my %rv = ();
    foreach my $x (keys %{$res[0]}) {
        $rv{$x} = $res[0]->{$x};
    }

    $rv{url} =~ s/disk/albumart/;
    \%rv;
}


# getImgResource
#
#
sub getImgResource {
    my $item = shift;

    return unless $item;

    my @res = sort {$a->{size} <=> $b->{size}} @{$item->{'res'}};
    $res[0];
}



# proxyRequest
#
#
sub proxyRequest {
    my($r) = shift;

    my(%in) = map { my($key, $val) = split('=', $_); $key => $val }                             (split('&', $r->args));
    my $target = $in{target};
    my $dev = $in{dev};

    my($device) = (grep $_->getudn eq $dev, @gDeviceList)[0];
    return undef unless ref $device eq 'Net::UPnP::Device';

    return undef unless $target;

    $device->getlocation =~ m|(http://[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\:[0-9]+)|;
    my $baseurl = $1;
    my $content = get(join('/', $baseurl,$target));

    output($content);
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




# getParentId
#
#
sub getParentId {
    my($r, $dir) = @_;

    my $retval;

    if($dir =~ /\$/) {
        my @tmp = split('\$', $dir);
        pop @tmp;
        $retval = join('$', @tmp);
    } else {
        $retval = 0;
    }

    $retval;
}



# getMetadata
#
#
sub getMetadata {
    my($r, $id, $dev) = @_;

    my($retval);

    my($device) = (grep $_->getudn eq $dev, @gDeviceList)[0];
    return undef unless ref $device eq 'Net::UPnP::Device';

    $retval = upnpGetMetadata($r, $device, $id);

    $retval;
}



# getFileList
#
#
sub getFileList {
    my($r, $dir, $dev) = @_;

    my(@retval) = ();

    my($device) = (grep $_->getudn eq $dev, @gDeviceList)[0];
    return undef unless ref $device eq 'Net::UPnP::Device';

    @retval = upnpGetFileList($r, $device, $dir);

    @retval;
}


# getDirectoryList
#
#
sub getDirectoryList {
    my($r, $dir, $dev) = @_;

    my(@retval) = ();

    my $device = (grep $_->getudn eq $dev, @gDeviceList)[0];
    return undef unless ref $device eq 'Net::UPnP::Device';

    @retval = upnpGetDirectory($r, $device, $dir); 

    @retval;
}



sub output { push(@gOutput, @_); }



1;
