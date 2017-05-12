<?

// Capture output
ob_start();

// Suspend the program and wait for input
// Return the new parameters
function getParsedInput() {
  global $perl;
  $out = ob_get_clean();
  ob_start();
  return $perl->getParsedInput($out);
}

// Set up global perl interpreter connection
$perl = Perl::getInstance();

?>
