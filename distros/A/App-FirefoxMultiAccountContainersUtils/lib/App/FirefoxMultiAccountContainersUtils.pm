package App::FirefoxMultiAccountContainersUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-02'; # DATE
our $DIST = 'App-FirefoxMultiAccountContainersUtils'; # DIST
our $VERSION = '0.011'; # VERSION

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

our %arg0_profile = (
    profile => {
        schema => 'firefox::local_profile_name*',
        req => 1,
        pos => 0,
    },
);

our %argopt_profile = (
    profile => {
        schema => 'firefox::local_profile_name*',
    },
);

sub _get_containers_json {
    require App::FirefoxUtils;
    require File::Copy;
    require File::Slurper;
    require Firefox::Util::Profile;
    require JSON::MaybeXS;

    my ($args, $do_backup) = @_;

    my $res;

    if ($do_backup) {
        $res = App::FirefoxUtils::firefox_is_running();
        return [500, "Can't check if Firefox is running: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        if ($args->{-dry_run}) {
            log_info "[DRY-RUN] Note that Firefox is still running, ".
                "you should stop Firefox first when actually sorting containers";
        } else {
            return [412, "Please stop Firefox first"] if $res->[2];
        }
    }

    $res = Firefox::Util::Profile::list_firefox_profiles(detail=>1);
    return [500, "Can't list Firefox profiles: $res->[0] - $res->[1]"]
        unless $res->[0] == 200;
    my $path;
    {
        for (@{ $res->[2] }) {
            next unless $_->{name} eq $args->{profile};
            $path = $_->{path};
            last;
        }
    }
    return [404, "No such Firefox profile '$args->{profile}', ".
                "available profiles include: ".
                join(", ", map {$_->{name}} @{$res->[2]})]
        unless defined $path;

    $path = "$path/containers.json";
    return [412, "Can't find '$path', is this Firefox using Multi-Account Containers?"]
        unless (-f $path);

    unless ($args->{-dry_run} || !$do_backup) {
        log_info "Backing up $path to $path~ ...";
        File::Copy::copy($path, "$path~") or
              return [500, "Can't backup $path to $path~: $!"];
    }

    my $json = JSON::MaybeXS::decode_json(File::Slurper::read_text($path));

    [200, "OK", {path=>$path, content=>$json}];
}

sub _complete_container {
    require Firefox::Util::Profile;

    my %args = @_;

    # XXX if firefox profile is already specified, only list containers for that
    # profile.
    my $res = Firefox::Util::Profile::list_firefox_profiles();
    $res->[0] == 200 or return {message => "Can't list Firefox profiles: $res->[0] - $res->[1]"};

    my %containers;
    for my $profile (@{ $res->[2] }) {
        my $cres = firefox_mua_list_containers(profile => $profile);
        $cres->[0] == 200 or next;
        for (@{ $cres->[2] }) {
            next unless $_->{public};
            next unless $_->{name};
            $containers{ $_->{name} }++;
        }
    }
    Complete::Util::complete_hash_key(
        word => $args{word},
        hash => \%containers,
    );
}

$SPEC{firefox_mua_list_containers} = {
    v => 1.1,
    summary => "List Firefox Multi-Account Containers add-on's containers",
    args => {
        %arg0_profile,
    },
};
sub firefox_mua_list_containers {
    my %args = @_;

    my $res;
    $res = _get_containers_json(\%args, 0);
    return $res unless $res->[0] == 200;
    my $json = $res->[2]{content};

    # convert boolean object to 1/0 for display
    for (@{ $json->{identities} }) { $_->{public} = $_->{public} ? 1:0 }
    return [200, "OK", $json->{identities}];
}

$SPEC{firefox_mua_modify_containers} = {
    v => 1.1,
    summary => "Modify (and delete) Firefox Multi-Account Containers add-on's containers with Perl code",
    description => <<'_',

This utility lets you modify the identity records in `containers.json` file
using Perl code. The Perl code is called for every container (record). It is
given the record hash in `$_` and is supposed to modify and return the modified
the record. It can also choose to return false to instruct deleting the record.

_
    args => {
        %arg0_profile,
        code => {
            schema => ['any*', of=>['code*', 'str*']],
            req => 1,
            pos => 1,
        },
    },
    features => {
        dry_run => 1,
    },
    examples => [
        {
            summary => 'Delete all containers matching some conditions (remove -n to actually delete it)',
            argv => ['myprofile', 'return 0 if $_->{icon} eq "cart" || $_->{name} =~ /temp/i; $_'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Delete all containers (remove -n to actually delete it)',
            argv => ['myprofile', '0'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Change all icons to "dollar" and all colors to "red"',
            argv => ['myprofile', '$_->{icon} = "dollar"; $_->{color} = "red"; $_'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub firefox_mua_modify_containers {
    require File::Slurper;

    my %args = @_;

    my $code = $args{code};
    unless (ref $code eq 'CODE') {
        $code = "no strict; no warnings; package main; sub { $code }";
        $code = eval $code;
        return [400, "Cannot compile string code: $@"] if $@;
    }

    my $res;
    $res = _get_containers_json(\%args, 'backup');
    return $res unless $res->[0] == 200;

    my $path = $res->[2]{path};
    my $json = $res->[2]{content};
    my $new_identities = [];
    for my $identity (@{ $json->{identities} }) {
        local $_ = $identity;
        my $code_res = $code->($identity);
        if (!$code_res) {
            next;
        } elsif (ref $code_res ne 'HASH') {
            log_fatal "Code does not return a hashref: %s", $code_res;
            die;
        } else {
            push @$new_identities, $code_res;
        }
    }
    $json->{identities} = $new_identities;

    if ($args{-dry_run}) {
        # convert boolean object to 1/0 for display
        for (@{ $json->{identities} }) { $_->{public} = $_->{public} ? 1:0 }

        return [200, "OK (dry-run)", $json->{identities}];
    }

    log_info "Writing $path ...";
    File::Slurper::write_text($path, JSON::MaybeXS::encode_json($json));
    [200];
}

$SPEC{firefox_mua_sort_containers} = {
    v => 1.1,
    summary => "Sort Firefox Multi-Account Containers add-on's containers",
    description => <<'_',

At the time of this writing, the UI of the Firefox Multi-Account Containers
add-on does not provide a way to sort the containers. Thus this utility.

_
    args => {
        %arg0_profile,
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
    $res = _get_containers_json(\%args, 'backup');
    return $res unless $res->[0] == 200;

    my $path = $res->[2]{path};
    my $json = $res->[2]{content};
    $json->{identities} = [
        sort {
            my $a_name = defined$a->{name} ? $a->{name} : do { my $name = lc $a->{l10nID}; $name =~ s/^usercontext//; $name =~ s/\.label$//; $name };
            my $b_name = defined$b->{name} ? $b->{name} : do { my $name = lc $b->{l10nID}; $name =~ s/^usercontext//; $name =~ s/\.label$//; $name };
            $sort_sub eq 'by_perl_code' ? $cmp->($a, $b) : $cmp->($a_name, $b_name)
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

$SPEC{firefox_container} = {
    v => 1.1,
    summary => "CLI to open URL in a new Firefox tab, in a specific multi-account container",
    description => <<'_',

This utility opens a new firefox tab in a specific multi-account container. This
requires the Firefox Multi-Account Containers add-on, as well as another add-on
called "Open external links in a container",
<https://addons.mozilla.org/en-US/firefox/addon/open-url-in-container/>.

The way it works, because add-ons currently do not have hooks to the CLI, is via
a custom protocol handler. For example, if you want to open
<http://www.example.com/> in a container called `mycontainer`, you ask Firefox
to open this URL:

    ext+container:name=mycontainer&url=http://www.example.com/

Ref: <https://github.com/mozilla/multi-account-containers/issues/365>

_
    args => {
        %argopt_profile,
        container => {
            schema => 'str*',
            completion => \&_complete_container,
            req => 1,
            pos => 0,
        },
        urls => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'url',
            schema => ['array*', of=>'str*'],
            pos => 1,
            slurpy => 1,
        },
    },
    features => {
    },
    examples => [
        {
            summary => 'Open two URLs in a container called "mycontainer"',
            argv => [qw|mycontainer www.example.com www.example.com/url2|],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'If URL is not specified, will open a blank tab',
            argv => [qw|mycontainer|],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    links => [
        {url=>'prog:open-browser'},
    ],
};
sub firefox_container {
    require URI::Escape;

    my %args = @_;
    my $container = $args{container};

    my @urls;
    for my $url0 (@{ $args{urls} || ["about:blank"] }) {
        my $url = "ext+container:";
        $url .= "name=" . URI::Escape::uri_escape($container);
        $url .= "&url=" . URI::Escape::uri_escape($url0);
        push @urls, $url;
    }

    my @cmd = ("firefox", @urls);
    log_trace "Executing %s ...", \@cmd;
    exec @cmd;
    #[200]; # won't be reached
}

1;
# ABSTRACT: Utilities related to Firefox Multi-Account Containers add-on

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FirefoxMultiAccountContainersUtils - Utilities related to Firefox Multi-Account Containers add-on

=head1 VERSION

This document describes version 0.011 of App::FirefoxMultiAccountContainersUtils (from Perl distribution App-FirefoxMultiAccountContainersUtils), released on 2020-11-02.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox multi-account
containers addon:

=over

=item * L<firefox-container>

=item * L<firefox-mua-list-containers>

=item * L<firefox-mua-modify-containers>

=item * L<firefox-mua-sort-containers>

=back


About the add-on: L<https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/>.

=head1 FUNCTIONS


=head2 firefox_container

Usage:

 firefox_container(%args) -> [status, msg, payload, meta]

CLI to open URL in a new Firefox tab, in a specific multi-account container.

Examples:

=over

=item * Open two URLs in a container called "mycontainer":

 firefox_container(
     container => "mycontainer",
   urls => ["www.example.com", "www.example.com/url2"]
 );

=item * If URL is not specified, will open a blank tab:

 firefox_container( container => "mycontainer");

=back

This utility opens a new firefox tab in a specific multi-account container. This
requires the Firefox Multi-Account Containers add-on, as well as another add-on
called "Open external links in a container",
L<https://addons.mozilla.org/en-US/firefox/addon/open-url-in-container/>.

The way it works, because add-ons currently do not have hooks to the CLI, is via
a custom protocol handler. For example, if you want to open
L<http://www.example.com/> in a container called C<mycontainer>, you ask Firefox
to open this URL:

 ext+container:name=mycontainer&url=http://www.example.com/

Ref: L<https://github.com/mozilla/multi-account-containers/issues/365>

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<container>* => I<str>

=item * B<profile> => I<firefox::local_profile_name>

=item * B<urls> => I<array[str]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 firefox_mua_list_containers

Usage:

 firefox_mua_list_containers(%args) -> [status, msg, payload, meta]

List Firefox Multi-Account Containers add-on's containers.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<profile>* => I<firefox::local_profile_name>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 firefox_mua_modify_containers

Usage:

 firefox_mua_modify_containers(%args) -> [status, msg, payload, meta]

Modify (and delete) Firefox Multi-Account Containers add-on's containers with Perl code.

Examples:

=over

=item * Delete all containers matching some conditions (remove -n to actually delete it):

 firefox_mua_modify_containers(
     profile => "myprofile",
   code => "return 0 if \$_->{icon} eq \"cart\" || \$_->{name} =~ /temp/i; \$_"
 );

=item * Delete all containers (remove -n to actually delete it):

 firefox_mua_modify_containers( profile => "myprofile", code => 0);

=item * Change all icons to "dollar" and all colors to "red":

 firefox_mua_modify_containers(
     profile => "myprofile",
   code => "\$_->{icon} = \"dollar\"; \$_->{color} = \"red\"; \$_"
 );

=back

This utility lets you modify the identity records in C<containers.json> file
using Perl code. The Perl code is called for every container (record). It is
given the record hash in C<$_> and is supposed to modify and return the modified
the record. It can also choose to return false to instruct deleting the record.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<code|str>

=item * B<profile>* => I<firefox::local_profile_name>


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



=head2 firefox_mua_sort_containers

Usage:

 firefox_mua_sort_containers(%args) -> [status, msg, payload, meta]

Sort Firefox Multi-Account Containers add-on's containers.

At the time of this writing, the UI of the Firefox Multi-Account Containers
add-on does not provide a way to sort the containers. Thus this utility.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<profile>* => I<firefox::local_profile_name>

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

"Open external links in a container" add-on,
L<https://addons.mozilla.org/en-US/firefox/addon/open-url-in-container/> (repo
at L<https://github.com/honsiorovskyi/open-url-in-container/>). The add-on also
comes with a bash launcher script:
L<https://github.com/honsiorovskyi/open-url-in-container/blob/master/bin/launcher.sh>.
This C<firefox-container> Perl script is a slightly enhanced version of that
launcher script.

Some other CLI utilities related to Firefox: L<App::FirefoxUtils>,
L<App::DumpFirefoxHistory>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
