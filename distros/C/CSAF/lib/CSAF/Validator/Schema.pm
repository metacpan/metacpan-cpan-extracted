package CSAF::Validator::Schema;

use 5.010001;
use strict;
use warnings;
use utf8;

use CSAF::Schema;
use CSAF::Builder;

use Moo;
extends 'CSAF::Validator::Base';

sub validate {

    my ($self) = @_;

    # 9.1.14 Conformance Clause 14: CSAF basic validator

    my $schema = CSAF::Schema->validator('csaf-2.0');
    my @errors = $schema->validate(CSAF::Builder->new(shift->csaf)->build(1));

    foreach my $error (@errors) {
        $self->add_message(category => 'schema', message => $error->message, path => $error->path, code => '9.1.14');
    }

    return @{$self->messages};

}

1;


__END__

=encoding utf-8

=head1 NAME

CSAF::Validator::Schema - Validate CSAF document using JSON Schema.

=head1 SYNOPSIS

    use CSAF::Validator::Schema;

    my $v = CSAF::Validator::Schema->new( csaf => $csaf );

    $v->validate;


=head1 DESCRIPTION

L<CSAF::Validator::Schema> is a JSON Schema validator for the CSAF documents.

=head2 METHODS

L<CSAF::Validator::InformativeTests> inherits all methods from L<CSAF::Validator::Base>.


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
