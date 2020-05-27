package App::FirefoxMultiAccountContainersUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-26'; # DATE
our $DIST = 'App-FirefoxMultiAccountContainersUtils'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Sort::Sub ();

$Sort::Sub::argsopt_sortsub{sort_sub}{cmdline_aliases} = {S=>{}};
$Sort::Sub::argsopt_sortsub{sort_args}{cmdline_aliases} = {A=>{}};

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Firefox Multi-Account Containers add-on',
    description => <<'_',

About the add-on: <https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/>.

_
};

$SPEC{firefox_mua_sort_containers} = {
    v => 1.1,
    summary => "Sort Firefox Multi-Account Containers add-on's containers",
    description => <<'_',

At the time of this writing, the UI does not provide a way to sort the
containers. Thus this utility.

_
    args => {
        profile => {
            schema => 'firefox::profile_name*',
            req => 1,
            pos => 0,
        },
        %Sort::Sub::argsopt_sortsub,
    },
    features => {
        dry_run => 1,
    },
};
sub firefox_mua_sort_containers {
    require App::FirefoxUtils;
    require File::Copy;
    require File::Slurper;
    require Firefox::Util::Profile;
    require JSON::MaybeXS;

    my %args = @_;

    my $sort_sub  = $args{sort_sub}  // 'asciibetically';
    my $sort_args = $args{sort_args} // [];
    my $cmp = Sort::Sub::get_sorter($sort_sub, { map { split /=/, $_, 2 } @$sort_args });

    my $res;

    $res = App::FirefoxUtils::firefox_is_running();
    return [500, "Can't check if Firefox is running: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    return [412, "Please stop Firefox first"] if $res->[2];

    $res = Firefox::Util::Profile::list_firefox_profiles(detail=>1);
    return [500, "Can't list Firefox profiles: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    my $path;
    {
        for (@{ $res->[2] }) {
            next unless $_->{name} eq $args{profile};
            $path = $_->{path};
            last;
        }
    }
    return [404, "No such Firefox profile '$args{profile}', ".
                "available profiles include: ".
                join(", ", map {$_->{name}} @{$res->[2]})]
        unless defined $path;

    $path = "$path/containers.json";
    return [412, "Can't find '$path', is this Firefox using Multi-Account Containers?"]
        unless (-f $path);

    unless ($args{-dry_run}) {
        log_info "Backing up $path to $path~ ...";
        File::Copy::copy($path, "$path~") or
              return [500, "Can't backup $path to $path~: $!"];
    }

    my $json = JSON::MaybeXS::decode_json(File::Slurper::read_text($path));

    $json->{identities} = [
        sort {
            $sort_sub eq 'by_perl_code' ? $cmp->($a, $b) : $cmp->($a->{name}, $b->{name})
        }  @{ $json->{identities} }
    ];

    if ($args{-dry_run}) {
        # convert boolean object to 1/0 for display
        for (@{ $json->{identities} }) { $_->{public} = $_->{public} ? 1:0 }

        return [200, "OK (dry-run)", $json->{identities}];
    }

    log_info "Writing $path ...";
    File::Slurper::write_text($path, JSON::MaybeXS::encode_json($json));
    [200];
}

1;
# ABSTRACT: Utilities related to Firefox Multi-Account Containers add-on

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FirefoxMultiAccountContainersUtils - Utilities related to Firefox Multi-Account Containers add-on

=head1 VERSION

This document describes version 0.004 of App::FirefoxMultiAccountContainersUtils (from Perl distribution App-FirefoxMultiAccountContainersUtils), released on 2020-05-26.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox multi-account
containers addon:

=over

=item * L<firefox-mua-sort-containers>

=back


About the add-on: L<https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/>.

=head1 FUNCTIONS


=head2 firefox_mua_sort_containers

Usage:

 firefox_mua_sort_containers(%args) -> [status, msg, payload, meta]

Sort Firefox Multi-Account Containers add-on's containers.

At the time of this writing, the UI does not provide a way to sort the
containers. Thus this utility.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<profile>* => I<firefox::profile_name>

=item * B<sort_args> => I<array[str]>

Arguments to pass to the Sort::Sub::* routine.

=item * B<sort_sub> => I<sortsub::spec>

Name of a Sort::Sub::* module (without the prefix).


=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=E<gt>1 to enable simulation mode.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-FirefoxMultiAccountContainersUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FirefoxMultiAccountContainersUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FirefoxMultiAccountContainersUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Some other CLI utilities related to Firefox: L<App::FirefoxUtils>,
L<App::DumpFirefoxHistory>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
