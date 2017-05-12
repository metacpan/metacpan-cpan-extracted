package App::Slackeria::Plugin::Whohas;

use strict;
use warnings;
use 5.010;

use parent 'App::Slackeria::Plugin';

our $VERSION = '0.12';

sub run_whohas {
	my ( $self, $distro, $name ) = @_;

	my $out = qx{whohas --no-threads --strict -d $distro $name};

	if ( not defined $out or $out eq q{} ) {
		die("not found\n");
	}

	$out = ( split( /\n/, $out ) )[-1];

	return {
		data => substr( $out, 51, 10 ),
		href => substr( $out, 112 ),
	};
}

1;

__END__

=head1 NAME

App::Slackeria::Plugin::Whohas - Parent for whohas-based distro check plugins

=head1 SYNOPSIS

    use parent 'App::Slackeria::Plugin::Whohas'

    sub check {
        my ($self) = @_;

        return $self->run_whohas( 'distro name', $self->{conf}->{name} );
    }

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This plugin serves as a parent for all distro plugins based on whohas.

=head1 CONFIGURATION

None.

=head1 DEPENDENCIES

whohas(1).

=head1 BUGS AND LIMITATIONS

whohas is quite fragile at times.  Also, we are parsing raw text output here,
so there's no guarantee that we actually get the right line.

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
