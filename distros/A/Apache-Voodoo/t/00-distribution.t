use Test::More;

# Not every module is supposed to be publicly used, so we need to disable the pod 
# converage checks.  There are also optional modules, so we have to conditionally 
# decide which ones to check for compilation in a separate test.
eval {
	require Test::Distribution;
};
plan(skip_all => 'Test::Distribution not installed') if $@;
import Test::Distribution only => ['description','pod'];
