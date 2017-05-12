package MyApp::Controller::REST::CRUD;
use Moose;
use namespace::autoclean;

# we might not have this module installed
BEGIN {
    eval {
        extends 'CatalystX::CRUD::Controller::REST';
        __PACKAGE__->config(
            model_name    => 'Main',
            model_adapter => 'MyModelAdapter',
            model_meta    => {
                dbic_schema    => 'Track',
                resultset_opts => {
                    join     => { track_cds => 'cd' },
                    prefetch => { track_cds => 'cd' }
                }
            },
            primary_key => 'trackid',
            page_size   => 50,
            default     => 'application/json',
        );
    };
    if ($@) {
        warn "CatalystX::CRUD::Controller::REST not available";
    }
}

1;
