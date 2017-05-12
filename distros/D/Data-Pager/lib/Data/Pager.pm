package Data::Pager;
use strict;
use Carp;
use POSIX qw(ceil);
use vars qw($VERSION);

$VERSION = '0.01';

sub new {
    my $class = shift;
    my $data  = shift;
    my $self  = {};

    $class ne __PACKAGE__
      and croak "class " . __PACKAGE__ . " constructor is not static";

    $self->{data}{fields} = $data;

    bless $self, $class;

    $self->__init($data);

    return $self;
}

sub __init {
    my $self = shift;
    my $data = shift || {};

    my $current = $data->{'current'} || 1;
    my $offset  = $data->{'offset'}  || 10;
    my $links   = $data->{'perpage'} || 10;
    my $limit   = $data->{'limit'}   || 0;

    $self->{'tmp'} = { links => $links };

    $links % 2 or $links += 1;

    my $middle = int( $links / 2 );
    my %pager  = ();
    my %tmp    = ();
    my @pager  = ();

    return undef
      if $current * $offset - $offset + 1 > $limit;

    for my $i ( $current .. $current + $middle ) {
        $pager{$i}++ if $i * $offset - $offset < $limit;
    }
    for my $i ( $current - $middle .. $current ) {
        $pager{$i}++ if $i > 0;
    }

    if ( scalar keys %pager < $links and $current < 5 ) {
        while ( $middle++ < $links - 1 ) {
            $middle > $limit
              and last;
            exists( $pager{$middle} )
              or $pager{$middle}++;
        }
    }

    %tmp   = %pager;
    %pager = ();

    for my $pos ( sort { $a <=> $b } keys %tmp ) {
        $pos == $current
          and $pager{'current'} = $pos;
        $pager{$pos} = {
            'prev' => $pos - 1 ? $pos - 1 : undef,
            'next' => $pos * $offset >= $limit ? undef: $pos + 1,
            'from' => $offset * $pos - $offset,
            'to'   => $offset * $pos,
        };
        push @pager, $pos;
    }

    $pager{'limit'}  = $limit;
    $pager{'list'}   = \@pager;
    $pager{'last'}   = $pager[-1];
    $pager{'first'}  = $pager[0];
    $pager{'start'}  = 1;
    $pager{'end'}    = $self->final;
    $pager{'offset'} = $offset;
    $pager{'links'}  = $self->{'tmp'}->{'links'};
    $pager{'prev'}   = $pager{ $pager{'current'} }->{'prev'} || undef;
    $pager{'next'}   = $pager{ $pager{'current'} }->{'next'} || undef;

    $self->{'data'} = \%pager;

}

sub list {
    no strict 'refs';
    my $self = shift;
    wantarray
      ? @{ $self->{data}{list} }
      : \@{ $self->{data}{list} };
}

for my $method (qw(start first last set_current current prev next offset limit links))
{
    no strict 'refs';
    *$method = sub {
        my $self  = shift;
        my $value = shift;
        if ( $method eq 'set_current' ) {
            if ( $value > 0 ) {
                $self->{data}{current} = $value;
                $self->__init( $self->{data} );
				if ( $self->current eq $value ) {
					return $self;
				} 
				else {
					return undef;
				}
            }
        }
        return $self->{data}{$method};
    };
}

sub from {
	my $self = shift;
    $self->{'data'}->{ $self->current }{'from'};
}

sub to {
	my $self = shift;
    $self->{'data'}->{ $self->current }{'to'};
}

sub final {
    my $self = shift;
	no warnings;
    return eval { ceil( $self->limit / $self->offset ) };
}

sub end { shift->final }

1;

__END__

=head1 NAME

Data::Pager - flexible data pager

=head1 SYNOPSIS

  use Data::Pager;
  
  my $pager = Data::Pager->new({
    current => 100,
    perpage => 10,
    offset  => 5,
    limit   => 2000,
  });

  #~ accessors:  
  $pager->current; # 100
  $pager->next;    # 101
  $pager->prev;    # 99
  $pager->limit;   # 2000
  $pager->start;   # 1 # not typical start of a programmer
  $pager->final;   # \
                      # 400 (which denotes 2000 / 5 pager links)
  $pager->end;     # /
  $pager->from;    # 495 (may serve in SQL LIMIT clause)
  $pager->to;      # 500 (may serve in SQL LIMIT clause)
  $pager->list;    # 95  96  97  98  99  100  101  102  103  104  105
  
=head1 DESCRIPTION

This class implements the familiar pager where the current position is centered.

=head1 CONSTRUCTOR

=head2 new 

 my $pager = Data::Pager->new({
   current => 1,      # this is the current pager position
   perpage => 10,     # the pager consists of this number of links (defaults to 10)
   offset  => 5,      # this is the number of results (fetched from the DB for example) per result
   limit   => 100,    # how far is the pager allowed 
 });

 # sample output from html table:
 
 id ... ..... ... 
 1. ... ..... ...
 2. ... ..... ...
 3. ... ..... ...
 4. ... ..... ...
 5. ... ..... ...
 
 1 2 3 4 5 6 7 8 9 10

Returns object or undef if current position is beyond the limit.

=head1 METHODS

=head2 current

 $pager->current();

Returns the current pager position.

=head2 set_current($digit)

 $pager->set_current(850);
 $pager->set_current(850)->next();
 
Sets the current pager position. 
Returns the pager object on succes, undef on false.


=head2 next

Returns the next pager position or undef if this is the last one.

=head2 prev

Returns the previous pager position or undef if this is the first one.

=head2 start

Returns 1 - the start pager position.

=head2 end

Returns the end pager position.

=head2 first

Returns the first pager position for this result set.

=head2 last

Returns the last pager position for this result set.

=head2 from 

  '1' => {
    'to' => 5,
    'next' => 2,
    'prev' => undef,
    'from' => 0
  },
  '2' => {
    'to' => 10,
    'next' => 3,
    'prev' => 1,
    'from' => 5
  },
  ...

Returns the start result this pager position refers to.

=head2 to

Returns the end result this pager position refers to.

=head2 list

 @_ = $pager->list;
 $_ = $pager->list;

Returns the pager links for this result set.
In list context returns the resulting list.
In scalar context returns reference to the resulting list.

 # note the alignment

 $pager->set_current(10);
 print $pager->list;         # 6 7 8 9  [10]  11 12 13 14 15
 $pager->set_current(33);    
 print $pager->list;         # 28 29 30 31 32 [33] 34 35 36 37 38

=head1 SEE ALSO

L<Data::Page>

=head1 BUGS

What BUGS?

=head1 AUTHOR

Vidul Nikolaev Petrov, vidul@cpan.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

