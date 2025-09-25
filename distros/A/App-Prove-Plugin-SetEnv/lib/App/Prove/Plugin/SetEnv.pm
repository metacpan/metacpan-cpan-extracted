use strict;
use warnings;

package App::Prove::Plugin::SetEnv;

$App::Prove::Plugin::SetEnv::VERSION = 'v1.0.0'; ## no critic (ProhibitPackageVars)

use String::Expand qw( expand_string );

sub load {
  my ( $class, $p ) = @_;
  foreach my $arg ( @{ $p->{ args } } ) {
    my ( $var, $val ) = split '=', $arg, 2;
    $ENV{ $var } = expand_string( $val, \%ENV ) ## no critic (RequireLocalizedPunctuationVars)
  }
}

1
