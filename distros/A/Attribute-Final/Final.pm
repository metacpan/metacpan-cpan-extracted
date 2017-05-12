package Attribute::Final;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.3';
our %marked;
my @all_packages;
use B qw(svref_2object);

sub fill_packages {
    no strict 'refs';
    my $root = shift;
    my @subs = grep s/::$//, keys %{$root."::"}; 
    push @all_packages, $root;
    for (@subs) {
        next if $root eq "main" and $_ eq "main"; # Loop
        fill_packages($root."::".$_);
    }
}

sub check {
    no strict 'refs';
    fill_packages("main") unless @all_packages;
    for my $derived_pack (@all_packages) {
        next unless @{$derived_pack."::ISA"};
        for my $marked_pack (keys %marked) {
            next unless $derived_pack->isa($marked_pack);
            for my $meth (@{$marked{$marked_pack}}) {
                my $glob_ref = \*{$derived_pack."::".$meth};
                if (*{$glob_ref}{CODE}) {
                    my $name = $marked_pack."::".$meth;
                    my $b = svref_2object($glob_ref);
                    die "Cannot override final method $name at ".
                        $b->FILE. ", line ".$b->LINE."\n";
                }
            }
        }
    }
}

CHECK { Attribute::Final->check() }

package UNIVERSAL;
use Attribute::Handlers;
sub final :ATTR(CODE) {
    my ($pack, $ref) = @_;
    push @{$marked{$pack}}, *{$ref}{NAME};
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Attribute::Final - Provides Java-style finalized methods

=head1 SYNOPSIS

    use Attribute::Final;

    package Beverage::Hot; 
    sub serve :final { ... } 
     
    package Tea; 
    use base 'Beverage::Hot'; 
     
    sub Tea::serve { # Compile-time error. 
    } 

=head1 DESCRIPTION

Final methods are methods which cannot be overriden in derived classes.
This module will allow you to mark some methods as C<:final>; prior to
running the script, Perl will check that no packages which derive from
classes with marked methods override those methods. 

=head1 AUTHOR

Originally by Simon Cozens, C<simon@cpan.org>

Maintained by Scott Penrose, C<scott@cpan.org>

=head1 SEE ALSO

L<java>.

=cut
