package Collection::Utl::Base;

#$Id$

=head1 NAME

 Collection::Utl::Base - abstract class.

=head1 SYNOPSIS

    use Collection::Utl::Base;
    @Collection::ISA = qw(Collection::Utl::Base);

=head1 DESCRIPTION

Abstract class.

=head1 METHODS

=cut


use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
require Exporter;
@Collection::Utl::Base::ISA    = qw(Exporter);
@Collection::Utl::Base::EXPORT = qw(attributes);
$Collection::Utl::Base::VERSION = '0.01';

sub attributes {
    my ($pkg) = caller;
    no strict;
    croak "Error: attributes() invoked multiple times"
      if scalar @{"${pkg}::__ATTRIBUTES__"};

    @{"${pkg}::__ATTRIBUTES__"} = @_;
    my $code = "";
    foreach my $attr (@_) {
        if ( UNIVERSAL::can( $pkg, "$attr" ) ) {
            next;
        }
        $code .= _define_accessor( $pkg, $attr );
    }
    eval $code;
}

sub _define_accessor {
    my ( $pkg, $attr ) = @_;
    my $code = qq{
    package $pkg;
    sub $attr {                                      # Accessor ...
      my \$self=shift;
      \@_ ? \$self->{ Var }->{ $attr } = shift : \$self->{ Var }->{ $attr };
    }
  };
    $code;
}

sub _deprecated {
    my $self       = shift;
    my $new_method = shift;
    my ( $old_method, $called_from_str, $called_from_method ) =
      ( ( caller(1) )[3], ( caller(1) )[2], ( caller(2) )[3] );
    print STDERR 
"called deprecated method $old_method from $called_from_method at line $called_from_str. Use method $new_method instead."
    ;
}

sub new {
    my $class = shift;
    my $self  = ( $#_ == 0 ) ? {} : {@_};
    my $stat;
    bless( $self, $class );
    return ( $stat = $self->_init(@_) ) ? $self : $stat;
}

sub _init {
    my $self = shift;
    return 1;
}


# Preloaded methods go here.

1;
__END__


=head1 SEE ALSO

Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
