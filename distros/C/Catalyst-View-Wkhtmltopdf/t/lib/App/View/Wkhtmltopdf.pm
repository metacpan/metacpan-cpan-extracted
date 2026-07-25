package App::View::Wkhtmltopdf;

use Moose;
extends 'Catalyst::View::Wkhtmltopdf';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
