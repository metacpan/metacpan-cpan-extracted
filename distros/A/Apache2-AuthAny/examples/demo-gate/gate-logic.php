<?php
$req    = $_GET['req'];
$reason = $_GET['reason']; // cookie, authz, timeout
$msg    = $_GET['msg'];

# if reason is 'unknown', authProvider and authId should be set
$aType = $_GET['authProvider'];
$aId   = $_GET['authId'];

# if reason is 'authz', username should be set
$username = $_GET[username];

# if denied access to due to roles, $_GET[user_roles] and 
# $_GET[req_roles] should be set
if ($_GET[req_roles]) {
  $msg = "User has roles '$_GET[user_roles]', and must
          have one of '$_GET[req_roles]' to be granted access.";
}

$account_admin_email = 'help@example.com';

$unknownUser = <<<MESSAGE
<h2>Do we know you?</h2>
    You have attempted to access our site using '$aType' authentication.
    The user name provided, '$aId' is not registered with us for 
    '$aType' authentication. If you have been registered using another
    authentication type, please select it below. Otherwise, please send 
    an email request to 
<a href="mailto:$account_admin_email?subject=authProvider:$aType,authId:$aId">
   $account_admin_email
</a>
and we will add you to our '$aType' authentication list within the next
business day. Please add your ID, '$aId' to the subject line.

MESSAGE;

$userUnauthorized = <<<MESSAGE
<h2>Not Authorized</h2>
    You have been denied access. $msg
MESSAGE;

$errorMessages =
   array(
       'logout'  => 'You have been logged out.',
       'cookie'  => 'You must enable cookies in your browser to continue.',
       'timeout' => 'Your session has timed out. Please log in again.',
       'session' => '', # ex. 'Login is required after browser window is closed'
       'unknown' => $unknownUser,
       'authz'   => $userUnauthorized,
       'authen'  => "Could not authenticate. $msg",
       'tech'    => "We are experiencing technical difficulties. $msg",
       'other'   => "$msg",
   );

if ($errorMessages[$reason]) {
    $error_message = <<<REASON
<div class="gate-message">
$errorMessages[$reason]
</div>
REASON;
}

function provider_auth_url ($provider) {
   global $req;
   $encoded_req = urlencode($req);
   $file = $provider == 'google' ? 'redirect.php' : 'redirect';
   return("/aa_auth/$provider/$file?req=$encoded_req");
}

# This function allows basic logout by changing the auth
# url on each new login.
function basic_provider_auth_url ($provider) {
   global $req;
   $encoded_req = urlencode($req);

   # Get logoutKey
   $dbPassword = trim(file_get_contents($_SERVER[AUTH_ANY_DB_PW_FILE]));
   $dbUserName = $_SERVER[AUTH_ANY_DB_USER];
   $projectDbName = $_SERVER[AUTH_ANY_DB_NAME];
   $projectDbHost = $_SERVER[AUTH_ANY_DB_HOST];
   $host = $projectDbHost ? $projectDbHost : 'localhost';

   $conection = @mysql_connect($host, $dbUserName, $dbPassword);
   mysql_select_db($projectDbName) or die (mysql_error());

   $sql = "SELECT logoutKey FROM userAACookie WHERE PID = '$_COOKIE[AA_PID]'";

   mysql_query('set character set utf8');
   $content = mysql_query($sql) or die (mysql_error());
   $rs = mysql_fetch_array($content);
   $logoutKey = $rs['logoutKey'];
   $provider_string = $provider . "_aa-key_" . $logoutKey;
   return("/aa_auth/$provider_string/redirect?req=$encoded_req");
}

?>
