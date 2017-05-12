package Data::MuForm::Common;
# ABSTRACT: common role
use Moo::Role;

sub munge_field_attr {
    my $field_attr = shift;

  # allow using 'inactive => 1' in a field definition
  if ( exists $field_attr->{inactive} ) {
     my $inactive = delete $field_attr->{inactive};
     $field_attr->{active} = $inactive ? 0 : 1;
  }
  if ( grep { $_ =~ /ra\./ } keys %$field_attr ) {
      munge_field_attr_ra($field_attr);
  }
  if ( my @keys = grep { $_ =~ /msg\./ } keys %$field_attr ) {
     foreach my $key ( @keys ) {
         my $value = delete $field_attr->{$key};
         $key =~ s/msg\.//;
         $field_attr->{messages}{$key} = $value;
     }
  }
  if ( my @keys = grep { $_ =~ /meth\./ } keys %$field_attr ) {
     foreach my $key ( @keys ) {
         my $value = delete $field_attr->{$key};
         $key =~ s/meth\.//;
         $field_attr->{methods}{$key} = $value;
     }
  }
  return $field_attr;
}

my $shortcuts = {
     ea => 'element_attr',
     la => 'label_attr',
     wa => 'wrapper_attr',
     era => 'error_attr',
     ewa => 'element_wrapper_attr',
};

sub munge_field_attr_ra {
    my $args = shift;

    my $render_args = $args->{render_args};
    my $ra = delete $args->{ra};
    if ( $render_args && $ra ) {
        $render_args = merge($render_args, $ra);
    }
    else {
        $render_args = $render_args || $ra || {};
    }
    my @ra_keys = grep { $_ =~ /ra\./ } keys %$args;
    foreach my $key ( @ra_keys ) {
        my @seg = split('\.', $key);
        shift @seg;
        my $new_key = $shortcuts->{$seg[0]} || $seg[0];
        if ( $seg[1] ) {
            $render_args->{$new_key}{$seg[1]} = $args->{$key};
        }
        else {
            $render_args->{$new_key} = $args->{$key};
        }
        delete $args->{$key};
    }
    $args->{render_args} = $render_args;
}

sub munge_render_field_attr {
    my $args = shift;
    if ( my @keys = grep { $_ =~ /^.{2,}\./ } keys %$args ) {
         foreach my $key (@keys) {
             my @seg = split('\.', $key );
             if ( my $new_key = $shortcuts->{$seg[0]} ) {
                 my $value = delete $args->{$key};
                 $args->{$new_key}{$seg[1]} = $value;
             }
         }
    }
}

sub has_flag {
    my ( $self, $flag_name ) = @_;
    return unless $self->can($flag_name);
    return $self->$flag_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Common - common role

=head1 VERSION

version 0.04

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
