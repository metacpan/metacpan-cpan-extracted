<?php
require_once "../demo-common.php";

$style = <<<STY
<style>
 $style_common
.envVars { background: #FFFFFF; padding: 5px; border: 1px solid; margin: 20px 0 0 10px; 
           width: 350px; font-family: "Courier New", monospace;
         }
.envVars p {font-family: Arial,Helvetica,sans-serif; font-weight: bold; }
.htaccess { padding: 5px; }
.amz { font-weight: bold; color: #E47911 }
</style>
STY;

$script = <<<SCRIPT
<script> 
<!-- 
//
 var milisec=0;
 var timeout;
 var seconds=$_SERVER[AA_TIMEOUT];
 document.counter.d2.value='$_SERVER[AA_TIMEOUT]';

function display(){ 
 if (milisec<=0){ 
     milisec=9;
     seconds-=1;
 } 
 if (seconds<=-1){ 
     milisec=0;
     seconds+=1;
     if (! timeout) {     
//        alert('timeout!');
        var ctr = document.getElementById('counter');
        ctr.innerHTML = '<span style="color: red">No longer authenticated</span>';
        timeout = 1;
     }
 } 
 else 
     milisec-=1;
    document.counter.d2.value=seconds; //+"."+milisec;
    setTimeout("display()",100);
} 
display() 
--> 
</script> 
SCRIPT;

$counter = <<<CTR
<form id="counter" style="margin: 5px 0" name="counter">
  Seconds before timeout: <input type="text" size="8" name="d2">
</form> 
$script
CTR;

preg_match('/(.*demo\/)/', $_SERVER[SCRIPT_FILENAME], $matches);
$demo_dir = $matches[1];

$thisurl = $_SERVER[SCRIPT_NAME];
$thisurl_enc = urlencode($thisurl);
$gate = $_SERVER[AA_GATE] ? $_SERVER[AA_GATE] : "/gate/default-gate.php";

$login = <<<LOGIN
<span class="amz">Hello.</span> <a href="$thisurl?aalogin">Sign in</a> to authenticate. New customer? <a href="/demo">Start here</a>
LOGIN;

$fullname = $_SERVER[AA_IDENT_firstName] || $_SERVER[AA_IDENT_lastName] ? 
         "$_SERVER[AA_IDENT_firstName] $_SERVER[AA_IDENT_lastName]" : $_SERVER[REMOTE_USER];
$full_arr = explode(" ", $fullname);
$first = $full_arr[0];

$logout = <<<LOGOUT
<span class="amz">Hello $first.</span> <a href="$thisurl?aalogout">(not $fullname?)</a>
LOGOUT;

if ($_SERVER[AA_STATE] == 'authenticated') {
    $logout .= "<br style='height:40px'/>" . $counter;
}

if ($_SERVER[AA_STATE]) {
    $ident_block = $_SERVER[REMOTE_USER] ? $logout : $login;
}


// Environment variables
if ($_SERVER[AA_STATE]) {
    $env_vars_base .= "<p>Base Variables</b>";
    $env_vars_base .= "<dt>AA_STATE:</dt><dd>'$_SERVER[AA_STATE]'</dd>";
}
if ($_SERVER[REMOTE_USER]) {
    $env_vars_base .= "<dt>REMOTE_USER:</dt> <dd>'$_SERVER[REMOTE_USER]'</dd>";
    $env_vars_base .= "<dt>AA_USER:</dt>     <dd>'$_SERVER[AA_USER]'</dd>";
    $env_vars_base .= "<dt>AA_PROVIDER:</dt> <dd>'$_SERVER[AA_PROVIDER]'</dd>";
    $env_vars_base .= "<dt>AA_TIMEOUT:</dt>  <dd>'$_SERVER[AA_TIMEOUT]'</dd>";
    $env_vars_base .= "<dt>AA_SESSION:</dt>  <dd>'$_SERVER[AA_SESSION]'</dd>";
}

if ($_SERVER[AA_IDENT_UID]) {
   $env_vars_ident .= '<p>Identity related variables</p>';
   $env_vars_ident .= '<dl>';
   $special_vars = array('UID','username','timeout','active');
   foreach ($special_vars as $special) {
       $vname = "AA_IDENT_$special";
       $env_vars_ident .= "<dt>AA_IDENT_$special:</dt>  <dd>'$_SERVER[$vname]'</dd>";
   }


   $identities_display = preg_replace('/,/', ',<br/>', $_SERVER[AA_IDENTITIES]);
   $env_vars_ident .= "<dt>AA_IDENTITIES:</dt>  <dd>'$identities_display'</dd>";
   $roles_display = preg_replace('/,/', ',<br/>', $_SERVER[AA_ROLES]);
   $env_vars_ident .= "<dt>AA_ROLES:</dt>  <dd>'$roles_display'</dd>";
   $role_choices_display = preg_replace('/,/', ',<br/>', $_SERVER[AA_ROLE_CHOICES]);
   $env_vars_ident .= "<dt>AA_ROLE_CHOICES:</dt>  <dd>'$role_choices_display'</dd>";

   $env_vars_ident .= '<p>Extra identity variables</p>';
   foreach ($_SERVER as $key => $val) {
      if (substr($key, 0, 9) == 'AA_IDENT_') {
          $extra_var = substr($key, 9);
          if (! preg_grep("/$extra_var/", $special_vars)) {
             $env_vars_ident .= "<dt>$key:</dt><dd>'$val'</dd>";
          }
      }
   }

   $env_vars_ident .= '</dl>';
}

function htaccess($dir, $current_p = 0) {
  global $demo_dir;
  global $current_dir;
  $highlight = $current_p ? 'border: 2px solid; background: #FFFFFF;' : 'background: #CCCCCC; border-bottom: 1px solid;';
  $htaccess = file_get_contents("$demo_dir/$dir/.htaccess");
  $block = <<<BLOCK
<div class="htaccess" style="$highlight">
  <h3>$dir</h3>
  <pre>
$htaccess
  </pre>
</div>
BLOCK;

  return $block;
}

$all_htaccess = '';

foreach ($all_demos as $demo) {
    if ($current_dir == $demo) {
        continue;
    }

    $all_htaccess .= htaccess($demo);
}

?>

<html>
  <head>
    <title>hello <?= $current_dir ?></title>
    <?= $style ?>
  </head>
  <body>
<div align="center">
<div align="left" style="background: #CCEEFF; padding: 5px; border: 1px solid #CCAAFF; width: 1024px">
<div class="header">
   <span style="font-size: 50px; font-weight: bold; float: left;">Apache2::AuthAny</span>
   <div style="float: right; padding-right: 20px"><?= $ident_block ?></div>
   <div style="clear: both"></div>
</div>
<div id="tabs">
 <ul>
   <?= $tabs ?>
 </ul>
</div>
<table width="100%" cellpadding="0" cellspacing="0" border="0">
<tr>
  <td>

<h1><?= $current_dir ?></h1>

<?= htaccess($current_dir, 1) ?>

<?= $all_htaccess ?>
</td>
<td valign="top">
  <div class="envVars">
    <dl>
      <?= $env_vars_base ?> 
    </dl>
    <?= $env_vars_ident ?> 
  </div>
</td>
</tr>
</table>
</div>
</div>
</body></html>
