package Catalyst::Helper::Controller::Enzyme::CRUD;

our $VERSION = '0.10';


use strict;


=head1 NAME

Catalyst::Helper::Controller::Enzyme::CRUD - Helper for
Catalyst::Enzyme CRUD Controllers



=head1 SYNOPSIS

    script/myapp/create.pl controller <CONTROLLER> Enzyme::CRUD <MODEL>

    #Create BookShelf/Controller/Book.pm using the
    #BookShelf/Model/BookShelfDB/Book.pm model
    script\bookshelf_create.pl controller Book Enzyme::CRUD BookShelfDB::Book



=head1 DESCRIPTION

Helper for Enzyme::Controller::CRUD Controller.



=head2 METHODS

=over 4

=item mk_compclass



=item mk_comptest

Makes tests for the CRUD Controller.

=back

=cut

sub mk_compclass {
    my ( $self, $helper, $model ) = @_;
    my $file = $helper->{file};

    $model and $model = "$helper->{app}::Model::$model";
    $helper->{model} = $model || "";

    $helper->render_file( 'controller', $file );

    return 1;
}


sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};
    $helper->render_file('test', $test);
};


=head1 SEE ALSO

L<Catalyst::Enzyme::CRUD::Controller>, L<Catalyst::Enzyme>,
L<Catalyst::Test>, L<Catalyst::Helper>,



=head1 AUTHOR

Johan Lindstrom <johanl ÄT DarSerMan.com>



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__DATA__

__controller__
package [% class %];
use base 'Catalyst::Enzyme::CRUD::Controller';

use strict;
use warnings;



=head1 NAME

[% class %] - Catalyst Enzyme CRUD Controller



=head1 SYNOPSIS

See L<[% app %]>



=head1 DESCRIPTION

Catalyst Enzyme Controller with CRUD support.



=head1 METHODS

=head2 model_class

Define the  model class for this Controller

=cut
sub model_class {
    return("[% model %]");
}



=head1 ACTIONS

=cut
#Your actions here



=head1 SEE ALSO

L<[% app %]>, L<Catalyst::Enzyme::CRUD::Controller>,
L<Catalyst::Enzyme>



=head1 AUTHOR

[% author %]



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__test__
use strict;
use Test::More tests => 3;
use_ok( 'Catalyst::Test', '[% app %]' );
use_ok('[% class %]');

ok( request('/[% uri %]')->is_success );
