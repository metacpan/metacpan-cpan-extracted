<?php
$account_admin_email = "kgoldov@uw.edu";
require_once "gate-logic.php";
# require_once "../demo/demo-common.php";

$protectnet_auth_url = provider_auth_url('protectnetwork');
$uw_auth_url         = provider_auth_url('uw');
# $google_auth_url     = provider_auth_url('google');
$basic_auth_url      = basic_provider_auth_url('basic');
$ldap_auth_url       = basic_provider_auth_url('ldap');
# $openid_auth_url     = provider_auth_url('openid');

$other_providers = array( 'google', 'openid' );

$other_provider_html = '';

foreach ($other_providers as $provider) {
   $auth_url = provider_auth_url($provider);
   $other_provider_html .= <<<PROV
<div class="gate-provider">
  <button onclick="document.location = '$auth_url'; return false">
    <img style="width: 100px" src="images/$provider.png" alt="$provider"/>
  </button>
</div>

PROV;
}

?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
    <title>AuthAny Login</title>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <link rel="stylesheet" type="text/css" href="gate.css" />
  </head>

  <body id="gateBody">
    <h1>Apache2::AuthAny Example GATE</h1>
    <button style="margin: 5px 0" onclick="document.location='/'">Home</button>

    <?= $error_message ?>

    <p>
      Descriptive text goes here.
    </p>

    <h2>Select the method you would like to use to log in:</h2>
    <div class="gate-providers">    
      <div class="gate-provider">
        <button onclick="document.location = '<?= $protectnet_auth_url ?>'; return false">
          <img src="images/chooser_protect_net.gif" alt="ProtectNetwork">
        </button>
      </div>

      <div class="gate-provider">
        <button onclick="document.location = '<?= $uw_auth_url ?>'; return false">
          <img style="width: 90px" src="images/uw_small.jpg" alt="U of W">
        </button>
      </div>

      <div class="gate-provider">
        <button onclick="document.location = '<?= $basic_auth_url ?>'; return false">
          <span style="font-size: 26px; font-weight: bold;">Basic</span>
        </button>
      </div>

<!--
      <div class="gate-provider">
        <button onclick="document.location = '<?= $ldap_auth_url ?>'; return false">
          <span style="font-size: 26px; font-weight: bold;">LDAP</span>
        </button>
      </div>
-->
      <?= $other_provider_html ?>
    </div>
    <div style="clear: both;"></div>
  </body>
</html>
