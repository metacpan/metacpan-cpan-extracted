package Class::Dynamic;

use 5.006;
our $VERSION = '1.01';

sub UNIVERSAL::AUTOLOAD {
    no strict;
    my $obj = $_[0];
    my $class = ref $obj || $obj;
    my @foo = @{$class."::ISA"};
    $UNIVERSAL::AUTOLOAD =~ /(.*)::(.*)/;
    my $package = $1;
    my $method = $2;
    my $sr;
    while (@foo) {
        last if ($sr = shift @foo) eq "CODE";
    }
    return unless ref $sr;
    my $rv = $sr->($obj, $method);
    $UNIVERSAL::AUTOLOAD =~ s/.*::/${rv}::/;
    if (! defined &$UNIVERSAL::AUTOLOAD) { 
        require Carp; import Carp;
        return if $method eq "DESTROY";
        croak( qq{Can't locate object method "$method" via package "$rv" 
        (perhaps you forgot to load "$rv"?)});
    } else { 
        goto &$UNIVERSAL::AUTOLOAD;
    }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::Dynamic - Rudimentary support for coderefs in @ISA

=head1 SYNOPSIS

  package Blargh;
  use Class::Dynamic;
  our @ISA = ("Foo", sub { rand < 0.5 ? "Bar" : "Baz" } );

=head1 DESCRIPTION

This module allows you to insert coderefs into a class's C<@ISA>.

The coderef is called with the object and method name as parameters, so
that it can determine which class is appropriate. The coderef should
return a string representing the class to delegate the method to.

Suggested uses: mixins, random dispatch, creating classes at runtime...

=head1 BUGS

Almost certainly. This is almost throw-away code, although it does do
something vaguely useful, so I'm not really inclined to answer bug
reports without patches. 

=head1 LICENSE

GPL & AL.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=cut
