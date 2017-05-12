use Test::More;
eval "use Test::Prereq::Build";
plan skip_all => "Test::Prereq::Build required to test dependencies" if $@;
plan skip_all => '$ENV{TEST_PREREQ} is not set'
	unless(
		((($ENV{USER} || '') eq 'ewilhelm') and (-t STDOUT))
		or exists($ENV{TEST_PREREQ}));
my $name = $0;
($name =~ m#/#) or chdir("../");
prereq_ok();

# vi:syntax=perl:ts=4:sw=4:noet
