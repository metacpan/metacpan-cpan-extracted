package My::Module::Test;

use 5.006002;

use strict;
use warnings;

use Exporter;

our @ISA = qw{ Exporter };

use HTTP::Date;
use HTTP::Status qw{ :constants };
use Test::More 0.96;	# For subtest

our $VERSION = '0.163';

# Set the following to zero if Space Track (or any other SSL host)
# starts using a certificate that can not be verified.
use constant VERIFY_HOSTNAME => defined $ENV{SPACETRACK_VERIFY_HOSTNAME}
    ? $ENV{SPACETRACK_VERIFY_HOSTNAME}
    : 0;

our @EXPORT =		## no critic (ProhibitAutomaticExportation)
qw{
    is_error
    is_error_or_skip
    is_not_success
    is_success
    is_success_or_skip
    last_modified
    most_recent_http_response
    not_defined
    site_check
    spacetrack_user
    spacetrack_skip_no_prompt
    skip_site
    throws_exception
    VERIFY_HOSTNAME
};

use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};

use constant NO_SPACE_TRACK_ACCOUNT => 'No Space-Track account provided';

# Deliberately not localized, to prevent unwanted settings from sneaking
# in from the user's identity file.
$Astro::SpaceTrack::SPACETRACK_IDENTITY_KEY = {
    map { $_ => 1 } qw{ username password } };

my $rslt;

sub is_error {		## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    my ( $code, $name ) = splice @args, -2, 2;
    $rslt = eval { $obj->$method( @args ) };
    $rslt or do {
	@_ = ( "$name threw exception: $@" );
	goto \&fail;
    };
    @_ = ( $rslt->code() == $code, $name );
    goto &ok;
}

sub is_error_or_skip {		## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $code, $name ) = splice @args, -2, 2;
    $rslt = eval { $obj->$method( @args ) };
    $rslt
	or return fail "$name threw exception: $@";
    my $got = $rslt->code();
    __skip_if_server_error( $method, $got );
    return cmp_ok $got, '==', $code, $name;
}

sub is_not_success {	## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    my $name = pop @args;
    $rslt = eval { $obj->$method( @args ) };
    $rslt or do {
	@_ = ( "$name threw exception: $@" );
	goto \&fail;
    };
    @_ = ( ! $rslt->is_success(), $name );
    goto &ok;
}

sub is_success {	## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    my $name = pop @args;
    $rslt = eval { $obj->$method( @args ) }
	or do {
	@_ = ( "$name threw exception: $@" );
	chomp $_[0];
	goto \&fail;
    };
    $rslt->is_success() or $name .= ": " . $rslt->status_line();
    @_ = ( $rslt->is_success(), $name );
    goto &ok;
}

sub is_success_or_skip {	## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $skip = pop @args;
    $skip =~ m/ [^0-9] /smx
	and fail "Skip number '$skip' not numeric";
    my $name = pop @args;
    $rslt = eval { $obj->$method( @args ) } or do {
	fail "$name threw exception: $!" ;
	skip "$method() threw exception", $skip;
    };
    __skip_if_server_error( $method, $rslt->code(), $skip );
    ok $rslt->is_success(), $name
	or do {
	diag $rslt->status_line();
	skip "$method() failed", $skip;
    };
    return 1;
}


sub last_modified {
    $rslt
	or return;
    foreach my $hdr ( $rslt->header( 'Last-Modified' ) ) {
	return str2time( $hdr );
    }
    return;
}

sub most_recent_http_response {
    return $rslt;
}

sub not_defined {
    @_ = ( ! defined $_[0], @_[1 .. $#_] );
    goto &ok;
}

# Prompt the user. DO NOT call this if $ENV{AUTOMATED_TESTING} is set.

{
    my ( $set_read_mode, $readkey_loaded );

    BEGIN {
	eval {
	    require Term::ReadKey;
	    $set_read_mode = Term::ReadKey->can( 'ReadMode' );
	    $readkey_loaded = 1;
	    1;
	} or $set_read_mode = sub {};

	local $@ = undef;
	eval {		## no critic (RequireCheckingReturnValueOfEval)
	    require IO::Handle;
	    STDERR->autoflush( 1 );
	};
    }

    sub prompt {
	my @args = @_;
	my $opt = HASH_REF eq ref $args[0] ? shift @args : {};
	$readkey_loaded
	    or not $opt->{password}
	    or push @args, '(ECHOED)';
	print STDERR "@args: ";
	# We're a test, and we're trying to be lightweight.
	$opt->{password}
	    and $set_read_mode->( 2 );
	my $input = <STDIN>;	## no critic (ProhibitExplicitStdin)
	if ( $opt->{password} ) {
	    $set_read_mode->( 0 );
	    $readkey_loaded
		and print STDERR "\n\n";
	}
	defined $input
	    and chomp $input;
	return $input;
    }

}


# Determine whether a given web site is to be skipped.

{
    my %info;
    my %skip_site;
    BEGIN {
	%info = (
	    'celestrak.org'	=> {
		url	=> 'https://celestrak.org/',
	    },
	    'mike.mccants'	=> {
		# url	=> 'http://www.prismnet.com/~mmccants/',
		url	=> 'https://www.mmccants.org/',
	    },
	    'rod.sladen'	=> {
		url	=> 'http://www.rod.sladen.org.uk/iridium.htm',
	    },
	    'www.amsat.org'	=> {
		url	=> 'https://www.amsat.org/',
	    },
	    'www.space-track.org'	=> {
		url	=> 'https://www.space-track.org/',
		check	=> \&__spacetrack_skip,
	    }
	);

	if ( defined $ENV{ASTRO_SPACETRACK_SKIP_SITE} ) {
	    foreach my $site ( split qr{ \s* , \s* }smx,
		$ENV{ASTRO_SPACETRACK_SKIP_SITE} ) {
		exists $info{$site}{url}
		    and $skip_site{$site} = "$site skipped by user request";
	    }
	}
    }

    sub __site_to_check_uri {
	my ( $site ) = @_;
	return $info{$site}{url};
    }

    my $ua;

    sub set_skip {
	my ( $site, $skip ) = @_;
	exists $info{$site}{url}
	    or die "Programming error. '$site' unknown";
	$skip_site{$site} = $skip;
	return;
    }

    sub site_check {
	my @sites = @_;
	my @rslt = grep { defined $_ } map { _site_check( $_ ) } @sites
	    or return;
	return join '; ', @rslt;
    }

    sub _site_check {
	my ( $site ) = @_;
	exists $skip_site{$site} and return $skip_site{$site};
	my $url = __site_to_check_uri( $site ) or do {
	    my $skip = "Programming error - No known url for '$site'";
	    diag( $skip );
	    return ( $skip_site{$site} = $skip );
	};

	{
	    no warnings qw{ once };
	    $Astro::SpaceTrack::Test::SKIP_SITES
		and return ( $skip_site{$site} =
		"$site skipped: $Astro::SpaceTrack::Test::SKIP_SITES"
	    );
	}

	$ua ||= LWP::UserAgent->new(
	    agent	=> 'curl/7.77.0',
	    ssl_opts	=> { verify_hostname => VERIFY_HOSTNAME },
	);
	my $rslt = $ua->get( $url );
	$rslt->is_success()
	    or return ( $skip_site{$site} =
		"$site not available: " . $rslt->status_line() );
	if ( $info{$site}{check} and my $check = $info{$site}{check}->() ) {
	    return ( $skip_site{$site} = $check );
	}
	return ( $skip_site{$site} = undef );
    }
}

{
    my @is_server_error;

    BEGIN {
	foreach my $inx (
	    HTTP_INTERNAL_SERVER_ERROR,
	) {
	    $is_server_error[$inx] = 1;
	}
    }

    sub __skip_if_server_error {
	my ( $method, $code, $skip ) = @_;
	$is_server_error[$code]
	    or return;
	skip "$method() encountered server error $code", ( $skip || 0 ) + 1;
    }
}

sub __spacetrack_identity {
    # The following needs to be armor-plated so that a compilation
    # failure does not shut down the testing system (though maybe it
    # should!)
    local $@ = undef;
    return eval {	## no critic (RequireCheckingReturnValueOfEval)
	local @INC = @INC;
	require blib;
	blib->import();
	require Astro::SpaceTrack;
	-f Astro::SpaceTrack->__identity_file_name()
	    or return;
	# Ad-hocery. Under Mac OS X the GPG machinery seems not to work in
	# an SSH session; a dialog pops up which the originator of the
	# session has no way to respond to. If the dialog is actually
	# executed, the primary user's information gets clobbered. If
	# the identity file is not binary, we assume we don't need GPG,
	# because that is what Config::Identity assumes.
	Astro::SpaceTrack->__identity_file_is_encrypted()
	    and $ENV{SSH_CONNECTION}
	    and return;
	my $id = Astro::SpaceTrack->__spacetrack_identity();
	defined $id->{username} && defined $id->{password} &&
	    "$id->{username}/$id->{password}";
    };
    return;
}

{
    my $spacetrack_auth;

    sub __spacetrack_skip {
	my ( %arg ) = @_;
	defined $spacetrack_auth
	    or $spacetrack_auth = $ENV{SPACETRACK_USER};
	defined $spacetrack_auth
	    and $spacetrack_auth =~ m< \A [:/] \z >smx
	    and return NO_SPACE_TRACK_ACCOUNT;
	$spacetrack_auth
	    and return;
	$ENV{AUTOMATED_TESTING}
	    and return 'Automated testing and SPACETRACK_USER not set.';
	$spacetrack_auth = __spacetrack_identity()
	    and do {
	    $arg{envir}
		and $ENV{SPACETRACK_USER} = $spacetrack_auth; ## no critic (RequireLocalizedPunctuationVars)
	    return;
	};
	$arg{no_prompt}
	    and return $arg{no_prompt};
	$^O eq 'VMS' and do {
	    warn <<'EOD';

Several tests will be skipped because you have not provided logical
name SPACETRACK_USER. This should be set to your Space Track username
and password, separated by a slash ("/") character.

EOD
	    return 'No Space-Track account provided.';
	};
	warn <<'EOD';

Several tests require the username and password of a registered Space
Track user. Because you have not provided environment variable
SPACETRACK_USER, you will be prompted for this information. The password
will be echoed unless Term::ReadKey is installed and supports ReadMode.
If you leave either username or password blank, the tests will be
skipped.

If you set environment variable SPACETRACK_USER to your Space Track
username and password, separated by a slash ("/") character, that
username and password will be used, and you will not be prompted.

You may also supress prompts by setting the AUTOMATED_TESTING
environment variable to any value Perl takes as true. This is
equivalent to not specifying a username, and tests that require a
username will be skipped.

EOD

	my $user = prompt( 'Space-Track username' )
	    and my $pass = prompt( { password => 1 }, 'Space-Track password' )
	    or do {
	    $ENV{SPACETRACK_USER} = '/'; ## no critic (RequireLocalizedPunctuationVars)
	    return NO_SPACE_TRACK_ACCOUNT;
	};
	$ENV{SPACETRACK_USER} = $spacetrack_auth = "$user/$pass"; ## no critic (RequireLocalizedPunctuationVars)
	return;
    }
}

sub spacetrack_skip_no_prompt {
    my $skip;
    $ENV{SPACETRACK_TEST_LIVE}
	or plan skip_all => 'SPACETRACK_TEST_LIVE not set';
    defined( $skip = __spacetrack_skip(
	    envir	=> 1,
	    no_prompt	=> NO_SPACE_TRACK_ACCOUNT,
	)
    ) and plan skip_all => $skip;
    return;
}

sub spacetrack_user {
    __spacetrack_skip( envir => 1 );
    return;
}

sub throws_exception {	## no critic (RequireArgUnpacking)
    my ( $obj, $method, @args ) = @_;
    my $name = pop @args;
    my $exception = pop @args;
    REGEXP_REF eq ref $exception
	or $exception = qr{\A$exception};
    $rslt = eval { $obj->$method( @args ) }
	and do {
	@_ = ( "$name throw no exception. Status: " .
	    $rslt->status_line() );
	goto &fail;
    };
    @_ = ( $@, $exception, $name );
    goto &like;
}


1;

__END__

=head1 NAME

My::Module::Test - Test routines for Astro::SpaceTrack

=head1 SYNOPSIS

 use Astro::SpaceTrack;

 use lib qw{ inc };
 use My::Module::Test;

 my $st = Astro::SpaceTrack->new();

 is_success $st, fubar => 42,
     'fubar( 42 ) succeeds';

 my $resp = most_recent_http_response;
 is $resp->content(), 'XLII',
     q<fubar( 42 ) returned 'XLII'>;

=head1 DESCRIPTION

This Perl module contains testing routines for Astro::SpaceTrack. Some
of them actually perform tests, others perform whatever miscellany of
functions seemed appropriate.

Everything in this module is B<private> to the C<Astro::SpaceTrack>
package. The author reserves the right to change or revoke anything here
without notice.

=head1 SUBROUTINES

This package exports the following subroutines, all by default.

=head2 is_error

 is_error $st, fubar => 42,
     404,
     'Make sure $st->fubar( 42 ) returns a 404';

This subroutine executes the given method and tests its result code for
numeric equality to the given code.  The method is assumed to return an
HTTP::Response object. The arguments are:

  - The method's invocant
  - The method's name
  - Zero or more arguments
  - The expected HTTP status code
  - The test name

=head2 is_error_or_skip

 is_error $st, fubar => 42,
     404,
     'Make sure $st->fubar( 42 ) returns a 404';

This subroutine is like C<is_error(), but if the returned status is 500,
the test is skipped.

=head2 is_not_success

 is_not_success $st, fubar => 42,
     'Make sure $st->fubar( 42 ) fails';

This subroutine executes the given method and tests its result for
failure. The method is assumed to return an HTTP::Response object. The
arguments are:

  - The method's invocant
  - The method's name
  - Zero or more arguments
  - The test name

=head2 is_success

 is_success $st, fubar => 42,
     'Make sure $st->fubar( 42 ) succeeds';

This subroutine executes the given method and tests its result for
success. The method is assumed to return an HTTP::Response object. The
arguments are:

  - The method's invocant
  - The method's name
  - Zero or more arguments
  - The test name

=head2 is_success_or_skop

 is_success_or_skip $st, fubar => 42,
     'Make sure $st->fubar( 42 ) succeeds', 3;

This subroutine is like C<is_success>, but if a problem occurs the
number of tests given by the last argument is skipped. The skip argument
assumes that the current test is B<not> skipped. If a 500 error is
encountered, the current test B<is> skipped, and the number of tests
skipped is the skip argument plus 1.

=head2 last_modified

This subroutine returns the value of the C<Last-Modified> header from
the most recent HTTP::Respose object, as a Perl time. If there is no
HTTP::Response, or if it did not contain that header, C<undef> is
returned.

=head2 most_recent_http_response

 my $resp = most_recent_http_response;
 $resp->is_success()
     or diag $resp->status_line();

This subroutine returns the HTTP::Response object from the most-recent
test that actually generated one.

=head2 not_defined

 not_defined $resp, 'Make sure we have a response';

This subroutine performs a test which succeeds its first argument is not
defined. The second argument is the test name.

=head2 set_skip

 set_skip 'celestrak.org';
 set_skip 'celestrak.org', 'Manually skipping';

This subroutine sets or clears the skip indicator for the given site.
The first argument is the site name, which must appear on the list
supported by L<site_check|/site_check>. The second argument is optional
and represents the skip message, if any.

=head2 site_check

 site_check 'www.amsat.org', 'celestrak.org';

This subroutine tests a preselected URL on the given sites, and sets the
skip indicator appropriately. Allowed site names are:

 celestrak.org
 mike.mccants
 rod.sladen
 www.amsat.org
 www.space-track.org

=head2 spacetrack_user

If C<$ENV{SPACETRACK_USER}> is not set, this subroutine sets it to
whatever value is obtained from the identity file if available, or by
prompting the user. The environment variable is B<not> localized.

=head2 throws_exception

 is_error $st, fubar => 666,
     'The exception of the beast',
     'Make sure $st->fubar( 666 ) throws the correct exception';

This subroutine executes the given method and succeeds if the method
throws the expected exception. The arguments are:

  - The method's invocant
  - The method's name
  - Zero or more arguments
  - The expected exception
  - The test name

The exception can be specified either as a Regexp object or as a scalar.
In the latter case the scalar is expected to match at the beginning of
the exception text.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-SpaceTrack>,
L<https://github.com/trwyant/perl-Astro-SpaceTrack/issues/>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2023 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
