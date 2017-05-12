package Data::Iterator::SlidingWindow;
use strict;
use warnings;
use 5.008001;
use parent 'Exporter';
use Carp qw(croak);
use overload
    '<>'     => sub { shift->next() },
    fallback => 1;

our $VERSION = '0.05';

our @EXPORT = qw(iterator);

sub _new {
    my $class = shift;
    my %args  = @_;

    my $window_size = $args{window_size};
    my $src_stuff   = $args{data_source};

    if ( !defined $window_size || $window_size !~ /^[0-9]+$/ || $window_size == 0 ) {
        croak "window size must be positive integer.";
    }

    my $src_type = ref( $src_stuff || q{} ) || q{};
    if ( !( $src_type eq 'CODE' || $src_type eq 'ARRAY' ) ) {
        croak "data_source must be CODE reference or ARRAY refernce.";
    }

    my $source;
    if ( $src_type eq 'ARRAY' ) {
        $source = sub {
            shift @$src_stuff;
        };
    }
    else {
        $source = $src_stuff;
    }

    # Initialize current window
    my @current_window;
    while ( @current_window < $window_size ) {
        my $next = $source->();
        last if !defined $next;
        push @current_window, $next;
    }

    my $self = {
        _window_size    => $window_size,
        _source         => $source,
        _current_window => \@current_window,
    };

    return bless $self, $class;
}

sub next {
    my $self = shift;
    my $ret  = [ @{ $self->{_current_window} } ];
    return if @$ret != $self->{_window_size};
    shift @{ $self->{_current_window} };
    my $next = $self->{_source}->();
    if ( defined $next ) {
        push @{ $self->{_current_window} }, $next;
    }
    return $ret;
}

sub iterator {
    my ( $window_size, $data_source ) = @_;
    return __PACKAGE__->_new(
        window_size => $window_size,
        data_source => $data_source,
    );
}

1;
__END__
 
=head1 NAME
 
Data::Iterator::SlidingWindow - Iteration data with Sliding Window Algorithm
 
=head1 SYNOPSIS
 
  use Data::Iterator::SlidingWindow;
 
  my $ i = 0;
  my $iter = iterator 3 => sub{
      #generate/fetch next one.
      return if $i > 6;
      return $i++;
  };
 
  while(defined(my $cur = $iter->next())){
      # $cur is [1, 2, 3], [2, 3, 4], [3, 4, 5], [4, 5, 6]
  }
 
And you can use <> operator.
 
    while(<$iter>){
        my $cur = $_;
        ....
    }
 
 
=head1 DESCRIPTION
 
This module is iterate elements of Sliding Window.
 
=head1 METHODS

=head2 iterator($window_size, $data_source) 

Iterator constructor.
The arguments are:

=over 2

=item $window_size 

Windows size. 

=item $data_source

Data source of iterator.

CODE reference:

  iterator 3 => sub{
      CODE
  };
  
CODE returns a value on each call, and if it is exhausted, returns undef.
If you want yield undefined value as a meaning value.You can use 'NULL object pattern'.

  iterator 3 => sub{
     my $value = generate_next_value();
     return unless is_valid_value($value); # exhausted!
     return { value => $value };
  };

ARRAY reference:

  iterator 3 => \@array;

=back

=head2 next()

Get next window.
 
=head1 AUTHOR
 
Hideaki Ohno E<lt>hide.o.j55{at}gmail.comE<gt>
 
=head1 SEE ALSO
 
=head1 LICENSE
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=cut
