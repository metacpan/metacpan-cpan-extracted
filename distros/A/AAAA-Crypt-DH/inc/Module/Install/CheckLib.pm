#line 1
package Module::Install::CheckLib;

use strict;
use warnings;
use File::Spec;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.12';

sub checklibs {
  my $self = shift;
  return unless scalar @_;
  my %parms = @_;
  unless (_author_side(delete $parms{run_checks_as_author})) {
     require Devel::CheckLib;
     Devel::CheckLib::check_lib_or_exit( %parms );
     return;
  }
}

sub assertlibs {
  my $self = shift;
  return unless scalar @_;
  my %parms = @_;
  unless (_author_side(delete $parms{run_checks_as_author})) {
    require Devel::CheckLib;
    Devel::CheckLib::assert_lib( %parms );
    return;
  }
}

sub _author_side {
  my $run_checks_as_author = shift;
  if ($Module::Install::AUTHOR) {
    mkdir 'inc';
    mkdir 'inc/Devel';
    print "Extra directories created under inc/\n";
    require Devel::CheckLib;
    local $/ = undef;
    open(CHECKLIBPM, $INC{'Devel/CheckLib.pm'}) ||
      die("Can't read $INC{'Devel/CheckLib.pm'}: $!");
    (my $checklibpm = <CHECKLIBPM>) =~ s/package Devel::CheckLib/package #\nDevel::CheckLib/;
    close(CHECKLIBPM);
    open(CHECKLIBPM, '>'.File::Spec->catfile(qw(inc Devel CheckLib.pm))) ||
      die("Can't write inc/Devel/CheckLib.pm: $!");
    print CHECKLIBPM $checklibpm;
    close(CHECKLIBPM);

    print "Copied Devel::CheckLib to inc/ directory\n";
    return !$run_checks_as_author;
  }
  return 0;
}

'All your libs are belong';

__END__

#line 132
