package Dancer::SearchApp::Defaults;
use strict;
use Exporter 'import';
use Data::Diver qw<DiveRef Dive >;
use vars qw($VERSION @EXPORT_OK %defaults);
$VERSION = '0.06';

# This should move to Config::Spec::FromPod
# and maybe even Config::Collect
# instead of hand rolling yet another cascade

@EXPORT_OK = qw(
    get_defaults
);

%defaults = (
);

=head1 FUNCTIONS

=head2 C<< get_defaults >>

  my $config = get_defaults(
      #defaults => \%Dancer::SearchApp::Defaults::defaults,
      #env      => \%ENV,
      config   => LoadFile( 'config.yml' ),
      
      names    => [
          # hash-name, config-name, env-name, (hard-default)
            [ Server   => 'server' => IMAP_SERVER => 'localhost' ],
            [ Port     => 'port'   => IMAP_PORT => '993' ],
            [ User     => 'username' => IMAP_USER => '' ],
            [ Password => 'password' => IMAP_PASSWORD => '' ],
            [ Debug    => 'debug'    => IMAP_DEBUG => 0 ],
      ],
  );

Lame-ass config cascade

Read from %ENV, $config, hard defaults, with different names,
write to yet more different names
Should merge with other config cascade in Config::Collect

=cut

sub get_defaults {
    my( %options ) = @_;
    
    my $result = $options{ result } || {};

    $options{ defaults } ||= \%defaults; # premade defaults
    
    my @names = @{ $options{ names } };
    if( ! exists $options{ env }) {
        $options{ env } = \%ENV;
    };
    my $env = $options{ env };
    my $config = $options{ config };
    
    for my $entry (@{ $options{ names }}) {
        my ($result_name, $config_name, $env_name, $hard_default) = @$entry;
        
        if( defined $env_name and exists $env->{ $env_name } ) {
            #warn "Using $env_name from environment\n";
            my $result_loc = DiveRef($result, split m!/!, $result_name);
            $$result_loc //= $env->{ $env_name };
        };
        
        my $val = Dive( $config, split m!/!, $config_name );
        if( defined $config_name and defined( $val )) {
            #warn "Using $config_name from config ('$val')\n";
            my $result_loc = DiveRef($result, split m!/!, $result_name);
            $$result_loc //= $val;
        };
        
        if( ! defined Dive($result, split m!/!, $result_name) and defined $hard_default) {
            #warn "No $config_name from config, using hardcoded default\n";
            #print "Using $result_name from hard defaults ($hard_default)\n";
            my $result_loc = DiveRef($result, split m!/!, $result_name);
            $$result_loc = $hard_default;
        };
    };
    return $result;
};


1;