#!/bin/bash
error() {
    echo Fase failed
    exit 1;
}

if [ -z $INTERNET_AVAILABLE ]; then
    INTERNET_AVAILABLE=1;
fi
echo 'CHECKING FOR INTERNET';
ping -c1 8.8.8.8 || INTERNET_AVAILABLE=0
for x in $(find lib -name '*.pm'); do
	if rg $x MANIFEST >/dev/null; then
		echo $x present in manifest
	else
		echo $x is missing in manifest;
	       	error;
	fi
done
for x in $(find t -name '*.t'); do
	if rg $x MANIFEST >/dev/null; then
		echo $x present in manifest
	else
		echo $x is missing in manifest;
	       	error;
	fi
done


if [[ $INTERNET_AVAILABLE == 1 ]]; then
    echo 'Installing CPANTS checker and Path::Tiny'
    cpan Module::CPANTS::Analyse
    cpan Path::Tiny
else
    echo 'WARNING: Skipping internet connection';
fi
echo 'Installing deps current perl';
perl Build.PL || error
echo ./Build installdeps || error
./Build installdeps || error
echo "Testing current perl";
prove || error
perl -e '
    use v5.38.2;
    use Path::Tiny;
    say "Checking version in Changelog";
    my ($version) = path("lib/DBIx/Auto/Migrate.pm")->slurp_utf8 =~ /\$VERSION\s+=\s+"(.*?)"/;
    say "version=$version";
    if (path("Changes")->slurp_utf8 !~ /$version/) {
        exit 1;
    }
    say "Version $version Present";
' || error
pod2markdown < lib/DBIx/Auto/Migrate.pm > README.md || error
# Not adding contribution instructions yet
# pod2markdown < lib/DBIx/Auto/Migrate/Contributing.pm > CONTRIBUTING.md || error
./Build dist
echo '#### TESTING NOT FINALIZED YET, QUALITY CONTROL NOW ####'

SUCCESS_CPANTS=0;
perl -MModule::CPANTS::Analyse -e '
    use v5.38.2;
    use Path::Tiny;
    use Data::Dumper;

    my ($version) = path("lib/DBIx/Auto/Migrate.pm")->slurp_utf8 =~ /\$VERSION\s+=\s+"(.*?)"/;
    my $analyzer = Module::CPANTS::Analyse->new({ dist => "DBIx-Auto-Migrate-$version.tar.gz" });
    my $results = $analyzer->run->{kwalitee};
    my %failed_results;
    my $failed = 0;
    for my $check (keys %$results) {
        next if $results->{$check};
        $failed = 1;
        say uc "\t### $check failed ###";
    }
    if (system "podman run -it --rm -v \$(realpath .):/Library:ro,Z  perl-dbix-auto bash -c \"tar -xf /Library/DBIx-Auto-Migrate-$version.tar.gz; cd DBIx-Auto-Migrate-$version && yes | cpan .\"") {

	    exit 1;
    }
    exit 1 if $failed;
    exit 0;
' && SUCCESS_CPANTS=1
if [[ $SUCCESS_CPANTS == 1 ]]; then
    echo '#### YOU CAN SUBMIT, EVERYTHING OK ####';

fi
