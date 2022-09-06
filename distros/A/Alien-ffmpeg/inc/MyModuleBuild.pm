package # hide from PAUSE
  MyModuleBuild;

use parent 'Alien::Base::ModuleBuild';

sub process_script_files {
  my $self = shift;

  if( $self->config_data->{install_type} eq 'system' ) {
    my $bins;
    $bins = [
          'bin/ffmpeg',
          'bin/ffprobe'
        ];

    my %script_files = map { $_ => 1 } @{ $self->{properties}{script_files} };
    delete @script_files{ @$bins };
    $self->{properties}{script_files} = [ keys %script_files ];
  }

  $self->SUPER::process_script_files;
}

1;
