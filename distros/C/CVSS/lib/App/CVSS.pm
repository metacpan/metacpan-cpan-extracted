package App::CVSS;

use feature ':5.10';
use strict;
use warnings;
use utf8;

use Getopt::Long qw(GetOptionsFromArray :config gnu_compat);
use Pod::Usage   qw(pod2usage);
use Carp         ();
use JSON::PP     ();
use Data::Dumper ();

use CVSS;

our $VERSION = $CVSS::VERSION;

sub cli_error {
    my ($error) = @_;
    $error =~ s/ at .* line \d+.*//;
    print STDERR "ERROR: $error\n";
}

sub run {

    my ($class, @args) = @_;

    my %options = (format => 'json');

    GetOptionsFromArray(
        \@args, \%options, qw(
            help|h
            man
            v

            vector-string=s

            severity
            base-severity

            score
            base-score

            null|0
            format=s

            json
            xml
        )
    ) or pod2usage(-verbose => 0);

    pod2usage(-exitstatus => 0, -verbose => 2) if defined $options{man};
    pod2usage(-exitstatus => 0, -verbose => 0) if defined $options{help};

    if (defined $options{v}) {

        (my $progname = $0) =~ s/.*\///;

        say <<"VERSION";
$progname version $URI::PackageURL::VERSION

Copyright 2023-2024, Giuseppe Di Terlizzi <gdt\@cpan.org>

This program is part of the "CVSS" distribution and is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

Complete documentation for $progname can be found using 'man $progname'
or on the internet at <https://metacpan.org/dist/CVSS>.
VERSION

        return 0;

    }

    my ($vector_string) = @args;

    pod2usage(-verbose => 1) if !$vector_string;

    $options{format} = 'json' if defined $options{json};
    $options{format} = 'xml'  if defined $options{xml};

    $options{'base-severity'} = 1 if defined $options{severity};
    $options{'base-score'}    = 1 if defined $options{score};

    my $cvss = eval { CVSS->from_vector_string($vector_string) };

    if ($@) {
        cli_error($@);
        return 1;
    }

    if ($options{'base-severity'}) {
        print $cvss->base_severity . (defined $options{null} ? "\0" : "\n");
        return 0;
    }

    if ($options{'base-score'}) {
        print $cvss->base_score . (defined $options{null} ? "\0" : "\n");
        return 0;
    }

    if ($options{format} eq 'json') {
        print JSON::PP->new->canonical->pretty(1)->convert_blessed(1)->encode($cvss);
        return 0;
    }

    if ($options{format} eq 'xml') {
        print $cvss->to_xml;
        return 0;
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

App::CVSS - CVSS Command Line Interface

=head1 SYNOPSIS

    use App::CVSS qw(run);

    run(\@ARGV);

=head1 DESCRIPTION

App::CVSS "Command Line Interface" helper module for C<cvss(1)>.

=over

=item App::CVSS->run(@args)

Execute the command

=item cli_error($error)

Clean error

=back

=head1 AUTHOR

L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

=head1 COPYRIGHT AND LICENSE

Copyright © 2023-2024 L<Giuseppe Di Terlizzi|https://metacpan.org/author/gdt>

You may use and distribute this module according to the same terms
that Perl is distributed under.

=cut
