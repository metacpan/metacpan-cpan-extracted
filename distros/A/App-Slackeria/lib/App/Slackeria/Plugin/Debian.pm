package App::Slackeria::Plugin::Debian;

use strict;
use warnings;
use 5.010;

use parent 'App::Slackeria::Plugin';

use LWP::UserAgent;
use XML::LibXML;

our $VERSION = '0.12';

sub new {
	my ( $obj, %conf ) = @_;

	my $ref = {};

	$ref->{default} = \%conf;

	$ref->{ua} = LWP::UserAgent->new( timeout => 10 );

	return bless( $ref, $obj );
}

sub check {
	my ($self) = @_;

	my $name  = $self->{conf}->{name};
	my $dist  = $self->{conf}->{distribution} // 'sid';
	my $reply = $self->{ua}->get("http://packages.debian.org/${dist}/${name}");

	if ( not $reply->is_success ) {
		die( $reply->status_line );
	}

	$self->{conf}->{href} //= 'http://packages.debian.org/sid/%s';
	my $href = sprintf( $self->{conf}->{href}, $self->{conf}->{name} );

	my $html = $reply->decoded_content();
	my $tree = XML::LibXML->load_html(
		string            => $html,
		recover           => 2,
		suppress_errors   => 1,
		suppress_warnings => 1,
	);

	my $xp_title = XML::LibXML::XPathExpression->new('//div[@id="content"]/h1');
	my $re_package = qr{
		^ Package: \s ${name} \s
		\( (?<ver> \S+ )
		(?: \) | \s and \s others)
	}x;

	for my $node ( @{ $tree->findnodes($xp_title) } ) {
		my $text = $node->textContent;

		if ( $text =~ $re_package ) {
			return {
				data => $+{ver},
				href => $href
			};
		}
	}

	die("not found\n");
}

1;

__END__

=head1 NAME

App::Slackeria::Plugin::Debian - Check project version in Debian

=head1 SYNOPSIS

In F<slackeria/config>

    [Debian]

=head1 VERSION

version 0.12

=head1 DESCRIPTION

This plugin queries a project and its version in Debian Sid.

=head1 CONFIGURATION

=over

=item distribution

Debian Distribution to check.  Defaults to B<sid>.

=item href

Link to point to in output, %s is replaced by the project name.

Defaults to C<< http://packages.debian.org/sid/%s >>

=back

=head1 DEPENDENCIES

LWP::UserAgent(3pm), XML::LibXML(3pm).

=head1 BUGS AND LIMITATIONS

This plugin does not use an API, but simple HTML output.  It may break
anytime.

=head1 SEE ALSO

slackeria(1)

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
