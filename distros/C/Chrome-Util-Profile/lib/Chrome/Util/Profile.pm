package Chrome::Util::Profile;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-19'; # DATE
our $DIST = 'Chrome-Util-Profile'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;

use Exporter 'import';
our @EXPORT_OK = qw(list_chrome_profiles);

our %SPEC;

$SPEC{list_chrome_profiles} = {
    v => 1.1,
    summary => 'List available Google Chrome profiles',
    description => <<'_',

This utility will search for profile directories under ~/.config/google-chrome/.

_
    args => {
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_chrome_profiles {
    require File::Slurper;
    require JSON::MaybeXS;
    require Sort::Sub;

    my %args = @_;

    my $gc_dir     = "$ENV{HOME}/.config/google-chrome";
    unless (-d $gc_dir) {
        return [412, "Cannot find google chrome directory $gc_dir"];
    }

    my @rows;
    my $resmeta = {};
    local $CWD = $gc_dir;
  DIR:
    for my $dir (glob "*") {
        next unless -d $dir;
        my $prefs_path = "$dir/Preferences";
        next unless -f $prefs_path;
        my $prefs = JSON::MaybeXS::decode_json(
            File::Slurper::read_binary $prefs_path);
        my $profile_name = $prefs->{profile}{name};
        defined $profile_name && length $profile_name or do {
            log_warn "Profile in $prefs_path does not have profile/name, skipped";
            next DIR;
        };
        push @rows, {
            path => "$gc_dir/$dir",
            dir  => $dir,
            name => $profile_name,
        };
        $resmeta->{'func.raw_prefs'}{$profile_name} = $prefs;
    }

    unless ($args{detail}) {
        @rows = map { $_->{name} } @rows;
    }

    [200, "OK", \@rows, $resmeta];
}

1;
# ABSTRACT: List available Google Chrome profiles

__END__

=pod

=encoding UTF-8

=head1 NAME

Chrome::Util::Profile - List available Google Chrome profiles

=head1 VERSION

This document describes version 0.003 of Chrome::Util::Profile (from Perl distribution Chrome-Util-Profile), released on 2020-04-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 list_chrome_profiles

Usage:

 list_chrome_profiles(%args) -> [status, msg, payload, meta]

List available Google Chrome profiles.

This utility will search for profile directories under ~/.config/google-chrome/.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Chrome-Util-Profile>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Chrome-Util-Profile>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Chrome-Util-Profile>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<Chrome::Util::*> modules.

L<Firefox::Util::Profile>

L<Vivaldi::Util::Profile>

L<Opera::Util::Profile>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
