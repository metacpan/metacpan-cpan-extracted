package Data::Monad::Control;
use 5.008001;
use strict;
use warnings;

use Data::Monad::Either qw( left right );
use Exporter qw( import );

our $VERSION = "0.01";
our @EXPORT = qw( try );

sub try (&) {
  my ($try_clause) = @_;
  my $wantarray = wantarray;
  local $@;
  my @ret = eval {
    my @ret;
    if ($wantarray) {
      @ret = $try_clause->();
    } elsif (defined $wantarray) {
      $ret[0] = $try_clause->();
    } else {
      $try_clause->();
    }
  };
  return $@ ? left($@) : right(@ret);
}

1;
__END__

=encoding utf-8

=head1 NAME

Data::Monad::Control - Exception handling with Monad

=head1 SYNOPSIS

    use Data::Monad::Control qw( try );

    my $result = try {
      write_to_file_may_die(...);
    }; # => Data::Monad::Either
    $result->flat_map(sub {
      # ...
    });

=head1 DESCRIPTION

Data::Monad::Control provides some functions to handle exceptions with monad.

=head1 FUNCTIONS

=over 4

=item try($try_clause: CodeRef); # => Data::Monad::Either

Takes a function that will die with some exception and runs it.

Returns a left Either monad contains the exception if some exception caught, otherwise, returns a right Either monad contains the values from the given function.

=back

=head1 LICENSE

Copyright (C) aereal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

aereal E<lt>aereal@aereal.orgE<gt>

=head1 SEE ALSO

L<Data::Monad>, L<Try::Tiny>

=cut

