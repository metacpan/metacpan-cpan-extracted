package CPAN::Maker::Bootstrapper::Role::Provides;

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Find;

use CLI::Simple::Constants qw(:booleans);
use Role::Tiny;

########################################################################
sub cmd_provides {
########################################################################
  my ($self) = @_;

  my @provides;

  find(
    { no_chdir => $TRUE,
      wanted   => sub {
        my $file = $File::Find::name;

        return
          if !-f $file;

        return
          if $file !~ /[.]pm[.]in$/xsm;

        my $module = $file;

        $module =~ s{^lib/}{}xsm;
        $module =~ s{[.]pm[.]in$}{}xsm;
        $module =~ s{/}{::}gxsm;

        push @provides, $module;

        return;
      },
    },
    'lib'
  );

  if (@provides) {
    print {*STDOUT} join( "\n", sort @provides ), "\n";
  }

  return $SUCCESS;
}

1;
