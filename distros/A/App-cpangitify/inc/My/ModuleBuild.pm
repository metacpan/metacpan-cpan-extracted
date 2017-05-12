package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use Git::Wrapper;
use Sort::Versions qw( versioncmp );

sub new
{
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  
  if ( versioncmp( Git::Wrapper->new('.')->version, '1.5.0' ) == -1 )
  {
    print "git version 1.5.0 or better is required\n";
    exit 2;
  }
  
  $self;
}

1;
