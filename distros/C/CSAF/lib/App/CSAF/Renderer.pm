package App::CSAF::Renderer;

use 5.010001;
use strict;
use warnings;
use utf8;

use Getopt::Long qw( GetOptionsFromArray :config gnu_compat );
use Pod::Usage;
use Carp;
use Log::Any::Adapter;

use CSAF::Util      qw(file_write);
use CSAF::Util::App qw(cli_error cli_version);
use CSAF::Parser;

sub run {

    my ($class, @args) = @_;

    my %options = ();

    delete $ENV{CSAF_DEBUG};

    GetOptionsFromArray(
        \@args, \%options, qw(
            file|f=s
            output|o=s
            template|t=s
            verbose|v

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

    $options{template} //= 'default';

    unless ($options{file}) {
        cli_error("Specify CSAF input file");
        return 255;
    }

    my $csaf = eval { CSAF::Parser->new(file => $options{file})->parse };

    if ($@) {
        cli_error($@);
        return 255;
    }

    if (my @errors = $csaf->validate) {
        say STDERR $_ for (@errors);
    }

    my $rendered = $csaf->render(format => 'html', template => $options{template});

    unless ($options{output}) {
        say $rendered;
        return 0;
    }

    file_write($options{output}, $rendered);
    return 0;

}

1;

__END__

=encoding utf-8

=head1 NAME

App::CSAF::Renderer - Renderer Command Line Interface

=head1 SYNOPSIS

    use App::CSAF::Renderer qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

L<App::CSAF::Renderer> is a "Command Line Interface" helper module for C<csaf2html(1)> command.

=head2 METHODS

=over

=item App::CSAF::Renderer->run(@args)

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
