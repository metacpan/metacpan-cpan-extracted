package BlankOnDev::config::save;
use strict;
use warnings FATAL => 'all';

# Import Module :
use JSON::XS;
use BlankOnDev::Utils::file;

# Version :
our $VERSION = '0.1005';

# Subroutine save key config "prepare" :
# ------------------------------------------------------------------------
sub prepare {
    my ($self, $fix_config) = @_;

    my $data_config = $fix_config->{'r_config'};
    my $filename_cfg = $fix_config->{'filename'};
    my $dirdev_cfg = $fix_config->{'dir_dev'};

    $self->save_to_file($filename_cfg, $dirdev_cfg, $data_config);
}
# Subroutine for save config GnuPG generate Key :
# ------------------------------------------------------------------------
sub gpg_genkey {
    my ($self, $fix_config) = @_;

    my $data_config = $fix_config->{'r_config'};
    my $filename_cfg = $fix_config->{'filename'};
    my $dirdev_cfg = $fix_config->{'dir_dev'};

    $self->save_to_file($filename_cfg, $dirdev_cfg, $data_config);
}

# Subroutine for save config to file config :
# ------------------------------------------------------------------------
sub save_to_file {
    my ($self, $filename, $dir_dev, $data) = @_;

    my $data_file = encode_json($data);
    my $create_file = BlankOnDev::Utils::file->create($filename, $dir_dev, $data_file);

    return $create_file;
}
1;