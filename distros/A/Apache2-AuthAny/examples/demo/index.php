<?php
require_once "demo-common.php"; # $style_common, page_template(),
?>

<html>
  <head>
    <title>mod_auth_any Demo</title>
    <style>
        <?= $style_common ?>
        h2 { font-style: italic; }
        .highlight {border: 2px solid; background: #FFFFFF;}
    </style>
  </head>
  <body>

<?php

preg_match('/(.*)\/demo\//', $_SERVER[SCRIPT_FILENAME], $matches);
$current_dir = getcwd();

$current_htaccess = file_get_contents("$current_dir/.htaccess");
  $block = <<<BLOCK
$current_dir/.htaccess
<div class="highlight">
  <pre>
$current_htaccess
  </pre>
</div>
BLOCK;

$main_content = <<<MAIN_CONTENT
<h1>Demo</h1>
<p>
This set of demos is intended to show the basic features of
"Apache2::AuthAny". AuthAny has
an extensible architecture for providing authentication using --any--
authentication mechanism or provider. Each demo includes a PHP file in
a directory protected by a ".htaccess" file containing Apache
directives defined by AuthAny.
</p>

<p>
The .htaccess file in the demo directory supplies directives that will
be in effect for all the demo directories (demo1 - demo8).
</p>

$block

<h2>Identity resolution</h2>
<p>
Apache2::AuthAny (optionally) uses a database table (userIdent) to
resolve the identities provided by the identity providers. Multiple
provider identities can resolve to a single AuthAny identity.
This AuthAny identity can then be used for
authorization purposes.
</p>

<h2>Trial logins</h2>
<p>
To make it possible to show the authentication and authorization
capabilities to anyone coming to this site, several "basic auth" accounts/passwords have been set
up. The password field should be left blank

<ul>
  <li><b>aatest1</b> - This user name is not in the identity table. The access provided will be similar
                       to what you will get if an unknown user (you) logs in with Google or Shibboleth.
  </li>
  <li><b>aatest2</b> - This user name IS in our userIdent and user
                       tables. The user's name and roles are available.
  </li>
  <li><b>aatest3</b> - This user name is linked to the same user as "aatest2".</li> 

  <li><b>aatest4</b> - This user name is similar to "aatest2" and "aatest3", 
                       however it resolves to a different AuthAny identity, with 
                       different roles.
  </li>
</ul>
</p>

<h2>Environment variables</h2>
<p>
  Environment variables are available to the protected application.

<div class="envVars">
  <dl>
    <dt>REMOTE_USER:</dt>
    <dd>
      If the user has successfully authenticated with one of the providers,
      the "REMOTE_USER" variable gets set. If the userId/provider has an entry
      in the userIdent table, "REMOTE_USER" will be set to the username
      value in the user table. Otherwise, it will be set to
      &lt;userId&gt;|&lt;provider&gt;
      <br/>
      <br/>
      "REMOTE_USER" is a standard variable set by all Apache authentication modules.
      Without the identity resolution provided by AuthAny, the protected application
      would need to perform this function. (assuming we wish to consider someone
      logging in with multiple providers as the same person)

    </dd>

    <dt>AA_USER:</dt>
    <dd>
      Set to the identity supplied by the provider.
    </dd>

    <dt>AA_PROVIDER:</dt>
    <dd>
      Set to the provider or authentication mechanisim name.
    </dd>

    <dt>AA_SESSION:</dt>
    <dd>
      Set to 1 if the user has logged in the current browser session. Note,
      Firefox saves session cookies if the user chooses to save tabs when
      closing her browser. When reopening Firefox, AA_SESSION will still
      be set to 1.
    </dd>

    <dt>AA_TIMEOUT:</dt>
    <dd>
      This variable is set if the user's session has not yet timed out. The
      value is the number of seconds that can elapse before the user gets
      timed out.
    </dd>

    <dt>AA_STATE:</dt>
    <dd>
      This value can be one of "logged_out", "recognized", or "authenticated".
      A user who has never logged in, has removed their "AA_PID" cookie, or has
      logged out will be in the "logged_out" state. After signing in, AA_STATE
      will be "authenticated", however if 'AA_TIMEOUT' seconds have elapsed
      since the last time a URL was accessed, the user is timed out, and 
      AA_STATE will change to "recognized".
    </dd>

    <dt>AA_IDENTITIES:</dt>
    <dd>
      An identified user might have more than authId|provider combination
      that they can log in with. This variable is set to a list of all
      the user's identities
    </dd>

    <dt>AA_ROLES:</dt>
    <dd>
      This variable will be set only if the user is identified, and there
      are roles associated with that user in the userRole table.
    </dd>
    
    <p>
      Environment variables beginning with "AA_IDENT_" take their values
      from the "user" table, and are only set if the user is identified.
    </p>

    <dt>AA_IDENT_UID:</dt>
    <dd>
      Set to the primary key in the user table.
    </dd>

    <dt>AA_IDENT_username:</dt>
    <dd>
      Same as REMOTE_USER for identified users.
    </dd>

    <dt>AA_IDENT_active:</dt>
    <dd>
      Users whose "active" value is not "1" are denied access to directories
      protected with any "Require" directive (eg. "Require valid-user")
    </dd>

    <p>
      In addition to the above, the value of any field in the "user" table
      will be passed as AA_IDENT_<field>. The demo database includes "firstName",
      "lastName", and "created".
    </p>

  </dl>
</div>

</p>

<h2>Logout</h2>
<p>
AuthAny provides a logout feature that allows the user to log out without closing her browser.
The feature has two functions. It sets the state in the database to "logged_out". It also logs
the user out of Basic auth and Shibboleth.
Without the second function, a user would simply be able to click again on the GATE's provider
link and get right back into the protected application.

Google authentication is not included in this second logout function, however
Google's login state is set to expire after about a minute, after which the user must
log in again.
</p>

MAIN_CONTENT;
?>


<?= page_template($main_content); ?>
</body></html>
