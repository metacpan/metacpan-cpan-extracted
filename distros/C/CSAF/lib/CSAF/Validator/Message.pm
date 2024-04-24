package CSAF::Validator::Message;

use 5.010001;
use strict;
use warnings;
use utf8;

use Moo;

use overload '""' => \&to_string, bool => sub {1}, fallback => 1;

has message  => (is => 'ro', required => 1);
has code     => (is => 'ro');
has path     => (is => 'ro');
has type     => (is => 'ro', default  => 'error');
has category => (is => 'ro', required => 1);

sub to_string {
    sprintf '[%s] %s: %s (%s - %s)', $_[0]->type, $_[0]->path, $_[0]->message, $_[0]->code, $_[0]->category;
}

sub TO_JSON {

    return {
        type     => $_[0]->type,
        category => $_[0]->category,
        message  => $_[0]->message,
        path     => $_[0]->path,
        code     => $_[0]->code
    };

}

1;

__END__

=encoding utf-8

=head1 NAME

CSAF::Validator::Message - Validator Message

=head1 SYNOPSIS

    use CSAF::Validator::Message;

    my $message = CSAF::Validator::Message->new(
        type     => 'info',
        category => 'MY-CATEGORY',
        message  => 'Test message',
        path     => '/document',
        code     => '200'
    );

    say $message; # [info] /document: Test message (200 - MY-CATEGORY)

=head1 DESCRIPTION

Message class for L<CSAF::Validator>.

=head2 PROPERTIES

=over

=item message

=item code

=item path

=item type

=item category

=back

=head2 METHODS

=over

=item to_string

=item TO_JSON

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
