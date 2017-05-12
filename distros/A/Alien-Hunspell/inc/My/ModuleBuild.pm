package My::ModuleBuild;

use strict;
use warnings;
use base qw( Alien::Base::ModuleBuild );
use File::Glob qw( bsd_glob );

sub new
{
  my($class, %args) = @_;

  if($^O eq 'MSWin32')
  {
    $args{alien_bin_requires}->{'Alien::libtool24'} = '0.02';
    $args{alien_helper}->{ltbase} = q{
      require Alien::libtool24;
      my $dir = Alien::libtool24->dist_dir;
      $dir =~ s{/}{\\\\}g if $^O eq 'MSWin32';
      $dir;
    };
    my $make = pop @{ $args{alien_build_commands} };
    
    my $cmd = $^O eq 'MSWin32'
      ? 'copy %{ltbase}\\bin\\libtool libtool'
      : 'cp %{ltbase}/bin/libtool libtool';
    
    push @{ $args{alien_build_commands} }, $cmd, $make;
    
    $args{configure_requires}->{'Alien::Base'} = '0.024';
    $args{requires}->{'Alien::Base'} = '0.024';
  }
  elsif($^O eq 'freebsd')
  {
    $args{alien_helper}->{star} = q{
      join " ", File::Glob::bsd_glob("*")
    };
    unshift @{ $args{alien_build_commands} }, 
      '%{patch} -p1 < ../../patches/freebsd-configure.diff',
      '%{patch} -p1 < ../../patches/freebsd-autotools.diff',
      '%{patch} -p1 < ../../patches/freebsd-iconv-const-arg2.diff',
      # trick autotools into thinking that they do
      # not need to regenerate (which is true)
      'rm -f compile',
      'touch %{star}';
  }
  
  my $self = $class->SUPER::new(%args);
  $self;
}

sub ACTION_install
{
  my($self, @ARGS) = @_;
  unlink for 
    grep { /\.so/ || /\.(dylib|bundle|la|dll|dll\.a)$/ } 
    map { bsd_glob($_) }
    File::Spec->catfile($self->install_destination($self->alien_arch ? 'arch' : 'lib'), qw( auto share dist ), $self->dist_name, 'lib', '*' );
  $self->SUPER::ACTION_install(@ARGS);
}

1;
