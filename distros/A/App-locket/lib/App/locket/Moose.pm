package App::locket::Moose;

use strict;
use warnings;

use Any::Moose();
use Any::Moose 'Util::TypeConstraints';

subtype 'App::locket::Dir' => as 'Path::Class::Dir';
for my $type ( 'App::locket::Dir' ) {
    coerce $type,
    from 'Str',      via { Path::Class::Dir->new($_) },
    from 'ArrayRef', via { Path::Class::Dir->new(@$_) },
    ;
}

subtype 'App::locket::File' => as 'Path::Class::File';
for my $type ( 'App::locket::File' ) {
    coerce $type,
    from 'Str',      via { Path::Class::File->new($_) },
    from 'ArrayRef', via { Path::Class::File->new(@$_) },
    ;
}

any_moose( 'Exporter' )->setup_import_methods(
    as_is => [qw/ has_dir has_file /], 
    also => any_moose,
);

sub has_dir {
    my $meta = caller->meta;
    my ( $name, %options ) = @_;
    $meta->add_attribute(
        $_,
        isa => 'App::locket::Dir',
        coerce => 1,
        %options,
    ) for ( ref $name ? @$name : $name );
}

sub has_file {
    my $meta = caller->meta;
    my ( $name, %options ) = @_;
    $meta->add_attribute(
        $_,
        isa => 'App::locket::File',
        coerce => 1,
        %options,
    ) for ( ref $name ? @$name : $name );
}

1;
