use strict;
use warnings;
use Devel::CheckOS qw(os_is);

my @args;

use Test::More tests => do {
  my $tests = 40;
  @args = ([]);

  local $ENV{AUTHOR_TESTING} = 1
    if($ENV{AUTOMATED_TESTING} && `tar --version` =~ /gnu/i);

  if($ENV{AUTHOR_TESTING}) {
    $tests *= 2;
    push @args, [use_tar => 'tar'];
  } else {
    print STDERR "no AUTHOR_TESTING, skipping a bunch of tests\n";
  }
  $tests;
};

use CPAN::ParseDistribution;
use File::Find::Rule;
use Config;

foreach my $args (@args) {
  print "# can we read all the different types of file?\n";
  foreach my $archive (File::Find::Rule->file()->name('XML-Tiny-DOM-1.0*')->in('t/gooddists')) {
      SKIP: {
          skip "bzip2 not available", 1 if(
              $archive =~ /(bz2|tbz)$/ &&
              !(grep { -x "$_/bzip2" } split($Config{path_sep}, $ENV{PATH}))
          );
          is_deeply(
              CPAN::ParseDistribution->new($archive, @{$args})->modules(),
              {
                  'XML::Tiny::DOM' => '1.0',
                  'XML::Tiny::DOM::Element' => '1.0'
              },
              "$archive: can read and find module versions"
          );
      }
  }
  
  print "# make sure all the methods work on a good distro\n";
  my $archive = CPAN::ParseDistribution->new('t/gooddists/Class-CanBeA-1.2.tar.gz', @{$args});
  ok($archive->dist() eq 'Class-CanBeA', "Class-CanBeA-1.2.tar.gz: dist() works");
  ok($archive->distversion() eq '1.2', "Class-CanBeA-1.2.tar.gz: distversion() works");
  ok(!$archive->isdevversion(), "Class-CanBeA-1.2.tar.gz: isdevversion() works");
  is_deeply($archive->{modules}, {}, "Class-CanBeA-1.2.tar.gz: \$dist->{modules} isn\'t populated until needed");
  is_deeply(
      $archive->modules(),
      { 'Class::CanBeA' => 1.2 },
      "Class-CanBeA-1.2.tar.gz: modules in /t/ and /inc/ etc are ignored"
  );
  is_deeply(
      $archive->modules(),
      { 'Class::CanBeA' => 1.2 },
      "Class-CanBeA-1.2.tar.gz: calling ...->modules() twice works"
  );
  ok($archive->{_modules_runs} == 1, "Class-CanBeA-1.2.tar.gz: ... but the time-consuming bit is only run once");
  
  $archive = CPAN::ParseDistribution->new('t/gooddists/Class-CanBeA-1.2_1.tar.gz', @{$args});
  ok($archive->isdevversion(), "Class-CanBeA-1.2_1.tar.gz: _ in dist version implies dev release");
  is($archive->distversion(), '1.2_1', "Class-CanBeA-1.2_1.tar.gz: distversion is 1.2_1");
  
  $archive = CPAN::ParseDistribution->new('t/gooddists/Class-CanBeA-1.2.1-TRIAL.tar.gz', @{$args});
  ok($archive->isdevversion(), "Class-CanBeA-1.2.1-TRIAL.tar.gz: -TRIAL in dist version implies dev release");
  is($archive->distversion(), '1.2.1-TRIAL', "Class-CanBeA-1.2.1-TRIAL.tar.gz: distversion is 1.2.1-TRIAL");

  $archive = CPAN::ParseDistribution->new('t/gooddists/common-sense-3.4.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      { 'common::sense' => 3.4 },
      "common-sense-3.4.tar.gz: module is stored as sense.pm.PL"
  );

  
  print "# Pay attention to META.yml ...\n";
  $archive = CPAN::ParseDistribution->new('t/metadists/Devel-Backtrace-0.11.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      {
          'Devel::DollarAt' => '0.02',
          'Devel::Backtrace' => '0.11',
          'Devel::Backtrace::Point' => '0.11'
      },
      'Devel-Backtrace-0.11.tar.gz: META.yml/no_index/directory SCALAR not fatal'
  );
  $archive = CPAN::ParseDistribution->new('t/metadists/Module-Extract-VERSION-0.13.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      { 'Module::Extract::VERSION' => 0.13 },
      'Module-Extract-VERSION-0.13.tar.gz: META.yml/no_index/directory ARRAY'
  );
  $archive = CPAN::ParseDistribution->new('t/metadists/DBD-SQLite-Amalgamation-3.6.1.2.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      { 'DBD::SQLite::Amalgamation' => '3.6.1.2' },
      'DBD-SQLite-Amalgamation-3.6.1.2.tar.gz: META.yml/no_index/file ARRAY'
  );
  $archive = CPAN::ParseDistribution->new('t/metadists/Carp-REPL-0.14.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      { 'Carp::REPL' => '0.14' },
      'Carp-REPL-0.14.tar.gz: META.yml/no_index/package ARRAY'
  );
  $archive = CPAN::ParseDistribution->new('t/metadists/Net-FSP-0.16.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      {
          'Net::FSP::File' =>  undef,
          'Net::FSP::Dir' =>  undef,
          'Net::FSP::Util' =>  undef,
          'Net::FSP' =>  0.16,
          'Net::FSP::Entry' =>  undef
      },
      'Net-FSP-0.16.tar.gz: META.yml/no_index/namespace ARRAY'
  );

  $archive = CPAN::ParseDistribution->new('t/metadists/IPC-Run3-0.044.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      {
          'IPC::Run3' => '0.044',
          'IPC::Run3::ProfPP' => '0.044',
          'IPC::Run3::ProfArrayBuffer' => '0.044',
          'IPC::Run3::ProfLogger' => '0.044',
          'IPC::Run3::ProfReporter' => '0.044',
          'IPC::Run3::ProfLogReader' => '0.044'
      },
      'IPC-Run3-0.044.tar.gz: META.yml/no_index/dir is bogus, ignore'
  );
  $archive = CPAN::ParseDistribution->new('t/metadists/IPC-Run3-0.045.tar.gz', @{$args});
  is_deeply(
      $archive->modules(),
      { 'IPC::Run3' => '0.045' },
      'IPC-Run3-0.045.tar.gz: most files are hidden in this version'
  );

  print "# miscellaneous errors\n";
  $archive = CPAN::ParseDistribution->new('t/dodgydists/Bad-Permissions-123.456.tar.gz', @{$args});
  is_deeply($archive->modules(), { 'Bad::Permissions' => 123.456}, "Bad-Permissions-123.456.tar.gz: bad perms handled OK");
  $archive = CPAN::ParseDistribution->new('t/dodgydists/Bad-UseVars-123.456.tar.gz', @{$args});
  is_deeply($archive->modules(), { 'Bad::UseVars' => 789}, "Bad-UseVars-123.456.tar.gz: 'use vars ...; \$VERSION =' handled OK");
  
  print "# check that package\\nFoo is not indexed\n";
  $archive = CPAN::ParseDistribution->new('t/dodgydists/Bad-SplitPackage-234.567.tar.gz', @{$args});
  is_deeply($archive->modules(), { 'NotSplit' => 234.567 }, 'Bad-SplitPackage-234.567.tar.gz: package\nFoo; is not indexed');
  
  print "# various broken \$VERSIONs\n";
  { local $SIG{__WARN__} = sub {};
    $archive = CPAN::ParseDistribution->new('t/dodgydists/Foo-123.456.tar.gz', @{$args});
    is_deeply($archive->modules(), { 'Foo' => undef }, "Foo-123.456.tar.gz: Broken version == undef");
  
    $archive = CPAN::ParseDistribution->new('t/dodgydists/Bad-Backticks-123.456.tar.gz', @{$args});
    is_deeply($archive->modules(), { 'Bad::Unsafe' => undef }, 'Bad-Backticks-123.456.tar.gz: unsafe `$VERSION` isn\'t executed');
    $archive = CPAN::ParseDistribution->new('t/dodgydists/Bad-UseVersion-123.456.tar.gz', @{$args});
    is_deeply(
        $archive->modules(),
        {
            'Bad::UseVersion'   => '0.0.3',
            'Bad::UseVersionQv' => '0.0.3'
        }, 'Bad-UseVersion-123.456.tar.gz: use version; $VERSION = qv(...) works'
    );
    SKIP: {
        skip "This test crashes on Windows, see the LIMITATIONS section of the doco", 1 if(
            os_is('MicrosoftWindows')
        );
        $archive = CPAN::ParseDistribution->new('t/dodgydists/Acme-BadExample-1.01.tar.gz', @{$args});
        is_deeply(
            $archive->modules(),
            { 'Acme::BadExample' => undef },
            "Acme-BadExample-1.01.tar.gz: doesn't crash :-)"
        );
    }
  }
  
  print "# Check that we ignore obviously silly files\n";
  eval { CPAN::ParseDistribution->new('t/baddists/Foo-123.456.ppm.zip', @{$args}) };
  ok($@ =~ /looks like a ppm/i, "Correctly fail on a PPM");
  eval { CPAN::ParseDistribution->new('t/non-existent-file', @{$args}) };
  ok($@ =~ /doesn't exist/i, "Correctly fail on non-existent file");
  eval { CPAN::ParseDistribution->new('MANIFEST', @{$args}) };
  ok($@ =~ /isn't the right type/i, "Correctly fail on something that isn't an archive");
  eval { CPAN::ParseDistribution->new('t/baddists/perl-5.6.2.tar.gz', @{$args}) };
  ok($@ =~ /Can't index perl itself \(perl-5.6.2\)/, "refuse to index perl*");
  eval { CPAN::ParseDistribution->new('t/baddists/parrot-0.4.13.tar.gz', @{$args}) };
  ok($@ =~ /Can't index perl itself \(parrot-0.4.13\)/, "refuse to index parrot*");
  eval { CPAN::ParseDistribution->new('t/baddists/Perl6-Pugs-6.2.13.tar.gz', @{$args}) };
  ok($@ =~ /Can't index perl itself \(Perl6-Pugs-6.2.13\)/, "refuse to index pugs");
  eval { CPAN::ParseDistribution->new('t/baddists/ponie-2.tar.gz', @{$args}) };
  ok($@ =~ /Can't index perl itself \(ponie-2\)/, "refuse to index ponie*");
  eval { CPAN::ParseDistribution->new('t/baddists/kurila-1.14_0.tar.gz', @{$args}) };
  ok($@ =~ /Can't index perl itself \(kurila-1.14_0\)/, "refuse to index kurila*");
}
