package Chart::GGPlot::Labeller;

# ABSTRACT: Labeller functions for facets

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.0007'; # VERSION

use Data::Munge qw(elem);
use Types::Standard qw(CodeRef HashRef InstanceOf Str);
use namespace::autoclean;

use List::AllUtils qw(each_arrayref pairmap pairwise);
use Data::Frame::Types qw(DataFrame);
use Chart::GGPlot::Util qw(:all);

use overload
  '&{}'    => sub { $_[0]->func },
  fallback => 1;

has func => ( is => 'ro', isa => CodeRef, required => 1 );

around BUILDARGS( $orig, $class : @rest ) {
    my %params;
    if ( @rest == 1 ) {
        %params =
          Ref::Util::is_plain_coderef( $rest[0] )
          ? ( func => $rest[0] )
          : %{ $rest[0] };
    }
    else {
        %params = @rest;
    }
    return $class->$orig(%params);
}

classmethod _collapse_labels_lines ($labeller_out) {
    return $labeller_out->map( sub { join( ', ', @$_ ) } );
}

classmethod label_value ($multi_line=true) {
    my $f = fun( DataFrame $labels) {
        my $ea = each_arrayref(
            @{ $labels->names->map( sub { $labels->at($_)->unpdl } ) } );
        my $rslt =
          [ 0 .. $labels->nrow - 1 ]->map( sub { [ $ea->() ] } );
        return (
              $multi_line
            ? $rslt
            : $class->_collapse_labels_lines($rslt)
        );
    };
    return $class->new($f);
}

classmethod label_both ($multi_line=true, $sep=': ') {
    my $f = fun( DataFrame $labels) {
        my $variables = $labels->names;
        my $ea        = each_arrayref(
            @{ $variables->map( sub { $labels->at($_)->unpdl } ) } );
        my $rslt = [ 0 .. $labels->nrow - 1 ]->map(
            sub {
                my @row_data = $ea->();
                [ pairwise { join( $sep, $a, $b ) } @$variables, @row_data ];
            }
        );
        return (
              $multi_line
            ? $rslt
            : $class->_collapse_labels_lines($rslt)
        );
    };
    return $class->new($f);
}


classmethod label_context ($multi_line=true, $sep=': ') {
    my $f = fun( DataFrame $labels) {
        return (
              $labels->length == 1
            ? $class->label_value($multi_line)->($labels)
            : $class->label_both( $multi_line, $sep )->($labels)
        );
    };
    return $class->new($f);
}


classmethod _labeller_by_name ($x, $multi_line) {
    state $supported_labeller_names = [qw(value both context)];
    if ( !Ref::Util::is_ref($x) and elem( $x, $supported_labeller_names ) ) {
        my $f = "label_$x";
        return $class->$f($multi_line);
    }
    else {
        return $x;
    }
}

classmethod as_labeller ($x, $default='value', $multi_line=true) {
    $x       = $class->_labeller_by_name( $x,       $multi_line );
    $default = $class->_labeller_by_name( $default, $multi_line );

    if ( $x->$_isa($class) ) {
        return $x->func;
    }
    elsif ( Ref::Util::is_plain_coderef($x) ) {
        my $f = fun( DataFrame $labels) {
            return $default->( $labels->apply($x) );
        };
        return $class->new( func => $f );
    }
    else {
        return $default;
    }
}

classmethod _resolve_labeller ($rows, $cols, $labels) {
    unless ( defined $rows or defined $cols ) {
        die "Supply one of rows or cols";
    }
    if ( ( $labels->$_call_if_can('facet') // '' ) eq 'wrap' ) {
        if ( defined $rows and defined $cols ) {
            die "Cannot supply both rows and cols to facet_wrap()";
        }
        return ( $cols // $rows );
    }
    else {
        if ( ( $labels->$_call_if_can('type') // '' ) eq 'rows' )
          {
              return $rows;
        }
        else {
              return $cols;
        }
    }
}


classmethod labeller (:$_rows=undef, :$_cols=undef, :$_multi_line=true,
        :$_default='value', %params) {
      $_default = $class->as_labeller( $_default, 'value', $_multi_line );

      my $f = fun( DataFrame $labels) {
          my $margin_labeller =
            ( defined $_rows or defined $_cols )
            ? $class->_resolve_labeller( $_rows, $_cols, $labels )
            : undef;
          if ( defined $margin_labeller ) {
              return $class->as_labeller( $margin_labeller, $_default );
          }
          else {
              my %labellers = pairmap { $a => $class->as_labeller($b) } %params;
              my $ea = each_arrayref(
                  @{
                      $labels->names->map(
                          sub {
                              my $labeller = $labellers{$_} // $_default;
                              $labeller->( $labels->select_columns( [$_] ) );
                          }
                      )
                  }
              );
              my $rslt = [ 0 .. $labels->nrow - 1 ]->map(
                  sub {
                      my @row_data = $ea->();
                      [ map { @$_ } @row_data ];
                  }
              );
              return (
                    $_multi_line
                  ? $rslt
                  : $class->_collapse_labels_lines($rslt)
              );
          }
      };
      return $class->new( func => $f );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Labeller - Labeller functions for facets

=head1 VERSION

version 0.0007

=head1 DESCRIPTION

Labeller functions are in charge of formatting the strip labels of
facet grids and wraps.

A labeller function has a signature of C<f(DataFrame $labels)>, and 
returns an array ref of labels.

=head1 CLASS METHODS

=head2 label_context($multi_line=true, $sep=': ')

Returns a labeller object, which is equivalent to C<label_value()> for
single factor faceting, and C<label_both()> when multiple factors are
involved.

=head2 as_labeller($x, $default='value', $multi_line=true)

This transforms objects to labeller functions.

    my $appender = sub { $_[0] . '-foo' };
    my $labeller = Chart::GGPlot::Labeller->as_labeller($appender);    

=head2 labeller(:$_rows=undef, :$_cols=undef, $_multi_line=true,
:$_default='value', %params)

=head1 SEE ALSO

L<Chart::GGPlot::Facet>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
