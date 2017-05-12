package Catalyst::Plugin::HTML::Widget;

use warnings;
use strict;
use HTML::Widget;

our $VERSION = '1.1';

=head1 NAME

Catalyst::Plugin::HTML::Widget - HTML Widget And Validation Framework

=head1 SYNOPSIS

    use Catalyst qw/HTML::Widget;

    $c->widget('foo')->method('get')->action('/foo/action');

    $c->widget('foo')->element( 'Textfield', 'age' )->label('Age')->size(3);
    $c->widget('foo')->element( 'Textfield', 'name' )->label('Name')->size(60);
    $c->widget('foo')->element( 'Submit', 'ok' )->value('OK');

    $c->widget('foo')->constraint( 'Integer', 'age' )->message('No integer.');
    $c->widget('foo')->constraint( 'All', 'age', 'name' )
        ->message('Missing value.');

    $c->widget( HTML::Widget->new('foo') );

    $c->widget('foo')->indicator('some_field');

    my $result = $c->widget('foo')->process;
    my $result = $c->widget('foo')->process($query);

    my $result = $c->widget_result('foo');      #  with query params

=head1 DESCRIPTION

HTML Widget And Validation Framework.

=head1 METHODS

=head2 $c->widget( $name, $widget )

Returns a L<HTML::Widget>. If no object exists, it will be created on the
fly. The widget name defaults to C<_widget>.

=cut

sub widget {
    my ( $c, $name, $widget ) = @_;
    $widget = $name if ref $name;
    $c->{_widget} ||= {};
    $name ||= $widget ? $widget->name ? $widget->name : '_widget' : '_widget';
    $c->{_widget}->{$name} ||= ( $widget || HTML::Widget->new($name) );
    return $c->{_widget}->{$name};
}

=head2 $c->widget_result($name)

Returns a L<HTML::Widget::Result> object, processed B<with> query and upload
parameters.

=cut

sub widget_result {
    my $c = shift;
    my $w = $c->widget(@_);

    my $result;
    my $indi = $w->indicator;
    $indi = ref $indi ? $indi : sub { $c->request->param( $w->indicator ) };
    if ( $indi->() ) {
        local $w->{query}   = $c->request;
        local $w->{uploads} = $c->request->uploads;
        $result = $w->result;
    }
    else {
        local $w->{query}   = undef;
        local $w->{uploads} = undef;
        $result = $w->result;
    }

    return $result;
}

=head1 SEE ALSO

L<Catalyst>, L<HTML::Widget>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
