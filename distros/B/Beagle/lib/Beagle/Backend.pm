package Beagle::Backend;

use Beagle::Util;

sub type {
    my $class = shift;
    my $root  = shift;
    if ( $root =~ /^(\w+).*:/i ) {
        return lc $1;
    }
    else {
        return 'git';
    }
}

sub new {
    my $class = shift;
    my %args  = @_;

    die 'need root arg' unless exists $args{root};

    my $type = delete $args{type};
    $type ||= root_type( $args{root} );

    unless ($type) {
        if ( $args{root} =~ /^(\w+).*:/i ) {
            $type = lc $1;
        }
        else {
            $type = 'git';
        }
    }

    my $subclass = $class . '::' . $type;
    load_class( $subclass );
    return $subclass->new(%args);
}

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

