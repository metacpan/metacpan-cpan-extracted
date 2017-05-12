<pre>
begin results
-----------------
<?php

function compute_in_perl($expression) {
    global $compute_in_perl_result;
    $compute_in_perl_result = "no result";
    $json = json_encode( array(
    	"expr" => $expression,
	"output" => 'compute_in_perl_result'
    ) );
    header("X-compute: $json");
    return $compute_in_perl_result;
}

for ($i=0; $i<=9; $i++) {

    if (isset($_REQUEST["expr" . $i])) {
       $request = $_REQUEST["expr" . $i];
       $result = compute_in_perl($request);

       echo "Input # $i:  $request\n";
       echo "Output# $i:  " . var_export($result, TRUE) . "\n";
       echo "---------------------------------------\n";
    }

}

?>
----------------
end results
</pre>