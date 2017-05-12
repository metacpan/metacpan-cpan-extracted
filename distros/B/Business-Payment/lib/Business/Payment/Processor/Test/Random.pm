package Business::Payment::Processor::Test::Random;
use Moose;

with 'Business::Payment::Processor';

use Business::Payment::Result;

sub request      { return ( 'OK', 'OK' ); }
sub prepare_data { return {} };
sub prepare_result {
    my ($self, $page, $response) = @_;

    srand(time);

    my $success = int(rand(1));

    my $result;

    if($success) {
        $result = Business::Payment::Result->new(
            success => 1,
        );
    } else {
        $result = Business::Payment::Result->new(
            success => 0,
            error_code => -1,
            error_message => 'Failed on purpose!'
        );
    }

    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Business::Payment::Processor::Test::Random - Test Processor

=head1 SYNOPSIS

    use Business::Payment;

    my $bp = Business::Payment->new(
        processor => Business::Payment::Processor::Test::Random->new
    );

    my $charge = Business::Payment::Charge->new(
        amount => 10.00 # Something Math::Currency can parse
    );

    my $result = $bp->handle($charge);

    my $result = $bp->handle($charge);
    if($result->success) {
        print "Success!\n";
    } else {
        print "Failed: ".$result->error_code.": ".$result->error_message."\n";
    }

=head1 DESCRIPTION

Business::Payment::Processor::Test::Random is test processor that randomly
decides if a charge succeeds or fails.  This is useful for testing.

=head1 AUTHOR

Cory G Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
