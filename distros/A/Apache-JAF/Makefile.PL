use strict;

$| = 1;

my $modules = [
  [ 'Apache::JAF', 
    [
      ['5.6.0'           => 'Perl 5.6.0 required'],
      ['Apache'          => 'mod_perl is required'],
      ['Apache::Request' => 'libapreq is required'],
      ['Template 2.08'   => 'Framework is based on Template-Toolkit'],
      ['DirHandle'       => 'This module is used for additional handlers loading'],
      ['File::Find'      => 'For compile-time templates loading'],
      ['Data::Dumper'    => 'Used for logging purposes'],
    ],
    [
      ['Time::HiRes' => 'For measuring rquest processing time' ],
      ['DBI 1.20' => 'Used in conjunction with Apache::Session::MySQL'],
      ['Apache::Filter' =>  'JAF is filter-aware'],
      ['Apache::Session::MySQL' => 'Used for transparent session handling'],
    ],
  ],
  [ 'JAF', 
    [
      ['5.6.0' => 'Perl 5.6.0 required'],
    ],
    [
      ['DBI 1.20' => 'most of modern sites are database-driven so you REALLY need this'],
      ['File::Path' => 'used for semi-automatic file uploads'],
      ['File::Basename' => 'used for semi-automatic file uploads'],
    ],
  ],
];

my @ews = (0, 0);
my @ros = qw(required optional);

for my $ro (1..2) {
  foreach my $module (@$modules) {
    print "Checking $ros[$ro-1] modules for $module->[0]...\n";
    foreach my $req (@{$module->[$ro]}) {
      eval 'use ' . $req->[0];
      $req->[0] =~ s/( [\d\.]+)$/ \>\=$1/isg;
      if ($@) {
        $ews[$ro-1]++;
        print +($ro-1 ? 'May be you want' : 'You need'), " the module $req->[0]: ",  $req->[1], "\n";
      } else {
        print ucfirst $ros[$ro-1], ' module ', $req->[0], " ...OK\n";
      }
    }
    print "\n" if @{$module->[$ro]};
  }
}

if ($ews[1]) {
  print "Some of the optional modules are missing. Some features will not work!\n";
  print "You may install it later from CPAN.\n\n";
}

if ($ews[0]) {
  print "Some of the REQUIRED modules are MISSING! Don't make install!!!\n";
  print "You have to install it from CPAN!\n\n";
}

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Apache::JAF',
    'VERSION_FROM'	=> 'lib/Apache/JAF.pm',
    'PREREQ_PM'		=> {
      'Apache' => 0,
      'Apache::Request' => 0,
      'Template' => 2.08,
      'DirHandle' => 0,
      'Data::Dumper' => 0,
    },
    PMLIBDIRS => [ 'lib', 'lib/JAF', 'lib/Apache' ],
);

__END__
