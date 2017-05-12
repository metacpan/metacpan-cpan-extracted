$adaptor_name = 'CSS::Adaptor::Debug';
$expected_output = "NEW RULE\n".
		"--------------------------------------------------\n".
		"SELECTORS:\n\ta\n\n".
		"PROPERTIES:\n\tb:\tc;\n\n".
		"--------------------------------------------------\n\n";

1 if $::adaptor_name;
1 if $::expected_output;

require 't/harness_adaptor';
