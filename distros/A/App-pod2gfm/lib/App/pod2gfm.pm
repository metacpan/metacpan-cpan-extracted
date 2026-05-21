use v5.40.0;

use strict;
use warnings;

use Object::Pad 0.825;

package App::pod2gfm;  # For toolchain compatibility.
class App::pod2gfm;

use File::Basename qw< basename >;
use File::Spec     ();
use Pod::Usage;
use Pod::Markdown::Githubert 0.05;

our $VERSION = 'v1.1.0';

my $PROG = basename($0);

field @_argv;
field %_opts    :reader;
field %_gh_opts :reader = ( output_encoding => 'UTF-8' );  # Pod::Markdown::Githubert options
field $_infile  :reader;
field $_outfile :reader;
field $_has_stdin = false;

method init (@argv)
{
    _exit( $self->_process_opts( \@argv ) );

    return $self;
}

method run ()
{
    my $start = true;  # Process STDIN.

    while ( $start || @_argv ) {
        $start = false     if $start;
        $self->_convert_md if $self->_set_handles == 0;
    }

    return 0;
}

method _process_opts ( $argv = undef )
{
    return 0 unless defined $argv;

    # Transform Getopt::Long error warns.
    local $SIG{__WARN__} = sub {
        chomp( my $msg = shift );

        $msg =~ tr{"}{'};
        $msg = lcfirst $msg;

        warn "$PROG: $msg\n";
    };

    # Bash completion
    try {
        require Getopt::Long::More;

        Getopt::Long::More->VERSION('0.007');
        Getopt::Long::More->import( qw< GetOptionsFromArray optspec > );

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
        'a|auto' => \$_opts{auto},

        'e|file-extension=s' => defined &Getopt::Long::More::optspec
        ? optspec(
            destination => \$_opts{file_ext},
            completion  => [ qw< markdown > ],
          )
        : \$_opts{file_ext},

        'no-strip-ext'         => \$_opts{no_strip_ext},
        't|target-directory=s' => \$_opts{target_dir},
        'force'                => \$_opts{force},

        'hl-language=s' => defined &Getopt::Long::More::optspec
        ? optspec(
            destination => \$_gh_opts{hl_language},
            completion  => [ qw< perl > ],
          )
        : \$_gh_opts{hl_language},

        'man-url-prefix=s'     => \$_gh_opts{man_url_prefix},
        'perldoc-url-prefix=s' => \$_gh_opts{perldoc_url_prefix},
        'h|help'               => sub { pod2usage( -exitval => 0, -verbose => 0 ) },
        'v|version'            => sub { print "$PROG $VERSION\n"; exit 0 },

    ) or return 2;

    @_argv = $argv->@*;

    foreach my ( $k, $v ) (%_gh_opts) {
        delete $_gh_opts{$k} unless defined $v;
    }

    return 0;
}

method _set_handles ()
{
    my ( $in_fh, $infile ) = $self->_get_infile;
    my $out_fh = $self->_get_outfile($infile);

    # File exists (--force not set).
    return 1 if !fileno $out_fh && $out_fh == 1;

    # Return only bytes to avoid PERL_UNICODE effects.
    binmode $_, ':bytes' foreach ( $in_fh, $out_fh );

    $_infile  = $in_fh;
    $_outfile = $out_fh;

    return 0;
}

method _get_infile ()
{
    my $in_fh;
    my $infile = shift @_argv;

    if ( $_has_stdin eq false && ( !defined $infile || $infile eq '-' ) ) {
        $in_fh      = *STDIN;  # Read STDIN.
        $_has_stdin = true;    # Only one STDIN is allowed per process.
    }
    else {
        open my $fh, '<', $infile
          or do {
              warn "$PROG: failed to open '$infile': $!\n";
              exit 1;
          };

        $in_fh = $fh;
    }

    return ( $in_fh, $infile );
}

method _get_outfile ($infile)
{
    my $out_fh;
    my $auto = $_opts{auto};

    my $outfile =
        $auto
      ? $infile
      : shift @_argv;

    if ( !defined $infile || !defined $outfile && !$auto ) {
        $out_fh = *STDOUT;  # Print to STDOUT.
    }
    else {
        if ($auto) {
            my $target_dir = $_opts{target_dir};
            $infile = basename($infile) if defined $target_dir;

            my $auto_file =
                $_opts{no_strip_ext}
              ? $infile
              : $infile =~ s{\.(?> pm | pod | pl)\z}{}xr;  # Strip extension.

            my $ext = $_opts{file_ext} // 'md';

            $outfile = "$auto_file.$ext";
            $outfile =
              defined $target_dir
              ? File::Spec->catdir( $target_dir, $outfile )
              : $outfile;
        }

        if ( -f $outfile && !$_opts{force} ) {
            warn "$PROG: $outfile file exists; use --force to overwrite it\n";
            return 1;
        }

        open my $fh, '>', $outfile
          or do {
              warn "$PROG: failed to open '$outfile': $!\n";
              exit 1;
          };

        $out_fh = $fh;
    }

    return $out_fh;
}

method _convert_md ()
{
    my $parser = Pod::Markdown::Githubert->new(%_gh_opts);

    $parser->output_fh($_outfile);
    $parser->parse_file($_infile);

    close $_infile  or die $!;
    close $_outfile or die $!;

    return $self;
}

sub _exit ($code)
{
    exit $code if $code > 0;
}

=encoding UTF-8

=for highlighter language=perl

=head1 NAME

App::pod2gfm - convert POD to GitHub Flavored Markdown

=head1 SYNOPSIS

  use App::pod2gfm;

  App::pod2gfm->new->init(@ARGV)->run;

=head1 DESCRIPTION

B<App::pod2gfm> provides the logic behind the L<pod2gfm> wrapper script, handling
the processing of options and filehandles before calling L<Pod::Markdown::Githubert>.
See L<pod2gfm/DESCRIPTION> for details.

Note that unlike L<pod2markdown>, this module does not deal with some options such
as encodings, and uses UTF-8 by default. Also, it supports writing to multiple
files and does not overwrite existing ones.

=head1 METHODS

=head2 new

  my $pod2gfm = App::pod2gfm->new;

Constructs and returns a new B<App::pod2gfm> instance. Takes no arguments.

=head2 init

  $pod2gfm->init(@ARGV);

Parses the list given (typically from C<@ARGV>) for options. Returns C<self>.

=head2 run

  $pod2gfm->run;

Performs the program actions: sets the filehandles according to the command-line
arguments, then passes them to L<Pod::Markdown::Githubert> to do the conversion.
Takes no arguments and returns C<0> on success.

=head1 ERRORS

This module reports errors to C<STDERR> and exits with a non‑zero status in the
following:

=over 4

=item * File access/permission issues.

=item * Invalid command-line options.

=back

See L<pod2gfm/EXIT-STATUS> for exit code details.

=head1 BUGS

Report bugs at L<https://github.com/ryoskzypu/App-pod2gfm/issues>.

=head1 AUTHOR

ryoskzypu <ryoskzypu@proton.me>

=head1 SEE ALSO

=over 4

=item *

L<Pod::Markdown>

=item *

L<Pod::Markdown::Githubert>

=back

=head1 COPYRIGHT

Copyright © 2026 ryoskzypu

MIT-0 License. See LICENSE for details.

=cut
