package Data::DefGen;

use warnings;
use strict;

BEGIN {
    require Exporter;
    *import = \&Exporter::import;

    our $VERSION = "1.001003";
    our @EXPORT = qw(def);
}

use Scalar::Util qw(reftype blessed);

# to subclass, copy and EXPORT this function
sub def (&@) { __PACKAGE__->new(data => shift, @_) }

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    %{ $self } = (
        data => undef,
        @_,
    );

    $self->{obj_cloner} = sub { $_[0] }
      unless UNIVERSAL::isa($self->{obj_cloner}, "CODE");
}

sub gen {
    my $self = shift;
    local $self->{gen_p} = \@_;

    return $self->_gen($self->{data}) if ref($self->{data}) ne "CODE";

    my @data = @{ $self->_gen([ $self->{data}->(@_) ]) };
    return @data[0 .. $#data];
}

sub _gen {
    my $self = shift;

    if (defined blessed($_[0]))
    {
        return $_[0]->isa(ref $self)
          ? $_[0]->gen(@{ $self->{gen_p} })
          : $self->{obj_cloner}->($_[0]);
    }

    my $type = reftype($_[0]);
    $type or return $_[0];
    $type eq "HASH"   and return { map +($_ => $self->_gen($_[0]->{$_})), keys %{ $_[0] } };
    $type eq "ARRAY"  and return [ map $self->_gen($_), @{ $_[0] } ];
    $type eq "SCALAR" and return \${ $_[0] };
    $type eq "REF"    and return \$self->_gen(${ $_[0] });
    return $_[0];
}

1;


__END__

=pod

=head1 NAME

Data::DefGen - Define and Generate arbitrary data.


=head1 SYNOPSIS

  use Data::DefGen;

  my $defn = def {
      my $date = localtime;

      return {
          when => $date,
          result => def { [ 1 .. rand(5), def { scalar reverse 'olleh' } ] },
          topic => def { pick_one('foo', 'bar', 'baz') },
      };
  };

  my $data = $defn->gen;

  # Example of generated data
  # {
  #     when => 'Sun Apr 19 12:48:16 2015',
  #     result => [1, 2, 3, 'hello'],
  #     topic => 'bar',
  # }

  # Generate 10 of these
  my @datas = def { ($defn) x 10 }->gen;


=head1 DESCRIPTION

This module exports a single C<def> function that takes a CODE block to define a data structure. The returned structure may contain more definitions within it.

Calling C<gen> method on the returned object will recursively execute all the definitions, and return the entire generated data structure. Params passed to C<gen> will be received by all CODE definitions.

By default, a shallow copy is performed whenever a blessed object is encountered. To override this behavior, pass an C<obj_cloner> function, per C<def> block:

  my $defn = def { ... } obj_cloner => sub { my_cloning($_[0]) };

Unlike C<gen> params, the C<obj_cloner> function does not propagate to nested definitions.


=head1 CREDIT

This was inspired by the JSON Generator L<http://www.json-generator.com/>.


=head1 DEPENDENCIES

No non-core modules are required.


=head1 AUTHOR

Gerald Lai <glai at cpan dot org>


=cut

