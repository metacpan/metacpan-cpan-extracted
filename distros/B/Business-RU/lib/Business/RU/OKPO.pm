package Business::RU::OKPO;

use strict;
use warnings;

use Moose::Role;
requires 'okpo';

sub validate_okpo {
   my $self = shift;

   return unless $self -> okpo();

    my $result1 = 0;
    my $result2 = 0;
    for ( my $i = 0; $i < length( $self -> okpo() ) - 1; $i ++ ) {
        $result1 += substr( $self -> okpo(), $i, 1) * ( ( $i + 1 ) % 11 );
        $result2 += substr( $self -> okpo(), $i, 1) * ( ( $i + 3 ) % 11 );
    }

    return 
        ( ( $result1 % 11 ) > 9 )
            ? substr( $self -> okpo(), length( $self -> okpo() ) - 1, 1 ) == $result2 % 11 % 10
            : substr( $self -> okpo(), length( $self -> okpo() ) - 1, 1 ) == $result1 % 11;
}

1;

__END__

=pod

=head1 NAME

Business::RU::OKPO

=head1 SYNOPSIS

    package myDecorator;
    use Moose;
    has 'okpo' => ( is => 'ro', isa => 'Int' );
    with 'Business::RU::OKPO';

    my $decorator = myDecorator  ->  new( okpo => 123456789 );
    if( $decorator  ->  validate_okpo() ) {
        ... success ...
    } else {
        ... process error ...
    }

=head1 DESCRIPTION

Validate russian national classification of enterprises and organizations (OKPO)
B<NOTE:> This role expects that it's consuming class will have a C<okpo> method.

=head1 METHODS

=head2 validate_okpo()

Validate OKPO.
Return true if OKPO valid.

=head1 SEE ALSO

L<http://ru.wikipedia.org/wiki/%D0%9E%D0%9A%D0%9F%D0%9E>

=head1 BUGS

Please report any bugs through the web interface at L<http://rt.cpan.org> 
or L<https://github.com/GermanS/Business-RU>

=head1 AUTHOR

German Semenkov
german.semenkov@gmail.com

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut