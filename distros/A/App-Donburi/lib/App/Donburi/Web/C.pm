package App::Donburi::Web::C;
use strict;
use warnings;

use App::Donburi::Util;
use String::CamelCase qw/decamelize/;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/req/],
);

use Text::Xslate;

our $tx;

sub render {
    my ($self, $tmpl, $vars) = @_;
    $vars ||= {};

    my $content = xslate()->render($tmpl, $vars);

    utf8::encode($content);

    return [
        200,
        [   'Content-Type'   => 'text/html',
            'Content-Length' => length($content)
        ],
        [$content]
    ];
}

sub auto_render {
    my ( $self, $action, $vars ) = @_;

    ( my $class = ref($self) ) =~ s/^@{[__PACKAGE__]}:://;
    my $tmpl = join( '/', map { decamelize($_) } split( '::', $class ) );

    return $self->render("$tmpl/$action.tx", $vars);
}

sub redirect {
    my ( $self, $path ) = @_;

    return [ 302, ['Location' => $path ], [''] ];
}

1;
