package DBIx::Class::Validation::Structure;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.15';

use Email::Valid;
use HTML::TagFilter;

use base qw/DBIx::Class/;

use utf8;

sub validate {
  my $self = shift;
  my @check_columns = @_;

  my $check_columns = { map{ $_ => 1 } @check_columns } || {};

  my $source = $self->result_source;
  my %data = $self->get_columns;
  my $columns = $source->columns_info;

  my ($error, @error_list, $stmt);

  for my $column ( keys %$columns ) {

    if ( ( not keys %$check_columns ) or $check_columns->{$column} ) {

      if ($columns->{$column}{validation_function} and ref $columns->{$column}{validation_function} eq 'CODE' ) {
        ($data{$column}, $error) = $columns->{$column}{validation_function}(
          info => $columns->{$column},
          value => $data{$column},
          data => \%data,
          self => $self,
        );
        if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
      } else {
        my $mand = (defined $columns->{$column}{is_nullable} and $columns->{$column}{is_nullable} == 1 or ( defined $columns->{$column}{is_auto_increment} and $columns->{$column}{is_auto_increment} == 1 ) ) ? 0 : 1;
        my $val_type = (defined $columns->{$column}{val_override}) ? $columns->{$column}{val_override} : $columns->{$column}{data_type};

        if ($val_type eq 'email') {
          ($data{$column}, $error) = _val_email( $mand, $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        } elsif ($val_type eq 'varchar' or $val_type eq 'text') {
          ($data{$column}, $error) = _val_text( $mand, $columns->{$column}{size}, $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        } elsif ($val_type eq 'password') {
          ($data{$column}, $error) = _val_password( $mand, $columns->{$column}{size}, $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        } elsif ($val_type eq 'selected') {
          if ($columns->{$column}{data_type} eq 'varchar' or $columns->{$column}{data_type} eq 'text') {
            ($data{$column}, $error) = _val_text( 0, $columns->{$column}{size}, $data{$column} );
            if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
          } else {
            ($data{$column}, $error) = _val_int( 0, $data{$column} );
            if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
          }
          ($data{$column}, $error) = _val_selected( $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        } elsif ($val_type eq 'integer' or $val_type =~ /int/g) {
          ($data{$column}, $error) = _val_int( $mand, $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        } elsif ($val_type eq 'number') {
          ($data{$column}, $error) = _val_number( $mand, $columns->{$column}{size}, $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        } else {
          ($data{$column}, $error) = _val_text( $mand, $columns->{$column}{size}, $data{$column} );
          if ( $error-> { msg } ) { push @error_list, { $column => $error->{ msg } }; }
        }

        # If the column is auto_increment and there is no value set, set it to undef
        # @TODO decide if this should be deleted all together
        $data{$column} = undef if $columns->{$column}{is_auto_increment} and not $data{$column};
      }
    }
  }

  unless (@error_list) {
    # Check the unique constraints
    @error_list = check_uniques($self, \%data, $check_columns);
  }

  $self->set_columns(\%data);

  if (@error_list) {
    return { 'errors' => \@error_list };
  }
  return {};
}

# Returns whether any of the primary columns have changed
# @TODO Write tests for this function
sub primary_cols_have_changed {
  my $self = shift;
  foreach ( $self->result_source->primary_columns ) {
    return 1 if $self->is_column_changed($_);
  }

  return 0;
}

sub check_uniques {
  my $self = shift;
  my $data = shift;
  my $check_columns = shift;
  my $source = $self->result_source;
  my %unique_constraints = $source->unique_constraints();

  my %errors;

  foreach my $constraint ( sort keys %unique_constraints ) {

    # Skip the primary constraint uniqueness test if self is in_storage
    # and the primary columns haven't changed
    next if $constraint eq 'primary' and $self->in_storage and not primary_cols_have_changed($self);

    my $search = {
      map {
        next unless ( not keys %$check_columns ) or $check_columns->{$_};
        ($_ => $data->{$_}) } @{ $unique_constraints{$constraint} }
    };

    # Exclude this entries primary keys to the search for dupes
    # to not detect itself when updating.
    unless ( $constraint eq 'primary' ) {
      for my $column ( $source->primary_columns ) {
        $search->{$column} = {
          '!=' => $data->{$column},
        };
      }
    }

    # If there is an entry with the combined value defined above...
    if ( $source->resultset->count($search) ) {
      foreach my $key ( @{ $unique_constraints{$constraint} } ) {
        $errors{$key} = [] unless defined $errors{$key};
        my @other_fields = @{ $unique_constraints{$constraint} };
        # Remove the field so we get a list of other fields in the
        # combination
        my $index = 0;
        $index++ until $other_fields[$index] eq $key;
        splice(@other_fields, $index, 1);
        # If there are no keys other than the key that isnt unique,
        # then write the error as singular else explain the combination.
        if ( $#other_fields >= 0 ) {
          push @{$errors{$key}}, { $key => 'must be unique when combined with '.join(', ',@other_fields) };
        } else {
          push @{$errors{$key}}, { $key => 'must be unique' };
        }
      }
    }
  }

  if ( %errors ) {
    # Convert hash into the array of hashrefs like the validate returns
    return map { { $_ => join( ' and ', map { values %$_ } @{ $errors{$_} } ) } } keys %errors;
  } else {
    return ();
  }
}

sub insert {
   my $self = shift;
   my $result = $self->validate;
   # If errors return the result
   if ($result->{errors}) {
      return $result;
   } else {
   # Else do the normal insert
      $self->next::method(@_);
   }
}

sub update {
   my $self = shift;
   my $columns = shift;

   $self->set_inflated_columns($columns) if $columns;

   my $result = $self->validate;
   # If errors return the result
   if ($result->{errors}) {
      return $result;
   } else {
      # Else do the normal update
      $self->next::method(@_);
   }
}

# =============== Validatators ===============

sub _val_email {
  my ($mand, $value) = @_;
   if (not defined $value) { $value = ''; }
  if ( !Email::Valid->address($value) && $mand ) {
    return ( undef, { msg => 'address is blank or not valid' }  );
  } elsif ( !Email::Valid->address($value) && $value ) {
    return ( undef, { msg => 'address is blank or not valid' }  );
  } else {
    return $value;
  }
}

sub _val_text {
  my ($mand, $len, $value) = @_;

  if ($mand && ( not( defined $value ) or $value eq '' )) {
    return (undef, { msg => 'cannot be blank' });
  } elsif ($len && length($value) && (length($value) > $len) ) {
    return (undef, { msg => 'is limited to '.$len.' characters' });
  } elsif (defined $value && $value !~ /^([\d \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\[\]\?\;\n\r\<\>\/\@\w]*)$/) {
    return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()[]=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
  } else {
    # This is to ensure that $1 is from the last regex match
    if (defined $value) {
      return ($1);
    } else {
      return $value;
    }
  }
}

# _val_password is the same as _val_text but it also allows {}s
sub _val_password {
  my ($mand, $len, $value) = @_;

  if ($mand && (!$value || $value =~ /bogus="1"/)) {  #tiny mce
    return (undef, { msg => 'cannot be blank' });
  } elsif ($len && length($value) && (length($value) > $len) ) {
    return (undef, { msg => 'is limited to '.$len.' characters' });
  } elsif ($value && $value !~ /^([\w \.\,\-\'\"\!\$\#\%\=\&\:\+\(\)\[\]\{\}\?\;\n\r\<\>\/\@\w]*)$/) {
    return (undef, { msg => 'can only use letters, 0-9 and -.,\'\"!&#$?:()[]=%<>;/@ (do not cut and paste from a Word document, you must Save As text only)' });
  } else {
    my $tf = new HTML::TagFilter;
    # This is to ensure that $1 is from the last regex match
    if ($value) {
      return ($tf->filter($1));
    } else {
      return $value;
    }
  }
}

sub _val_int {
  my ($mand, $value) = @_;
  if ( (not( defined $value ) or $value ne '0') && !$value && $mand ) {
    return (undef, { msg => 'cannot be blank' });
  } elsif ( ( defined $value and ( $value or $value eq '0' ) ) and $value !~ /^[-]?\d+$/) {
    return (undef, { msg => 'can only use numbers' });
  } else {
      return ($value);
  }
}

sub _val_selected {
  my ($value) = @_;
  if (not defined $value or $value eq '') {
    return (undef, { msg => 'must be selected' });
  } else {
    return $value;
  }
}

sub _val_number {
  my ($mand, $len, $value) = @_;
  if ((!defined $value or $value eq '') && $mand) {
    return (undef, { msg => 'cannot be blank' });
  } elsif ($len && (length($value) > $len) ) {
    return (undef, { msg => 'is limited to '.$len.' characters' });
  } elsif ($value && $value !~ /^([-\.]*\d[\d\.-]*)$/) {
    return (undef, { msg => 'can only use numbers and . or -' });
  } else {
    # This is to ensure that $1 is from the last regex match
    if ($value) {
      return ($1);
    } else {
      return $value;
    }
  }
}


1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::Validation::Structure - DBIx::Class Validation based on the column meta data

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base qw/DBIx::Class::Core/;

  __PACKAGE__->load_components(qw/Validation::Structure/);

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD');


=head1 DESCRIPTION

DBIx::Class::Validation::Structure is DBIx::Class Validation based on the column meta data set in add_columns or add_column.

=head1 AUTHOR

Sean Zellmer E<lt>sean@lejeunerenard.comE<gt>

=head1 COPYRIGHT

Copyright 2013- Sean Zellmer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 8

=item L<DBIx::Class>

=item L<DBIx::Class::Validation>

=item L<Email::Valid>

=item L<HTML::TagFilter>

=back

=cut
