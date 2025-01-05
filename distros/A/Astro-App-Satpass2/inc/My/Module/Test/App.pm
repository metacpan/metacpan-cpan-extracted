package My::Module::Test::App;

use 5.008;

use strict;
use warnings;

use Exporter ();
our @ISA = qw{ Exporter };

use Carp;

use Cwd qw{ abs_path };
use Getopt::Long 2.39 ();
use POSIX qw{ strftime };
use Scalar::Util 1.26 qw{ blessed };
use Test2::V0;
use Test2::Util::Table qw{ table };

use constant CODE_REF	=> ref sub {};
use constant REGEXP_REF	=> ref qr{};

our @EXPORT = qw{
    any_greg_time_gm
    any_greg_time_local
    call_m
    call_m_result
    check_access
    check_datetime_timezone_local
    dependencies_table
    dt_greg_time_gm
    dt_greg_time_local
    dump_date_manip
    dump_date_manip_init
    dump_zones
    dump_zones_init
    execute
    invocant
    klass
    load_or_skip
    normalize_path
    same_path
    setup_app_mocker
    FALSE
    INSTANTIATE
    TRUE
};

{
    local $@ = undef;

    use constant HAVE_DATETIME => eval {
	require DateTime;
	require DateTime::TimeZone;
	1;
    } || 0;
}

BEGIN {
    # If I should need to write a test that uses a dirty environment (or
    # at least wants something in $ENV{TZ}) the plan is to handle it via
    # the import mechanism. See @EXPORT_FAIL, which is good back to at
    # least 5.12. Except this may be causing problems with CPAN Testers
    # machines set up correctly for zones other than their default.
    # delete $ENV{TZ};

    # Note that we have to load Astro::App::Satpass2 this way because we
    # need to clean up the environment before we do the load.
    require Astro::App::Satpass2;
    Astro::App::Satpass2->import();
}

my $app = 'Astro::App::Satpass2';

use constant FALSE => sub {
    shift;
    $_[0] = !$_[0];
    goto &ok;
};

use constant INSTANTIATE => sub {
    shift;
    $app = $_[0];
    goto &ok;
};

use constant TRUE => sub {
    shift;
    goto &ok;
};

if ( HAVE_DATETIME ) {
    *any_greg_time_gm = \&dt_greg_time_gm;
    *any_greg_time_local = \&dt_greg_time_local;
} else {
    require Astro::Coord::ECI::Utils;
    Astro::Coord::ECI::Utils->VERSION( 0.112 );
    *any_greg_time_gm = \&Astro::Coord::ECI::Utils::greg_time_gm;
    *any_greg_time_local = \&Astro::Coord::ECI::Utils::greg_time_local;
}

sub invocant {
    return $app;
}

sub check_access {
    my ( $url ) = @_;

    eval {
	require LWP::UserAgent;
	1;
    } or return 'Can not load LWP::UserAgent';

    my $ua = LWP::UserAgent->new()
	or return 'Can not instantiate LWP::UserAgent';

    my $rslt = $ua->get( $url )
	or return "Can not get $url";

    $rslt->is_success or return $rslt->status_line;

    return;
}

sub check_datetime_timezone_local {
    local $@ = undef;
    eval {
	require DateTime;
	require DateTime::TimeZone;
	1;
    } or return 1;
    return eval {
	DateTime::TimeZone->new( name => 'local' );
	1;
    };
}

sub klass {
    ( $app ) = @_;
    return;
}

sub _dtz_to_epoch {
    my ( $sec, $min, $hr, $day, $mon, $yr, $zone ) = @_;
    $mon += 1;
    ( my $nano, $sec ) = POSIX::modf( $sec );
    $nano *= 1_000_000_000;
    return DateTime->new(
	year	=> $yr,
	month	=> $mon,
	day	=> $day,
	hour	=> $hr,
	minute	=> $min,
	second	=> $sec,
	nanosecond	=> $nano,
	time_zone	=> $zone,
    )->epoch();
}

{
    my $tz_utc;

    sub dt_greg_time_gm {
	my ( $sec, $min, $hr, $day, $mon, $yr ) = @_;
	$tz_utc ||= DateTime::TimeZone->new( name => 'UTC' );
	return _dtz_to_epoch( $sec, $min, $hr, $day, $mon, $yr, $tz_utc );
    }
}

{
    my $tz_local;

    sub dt_greg_time_local {
	my ( $sec, $min, $hr, $day, $mon, $yr ) = @_;
	$tz_local ||= DateTime::TimeZone->new( name => 'local' );
	return _dtz_to_epoch( $sec, $min, $hr, $day, $mon, $yr, $tz_local );
    }
}

{
    my $dumped;

    sub dump_date_manip {
	my ( $time_tested ) = @_;

	diag '  difference: ', $time_tested - call_m_result();

	$dumped++
	    and return;

	my $vers = Date::Manip->VERSION();

	diag '';

	diag "Date::Manip version: $vers";

	$vers =~ s/ _ //smxg;

	if ( $vers >= 6 ) {

	    diag 'Date::Manip superclasses: ', join ', ', @Date::Manip::ISA;

	    if ( Date::Manip->isa( 'Date::Manip::DM5' ) ) {
		no warnings qw{ once };
		diag '$Cnf{Language}: ', $Date::Manip::DM5::Cnf{Language};
	    }

	}

	if ( my $code = Date::Manip->can( 'Date_TimeZone' ) ) {
	    diag 'Date_TimeZone = ', $code->();
	} else {
	    diag 'Date_TimeZone unavailable';
	}

	if ( $app->isa( 'Astro::App::Satpass2::ParseTime' ) ) {
	    # Only displays for Date::Manip v6 interface
	    $app->can( 'dmd_zone' )
		and diag 'dmd_zone = ', $app->dmd_zone();
	    $app->can( '__epoch_offset' )
		and diag 'epoch_offset = ', $app->__epoch_offset();
	}

	{
	    local $ENV{DATE_MANIP_DEBUG} = 1;
	    local $@ = undef;
	    eval {
		require Date::Manip::TZ;
		my $text;
		open my $fh, '>', \$text;
		local *STDOUT = $fh;
		Date::Manip::TZ->new();
		close $fh;
		diag $text;
	    };
	}

	goto &__dump_zones;
    }

    sub dump_date_manip_init {
	$dumped = undef;
	return;
    }
}

{
    my $dumped;

    sub dump_zones {
	my ( $time_tested ) = @_;

	diag '  difference: ', $time_tested - call_m_result();

	$dumped++
	    and return;

	goto &__dump_zones;
    }

    sub dump_zones_init {
	$dumped = undef;
	return;
    }
}

sub __dump_zones {
    my ( $time_tested ) = @_;

    if ( eval { require DateTime; 1; } ) {
	diag 'Have DateTime ', DateTime->VERSION();
    } else {
	diag 'DateTime not available';
    }

    if ( eval { require DateTime::TimeZone; 1; } ) {
	diag 'Have DateTime::TimeZone ', DateTime::TimeZone->VERSION();
	my $dt_zone = DateTime::TimeZone->new( name => 'local')->name();
	diag "DateTime::TimeZone is '$dt_zone'";
    } else {
	diag 'DateTime::TimeZone not available';
    }

    diag strftime(
	q<POSIX zone: %z ('%Z')>, localtime( $time_tested || 0 ) );

    eval {
	no strict qw{ refs };
	my $class = defined $Time::y2038::VERSION ? 'Time::y2038' :
	    'Time::Local';
	diag sprintf 'Time to epoch uses %s %s', $class,
	    $class->VERSION();
    };

    diag '$main::TZ is ', defined $main::TZ ? "'$main::TZ'" : 'undef';

    diag q<$ENV{TZ} = >, defined $ENV{TZ} ? "'$ENV{TZ}'" : 'undef';

    return;
}

sub execute {	## no critic (RequireArgUnpacking)
    splice @_, 0, 0, 'execute';
    goto &call_m;
}

{
    my $go;

    # CAVEAT:
    #
    # Unfortunately as things currently stand, the version needs to be
    # maintained three places:
    # - lib/Astro/App/Satpass2/Utils.pm
    # - inc/My/Module/Recommend.pm
    # - inc/My/Module/Test/App.pm
    # These all need to stay the same. Sigh.
    # Any such should be in xt/author/consistent_module_versions.t

    my %version = (
	'DateTime::Calendar::Christian'	=> 0.06,
    );

    # Expose the module version so we can test for consistent definition.
    sub __module_version {
	my $module = $_[-1];
	exists $version{$module}
	    or confess "Bug - Module $module has no defined version";
	return $version{$module};
    }

    # skip() actually jumps out via 'goto SKIP', but Perl::Critic does
    # not know this.
    sub load_or_skip {	## no critic (RequireFinalReturn)
	my @arg = @_;
	$go ||= Getopt::Long::Parser->new();
	my %opt;
	$go->getoptionsfromarray( \@arg, \%opt,
	    qw{ import=s@ noimport! } );
	my ( $module, $skip ) = @arg;
	my $v = $version{$module};
	local $@ = undef;
	my $caller = caller;
	eval "require $module; 1"
	    and eval {
	    $v and $module->VERSION( $v );
	    my @import = map { split qr{ \s* , \s* }smx }
		@{ $opt{import} || [] };
	    # We rely on the following statement always being true
	    # unless the import is requested and fails.
	    $opt{noimport}
		or eval "package $caller; $module->import( qw{ @import } ); 1";
	} and return;
	my $display = $v ? "$module $v" : $module;
	$display .= ' not available';
	$skip
	    and $skip =~ m/ \A all \z /smxi
	    and skip_all $display;
	skip $display, $skip;
    }
}

{
    my $got;

    sub call_m {	## no critic (RequireArgUnpacking)
	my ( $method, @args ) = @_;
	my ( $want, $title ) = splice @args, -2;
	if ( eval { $got = $app->$method( @args ); 1 } ) {

	    if ( CODE_REF eq ref $want ) {
		@_ = ( $want, $got, $title );
		goto &$want;
	    }

	    foreach ( $want, $got ) {
		defined and not ref and chomp;
	    }
	    @_ = ( $got, $want, $title );
	    REGEXP_REF eq ref $want ? goto &like : goto &is;
	} else {
	    $got = $@;
	    chomp $got;
	    defined $want or $want = 'Unexpected error';
	    REGEXP_REF eq ref $want
		or $want = qr<\Q$want>smx;
	    @_ = ( $got, $want, $title );
	    goto &like;
	}
    }

    sub call_m_result {
	return $got;
    }
}

{
    my $kind_hdr = {
	configure_requires	=> 'CONFIGURE REQUIRES',
	build_requires		=> 'BUILD REQUIRES',
	test_requires		=> 'TEST REQUIRES',
	requires		=> 'RUNTIME REQUIRES',
	optional_modules	=> 'OPTIONAL MODULES',
    };

    sub dependencies_table {
	require My::Module::Meta;
	my @tables = ( '' );

	{
	    my @perls = ( My::Module::Meta->requires_perl(), $] );
	    foreach ( @perls ) {
		$_ = sprintf '%.6f', $_;
		$_ =~ s/ (?= ... \z ) /./smx;
		$_ =~ s/ (?<= \. ) 00? //smxg;
	    }
	    push @tables, table(
		header	=> [ qw{ PERL REQUIRED INSTALLED } ],
		rows	=> [ [ perl => @perls ] ],
	    );
	}

	foreach my $kind ( qw{ configure_requires build_requires test_requires requires optional_modules }
	) {
	    my $code = My::Module::Meta->can( $kind )
		or next;
	    my $req = $code->();
	    my @rows;
	    foreach my $module ( sort keys %{ $req } ) {
		( my $file = "$module.pm" ) =~ s| :: |/|smxg;
		# NOTE that an alternative implementation here is to use
		# Module::Load::Conditional (core since 5.10.0) to find the
		# installed modules, and then MM->parse_version() (from
		# ExtUtils::MakeMaker) to find the version without actually
		# loading the module.
		my $installed;
		eval {
		    require $file;
		    $installed = $module->VERSION();
		    defined $installed
			or $installed = 'undef';
		    1;
		} or $installed = 'not installed';
		push @rows, [ $module, $req->{$module}, $installed ];
	    }

	    my $hdr = $kind_hdr->{$kind};
	    defined $hdr
		or $hdr = uc $kind;
	    push @tables, table(
		header	=> [ $hdr, 'REQUIRED', 'INSTALLED' ],
		rows	=> \@rows,
	    );
	}

	return @tables;
    }
}

{
    my $win32 = sub {
	my ( $path ) = @_;
	$path =~ tr{\\}{/};
	return $path;
    };

    my %normalizer = (
	dos		=> $win32,
	dragonfly	=> sub {
	    my ( $path ) = @_;
	    $path =~ s{ / \z }{}smx;
	    return $path;
	},
	MSWin32		=> $win32,
	os2		=> $win32,
    );

    sub normalize_path {
	my ( $path ) = @_;
	$path = abs_path( $path );
	my $code = $normalizer{$^O}
	    or return $path;
	return $code->( $path );
    }
}

{

    my %no_stat = map { $_ => 1 } qw{ dos MSWin32 os2 riscos VMS };

    sub same_path {
	my ( $got, $want, $name ) = @_;
	$got = normalize_path( $got );
	$want = normalize_path( $want );
	if ( $want eq $got || $no_stat{$^O} ) {
	    @_ = ( $got, $want, $name );
	    goto &is;
	}
	my $got_inode = ( stat $got )[1];
	my $want_inode = ( stat $want )[1];
	@_ = ( $got_inode, '==', $want_inode, $name );
	goto &cmp_ok;
    }
}

sub setup_app_mocker {
    return mock 'Astro::App::Satpass2' => (
    override	=> [
	new	=> sub {
	    my ( $class, %self ) = @_;
	    return bless \%self, $class;
	},
	get	=> sub { return $_[0]{$_[1]}; },
	set	=> sub {
	    my ( $self, @args ) = @_;
	    while ( @args ) {
		my ( $name, $value ) = splice @args, 0, 2;
		$self->{$name} = $value;
	    }
	    return $self;
	},
    ],
);
}

sub Astro::App::Satpass2::__TEST__frame_stack_depth {
    my ( $self ) = @_;
    return scalar @{ $self->{frame} };
}

sub Astro::App::Satpass2::__TEST__is_exported {
    my ( $self, $name ) = @_;
    return exists $self->{exported}{$name} ? 1 : 0;
}

#	$string = $self->__raw_attr( $name, $format )

#	Fetches the raw value of the named attribute, running it through
#	the given sprintf format if that is not undef. THIS IS AN
#	UNSUPPORTED INTERFACE USED FOR TESTING ONLY.

sub Astro::App::Satpass2::__TEST__raw_attr {
    my ( $self, $name, $format ) = @_;
    defined $format or return $self->{$name};
    return sprintf $format, $self->{$name};
}

1;

__END__

=head1 NAME

My::Module::Test::App - Help test Astro::App::Satpass2;

=head1 SYNOPSIS

 use lib qw{ inc };
 use My::Module::Test::App;
 
 ... set location ...
 
 execute 'almanac 20100401T000000Z', <<'EOD', 'Test almanac'
 ... expected almanac output ...
 EOD

=head1 DESCRIPTION

This entire module is private to the C<Astro-App-Satpass2> distribution.
It may be changed or retracted without notice. This documentation is for
the convenience of the author.

This module exports subroutines to help test the
L<Astro::App::Satpass2|Astro::App::Satpass2> class. It works by holding
an C<Astro::App::Satpass2> object. The exported subroutines generally
perform tests on this object.

=head1 SUBROUTINES

This module exports the following subroutines:

=head2 any_greg_time_gm

If the L<DateTime|DateTime> module can be loaded, this subroutine is an
alias for L<dt_greg_time_gm()|/dt_greg_time_gm>. Otherwise, it is an
alias for
L<Astro::Coord::ECI::Utils::greg_time_gm()|Astro::Coord::ECI::Utils>.

=head2 any_greg_time_local

If the L<DateTime|DateTime> module can be loaded, this subroutine is an
alias for L<dt_greg_time_local()|/dt_greg_time_local>. Otherwise, it is an
alias for
L<Astro::Coord::ECI::Utils::greg_time_local()|Astro::Coord::ECI::Utils>.

=head2 check_access

 SKIP: {
     my $tests = 2;
     my $rslt;
     $rslt = check_access 'http://celestrak.com/'
         and skip $rslt, $tests
     ... two tests ...
 }

This subroutine checks access to the given URL. It returns a false value
if it has access to the URL, or an appropriate message otherwise.
Besides the usual reasons of net connectivity or host availability, it
may fail because L<LWP::UserAgent|LWP::UserAgent> can not be loaded.

=head2 check_datetime_timezone_local

 check_datetime_timezone_local()
     or skip 'Can not create local zone object', 1;

This method is intended to determine whether tests involving the local
time zone should be run. It returns true unless C<DateTime::TimeZone>
can be loaded but the requisite object can not be instantiated. The
assumption is that if C<DateTime::TimeZone> can not be loaded we are
using some other mechanism (probably POSIX) to determine the local zone.

This is really to help us to skip specific tests which fail under
Cygwin. C<DateTime::TimeZone> assumes Cygwin is a Unix system, but I am
seeing test failures thre, where presumably the Windows machinery would
come up with a time zone. We assume the user who really wants to use
this machinery will sort things out.

=head2 dependencies_table

 diag $_ for dependencies_table;

This subroutine builds and returns depencency tables. The heavy lifting
is done by C<table()> in L<Test2::Util::Table|Test2::Util::Table>. The
return is pretty much raw output from the C<table()> subroutine -- that
is, lines of text without terminating C<"\n"> characters.

B<Note> that this subroutine does not initialize C<Test2>. This is
important because it may load C<Test::Builder|Test::Builder> at some
point. If it does this after C<Test2> has been initialized, C<Test2>
will complain.

=head2 klass

 klass 'Astro::App::Satpass2';

This subroutine replaces the stored object (if any) with the given class
name. The stored object is initialized to C<'Astro::App::Satpass2'>.

=head2 dt_greg_time_gm

This has the same signature and return as C<greg_time_gm> in
L<Astro::Coord::ECI::Utils|Astro::Coord::ECI::Utils>, but the heavy
lifting is done by L<DateTime|DateTime>.

=head2 dt_greg_time_local

This has the same signature and return as C<greg_time_local> in
L<Astro::Coord::ECI::Utils|Astro::Coord::ECI::Utils>, but the heavy
lifting is done by L<DateTime|DateTime>.

=head2 execute

 execute 'location', <<'EOD', 'Verify location';
 Location: 1600 Pennsylvania Ave NW Washington DC 20502
           Latitude 38.8987, longitude -77.0377, height 17 m
 EOD

This subroutine calls the C<execute()> method on the stored object and
tests the result. The last argument is the test name; the next-to-last
is the expected result.  All other arguments are arguments to
C<execute()>.

This is really just a convenience wrapper for L<call_m()|/call_m>.

=head2 invocant

This subroutine returns the current stored object.

=head2 load_or_skip

 SKIP: {
     load_or_skip 'Fubar', 2;
     load_or_skip qw{ Frobozz -import foozle };
     load_or_skip qw{ Moe::Howard -noimport };
     ...
 }

This subroutine loads the given module or skips the remaining tests in
the skip block. The skip count is not required, but it is an error to
omit it if your script plans an explicit number of tests.

You can specify option C<-import> to specify what is to be imported into
the caller's name space if the load is successful. This option can be
specified more than once, or with a comma-delimited list of stuff to
import, or both. If nothing is specified a default import is done.

As a special case, the skip count can be C<'all'>, in which case C<plan
skip_all => ...> is done if the module can not be loaded. This is an
error if you have already done tests.

The following options can be specified:

=over

=item -import

 -import foozle

This option specifies an explicit import. You can specify it more than
once, or specify a comma-delimited list, or both. If this is unspecified
the default import is done.

=item -noimport

 -noimport

If this option is specified, no import is done, even if C<-import> is
also specified.

=back

This method enforces version limits on the following module:

 DateTime::Calendar::Christian  0.06

=head2 call_m

 call_m 'new', undef, 'Instantiate a new object';
 call_m get => 'twilight', 'civil', 'Confirm civil twilight';
 call_m set => twilight => 'astronomical', undef,
     'Set astronomical twilight';

This subroutine calls an arbitrary method on the stored object and tests
the result. The last argument is the test name, and the next-to-last
argument is the desired result. The first argument is the method name,
and all other arguments (if any) are arguments to the method. If the
method is 'new', the result becomes the new stored object.

If the method fails, the desired value is compared to the exception
using C<like()>, after converting the desired value to a C<Regex> if
needed.

If the method returns a blessed reference, the return for testing
purposes is set to C<undef>. In this case, all we're doing is testing to
see if the method call succeeded.

If the desired result is C<'true'> or C<'false'>, the result of the
method call is tested with C<ok()>. If the desired result is C<'false'>,
the actual result is logically inverted before the test.

If the desired result is a C<Regexp>, the results are tested with
C<like()>. If it is any other reference, the test is done with
C<is_deeply()>. Otherwise, they are tested with C<is()>.

=head2 call_m_result

 call_m get => 'twilight', 'civil', 'Confirm civil twilight';
 say call_m_result;

This subroutine returns whatever value was returned by the method call
executed by the most-recent C<call_m()>.

=head2 normalize_path

 my $normalized = normalize_path( $path );

This subroutine normalizes paths. It converts them to absolute using
C<Cwd::cwd()>, then it performs OS-specific normalization on them.
Typically this consists of changing slash direction (MSWin32 and
friends) and lopping off trailing slashes (DragonFly BSD).

=head2 setup_app_mocker

 my $mocker = setup_app_mocker();

This subroutine sets up to mock
L<Astro::App::Satpass2|Astro::App::Satpass2> using the tools provided by
L<Test2::Tools::Mock|Test2::Tools::Mock>. The C<new()>, C<get()>, and
C<set()> methods are mocked, but behind them is a hash that just stores
and returns values.

The return is not a mock L<Astro::App::Satpass2|Astro::App::Satpass2>
object, but an object that manages the mocking. This object needs to be
retained because it is also a sentinel that tears down the mock when it
is destroyed. See L<Test2::Tools::Mock|Test2::Tools::Mock> for details.

You actually get a new application object in the normal way:

  my $app = Astro::App::Satpass2->new();


=head2 same_path

 same_path $got, $want, 'Got the same path';

This subroutine implements a test to see if the first two arguments
represent the same file path. On systems that do not support reliable
inode results from C<stat()> (that is, MSWin32 and friends, riscos, and
VMS) the test is simply a comparison of normalized paths. On systems
that support (or are suspected to support) reliable inodes, if the
normalized paths are different the inode numbers are compared.

=head1 METHODS

This module also does some aspect-oriented programming (read: 'violates
encapsulation') by placing the following methods in the
L<Astro::App::Satpass2|Astro::App::Satpass2> name space:

=head2 __TEST__frame_stack_depth

 call_m __TEST__frame_stack_depth => 1, 'Stack is empty';

This method returns the context frame stack depth. There is always 1
frame, even when the stack is nominally empty.

=head2 __TEST__is_exported

 call_m __TEST__is_exported => 'foo', 1, 'Foo is exported';

This method returns C<1> if the given variable is currently exported,
and C<0> otherwise.

=head2 __TEST__raw_attr

 call_m __TEST__raw_attr => '_twilight', '%.3f', -0.215,
     'Twilight in radians';

This method bypasses the accessors and accesses attribute values
directly. It takes one or two arguments. The first is the name of the
hash key to be accessed. The second argument, which is optional, is an
C<sprintf> format to run the value through.

=head1 SEE ALSO

L<Astro::App::Satpass2|Astro::App::Satpass2>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Astro-App-Satpass2>,
L<https://github.com/trwyant/perl-Astro-App-Satpass2/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
