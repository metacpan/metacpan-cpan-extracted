use strict;
use warnings;
no warnings 'once';

use Test::More 0.92;
use Config;
use File::Spec;
use t::Util;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

#--------------------------------------------------------------------------#
# set PATH to find our mock uuid
#--------------------------------------------------------------------------#

local $ENV{PATH} = File::Spec->catdir(qw/t bin/).$Config{path_sep}.$ENV{PATH};
my $binary = File::Spec->catfile(qw/t bin uuid/);
$binary .= ".bat" if $^O eq 'MSWin32';

#--------------------------------------------------------------------------#
# hide some modules
#--------------------------------------------------------------------------#

my %hidden;
sub _hider {
  my ($self, $file) = @_;
  die "Can't locate '$file' (hidden)" if $hidden{$file};
};

unshift @INC, \&_hider;

#--------------------------------------------------------------------------#
# Start tests
#--------------------------------------------------------------------------#

my %fcn = (
  any => sub { Data::GUID::Any::guid_as_string() },
  v1  => sub { Data::GUID::Any::v1_guid_as_string() },
  v4  => sub { Data::GUID::Any::v4_guid_as_string() },
);

my %using = (
  any => sub { $Data::GUID::Any::Using_vX },
  v1  => sub { $Data::GUID::Any::Using_v1 },
  v4  => sub { $Data::GUID::Any::Using_v4 },
);

require_ok( "Data::GUID::Any" )
  or BAIL_OUT "require Data::GUID::Any failed";

for my $style ( qw/any v1 v4/ ) {

  my @providers = map { $_->[0] } @{Data::GUID::Any::_generator_set($style)};
  undef $Data::GUID::Any::NO_BINARY;
  undef %hidden;

  while ( my $mod = shift @providers )  {
    SKIP: {
      my $available;
      {
        local $SIG{__WARN__} = sub {};
        $available = Data::GUID::Any::_is_available($mod);
      }
      skip( "$mod not available", 1) unless $available;
      # reload Data::GUID::Any
      delete $INC{'Data/GUID/Any.pm'};
      {
        local $SIG{__WARN__} = sub {};
        eval { require Data::GUID::Any;1 };
        is( $@ , "",
          "reloaded Data::GUID::Any"
        );
      }
      is( $using{$style}->(), $mod,
        "$style: Data::GUID::Any set to use '$mod'"
      );
      my $guid = $fcn{$style}->();
      ok( t::Util::looks_like_uc_guid( $guid  ),
        "$style: got valid guid from '$mod'"
      ) or diag $guid;
      {
        local $Data::GUID::Any::UC;
        $guid = $fcn{$style}->();
        ok( t::Util::looks_like_lc_guid( $guid  ),
          "$style: got valid lc guid from '$mod' (\$UC=0)"
        ) or diag $guid;
      }
      # hide binary or module before next loop
      if ( $mod eq 'uuid') {
        $Data::GUID::Any::NO_BINARY = 1;
        pass 'uuid hidden';
      }
      else {
        my $mod_path = $mod;
        $mod_path =~ s{::}{/}g;
        $mod_path .= ".pm";
        $hidden{$mod_path} = delete $INC{$mod_path};
        eval "require $mod; 1";
        ok( $@, "$mod hidden" )
          or diag "$mod_path";
      }
    }
  }
}

done_testing;
