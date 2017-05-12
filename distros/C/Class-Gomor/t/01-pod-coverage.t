eval "use Test::Pod::Coverage tests => 3";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };

   pod_coverage_ok("Class::Gomor",        $trustparents);
   pod_coverage_ok("Class::Gomor::Array", $trustparents);
   pod_coverage_ok("Class::Gomor::Hash",  $trustparents);
}
