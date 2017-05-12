package Apache2::FileManager;

=head1 NAME

Apache2::FileManager - Apache2 mod_perl File Manager

=head1 SYNOPSIS

 # Install in mod_perl enabled apache conf file
  <Location /FileManager>
    SetHandler           perl-script
    PerlHandler          Apache2::FileManager
  </Location>

  (Then point your browser to http://www.yourwebsite.com/FileManager)

 # Or call from your own mod_perl script
  use Apache2::FileManager;
  my $obj = Apache2::FileManager->new();
  $obj->print();

 # Or create your own custom MyFileManager subclass

 package MyFileManager;
 use strict;
 use Apache2::FileManager;

 our @ISA = ('Apache2::FileManager');

 sub handler {
   my $r = shift;
   my $obj = __PACKAGE__->new();
   $r->content_type('text/html');
   $r->print ("
    <HTML>
      <HEAD>
        <TITLE>".$r->hostname." File Manager</TITLE>
      </HEAD>
   ");
   $obj->print();
   $r->print("</HTML>");
 }

 # .. overload the methods ..


=head1 DESCRIPTION

The Apache2::FileManager module is a simple HTML file manager.  It provides
file manipulations such as cut, copy, paste, delete, rename, extract archive,
create directory, create file, edit file, and upload files.

Apache2::FileManager also has the ability to rsync the server htdocs tree to
another server with the click of a button.


=head1 PREREQUISITES

The following (non-core) perl modules must be installed before installing
Apache2::FileManager.

 Apache/mod_perl => 2.0
 Archive::Any    => 0.03
 CGI::Cookie     => 1.20
 File::NCopy     => 0.32
 File::Remove    => 0.20

=head1 SPECIAL NOTES

Make sure the web server has read, write, and execute access access to the
directory you want to manage files in. Typically you are going to want to
run the following commands before you begin.

chown -R nobody /web/xyz/htdocs
chmod -R 755 /web/xyz/htdocs

The extract functionality only works with *.tar.gz and *.zip files.

=head1 RSYNC FEATURE

To use the rync functionality you must have ssh, rsync, and the L<File::Rsync>
perl module installed on the development server. You also must have an sshd 
running on the production server.

Make sure you always fully qualify your server names so you don't have 
different values in your known hosts file.

 For Example:
 ssh my-machine                -  wrong
 ssh my-machine.subnet.com     -  right

Note: If the ip address of the production_server changes you will need to
create a new known_hosts file.

To get the rsync feature to work do the following:

 #1 log onto the production server

 #2 become root

 #3 give web server user (typically nobody) a home area
   I made mine /usr/local/apache/nobody
   - production_server> mkdir /usr/local/apache/nobody
   - edit passwd file and set new home area for nobody
   - production_server> mkdir /usr/local/apache/nobody/.ssh

 #4 log onto the development server

 #5 become root

 #6 give web server user (typically nobody) a home area
   - dev_server> mkdir /usr/local/apache/nobody
   - dev_server> chown -R nobody.nobody /usr/local/apache/nobody
   - edit passwd file and set new home area for nobody
   - dev_server> su - nobody
   - dev_server> ssh-keygen -t dsa      (don't use passphrase)
   - dev_server> ssh production_server 
     (will fail but will make known_hosts file)
   - log out from user nobody back to root user
   - dev_server> cd /usr/local/apache/nobody/.ssh
   - dev_server> scp id_dsa.pub production_server:/usr/local/apache/nobody/.ssh/authorized_keys
   - dev_server> chown -R nobody.nobody /usr/local/apache/nobody
   - dev_server> chmod -R 700 /usr/local/apache/nobody

 #7 log back into the production server

 #8 become root

 #9 Do the following commands:
   - production_server> chown -R nobody.nobody /usr/local/apache/nobody
   - production_server> chmod -R 700 /usr/local/apache/nobody

You also need to specify the production server in the development server's
web conf file. So your conf file should look like this:

 <Location /FileManager>
   SetHandler           perl-script
   PerlHandler          Apache2::FileManager
   PerlSetVar           RSYNC_TO   production_server:/web/xyz
 </Location>

If your ssh path is not /usr/bin/ssh or /usr/local/bin/ssh, you also need to
specify the path in the conf file or in the contructor with the directive
SSH_PATH.

You can also specify RSYNC_TO in the constructor:

  my $obj = Apache2::FileManager->new({
    RSYNC_TO => "production_server:/web/xyz"
  });

Also make sure /web/xyz and all files in the tree are readable, writeable, and
executable by nobody on both the production server AND the development server.

=head1 USING DIFFERENT DOCUMENT ROOT

You can specify a different document root as long as the new document root
falls inside of the orginal document root. For example if the document root
of a web server is /web/project/htdocs, you could assign the document root to
also be /web/project/htdocs/newroot. The directory `newroot` must exist.

 # Specify different document root in apache conf file
   <Location /FileManager>
     SetHandler           perl-script
     PerlHandler          Apache2::FileManager
     PerlSetVar           DOCUMENT_ROOT /web/project/htdocs/newroot
   </Location>

 # Or specify different document root in your own mod_perl script
   use Apache2::FileManager;
   my $obj = Apache2::FileManager->new({
     DOCUMENT_ROOT => '/web/project/htdocs/newroot'
   });
   $obj->print();

=head1 SUBCLASSING Apache2::FileManager

 # Create a new file with the following code:

 package MyProject::MyFileManager;
 use strict;
 use Apache2::FileManager;
 our @ISA = ('Apache2::FileManager');

 #Add your own methods here

 1;

The best way to subclass the filemanager would be to copy the methods you want
to overload from the Apache2::FileManager file to your new subclass. Then change
the methods to your liking.

=head1 BUGS

There is a bug in L<File::NCopy> that occurs when trying to paste an empty
directory. The directory is copied but reports back as 0 directories pasted.
The author is in the process of fixing the problem.

=head1 AUTHOR

L<Apache::FileManager> was written by
Philip Collins E<lt>pmc@cpan.orgE<gt>.

L<Apache2::FileManager> was adapted for Apache2 by
David Aguilar E<lt>davvid@cpan.orgE<gt>.

=cut

use strict;
use warnings;
use Apache2::Log ();
use Apache2::Util ();
use Apache2::Const -compile => qw(OK DECLINED);
use Apache2::Request ();
use Apache2::RequestIO ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::ServerUtil ();
use Apache2::Upload;
use IO::File;
use File::NCopy  qw(copy);
use File::Copy   qw(move);
use File::Remove qw(remove);
use File::stat;
use Archive::Any;
use POSIX qw(strftime);
use CGI::Cookie;
#use Data::Dumper;

require 5.005_62;

our $VERSION = '0.20';

sub r { return Apache2::Request->new(Apache2::RequestUtil->request) }

# ---------- Object Constructor -----------------------------------------
sub new {
  my $package = shift;
  my $attribs = shift || {};
  my $o = bless $attribs, $package;
  $o->intialize();
  $o->execute_cmds();
  return $o;
}


# ---- If this was called directly via a perl content handler by apache -------
sub handler {
  my $r = Apache2::Request->new(@_);
  return Apache2::Const::DECLINED if defined r->param('nossi');
  my $package = __PACKAGE__;
  my $obj = $package->new();
  r->content_type('text/html');
  r->print("<HTML><HEAD><TITLE>"
           .r->hostname." File Manager $VERSION</TITLE></HEAD>");
  $obj->print();
  r->print("</HTML>");
  return Apache2::Const::OK;
}


# ---- Call the view ----------------------------------------------
sub print {
  my $o = shift;

  my $view = "view_".$$o{'view'};
  $o->$view();
}


# ------------ Intialize object -----------------------------------------
sub intialize {
  my $o = shift;

  $$o{MESSAGE} = "";
  $$o{JS} = "";
  $$o{EDIT_COLS} ||= 75;
  $$o{EDIT_ROWS} ||= 22;


  # Is this filemanager rsync capable?
  $$o{RSYNC_TO} ||= r->dir_config('RSYNC_TO') || undef;

  #set some defaults (for warnings sake)

  $$o{FILEMANAGER_cmd} = r->param('FILEMANAGER_cmd') || "";
  $$o{FILEMANAGER_arg} = r->param('FILEMANAGER_arg') || "";
  $$o{FILEMANAGER_curr_dir} = r->param('FILEMANAGER_curr_dir') || "";
  $$o{FILEMANAGER_sel_files} => r->param('FILEMANAGER_sel_files') || [];

  #document root
  my $dr = r->document_root;
  $$o{DR} ||= r->dir_config('DOCUMENT_ROOT') || r->document_root;

  #does user defined document root lie inside real doc root?
  if ($$o{DR} !~ /^$dr/) {
    $$o{DR} = r->document_root;
    r->log_error("Warning: Document root changed to $dr.".
                  " Custom document root must lie inside of ".
                  "real document root.");
  }

  #verify current working directory
  $_ = r->param('FILEMANAGER_curr_dir');
  s/\.\.//g; s/^\///; s/\/$//;
  my $curr_dir = $_;

  #set current directory
  if (! chdir $$o{DR}."/$curr_dir") {
    chdir $$o{DR};
    $curr_dir = "";
  }

  $$o{FILEMANAGER_curr_dir} = $curr_dir;

  #set default view method
  $$o{'view'} = "filemanager";

  return undef;
}





###############################################################################
# ----- Views --------------------------------------------------------------- #
###############################################################################

#after upload files - view
sub view_post_upload {
  r->print(q{
      <SCRIPT>
        window.opener.document.FileManager.submit();
        window.opener.focus();
        window.close();
      </SCRIPT>
      });
  return undef;
}


#after rsync transacation - view
sub view_post_rsync {
  my $o = shift;
  r->print(qq{
    <CENTER>
      <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
        <TR><TD>$$o{MESSAGE}</TD></TR>
        <TR>
          <FORM>
            <TD ALIGN=RIGHT>
              <INPUT TYPE=BUTTON VALUE='close'
                      onclick="window.close();">
            </TD>
          </FORM>
        </TR>
      </TABLE>
    </CENTER>
  });
  return undef;
}


sub view_filemanager {
  my $o = shift;

  my ($location, $up_a_href) = $o->html_location_toolbar();
  $up_a_href ||= "";

  my $message = "<I><FONT COLOR=#990000>".$$o{MESSAGE}."</FONT></I>";
  r->print("
    <!-- Scripts -->
    ".$o->html_javascript(r->hostname())."

    <!-- Styles -->
    ".$o->html_style_sheet()."

    <FORM NAME=FileManager ACTION='".r->uri."' METHOD=POST>
    ".$o->html_hidden_fields()."

      <!-- Header -->
      ".$o->html_top()."

      <!-- Special message -->
      $message

      <TABLE CELLPADDING=2 CELLSPACING=2
             BORDER=0 WIDTH=100% BGCOLOR=#606060>
        <TR><TD>".$o->html_cmd_toolbar()."</TD></TR>
        <TR BGCOLOR=WHITE><TD>$location</TD></TR>
        <TR><TD>".$o->html_file_list($up_a_href)."</TD></TR>
      </TABLE>

      <!-- Footer -->
      ".$o->html_bottom()."

    </FORM>
    ");

  return undef;
}


sub view_pre_editfile {
  my $o = shift;

  my $editfile = r->param('FILEMANAGER_editfile');
  my $base = "http://".r->hostname."/$editfile";
  $editfile =~ /([^\/]+)$/;
  my $filename = $1;

  my $fh;
  if (-T $filename && -w $filename) {
    $fh = IO::File->new("< ".$filename);
  }

  my $message = "";
  if ($$o{MESSAGE}) {
    $message =
      "<I><FONT COLOR=#990000>".$$o{MESSAGE}."</FONT></I><BR>";
  }

  if (! $fh) {
    r->print("
      <HTML>
      <HEAD>
      <BODY>
      <CENTER><BR>$message

      <TABLE BORDER=1 CELLPADDING=10 CELLSPACING=0
             BGCOLOR=#606060>
        <TR BGCOLOR=WHITE>
          <TD ALIGN=CENTER>
            could not open file: <I>$base</I> in text writing mode
          </TD>
        </TR>
        <TR BGCOLOR=#efefef>
          <TD ALIGN=RIGHT>
            <FORM>
              <INPUT TYPE=BUTTON VALUE=close
                onclick=\"
                  window.close();
                  return false;\">
            </FORM>
          </TD>
        </TR>
      </TABLE>

      <BR>
      </CENTER>
      </BODY>
      </HTML>");
  }

  else {

    my $data;
    {
      local $/=undef;
      $data = scalar(<$fh>);
    }

    r->print("
    <SCRIPT>
      function show_preview () {
        var f = window.document.FileManagerEditFile;
        var w = window.open('',
                  'FileManagerPreviewEditFile',
                  'scrollbars,resizable,menubar,status,toolbar');
        var d = w.document.open();
        d.write('<HTML><HEAD><BASE HREF=\"$base\"></HEAD>');
        d.write(f.FILEMANAGER_filedata.value);
        d.write('</HTML>');
        d.close();
        w.focus();
      }
      $$o{JS}
    </SCRIPT>

    <!-- Styles -->
    ".$o->html_style_sheet()."

    <FORM NAME=FileManagerEditFile
          ACTION='".r->uri."'
          METHOD=POST>

      ".$o->html_hidden_fields()."

      <INPUT TYPE=HIDDEN NAME=FILEMANAGER_editfile
             VALUE=\"".r->param('FILEMANAGER_editfile')."\">

      <!-- Header -->
      <TABLE WIDTH=100% CELLPADDING=0 CELLSPAING=0>
        <TR>
          <TD>
            <FONT COLOR=#3a3a3a><B>$base</B></FONT>
          </TD>
        </TR>
      </TABLE>

      <!-- Special message -->
      $message

      <TABLE CELLPADDING=2 CELLSPACING=2
             BORDER=0 WIDTH=100% BGCOLOR=#606060>

        <!-- Toolbar -->
        <TR>
          <TD ALIGN=CENTER>
            <TABLE CELLPADDING=0 CELLSPACING=0
                   BORDER=0 WIDTH=90%>
              <TR ALIGN=CENTER>
                <TD ALIGN=CENTER>
                  <INPUT TYPE=BUTTON VALUE='cancel'
                    onclick=\"
                      window.close();
                      return false;\">
                </TD>

                <TD ALIGN=CENTER>
                  <INPUT TYPE=BUTTON VALUE='preview'
                    onclick=\"
                      window.show_preview();
                      return false;\">
                </TD>

                <TD ALIGN=CENTER>
                  <INPUT TYPE=BUTTON VALUE='save'
                    onclick=\"
                      var f = window.document.FileManagerEditFile;
                      f.FILEMANAGER_cmd.value = 'savefiledata';
                      f.submit();
                      return false;\">
                </TD>
              </TR>
            </TABLE>
          </TD>
        </TR>

        <!-- file edit box -->
        <TR>
          <TD ALIGN=CENTER BGCOLOR=#efefef>
          <TEXTAREA NAME=FILEMANAGER_filedata
            COLS=$$o{EDIT_COLS}
            ROWS=$$o{EDIT_ROWS}>$data</TEXTAREA>
          </TD>
        </TR>

        <!-- Toolbar -->
        <TR>
          <TD ALIGN=CENTER>
            <TABLE CELLPADDING=0 CELLSPACING=0
                   BORDER=0 WIDTH=90%>
              <TR ALIGN=CENTER>
                <TD ALIGN=CENTER>
                  <INPUT TYPE=BUTTON VALUE='cancel'
                    onclick=\"
                      window.close();
                      return false;\">
                </TD>

                <TD ALIGN=CENTER>
                  <INPUT TYPE=BUTTON VALUE='preview'
                    onclick=\"
                      window.show_preview();
                      return false;\">
                </TD>

                <TD ALIGN=CENTER>
                  <INPUT TYPE=BUTTON VALUE='save'
                    onclick=\"
                      var f = window.document.FileManagerEditFile;
                      f.FILEMANAGER_cmd.value = 'savefiledata';
                      f.submit();
                      return false;\">
                </TD>
              </TR>
            </TABLE>
          </TD>
        </TR>
      </TABLE>
      <!-- Footer -->
      ".$o->html_bottom()."
    </FORM>
    ");
  }

  return undef;
}





###############################################################################
# ---- HTML Component Output ------------------------------------------------ #
###############################################################################

sub html_javascript {
  my $o = shift;

  my $hostname = r->hostname();
  my $cookie_name = uc($hostname);
  $cookie_name =~ s/[^A-Z]//g;
  $cookie_name .= "_FM";

  #start return literal
  return "
    <NOSCRIPT>
      <H1><FONT COLOR=#990000>please enable javascript</FONT></H1>
    </NOSCRIPT>
    <SCRIPT>
    <!--
    var cookie_name = '$cookie_name';

    function select_all () {
      var f = window.document.FileManager;
      var ck_stat;
      var ar = get_ckbox_array();

      if (ar.length > 0) {
        if (f.FILEMANAGER_last_select_all.value == '1') {
          ck_stat = false;
          f.FILEMANAGER_last_select_all.value = '0';
        } else {
          ck_stat = true;
          f.FILEMANAGER_last_select_all.value = '1';
        }
      }

      for (var i=0; i < ar.length; i++) {
        ar[i].checked = ck_stat;
      }
    }

    function display_help () {
      var w=window.open('', 'help',
                        'resizable=yes,scrollbars=yes,width=650,height=650');
      var d = w.document.open();
      d.write(
        \"<HTML> <UL><B><U><FONT SIZE=+1>Help</FONT></U></B><BR><BR>\"+

        \"<LI><A NAME=upload><B>How do I upload files?</B></A><BR>\"+
        \"Click on the upload menu item. After the <I>Upload Files</I>\"+
        \"window opens, click the <I>Browse</I> button. \"+
        \"This will pop open another window showing files on your computer. \"+
        \"Select a file you want to upload. You can not upload directories. \"+
        \"If you want to upload a directory, archive it first into a \"+
        \"<I>zip</I> file or a tarball. You will then be able to extract \"+
        \"it on the server. You can upload up to 10 files at a time. \"+
        \"After selecting the files you want to upload, click the \"+
        \"<I>upload</I> button to transfer the files from your machine to \"+
        \"the server.<BR><BR>\"+

        \"<LI><A NAME=move><B>How do I copy or move files?</B></A><BR>\"+
        \"First click the check boxes next to the file names that you would \"+
        \"like to copy or paste. Next click the <I>copy</I> or <I>paste</I> \"+
        \"button. Then go to the directory you would like them pasted in. \"+
        \"Finally, click <I>paste</I>.<BR><BR>\"+

        \"<LI><A NAME=move><B>Why does the file manager seem broken in \"+
        \"certain directories or when copying or pasting certain files?\"+
        \"</B></A><BR>\"+
        \"This occurs when the file manager does not have permission to \"+
        \"access these files. To fix the problem, contact your system \"+
        \"administrator and ask them to grant the webserver \"+
        \"READ, WRITE, and EXECUTE access to your files.<BR><BR>\"+

        \"</UL><CENTER>\"+
        \"<FORM><INPUT TYPE=BUTTON VALUE='close' onclick='window.close();'>\"+
        \"</FORM></CENTER></HTML>\");
      d.close();
      w.focus();
    }

    function getexpirydate(nodays){
      var UTCstring;
      Today = new Date();
      nomilli=Date.parse(Today);
      Today.setTime(nomilli+nodays*24*60*60*1000);
      UTCstring = Today.toUTCString();
      return UTCstring;
    }

    function getcookie(cookiename) {
      var cookiestring=''+document.cookie;
      var index1=cookiestring.indexOf(cookiename);
      if (index1==-1 || cookiename=='') return '';
      var index2=cookiestring.indexOf(';',index1);
      if (index2==-1) index2=cookiestring.length;
      escsubstring = cookiestring.substring(index1+cookiename.length+1, index2)
      return unescape(escsubstring);
    }

    function setcookie(name,value,duration){
      cookiestring=name+'='+escape(value)+';EXPIRES='+getexpirydate(duration);
      document.cookie=cookiestring;
      if (!getcookie(name)) {
        return false;
      } else{
        return true;
      }
    }

    function print_upload () {
      var w = window.open('','FileManagerUpload',
                          'scrollbars=yes,resizable=yes,width=500,height=440');
      var d = w.document.open();
      d.write(\"<HTML><BODY><CENTER><H1>Upload Files</H1>\"+
              \"<FORM NAME=UploadForm ACTION='".r->uri."' \"+
              \"      METHOD=POST onsubmit='window.opener.focus();' \"+
              \"      ENCTYPE=multipart/form-data>\"+
              \"  <INPUT TYPE=HIDDEN NAME=FILEMANAGER_curr_dir \"+
              \"         VALUE='".r->param('FILEMANAGER_curr_dir')."'>\");

      for (var i=1; i <= 10; i++) {
        d.write(\"<INPUT TYPE=FILE SIZE=40 NAME=FILEMANAGER_file\"+i+\"><BR>\");
      }
      d.write(\"<INPUT TYPE=BUTTON VALUE='cancel' onclick='window.close();'>\"+
              \"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\"+
              \"<INPUT TYPE=SUBMIT NAME=FILEMANAGER_cmd\"+
              \"       VALUE=upload></CENTER></BODY></HTML>\");
      d.close();
      w.focus();
    }

    // make input check box form elements into an array ALL the time
    function get_ckbox_array() {
      var ar;
      sel_files = window.document.FileManager.FILEMANAGER_sel_files;

      // no files
      if (sel_files == null) {
        ar = new Array();
      }

      // 1 file (no length)
      else if (sel_files.length == null) {
        ar = [ sel_files ];
      }

      // more than one file
      else {
        ar = sel_files;
      }
      return ar;
    }


    // make array of check box objects that are selected
    function get_sel_ckbox_array() {
      var sel_ar = new Array();
      var ar = window.get_ckbox_array();

      for (var i=0; i < ar.length; i++) {
        if (ar[i].checked == true) {
          sel_ar.push(ar[i]);
        }
      }

      return sel_ar;
    }




    // get the number checked
    function get_num_checked() {
      var sel_ar = get_sel_ckbox_array();
      return sel_ar.length;
    }

    //function to edit file
    function edit_file () {
      var sel_ar = get_sel_ckbox_array();

      //make sure there is 1 and only 1 selected file
      if (sel_ar.length != 1) {
        window.alert('Please select ONE file to edit by clicking on a '+
                     'check box with the mouse.');
      }

      else {
        var f= window.document.FileManager;
        var cd = escape(f.FILEMANAGER_curr_dir.value);
        var editfile = escape(sel_ar[0].value);
        var w = window.open('".r->uri."?FILEMANAGER_cmd=editfile".
                                      "&FILEMANAGER_curr_dir='+cd+'".
                                      "&FILEMANAGER_editfile='+editfile,
                            'FileManagerEditFile',
                            'scrollbars,resizable');
        sel_ar[0].checked = false;
        w.focus();
      }
    }

    // make cookie for checked filenames
    function save_names (type) {
      var cb = get_sel_ckbox_array();
      var ac = '';
      for (var i=0; i < cb.length; i++) {
        ac = ac + cb[i].value + '|';
        cb[i].checked = false;
      }
      if (ac == '') {
        window.alert('Please select file(s) by clicking on the '+
                     'check boxes with the mouse.');
      } else {
        ac = ac + type;
        window.setcookie(cookie_name,ac,1);
      }
    }

    //test if browser cookies are enabled
    if (! window.document.cookie ) {
      window.setcookie(cookie_name,'test',1);
      if (! window.document.cookie) {
          document.write('<H1><FONT COLOR=#990000>'+
                          'please enable cookies</FONT></H1>');
      }
      window.setcookie(cookie_name,'',-1);
    }
    $$o{JS}
    --></SCRIPT> "; #end return literal
}


sub html_style_sheet {
  return "
    <STYLE TYPE='text/css'>
      <!--
        BODY {
          background-color: white;
          font-family: serif;
          margin-top: 0;
          margin-right: 0;
          margin-bottom: 0;
          margin-left: 0;
          padding-top: 0;
          padding-bottom: 0;
          padding-right: 1;
          padding-left: 1;
          border-top: 0;
          border-bottom: 0;
          border-right: 0;
          border-left: 0;
          border-style: 0;
        }

        A:link {
          color: #990000;
          text-decoration: none;
        }

        A:visited {
          color: #990000;
          text-decoration: none;
        }

        A:hover {
          color: #990000;
          text-decoration: underline;
        }
    --> </STYLE>";
}


sub html_hidden_fields {
  return "
    <INPUT TYPE=HIDDEN NAME=FILEMANAGER_curr_dir
           VALUE='".r->param('FILEMANAGER_curr_dir')."'>
    <INPUT TYPE=HIDDEN NAME=FILEMANAGER_cmd VALUE=''>
    <INPUT TYPE=HIDDEN NAME=FILEMANAGER_arg VALUE=''>
    <INPUT TYPE=HIDDEN NAME=FILEMANAGER_last_select_all
           VALUE='".r->param('FILEMANAGER_last_select_all')."'>
    ";
}


sub html_location_toolbar {
  my $o = shift;

  my @loc = split /\//, r->param('FILEMANAGER_curr_dir');

  #already in base directory?
  return "<B>location: / </B>" if ($#loc == -1);

  #for all elements in the loc except the last one
  my @ac;
  my $up_a_href = "
    <A HREF=#
      onclick=\"
        var f=window.document.FileManager;
        f.FILEMANAGER_curr_dir.value='';
        f.submit();
        return false;\">
      <FONT COLOR=#006699 SIZE=+1><B>..</B></FONT></A>
      &nbsp;
    ";

  for (my $i = 0; $i < $#loc; $i++) {
    push @ac, $loc[$i];
    my $url = join("/", @ac);

    $loc[$i] = "
      <A HREF=#
        onclick=\"
          var f=window.document.FileManager;
          f.FILEMANAGER_curr_dir.value='$url';
          f.submit();
          return false;\">
        <FONT COLOR=#006699 SIZE=+1><B>".$loc[$i]."</B></FONT></A>
      ";

    if ($i == ($#loc - 1)) {
      $up_a_href = "
        <A HREF=#
          onclick=\"
            var f=window.document.FileManager;
            f.FILEMANAGER_curr_dir.value='$url';
            f.submit();
            return false;\">
          <FONT COLOR=#006699 SIZE=+1><B>..</B></FONT></A>
        &nbsp;
        ";
    }
  }

  $loc[$#loc] = "<FONT SIZE=+1><B>".$loc[$#loc]."</B></FONT>";

  my $location = "
    <B>location: </B>
    <A HREF=#
      onclick=\"
        var f=window.document.FileManager;
        f.FILEMANAGER_curr_dir.value='';
        f.submit();
        return false;\">
      <FONT COLOR=#006699 SIZE=+1><B>/</B></FONT></A>
    &nbsp;
    ".join("&nbsp;<FONT SIZE=+1><B>/</B></FONT>&nbsp;", @loc);

  return ($location, $up_a_href);
}


sub html_cmd_toolbar {
  my $o = shift;

  my @cmds = (

    #Refresh
    "<A HREF=# onclick=\"
        var f=window.document.FileManager;
        f.submit();
        return false;\"
        ><FONT COLOR=WHITE><B>refresh</B></FONT></A>",

    #Edit
    "<A HREF=# onclick=\"
        window.edit_file(); return false;\"
        ><FONT COLOR=WHITE><B>edit</B></FONT></A>",

    #Cut
    "<A HREF=# onclick=\"
        window.save_names('cut'); return false;\"
        ><FONT COLOR=WHITE><B>cut</B></FONT></A>",

    #Copy
    "<A HREF=# onclick=\"
        window.save_names('copy'); return false;\"
        ><FONT COLOR=WHITE><B>copy</B></FONT></A>",

    #Paste
    "<A HREF=# onclick=\"
        if (window.getcookie(cookie_name) != '') {
          var f=window.document.FileManager;
          f.FILEMANAGER_cmd.value='paste'; f.submit();
        } else {
          window.alert('Please select file(s) to paste by checking '+
                       'the file(s) first and clicking copy or cut.');
        }
        return false;\"
        ><FONT COLOR=WHITE><B>paste</B></FONT></A>",

    #Delete
    "<A HREF=# onclick=\"
      var f=window.document.FileManager;
      if (get_num_checked() == 0) {
        window.alert('Please select a file to delete by clicking'+
                     ' on a check box with the mouse.');
        } else {
          var msg = '\\n                 Are you sure?\\n' +
                    '\\n' + 'Click OK to delete selected ' +
                    'files & directories\\n' +
                    '   ***including*** files in those directories';

          if (window.confirm(msg)) {
            f.FILEMANAGER_cmd.value='delete'; f.submit();
          }
        }
        return false; \"
        ><FONT COLOR=WHITE><B>delete</B></FONT></A>",

    #Rename
    "<A HREF=# onclick=\"
        var f=window.document.FileManager;
        if (get_num_checked() != 1) {
          window.alert('Please select ONE file to rename by clicking on a '+
                       'check box with the mouse.');
        } else {
          var rv=window.prompt('enter new name','');
          if ((rv != null) && (rv != '')) {
            f.FILEMANAGER_cmd.value='rename';
            f.FILEMANAGER_arg.value=rv;
            f.submit();
          }
        }
        return false;\"
        ><FONT COLOR=WHITE><B>rename</B></FONT></A>",

    #Extract
    "<A HREF=# onclick=\"
        var f=window.document.FileManager;
        if (get_num_checked() == 0) {
          window.alert('Please select a file to extract by clicking on a '+
                       'check box with the mouse.');
        } else {
          f.FILEMANAGER_cmd.value='extract';
          f.submit();
        }
        return false;\"
        ><FONT COLOR=WHITE><B>extract</B></FONT></A>",

    #New File
    "<A HREF=# onclick=\"
        var f=window.document.FileManager;
        var rv = window.prompt('new file name','');
        var cd = f.FILEMANAGER_curr_dir.value;
        if (cd != '') {
          rv = cd+'/'+rv;
        }
        if ((rv != null) && (rv != '')) {
          var w = window.open('".r->uri."?FILEMANAGER_cmd=editfile".
                                        "&FILEMANAGER_curr_dir='+escape(cd)+'".
                                        "&FILEMANAGER_editfile='+escape(rv),
                              'FileManagerEditFile',
                              'scrollbars,resizable');
          w.focus();

        } else if (rv == '') {
          window.alert('can not create blank file names');
        }
        return false; \">
        <FONT COLOR=WHITE><B>new file</B></FONT></A>",

    #New Directory
    "<A HREF=# onclick=\"
        var f=window.document.FileManager;
        var rv=window.prompt('new directory name','');
        if ((rv != null) && (rv != '')) {
          f.FILEMANAGER_arg.value=rv;
          f.FILEMANAGER_cmd.value='mkdir';
          f.submit();

        } else if (rv == '') {
          window.alert('can not create blank directory names');
        }
        return false;\"
        ><FONT COLOR=WHITE><B>new directory</B></FONT></A>",

    #Upload
    "<A HREF=# onclick=\"
        window.print_upload();
        return false;\"
        ><FONT COLOR=WHITE><B>upload<B></FONT></A>"
  );

  #Rsync
  my $rsync = "";
  if ($$o{'RSYNC_TO'}) {
    push @cmds,
      "<TD><A HREF=# onclick=\"
          if (window.confirm('Are you sure you want to synchronize with ".
              "the production server?')) {
            var w=window.open('','RSYNC',
                              'scrollbars=yes,resizables=yes,width=400,height=500');
            w.focus();
            var d=w.document.open();
            d.write('<HTML><BODY><BR><BR><BR>".
                    "<CENTER>Please wait synchronizing production server.".
                    "<BR>This could take several minutes.".
                    "</CENTER></BODY></HTML>');
            d.close();
            w.location.replace('".r->uri."?FILEMANAGER_cmd=rsync',
                               'RSYNC',
                               'scrollbars=yes,resizables=yes,width=400,height=500');
          } return false;\"
          ><FONT COLOR=WHITE><B>synchronize</B></FONT></A>";
  }

  return "
    <!-- Actions Tool bar -->
    <TABLE CELLPADDING=0 CELLSPACING=0
           BORDER=0>
      <TR ALIGN=CENTER>
        <TD ALIGN=CENTER>"
    .join("</TD><TD>&nbsp;<B><FONT COLOR=#bcbcbc SIZE=+2>|</FONT>&nbsp;</B>"
         ."</TD><TD>",
         @cmds)
    ."</TD></TR></TABLE>";
}


sub html_file_list {
  my $o = shift;
  my $up_a_href = shift || "";

  my $bgcolor = "efefef";

  #get the list in this directory
  my $curr_dir = "";
  $curr_dir = r->param('FILEMANAGER_curr_dir')."/"
    if (r->param('FILEMANAGER_curr_dir') ne "");

  #if there is a value for the ".." directory, then add a row for that link
  #at the *top* of the list
  my $acum = "";
  if ($up_a_href ne "") {
    $acum = "
        <TR BGCOLOR=#$bgcolor>
        <TD>&nbsp;</TD>
        <TD>$up_a_href</TD>
        <TD ALIGN=CENTER>--</TD>
        <TD ALIGN=CENTER>--</TD>
        </TR>";
    $bgcolor = "ffffff";
  }

  my $ct_rows = 0;

  foreach my $file (sort <*>) {

    my ($link,$last_modified,$size,$type);
    $ct_rows++;

    #if directory?
    if (-d $file) {
      $last_modified = "--";
      $size = "<TD ALIGN=CENTER>--</TD>";
      $type = "/"; # "/" designates "directory"
      $link = "<A HREF=#
                onclick=\"
                  var f=window.document.FileManager;
                  f.FILEMANAGER_curr_dir.value='"
                      .Apache2::Util::escape_path($curr_dir.$file, r->pool)."';
                  f.submit();
                  return false;\">
                <FONT COLOR=#006699>$file$type</FONT></A>";
    }

    #must be a file
    elsif (-f $file) {

      #get file size
      my $stat = stat($file);
      $size = $stat->size;
      if ($size > 1024000) {
        $size = sprintf("%0.2f",$size/1024000) . " <I>M</I>";
      } elsif ($stat->size > 1024) {
        $size = sprintf("%0.2f",$size/1024). " <I>K</I>";
      } else {
        $size = sprintf("%.2f",$size). " <I>b</I>";
      }
      $size =~ s/\.0{1,2}//;
      $size = "<TD NOWRAP ALIGN=RIGHT>$size</TD>";

      #get last modified
      $last_modified = $o->formated_date($stat->mtime);

      #get file type
      if (-S $file) {
        $type = "="; # "=" designates "socket"
      }
      elsif (-l $file) {
        $type = "@"; # "@" designates "link"
      }
      elsif (-x $file) {
        $type = "*"; # "*" designates "executable"
      }

      my $true_doc_root = r->document_root;
      my $fake_doc_root = $$o{DR};
      $fake_doc_root =~ s/^$true_doc_root//;
      $fake_doc_root =~ s/^\///; $fake_doc_root =~ s/\/$//;

      my $href = $curr_dir;
      $href = $fake_doc_root."/".$href if $fake_doc_root;

      $link = "
          <A HREF=\"/$href"."$file?nossi=1\"
             TARGET=_blank><FONT COLOR=BLACK>"
             .Apache2::Util::escape_path($file.$type, r->pool).
            "</FONT>
          </A>";
    }

    $acum .= "
        <TR BGCOLOR=#$bgcolor>
        <TD><INPUT TYPE=CHECKBOX NAME=FILEMANAGER_sel_files
                   VALUE='$curr_dir"."$file'></TD>
        <TD>$link</TD>
        <TD ALIGN=CENTER NOWRAP>$last_modified</TD>
        $size
        </TR>";

    #alternate bgcolor so it is easier to read
    $bgcolor = ( ($bgcolor eq "ffffff") ? "efefef" : "ffffff" );
  }

  #print a message if there were no files in this directory
  if ($ct_rows == 0) {
    $acum .= "
        <TR ALIGN=CENTER><TD COLSPAN=3>
          <TABLE BORDER=1 WIDTH=100% BGCOLOR=WHITE>
            <TR>
              <TD ALIGN=CENTER><BR><I>no files found</I><BR><BR></TD>
            </TR>
          </TABLE>
        </TD>
      </TR>";
  }

  return "
      <!-- Files list -->
      <TABLE CELLPADDING=3 CELLSPACING=0 WIDTH=100% BORDER=0>

      <!-- Headers -->
      <TR BGCOLOR=#606060>
        <TD WIDTH=1% ALIGN=CENTER>
          <A HREF=# onclick=\"
              window.select_all();
              return false;\"
          ><FONT COLOR=WHITE>+</FONT> </A>
        </TD>
        <TD WIDTH=80%>
            <FONT COLOR=WHITE><B>filename</B></FONT>
        </TD>
        <TD WIDTH=15% ALIGN=CENTER NOWRAP>
            <FONT COLOR=WHITE><B>last modified</B></FONT>
        </TD>
        <TD WIDTH=4% ALIGN=CENTER>
            <FONT COLOR=WHITE><B>size</B></FONT>
        </TD>
      </TR>

      <! -- Files -->
      $acum
      </TD></TR></TABLE>";
}


sub html_top {
  return "
      <TABLE WIDTH=100% CELLPADDING=0 CELLSPAING=0>
        <TR>
          <TD>
            <FONT SIZE=+2 COLOR=#3a3a3a>
              <B>".r->hostname." - file manager</B></FONT>
          </TD>
          <TD ALIGN=RIGHT VALIGN=TOP>
            <A HREF=# onclick=\"
              window.display_help();
              return false;\"
              ><FONT COLOR=#3a3a3a>help</FONT></A>
          </TD>
        </TR>
      </TABLE>
      ";
}


sub html_bottom {
  return "
      <TABLE WIDTH=100% CELLPADDING=0 CELLSPAING=0><TR>
      <TD ALIGN=RIGHT VALIGN=TOP>
          <A HREF=http://www.cpan.org/modules/by-module/Apache/PMC
             TARGET=CPAN
          ><FONT SIZE=-1 COLOR=BLACK>Apache2-FileManager-$VERSION</FONT></A>
      </TD>
      </TR>
      </TABLE>";
}





##############################################################################
# -------------- Utility Methods ------------------------------------------- #
##############################################################################

sub execute_cmds {
  my $o = shift;
  my $cmd = r->param('FILEMANAGER_cmd');
  my $arg = r->param('FILEMANAGER_arg');
  my $method = "cmd_$cmd";
  if ($o->can($method)) {
    $o->$method($arg);
  }
}


sub get_selected_files {
  my @sel_files = r->param('FILEMANAGER_sel_files');
  return \@sel_files;
}


sub filename_esc {
  #escape spaces in filename
  my $o = shift;
  my $f = shift;
  $f =~ s/\ /\\\ /g;
  return $f;
}


sub formated_date {
  my $o = shift;
  my $date = shift || time;
  return strftime "%D %l:%M %P", localtime($date);
}


sub get_clip_board {
  my $o = shift;

  #get copy and cut file arrays
  my $buffer_type = "";
  my $buffer_filenames = [];

  if (defined(r->headers_in->{'Cookie'})) {
    my $cookie_name = uc(r->hostname());
    $cookie_name =~ s/[^A-Z]//g;
    $cookie_name .= "_FM";
    my %cookies = CGI::Cookie->parse(r->headers_in->{'Cookie'});
    if (exists $cookies{$cookie_name}) {
      my $data = $cookies{$cookie_name}->value;
      my @ar = split /\|/, $data;

      #is there something in buffer
      if ($#ar > 0) {
        $buffer_type      = pop @ar;
        $buffer_filenames = \@ar;
      }
    }
  }
  return ($buffer_type, $buffer_filenames);
}





###############################################################################
# -- Commands (called via form input from method execute_cmds or manually) -- #
###############################################################################

sub cmd_savefiledata {
  my $o = shift;

  my $base = r->param('FILEMANAGER_editfile');
  $base =~ /([^\/]+)$/;
  my $filename = $1;
  remove $filename;
  my $fh = IO::File->new("> ".$filename);
  print $fh scalar(r->param('FILEMANAGER_filedata'));
  $$o{MESSAGE} = "file saved";
  $$o{view} = "pre_editfile";
  return undef;
}


sub cmd_editfile {
  my $o = shift;

  my $base = r->param('FILEMANAGER_editfile');
  $base =~ /([^\/]+)$/;
  my $filename = $1;

  if (! -e $filename) {
    my $fh = IO::File->new("> ".$filename);
    if ($fh) {
      $$o{JS} .= "
        if (window.opener && window.opener.document.FileManager) {
          window.opener.document.FileManager.submit();
        }";
    }
  }
  $$o{view} = "pre_editfile";
}


sub cmd_paste {
  my $o = shift;
  my $arg1 = shift;
  my ($buffer_type, $files) = $o->get_clip_board();

  my $count = 0;

  if ($buffer_type eq "copy") {
    my @files = map { $o->filename_esc($$o{DR}."/".$_) } @{ $files };
    $count = copy \1, @files, ".";
  } elsif ($buffer_type eq "cut") {
    for (@{ $files }) {
      my $file = $$o{DR}."/".$_;
      if (-d $file) {
        my $file = $o->filename_esc($file);
        my $tmp = copy \1, $file, ".";
        if ($tmp) {
          remove \1, $file and $count++;
        }
      } elsif (-f $file) {
        move($file, ".") and $count++;
      }
    }
  }

  if ($count == 0) {
    $$o{MESSAGE} = "0 files and directories pasted";
  } elsif ($count == 1) {
    $$o{MESSAGE} = "1 file or directory pasted";
  } else { 
    $$o{MESSAGE} = "$count files or directories pasted";
  }
  $$o{JS} = "window.setcookie(cookie_name,'',-1);";
  return undef;
}


sub cmd_delete {
  my $o = shift;
  my $arg1 = shift;
  my $sel_files = $o->get_selected_files();
  my @files = map { $o->filename_esc($$o{DR}."/".$_) } @{ $sel_files };
  my $count = remove \1, @files;
  if ($count == 0) {
    $$o{MESSAGE} = "0 files and directories deleted";
  } elsif ($count == 1) {
    $$o{MESSAGE} = "1 file or directory deleted";
  } else {
    $$o{MESSAGE} = "$count files or directories deleted";
  }
  return undef;
}


sub cmd_extract {
  my $o = shift;
  my $arg1 = shift;
  my $sel_files = $o->get_selected_files();
  foreach my $f (@{ $sel_files }) {
    my $esc = $o->filename_esc($$o{DR}."/".$f);
    my $archive = Archive::Any->new($esc);
    $archive->extract if defined $archive;
    $$o{MESSAGE} = "Files extracted.";
  }
  return undef;
}


sub cmd_upload {
  my $o = shift;
  my $arg1 = shift;
  my $count = 0;

  foreach my $i (1 .. 10) {
    my @ar = split /\/|\\/, r->param("FILEMANAGER_file$i");
    next if ($#ar == -1);
    my $filename = pop @ar;
    $filename =~ s/[^\w\ \d\.\-]//g;
    next if ($filename eq "");

    $count++;

    my $up = r->upload("FILEMANAGER_file$i");
    #next if not defined $up;

    #my $in_fh = $up->fh;
    #next if !defined $in_fh;

    my $path = $$o{DR}."/".r->param('FILEMANAGER_curr_dir')."/".$filename;
    $up->link($path);

    #my $arg = "> ".$$o{DR}."/".r->param('FILEMANAGER_curr_dir')."/".$filename;
    #my $out_fh;
    #open($out_fh, $arg)
    #  or die "ERROR: cannot open '$arg'";

    #next if not defined $out_fh;

    #while (<$in_fh>) {
    #  print $out_fh $_;
    #}
    #close($out_fh);

  }
  #$$o{MESSAGE} = "$count file(s) uploaded.";
  $$o{'view'} = "post_upload";
  return undef;
}


sub cmd_rename {
  my $o = shift;
  my $arg1 = shift;
  my $sel_files = $o->get_selected_files();
  my $file = $$o{DR}."/".$sel_files->[0];
  my $bool = move($file, $arg1);
  if ($bool) {
    $$o{MESSAGE} = "File renamed.";
  } else {
    $$o{MESSAGE} = "File could not be renamed.";
  }
  return undef;
}


sub cmd_rsync {
  my $o = shift;
  my $arg1 = shift;
  $$o{'SSH_PATH'} ||= r->dir_config('SSH_PATH');

  #try some default paths for ssh if we can't find ssh
  for (qw(/usr/bin/ssh /usr/local/bin/ssh)) {
    last if $$o{'SSH_PATH'};
    $$o{'SSH_PATH'} = $_ if (-f $_);
  }

  eval "require File::Rsync";
  if ($@) {
    r->log_error($@);
    $$o{MESSAGE} = "Module File::Rsync not installed.";
  } else {
    my $obj = File::Rsync->new( {
      'archive'    => 1,
      'compress'   => 1,
      'rsh'        => $$o{'SSH_PATH'},
      'delete'     => 1,
      'stats'      => 1
    } );

    $obj->exec( { src  => r->document_root(),
                  dest => $$o{'RSYNC_TO'}    } )
      or warn "rsync failed\n";
    $$o{MESSAGE} = join("<BR>", @{ $obj->out }) if ($obj->out);
    $$o{MESSAGE} = join("<BR>", @{ $obj->err }) if ($obj->err);
  }
  $$o{'view'} = "post_upload";
  return undef;
}


sub cmd_mkdir {
  my $o = shift;
  my $arg1 = shift;
  my $bool = mkdir $arg1;
  if ($bool) {
    $$o{MESSAGE} = "New directory added.";
  } else {
    $$o{MESSAGE} = "Could not make directory.";
  }
  return undef;
}


"righty-o";
