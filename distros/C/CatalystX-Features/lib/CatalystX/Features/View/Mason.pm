package CatalystX::Features::View::Mason;
$CatalystX::Features::View::Mason::VERSION = '0.26';
use strict;
use warnings;
use base 'Catalyst::View::Mason';

sub new {
    my ( $self, $app, $arguments ) = @_;

    $arguments->{comp_root} = [ [ 'root' => $app->config->{root} ] ];

    foreach my $feature ( $app->features->list ) {

        my $prefix = $app->features->config->{ $feature->name }->{mason_prefix} || '';

        if ( ref $prefix eq 'ARRAY' ) {
			my $cnt;
            for ( @{$prefix} ) {

				$cnt++;
				my $id = $feature->id . "-$cnt";

                push(
                    @{ $arguments->{comp_root} },
                    [
                        $id => Path::Class::dir( $feature->root, $prefix )->stringify
                    ]
                );
            }
        }
        else {
                push(
                    @{ $arguments->{comp_root} },
                    [
                        $feature->id => Path::Class::dir( $feature->root, $prefix )->stringify
                    ]
                );

        }
    }
    $self->next::method( $app, $arguments );
}

=head1 NAME

CatalystX::Features::View::Mason - Makes View::Mason know about features

=head1 VERSION

version 0.26

=head1 SYNOPSIS

	package MyApp::View::Mason;
	use base 'CatalystX::Features::View::Mason';

=head1 DESCRIPTION

Use this base class to make View::Mason support Mason in your features. 

Just make C<MyApp::View::Mason> inherit from this class to put mason files 
under your feature's C</root>.

=head1 CONFIG

=head2 mason_prefix

Appended to the feature C</root> dir. 

	<CatalystX::Features>
		<simple.feature>
			mason_prefix mason
			mason_prefix more_mason
		</simple.feature>
	</CatalystX::Features>

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
