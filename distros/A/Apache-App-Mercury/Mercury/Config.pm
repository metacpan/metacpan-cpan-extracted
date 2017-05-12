package Apache::App::Mercury::Config;

require 5.004;
use strict;

# --------------------- USER CUSTOMIZABLE VARIABLES ------------------------

#use constant CONTROLLER_CLASS  => 'Apache::App::Mercury::Controller';
use constant CONTROLLER_CLASS  => '';
use constant USER_MANAGER_CLASS=> 'Apache::App::Mercury::UserManager';
use constant DISPLAY_CLASS     => 'Apache::App::Mercury::Display';

use constant BASE_URL          => "https://www.your.domain.com";
use constant BASE_URI          => "/messaging";
use constant ADMIN_EMAIL       => 'postmaster@your.domain.com';
# Your application's name - displayed in HTML <title>
use constant APPLICATION_NAME  => 'Apache::App::Mercury';

use constant DBI_CONNECT_STR   => "DBI:mysql:database=mercury;host=localhost";
use constant DBI_LOGIN         => "nobody";
use constant DBI_PASS          => "";
use constant DBI_SQL_MSG_TABLE => "messages";
use constant DBI_MSG_ATTACHMENT_TABLE => "message_attachments";

# where to store attachments on filesystem (apache user must have write access)
use constant ATTACHMENT_FILESYS_BASE => "/var/www/html/attachments/";
# attachment base URI: this should be an absolute URI on your virtual host
#  e.g. "/attachments/" for http://www.mydomain.org/attachments/
use constant ATTACHMENT_BASE_URI     => "/attachments/";

# these are only for outgoing auto-forwarded e-mail messages (smtp_send script)
use constant SMTP_SERVER  => "smtp";
use constant SMTP_HELLO   => "your.domain.com";
use constant SMTP_TIMEOUT => 30;   # in seconds
use constant SMTP_DEBUG   => 0;

use constant MIME_NOTIFY_HDR => "Notification from Apache::App::Mercury";
use constant MIME_NOTIFY_MSG => 'This is an automated note to inform you that you have received an Apache::App::Mercury message.  It can be read from:

  '.BASE_URL.BASE_URI;
use constant MIME_FOOTER =>
  '

____________________________________________________________________________
This message has been automatically forwarded to you by Apache::App::Mercury
according to your current user settings.

To discontinue receiving these auto-forwarded e-mail messages, login
and change your mail preferences:

  '.BASE_URL.BASE_URI.'?edit_mail_prefs=1

If you do not have an account at this site, or otherwise believe you have
received this message in error, please send e-mail to
<'.ADMIN_EMAIL.'> with the word "remove" in the subject line.
____________________________________________________________________________
';

# --------------------- END USER CUSTOMIZABLE VARIABLES --------------------


1;
