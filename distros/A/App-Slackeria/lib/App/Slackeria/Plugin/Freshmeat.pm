package App::Slackeria::Plugin::Freshmeat;

use strict;
use warnings;
use 5.010;

use parent 'App::Slackeria::Plugin';

use WWW::Freshmeat;

our $VERSION = '0.12';

sub new {
	my ( $obj, %conf ) = @_;
	my $ref = {};
	$ref->{default} = \%conf;
	$ref->{default}->{href} //= 'http://freshmeat.net/projects/%s/';
	$ref->{fm} = WWW::Freshmeat->new( token => $conf{token} );
	return bless( $ref, $obj );
}

sub check {
	my ( $self, $res ) = @_;

	my $fp = $self->{fm}->retrieve_project( $self->{conf}->{name} );

	if ( defined $fp ) {
		return {
			data        => $fp->version(),
			description => $fp->description(),
		};
	}
	else {
		die("not found\n");
	}
}

1;

__END__

=head1 NAME

App::Slackeria::Plugin::Freshmeat - Check project on freshmeat.net

=head1 SYNOPSIS

In F<slackeria/config>

    [Freshmeat]
    token = something

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This plugin queries a project and its version on B<freshmeat.net>.

=head1 CONFIGURATION

=over

=item href

Link to point to.  Defaults to "http://freshmeat.net/projects/%s/", where %s
is replaced by the project name

=item token

Set this to your freshmeat access token (mandatory)

=back

=head1 DEPENDENCIES

Requires the WWW::Freshmeat(3pm) perl module.

=head1 BUGS AND LIMITATIONS

None known.

=head1 SEE ALSO

slackeria(1)

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
