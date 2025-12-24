package App::newver::Scanner;
use 5.016;
use strict;
use warnings;
our $VERSION = '0.01';

use Exporter qw(import);
our @EXPORT_OK = qw(scan_version);

use HTML::TreeBuilder 5 -weak;
use LWP::UserAgent;
use URI;

use App::newver::Version qw(version_compare);

our $user_agent = "newver/$VERSION (perl $^V; $^O)";

our $MAYBE_VERSION_RX = qr/v?(?<Version>[0-9a-zA-Z._\-+~:,;]+)/;

sub scan_version {

    my %params = @_;
    my $program = $params{ program }
        // die "required parameter 'program' missing";
    my $version = $params{ version }
        // die "required parameter 'version' missing";
    my $match = $params{ match }
        // die "required parameter 'match' missing";
    my $page = $params{ page }
        // die "required parameter 'page' missing";

    $match =~ s/\@VERSION\@/$MAYBE_VERSION_RX/g
        or die "Match regex missing '\@VERSION\@'\n";
    $match = qr/$match/;

    my $ua = LWP::UserAgent->new;
    $ua->agent($user_agent);

    my $req = HTTP::Request->new(GET => $page);
    my $res = $ua->request($req);
    if (not $res->is_success) {
        die sprintf "Error fetching %s: %s\n", $page, $res->status_line;
    }

    my $content = $res->decoded_content;

    my $tree = HTML::TreeBuilder->new_from_content($content);
    my @as = $tree->look_down(_tag => "a", sub { defined $_[0]->attr('href') });
    if (!@as) {
        die qq{Found no <a href="..."> elements in $page\n};
    }

    my $greatest;
    for my $ae (@as) {
        my $href = $ae->attr('href');
        $href =~ $match or next;
        my $ver = $+{ Version };
        if (not defined $greatest or version_compare($ver, $greatest->[1]) == 1) {
            $greatest = [ $href, $ver ];
        }
    }

    if (not defined $greatest) {
        die "Found no matches in $page\n";
    }

    if (version_compare($greatest->[1], $version) != 1) {
        return undef;
    }

    return {
        program => $program,
        version => $greatest->[1],
        url     => URI->new_abs($greatest->[0], $page)->as_string,
    };

}

1;

=head1 NAME

App::newver::Scanner - Scan webpage for new software versions

=head1 SYNOPSIS

  use App::newver::Scanner qw(scan_version);

  my $scan = scan_version(
    program => 'perl',
    version => '5.16',
    page    => 'https://github.com/Perl/perl5/tags',
    match   => 'v@VERSION@.tar.gz',
  );

=head1 DESCRIPTION

B<App::newver::Scanner> is a module that provides the C<scan_version()>
subroutine for scanning software's upstream webpages for new software versions.
This is a private module, please consult the L<newver> manual for user
documentation.

=head1 SUBROUTINES

No subroutines are exported by default.

=head2 \%scan = scan_version(%params)

Scans the webpage given webpage for software versions newer than the current
version, and returns a hash ref of the new software version if one is found, or
C<undef> you're up-to-date.

The following fields are required for C<%params>.

=over 2

=item program

The name of the software.

=item version

The current software version.

=item page

The URL of the web page to scan.

=item match

Regex to use for matching software versoin hrefs in C<E<lt>aE<gt>> elements.
Regex must contain C<@VERSION@>, which matches the href's version component.

=back

=head1 GLOBAL VARIBES

=head2 $App::newver::Scanner::user_agent

User agent to use when fetching web pages.

=head2 $App::newver::MAYBE_VERSION_RX

Regex used by C<@VERSION@>.

=head1 AUTHOR

Written by L<Samuel Young|samyoung12788@gmail.com>

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/newver.git>. Comments and pull
requests are welcome.

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

=head1 SEE ALSO

L<newver>

=cut
