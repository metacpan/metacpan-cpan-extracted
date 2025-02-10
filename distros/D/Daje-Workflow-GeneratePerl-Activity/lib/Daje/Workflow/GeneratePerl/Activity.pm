package Daje::Workflow::GeneratePerl::Activity;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;

use Mojo::JSON qw{to_json from_json};

#
# NAME
# ====
#
# Daje::Workflow::GeneratePerl::Activity - It creates perl code
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::GeneratePerl::Activity;
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::GeneratePerl::Activity is a module that generates perl code
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

use String::CamelCase qw(camelize);

use Daje::Workflow::GeneratePerl::Generate::Fields;
use Daje::Workflow::GeneratePerl::Generate::Methods;
use Daje::Workflow::GeneratePerl::Generate::Class;
use Daje::Workflow::GeneratePerl::Generate::BaseClass;
use Daje::Workflow::GeneratePerl::Generate::Interface;
use Daje::Workflow::GeneratePerl::Generate::View;
use Daje::Workflow::Templates;

our $VERSION = '0.11';

has 'success' ;
has 'templates';
has 'json';

sub generate_classes($self) {

    @{$self->context->{context}->{perlfiles}} = ();
    $self->_load_schema();
    $self->_load_template() unless $self->error->has_error();
    return 0 if $self->error->has_error();

    $self->_base_class();
    my $length = scalar @{$self->json->{tables}};
    for (my $i = 0; $i < $length; $i++) {
        $self->_generate_table_class(@{$self->json->{tables}}[$i]);
        $self->_generate_interface_class(@{$self->json->{tables}}[$i]->{table}->{table_name});
    }
    $length = scalar @{$self->json->{views}};
    for (my $i = 0; $i < $length; $i++) {
        $self->_generate_view_class(@{$self->json->{views}}[$i]);
        $self->_generate_interface_class(
            @{$self->json->{views}}[$i]->{view}->{table_name},
            'view_name_space',
            'view_name_interface',
            'view_interface_space_dir'
        );
    }
    return 1;
}

sub _load_schema($self) {
    eval {
        my $schema = from_json(@{$self->context->{context}->{schema}}[0]->{data});
        $self->json($schema);
    };
    $self->error->add_error($@) if defined $@;
}

sub _load_template($self) {

    eval {
        my $templates = Daje::Workflow::Templates->new(
            data_sections => $self->activity_data->{template}->{data_sections},
            source        => $self->activity_data->{template}->{source},
            error         => $self->error,
        )->load_templates();
        $self->templates($templates);
    };
    $self->error->add_error($@) if defined $@;
}

sub _generate_interface_class($self, $table_name,
                              $name_space = 'name_space',
                              $name_interface = 'name_interface',
                              $interface_space_dir =  'interface_space_dir') {

    my $template = $self->templates();
    Daje::Workflow::GeneratePerl::Generate::Interface->new(
        templates           => $template,
        context             => $self->context,
        table               => $table_name,
        name_space          => $name_space,
        name_interface      => $name_interface,
        interface_space_dir => $interface_space_dir,
    )->generate();
}

sub _base_class($self) {
    my $templates = $self->templates();
    Daje::Workflow::GeneratePerl::Generate::BaseClass->new(
        templates => $templates,
        context   => $self->context,
    )->generate();

}

sub _generate_table_class($self, $table) {
    my $fields = $self->_get_fields($table);
    my $methods = $self->_methods($fields, $table);
    my $perl = $self->_class($methods, $table, $fields);
    $self->_save_class($perl, $table->{table});
}

sub _save_class($self, $perl, $table, $name_space_dir =  "name_space_dir") {

    my $data->{file} = $self->context->{context}->{perl}->{$name_space_dir} . camelize($table->{table_name}) . ".pm";
    $data->{data} = $perl;
    $data->{only_new} = 0;
    $data->{path} = 1;
    push(@{$self->context->{context}->{perlfiles}},$data);
}

sub _class($self, $methods, $table, $fields) {
    my $template = $self->templates();
    my $class = Daje::Workflow::GeneratePerl::Generate::Class->new(
        json     => $table->{table},
        methods  => $methods,
        templates => $template,
        context   => $self->context,
        fields   => $fields,
    );
    my $perl = $class->generate();

    return $perl;
}

sub _methods($self, $fields, $table) {
    my $template = $self->templates();
    my $methods = Daje::Generate::Perl::Generate::Methods->new(
        json     => $table->{table},
        fields   => $fields,
        templates => $template
    );
    $methods->generate();

    return $methods;
}

sub _generate_view_class($self, $view) {
    $view = $view;
    my $template = $self->templates();

    my $perl = Daje::Workflow::GeneratePerl::Generate::View->new(
        json        => $view,
        templates   => $template,
        context     => $self->context,
    )->generate();

    $self->_save_class($perl, $view->{view}, "view_name_space_dir");
}

sub _get_fields($self, $json) {
    my $template = $self->templates();
    my $fields = Daje::Workflow::GeneratePerl::Generate::Fields->new(
        json     => $json->{table},
        templates => $template
    );
    $fields->generate();
    return $fields;
}


1;
__END__




#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Workflow::GeneratePerl::Activity - It creates perl code



=head1 SYNOPSIS


    use Daje::Workflow::GeneratePerl::Activity;



=head1 DESCRIPTION



Daje::Workflow::GeneratePerl::Activity is a module that generates perl code



=head1 REQUIRES

L<Daje::Workflow::Templates> 

L<Daje::Workflow::GeneratePerl::Generate::View> 

L<Daje::Workflow::GeneratePerl::Generate::Interface> 

L<Daje::Workflow::GeneratePerl::Generate::BaseClass> 

L<Daje::Workflow::GeneratePerl::Generate::Class> 

L<Daje::Workflow::GeneratePerl::Generate::Methods> 

L<Daje::Workflow::GeneratePerl::Generate::Fields> 

L<String::CamelCase> 

L<Mojo::JSON> 

L<Mojo::Base> 


=head1 METHODS

=head2 generate_classes($self)

 generate_classes($self)();


=head1 AUTHOR


janeskil1525 E<lt>janeskil1525@gmail.comE<gt>



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

