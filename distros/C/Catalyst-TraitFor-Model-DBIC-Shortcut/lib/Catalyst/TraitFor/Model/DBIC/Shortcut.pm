package Catalyst::TraitFor::Model::DBIC::Shortcut;

use namespace::autoclean;
use Moose::Role;

=head1 NAME

Catalyst::TraitFor::Model::DBIC::Shortcut - shortcuts support for DBIC models

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    #
    # application class
    #
    package TestApp;

    use Moose;
    use namespace::autoclean;
    use Catalyst qw/ ......... /;
    extends 'Catalyst';
    with 'Catalyst::TraitFor::Model::DBIC::Shortcut';


    #
    # controller class
    #
    package TestApp::Controller::Test;

    .........
        # these two calss are the same
        my $s = $c->model('DB')->schema;
        my $s = $c->db_schema;
    .........
        # these two calss are the same
        my $rs = $c->model('DB::Actor');
        my $rs = $c->db_actor_rs;
    .........


=head1 DESCRIPTION

If you got tired of writting C<< $c->model('DB::Actor') >> each time, or if
you use auto-completion intensively, you could look at this trait.
Just use this role in your application class, and you'll have shortcuts
auto-created for all L<DBIx::Class>-based models:

=over 4

=item - schema

for all schema classes, based on L<Catalyst::Model::DBIC::Schema>, you'll get
method with name "lowercase class name" + "_schema", with all "::" converted to
underscore ("_"):

    $c->model('DB')->schema         ==>     $c->db_schema
    $c->model('DBIC')->schema       ==>     $c->dbic_schema
    $c->model('DBIC::DB1')->schema  ==>     $c->dbic_db1_schema

=item - resultset

for all resultset classes, based on L<DBIx::Class>, you'll get
method with name "lowercase class name" + "_rs", with all "::" converted to
underscore ("_"):

    $c->model('DB::Actor')          ==>     $c->db_actor_rs
    $c->model('DB::Track')          ==>     $c->db_track_rs
    $c->model('DBIC::DB1::Actor')   ==>     $c->dbic_db1_actor_rs

=back

=cut

after 'setup_finalize' => sub {
    my $self = shift;

    for my $m ( sort $self->models ) {
        my $model = $self->model($m);
        my $acc   = lc($m);
        $acc =~ s/::/_/g;

        if ( $model->isa('Catalyst::Model::DBIC::Schema') ) {
            $acc .= '_schema';

            if ( $self->can($acc) ) {
                ## log
                next;
            }
            $self->mk_group_accessors( inherited => $acc );
            $self->$acc( $model->schema );
        }
        elsif ( $model->isa('DBIx::Class') ) {
            $acc .= '_rs';
            if ( $self->can($acc) ) {
                ## log
                next;
            }
            $self->mk_group_accessors( inherited => $acc );
            $self->$acc($$model);
        }
    }

};

__PACKAGE__->meta->make_immutable();

=head1 SEE ALSO

L<Catalyst>, L<DBIx::Class>, L<Moose>

=head1 SUPPORT

=over 4

=item * Report bugs or feature requests

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-TraitFor-Model-DBIC-Shortcut>

L<http://www.assembla.com/spaces/Catalyst-TraitFor-Model-DBIC-Shortcut/tickets>

=item * Git repository

git clone git://git.assembla.com/Catalyst-TraitFor-Model-DBIC-Shortcut.git

=back

=head1 AUTHOR

Oleg Kostyuk, C<< <cub#cpan.org> >>

Based on ideas from from Pedro Melo and Oleg Pronin

L<http://lists.scsys.co.uk/pipermail/dbix-class/2010-January/008794.html>

L<http://lists.scsys.co.uk/pipermail/dbix-class/2010-February/008903.html>


=head1 COPYRIGHT & LICENSE

Copyright by Oleg Kostyuk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Catalyst::TraitFor::Model::DBIC::Shortcut

