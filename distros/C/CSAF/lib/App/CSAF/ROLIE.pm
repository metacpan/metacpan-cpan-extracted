package App::CSAF::ROLIE;

use 5.010001;
use strict;
use warnings;
use utf8;

use Carp;
use File::Spec::Functions qw(catfile);
use Getopt::Long          qw( GetOptionsFromArray :config gnu_compat );
use Pod::Usage;
use YAML::XS 'LoadFile';

use CSAF;
use CSAF::Util::App qw(cli_error cli_version);
use CSAF::ROLIE::Feed;

sub run {

    my ($class, @args) = @_;

    my %options = ();

    delete $ENV{CSAF_DEBUG};

    GetOptionsFromArray(
        \@args, \%options, qw(
            csaf|d=s
            output=s

            tlp-label=s
            feed-title=s
            feed-id=s
            base-url=s

            test
            stdout
            config|c=s

            help|h
            man
            version|v
            verbose
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    return cli_version if defined $options{version};

    if (defined $options{config}) {
        unless (-e $options{config}) {
            cli_error("Config file not found");
            return 255;
        }
    }

    my $rolie = CSAF::ROLIE::Feed->new();

    $rolie->options->config_file($options{'config'}) if defined $options{'config'};

    $rolie->options->csaf_directory($options{'csaf'})   if defined $options{'csaf'};
    $rolie->options->tlp_label($options{'tlp-label'})   if defined $options{'tlp-label'};
    $rolie->options->base_url($options{'base-url'})     if defined $options{'base-url'};
    $rolie->options->feed_id($options{'feed-id'})       if defined $options{'feed-id'};
    $rolie->options->feed_title($options{'feed-title'}) if defined $options{'feed-title'};

    unless ($rolie->options->csaf_directory) {
        cli_error("Specify CSAF input directory");
        return 255;
    }

    unless (-e -d $rolie->options->csaf_directory) {
        cli_error("CSAF input directory not found");
        return 255;
    }

    $options{output} = catfile($rolie->options->csaf_directory, $rolie->options->feed_filename)
        unless defined $options{output};

    say STDERR 'CSAF directory : ' . $rolie->options->csaf_directory;
    say STDERR 'TLP label      : ' . $rolie->options->tlp_label();
    say STDERR 'Base URL       : ' . $rolie->options->base_url();
    say STDERR 'Feed ID        : ' . $rolie->options->feed_id();
    say STDERR 'Feed title     : ' . $rolie->options->feed_title();
    say STDERR 'Feed filename  : ' . $rolie->options->feed_filename();
    say STDERR 'Output file    : ' . $options{output};

    return 0 if ($options{test});

    eval { $rolie->from_csaf_directory($rolie->options->csaf_directory) };

    return cli_error($@) if $@;

    if (defined $options{stdout}) {
        say $rolie->render;
        return 0;
    }

    $rolie->write($options{output});
    say STDERR "ROLIE feed saved in $options{output}";
    return 0;

}

1;

__END__

=encoding utf-8

=head1 NAME

App::CSAF::ROLIE - ROLIE Command Line Interface

=head1 SYNOPSIS

    use App::CSAF::ROLIE qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

L<App::CSAF::ROLIE> is a "Command Line Interface" helper module for C<csaf-rolie(1)> command.

=head2 METHODS

=over

=item App::CSAF::ROLIE->run(@args)

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

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
