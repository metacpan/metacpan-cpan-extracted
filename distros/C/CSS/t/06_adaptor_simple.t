$adaptor_name = 'CSS::Adaptor';
$expected_output = "a { b: c }\n";

1 if $::adaptor_name;
1 if $::expected_output;

require 't/harness_adaptor';
