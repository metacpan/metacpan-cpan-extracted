package Business::Payment::Processor::Test::False;

use Moose;

with 'Business::Payment::Processor';

use Business::Payment::Result;

sub request { return ( 'OK', 'OK' ); }
sub prepare_data { return {} };

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Business::Payment::Processor::Test::False - Test Processor

=head1 SYNOPSIS

    use Business::Payment;

    my $bp = Business::Payment->new(
        processor => Business::Payment::Processor::Test::False->new
    );

    my $charge = Business::Payment::Charge->new(
        amount => 10.00 # Something Math::Currency can parse
    );

    my $result = $bp->handle($charge);

    print "Failed: ".$result->error_code.": ".$result->error_message."\n";

=head1 DESCRIPTION

Business::Payment::Processor::Test::False is test processor that always fails.

=head1 AUTHOR

Cory G Watson, C<< <gphat@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Cold Hard Code, LLC, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
