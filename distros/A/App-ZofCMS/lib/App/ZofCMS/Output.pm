
package App::ZofCMS::Output;

use strict;
use warnings;
use Carp;

our $VERSION = '1.001007'; # VERSION

sub new {
    my ( $class, $config, $template ) = @_;
    my $self = bless {}, $class;
    $self->config( $config );
    $self->conf( $config->conf );
    $self->template( $template );
    return $self;
}

sub headers {
    my $self = shift;
    my $query = $self->config->query;
    if ( $query->{dir} eq '/' and $query->{page} eq '404' ) {
         return $self->config->cgi->header('text/html','404 Not Found');
    }
    return $self->config->cgi->header( -type => 'text/html', -charset => 'utf-8' );
}

sub output {
    my $self = shift;

    return $self->template->html_template->output;
}

sub config {
    my $self = shift;
    if ( @_ ) {
        $self->{ config } = shift;
    }
    return $self->{ config };
}


sub conf {
    my $self = shift;
    if ( @_ ) {
        $self->{ conf } = shift;
    }
    return $self->{ conf };
}


sub template {
    my $self = shift;
    if ( @_ ) {
        $self->{ template } = shift;
    }
    return $self->{ template };
}


1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Output - "core" part of ZofCMS - web-framework/templating system

=head1 SYNOPSIS

N/A

=head1 DESCRIPTION

This module is used internally by L<App::ZofCMS> and currently does not
provide anything "public".

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut