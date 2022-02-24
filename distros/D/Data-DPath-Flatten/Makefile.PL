use inc::Module::Install;

# Load things like the name, license, and Perl version from the main module.
# There's no sense duplicating that stuff in this file.
name 'Data-DPath-Flatten';
license 'perl';
all_from 'lib/Data/DPath/Flatten.pm';

# The application needs these modules to work.
requires 'Carp';
requires 'Exporter';

# The unit tests need these modules. The application, however, works fine
# without them.
test_requires 'Pod::Coverage'       => '0.20';
test_requires 'Test::More'          => '0.88';
test_requires 'Test::Pod'           => '1.14';
test_requires 'Test::Pod::Coverage' => '1.04';

# These commands generate the "Makefile".
auto_install;	# Automatically install dependencies from CPAN.
auto_manifest;

WriteAll;
