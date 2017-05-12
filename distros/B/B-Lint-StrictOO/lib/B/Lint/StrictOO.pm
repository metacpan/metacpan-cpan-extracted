package B::Lint::StrictOO;
BEGIN {
  $B::Lint::StrictOO::VERSION = '0.04';
}
# ABSTRACT: Apply strict to classes and methods


use 5.006;
use strict;
use warnings;

use B::Lint 1.09 ();
B::Lint->register_plugin( __PACKAGE__, [ 'oo' ] );

use B::Utils 0.10 ();

use constant _invocant_is_lexical_object => 1;
use constant _invocant_is_global_object  => 2;
use constant _invocant_is_literal_class  => 3;
use constant _invocant_is_unknown        => 4;


sub match {
    # Arguments:
    #
    #   0: the opcode to check. It will always be some subclass of
    #      B::OP but the only ones I'm interested in are B::LISTOP.
    #
    #   1: a hash of currently enabled checks. This check is looking
    #      for the 'oo' check.
    my B::OP $op_entersub = $_[0];
    my       $check       = $_[1];

    return if ! $check->{oo};

    # We're looking for method invocations. Method calls are just a
    # special case of invoking a function so I'm looking for entersub.
    #
    #   perl -MO=Terse -e 'XXX->xxx';
    #
    #       UNOP entersub
    #          OP pushmark
    #          SVOP const PV "XXX"            <<<< invocant
    #          ...                            <<<< more arguments
    #          SVOP method_named PV "xxx"     <<<< method name
    #
    return if $op_entersub->name ne 'entersub';

    # Fetch the ops for the invocant and method name
    my @children = $op_entersub->first;
    push @children, $children[0]->siblings;

    # Skip past the leading pushmark
    for ( ;
          @children && $children[0]->oldname eq 'pushmark';
          shift @children ) {
    }

    # Remove null children
    for ( ;
          @children && ! ${$children[-1]};
          pop @children ) {
    }

    my B::SVOP $invocant_op = $children[0];
    my B::SVOP $method_op   = $children[-1];

    # Not a method call at all!
    return if $invocant_op == $method_op;

    my $category = guess_invocant_category( $invocant_op );

    if ( _invocant_is_literal_class() == $category ) {
        lint_class_method_call(
            $invocant_op,
            $method_op
        );
        return;
    }

# TODO:
#     if ( _invocant_is_lexical_object() == $category
#          || _invocant_is_global_object() == $category
#          || _invocant_is_unknown() == $category
#     ) {
#         lint_object_method_call(
#             $invocant_op,
#             $method_op
#         );
#         return;
#     }

    return;
}


#sub B::OP::siblings {
#    my @siblings = $_[0];
#
#    my $sibling;
#    while ( $siblings[-1]->can('sibling') ) {
#        push @siblings, $siblings[-1]->sibling;
#    }
#    shift @siblings;
#
#    # Remove trailing B::NULL
#    pop @siblings while @siblings && ! ${$siblings[-1]};
#
#    return @siblings;
#}


sub class_exists {
    my $target = $_[0];
    my @parts =
        map { "${_}::" }
        split /::/, $target;

    my $symbol_table = \ %main::;
    for my $part ( @parts ) {
        if ( exists $symbol_table->{$part} ) {
            $symbol_table = $symbol_table->{$part};
        }
        else {
            return 0;
        }
    }

    return 1;
}


sub lint_class_method_call {
    my B::OP $invocant_op = $_[0];
    my B::OP $method_op   = $_[1];

    my $class_name;
    if ( $invocant_op->can('sv_harder') ) {
        $class_name = $invocant_op->sv_harder->PV;
    }

    my $method_name;
    if ( $method_op->can('sv_harder') ) {
        $method_name = $method_op->sv_harder->PV;
    }

    # check strict classes
    if ( defined $class_name ) {
        if ( class_exists( $class_name ) ) {
            # Class is ok!

            if ( defined $method_name ) {
                if ( $class_name->can( $method_name ) ) {
                    # Class + method are ok!
                }
                else {
                    B::Lint::warning "Class $class_name can't do method $method_name";
                }
            }
            else {
                B::Lint::warning "Symbolic method call";
            }
        }
        else {
            B::Lint::warning "Class $class_name doesn't exist";
        }
    }
    elsif ( defined $method_name
            && ! nearby_classes_perform( $method_name )
    ) {
        B::Lint::warning "Object can't do method $method_name";
    }

    return;
}


sub nearby_classes_perform {
    my ( $method_name ) = @_;

    for my $class_name ( @{nearby_classes_in_current_file()} ) {
        return 1 if $class_name->can($method_name);
    }

    return 0;
}


sub guess_invocant_category {
    my ( $op ) = @_;

    # We've been handed a B::NULL object which is a representation for
    # a null pointer.
    if ( ! $$op ) {
        return _invocant_is_unknown();
    }

    my $op_name = $op->oldname;

    # Descend past this type of code. This is very silly.
    #
    #   scalar( scalar( scalar( $invocant ) ) )->xxx
    #
    for ( ;
          $op_name eq 'scalar' || $op_name eq 'null';
          $op = $op->first, $op_name = $op->name ) {
    }

    # A class method call
    #   perl -MO=Terse -e 'Foo->xxx'
    #     UNOP entersub
    #         OP pushmark
    #         SVOP const PV "XXX"
    #         SVOP method_named PV "xxx"
    if ( $op_name eq 'const' ) {
        return _invocant_is_literal_class();
    }

# TODO:
#    # An object method call using a lexical:
#    #
#    #   perl -MO=Terse -e 'my $foo; $foo->xxx'
#    #
#    #     UNOP entersub
#    #         OP pushmark
#    #         OP padsv
#    #         SVOP method_named PV "xxx"
#    #
#    if ( $op_name eq 'padsv' ) {
#        return _invocant_is_lexical_object();
#    }
#
#    # An object method call using a global:
#    #
#    #   perl -MO=Terse -e '$foo->xxx'
#    #
#    #     UNOP entersub
#    #         OP pushmark
#    #         UNOP null
#    #             PADOP gvsv  GV *foo
#    #         SVOP method_named PV "xxx"
#    #
#    if ( $op_name eq 'gvsv' ) {
#        return _invocant_is_global_object();
#    }

    return _invocant_is_unknown();
}


our %nearby_classes_cache;
sub nearby_classes_in_current_file {
    my $file = B::Lint->file;

    return $nearby_classes_cache{$file}
        ||= nearby_classes_in_file( $file );
}


sub nearby_classes_in_file {
    my ( $file ) = @_;
    my $src = File::Slurp::read_file( $file );

    my @mentioned_potential_classes = $src =~ /
        (
            (?> \w+ )
            (?:
                ::
                (?> \w+ )
            )+
        )
    /gx;

    my %seen;
    my @mentioned_classes =
        grep {
            class_exists( $_ )
            && ! $seen{$_}++
        }
        @mentioned_potential_classes;

    return [ sort keys %seen ];
}

'Why did the elf cross the road? To get to the ';



=pod

=head1 NAME

B::Lint::StrictOO - Apply strict to classes and methods

=head1 VERSION

version 0.04

=head1 METHODS

=head2 match

=head2 class_exists

=head2 lint_class_method_call

=head2 nearby_classes_perform

=head2 guess_invocant_category

=head2 nearby_classes_in_current_file

=head2 nearby_classes_in_file

=head1 SYNOPSIS
Validates that classes exist, that methods that are called on classes
and objects, and variables aren't used as method names.

From the command line:

    perl -MB::Lint::StrictOO -MO=Lint,oo my_file.pl

Against a program F<my_file.pl>:

    sub Hickory::Dickory::dock;

    Mouse->dockk;           # Class Mouse doesn't exist
    Hickory::Dickory->dock;
    Hickory::Dickory->$_;   # Symbolic method call
    $obj->dockk;            # Object can't do method
    $obj->dock;
    $obj->$_;               # Symbolic method call

=head1 PRIVATE API

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc B::Lint::StrictOO

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/B-Lint-StrictOO>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/B-Lint-StrictOO>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=B-Lint-StrictOO>

=item * Search CPAN

L<http://search.cpan.org/dist/B-Lint-StrictOO>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Josh Jore <jjore@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Josh Jore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

