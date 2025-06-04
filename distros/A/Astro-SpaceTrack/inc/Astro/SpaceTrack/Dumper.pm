package Astro::SpaceTrack::Dumper;

use 5.006002;

use strict;
use warnings;

use Carp;
use JSON;

use Astro::SpaceTrack;
use HTTP::Response;
use HTTP::Status qw{ HTTP_OK };
our @ISA = qw{ Astro::SpaceTrack };

# NOTE that these live in inc/, but so does this module, so we assume
# inc/ is already in @INC.

use Mock::LWP::UserAgent;
use My::Module::Test;

our $VERSION = '0.169';

sub new {
    my ( $class, %arg ) = @_;
    local $Mock::LWP::UserAgent::CANNED_RESPONSE_FILE = delete
    $arg{canned_response_file};
    my $self = $class->SUPER::new( %arg );
    $self->{ +__PACKAGE__ } = Mock::LWP::UserAgent::__load_data(
	optional	=> 1,
    );
    return $self;
}

sub site_check {
    my ( $self, $site ) = @_;
    my $uri = My::Module::Test::__site_to_check_uri( $site )
	or die "No check URI for site '$site'\n";
    return $self->_get_from_net( url => $uri );
}

sub _readline_complete_command_site_check {
    # my ( $self, $text, $line, $start, $cmd_line ) = @_;
    my ( $self, $text ) = @_;
    my @sites = My::Module::Test::__site_codes();
    $text eq ''
	and return @sites;
    my $re = qr/ \A \Q$text\E /smx;
    return grep { $_ =~ $re } @sites;
}

sub request {
    my ( $self, $method, $uri ) = @_;
    defined $uri
	or ( $method, $uri ) = ( GET => $method );
    return $self->_get_from_net(
	method	=> uc $method,
	url	=> $uri,
    );
}

{
    my $json;
    my $keep;

    # Accessed via address space scan in _list_censors()
    sub _censor_json {	## no critic (ProhibitUnusedPrivateSubroutines)
	my ( $data ) = @_;
	$data =~ m/ \A \s* [[] \s* [{] .* [}] \s* []] \s* \z /smx
	    or return;
	$json ||= JSON->new()->utf8()->pretty()->canonical();
	$keep ||= {
	    map { $_ => 1 } qw{
		COMMENT
		COMMENTCODE
		COUNTRY
		DECAY
		FILE
		INTLDES
		LAUNCH
		LAUNCH_NUM
		LAUNCH_PIECE
		LAUNCH_YEAR
		NORAD_CAT_ID
		OBJECT_ID
		OBJECT_NAME
		OBJECT_NUMBER
		OBJECT_TYPE
		RCSVALUE
		SATNAME
		SITE
		TLE_LINE0
		TLE_LINE1
		TLE_LINE2
	    }
	};
	my $a = $json->decode( $data );
	foreach my $item ( @{ $a } ) {
	    foreach my $key ( keys %{ $item } ) {
		$keep->{$key}
		    or delete $item->{$key};
	    }
	    defined $item->{TLE_LINE1}
		and $item->{TLE_LINE1} =~ s/
		    (?: \A | (?<= [\r\n] ) )
		    ( 1 [\s0-9]{6}U \s )
		    [^\r\n]*
		/${1}First line of data/smxg;
	    defined $item->{TLE_LINE2}
		and $item->{TLE_LINE2} =~ s/
		    (?: \A | (?<= [\r\n] ) )
		    ( 2 [\s0-9]{6} \s )
		    [^\r\n]*
		/${1}Second line of data/smxg;
	}
	return $json->encode( $a );
    }
}

# Accessed via address space scan in _list_censors()
sub _censor_tle {	## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $data ) = @_;
    $data =~ s/
	(?: \A | (?<= [\r\n] ) )
	( 1 [\s0-9]{6}U \s )
	[^\r\n]*
    /${1}First line of data/smxg
	or return;
    $data =~ s/
	(?: \A | (?<= [\r\n] ) )
	( 2 [\s0-9]{6} \s )
	[^\r\n]*
    /${1}Second line of data/smxg
	or return;
    return $data;
}

{
    my $censors;
    my $json;

    sub __dump_response {
	my ( $self, $resp ) = @_;

	my $rqst = $resp->request()
	    or return;

	my $method = $rqst->method();
	my $url = $rqst->url();

	$censors ||= _list_censors();
	my $content = $resp->content();
	foreach my $code ( @{ $censors } ) {
	    defined( my $revised = $code->( $content ) )
		or next;
	    $content = $revised;
	    last;
	}
	my @data = (
	    $resp->code(),
	    $resp->message(),
	    [ 
		_dump_header_item( $resp, 'Content-Type' ),
		_dump_header_item( $resp, 'Set-Cookie',
		    "chocolatechip=This bears no relation to any cookie set by Space Track; path=/; domain=www.space-track.org",
		),
		_dump_header_item( $resp, 'Status' ),
	    ],
	    $content,
	);

	Mock::LWP::UserAgent::__modify_data(
	    $self->{ +__PACKAGE__ }, $url, $method, \@data );

	return;
    }
}

sub list {
    my ( $self ) = @_;
    my $data = $self->{ +__PACKAGE__ }{data};
    my @content;
    foreach my $url ( sort keys %{ $data } ) {
	foreach my $method ( sort keys %{ $data->{$url} } ) {
	    push @content, "$method $url\r\n";
	}
    }
    return HTTP::Response->new(
	HTTP_OK,
	undef,
	undef,
	join( '', @content ),
    );
}

sub _dump_header_item {
    my ( $resp, $name, $override ) = @_;
    my @value = $resp->header( $name )
	or return;
    defined $override
	and return ( $name => $override );
    @value > 1
	and return ( $name => \@value );
    return ( $name => $value[0] );
}

# Return an array of code references to all the methods named
# '_censor_'. If called in scalar context, return a reference to the
# array.
sub _list_censors {
    my @censors;
    my $name_space = __PACKAGE__ . '::';
    my $symbol_table;
    {
	no strict qw{ refs };
	$symbol_table = { %$name_space };
    }
    foreach my $symbol ( sort keys %{ $symbol_table } ) {
	$symbol =~ m/ \A _censor_ /smx
	    or next;
	my $code = __PACKAGE__->can( $symbol )
	    or next;
	push @censors, $code;
    }
    return wantarray ? @censors : \@censors;
}

1;

__END__

=head1 NAME

Astro::SpaceTrack::Dumper - Dump HTTP responses for replay during testing

=head1 SYNOPSIS

The following code must be run from the Astro-SpaceTrack base directory:

 use lib 'inc';
 use Astro::SpaceTrack::Dumper;

 my $st = Astro::SpaceTrack::Dumper->new();
 $st->shell( @ARGV );

=head1 DESCRIPTION

This Perl class is private to the C<Astro-SpaceTrack> distribution, and
will be modified or retracted without notice. Any documentation is for
the benefit of the author.

This Perl subclass of L<Astro::SpaceTrack|Astro::SpaceTrack> overrides
the parent class' code to dump L<HTTP::Response|HTTP::Response> objects.
Instead of dumping them to standard out, they are written to files
which C<Mock::LWP::UserAgent> can read to simulate Space Track queries
without actually making them.

=head1 METHODS

This class supports the following protected methods:

=head2 __dump_response

 $st->__dump_response( $resp );

This override of the superclass' method adds the given response to the
C<Mock::LWP::UserAgent> data file.

=head1 ATTRIBUTES

This class has no additional attributes.

=head1 SEE ALSO

L<Astro::SpaceTrack|Astro::SpaceTrack>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
