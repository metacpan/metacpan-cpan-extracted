<?php
$req =  $_GET[req];

require_once "common.php";

session_start();

function finish_auth() {

    $consumer = getConsumer();

    // Complete the authentication process using the server's
    // response.
    $return_to = getReturnTo();
    $response = $consumer->complete($return_to);

    // Check the response status.
    if ($response->status == Auth_OpenID_CANCEL) {
        // This means the authentication was cancelled.
        $result['msg'] = 'Verification cancelled.';
    } else if ($response->status == Auth_OpenID_FAILURE) {
        // Authentication failed; display the error message.
        $result['msg'] = "OpenID authentication failed: " . $response->message;
    } else if ($response->status == Auth_OpenID_SUCCESS) {
        $ax = new Auth_OpenID_AX_FetchResponse();
        $obj = $ax->fromSuccessResponse($response);
        $email_address = $obj->data['http://axschema.org/contact/email'][0];
        if ($email_address) {
            $result['email'] = $email_address;
        } else {
            $result['msg'] = 'Google email address not found';
        }
    } else {
        $result['msg'] = "Unknown Google OpenID response, '" . $response->status . "'";
    }
    return $result;
}

$result = finish_auth();

if ($result['email']) {

    $atype = 'google';
    $time = time();

    ######################################################################
    # Session cookie
    ######################################################################
    $sid = md5(rand() . $time);
    $c_name   = 'AA_SID';
    $c_value  = $sid;
    $c_expire = 0; // 0 for session cookie
    $c_path = '/';
    $c_domain = '';

    ######################################################################
    # Permanent cookie
    ######################################################################
    $pid = $_COOKIE[AA_PID];

    # add to DB
    $dbPassword = trim(file_get_contents($_SERVER[AUTH_ANY_DB_PW_FILE]));
    $dbUserName = $_SERVER[AUTH_ANY_DB_USER];
    $projectDbName = $_SERVER[AUTH_ANY_DB_NAME];
    $projectDbHost = $_SERVER[AUTH_ANY_DB_HOST];
    $host = $projectDbHost ? $projectDbHost : 'localhost';

    $conection = @mysql_connect($host, $dbUserName, $dbPassword);
    mysql_select_db($projectDbName) or abortSignin( mysql_error() );

    mysql_query('set character set utf8');

    $nowsec = time();
    $psql = "UPDATE userAACookie SET authId = '$result[email]', authProvider = '$atype',
                                    SID = '$sid', state = 'authenticated', last = '$nowsec'
         WHERE PID = '$pid'";

    if (mysql_query($psql)) {
        setcookie($c_name, $c_value, $c_expire, $c_path, $c_domain);

    } else {
        $result[msg] .= mysql_error();
    }
} else {
   if (! $result[msg]) {
       $result[msg] = "Unknown Google authentication error.";
   }
}
if ($result[msg]) {
    abortSignin("$result[msg]");
}

header("Location: $req");

$page = <<<PAGE
<html>
 <body>
  <h1>Cookie setter and redirector</h1>

      <b>you are $result[email]</b><br/>
      Your cookie has been set. Click <a href="$req">here</a> to continue.

        </body>
          </html>
PAGE;

print($page);

?>
