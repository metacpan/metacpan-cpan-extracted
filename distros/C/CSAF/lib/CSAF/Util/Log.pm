package CSAF::Util::Log;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo::Role;
use Log::Any;

has log => (
    is      => 'ro',
    default => sub { Log::Any->get_logger(filter => \&CSAF::Util::log_formatter, category => (caller(0))[0]) }
);

1;
__END__

=encoding utf-8

=head1 NAME

CSAF::Util::Log - Log utility for CSAF

=head1 SYNOPSIS

    package My::CSAF;

    use Moo;
    with 'CSAF::Util::Log';

    sub my_job {
        my $self = shift;

        $self->log->info("Execute My Job");
    }


=head1 DESCRIPTION

L<CSAF::Util::Log> is L<Moo> role and utility for L<CSAF>.

=head2 METHODS

=over

=item log

Return L<Log::Any> logger.

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
