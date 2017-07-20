package Async::Stream;

use 5.010;
use strict;
use warnings;

use Async::Stream::Item;
use Async::Stream::Iterator;
use Scalar::Util qw(weaken);
use Carp;
use Exporter 'import';

our @EXPORT_OK = qw(merge branch);

=head1 NAME

Async::Stream - it's convenient way to work with async data flow.

IMPORTANT! PUBLIC INTERFACE ISN'T STABLE, DO NOT USE IN PRODACTION BEFORE VERSION 1.0.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

Module helps to organize your async code to stream.

  use Async::Stream;

  my @urls = qw(
      http://ucoz.com
      http://ya.ru
      http://google.com
    );

  my $stream = Async::Stream->new_from(@urls);

  $stream
    ->transform(sub {
        $return_cb = shift;
        http_get $_, sub {
            $return_cb->({headers => $_[0], body => $_[0]})
          };
      }, 'async')
    ->filter(sub { $_->{headers}->{Status} =~ /^2/ })
    ->for_each(sub {
        my $item = shift;
        print $item->{body};
      });

=head1 SUBROUTINES/METHODS

=head2 new($generator)

Constructor creates instance of class. 
Class method gets 1 arguments - generator subroutine references to generate items.
Generator will get a callback which it will use for returning result. 
If generator is exhausted then returning callback is called without arguments.

  my $i = 0;
  my $stream = Async::Stream->new(sub {
      $return_cb = shift;
      if ($i < 10) {
        $return_cb->($i++);
      } else {
        $return_cb->();
      }
    });
=cut
sub new {
	my $class = shift;
	my $generator = shift;
	my %args = @_;

	if (ref $generator ne 'CODE') {
		croak 'First argument can be only subroutine reference';
	} elsif (defined $args{prefetch} and $args{prefetch} < 0) {
		croak 'Prefetch can\'t be less then zero';
	}

	my $self = bless {
			_head =>  undef,
			_prefetch => int($args{prefetch} // 0),
		}, $class;

	$self->_set_head($generator);

	return $self;
}

=head2 new_from(@array_of_items)

Constructor creates instance of class. 
Class method gets a list of items which are used for generating streams.
	
  my @domains = qw(
    ucoz.com
    ya.ru
    googl.com
  );
  
  my $stream = Async::Stream->new_from(@urls)

=cut
sub new_from {
	my $class = shift;
	my $items = \@_;

	return $class->new(sub { $_[0]->(@{$items} ? (shift @{$items}) : ()) })
}

=head2 head()

Method returns stream's head item. 
Head is a instance of class Async::Stream::Item.

  my $stream_head = $stream->head;
=cut
sub head {
	return $_[0]->{_head};
}

=head2 set_prefetch($number)

Method returns stream's head item. 
Head is a instance of class Async::Stream::Item.

  $stream->set_prefetch(4);
=cut
sub set_prefetch {
	my $self = shift;
	my $prefetch = shift // 0;

	if ($prefetch < 0) {
		croak 'Prefetch can\'t be less then zero';
	}

	$self->{_prefetch} = $prefetch;

	return $self;
}


=head2 iterator()

Method returns stream's iterator. 
Iterator is a instance of class Async::Stream::Iterator.

  my $stream_iterator = $stream->iterator;
=cut

sub iterator {
	return Async::Stream::Iterator->new($_[0]);
}

=head1 CONVEYOR METHODS

=head2 peek($action)

This method helps to debug streams data flow. 
You can use this method for printing or logging steam data and track data 
mutation between stream's transformations.

  $stream->peek(sub { print $_, "\n" })->to_arrayref(sub {print @{$_[0]}});
=cut
sub peek {
	my $self = shift;
	my $action = shift;

	if (ref $action ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my $iterator = $self->iterator;
	my $generator = sub {
			my $return_cb = shift;
			$iterator->next(sub {
					if (@_) {
						local *{_} = \$_[0];
						$action->();
						$return_cb->($_[0]);
					} else {
						$return_cb->()
					}
				});
		};

	$self->_set_head($generator, prefetch => 0);

	return $self;
}

=head2 filter($predicate)

The method filters current stream. Filter works like lazy grep.

  $stream->filter(sub {$_ % 2})->to_arrayref(sub {print @{$_[0]}});

=cut
sub filter {
	my $self = shift;
	my $predicate = shift;
	my $async_opt = shift // 'sync';

	my $is_async = 0;
	if ($async_opt eq 'async') {
		$is_async = 1;
	}

	if (ref $predicate ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my $iterator = $self->iterator;

	my $next_cb; $next_cb = sub {
		my $return_cb = shift;
		$iterator->next(sub {
			if (@_) {
				my $item = shift;
				local *{_} = \$item;
				if ($is_async) {
					$predicate->(sub {
							my $is_intresting = shift;
							if ($is_intresting) {
								$return_cb->($item);
							} else {
								$next_cb->($return_cb);
							}
						});
				} else {
					if ($predicate->()) {
						$return_cb->($item);
					} else {
						$next_cb->($return_cb);
					}
				}
			} else {
				$return_cb->()
			}
		});
	};

	$self->_set_head($next_cb, $is_async ? () : ( prefetch => 0 ),);

	return $self;
}

=head2 transform($transformer)

Method transform current stream. 
Transform works like lazy map with async response. 
You can use the method for example for async http request or another async 
operation.

  $stream->transform(sub {
  	  $return_cb = shift;
      $return_cb->($_ * 2)
    })->to_arrayref(sub {print @{$_[0]}});

=cut
sub transform {
	my $self = shift;
	my $transform = shift;
	my $async_opt = shift // 'sync';

	my $is_async = 0;
	if ($async_opt eq 'async') {
		$is_async = 1;
	}

	if (ref $transform ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my $iterator = $self->iterator;

	my $next_cb; $next_cb = sub {
		my $return_cb = shift;
		$iterator->next(sub {
			if (@_) {
				local *{_} = \$_[0];
				if ($is_async) {
					$transform->($return_cb);
				} else {
					$return_cb->($transform->());
				}
			} else {
				$return_cb->()
			}
		});
	};

	$self->_set_head($next_cb, $is_async ? () : ( prefetch => 0 ),);

	return $self;
}

=head2 append(@list_streams)

The method appends several streams to tail of current stream.

  $stream->append($stream1)->to_arrayref(sub {print @{$_[0]}}); 
=cut
sub append {
	my $self = shift;
	my @streams = @_;

	for my $stream (@streams) {
		if (!$stream->isa('Async::Stream')) {
			croak 'Arguments can be only Async::Stream or instances of derived class'
		}
	}

	my $iterator = $self->iterator;

	my $generator; $generator = sub {
		my $return_cb = shift;
		$iterator->next(sub {
				if (@_){
					$return_cb->($_[0]);
				} elsif (@streams) {
					$iterator = (shift @streams)->iterator;
					$generator->($return_cb);
				} else {
					$return_cb->();
				}
			});
	};

	$self->_set_head($generator, prefetch => 0);

	return $self;
}

=head2 skip($number)

The method skips $number items in stream.

  $stream->skip(5)->to_arrayref(sub {print @{$_[0]}});
=cut
sub skip {
	my $self = shift;
	my $skip = int shift;

	if ($skip < 0) {
		croak 'First argument can be only non-negative integer'
	};

	if ($skip) {
		my $iterator = $self->iterator;
		my $generator; $generator = sub {
			my $return_cb = shift;
			$iterator->next(sub {
					if (@_){
						if ($skip-- > 0) {
							$generator->($return_cb);
						} else {
							$return_cb->($_[0]);
						}
					} else {
						$return_cb->();
					}
				});
		};

		$self->_set_head($generator, prefetch => 0);

		return $self;
	} else {
		return $self;
	}
}

=head2 limit($number)

The method limits $number items in stream.

  $stream->limit(5)->to_arrayref(sub {print @{$_[0]}});
=cut
sub limit {
	my $self = shift;
	my $limit = int shift;

	if ($limit < 0) {
		croak 'First argument can be only non-negative integer'
	}

	my $generator;
	if ($limit) {
		my $iterator = $self->iterator;

		$generator = sub {
			my $return_cb = shift;
			return $return_cb->() if ($limit-- <= 0);
			$iterator->next($return_cb);
		}
	} else {
		$generator = sub {
			my $return_cb = shift;
			$return_cb->();
		}
	}

	$self->_set_head($generator, prefetch => 0);

	return $self;
}

=head2 sorted($comparator)

The method sorts whole stream.

  $stream->sorted(sub{$a <=> $b})->to_arrayref(sub {print @{$_[0]}});
=cut
sub sorted {
	my $self = shift;
	my $comporator = shift;

	if (ref $comporator ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my $pkg = caller;

	my $is_sorted = 0;
	my @stream_items;
	my $stream = $self;

	my $iterator = $self->iterator;

	my $generator = sub {
		my $return_cb = shift;
		if ($is_sorted) {
			$return_cb->( @stream_items ? shift @stream_items : () );
		} else {
			my $next_cb; $next_cb = sub {
				my $next_cb = $next_cb;
				$iterator->next(sub {
						if (@_) {
							push @stream_items, $_[0];
							$next_cb->();
						} else {
							if (@stream_items) {
								{
									no strict 'refs';
									local *{ $pkg . '::a' } = *{ ref($self) . '::a' };
									local *{ $pkg . '::b' } = *{ ref($self) . '::b' };
									@stream_items = sort $comporator @stream_items;
								}
								$is_sorted = 1;
								$return_cb->(shift @stream_items);
							} else {
								$return_cb->();
							}
						}
					});
			};$next_cb->();
			weaken $next_cb;
		}
	};

	$self->_set_head($generator, prefetch => 0);

	return $self;
}

=head2 cut_sorted($predicate, $comparator)

Sometimes stream can be infinity and you can't you $stream->sorted, 
you need certain parts of streams for example cut part by length of items.

  $stream
    ->cut_sorted(sub {length $a != length $b},sub {$a <=> $b})
    ->to_arrayref(sub {print @{$_[0]}});
=cut
sub cut_sorted {
	my $self = shift;
	my $cut = shift;
	my $comporator = shift;

	if (ref $cut ne 'CODE' or ref $comporator ne 'CODE') {
		croak 'First and Second arguments can be only subrotine references'
	}

	my $pkg = caller;

	my $iterator = $self->iterator;

	my $prev;
	my @cur_slice;
	my @sorted_array;
	my $generator; $generator = sub {
		my $return_cb = shift;
		if (@sorted_array) {
			$return_cb->(shift @sorted_array);
		} else {
			if (!defined $prev) {
				$iterator->next(sub {
						if (@_){
							$prev = $_[0];
							@cur_slice = ($prev);
							$generator->($return_cb);
						} else {
							$return_cb->();
						}
					});
			} else {
				$iterator->next(sub {
						if (@_) {
							my $is_cut;
							{
								no strict 'refs';
								local ${ $pkg . '::a' } = $prev;
								local ${ $pkg . '::b' } = $_[0];
								$is_cut = $cut->();
							}
							$prev = $_[0];
							if ($is_cut) {
								{
									no strict 'refs';
									local *{ $pkg . '::a' } = *{ ref($self) . '::a' };
									local *{ $pkg . '::b' } = *{ ref($self) . '::b' };
									@sorted_array = sort $comporator @cur_slice;
								}
								@cur_slice = ($prev);
								$return_cb->(shift @sorted_array);
							} else {
								push @cur_slice, $prev;
								$generator->($return_cb);
							}
						} else {
							if (@cur_slice) {
								{
									no strict 'refs';
									local *{ $pkg . '::a' } = *{ ref($self) . '::a' };
									local *{ $pkg . '::b' } = *{ ref($self) . '::b' };
									@sorted_array = sort $comporator @cur_slice;
								}
								@cur_slice = ();
								$return_cb->(shift @sorted_array);
							} else {
								$return_cb->();
							}
						}
					});
			}
		}
	};

	$self->_set_head($generator, prefetch => 0);

	return $self;
}

=head2 merge_in($comparator, @list_streams);

Merge additional streams into current stream by comparing each item of stream.

  $stream->merge_in(sub{$a <=> $b}, $stream1, $stream2);
=cut
sub merge_in {
	my $self = shift;
	my $comporator = shift;

	if (ref $comporator ne 'CODE') {
		croak 'First argument can be only reference to subroutine';
	}

	my $pkg = caller;

	my @iterators;
	for my $stream ($self, @_) {
		if ($stream->isa('Async::Stream')) {
			push @iterators, [$stream->iterator];	
		} else {
			croak 'Arguments can be only Async::Stream or instances of derived class'
		}
	}

	my $generator = sub {
		my $return_cb = shift;
		my $requested_item = grep { @{$_} == 1 } @iterators;
		for (my $i = 0; $i < @iterators; $i++) {
			if (@{$iterators[$i]} == 1) {
				my $iterator_id = $i;
				$iterators[$iterator_id][0]->next(sub {
						$requested_item--;
						if (@_) {
							my $item = shift;
							push @{$iterators[$iterator_id]}, $item;
						} else {
							$iterators[$iterator_id] = undef;
						}

						if ($requested_item == 0) {
							### it's awful and need to optimize ###
							{
								no strict 'refs';
								my $comp = sub {
									local ${ $pkg . '::a' } = $a->[1];
									local ${ $pkg . '::b' } = $b->[1];
									return $comporator->();
								};
								@iterators = sort $comp grep { defined $_ } @iterators;
							}
							### ###
							if (@iterators) {
								my $item = pop @{$iterators[0]};
								$return_cb->($item);
							} else {
								$return_cb->();
							}
						}
					});
			}
		}
	};

	$self->_set_head($generator);

	return $self;
}

=head2 $branch_stream branch_out($predicat);

Split stream into 2 stream are divided by predicat. Branch returns 2 streams.
First stream will contain "true" items, Second - "false" items;

  my $error_stream = $stream->branch_out(sub{$_->{headers}{status} != 200});
=cut
sub branch_out {
	my $self = shift;
	my $predicat = shift;

	if (ref $predicat ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my @branch_items;
	my @self_items;

	my $iterator = $self->iterator;

	my $generator; $generator = sub {
		my $return_cb = shift;
		my $is_for_branch = shift;

		if ($is_for_branch && @branch_items) {
			return $return_cb->(shift @branch_items);
		} elsif (!$is_for_branch && @self_items) {
			return $return_cb->(shift @self_items);
		}

		$iterator->next(sub {
				if (@_) {
					my $item = shift;
					my $is_branch_item;
					
					{
						local *{_} = \$item;
						$is_branch_item = $predicat->();
					}

					if ($is_for_branch && !$is_branch_item) {
						push @self_items, $item;
						return $generator->($return_cb,$is_for_branch);
					} elsif (!$is_for_branch && $is_branch_item) {
						push @branch_items, $item;
						return $generator->($return_cb,$is_for_branch);
					} else {
						return $return_cb->($item);
					}
				} else {
					$return_cb->();
				}
			});
	};

	$self->_set_head(sub { $generator->($_[0], 0) });
	return Async::Stream->new(sub { $generator->($_[0], 1) });
}

=head2 distinct($key_generator)

Method discards duplicate items from stream. 
By default uniqueness of items will be determined by textual representation of item.

  $stream->distinct(sub {$_->{name}})->to_arrayref(sub {print @{$_[0]}});
=cut
sub distinct {
	my $self = shift;
	my $to_key = shift;

	if (ref $to_key ne 'CODE') {
		$to_key = sub { "$_" };
	}

	my $iterator = $self->iterator;

	my %index_of;

	my $generator; $generator = sub {
		my $return_cb = shift;
		$iterator->next(sub {
				if (@_) {
					my $key;
					{
						local *{_} = \$_[0];
						$key = $to_key->()
					}

					if (exists $index_of{$key}) {
						$generator->($return_cb);
					} else {
						$index_of{$key} = undef;
						$return_cb->($_[0]);
					}
				} else {
					$return_cb->();
				}
			});

	};

	$self->_set_head($generator);

	return $self;
}

=head1 TERMINAL METHODS

=head2 to_arrayref($returing_cb)

Method returns stream's iterator.

  $stream->to_arrayref(sub {
      $array_ref = shift;

      #...	
    });
=cut
sub to_arrayref {
	my $self = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my @result;

	my $iterator = $self->iterator;

	my $next_cb; $next_cb = sub {
		my $next_cb = $next_cb;
		$iterator->next(sub {
				if (@_) {
					push @result, $_[0];
					$next_cb->();
				} else {
					$return_cb->(\@result);
				}
			});
	};$next_cb->();
	weaken $next_cb;

	return $self;
}

=head2 for_each($action)

Method execute action on each item in stream.

  $stream->to_arrayref(sub {
      $array_ref = shift;
      
      #...	
    });
=cut
sub for_each {
	my $self = shift;
	my $action = shift;

	if (ref $action ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my $iterator = $self->iterator;

	my $each; $each = sub {
		my $each = $each;
		$iterator->next(sub {
			if (@_) {
				$action->($_[0]);
				$each->()
			}
		});
	}; $each->();
	weaken $each;

	return $self;
}

=head2 reduce($accumulator, $returing_cb)

Performs a reduction on the items of the stream.

  $stream->reduce(
    sub{ $a + $b }, 
    sub {
    	$sum = shift 
		  #...
    });

=cut
sub reduce  {
	my $self = shift;
	my $code = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE' or ref $code ne 'CODE') {
		croak 'First and Second arguments can be only subroutine references'
	}

	my $pkg = caller;

	my $iterator = $self->iterator;

	$iterator->next(sub {
			if (@_) {
				my $prev = $_[0];
				
				my $reduce_cb; $reduce_cb = sub {
					my $reduce_cb = $reduce_cb;
					$iterator->next(sub {
							if (@_) {
								{
									no strict 'refs';
									local *{ $pkg . '::a' } = \$prev;
									local *{ $pkg . '::b' } = \$_[0];
									$prev = $code->();
								}
								$reduce_cb->();
							} else {
								$return_cb->($prev);
							}
						});
				};$reduce_cb->();
				weaken $reduce_cb;
			} else {
				$return_cb->();
			}
		});

	return $self;
}

=head2 sum($returing_cb)

The method computes sum of all items in stream.

  $stream->sum(
    sub {
    	$sum = shift 
		  #...
    });
=cut
sub sum {
	my $self = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	$self->reduce(sub{$a+$b}, $return_cb);

	return $self;
}

=head2 min($returing_cb)

The method finds out minimum item among all items in stream.

  $stream->min(
    sub {
    	$sum = shift 
		  #...
    });
=cut
sub min {
	my $self = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	$self->reduce(sub{$a < $b ? $a : $b}, $return_cb);

	return $self;
}

=head2 max($returing_cb)

The method finds out maximum item among all items in stream.

  $stream->max(
    sub {
    	$sum = shift 
		  #...
    });
=cut
sub max {
	my $self = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	$self->reduce(sub{$a > $b ? $a : $b}, $return_cb);

	return $self;
}

=head2 count($returing_cb)

The method counts number items in streams.

  $stream->count(sub {
      $count = shift;
    }); 
=cut
sub count {
	my $self = shift;
	my $return_cb = shift;

	if (ref $return_cb ne 'CODE') {
		croak 'First argument can be only subroutine reference'
	}

	my $result = 0;
	my $iterator = $self->iterator;

	my $next_cb ; $next_cb = sub {
		my $next_cb = $next_cb;
		$iterator->next(sub {
				if (@_) {
					$result++;
					return $next_cb->();
				}
				$return_cb->($result)
			});
	}; $next_cb->();
	weaken $next_cb;

	return $self;
}

=head2 any($predicat, $return_cb)

Method look for any equivalent item in steam. if there is any then return that.
if there isn't  then return nothing.

  $stream->any(sub {$_ % 2})->to_arrayref(sub {print @{$_[0]}});
=cut
sub any {
	my $self = shift;
	my $predicat = shift;
	my $return_cb = shift;

	my $iterator = $self->iterator;

	my $next_cb; $next_cb = sub {
		my $next_cb = $next_cb;
		$iterator->next(sub {
			if (@_) {
				local *{_} = \$_[0];
				if ($predicat->()) {
					$return_cb->($_[0]);
				} else {
					$next_cb->();
				}
			} else {
				$return_cb->()
			}
		});
	}; $next_cb->();
	weaken $next_cb;

	return $self;
}


sub _set_head {
	my $self = shift;
	my $generator = shift;
	my %args = @_;

	my $prefetch = $args{prefetch} // $self->{_prefetch};

	if ($prefetch) {
		my $new_generator = _get_prefetch_generator($generator, $self->{_prefetch});
		$self->{_head} = Async::Stream::Item->new(undef, $new_generator);
	} else {
		$self->{_head} = Async::Stream::Item->new(undef, $generator);
	}

	return $self;
}

sub _get_prefetch_generator {
	my ($generator,$prefetch) = @_;

	my @responses_cache;
	my @requests_queue;
	my $is_exhausted = 0;
	my $item_requested = 0;

	return sub {
			my $return_cb = shift;

			if (@responses_cache) {
				$return_cb->(shift @responses_cache);
			} else {
				push @requests_queue, $return_cb;
			}

			if (!$is_exhausted) {
				for (0 .. ($prefetch - $item_requested)) {
					$item_requested++;
					$generator->(sub {
							$item_requested--;
							if (@_) {
								if (@requests_queue) {
									shift(@requests_queue)->($_[0]);
								} else {
									push @responses_cache, $_[0];
								}
							} else {
								$is_exhausted = 1;
								if (!$item_requested && @requests_queue) {
									shift(@requests_queue)->();
								}
							}
						});
				}
			} elsif (!$item_requested && @requests_queue) {
				shift(@requests_queue)->();
			}
	};
}

=head1 AUTHOR

Kirill Sysoev, C<< <k.sysoev at me.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to 
L<https://github.com/pestkam/p5-Async-Stream/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Async::Stream::Item


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Kirill Sysoev.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

1; # End of Async::Stream
