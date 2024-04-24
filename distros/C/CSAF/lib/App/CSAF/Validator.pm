package App::CSAF::Validator;

use 5.010001;
use strict;
use warnings;
use utf8;

use Getopt::Long qw( GetOptionsFromArray :config gnu_compat );
use Pod::Usage;
use Carp;

use CSAF;
use CSAF::Util::App qw(cli_error cli_version);
use CSAF::Parser;

sub run {

    my ($class, @args) = @_;

    my %options = ();

    delete $ENV{CSAF_DEBUG};

    GetOptionsFromArray(
        \@args, \%options, qw(
            file|f=s

            help|h
            man
            version|v
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    return cli_version if defined $options{version};

    my $csaf_parser_options = {};

    # Detect input from STDIN
    if (-p STDIN || -f STDIN) {
        $csaf_parser_options->{content} = do { local $/; <STDIN> };
    }

    if (defined $options{file}) {
        $csaf_parser_options->{file} = $options{file};
    }

    if (%{$csaf_parser_options}) {

        my $csaf = eval { CSAF::Parser->new(%{$csaf_parser_options})->parse };

        if ($@) {
            cli_error($@);
            return 255;
        }

        if (my @errors = $csaf->validate) {
            say STDERR $_ for (@errors);
            return 1;
        }

        say STDERR "CSAF Document valid";
        return 0;

    }

    pod2usage(-verbose => 0);
    return 0;

}

1;

__END__

=encoding utf-8

=head1 NAME

App::CSAF::Validator - Validator Command Line Interface

=head1 SYNOPSIS

    use App::CSAF::Validator qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

L<App::CSAF::Validator> is a "Command Line Interface" helper module for C<csaf-validator(1)> command.

=head2 METHODS

=over

=item App::CSAF::Validator->run(@args)

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
