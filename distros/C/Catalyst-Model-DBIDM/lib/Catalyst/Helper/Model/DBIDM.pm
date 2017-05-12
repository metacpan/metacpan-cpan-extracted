package Catalyst::Helper::Model::DBIDM;

use strict;
use warnings;

our $VERSION = '0.01';

use Carp;

=head1 NAME

Catalyst::Helper::Model::DBIDM - Helper for DBIx::DataModel Schema Models

=head1 SYNOPSIS

  script/create.pl model CatalystModelName DBIDM MyApp::SchemaClass [ MyApp::SchemaCreatorClass ]

=head1 DESCRIPTION

Helper for the DBIx::DataModel Schema Models.

=head2 Arguments:

C<CatalystModelName> is the short name for the Catalyst Model class
being generated (i.e. callable with C<$c-E<gt>model('CatalystModelName')>).
It should thus B<not> start with C<MyApp::Model>.

C<MyApp::SchemaClass> is the fully qualified classname of your Schema.  Note
that you should have a good reason to create this under a new global namespace,
otherwise use an existing top level namespace for your schema class.

C<MyApp::SchemaCreatorClass> is the fully qualified name of the class that
creates your Schema (the one that runs
C<< DBIx::DataModel->Schema('MyApp::SchemaClass') >>). If present, the
generated model class will include a C<use> statement to run this schema
creator class.

=head1 METHODS

=head2 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $schema_class, $schema_creator_class) = @_;

    $helper->{schema_class} = $schema_class
        or croak "Must supply schema class name";
    $helper->{schema_creator_class} = $schema_creator_class;

    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to DBIC and this Model style:

L<DBIx::Class>, L<DBIx::Class::Schema>,
L<DBIx::Class::Schema::Loader>, L<Catalyst::Model::DBIC::Schema>

=head1 AUTHOR

Cedric Bouvier C<cbouvi@gmail.com>, largely inspired by the works of Brandon L
Black, C<blblack@gmail.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use base qw/ Catalyst::Model::DBIDM /;

[% IF schema_creator_class %]use [% schema_creator_class %];
[% END %]
__PACKAGE__->config(
    schema_class => '[% schema_class %]',
);

=head1 NAME

[% class %] - Catalyst DBIx::DataModel Schema Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

L<Catalyst::Model::DBIDM> Model using schema L<[% schema_class %]>.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

