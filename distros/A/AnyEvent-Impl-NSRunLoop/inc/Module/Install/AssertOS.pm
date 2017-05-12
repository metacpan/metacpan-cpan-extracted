#line 1
package Module::Install::AssertOS;

use strict;
use warnings;
use base qw(Module::Install::Base);
use File::Spec;
use vars qw($VERSION);

$VERSION = '0.10';

sub assertos {
  my $self = shift;
  my @oses = @_;
  return unless scalar @oses;

  unless ( $Module::Install::AUTHOR ) {
     require Devel::AssertOS;
     Devel::AssertOS->import( @oses );
     return;
  }

  _author_side( @oses );
}

sub _author_side {
  my @oses = @_;

  require Data::Compare;

  foreach my $os (@oses) {
    my $oldinc = { map { $_ => $INC{$_} } keys %INC }; # clone
    eval "use Devel::AssertOS qw($os)";
    if(Data::Compare::Compare(\%INC, $oldinc)) {
        print STDERR "Couldn't find a module for $os\n";
        exit(1);
    }
  }
  my @modulefiles = keys %{{map { $_ => $INC{$_} } grep { /Devel/i && /(Check|Assert)OS/i } keys %INC}};

  mkdir 'inc';
  mkdir 'inc/Devel';
  mkdir 'inc/Devel/AssertOS';
  print "Extra directories created under inc/\n";

  foreach my $modulefile (@modulefiles) {
    my $fullfilename = '';
    SEARCHINC: foreach (@INC) {
        if(-e File::Spec->catfile($_, $modulefile)) {
            $fullfilename = File::Spec->catfile($_, $modulefile);
            last SEARCHINC;
        }
    }
    die("Can't find a file for $modulefile\n") unless(-e $fullfilename);

    (my $module = join('::', split(/\W+/, $modulefile))) =~ s/::pm/.pm/;
    my @dircomponents = ('inc', (split(/::/, $module)));
    my $file = pop @dircomponents;

    mkdir File::Spec->catdir(@dircomponents);
    
    open(PM, $fullfilename) ||
        die("Can't read $fullfilename: $!");
    my $lsep = $/;
    $/ = undef;
    (my $pm = <PM>) =~ s/package Devel::/package #\nDevel::/;
    close(PM);
    $/ = $lsep;
    open(PM, '>'.File::Spec->catfile(@dircomponents, $file)) ||
        die("Can't write ".File::Spec->catfile(@dircomponents, $file).": $!");
    print PM $pm;
    print "Copied $fullfilename to\n       ".File::Spec->catfile(@dircomponents, $file)."\n";
    close(PM);

  }
  return 1;
}

'Assert this';

__END__

#line 139
