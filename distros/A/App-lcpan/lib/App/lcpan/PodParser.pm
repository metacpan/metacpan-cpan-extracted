package App::lcpan::PodParser;

use 5.010;
use strict;
use warnings;
use Log::ger;

use parent qw(Pod::Simple::Methody);

use List::Util qw(first);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-26'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.074'; # VERSION

sub handle_text {
    my $self = shift;

    # to reduce false positive with regular words, in naked text we only look
    # for modules that have namespaces, e.g. 'Foo::Bar' and not top-level
    # modules like 'strict' or 'warnings'. we also don't look for scripts
    # because script names might be regular words or proper nouns too like 'yes'
    # or 'wikipedia'.
    while ($_[0] =~ /\b([A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)+)\b/g) {
        my ($module_id, $module_name);
        if ($self->{module_ids}{$1}) {

            # skip if mention target is in the same release
            next if $self->{module_file_ids}{$1} == $self->{file_id};

            log_trace("    found a mention in naked text to known module: %s", $1);
            $module_id = $self->{module_ids}{$1};
        } else {
            log_trace("    found a mention in naked text to unknown module: %s", $1);
            $module_name = $1;
        }
        my $now = time();
        $self->{sth_ins_mention}->execute(
            $self->{content_id}, $self->{file_id}, $module_id, $module_name, undef,
            $now,$now,
        );
    }
}

sub start_L {
    my $self = shift;

    return unless $_[0]{type} eq 'pod' && $_[0]{to};
    my $to = "" . $_[0]{to};

    my ($module_id, $module_name, $script_name);
    if ($self->{module_ids}{$to}) {

        # skip if mention target is in the same release
        return if $self->{module_file_ids}{$to} == $self->{file_id};

        log_trace("    found a mention in POD link to known module: %s", $to);
        $module_id = $self->{module_ids}{$to};
    } elsif ($to =~ $self->{scripts_re}) {

        # skip if mention target is in the same release
        return if first { $_==$self->{file_id} } @{ $self->{script_file_ids}{$to} };

        log_trace("    found a mention in POD link to known script: %s", $to);
        $script_name = $to;
    } elsif ($to =~ /\A([A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*)\z/) {
        log_trace("    found a mention in POD link to unknown module: %s", $to);
        $module_name = $to;
    } else {
        # name doesn't look like a module name, skip
        return;
    }
    my $now = time();
    $self->{sth_ins_mention}->execute(
        $self->{content_id}, $self->{file_id}, $module_id, $module_name, $script_name,
        $now,$now,
    );
}

1;
# ABSTRACT: Pod parser for use in App::lcpan

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::PodParser - Pod parser for use in App::lcpan

=head1 VERSION

This document describes version 1.074 of App::lcpan::PodParser (from Perl distribution App-lcpan), released on 2023-09-26.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
