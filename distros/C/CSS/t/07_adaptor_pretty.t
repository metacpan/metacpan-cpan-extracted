$adaptor_name = 'CSS::Adaptor::Pretty';
$expected_output = "a {\n\tb:\tc;\n}\n\n";

1 if $::adaptor_name;
1 if $::expected_output;

require 't/harness_adaptor';
