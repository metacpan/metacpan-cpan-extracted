#!/usr/bin/perl
use v5.26;

package App::url;

our $VERSION = '1.004';

use Carp qw(carp);
use Mojo::Base -strict, -signatures;
use Mojo::URL;
use String::Sprintf;

=encoding utf8

=head1 NAME

App::url - format a URL according to a sprintf-like template

=head1 SYNOPSIS

	$ url '%h' http://www.example.com/a/b/c
	www.example.com

	$ url '%H' http://www.example.com/a/b/c
	www

	$ url '%P' http://www.example.com/a/b/c
	/a/b/c

	$ url '%P' http://www.example.com/a/b/c
	/a/b/c

=head1 DESCRIPTION

Decompose the URL and reformat it according to

=head2 The formats

=over 4

=item * C<%a> - the path

=item * C<%f> - the fragment

=item * C<%h> - the hostname, with domain info

=item * C<%H> - the hostname without domain info

=item * C<%i> - the hostname in punycode

=item * C<%I> - space-separated list of IP addresses for the host

=item * C<%P> - the password of the userinfo portion

=item * C<%p> - the port

=item * C<%q> - the query string

=item * C<%s> - the scheme

=item * C<%S> - the public suffix

=item * C<%u> - the complete URL

=item * C<%U> - the username of the userinfo portion

=back

There are also some bonus formats unrelated to the URL:

=over 4

=item * C<%n> - newline

=item * C<%t> - tab

=item * C<%%> - literal percent

=back

=head2 Methods

=over 4

=item * run( TEMPLATE, ARRAY )

Format each URL in ARRAY according to TEMPLATE and return an array
reference

=back

=head1 COPYRIGHT

Copyright © 2020, brian d foy, all rights reserved.

=head1 LICENSE

You can use this code under the terms of the Artistic License 2.

=cut

no warnings 'uninitialized';

# $w - width of field
# $v - value that corresponds to position in template
# $V - list of all values
# $l - letter
my $formatter = String::Sprintf->formatter(
	a   => sub ( $w, $v, $V, $l ) { $V->[0]->path      },
	f   => sub ( $w, $v, $V, $l ) { $V->[0]->fragment  },
	h   => sub ( $w, $v, $V, $l ) { $V->[0]->host      },
	H   => sub ( $w, $v, $V, $l ) { ( split /\./, $V->[0]->host )[0] },
	i   => sub ( $w, $v, $V, $l ) { $V->[0]->ihost     },
	I   => sub ( $w, $v, $V, $l ) {
		state $rc = require Socket;
		my @addresses = gethostbyname( $V->[0]->host );
		@addresses = map { Socket::inet_ntoa($_) } @addresses[4..$#addresses];
		"@addresses";
		},
	p   => sub ( $w, $v, $V, $l ) { $V->[0]->port // do {
			if(    $V->[0]->protocol eq 'http'  ) {  80 }
			elsif( $V->[0]->protocol eq 'https' ) { 443 }
			};
	     },
	P   => sub ( $w, $v, $V, $l ) { $V->[0]->password  },
	'q' => sub ( $w, $v, $V, $l ) { $V->[0]->query     },
	's' => sub ( $w, $v, $V, $l ) { $V->[0]->protocol  },

	S   => sub ( $w, $v, $V, $l ) {
		state $rc = eval { require Net::PublicSuffixList };
		unless( $rc ) {
			carp "%${l} requires Net::PublicSuffixList\n";
			return;
			}
		state $psl = Net::PublicSuffixList->new;
		my $hash = $psl->split_host( $V->[0]->host );
		$hash->{suffix};
		},

	U   => sub ( $w, $v, $V, $l ) { $V->[0]->username  },
	u   => sub ( $w, $v, $V, $l ) { $V->[0]->to_string },

	n   => sub { "\n" },
	t   => sub { "\t" },
	'%' => sub { '%'  },

	'*' => sub ( $w, $v, $V, $l ) { warn "Invalid specifier <$l>\n" },
	);

sub run ( $class, $template, @urls ) {
	my @strings;

	foreach my $url ( @urls ) {
		push @strings, $formatter->sprintf( $template, Mojo::URL->new($url) );
		}

	return \@strings;
	}
