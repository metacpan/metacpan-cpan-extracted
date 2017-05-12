package App::Slackeria::Plugin::CPAN;

use strict;
use warnings;
use 5.010;

use parent 'App::Slackeria::Plugin';

use CPANPLUS;

our $VERSION = '0.12';

sub new {
	my ( $obj, %conf ) = @_;
	my $ref = {};
	$ref->{default} = \%conf;
	$ref->{default}->{href} //= 'http://search.cpan.org/dist/%s/';
	$ref->{cb} = CPANPLUS::Backend->new();
	return bless( $ref, $obj );
}

sub check {
	my ($self) = @_;
	my $mod = $self->{cb}->parse_module( module => $self->{conf}->{name} );

	if ($mod) {
		return { data => $mod->version(), };
	}
	else {
		die("not found\n");
	}
}

1;

__END__

=head1 NAME

App::Slackeria::Plugin::CPAN - Check module distribution on CPAN

=head1 SYNOPSIS

In F<slackeria/config>

    [CPAN]

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This plugin queries the Comprehensive Perl Archive Network and checks if it
contains a given module.  Note that its B<name> option may be a module name
(like "App::Slackeria") as well as a distribution name (like "App-Slackeria").

=head1 CONFIGURATION

None.

=head1 DEPENDENCIES

CPANPLUS(3pm).

=head1 SEE ALSO

slackeria(1)

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
