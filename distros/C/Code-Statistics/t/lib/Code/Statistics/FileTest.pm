use strict;
use warnings;

package Code::Statistics::FileTest;

use lib '../..';

use parent 'Test::Class::TestGroup';

use Test::More;
use Test::MockObject;
use Path::Class 'dir';

use Code::Statistics::File;

sub make_fixtures : Test(setup) {
    my ( $self ) = @_;

    my $collector = Test::MockObject->new;
    $collector->set_isa( 'Code::Statistics::Collector' );
    $collector->set_always( 'relative_paths' );
    $collector->set_always( 'foreign_paths' );

    $self->{collector} = $collector;

    $self->{file} = Code::Statistics::File->new( collector => $self->{collector}, original_path => 'data/json/basic_collect.json', path => 'data/json/basic_collect.json' );

    return;
}

sub _format_file_path : TestGroup(file path formatting works with different inputs) {
    my ( $self ) = @_;

    is(
        $self->{file}->_format_file_path->path,
        dir('data/json/basic_collect.json')->absolute->stringify,
        'without any params set, files get formatted to native and absolute paths'
    );

    return;
}

1;
