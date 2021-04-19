package PDL::Logical;

# ABSTRACT: PDL subclass for keeping logical data

use 5.016;
use warnings;

use PDL::Lite ();   # PDL::Lite is the minimal to get PDL work
use PDL::Core qw(pdl);

use Ref::Util qw(is_plain_arrayref);
use Safe::Isa;

use parent 'PDL';
use Class::Method::Modifiers;

sub new {
    my ( $class, @args ) = @_;

    my $data;
    if ( @args % 2 != 0 ) {
        $data = shift @args;    # first arg
    }
    my %opt = @args;

    if ( $data->$_DOES('PDL') ) {
        $data = !!$data;
    }
    elsif ( is_plain_arrayref($data) ) {

        # this is faster than Data::Rmap::rmap().
        state $rmap = sub {
            my ($x) = @_;
            is_plain_arrayref($x)
              ? [ map { __SUB__->($_) } @$x ]
              : ( $x ? 1 : 0 );
        };

        $data = pdl( $rmap->($data) );
    }
    else {
        $data = pdl( $data ? 1 : 0 );
    }

    my $self = $class->initialize();
    $self->{PDL} .= $data;

    return $self;
}

sub initialize {
    my ($class) = @_;
    return bless( { PDL => PDL::Core::null }, $class );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::Logical - PDL subclass for keeping logical data

=head1 VERSION

version 0.0056

=head1 SYNOPSIS

    use PDL::Logical ();
    
    # below does what you mean, while pdl([true, false]) does not
    use boolean;
    my $logical = PDL::Logical->new([ true, false ]);

=head1 DESCRIPTION

This class represents piddle of logical values. It provides a way to
treat data as booleans and convert them to piddles.

=head1 SEE ALSO

L<PDL>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2020 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
