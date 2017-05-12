package Data::RuledValidator::Closure;

use Data::RuledValidator::Util;
use strict;
use warnings qw/all/;

our $VERSION = 0.05;

my $parent = 'Data::RuledValidator';

use constant 
  {
    IS => sub { # now this is not used, using ARE instead.
      my($key, $c) = @_;
      my $sub = $parent->_cond_op($c) || '';
      unless($sub){
        if($c eq 'n/a'){
          return $c;
        }else{
          Carp::croak("$c is not defined. you can use; " . join ", ", $parent->_cond_op);
        }
      }
      return sub {my($self, $v) = @_; $v = shift @$v; return ($sub->($self, $v) + 0)};
    },
    ISNT => sub { # now this is not used, using ARENT instead.
      my($key, $c) = @_;
      my $sub = $parent->_cond_op($c);
      unless($sub){
        Carp::croak("$c is not defined. you can use; " . join ", ", $parent->_cond_op);
      }
      return sub {my($self, $v) = @_; $v = shift @$v; return(! $sub->($self, $v) + 0)};
    },
    ARE => sub {
      my($key, $c) = @_;
      unless($c =~/,/){
        # single condition
        my $sub = $parent->_cond_op($c) || '';
        unless($sub){
          if($c eq 'n/a'){
            return $c;
          }else{
            Carp::croak("$c is not defined. you can use; " . join ", ", $parent->_cond_op);
          }
        }
        return sub {my($self, $v) = @_; return(_vand($self, $key, $c, $v, sub{my($self, $v) = @_; $sub->($self, $v)}))};
      }else{
        my @c = split /\s*,\s*/, $c;
        my @sub = grep $_, map $parent->_cond_op($_), @c;
        unless(@sub == @c){
          Carp::croak("some of '@c' are not defined. you can use; " . join ", ", $parent->_cond_op);
        }
        return sub {my($self, $v) = @_; return(_vand($self, $key, $c, $v, sub{my($self, $v) = @_; foreach (@sub){$_->($self, $v) and return 1} }))};
      }
    },
    ARENT => sub {
      my($key, $c) = @_;
      unless($c =~/,/){
        # single condition
        my $sub = $parent->_cond_op($c) || '';
        unless($sub){
          if($c eq 'n/a'){
            return $c;
          }else{
            Carp::croak("$c is not defined. you can use; " . join ", ", $parent->_cond_op);
          }
        }
        return sub {my($self, $v) = @_; return(_vand($self, $key, $c, $v, sub{my($self, $v) = @_; ! $sub->($self, $v)}))};
      }else{
        my @c = split /\s*,\s*/, $c;
        my @sub = grep $parent->_cond_op($_), @c;
        unless(@sub == @c){
          Carp::croak("some of '@c' are not defined. you can use; " . join ", ", $parent->_cond_op);
        }
        return sub {my($self, $v) = @_; return(_vand($self, $key, $c, $v, sub{my($self, $v) = @_; ! (grep $_->($self, $v), @sub) == @sub}))};
      }
    },
    MATCH => sub {
      my($key, $c) = @_;
      my @regex = map qr/$_/,_arg($c);
      my $sub = sub{
        my($self, $v) = @_;
        my $ok = 0;
        foreach my $regex (@regex){
          $ok |= $v =~ $regex or last;
        }
        return $ok;
      };
      return sub {my($self, $v) = @_; return(_vor($self, $key, $c, $v, sub{my($self, $v) = @_; $sub->($self, $v)}))};
    },
    GT => sub {
      my($key, $c, $op) = @_;
      my $sub;
      if($op eq '>='){
        if($c =~s/\s*~\s*//){
          $sub = sub{my($self, $v) = @_; return ((length($v) >=  $c) + 0)}
        }else{
          $sub = sub{my($self, $v) = @_; return (($v >=  $c) + 0)}
        }
      }else{
        if($c =~s/\s*~\s*//){
          $sub = sub{my($self, $v) = @_; return $v ? ((length($v) >  $c) + 0) : ()}
        }else{
          $sub = sub{my($self, $v) = @_; return $v ? (($v >  $c) + 0) : ()}
        }
      }
      return sub{my($self, $v) = @_; _vand($self, $key, $c, $v, $sub)};
    },
    LT => sub {
      my($key, $c, $op) = @_;
      my $sub;
      if($op eq '<='){
        if($c =~s/\s*~\s*//){
          $sub = sub{my($self, $v) = @_; return ((length($v) <=  $c) + 0)}
        }else{
          $sub = sub{my($self, $v) = @_; return (($v <=  $c) + 0)}
        }
      }else{
        if($c =~s/\s*~\s*//){
          $sub = sub{my($self, $v) = @_; return $v ? ((length($v) <  $c) + 0) : ()}
        }else{
          $sub = sub{my($self, $v) = @_; return $v ? (($v <  $c) + 0) : ()}
        }
      }
      return  sub{my($self, $v) = @_; _vand($self, $key, $c, $v, $sub)};
    },
    LENGTH => sub {
      my($key, $c, $op) = @_;
      my($start, $end) = split(/,/, $c);
      my $sub = sub{
        my($self, $v) = @_;
        my $l = length($v);
        return defined $end ? ($start <= $l and $l <= $end) : $l <= $start;
      };
      return  sub{my($self, $v) = @_; _vand($self, $key, $c, $v, $sub)};
    },
    BETWEEN => sub {
      my($key, $c, $op) = @_;
      my $sub;
      if($c =~s/\s*~\s*//){
        my($start, $end) = split(/,/, $c);
        $sub = sub{my($self, $v) = @_; return $v ? (($start <= length($v) and length($v) <=  $end) + 0) : ()}
      }else{
        my($start, $end) = split(/,/, $c);
        $sub = sub{my($self, $v) = @_; return $v ? (($start <= $v and $v <=  $end) + 0) : ()}
      }
      return  sub{my($self, $v) = @_; _vand($self, $key, $c, $v, $sub)};
    },
    IN => sub {
      my($key, $c) = @_;
      my @words = _arg($c);
      my $sub = sub{
        my($self, $v) = @_;
        my $ok = 0;
        foreach my $word (@words){
          $ok |= $v eq $word or last;
        }
        return $ok;
      };
      return sub {my($self, $v) = @_; return(_vor($self, $key, $c, $v, sub{my($self, $v) = @_; $sub->($self, $v)}))};
    },
    EQ => sub {
      my($key, $c) = @_;
      if($c =~s/^\[(.+)\]$/$1/){
        return sub{
          my($self, $v, $key) = @_;
          my($obj, $method) = ($self->obj, $self->method);
          return (($v->[0] eq $obj->$method($c)) + 0)
        };
      }elsif($c =~s/^\{(.+)\}$/$1/){
        return sub{
          my($self, $v, $key, $given_data) = @_;
          my($obj, $method) = ($self->obj, $self->method);
          return (($v->[0] eq $given_data->{$c}) + 0)
        };
      }else{
        return sub{
          my($self, $v) = @_;
          return (($v->[0] eq $c) + 0);
        };
      }
    },
    NE => sub {
      my($key, $c) = @_;
      if($c =~s/^\[(.+)\]$/$1/){
        return sub{
          my($self, $v, $key) = @_;
          my($obj, $method) = ($self->obj, $self->method);
          return (($v->[0] ne $obj->$method($c)) + 0)
        };
      }else{
        return sub{
          my($self, $v) = @_;
          return (($v->[0] ne $c) + 0);
        };
      }
    },
  };

$parent->add_operator
  (
   'is'        => ARE,
   'isnt'      => ARENT,
   'are'       => ARE,
   'arent'     => ARENT,
   're'        => MATCH,
   'match'     => MATCH,
   'length'    => LENGTH,
   '>'         => GT,
   '>='        => GT,
   '<'         => LT,
   '<='        => LT,
   'between'   => BETWEEN,
   'in'        => IN,
   'eq'        => EQ,
   'ne'        => NE,
   'equal'     => EQ,
   'not_equal' => NE,
   'has'       =>
   sub {
     my($key, $c) = @_;
     if(my($e, $n) = $c =~m{^\s*([<>])?\s*(\d+)$}){
       $e ||= '';
       if($e eq '<'){
         return sub{my($self, $v) = @_; return @$v < $n}
       }elsif($e eq '>'){
         return sub{my($self, $v) = @_; return @$v > $n}
       }else{
         return sub{my($self, $v) = @_; return @$v == $n}
       }
     }else{
       Carp::croak("$c is not number");
     }
   },
   'of-valid' =>
   sub {
     my($key, $c) = @_;
     my @cond = _arg($c);
     return
       sub {
         my($self, $values, $alias, $given_data, $validate_data) = @_;
         my($obj, $method) = ($self->obj, $self->method);
         my $ok = 0;
         my $n  = 0;
         foreach my $k (@cond){
           next unless $k;
           if($self->valid_yet($k)){
             $self->{valid} &= $self->_validate($k, @$validate_data);
           }
           ++$ok if $self->valid_ok($k);
           ++$n;
         }
         return $key eq 'all' ? ($ok == $n) + 0 : ($ok == $key) + 0 ;
       }, NEED_ALIAS | ALLOW_NO_VALUE;
     },
   'of'     =>
   sub {
     my($key, $c) = @_;
     my @cond = _arg($c);
     return
       sub {
         my($self, $values, $alias) = @_;
         my($obj, $method) = ($self->obj, $self->method);
         my $ok = 0;
         my $n  = 0;
         foreach my $k (@cond){
           next unless $k;
           ++$ok if defined $obj->$method($k);
           ++$n;
         }
         return $key eq 'all' ? ($ok == $n) + 0 : ($ok == $key) + 0 ;
       }, NEED_ALIAS | ALLOW_NO_VALUE;
     },
  );

1;

=head1 Name

Data::RuledValidator::Closure - sobroutines to create closure using by Data::RuledValidator

=head1 Description

=head1 Synopsys

=head1 Author

Ktat, E<lt>ktat@cpan.orgE<gt>

=head1 Copyright

Copyright 2006-2007 by Ktat

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
