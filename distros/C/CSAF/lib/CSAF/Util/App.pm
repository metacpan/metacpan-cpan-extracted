package CSAF::Util::App;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our @EXPORT_OK = (qw[cli_error cli_version]);

sub cli_error {
    my ($error) = @_;
    $error =~ s/ at .* line \d+.*//;
    print STDERR "ERROR: $error\n";
}

sub cli_version {

    (my $progname = $0) =~ s/.*\///;

    require CSAF;

    say <<"VERSION";
$progname version $CSAF::VERSION

Copyright 2023-2024, Giuseppe Di Terlizzi <gdt\@cpan.org>

This program is part of the CSAF distribution and is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

Complete documentation for $progname can be found using 'man $progname'
or on the internet at <https://metacpan.org/dist/CSAF>.
VERSION

    return 0;

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Util::App - Utility for CSAF CLI Applications

=head1 SYNOPSIS

    use CSAF::Util::App qw(cli_version);


=head1 DESCRIPTION

Utility for L<CSAF> CLI Applications.

=head2 FUNCTIONS

=over

=item cli_version

=item cli_error

=back

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
