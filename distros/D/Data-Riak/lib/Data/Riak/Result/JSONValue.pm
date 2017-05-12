package Data::Riak::Result::JSONValue;
{
  $Data::Riak::Result::JSONValue::VERSION = '2.0';
}
# ABSTRACT: A result containing JSON data

use Moose::Role;
use JSON 'decode_json';
use namespace::autoclean;


sub json_value {
    my ($self) = @_;
    decode_json $self->value;
}

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::JSONValue - A result containing JSON data

=head1 VERSION

version 2.0

=head1 DESCRIPTION

Results for requests resulting in JSON data use this role to provide convenient
access to the decoded body payload.

=head1 METHODS

=head2 json_value

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
