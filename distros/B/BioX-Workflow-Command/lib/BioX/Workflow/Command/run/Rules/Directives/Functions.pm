package BioX::Workflow::Command::run::Rules::Directives::Functions;

use MooseX::App::Role;
use namespace::autoclean;

use File::Slurp;
use JSON;
use Try::Tiny;

has 'remove_from_json' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        [
            'remove_from_json', 'register_namespace',
            '_ERROR',           'register_process_directives',
            'register_types',   'run_stats',
            'interpol_directive_cache', 'before_meta',
        ];
    },
);

sub serialize_to_json {
    my $self = shift;
    my $file = shift;

    my %hacky_self = %{$self};
    foreach my $remove ( @{ $self->remove_from_json } ) {
        delete $hacky_self{$remove};
    }

    my $json = JSON->new->utf8->pretty->allow_blessed->encode( \%hacky_self );

    if ($file) {
        write_file( $file, $json );
    }
    return $json;
}

sub read_json_file {
    my $self = shift;
    my $file = shift;

    my $read = read_file($file);
    my $json = JSON->new->utf8->decode($read);

    return $json;
}

# no Moose;
no Moose::Role;

1;
