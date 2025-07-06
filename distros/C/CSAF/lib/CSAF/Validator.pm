package CSAF::Validator;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Validator::MandatoryTests;
use CSAF::Validator::OptionalTests;
use CSAF::Validator::InformativeTests;

use CSAF::Validator::Schema;
use CSAF::Validator::Message;

use constant DEBUG => $ENV{CSAF_VALIDATOR_DEBUG};

use Moo;
extends 'CSAF::Validator::Base';
with 'CSAF::Util::Log';

sub validate {

    my ($self, $type) = @_;

    my %validator = (

        # 9.1.14 Conformance Clause 14: CSAF basic validator
        schema    => sub { CSAF::Validator::Schema->new($self->csaf)->validate },
        mandatory => sub { CSAF::Validator::MandatoryTests->new($self->csaf)->validate },

        # 9.1.15 Conformance Clause 15: CSAF extended validator
        optional => sub { CSAF::Validator::OptionalTests->new($self->csaf)->validate },

        # 9.1.16 Conformance Clause 16: CSAF full validator
        informative => sub { CSAF::Validator::InformativeTests->new($self->csaf)->validate },

    );

    my @types    = (qw[schema mandatory optional informative]);
    my @messages = ();

    if (defined $type && defined $validator{$type}) {
        @types = ($type);
    }

    foreach (@types) {
        push @messages, $validator{$_}->();
    }

    push @{$self->messages}, @messages;

    if (DEBUG && @{$self->messages}) {
        $self->log->debug('Validation messages(s)');
        $self->log->debug(sprintf('- %s', $_)) for (@{$self->messages});
    }

    return @{$self->messages};

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Validator - Conformance Validator

=head1 SYNOPSIS

    use CSAF::Validator;

    my $v = CSAF::Validator( csaf => $csaf );
    my @messages = $v->validate;

    if ($v->has_error) {
        say "Validator errors";
        say $_ for (@messages);
    }



=head1 DESCRIPTION

L<CSAF::Validator> reads documents and performs a check against the JSON schema 
(L<CSAF::Validator::Schema>), performs all mandatory (L<CSAF::Validator::MandatoryTests>),
optional (L<CSAF::Validator::OptionalTests>) and informative tests (L<CSAF::Validator::Informative>).

Conformance profiles:

=over

=item * CSAF basic validator: A program that reads a document and checks it against the JSON schema and performs mandatory tests.

=item * CSAF extended validator: A CSAF basic validator that additionally performs optional tests.

=item * CSAF full validator: A CSAF extended validator that additionally performs informative tests.

=back

L<https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html>


=head2 METHODS

L<CSAF::Validator> inherits all methods from L<CSAF::Validator::Base> and implements the following new ones.

=over

=item validate ( [$type] )

Execute all validation tests type (C<schema>, C<mandatory>, C<optional> and C<informative>)
and return all validation messages.

    my @messages = $v->validate;
    say $_ for (@messages);

    # Execute only the mandatory tests

    my @messages = $v->validate('mandatory');
    Carp::croak 'Validation error' if @messages;

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

This software is copyright (c) 2023-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
