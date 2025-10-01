#!/bin/bash
error() {
    echo Fase failed
    exit 1;
}

echo 'Installing CPANTS checker'
cpan Module::CPANTS::Analyse
cpan Path::Tiny
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
    my ($version) = path("lib/Attribute/Validate.pm")->slurp_utf8 =~ /\$VERSION\s+=\s+"(.*?)"/;
    say "version=$version";
    if (path("Changes")->slurp_utf8 !~ /$version/) {
        exit 1;
    }
    say "Version $version Present";
' || error
pod2markdown < lib/Attribute/Validate.pm > README.md || error
# Not adding contribution instructions yet
# pod2markdown < lib/Attribute/Validate/Contributing.pm > CONTRIBUTING.md || error
./Build dist
echo '#### TESTING NOT FINALIZED YET, QUALITY CONTROL NOW ####'

SUCCESS_CPANTS=0;
perl -MModule::CPANTS::Analyse -e '
    use v5.38.2;
    use Path::Tiny;
    use Data::Dumper;

    my ($version) = path("lib/Attribute/Validate.pm")->slurp_utf8 =~ /\$VERSION\s+=\s+"(.*?)"/;
    my $analyzer = Module::CPANTS::Analyse->new({ dist => "Attribute-Validate-v$version.tar.gz" });
    my $results = $analyzer->run->{kwalitee};
    my %failed_results;
    my $failed = 0;
    for my $check (keys %$results) {
        next if $results->{$check};
        $failed = 1;
        say uc "\t### $check failed ###";
    }
    exit 1 if $failed;
    exit 0;
' && SUCCESS_CPANTS=1
if [[ $SUCCESS_CPANTS == 1 ]]; then
    echo '#### YOU CAN SUBMIT, EVERYTHING OK ####';

fi
