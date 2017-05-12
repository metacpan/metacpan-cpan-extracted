package Class::Builtin::Hash;
use 5.008001;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.3 $ =~ /(\d+)/g;

use Carp;

use overload (
    '""' => \&Class::Builtin::Hash::dump,
);

sub new{
    my $class = shift;
    my $href  = shift;
    my %self;
    while(my ($k, $v) = each %$href){
	$self{$k} = Class::Builtin->new($v);
    }
    bless \%self, $class;
}

sub clone{
    __PACKAGE__->new({ %{$_[0]} });
}

sub get { $_[0]->{ $_[1] } }

sub set { $_[0]->{ $_[1] } = Class::Builtin->new( $_[2] ) }

sub unbless {
    my $self = shift;
    my %hash;
    while(my ($k, $v) = each %$self){
	$hash{$k} = eval { $v->can('unbless') } ? $v->unbless: $v;
    }
    \%hash;
}

sub dump {
    local ($Data::Dumper::Terse)  = 1;
    local ($Data::Dumper::Indent) = 0;
    local ($Data::Dumper::Useqq)  = 1;
    sprintf 'OO(%s)', Data::Dumper::Dumper($_[0]->unbless);
}

sub delete {
    my $self = shift;
    my @deleted = CORE::delete @{$self}{@_};
    Class::Builtin::Array->new([@deleted]);
}

sub exists {
    my $self = shift;
    my $key  = shift;
    CORE::exists $self->{$key}
}

for my $meth (qw/keys values/){
    eval qq{
      sub Class::Builtin::Hash::$meth
      {
        Class::Builtin::Array->new([CORE::$meth \%{\$_[0]}])
      }
    };
    croak $@ if $@;
}

sub length{
    CORE::length keys %{$_[0]};
}

sub each {
    my $self = shift;
    my $block = shift || croak;
    while (my ($k, $v) = each %$self){
	$block->($k, $v);
    }
}

sub print {
    my $self = shift;
    @_ ? CORE::print {$_[0]} %$self : CORE::print %$self;
}

sub say {
    my $self = shift;
    local $\ = "\n";
    local $, = ",";
    @_ ? CORE::print {$_[0]} %$self : CORE::print %$self;
}



sub methods {
    Class::Builtin::Array->new(
        [ sort grep { defined &{$_} } keys %Class::Builtin::Hash:: ] );
}

# Scalar::Util related
for my $meth (qw/blessed isweak refaddr reftype weaken/){
    eval qq{
      sub Class::Builtin::Hash::$meth
      {
	my \$self = CORE::shift;
	my \$ret  = Scalar::Util::$meth(\$self);
	__PACKAGE__->new(\$ret);
      }
    };
    croak $@ if $@;
}

1; # End of Class::Builtin::Hash

=head1 NAME

Class::Builtin::Hash - Hash as an object

=head1 VERSION

$Id: Hash.pm,v 0.3 2009/06/22 15:52:18 dankogai Exp $

=head1 SYNOPSIS

  use Class::Builtin::Hash;                             # use Class::Builtin;
  my $oo = Class::Builtin::Hash->new({key => 'value'}); # OO({key =>'value'});
  print $oo->keys->[0]; # 'key'

=head1 EXPORT

None.  But see L<Class::Builtin>

=head1 METHODS

This section is under construction. For the time being, try

  print Class::Builtin::Hash->new({})->methods->join("\n")

=head1 TODO

This section itself is to do :)

=over 2

=item * more methods

=back

=head1 SEE ALSO

L<autobox>, L<overload>, L<perlfunc> L<http://www.ruby-lang.org/>

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 ACKNOWLEDGEMENTS

L<autobox>, L<overload>, L<perlfunc>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
