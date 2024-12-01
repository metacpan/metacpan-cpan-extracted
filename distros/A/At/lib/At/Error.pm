package At::Error {
    use v5.40;
    use Carp qw[];
    no warnings 'experimental::class';    # Be quiet.
    use feature 'class';
    use overload
        bool => sub {0},
        '""' => sub ( $s, $u, $q ) { $s->message };

    class At::Error 1.0 {
        use Exporter 'import';

        BEGIN {
            our @EXPORT = qw[throw register];
        }
        field $message : param : reader;
        field $description : param //= ();
        field $fatal : param       //= 0;
        field @stack;

        # TODO: What should I do with description? Nothing?
        ADJUST {
            my $i = 0;    # Skip one
            while ( my %i = Carp::caller_info( ++$i ) ) {
                next if $i{pack} eq __CLASS__;
                push @stack, \%i;
            }
        }

        method throw() {
            my ( undef, $file, $line ) = caller();
            my $msg = join "\n\t", sprintf( qq[%s at %s line %d], $message, $file, $line ),
                map { sprintf q[%s called at %s line %d], $_->{sub_name}, $_->{file}, $_->{line} } @stack;
            $fatal ? die "$msg\n" : warn "$msg\n";
        }

        sub register( $class, $fatal //= 0 ) {
            my ($from) = caller;
            no strict 'refs';
            *{ $from . '::' . $class } = sub ( $message, $description //= '' ) {
                ($class)->new( message => $message, description => $description, fatal => $fatal );
            };
            push @{ $class . '::ISA' }, __PACKAGE__;    # perlclass screws up package in obj; waiting for an MOP
        }
    }
}
1;
__END__
=encoding utf-8

=head1 NAME

At::Error - Throwable Errors

=head1 SYNOPSIS

    use At::Error;    # You shouldn't be here yet.
    register 'SomeError';

    sub yay {

        # Some stuff here ...
        return SomeError('Oh, no!') if 'pretend someting bad happened';
        return 1;
    }
    my $okay = yay();
    throw $okay unless $okay;    # Errors overload bool to be false

=head1 DESCRIPTION

You shouldn't be here.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

atproto

=end stopwords

=cut
