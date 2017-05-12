=head1 NAME

DBD::iPod::row - a song record from the iPod.

=head1 SYNOPSIS

 #construct an object with a hashref
 $row = DBD::iPod::row->new( { field1 => 'value1' } ); #...

 #call column() to get data back out
 $row->column('field1'); #returns 'value1'

 #compare the columns to a SQL::Statement's WHERE clause
 $boolean = $row->is_match($statement->where());

=head1 DESCRIPTION

This class implements just enough to use the L<SQL::Statement::Op>
datastructure to perform recursive boolean matching on an iPod
song record.  L</is_match()>.

=head1 AUTHOR

Author E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

L<SQL::Statement>.

=head1 COPYRIGHT AND LICENSE

GPL

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut

package DBD::iPod::row;
use strict;
use Data::Dumper;

=head2 new()

 Usage   : DBD::iPod::row->new({});
 Function: make a new row record
 Returns : a DBD::iPod::row object
 Args    : a hashref of attribute/value pairs

=cut

sub new {
  my($class,$hash) = @_;
  my $self = bless($hash, $class);
  return $self;
}

=head2 column()

 Usage   : $row->column('bitrate'); #might return "256"
 Function: get row attributes (columns)
 Returns : value of attribute or undef if attribute
           does not exist.
 Args    : attribute name to retrieve value of

=cut

sub column {
  my $self = shift;
  my($column) = @_;
  return $self->{$column};
}

=head2 is_match()

 Usage   : $boolean = $row->is_match($where);
 Function: match row's contents (i.e. the column values) to
           a SQL SELECT statement's WHERE clause.
 Returns : 1 on true, 0 on false, undef on failure
 Args    : a SQL::Statement::Op object.  you can get it
           by calling ->where() on a SQL::Statement object

=cut

sub is_match {
  my($self, $pred) = @_;
  #warn Dumper($pred);

  if ($pred->op() eq 'OR') {
    return $self->is_match($pred->arg1()) || $self->is_match($pred->arg2());
  }
  elsif ($pred->op() eq 'AND') {
    return $self->is_match($pred->arg1()) && $self->is_match($pred->arg2());
  }
  else {
    my $op = $pred->op();
    my $neg = $pred->neg();

    my $numeric_re = qr/^([+-]?|\s+)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;

    my $v1 = ref($pred->arg1()) ? $self->column( lc($pred->arg1()->name) ) : $pred->arg1();
    my $v2 = ref($pred->arg2()) ? $self->column( lc($pred->arg2()->name) ) : $pred->arg2();

    my $return;
    if ($op eq 'LIKE') {
      if($v1 =~ /%/ || $v2 =~ /%/){
        ($v1,$v2) = ($v2,$v1) if $v1 =~ /%/;
        $v2 =~ s/%/.*?/g;
        #warn "a LIKE '%...'";
        $return = $v1 =~ /^$v2$/ ? 1 : -1;
      }
      else {
        #warn "a LIKE '...'";
        $return = $v1 eq $v2 ? 1 : -1;
      }
    }
    elsif ($v1 =~ $numeric_re && $v2 =~ $numeric_re) {
      if ($op eq '=') {
        $return = $v1 == $v2 ? 1 : -1;
      }
      elsif ($op eq '>') {
        $return = $v1 > $v2 ? 1 : -1;
      }
      elsif ($op eq '<') {
        $return = $v1 < $v2 ? 1 : -1;
      }
      elsif ($op eq '>=') {
        $return = $v1 >= $v2 ? 1 : -1;
      }
      elsif ($op eq '<') {
        $return = $v1 <= $v2 ? 1 : -1;
      }
      elsif ($op eq '!=') {
        $return = $v1 != $v2 ? 1 : -1;
      }
    }
    # "foo" = "bar";
    elsif ($op eq '=') {
      #warn "foo = bar";
      $return = $v1 eq $v2 ? 1 : -1;
    }

    $return *= -1 if $neg == 1;
    return $return > 0 ? 1 : 0;
  }

  return undef;
}

1;

__END__
