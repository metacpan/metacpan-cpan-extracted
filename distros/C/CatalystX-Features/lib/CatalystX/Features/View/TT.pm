package CatalystX::Features::View::TT;
$CatalystX::Features::View::TT::VERSION = '0.26';
use strict;
use warnings;
use base 'Catalyst::View::TT';
use Path::Class;

sub new {
    my ( $self, $app, $arguments ) = @_;

    $arguments->{INCLUDE_PATH} =
      ref $self->config->{INCLUDE_PATH} eq 'ARRAY'
      ? $self->config->{INCLUDE_PATH}
      : [];

    foreach my $feature ( $app->features->list ) {

        my $prefix = $app->features->config->{ $feature->name }->{tt_prefix} || '';

        if ( ref $prefix eq 'ARRAY' ) {
            for ( @{$prefix} ) {
                push(
                    @{ $arguments->{INCLUDE_PATH} },
                    Path::Class::dir( $feature->root, $_ )->stringify
                );
            }
        }
        else {
            push(
                @{ $arguments->{INCLUDE_PATH} },
                Path::Class::dir( $feature->root, $prefix )->stringify
            );
        }
    }

    $self->next::method( $app, $arguments );
}

=head1 NAME

CatalystX::Features::View::TT - Makes View::TT handle features. 

=head1 VERSION

version 0.26

=head1 SYNOPSIS

	package MyApp::View::TT;
	use base 'CatalystX::Features::View::TT';

    __PACKAGE__->config(
        TEMPLATE_EXTENSION => '.tt',
        root               => TestApp->path_to('root'),
        INCLUDE_PATH       => [ TestApp->path_to( 'root', 'src' ), ],
    );

=head1 DESCRIPTION

Use this base class to make View::TT support TT in your features. 

This class will modify C<INCLUDE_PATH>, adding the C</root> dir of each feature in the app.

=head1 CONFIG

=head2 tt_prefix

Appended to the feature C</root> dir. 

	<CatalystX::Features>
		<simple.feature>
			tt_prefix src
			tt_prefix more
		</simple.feature>
	</CatalystX::Features>

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
