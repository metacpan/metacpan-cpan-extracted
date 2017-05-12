package Business::Payment::Result;
use Moose;

has error_code => (
    is => 'ro',
    isa => 'Num'
);

has error_message => (
    is => 'ro',
    isa => 'Str'
);

has success => (
    is => 'ro',
    isa => 'Bool',
    required => 1
);

has extra => (
    is => 'rw',
    isa => 'HashRef'
);

has 'avs_response' => (
    is  => 'rw',
    isa => 'Str'
);

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Business::Payment::Result - Result of a handled charge

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

Business::Payment::Result contains the results of a handled charge.  It's most
basic indicator is the C<success> attribute.  If the charge was not successful
then the C<success> attribute will be false and the C<error_message> and
C<error_code> attribute should be set.

=head1 AUTHOR

Cory G Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
