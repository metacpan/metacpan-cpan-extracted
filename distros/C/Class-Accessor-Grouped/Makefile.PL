use strict;
use warnings;
use inc::Module::Install 1.06;

name 'Class-Accessor-Grouped';
license 'perl';
perl_version '5.006';
all_from 'lib/Class/Accessor/Grouped.pm';

requires 'Carp';
requires 'Module::Runtime' => '0.012';
requires 'Scalar::Util';
requires 'MRO::Compat' if $] < 5.009_005;

my $recommends = {
  'Sub::Name' => '0.05',
  # when changing CXSA version don't forget to adjust lib/Class/Accessor/Grouped.pm as well
  'Class::XSAccessor' => '1.19',
};

recommends( $_ => $recommends->{$_} )
  for keys %$recommends;

if (can_xs or $Module::Install::AUTHOR) {
  requires 'Sub::Name' => $recommends->{'Sub::Name'};

  requires 'Class::XSAccessor' => $recommends->{'Class::XSAccessor'}
    if $] > '5.008'; # CXSA does not work on 5.6
}

test_requires 'Test::More' => '0.88';
test_requires 'Test::Exception' => '0.31';

clean_files "Class-Accessor-Grouped-* t/var";

if (-e 'MANIFEST.SKIP') {
  system('pod2text lib/Class/Accessor/Grouped.pm > README');
  realclean_files 'README';
}

auto_install;

resources repository => 'git://git.shadowcat.co.uk/p5sagit/Class-Accessor-Grouped.git';

WriteAll;
if ($Module::Install::AUTHOR) {
  @{Meta->{values}{requires}} = grep
    { $_->[0] !~ /^ (?: Class\:\:XSAccessor | Sub\:\:Name | MRO\:\:Compat ) $/x }
    @{Meta->{values}{requires}}
  ;
  print "Regenerating META with XS requires excluded\n";
  Meta->write;
}
