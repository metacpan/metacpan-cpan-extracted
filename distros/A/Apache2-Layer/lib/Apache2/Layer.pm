use strict;
use warnings;
package Apache2::Layer;
BEGIN {
  $Apache2::Layer::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $Apache2::Layer::VERSION = '1.103360';
}
# ABSTRACT: Layers for DocumentRoot

use Apache2::Const -compile => qw(
    ACCESS_CONF RSRC_CONF
    FLAG ITERATE
    OK DECLINED

    NOT_IN_DIR_LOC_FILE NOT_IN_LOCATION 
);
use APR::Const -compile => qw(FINFO_NORM);

use Apache2::CmdParms ();
use Apache2::Module ();
use Apache2::Directive ();
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use APR::Finfo ();

use File::Spec ();

my @directives = (
    {
        name         => 'DocumentRootLayers',
        func         => __PACKAGE__ . '::_DocumentRootLayersParam',
        req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
        args_how     => Apache2::Const::ITERATE,
        errmsg       => 'DocumentRootLayers DirPath1 [DirPath2 ... [DirPathN]]',
    },
    {
        name         => 'EnableDocumentRootLayers',
        func         => __PACKAGE__ . '::_EnableDocumentRootLayersParam',
        req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
        args_how     => Apache2::Const::FLAG,
        errmsg       => 'EnableDocumentRootLayers On|Off',
    },
    {
        name         => 'DocumentRootLayersStripLocation',
        func         => __PACKAGE__ . '::_DocumentRootLayersStripLocationParam',
        req_override => Apache2::Const::RSRC_CONF | Apache2::Const::ACCESS_CONF,
        args_how     => Apache2::Const::FLAG,
        errmsg       => 'DocumentRootLayersStripLocation On|Off',
    },
);
Apache2::Module::add(__PACKAGE__, \@directives);
Apache2::ServerUtil->server->push_handlers(PerlTransHandler => ['Apache2::Layer::handler'] );

sub _merge_cfg {
    return bless {
        DocumentRootLayersStripLocation => 1,
        %{$_[0]}, %{$_[1]}
    }, ref $_[0];
}

sub DIR_MERGE { _merge_cfg(@_) }
sub SERVER_MERGE { _merge_cfg(@_) }

sub _check_cmd_context {
    my $params = shift;

    if ( $params->check_cmd_context(
            Apache2::Const::NOT_IN_DIR_LOC_FILE
            & ~Apache2::Const::NOT_IN_LOCATION
        )
    ) {
        my $dir = $params->directive;

        die $dir->directive," not allowed in ",
            $dir->parent->directive, " ...> context\n";
    }
}

# workaround the bug in mod_perl, that does not set to correct
# $r->location if only custom directives have been used within
# nested paths in <Location|LocationMatch>
sub _set_location_path {
    my ($self, $path) = @_;

    $self->{LocationPath} = $path
        if $path;
}

sub _DocumentRootLayersParam {
    my ($self, $params, $path) = @_;

    _check_cmd_context($params);

    push @{ $self->{DocumentRootLayers} }, $path;
    $self->_set_location_path( $params->path );
}

sub _EnableDocumentRootLayersParam {
    my ($self, $params, $flag) = @_;

    _check_cmd_context($params);

    $self->{DocumentRootLayersEnabled} = $flag;
    $self->_set_location_path( $params->path );
}

sub _DocumentRootLayersStripLocationParam {
    my ($self, $params, $flag) = @_;

    _check_cmd_context($params);

    $self->{DocumentRootLayersStripLocation} = $flag;
    $self->_set_location_path( $params->path );
}

sub handler {
    my $r = shift;

    my $dir_cfg = Apache2::Module::get_config(
        __PACKAGE__, $r->server, $r->per_dir_config
    );

    return Apache2::Const::DECLINED
        unless $dir_cfg->{DocumentRootLayersEnabled};

    if ( my $paths = $dir_cfg->{DocumentRootLayers} ) {
        for my $dir ( @$paths ) {
            my $uri = $r->uri;
            # not defined means On
            if ( ! defined $dir_cfg->{DocumentRootLayersStripLocation}
                    ||
                 $dir_cfg->{DocumentRootLayersStripLocation}
            ) {
                if ( my $path = $dir_cfg->{LocationPath} ) {
                    $uri =~ s/^$path//;
                }
            }
            my $file = File::Spec->canonpath(
                File::Spec->catfile(
                    File::Spec->file_name_is_absolute($dir) ?
                        $dir : File::Spec->catdir( $r->document_root, $dir ),
                    $uri
                )
            );

            if ( my $finfo = eval {
                APR::Finfo::stat($file, APR::Const::FINFO_NORM, $r->pool)
            } ) {
                $r->push_handlers(PerlMapToStorageHandler => sub {
                    my $r = shift;
                    $r->filename($file);
                    $r->finfo($finfo);
                    return Apache2::Const::DECLINED;
                });

                return Apache2::Const::DECLINED;
            }
        }
    }

    return Apache2::Const::DECLINED;
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Apache2::Layer - Layers for DocumentRoot

=head1 VERSION

version 1.103360

=head1 SYNOPSIS

    # in httpd.conf
    DocumentRoot "/usr/local/htdocs"

    # load module
    PerlLoadModule Apache2::Layer

    # enable layers for whole server
    EnableDocumentRootLayers On

    # disable location strip
    DocumentRootLayersStripLocation Off

    # paths are relative to DocumentRoot
    DocumentRootLayers layered/christmas layered/promotions

    <VirtualHost *:80>
        ...
        # layers enabled for this vhost
    </VirtualHost>

    <VirtualHost *:80>
        ...
        DocumentRoot "/usr/local/vhost2"

        # disabled by default
        EnableDocumentRootLayers Off

        <LocationMatch "\.png$">
            # layer images only
            EnableDocumentRootLayers On
            DocumentRootLayers images_v3 images_v2
        </LocationMatch>


        <Location "/images">
            DocumentRootLayersStripLocation On
        </Location>

        <Location "/images/company1">
            DocumentRootLayers company1/images default/images
        </Location>

        <Location "/images/company2">
            DocumentRootLayers company2/images default/images
        </Location>

    </VirtualHost>

    <VirtualHost *:80>
        ...
        PerlOptions +MergeHandlers
        PerlTransHandler My::Other::Handler
    </VirtualHost>

=head1 DESCRIPTION

Create multiple layers to allow incremental content modifications.

If file was found in layered directory it will be used instead of one from
C<DocumentRoot>.

Loaded module adds itself as C<PerlTransHandler> and
C<PerlMapToStorageHandler>, so please remember to use

    PerlOptions +MergeHandlers

if you want to define your own handlers for those phases.

=head1 DIRECTIVES

L<Apache2::Layer> needs to be loaded via C<PerlLoadModule> due to use of
following directives:

=head2 EnableDocumentRootLayers

    Syntax:   EnableDocumentRootLayers On|Off
    Default:  EnableDocumentRootLayers Off
    Context:  server config, virtual host, <Location*

Enable use of L<"DocumentRootLayers">.

=head2 DocumentRootLayersStripLocation

    Syntax:   DocumentRootLayersStripLocation On|Off
    Default:  DocumentRootLayersStripLocation On
    Context:  server config, virtual host, <Location*

Remove the path specified in E<lt>LocationE<gt>, E<lt>LocationMatchE<gt> from
the URI before searching for layered file.

That allows to simplify the file hieratchy tree, eg.  

    <Location "/images">
        DocumentRootLayersStripLocation On
    </Location>

    <Location "/images/company1">
        DocumentRootLayers company1/images default/images
    </Location>

    <Location "/images/company2">
        DocumentRootLayers company2/images default/images
    </Location>

for following requests:

    /images/company1/headers/top.png 

    /images/company2/headers/top.png 

those paths would be searched:

   company1/images/headers/top.png default/images/headers/top.png 

   company2/images/headers/top.png default/images/headers/top.png 

but with C<DocumentRootLayersStripLocation Off>:

   company1/images/images/company1/headers/top.png default/images/images/company1/headers/top.png

   company2/images/images/company2/headers/top.png default/images/images/company2/headers/top.png

=head2 DocumentRootLayers

    Syntax:   DocumentRootLayers dir-path1 [dir-path2 ... dir-pathN]
    Context:  server config, virtual host, <Location*

Specify content layers to be used on top of C<DocumentRoot>.

If the I<dir-path*> is not absolute it is assumed to be relative to
C<DocumentRoot>.

Directories are searched in order specified and first one containing the file
is used.

If file does not exists in any of them module falls back to C<DocumentRoot>.

=head1 SEE ALSO

Module was created as a result of upgrade existing application from mod_perl1
to mod_perl2 and is a replacement for L<Apache::Layer>.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

