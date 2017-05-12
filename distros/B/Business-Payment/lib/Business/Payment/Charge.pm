package Business::Payment::Charge;

use Moose;
use Business::Payment::Types;

with 'MooseX::Traits';

has '+_trait_namespace' => (
    default => 'Business::Payment::Charge'
);

has type => (
    is          => 'ro',
    isa         => 'Str',
    default     => 'CHARGE'
);

has amount => (
    is => 'ro',
    isa => 'Math::Currency',
    coerce => 1,
    required => 1
);

has credit_card => (
    is  => 'rw',
    isa => 'Object'
);

has description => (
    is  => 'rw',
    isa => 'Str'
);

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Business::Payment::Charge - Charge to be handled by Processor

=head1 SYNOPSIS

    use Business::Payment;

    my $bp = Business::Payment->new(
        processor => Business::Payment::Processor::Test::True->new
    );

    my $charge = Business::Payment::Charge->new(
        amount => 10.00 # Something Math::Currency can parse
    );

    my $result = $bp->handle($charge);
    if($result->success) {
        print "Success!\n";
    } else {
        print "Failed: ".$result->error_code.": ".$result->error_message."\n";
    }

=head1 DESCRIPTION

Business::Payment::Charge is a unit of work meant to represent a single
transaction to be handled by a processor.

=head1 AUTHOR

Cory G Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
