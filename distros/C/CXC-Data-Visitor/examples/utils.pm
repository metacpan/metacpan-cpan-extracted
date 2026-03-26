#! perl

use v5.26;
use experimental 'declared_refs';
use feature 'signatures';
use Ref::Util 'is_ref';
use List::Util 'any';
use Term::Table;
use CXC::Data::Visitor -passes;

my %PASS_VISIT
  = ( PASS_VISIT_ELEMENT, 'PASS_VISIT_ELEMENT', PASS_REVISIT_ELEMENT, 'PASS_REVISIT_ELEMENT', );

sub render_element ( $ref, $kydx, $vref, $context, $meta ) {

    my \%meta       = $meta;
    my \@rows       = $context->{rows};
    my \%struct_map = $context->{struct_map};
    my $path;
    for my $ikydx ( $meta{path}->@* ) {
        if ( is_hashref( $ref ) ) {
            $struct_map{$ref} = $path;
            $path .= "{$ikydx}";
            $ref = $ref->{$ikydx};
            $struct_map{$ref} = '\$root' . $path
              if is_ref( $ref );
        }
        elsif ( is_arrayref( $ref ) ) {
            $struct_map{$ref} = $path;
            $path .= "[$ikydx]";
            $ref = $ref->[$ikydx];
            $struct_map{$ref} = '\$root' . $path
              if is_ref( $ref );
        }
    }

    my $value = $struct_map{ $vref->$* } // $vref->$*;
    push @rows,
      {
        path  => '$root' . $path,
        value => $value,
        visit => $meta{visit},
        idx   => $meta{idx},
        pass  => $PASS_VISIT{ $meta{pass} },
      };

    return $path;
}

sub render_table( $rows ) {
    my @header = ( 'path', 'value', 'idx' );

    push @header, 'visit' if any { $_->{visit} > 1 } $rows->@*;
    push @header, 'pass'  if any { $_->{pass} eq 'PASS_REVISIT_ELEMENT' } $rows->@*;

    my $table = Term::Table->new(
        max_width => 100,
        header    => \@header,
        rows      => [ map { [ $_->@{@header} ] } $rows->@* ],
    );

    say "$_" for $table->render;
}

1;
