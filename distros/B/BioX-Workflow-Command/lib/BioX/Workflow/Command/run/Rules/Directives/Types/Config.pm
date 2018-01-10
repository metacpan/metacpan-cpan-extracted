package BioX::Workflow::Command::run::Rules::Directives::Types::Config;

use Moose::Role;
use namespace::autoclean;

with 'BioX::Workflow::Command::run::Rules::Directives::Types::Roles::File';

use Config::Any;
use Try::Tiny;

after 'BUILD' => sub {
    my $self = shift;

    $self->set_register_types(
        'config',
        {
            builder => 'create_reg_attr',
            lookup  => [
                '.*_json$',  '.*_yaml$', '.*_yml$', '.*_jsn$',
            ]
        }
    );

    $self->set_register_process_directives(
        'config',
        {
            builder => 'process_directive_config',
            lookup  => [
                '.*_json$', '.*_yaml$', '.*_yml$', '.*_jsn$',
            ],
        }
    );
};

=head3 process_directive_config

##TODO Think about adding in multiple files  - supported by Config::Any

This only takes the argument file
For now only one file per entry is supported

=cut

sub process_directive_config {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    return unless ref($v);

    my $file = $self->check_file_exists( $k, $v );
    return unless $file;

    my $cfg;
    my $valid = 1;
    try {
        $cfg = Config::Any->load_files( { files => [$file], use_ext => 1 } );
    }
    catch {
        $self->app_log->warn(
"Unable to load the config with '. $k .' The following error was received.\n"
        );
        $self->app_log->warn("$_\n");
        $valid = 0;
    };

    if ( !$valid ) {
        $self->$k($v);
        return;
    }

    $cfg = $cfg->[0];
    my $config = $cfg->{$file};
    $self->$k($config);
}

no Moose;

1;
