use v5.42.0;

use strict;
use warnings;
no source::encoding;  # Avoid dying on v5.42.0 (non-ASCII char in POD).

use Object::Pad 0.825;

package App::cpan2arch;  # For toolchain compatibility.
class App::cpan2arch
  :does(App::cpan2arch::GetMetadata)
  :does(App::cpan2arch::MergePrereqs)
  :does(App::cpan2arch::CheckPackages)
  :does(App::cpan2arch::WritePkgbuild);

use File::Basename qw< basename >;
use version;

our $VERSION = 'v1.1.2';

field %_env :reader :writer = (
    user_agent       => "App::cpan2arch/$VERSION",
    cache_mcpan_path => '/tmp/mcpan_cache',
    cache_arch_path  => '/tmp/arch_cache',
    cache_expiration => '1d',
);
field $_prog :reader = basename($0);
field %_opts :reader;
field %_args :reader;

method init (@argv)
{
    _exit( $self->_process_env->_process_opts( \@argv ) );

    return $self;
}

method run ()
{
    $self->_psub;

    # Non-interactive TTY must not display this.
    print STDERR "Generating PKGBUILD...\n" if -t STDOUT;

    _exit( $self->get_metadata );
    _exit( $self->merge_prereqs );
    _exit( $self->check_packages );
    _exit( $self->generate_pkgbuild->write_pkgbuild );

    return 0;
}

# Process environment variables.
method _process_env ()
{
    $_env{packager}         = $ENV{PACKAGER} // 'Your Name <email@domain.tld>';
    $_env{user_agent}       = $ENV{C2A_USER_AGENT}       if defined $ENV{C2A_USER_AGENT};
    $_env{cache_mcpan_path} = $ENV{C2A_CACHE_MCPAN_PATH} if defined $ENV{C2A_CACHE_MCPAN_PATH};
    $_env{cache_arch_path}  = $ENV{C2A_CACHE_ARCH_PATH}  if defined $ENV{C2A_CACHE_ARCH_PATH};
    $_env{cache_expiration} = $ENV{C2A_CACHE_EXPIRATION} if defined $ENV{C2A_CACHE_EXPIRATION};
    $_env{cache_ignore}     = $ENV{C2A_CACHE_IGNORE} ? true : false;
    $_env{debug}            = $ENV{C2A_DEBUG}        ? true : false;

    try {
        if ( $_env{debug} ) {
            require Data::Printer;
            Data::Printer->VERSION('1.002001');
        }
    }
    catch ($e) {
        warn $e;
        warn "$_prog: Data::Printer is required to display debug information\n";

        exit 1;
    }

    $self->_psub;
    $self->_pdump( '%_env', \%_env, "\n" );

    return $self;
}

# Process options and its arguments.
method _process_opts ( $argv = undef )
{
    $self->_psub;

    return 0 unless defined $argv;

    # Transform Getopt::Long error warns.
    local $SIG{__WARN__} = sub {
        chomp( my $msg = shift );

        $msg =~ tr{"}{'};
        $msg = lcfirst $msg;

        warn "$_prog: $msg\n";
    };

    # Bash completion
    try {
        require Getopt::Long::More;

        Getopt::Long::More->VERSION('0.007');
        Getopt::Long::More->import( qw< GetOptionsFromArray > );

        Getopt::Long::More::Configure(
            qw<
                default
                gnu_getopt
                no_ignore_case
            >
        );
    }
    catch ($e) {
        # Use Getopt::Long as fallback.
        require Getopt::Long;

        Getopt::Long->import(
            qw<
                GetOptionsFromArray
                :config
                default
                gnu_getopt
                no_ignore_case
            >
        );
    }

    GetOptionsFromArray(
        $argv,
        'w|write'     => \$_opts{write},
        'force'       => \$_opts{force},
        'u|update'    => \$_opts{update},
        'c|clear'     => \$_opts{clear},
        'clear-mcpan' => \$_opts{clear_mcpan},
        'clear-arch'  => \$_opts{clear_arch},
        'h|help'      => sub {
            require Pod::Usage;
            Pod::Usage::pod2usage( -exitval => 0, -verbose => 0 );
        },
        'v|version' => sub { print "$_prog $VERSION\n"; exit 0 },

    ) or return 2;

    $_args{module}  = shift $argv->@*;
    $_args{version} = shift $argv->@*;

    $self->_pdump( '%_opts', \%_opts, "\n" );
    $self->_pdump( '%_args', \%_args, "\n" );
    $self->_pdump( '$self',  $self,   "\n" );

    if ( !defined $_args{module} ) {
        warn "missing module name\n";
        return 2;
    }

    if ( $_args{module} eq 'perl' ) {
        warn "perl interpreter is not a module\n";
        return 2;
    }

    return 0;
}

# Print debug message.
method _pdbg ($msg)
{
    return undef unless $_env{debug};

    print STDERR $msg;
}

# Print debug the caller sub/method name.
method _psub ()
{
    $self->_pdbg( ( caller 1 )[3] . "\n\n" );
}

# Print variable dump.
method _pdump ( $prefix, $var_ref, $suffix )
{
    return undef unless $_env{debug};

    my $dump = join(
        '',
        "$prefix = ",
        Data::Printer::np($var_ref),
        "\n",
        $suffix,
    );

    print STDERR $dump;
}

# Compare Perl distribution versions.
method _comp_vers ( $ver_a, $ver_b, $op )
{
    my %vers = (
        a_parsed => $ver_a,
        b_parsed => $ver_b,
    );

    foreach my ( $k, $ver ) (%vers) {
        try {
            $vers{$k} = version->parse($ver);
        }
        catch ($e) {
            warn $e;
            warn "$_prog: failed to parse $ver version\n";

            return 1;
        }
    }

    $self->_pdump( '$vers{a_parsed}', $vers{a_parsed}, '' );
    $self->_pdump( '$vers{b_parsed}', $vers{b_parsed}, "\n" );

    my %ops = (
        '<'  => sub { $_[0] < $_[1] },
        '<=' => sub { $_[0] <= $_[1] },
        '==' => sub { $_[0] == $_[1] },
        '>'  => sub { $_[0] > $_[1] },
        '>=' => sub { $_[0] >= $_[1] },
    );

    if ( defined $ops{$op} ) {
        return 0 if $ops{$op}->( $vers{a_parsed}, $vers{b_parsed} );
    }

    return undef;
}

sub _exit ($code)
{
    exit $code if $code > 0;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

App::cpan2arch - generate PKGBUILD from CPAN metadata

=head1 SYNOPSIS

  use App::cpan2arch;

  App::cpan2arch->new->init(@ARGV)->run;

=head1 DESCRIPTION

B<App::cpan2arch> provides the logic behind the L<cpan2arch> wrapper script,
handling processing of environment variables and options, HTTP requests for
CPAN metadata and Arch Linux package information, translating dependencies
between CPAN and C<PKGBUILD>, and generating and outputting the C<PKGBUILD>.
See L<cpan2arch/DESCRIPTION> for details.

=head1 METHODS

=head2 new

  my $cpan2arch = App::cpan2arch->new;

Constructs and returns a new B<App::cpan2arch> instance. Takes no arguments.

=head2 init

  $cpan2arch->init(@ARGV);

Reads environment variables and parses the list given (typically from C<@ARGV>)
for options. Returns C<self>.

=head2 run

  $cpan2arch->run;

Performs the program actions:

=over 4

=item *

Fetches module/distribution metadata from L<MetaCPAN's|https://github.com/metacpan/metacpan-api>
API.

=item *

Merges L<CPAN prerequisites|https://metacpan.org/pod/CPAN::Meta::Spec#PREREQUISITES>
to L<PKGBUILD dependencies|https://man.archlinux.org/man/alpm-package-relation.7>.

=item *

Checks whether prerequisite distributions exist as packages on Arch's Official/AUR
repositories to build C<PKGBUILD> data.

=item *

Generates the C<PKGBUILD> to write to C<STDOUT> or file.

=back

Takes no arguments and returns C<0> on success.

=head1 ERRORS

This module reports errors to C<STDERR> and exits with a non-zero status in the
following:

=over 4

=item *

Missing runtime dependencies (L<Data::Printer>, L<vercmp|https://man.archlinux.org/man/vercmp.8>)

=item *

Invalid command-line options

=item *

Network/JSON issues

=item *

MetaCPAN/Arch API issues

=item *

Dist tarball issues

=item *

C<perl> version issues

=item *

L<Module::CoreList> issues

=item *

File access/permission/metadata issues

=back

See L<cpan2arch/EXIT-STATUS> for exit code details.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/App-cpan2arch/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<App::cpan2arch::GetMetadata>

=item *

L<App::cpan2arch::MergePrereqs>

=item *

L<App::cpan2arch::CheckPackages>

=item *

L<App::cpan2arch::WritePkgbuild>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
