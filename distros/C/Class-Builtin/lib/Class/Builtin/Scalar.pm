package Class::Builtin::Scalar;
use 5.008001;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;

use Carp;
use Encode ();

use overload (
    bool     => sub { !! ${ $_[0] } },
    '""'     => sub { ${ $_[0] } . '' },
    '0+'     => sub { ${ $_[0] } + 0  },
    '@{}'    => sub { $_[0]->split(qr//) },
    # unary ops
    (map { $_ => eval qq{sub {
       __PACKAGE__->new($_ \${\$_[0]});
      }
    } } qw{ ~ }),
    # binary numeric ops
    (map { $_ => eval qq{sub {
       my \$l = ref \$_[0] ? \${\$_[0]} : \$_[0];
       my \$r = ref \$_[1] ? \${\$_[1]} : \$_[1];
       # warn "\$l $_ \$r";
       __PACKAGE__->new(\$l $_ \$r);
      }
    } } qw{+ - * / % ** << >> & | ^ . x }),
    # comparison ops -- bools are not objects
    (map { $_ => eval qq{sub {
         my \$l = ref \$_[0] ? \${\$_[0]} : \$_[0];
         my \$r = ref \$_[1] ? \${\$_[1]} : \$_[1];
         \$l $_ \$r;
      }
    } } qw{ <=> cmp }),
    fallback => 1,
);

sub new {
    my ( $class, $scalar ) = @_;
    return $scalar if ref $scalar;
    bless \$scalar, $class;
}

sub clone{
    __PACKAGE__->new( ${$_[0]} );
}

sub unbless{ ${$_[0]} }

sub dump {
    local ($Data::Dumper::Terse)  = 1;
    local ($Data::Dumper::Indent) = 0;
    local ($Data::Dumper::Useqq)  = 1;
    sprintf 'OO(%s)', Data::Dumper::Dumper(${$_[0]});
}

my @unary = qw(
  length defined ref
  chomp chop chr lc lcfirst ord reverse uc ucfirst
  cos sin exp log sqrt int
  hex oct
);

for my $meth (@unary) {
    eval qq{
      sub Class::Builtin::Scalar::$meth
      {
	my \$self = shift;
	my \$ret  = CORE::$meth(\$\$self);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}

sub atan2{
    my $self   = shift;
    my $second = shift || 1;
    __PACKAGE__->new( CORE::atan2($$self, $second) );
}

# prototype: $$ => $
for my $meth (qw/crypt/) {
    eval qq{
      sub Class::Builtin::Scalar::$meth
      {
	my \$self = shift;
        my \$arg0 = shift;
	my \$ret  = CORE::$meth(\$\$self, \$arg0);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}
# prototype: $$ => @
sub unpack{
    my $self = shift;
    my $form = shift;
    my @ret  = CORE::unpack $$self, $form;
    __PACKAGE__->new([\@ret]);
}

# prototype: $$;$
for my $meth (qw/index rindex/) {
    eval qq{
      sub Class::Builtin::Scalar::$meth
      {
	my \$self = shift;
        my \$arg0 = shift;
	my \$ret  = \@_ ? CORE::$meth(\$\$self, \$arg0, shift)
                        : CORE::$meth(\$\$self, \$arg0);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}

# prototype:$@
for my $meth (qw/pack sprintf/) {
    eval qq{
      sub Class::Builtin::Scalar::$meth
      {
	my \$self = shift;
	my \$ret  = CORE::$meth(\$\$self, \@_);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}

sub substr {
    my $self = shift;
    croak unless @_ > 0;
    my $ret =
        @_ == 1 ? CORE::substr $$self, $_[0]
      : @_ == 2 ? CORE::substr $$self, $_[0], $_[1]
      : CORE::substr @$self, $_[0], $_[1], $_[2];
    return @_ > 2 ? $self : __PACKAGE__->new($ret);
}

sub split {
    my $self = shift;
    my $pat  = shift || qr//;
    my @ret  = CORE::split $pat, $$self;
    Class::Builtin::Array->new( [@ret] );
}

sub print {
    my $self = shift;
    @_ ? CORE::print {$_[0]} $$self : CORE::print $$self;
}

sub say {
    my $self = shift;
    local $\ = "\n";
    @_ ? CORE::print {$_[0]} $$self : CORE::print $$self;
}

sub methods {
    Class::Builtin::Array->new(
        [ sort grep { defined &{$_} } keys %Class::Builtin::Scalar:: ] );
}

# Encode-related
for my $meth (qw/decode encode decode_utf8/){
    eval qq{
    sub Class::Builtin::Scalar::$meth
    {
	my \$self = shift;
	my \$ret  = Encode::$meth(\$\$self,\@_);
	__PACKAGE__->new(\$ret);
    }
    };
    croak $@ if $@;
}
for my $meth (qw/encode_utf8/){
    eval qq{
    sub Class::Builtin::Scalar::$meth
    {
	my \$self = shift;
	my \$ret  = Encode::$meth(\$\$self);
	__PACKAGE__->new(\$ret);
    }
    };
    croak $@ if $@;
}

*bytes = \&encode_utf8;
*utf8  = \&decode_utf8;

# Scalar::Util
# dualvar() and  set_prototype() not included

our @scalar_util = qw(
  blessed isweak readonly refaddr reftype tainted
  weaken isvstring looks_like_number
);

for my $meth (qw/blessed isweak refaddr reftype weaken/){
    eval qq{
      sub Class::Builtin::Scalar::$meth
      {
	my \$self = shift;
	my \$ret  = Scalar::Util::$meth(\$self);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}

for my $meth (qw/readonly tainted isvstring looks_like_number/){
    eval qq{
      sub Class::Builtin::Scalar::$meth
      {
	my \$self = shift;
	my \$ret  = Scalar::Util::$meth(\$\$self);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}

1; # End of Class::Builtin::Scalar

=head1 NAME

Class::Builtin::Scalar - Scalar as an object

=head1 VERSION

$Id: Scalar.pm,v 0.3 2009/06/22 15:52:18 dankogai Exp $

=head1 SYNOPSIS

  use Class::Builtin::Scalar;                    # use Class::Builtin::Builtin;
  my $foo = Class::Builtin::Scalar->new('perl'); # OO('perl');
  print $foo->length; # 4

=head1 EXPORT

None.  But see L<Class::Builtin>

=head1 METHODS

This section is under construction. For the time being, try

  print Class::Builtin::Scalar->new(0)->methods->join("\n")

=head1 TODO

This section itself is to do :)

=over 2

=item * what should C<< $s->m(qr/.../) >> return ? SCALAR ? ARRAY ?

=item * more methods

=back

=head1 SEE ALSO

L<Class::Builtin>, L<Class::Builtin::Array>, L<Class::Builtin::Hash>

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 ACKNOWLEDGEMENTS

L<autobox>, L<overload>, L<perlfunc> L<http://www.ruby-lang.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
