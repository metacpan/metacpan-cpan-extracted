package Business::eWAY::RapidAPI::CardDetails;
$Business::eWAY::RapidAPI::CardDetails::VERSION = '0.11';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

has $_ => ( is => 'rw', isa => Str ) foreach (
    'Name',       'Number',    'ExpiryMonth', 'ExpiryYear',
    'StartMonth', 'StartYear', 'IssueNumber', 'CVN'
);

sub TO_JSON { return { %{ $_[0] } }; }

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::eWAY::RapidAPI::CardDetails

=head1 VERSION

version 0.11

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
