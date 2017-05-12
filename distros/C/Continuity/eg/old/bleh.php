<?

include_once("client.php");

// Signal the end of the initialization by getting input
$params = $perl->getParsedInput();

$count = 0;
while(true) {
  $count++;
  print "Hello from PHP!\n $count";
  $params = getParsedInput();
  print "<pre>Params:\n" . var_export($params, true);
}

?>
