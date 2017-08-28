package BioX::Workflow::Command::run::Rules::Directives::Types::Roles::File;

use Moose::Role;

sub check_file_exists {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    if ( !exists $v->{file} ) {
        $self->app_log->warn( 'You have a key ' . $k );
        $self->app_log->warn(
'This maps to a csv file type that requires file and optionally requires options'
        );
        $self->$k($v);
        return 0;
    }

    my $file = $self->interpol_directive( $v->{file} );
    if ( !-e $file ) {
        $self->app_log->warn( 'You have a key ' . $k );
        $self->app_log->warn( 'With file ' . $file );
        $self->app_log->warn('Which does not exist');
        $self->$k($v);
        return 0;
    }

    return $file;
}

1;
