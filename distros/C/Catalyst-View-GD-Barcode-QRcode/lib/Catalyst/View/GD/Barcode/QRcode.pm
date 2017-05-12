package Catalyst::View::GD::Barcode::QRcode;

use strict;
use warnings;

our $VERSION = '0.10';

use base qw(Catalyst::View);

use MRO::Compat;
use GD::Barcode::QRcode;

__PACKAGE__->mk_accessors(qw( ecc version module_size img_type ));

sub new {
    my ($class, $c, $args) = @_;
    my $self = $class->next::method($c, $args);

    $self->ecc($args->{ecc});
    $self->version($args->{version});
    $self->module_size($args->{module_size});
    $self->img_type($args->{img_type});

    return $self
}

sub process {
    my ($self, $c) = @_;
    
    my $conf = $c->stash->{qrcode_conf} || $self->config;

    my $ecc = $conf->{ecc} || $self->ecc || 'M';
    my $version = $conf->{version} || $self->version || 4;
    my $module_size = $conf->{module_size} || $self->module_size || 1;
    my $img_type = $conf->{img_type} || $self->img_type || 'png';

    my $text = $c->stash->{qrcode};
    my $qrcode = GD::Barcode::QRcode->new(
        $text, {
            Ecc => $ecc, 
            Version => $version, 
            ModuleSize => $module_size
        }
    );
    my $gd = $qrcode->plot();
    $c->res->content_type("image/$img_type");
    $c->res->body($gd->$img_type());
}

1;
__END__

=head1 NAME

Catalyst::View::GD::Barcode::QRcode - GD::Barcode::QRcode View Class


=head1 SYNOPSIS

Create a View class using the helper

    script/myapp_create.pl view QRcode GD::Barcode::QRcode

Configure variables in your application class

    package MyApp;

    MyApp->config(
        'View::QRcode' => {
            ecc         => 'M',
            version     => 4,
            module_size => 1,
            img_type    => 'png'
        },
    );

Or using YAML config file

    View::QRcode:
        ecc: 'M'
        version: 4
        module_size: 1
        img_type: 'png'

Add qrcode action to forward to the View on MyApp::Controller::Root

    sub qrcode : Local {
        my ( $self, $c ) = @_;
        $c->stash->{qrcode} = 'http://www.cpan.org';
        $c->forward( $c->view( 'QRcode' ) );
    }

Or change configuration dynamically

    sub qrcode : Local {
        my ( $self, $c ) = @_;
        $c->stash( 
            qrcode => 'http://www.cpan.org', 
            qrcode_conf => {
                ecc         => 'Q',
                version     => 5,
                module_size => 3,
                img_type    => 'gif',
            },
        );

        $c->forward( $c->view( 'QRcode' ) );
    }

=head1 DESCRIPTION

Catalyst::View::GD::Barcode::QRcode is the Catalyst view class for GD::Barcode::QRcode, create QRcode barcode image with GD.

=head2 CONFIG VARIABLES

=over 4

=item ecc

ECC mode.  Select 'M', 'L', 'H' or 'Q' (Default = 'M').

=item version

Version ie. size of barcode image (Default = 4).

=item module_size

Size of modules (barcode unit) (Default = 1).

=item img_type 

Type of barcode image (Default = 'png').

=back


=head1 AUTHOR

Hideo Kimura C<< <<hide@hide-k.net>> >>


=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


