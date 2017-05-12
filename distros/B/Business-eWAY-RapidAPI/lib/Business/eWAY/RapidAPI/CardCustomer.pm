package Business::eWAY::RapidAPI::CardCustomer;
$Business::eWAY::RapidAPI::CardCustomer::VERSION = '0.11';
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Business::eWAY::RapidAPI::CardDetails;

extends 'Business::eWAY::RapidAPI::Customer';

has 'CardDetails' =>
  ( is => 'lazy', isa => InstanceOf ['Business::eWAY::RapidAPI::CardDetails'] );
sub _build_CardDetails { Business::eWAY::RapidAPI::CardDetails->new }

sub TO_JSON { return { %{ $_[0] } }; }

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::eWAY::RapidAPI::CardCustomer

=head1 VERSION

version 0.11

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
