package Catalyst::Helper::Model::Enzyme::CDBI;

our $VERSION = '0.10';



use strict;
use Class::DBI::Loader;

use List::Util qw/first/;



=head1 NAME

Catalyst::Helper::Model::Enzyme::CDBI - Helper for Catalyst::Enzyme
CDBI Models



=head1 SYNOPSIS

    script/create.pl model CDBI Enzyme::CDBI dsn user password



=head1 DESCRIPTION

Helper for Enzyme::Model::CDBI Model.



=head2 METHODS

=over 4

=item mk_compclass

Reads the database and makes a main model class as well as placeholders
for each table.

=item mk_comptest

Makes tests for the CDBI Model.

=back 

=cut

sub mk_compclass {
    my ( $self, $helper, $dsn, $user, $pass ) = @_;
    $helper->{dsn}  = $dsn  || '';
    $helper->{user} = $user || '';
    $helper->{pass} = $pass || '';
    $helper->{rel} = $dsn =~ /sqlite|pg|mysql/i ? 1 : 0;
    my $file = $helper->{file};
    $helper->{classes} = [];
    $helper->render_file( 'cdbiclass', $file );
    #push( @{ $helper->{classes} }, $helper->{class} );
    return 1 unless $dsn;
    my $loader = Class::DBI::Loader->new(
        dsn       => $dsn,
        user      => $user,
        password  => $pass,
        namespace => $helper->{class}
    );

    my $path = $file;
    $path =~ s/\.pm$//;
    $helper->mk_dir($path);

    for my $c ( $loader->classes ) {
        $helper->{default_columns} = [ $self->default_columns($c) ];
        $helper->{main_column} = $self->default_main_column($c);
        $helper->{tableclass} = $c;
        $helper->{tableclass} =~ /\W*(\w+)$/;
        my $f = $1;
        my $p = File::Spec->catfile( $path, "$f.pm" );
        $helper->render_file( 'tableclass', $p );
        push( @{ $helper->{classes} }, $c );
    }
    return 1;
}

sub mk_comptest {
    my ( $self, $helper ) = @_;
    my $test = $helper->{test};
    my $name = $helper->{name};
    for my $c ( @{ $helper->{classes} } ) {
        $helper->{tableclass} = $c;
        $helper->{tableclass} =~ /\:\:(\w+)\:\:(\w+)$/;
        my $prefix;
        unless ( $1 eq 'M' ) { $prefix = "$name\::$2" }
        else { $prefix = $2 }
        $prefix =~ s/::/-/g;
        my $test = $helper->next_test($prefix);
        $helper->render_file( 'test', $test );
    }
}



=head2 default_columns($pkg)

Return array with the default column names suitable for an object in
model $pkg.

This is all column names, except PK columns.

=cut
sub default_columns {
    my $self = shift;
    my ($pkg)  = @_;

    my %pk_name_exists = map { $_ => 1 } $pkg->columns("Primary");
    my @columns = grep { ! $pk_name_exists{$_} } $pkg->columns();
    
    return(sort @columns);
}



=head2 default_main_column($pkg)

Return name of the probable main column for Model $pkg.

Default: name or title or something "name*" or "*name" or "*name*" or
MAIN_COLUMN.

=cut
sub default_main_column {
    my $self = shift;
    my ($pkg)  = @_;

    my %name = map { lc($_) => $_ } $pkg->columns;
    my $main = $name{name} ||
            $name{title} ||
            first { $_ =~  /name$/i } $pkg->columns || 
            first { $_ =~ /^name/i  } $pkg->columns || 
            first { $_ =~  /name/i  } $pkg->columns || 
            "MAIN_COLUMN";
    
    return($main);
}





=head1 SEE ALSO

L<Catalyst::Enzyme>, L<Catalyst::Test>, L<Catalyst::Helper>,
L<Catalyst::Helper::Model::CDBI>



=head1 AUTHOR

Johan Lindstrom <johanl ÄT DarSerMan.com>

I stole the _entire_ L<Catalyst::Helper::Model::CDBI> since the
Catalyst::Helper currently doesn't allow me to override only the
template contents and I wanted to get this out the door. I'd like to
subclass it though, that would be nice.



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__DATA__

__cdbiclass__
package [% class %];
use base 'Catalyst::Model::CDBI';

use strict;
use Class::DBI::Pager;



__PACKAGE__->config(
    dsn           => '[% dsn %]',
    user          => '[% user %]',
    password      => '[% pass %]',
    options       => {},
    relationships => [% rel %],
    additional_base_classes => [
        qw/
           Class::DBI::AsForm
           Class::DBI::FromForm
           Catalyst::Enzyme::CRUD::Model
           /
       ],    
);




=head1 NAME

[% class %] - Enzyme CDBI Model Component



=head1 SYNOPSIS

See L<[% app %]>



=head1 DESCRIPTION

Enzyme CDBI Model Component.



=head1 SEE ALSO

L<[% app %]>, L<Catalyst::Enzyme>



=head1 AUTHOR

[% author %]



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__tableclass__
package [% tableclass %];

use strict;



=head1 NAME

[% tableclass %] - CDBI Table Class



=head1 SYNOPSIS

See L<[% app %]>



=head1 DESCRIPTION

CDBI Table Class with Enzyme CRUD configuration.

=cut


#__PACKAGE__->columns(Stringify => "[% main_column %]");
#__PACKAGE__->columns(view_columns => qw/ [% default_columns.join(" ") %] /);
#__PACKAGE__->columns(list_columns => qw/ [% default_columns.join(" ") %] /);


#See the Catalyst::Enzyme docs and tutorial for information on what
#CRUD options you can configure here. These include: moniker,
#column_monikers, rows_per_page, data_form_validator.
__PACKAGE__->config(
    crud => {
        
    }
);



=head1 ALSO

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
use Test::More tests => 2;
use_ok( 'Catalyst::Test', '[% app %]' );
use_ok('[% tableclass %]');
