use ExtUtils::MakeMaker;

my $succeeded = 0;

print "\nChecking for required modules:\n\n";

my %requiredModules = (
    "DBI"          => 0,
    "Net::SSLeay"  => 0,
    "MIME::Base64" => 0,
    "URI::Escape"  => 0,
    "XML::Simple"  => 0,
    "mod_perl2"    => 0,
);

my @moduleNames = sort(keys(%requiredModules));

foreach my $module (@moduleNames)
{
    eval "require $module";
    print "$module is installed... "
        . ($@ ? "no" : "yes") . "\n";

    $succeeded++ unless ($@);
}

unless ($succeeded == scalar(@moduleNames))
{
    print "\nYou must install " . join(", ", @moduleNames) . "\n";
    exit;
}
print "\n";

WriteMakefile(
    'NAME'      => 'Apache2::AuthCAS',
    'VERSION'   => '0.1',
    'PREREQ_PM' => { %requiredModules },
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'ABSTRACT_FROM' => 'lib/Apache2/AuthCAS.pm',
    'AUTHOR'        => 'Jason Hitt <jhitt@illumasys.com>',
);

