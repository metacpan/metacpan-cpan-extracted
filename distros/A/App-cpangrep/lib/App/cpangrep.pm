package App::cpangrep;

use strict;
use warnings;
use 5.008_005;
use utf8;
use open OUT => qw< :encoding(UTF-8) :std >;

our $VERSION = '0.07';

use Config;
use URI::Escape qw(uri_escape);
use LWP::UserAgent;
use JSON qw(decode_json);
use CPAN::DistnameInfo;
use List::Util qw(sum);

our $SERVER = "http://grep.cpan.me";
our $COLOR;
our $DEBUG;

# TODO:
#
#   • Add paging data to api results and support for page=N parameter
#
#   • Support pages, first with --page, then with 'cpangrep
#     next' and 'cpangrep prev' or similar?  something smarter?
#

sub run {
    require Getopt::Long;
    Getopt::Long::GetOptions(
        'color!'    => \$COLOR,
        'd|debug!'  => \$DEBUG,
        'h|help'    => \(my $help),
        'version'   => \(my $version),
        'pager!'    => \(my $pager),

        'l'         => \(my $list),
        'server=s'  => \$SERVER,
    );

    setup_colors() unless defined $COLOR and not $COLOR;
    setup_pager() unless defined $pager and not $pager;

    if ($help) {
        print help();
        return 0;
    }
    elsif ($version) {
        print "cpangrep version $VERSION\n";
        return 0;
    }
    elsif (not @ARGV) {
        warn "A query is required.\n\n";
        print help();
        return 1;
    }
    else {
        my $query = join " ", @ARGV;
        debug("Using query «$query»");

        my $search = search($query)
            or return 2;

        if ($list) {
            display_list($search);
        } else {
            display($search);
        }
        return 0;
    }
    return 0;
}

sub help {
    return <<'    USAGE';
usage: cpangrep [--debug] <query>

The query is a Perl regular expression without look-ahead/look-behind.
Several operators are supported as well for advanced use.

See <http://grep.cpan.me/about#re> for more information.

Multiple query arguments will be joined with spaces for convenience.

  -l            List only matching filenames.  Note that omitted results are
                not mentioned, but your pattern is likely to match many more
                files than output.

  --color       Enable colored output even if STDOUT isn't a terminal
  --no-color    Disable colored output
  --no-pager    Disable output through a pager

  --server      Specifies an alternate server to use, for example:
                    --server http://localhost:5000

  --debug       Print debug messages to stderr
  --help        Show this help and exit
  --version     Show version

    USAGE
}

sub search_url     { "$SERVER/?q="    . uri_escape(shift) }
sub search_api_url { "$SERVER/api?q=" . uri_escape(shift) }

sub search {
    my $query = shift;
    my $ua    = LWP::UserAgent->new(
        agent => "cpangrep/$VERSION",
    );
    $ua->env_proxy;

    my $response = $ua->get( search_api_url($query) );

    if (not $response->is_success) {
        warn "Request failed: ", $response->status_line, "\n";
        return;
    }

    my $content = $response->decoded_content;
    debug("Successfully received " . length($content) . " bytes");

    my $result = eval { decode_json($content) };
    if ($@ or not $result) {
        warn "Error decoding JSON response: $@\n";
        debug($content);
        return;
    }
    return $result;
}

sub display {
    my $search  = shift or return;
    my $results = $search->{results} || [];
    printf "%d result%s in %d file%s.",
        $search->{count}, ($search->{count} != 1 ? "s" : ""),
        scalar @$results, (@$results        != 1 ? "s" : "");

    my $display_total = sum map { scalar @{$_->{results}} }
                            map { @{$_->{files}} }
                                @$results;
    printf "  Showing first %d results.", $display_total
        if $display_total and $display_total != $search->{count};
    print "\n\n";

    for my $result (@$results) {
        my $fulldist = $result->{dist};
           $fulldist =~ s{^(?=(([A-Z])[A-Z]))}{$2/$1/};
        my $dist = CPAN::DistnameInfo->new($fulldist);

        for my $file (@{$result->{files}}) {
            print colored(["GREEN"], join("/", $dist->cpanid, $dist->distvname, $file->{file})), "\n";

            for my $match (@{$file->{results}}) {
                my $snippet = $match->{text};

                my ($start, $len) = @{$match->{match}};
                $len -= $start;

                # XXX TODO: Track down the grep.cpan.me api bug that causes
                # this.  An example that fails for me today:
                #
                #   cpangrep dist:App-Prefix file:Changes '^\s*\[.+?\]\s*$'
                #
                # -trs, 29 Jan 2014
                if (length $snippet < $start + $len) {
                    warn colored("API returned an out of bounds match; skipping! (use --debug to see details)", "RED"),
                         color("reset"), "\n";
                    if ($DEBUG) {
                        require Data::Dumper;
                        debug("snippet: «$snippet» (length ", length $snippet, ")");
                        debug("reported match starts at «$start», length «$len» (ends at «@{[$start+$len]}»)");
                        debug("raw match response: ", Data::Dumper::Dumper($match));
                    }
                    next;
                }

                substr($snippet, $start, $len) = colored(substr($snippet, $start, $len), "BOLD RED");

                if ($match->{line}) {
                    my $ln       = $match->{line}[0] - (substr($snippet, 0, $start) =~ y/\n//);
                    my $print_ln = sub {
                        colored($ln++, "BLUE") . colored(":", "CYAN")
                    };
                    $snippet =~ s/^/$print_ln->()/mge;
                }

                chomp $snippet;
                print $snippet, color("reset"), "\n\n";
            }
            printf colored("  → %d more match%s from this file.\n\n", "MAGENTA"),
                $file->{truncated}, ($file->{truncated} != 1 ? "es" : "")
                    if $file->{truncated};
        }
        printf colored("→ %d more file%s matched in %s.\n\n", "MAGENTA"),
            $result->{truncated}, ($result->{truncated} != 1 ? "s" : ""), $dist->distvname
                if $result->{truncated};
    }
}

sub display_list {
    my $search  = shift or return;
    my $results = $search->{results} || [];
    for my $result (@$results) {
        my $fulldist = $result->{dist};
           $fulldist =~ s{^(?=(([A-Z])[A-Z]))}{$2/$1/};
        my $dist = CPAN::DistnameInfo->new($fulldist);

        for my $file (@{$result->{files}}) {
            print join("/", $dist->cpanid, $dist->distvname, $file->{file}), "\n";
        }
    }
}

# Some tricks borrowed from uninames' fork_output()
sub setup_pager {
    return unless -t STDOUT;

    my $pager = $ENV{PAGER} || 'less';

    $ENV{LESS} = 'SRFX' . ($ENV{LESS} || '')
        if $pager =~ /less/;
    $ENV{LESSCHARSET} = "utf-8"
        if $pager =~ /more|less/ and ($ENV{LESSCHARSET} || "") ne "utf-8";

    open STDOUT, "| $pager"
        or die "couldn't reopen stdout to pager '$pager': $!\n";

    # exit cleanly on :q in less
    $SIG{PIPE} = sub { exit };

    # close piped output, otherwise we screw up terminal
    END { close STDOUT or die "error closing stdout: $!\n" }

    binmode STDOUT, ':encoding(UTF-8)';
    $| = 1;
}

# Setup colored output if we have it
sub setup_colors {
    eval { require Term::ANSIColor };
    if ( not $@ and supports_color() ) {
        $Term::ANSIColor::EACHLINE = "\n";
        *color   = *_color_real;
        *colored = *_colored_real;
    }
}

# No-op passthrough defaults
sub color           { "" }
sub colored         { ref $_[0] ? @_[1..$#_] : $_[0] }
sub _color_real     { Term::ANSIColor::color(@_) }
sub _colored_real   { Term::ANSIColor::colored(@_) }

sub supports_color {
    # We're not on a TTY and don't force it, kill color
    return 0 unless -t *STDOUT or $COLOR;

    if ( $Config{'osname'} eq 'MSWin32' ) {
        eval { require Win32::Console::ANSI; };
        return 1 if not $@;
    }
    else {
        return 1 if $ENV{'TERM'} =~ /^(xterm|rxvt|linux|ansi|screen)/;
        return 1 if $ENV{'COLORTERM'};
    }
    return 0;
}

sub debug {
    return unless $DEBUG;
    warn "DEBUG: ", @_, " [", join("/", (caller(1))[3,2]), "]\n";
}

1;
__END__

=encoding utf-8

=head1 NAME

App::cpangrep - Grep CPAN from the command-line using grep.cpan.me

=head1 SYNOPSIS

  cpangrep "\bpackage\s+App::cpangrep\b"

  cpangrep --help

=head1 DESCRIPTION

App::cpangrep provides the C<cpangrep> program which is a command-line
interface for L<http://grep.cpan.me>.

=head1 AUTHOR

Thomas Sibley E<lt>tsibley@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- Thomas Sibley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<cpangrep>, L<http://grep.cpan.me>

=cut
