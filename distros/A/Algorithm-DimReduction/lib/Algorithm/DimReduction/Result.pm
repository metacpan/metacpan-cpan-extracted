package Algorithm::DimReduction::Result;
use strict;
use warnings;

sub new {
    my $class = shift;
    my %args  = @_;
    return bless { %args }, $class;
}

sub contribution_rate {
    my $self = shift;
    my $eigens = $self->{eigens};
    my @rate;
    for my $i( 1 .. @$eigens){
        push @rate, {reduct_to => $i, rate => $eigens->[$i-1] };
    }
    return \@rate;
}

1;
__END__

=head1 NAME

Algorithm::DimReduction::Result - Result object of analyze method 

=head1 SYNOPSIS

  # you can check contribution_rate
  my $result   = $reductor->analyze( $matrix );
  print Dumper $result->contribution_rate;

  # save and load
  $reductor->save_analyzed($result);
  my $result = $reductor->load_analyzed('save_dir');

  # it will be used as argument of reduce()
  $reductor->reduce( $result, $reduce_to);

=head1 DESCRIPTION

Algorithm::DimReduction::Result is result of analyze method.

It will be used  as argument of reduce method.

=head1 METHODS

=head2 new(%args) 

=head2 contribution_rate()

=head1 AUTHOR

Takeshi Miki E<lt>t.miki@nttr.co.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut