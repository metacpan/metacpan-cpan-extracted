# dictionary.pm - this file is part of the CGI::Listman distribution
#
# CGI::Listman is Copyright (C) 2002 iScream multimédia <info@iScream.ca>
#
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>

use strict;

package CGI::Listman::dictionary;

use Carp;

use CGI::Listman::dictionary::term;

=pod

=head1 NAME

CGI::Listman::dictionary - list of and informations about CGI form parameters

=head1 SYNOPSIS

    use CGI::Listman::dictionary;

=head1 DESCRIPTION

A dictionary mainly serves two purposes: first, it gives the list manager
a reference for what database rows are in use; second, it makes the
connection between your web representation of those rows (definition) and
checks whether some fields are mandatory or not.

This helps you build web pages where each mentionned field can have a
readable name. For example, let's say you have a form with a field
internally identified with "user_name". If the user forgets or refuses to
fill in this field, I<CGI::Listman> will return you a list containing it
among other similar fields (see the I<check_params> method of the
I<CGI::Listman> class). Furthermore, your error page could contain a more
explicit field name such as "User Identification" instead of the silly
"user_name" identifier.

This functionality is somewhat limited at this stage since
I<CGI::Listman> only checks the presence of mandatory fields, yet it
considers strings of whitespaces as empty strings. Otherwise, it does not
enforce semantics over those field. Until this is implemented, I
recommend you have a look at Mark Stosberg's L<Data::FormValidator> or
Francis J. Lacoste's L<HTML::FormValidator> modules which seem to do a
pretty job.

=head1 API

=head2 new

Constructor with a an argument specifying the filename where to store
the dictionary informations.

=over

=item Parameters

The parameter "filename" is optional with this method.

=over

=item filename

A string representing the path to your dictionary's storage file.

=back

=item Return values

A reference to a blessed instance of I<CGI::Listman::dictionary>.

=back

=cut

sub new {
  my $class = shift;

  my $self = {};
  $self->{'filename'} = shift;

  $self->{'_terms'} = undef;
  $self->{'_loading'} = 0;

  bless $self, $class;
}

=pod

=head2 add_term

Append an instance of I<CGI::Listman::dictionary::term> to your
dictionary's list of terms.

=over

=item Parameters

=over

=item term

A reference to the instance of I<CGI::Listman::dictionary::term> you want
to add to your dictionary.

=back

=item Return values

This method returns nothing.

=back

=cut

sub add_term {
  my ($self, $term) = @_;

  my $terms_ref = $self->terms ();
  push @$terms_ref, $term;
}

=pod

=head2 get_term

This method returns the I<CGI::Listman::dictionary::term> corresponding
to the key given as parameter.

=over

=item Parameters

=over

=item key

The key of the term you wish to be returned.

=back

=item Return values

A reference to an instance of I<CGI::Listman::dictionary::term> or
I<undef> if the key was not found.

=back

=cut

sub get_term {
  my ($self, $key) = @_;

  my $terms_ref = $self->terms ();

  my $term_object = undef;

  if (defined $terms_ref) {
    foreach my $term (@$terms_ref) {
      next if ($term->{'key'} ne $key);
      $term_object = $term;
    }
  }

  return $term_object;
}

=pod

=head2 terms

Returns the list of terms.

=over

=item Parameters

This method takes no parameter.

=item Return values

A reference to the ARRAY containing the list of terms.

=back

=cut

sub terms {
  my $self = shift;

  $self->_load () unless (defined $self->{'_terms'});
  my $terms_ref = $self->{'_terms'};

  return $terms_ref;
}

=pod

=head2 term_pos_in_list

=over

=item Parameters

=over

=item term

An instance of I<CGI::Listman::dictionary::term> you wish to know the
position of in the list.

=back

=item Return values

This method returns an integer corresponding to that term in the list's
order or -1 if the term was not found.

=back

=cut

sub term_pos_in_list {
  my ($self, $term) = @_;

  my $number = 0;
  my $terms_ref = $self->terms ();
  foreach my $comp_term (@$terms_ref) {
    last if ($comp_term == $term);
    $number++;
  }

  $number = -1 if ($number == scalar (@$terms_ref));

  return $number;
}

=pod

=head2 reposition_term

This functions serves the purpose of reposition a term relatively to its
siblings. Giving a value that is to high or low will silently cancel the
operation. This function is generally called by the I<increase_...> and
I<decrease_...> functions.

=over

=item Parameters

=over

=item term

An instance of I<CGI::Listman::dictionary::term> you wish to move in the
dictionary's internal list.

=item delta

An positive or negative integer giving the number of steps the term has
to be moved from.

=back

=item Return values

This method returns nothing.

=back

=cut

sub reposition_term {
  my ($self, $term, $delta) = @_;

  my $curr_pos = $self->term_pos_in_list ($term);
  my $new_pos = $curr_pos + $delta;
  my $terms_ref = $self->{'_terms'};

  unless ($new_pos > scalar (@$terms_ref)
	  || $new_pos < 0
	  || $delta == 0) {
    my @new_terms_list;

    for (my $count = 0; $count < @$terms_ref; $count++) {
      if ($delta > 0) {
	push @new_terms_list, $terms_ref->[$count + 1]
	  if ($count < $new_pos && $count >= $curr_pos);
      } else {
	push @new_terms_list, $terms_ref->[$count - 1]
	  if ($count > $new_pos && $count <= $curr_pos);
      }
      push @new_terms_list, $terms_ref->[$count]
	if (($count < $new_pos && $count < $curr_pos)
	    || ($count > $new_pos && $count > $curr_pos));
      push @new_terms_list, $term
	if ($count == $new_pos);
    }

    delete $self->{'_terms'};
    $self->{'_terms'} = \@new_terms_list;
  }
}

=pod

=head2 increase_term_pos

This method is similar to I<reposition_term> above except that its
increment is optional. If not present, the increment is assumed to be 1.

=over

=item Parameters

=over

=item increment

An optional positive or negative integer giving the number of steps the
term has to be moved from.

=back

=item Return values

This method returns nothing.

=back

=cut

sub increase_term_pos {
  my ($self, $term, $increment) = @_;

  $increment = 1 unless (defined $increment);

  $self->reposition_term ($term, $increment);
}

=pod

=head2 decrease_term_pos

This method is similar to I<reposition_term> above except that its
decrement is optional and considered negative. If not present, the
decrement is assumed to be 1.

=over

=item Parameters

=over

=item decrement

An optional positive or negative integer giving the number of steps the
term has to be moved from.

=back

=item Return values

This method returns nothing.

=back

=cut

sub decrease_term_pos {
  my ($self, $term, $decrement) = @_;

  $decrement = 1 unless (defined $decrement);

  $self->reposition_term ($term, -$decrement);
}

=pod

=head2 increase_term_pos_by_key

=over

=item Parameters

=over

=item key

The key corresponding to the I<CGI::Listman::dictionary::term> you would
like to increase in the list.

=item increment

An integer representing the amount of slots to increment the term by. If not
specified, this amount will be 1.

=back

=item Return values

This method returns nothing.

=back

=cut

sub increase_term_pos_by_key {
  my ($self, $key, $increment) = @_;

  my $term = $self->get_term ($key);

  $self->increase_term_pos ($term, $increment);
}

=pod

=head2 decrease_term_pos_by_key

=over

=item Parameters

=over

=item key

The key corresponding to the I<CGI::Listman::dictionary::term> you would
like to move in the list.

=item decrement

An integer representing the amount of slots to decrement the term by. If not
specified, this amount will be 1.

=back

=item Return values

This method returns nothing.

=back

=cut

sub decrease_term_pos_by_key {
  my ($self, $key, $decrement) = @_;

  my $term = $self->get_term ($key);

  $self->decrease_term_pos ($term, $decrement);
}

=pod

=head2 save

=over

=item Parameters

This method takes no parameter.

=item Return values

This method returns nothing.

=back

=cut

sub save {
  my $self = shift;

  open DOUTF, '>'.$self->{'filename'}
    or croak "Could not open dictionary (\""
      .$self->{'filename'}."\" for writing).\n";
  my $terms_ref = $self->{'_terms'};
  foreach my $term (@$terms_ref) {
    my $line = $term->{'key'};
    my $definition = $term->definition ();
    $line .= ':'.$definition if (defined $definition && $definition ne '');
    if ($term->{'mandatory'}) {
      $line .= (defined $definition && $definition ne '') ? ':!' : '::!';
    }
    print DOUTF $line."\n";
  }
  close DOUTF;
}

### private methods

sub _load {
  my $self = shift;

  return if $self->{'_loading'};

  $self->{'_loading'} = 1;
  croak "No dictionary filename.\n"
    unless (defined $self->{'filename'});

  open DINF, $self->{'filename'}
    or croak 'Could not open dictionary ("'.$self->{'filename'}.'")'."\n";

  my @terms;
  while (<DINF>) {
    my $line = $_;
    chomp $line;
    $line =~ m/([^:]*)(:([^:]+)?(:([!]))?)?/;

    my $key = $1;
    my $definition = $3 || '';
    my $mandatory = (defined $5 && $5 eq '!');

    croak "Dictionary entry \"".$key."\" is duplicated."
      if (defined $self->get_term ($key));

    my $term_object = CGI::Listman::dictionary::term->new ($key,
							   $definition,
							   $mandatory,
							   $self->{'count'});
    push @terms, $term_object;
  }
  close DINF;

  $self->{'_terms'} = \@terms;
  $self->{'_loading'} = 0;
}

1;
__END__

=pod

=head1 AUTHOR

Wolfgang Sourdeau, E<lt>Wolfgang@Contre.COME<gt>

=head1 COPYRIGHT

Copyright (C) 2002 iScream multimédia <info@iScream.ca>

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Listman::dictionary::term(3)>

=cut
