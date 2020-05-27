package Employee::IndexInfo;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use namespace::autoclean;

extends 'Data::AnyXfer::Elastic::IndexInfo';

sub define_index_info {
    return (
        silo         => 'private_data',
        connect_hint => 'readwrite',
        alias        => 'employees',
        type         => 'employee',
        mappings     => {
            employee => {
                properties => {
                    id         => { type => 'integer' },
                    first_name => { type => 'keyword' },
                    last_name  => { type => 'keyword' },
                    email      => { type => 'keyword' },
                },
            },
        },
    );
}

sub sample_documents {

    return (
        {   id         => 1,
            first_name => "Wayne",
            last_name  => "Duncan",
            email      => 'wduncan0@berkeley.edu'
        },
        {   id         => 2,
            first_name => "Randy",
            last_name  => "Cunningham",
            email      => 'rcunningham1@tripod.com'
        },
        {   id         => 3,
            first_name => "Lawrence",
            last_name  => "Chavez",
            email      => 'lchavez2@google.co.uk'
        },
        {   id         => 4,
            first_name => "Jessica",
            last_name  => "Edwards",
            email      => 'jedwards3@taobao.com'
        },
        {   id         => 5,
            first_name => "Gerald",
            last_name  => "Hart",
            email      => 'ghart4@dot.gov'
        },
        {   id         => 6,
            first_name => "Peter",
            last_name  => "Montgomery",
            email      => 'pmontgomery5@ftc.gov'
        },
        {   id         => 7,
            first_name => "Nancy",
            last_name  => "Russell",
            email      => 'nrussell6@163.com'
        },
        {   id         => 8,
            first_name => "Linda",
            last_name  => "Boyd",
            email      => 'lboyd7@admin.ch'
        },
        {   id         => 9,
            first_name => "Robert",
            last_name  => "Hernandez",
            email      => 'rhernandez8@salon.com'
        },
        {   id         => 10,
            first_name => "Jean",
            last_name  => "Ramirez",
            email      => 'jramirez9@telegraph.co.uk'
        },
    );
}

__PACKAGE__->meta->make_immutable;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

