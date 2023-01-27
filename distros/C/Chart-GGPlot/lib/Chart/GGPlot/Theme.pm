package Chart::GGPlot::Theme;

# ABSTRACT: Class for themes

use Chart::GGPlot::Setup;
use Function::Parameters qw(classmethod);

our $VERSION = '0.002002'; # VERSION

use parent qw(Chart::GGPlot::Params);

use List::AllUtils qw(reduce pairmap);
use Types::Standard qw(ArrayRef Bool HashRef InstanceOf Num Str);

use Chart::GGPlot::Global;
use Chart::GGPlot::Theme::ElementTree;
use Chart::GGPlot::Types qw(:all);

classmethod new ( @rest ) {
    my %params = @rest == 1 ? %{ $rest[0] } : @rest;
    return $class->_theme(%params);
}

classmethod _theme (:$complete = false, %elements ) {

    # Check that all elements have the correct class (element_text, unit, etc)
    %elements =
      map { $_ => $class->_validate_element( $elements{$_}, $_ ); }
      (sort keys %elements);

    # If complete theme set all non-blank elements to inherit from blanks
    if ($complete) {
        %elements = pairmap {
            my $el = $b;
            if ( $el->$_DOES('Chart::GGPlot::Theme::Element')
                and !$el->$_DOES('Chart::GGPlot::Theme::Element::Blank') )
            {
                $el->set( 'inherit_blank', true );
            }
            $a => $el;
        }
        %elements;
    }

    return bless(
        {
            _hash    => \%elements,
            complete => $complete,
        },
        $class
    );
}

method is_complete() { $self->{complete} }

# override Chart::GGPlot::Aes's transform_key().
method transform_key ($key) {
    return Chart::GGPlot::Theme::ElementTree->transform_key($key);
}


method calc_element ($elname) {
    my $message = "calc_element: $elname -->";

    # If this is element_blank, don't inherit anything from parents
    my $el = $self->at($elname);
    if ( $el->$_DOES('Chart::GGPlot::Theme::Element::Blank') ) {
        $log->debug( $message . ' element_blank (no inheritance)' )
          if $log->is_debug;
        return $el;
    }

    # If the element is defined (and not just inherited), check that
    # it is of the class specified in .element_tree
    my $eldef = Chart::GGPlot::Global->element_tree->at($elname);

    my $eldef_type = $eldef->{type};
    if ( defined $el and not $eldef_type->check($el) ) {
        die( "Invalid element type for '$elname': "
              . $eldef_type->get_message() );
    }

    # Get the names of parents from the inheritance tree
    my $pnames = $eldef->{inherit};

    # If no parents, this is a "root" node. Just return this element.
    if ( !@$pnames ) {
        my $nullprops = $el->parameters->grep( sub { !defined $el->at($_) } );
        if (@$nullprops) {
            die( sprintf "Theme element '%s' has undef property: %s",
                $elname, join( ", ", @$nullprops ) );
        }
        $log->debug( $message . ' nothing (top level)' ) if $log->is_debug;
        return $el;
    }

    # Calculate the parent objects' inheritance
    $log->debug( $message . ' ' . join( ', ', @$pnames ) ) if $log->is_debug;
    my $parents = $pnames->map( sub { $self->calc_element($_) } );

    return reduce { $self->_combine_elements( $a, $b ) } $el, @$parents;
}

# Check that an element object has the proper class
classmethod _validate_element ( $el, $elname ) {
    my $eldef = Chart::GGPlot::Global->element_tree->at($elname);
    unless ($eldef) {
        die("'$elname' is not a valid theme element name.");
    }

    # undef values for elements are OK
    return undef unless defined $el;

    my $eldef_type = $eldef->{type};
    eval {
        ($el) = Type::Params::validate([$el], $eldef_type);
    };
    if ($@) {
        unless ($el->$_DOES('Chart::GGPlot::Theme::Element::Blank')) {
            die( "Invalid element type for '$elname': $@" );
        }
    }
    return $el;
}

classmethod _combine_elements ($e1, $e2) {
    return $e1
      if ( !defined $e2
        or $e1->$_DOES("Chart::GGPlot::Theme::Element::Blank") );
    return $e2 unless defined $e1;
    if ( $e2->$_DOES("Chart::GGPlot::Theme::Element::Blank") ) {
        return ( $e1->at('inherit_blank') ? $e2 : $e1 );
    }

    my $rslt = $e1->clone;
    for ( $e2->parameters->flatten ) {
        unless ( defined $e1->at($_) ) {
            $rslt->set( $_, $e2->at($_) );
        }
    }

    # Calculate relative sizes
    my $e1_size = $e1->at('size');
    if ( $e1_size->$_DOES('Chart::GGPlot::Theme::Rel') )
    {
        $rslt->set('size', $e2->at('size') * $e1->at('size') );
    }

    return $rslt;
}


method add_theme (Theme $other) {

    # Iterate over the elements that are to be updated
    for my $item ( $other->names ) {
        my $x = $self->at($item);
        my $y = $other->at($item);

        if ( !defined $x or $x->$_DOES('Chart::GGProt::Theme::Element::Blank') )
        {
            $x = $y;
        }
        elsif (!defined $y
            or $y->$_DOES('Chart::GGProt::Theme::Element::Blank')
            or ref($y) )
        {
            $x = $y;
        }
        else {
            $x = $x->merge($y);
        }

        # Assign it back to $self
        $self->set( $item, $x );
    }

    # If either theme is complete, then the combined theme is complete
    $self->{complete} = ( $self->{complete} or $other->{complete} );
    return $self;
}

method replace (Theme $other) {
    my $new = $self->clone;
    for my $elname ( $other->names->flatten ) {
        $new->set( $elname, $other->at($elname) );
    }
    $new->{complete} = $other->{complete};
    return $new;
}


method string () {
    return Dumper( $self->elements );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme - Class for themes

=head1 VERSION

version 0.002002

=head1 DESCRIPTION

Themes are a powerful way to customize the non-data components of your
plots: i.e. titles, labels, fonts, background, gridlines, and legends.
Themes can be used to give plots a consistent customized look.

=head1 METHODS

=head2 calc_element($theme)

Calculate the element properties, by inheriting properties from its parents.

=head2 add_theme($other)

Modify properties of an element in a theme object

=head2 string()

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
