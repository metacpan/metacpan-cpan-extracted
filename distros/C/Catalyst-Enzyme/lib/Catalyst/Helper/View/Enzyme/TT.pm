package Catalyst::Helper::View::Enzyme::TT;

our $VERSION = '0.10';


use strict;
use Data::Dumper;
use File::Basename;
use File::Path;
use Path::Class;
use File::Slurp;



=head1 NAME

Catalyst::Helper::View::Enzyme::TT - Helper for Enzyme::TT Views

=head1 SYNOPSIS

    script/create.pl view TT Enzyme::TT



=head1 DESCRIPTION

Helper for Enzyme::TT Views.

=head1 METHODS



=head2 mk_compclass

=cut
sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );

    for my $template (
        qw/
           add.tt
           edit.tt
           footer.tt
           form_macros.tt
           header.tt
           list.tt
           list_macros.tt
           pager.tt
           pager_macros.tt
           view.tt
           view_macros.tt
           delete.tt
           /) {
        
        $self->cp_local_file($helper, __FILE__, "TT", "root/base/$template");
    }
    
    $self->cp_local_file($helper, __FILE__, "TT", "root/static/css/enzyme.css", "root/static/css/" . lc("$helper->{app}.css"));
}



=head2 cp_local_file($helper, $file_source_base, $subdir_source, $file_source_name, [$file_target_name = $file_source_name])

Copy the file at
basename($file_source_base)/$subdir_source/$file_source_name into the
application dir/$file_target_name.

=cut
sub cp_local_file {
    my ($self, $helper, $file_source_base, $subdir_source, $file_source_name, $file_target_name) = @_;
    $file_target_name ||= $file_source_name;

    my $dir_source = dir( dirname($file_source_base), $subdir_source );
    my $file_source = file($dir_source, $file_source_name);
    my $text_source = read_file("$file_source");

    my $file_target = file($helper->{'base'}, $file_target_name);

    mkpath(dirname($file_target));
    $helper->mk_file($file_target, $text_source);
}




=head1 SEE ALSO

L<Catalyst::View::TT::ControllerLocal>



=head1 AUTHOR

Johan Lindstrom, C<johanl ÄT cpan.org>


=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base qw/ Catalyst::View::TT::ControllerLocal Catalyst::Enzyme::CRUD::View /;

=head1 NAME

[% class %] - Catalyst Catalyst::Enzyme::CRUD::View TT View




=head1 SYNOPSIS

See L<[% app %]>



=head1 DESCRIPTION

Catalyst TT View with L<Catalyst::View::TT::ControllerLocal> and
L<Catalyst::Enzyme::CRUD::View> CRUD support.



=head1 AUTHOR

[% author %]



=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
