package Business::RU::INN;

use strict;
use warnings;

use Moose::Role;
requires 'inn';

sub validate_inn {
    my $self = shift;

    return $self -> _validate_individual_inn()
        if $self -> _is_individual();

    return $self -> _validate_company_inn()
        if $self -> _is_company();

    return;
}

sub _validate_company_inn {
    my $self = shift;

    my @weights = qw(2 4 10 3 5 9 4 6 8 0);

    my $result = 0;
    for (my $i = 0; $i < 10; $i++) {
        $result += substr( $self -> inn(), $i, 1 ) * $weights[ $i ];
    }

    return
        substr( $self -> inn(), 9, 1 ) == ($result % 11 % 10);
}


sub _validate_individual_inn {
    my $self = shift;

    my @weights = qw(3 7 2 4 10 3 5 9 4 6 8 0);

    my $result_11 = 0;
    for (my $i = 0; $i < 11; $i++) {
        $result_11 += substr( $self -> inn(), $i, 1 ) * $weights[ $i + 1 ];
    }

    my $result_12 = 0;
    for (my $i = 0;  $i < 12; $i++) {
        $result_12 += substr( $self -> inn(), $i, 1 ) * $weights[ $i ];
    }

    return
        substr( $self -> inn(), 10, 1 ) == ( $result_11 % 11 % 10 ) &&
        substr( $self -> inn(), 11, 1 ) == ( $result_12 % 11 % 10 );
}

sub is_individual {
    my $self = shift;

    return ( $self -> validate_inn() )
        ? $self -> _is_individual()
        : undef;
}

sub _is_individual {
    my $self = shift;
    return length $self -> inn() == 12;
}

sub is_company {
    my $self = shift;

    return ( $self -> validate_inn() )
        ? $self -> _is_company()
        : undef;
}

sub _is_company {
    my $self = shift;
    return length $self -> inn()  == 10;
}

1;

__END__

=pod

=head1 NAME

Business::RU::INN

=head1 SYNOPSIS

    package myDecorator;
    use Moose;
    has 'inn' => ( is => 'ro', isa => 'Int' );
    with 'Business::RU::INN';

    ...

    my $decorator = myDecorator -> new( inn => 123456789 );
    if( $decorator -> validate_inn() ) {
        ... success ...
    } else {
        ... process error ...
    }

    if( $decorator -> is_company() ) {
        ... process company data ..
    }

    if( $decorator -> is_individual() ) {
        ... process data ..
    }

=head1 DESCRIPTION

Validate russian individual taxpayer number.
B<NOTE:> This role expects that it's consuming class will have a C<inn()> method.

=head1 METHODS

=head2 validate_inn()

Validate INN. 
return true if INN valid

=head2 _validate_individual_inn()

Validate short INN. 
Internal method.

=head2 _validate_company_inn()

Validate long INN. 
Internal method.

=head2 is_individual()

Returns true if INN personal

=head2 is_company()

Raturns trus if it's company.

=head1 SEE ALSO

L<http://ru.wikipedia.org/wiki/%D0%98%D0%B4%D0%B5%D0%BD%D1%82%D0%B8%D1%84%D0%B8%D0%BA%D0%B0%D1%86%D0%B8%D0%BE%D0%BD%D0%BD%D1%8B%D0%B9_%D0%BD%D0%BE%D0%BC%D0%B5%D1%80_%D0%BD%D0%B0%D0%BB%D0%BE%D0%B3%D0%BE%D0%BF%D0%BB%D0%B0%D1%82%D0%B5%D0%BB%D1%8C%D1%89%D0%B8%D0%BA%D0%B0>

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