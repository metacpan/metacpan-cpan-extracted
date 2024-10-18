package App::CSAF::Downloader;

use 5.010001;
use strict;
use warnings;
use utf8;

use Getopt::Long qw( GetOptionsFromArray :config gnu_compat );
use Pod::Usage;
use Carp;
use Log::Any::Adapter;

use CSAF::Util::App qw(cli_error cli_version);
use CSAF::Downloader;

sub run {

    my ($class, @args) = @_;

    my %options = ();

    delete $ENV{CSAF_DEBUG};

    GetOptionsFromArray(
        \@args, \%options, qw(
            url|u=s
            directory|d=s
            after=s
            before=s
            insecure|k
            verbose|v
            validate:s
            integrity-check
            signature-check

            include=s
            exclude=s

            config|c=s
            parallel-downloads=i

            help|h
            man
            version
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    return cli_version if defined $options{version};

    if (defined $options{verbose}) {
        Log::Any::Adapter->set('Stderr');
    }

    my $downloader = CSAF::Downloader->new;

    $downloader->options->config_file($options{'config'}) if defined $options{'config'};

    $options{validate} = !!1 if (defined $options{validate} && $options{validate} eq '');

    $downloader->options->url($options{url})                                 if defined $options{url};
    $downloader->options->insecure($options{insecure})                       if defined $options{insecure};
    $downloader->options->directory($options{directory})                     if defined $options{directory};
    $downloader->options->validate($options{validate})                       if defined $options{validate};
    $downloader->options->integrity_check($options{'integrity-check'})       if defined $options{'integrity-check'};
    $downloader->options->signature_check($options{'signature-check'})       if defined $options{'signature-check'};
    $downloader->options->include_pattern($options{include})                 if defined $options{include};
    $downloader->options->exclude_pattern($options{exclude})                 if defined $options{exclude};
    $downloader->options->parallel_downloads($options{'parallel-downloads'}) if defined $options{'parallel-downloads'};
    $downloader->options->after_date($options{'after'})                      if defined $options{'after'};
    $downloader->options->before_date($options{'before'})                    if defined $options{'before'};

    unless ($downloader->options->url) {
        cli_error("Specify URL");
        return 1;
    }

    unless (-e -d $downloader->options->directory) {
        cli_error "Unknown directory";
        return 1;
    }

    eval { $downloader->mirror($downloader->options->url) };

    if ($@) {
        cli_error($@);
        return 1;
    }

    return 0;

}

1;

__END__

=encoding utf-8

=head1 NAME

App::CSAF::Downloader - Downloader Command Line Interface

=head1 SYNOPSIS

    use App::CSAF::Downloader qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

L<App::CSAF::Downloader> is a "Command Line Interface" helper module for C<csaf-downloader(1)> command.

=head2 METHODS

=over

=item App::CSAF::Downloader->run(@args)

=back

Execute the command

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-CSAF/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-CSAF>

    git clone https://github.com/giterlizzi/perl-CSAF.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2023-2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
