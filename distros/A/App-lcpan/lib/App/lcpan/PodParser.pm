package App::lcpan::PodParser;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use parent qw(Pod::Simple::Methody);

use List::Util qw(first);

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
        $self->{sth_ins_mention}->execute(
            $self->{content_id}, $self->{file_id}, $module_id, $module_name, undef);
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
    $self->{sth_ins_mention}->execute(
        $self->{content_id}, $self->{file_id}, $module_id, $module_name, $script_name);
}

1;
# ABSTRACT: Pod parser for use in App::lcpan

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::PodParser - Pod parser for use in App::lcpan

=head1 VERSION

This document describes version 1.034 of App::lcpan::PodParser (from Perl distribution App-lcpan), released on 2019-06-19.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
