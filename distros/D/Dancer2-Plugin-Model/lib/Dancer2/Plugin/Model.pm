package Dancer2::Plugin::Model;

use strictures 2;

use Dancer2;
use Dancer2::Plugin;

use Dancer2::Plugin::AppRole::Helper;

our $VERSION = '1.152120'; # VERSION

# ABSTRACT: gantry to hang a model layer onto Dancer2

#
# This file is part of Dancer2-Plugin-Model
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


on_plugin_import { ensure_approle_s Model => @_ };

register model => sub {
    my ( $dsl, $model ) = @_;
    return $dsl->app->model->get( $model );
};

register set_model => sub {
    my ( $dsl, $model ) = @_;
    return $dsl->app->model( $model ? $model : () );
};

register configure_model => sub { shift->app->model_args( {@_} ) };

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::Model - gantry to hang a model layer onto Dancer2

=head1 VERSION

version 1.152120

=head1 SYNOPSIS

In your app:

    package My;
    use Dancer2;
    use Dancer2::Plugin::Model;
    
    configure_model db => make_db();
    set_model;
    
    any '/' => sub {
        template 'index', { news => model( "News" )->get_latest };
    };

In the model factory:

    package My::Model;
    
    use Module::Runtime 'use_module';
    use Moo;
    
    has db => is => ro => required => 1;
    
    sub get {
        my ( $self, $entity_name ) = @_;
        use_module( __PACKAGE__ . "::$entity_name" )->new( db => $self->db );
    }

In the model entity:

    package My::Model;
    
    use Moo;
    
    has db => is => ro => required => 1;
    
    sub get_latest {
        my ( $self ) = @_;
        
        $self->db->search(
            "events",
            where => { event => 'New' }, sort => { date  => -1 }, per_page => 5,
        );
    }

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dancer2-Plugin-Model>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/Dancer2-Plugin-Model>

  git clone https://github.com/wchristian/Dancer2-Plugin-Model.git

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
