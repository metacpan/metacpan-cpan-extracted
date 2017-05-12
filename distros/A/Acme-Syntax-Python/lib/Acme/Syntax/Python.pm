use strict;
use warnings;
package Acme::Syntax::Python;
use Filter::Util::Call;
use vars qw($VERSION);

$VERSION = "0.01";

# ABSTRACT: Python like Syntax Module

sub import {
    my $class = shift; #We don't need Class Name.
    my %params = @_;
    my (%context) = (
        _filename => (caller)[1],
        _line_no => 0,
        _last_begin => 0,
        _in_block => 0,
        _block_depth => 0,
        _lambda_block => {},
        _class_block => {},
        _debug => $params{debug}
    );
    filter_add(bless \%context, $class);
}

sub error {
    my ($self) = shift;
    my ($message) = shift;
    my ($line_no) = shift || $self->{last_begin};
    die "Error: $message at $self->{_filename} line $line_no.\n"
}

sub warning {
    my ($self) = shift;
    my ($message) = shift;
    my ($line_no) = shift || $self->{last_begin};
    warn "Warning: $message at $self->{_filename} line $line_no.\n"
}

sub filter {
    my ($self) = @_;
    my ($status);
    $status = filter_read();
    ++ $self->{line_no};
    if ($status <= 0) {
        if($self->{_in_block}) {
            $_ = "}\n";
            ++ $status;
            $self->{_in_block} = 0;
        }
        return $status;
    }

    if($self->{_in_block}) {
        _handle_block($self, $_);
    }

    s{^\s*import (.+);$}
     {use $1;}gmx;
    s{^\s*from (.+) import (.+);$}
     {use $1 ($2);}gmx;

    s{True}{1}gmx;
    s{False}{0}gmx;

    if(/class (.+) inherits (.+):/) {
        s{class (.+) inherits (.+):}{\{\npackage $1;\nuse $2; our \@ISA = qw($2);\n}gmx;
        _start_block($self);
    }

    if(/class (.+):/) {
        s{class (.+):}{\{\npackage $1;\n}gmx;
        _start_block($self);
    }

    #Handle def with Params
    if(/lambda\((.+)\):/) {
        s{lambda\((.+)\):}{sub \{ my($1) = \@_;}gmx;
        _start_block($self, "_lambda_block");
    }

    #Handle def with no Params
    if(/lambda:/) {
        s{lambda:}{sub \{};
        _start_block($self, "_lambda_block");
    }

    #Handle def with Params
    if(/def (.+)\((.+)\):/) {
        if($1 eq "__init__") {
            s{def (.+)\((.+)\):}{sub $1 \{ my(\$class, $2) = \@_; my \$self = \{\};}gmx;
            $self->{_class_block}->{($self->{_block_depth} + 1)} = 1;
        } else {
            s{def (.+)\((.+)\):}{sub $1 \{ my($2) = \@_;}gmx;
        }
        _start_block($self);
    }

    #Handle def with no Params
    if(/def (.+):/) {
        if($1 eq "__init__") {
            s{def (.+):}{sub $1 \{ my (\$class) = shift; my \$self = \{\};}gmx;
            $self->{_class_block}->{($self->{_block_depth} + 1)} = 1;
        } else {
            s{def (.+):}{sub $1 \{}gmx;
        }
        _start_block($self);
    }

    s{__init__}{new}gmx;

    if(/elif (.+)/) {
        s{elif (.+)}{elsif $1}gmx;
    }
    elsif(/if (.*)/) {
        s{if (.*)}{if $1}gmx;
    }
    if(/\):$/) {
        s{:$}{ \{}gmx;
        _start_block($self);
    }
    if(/else:/) {
        s{:$}{\{}gmx;
        _start_block($self);
    }

    if($self->{_debug}) {
        print "$self->{line_no} $_";
    }
    return $status;
}

sub _handle_spacing {
    my $depth = shift;
    my $modifier = shift // 1;
    return (' ') x (4 * ($depth - $modifier));
}

sub _start_block {
    my ($self, $type) = @_;
    $self->{_in_block} = 1;
    ++ $self->{_block_depth};
    if(defined($type)) {
        $self->{$type}->{$self->{_block_depth}} = 1;
    }
}

sub _handle_block {
        my ($self) = @_;
        /^(\s*)/;
        my $depth = length ( $1 );
        if($depth < (4 * $self->{_block_depth})) {
            my $spaces = _handle_spacing($self->{_block_depth});
            if($self->{_lambda_block}->{$self->{_block_depth}}) {
                $self->{_lambda_block}->{$self->{_block_depth}} = 0;
                s/^/$spaces\};\n/;
            } elsif ($self->{_class_block}->{$self->{_block_depth}}){
                my $spaces_front = _handle_spacing($self->{_block_depth}, 0);
                $self->{_class_block}->{$self->{_block_depth}} = 0;
                s/^/$spaces_front return bless \$self, \$class;\n$spaces\}\n/;
            } else {
                s/^/$spaces\}\n/;
            }
            -- $self->{_block_depth};
        }
        if($self->{_block_depth} == 0) {
            $self->{_in_block} = 0;
        }
}

1;

__END__

=head1 NAME

Acme::Syntax::Python - Python like Syntax for Perl.

=head1 SYNOPSIS

  use Acme::Syntax::Python;
  from Data::Dump import 'dump';

  def print_dump:
      print dump "Hello";

  print_dump;

=head1 DESCRIPTION

Translates a Python like syntax into executable Perl code. Right now blocks are defined by 4 spaces. I plan on extending this to tabs as well soon.

=head1 MODULES

Include modules into your file is much like the Python way using import.

  import Data::Dump;

this would include the Data::Dump module and whatever it exported by default.

If you need to exlicity name exports you can using "from"

  from Data::Dump import 'dump';

With perl you can also define params for use, with those you would just use import as a syntatic change of use.

  import Test::More tests => 4;

=head1 FUNCTIONS

You can declare Functions just like you would in Python.

ex: Function with no Paramaters:

  def hello_world:
      print "Hello World";

You can also declare functions with Paramaters:

  def hello($say):
      print "Hello $say";

  hello("World");

It will automatically define the variable for you and assign it from the paramater list.

=head1 LAMBDA

Lambas are also supported as a named definition:

  my $sub = lambda: 5 * 2;

  print $sub->();

Would print 10.

You can declare params for lambdas just like functions:

  my $sub = lambda ($x): $x * 2;

  print $sub->(5);

Would print 10 as well.

=head1 IF/ELIF/ELSE

If/Else is the same as python as well, just you cannot omit the ()'s around the condition statements.
The Conditionals are still the same Perl conditionals.

  if ($1 eq "hello"):
      print "I received Hello!";
  elif ($2 eq "world"):
      print "I received World!";
  else:
      print "No mathces for me";


Conditionals can also span multiple lines like normal:

  if($bar == 1 &&
     $foo == 2):
      print "Truth";

=head1 CLASSES

Class definitions are supported as well, though translated in Perl they're just a Namespace declaration.

  class Foo:
      def bar:
          print "baz";

  Foo::baz();

You can also create Class Objects, using __init__ as the "sub new" constructor.
If declaring your paramaters for a Method in a Object class you need to declare $self first.

  class Foo:
      def __init__($bar):
          $self->{bar} = $bar;

      def bar($self):
          print $self->{bar};

  $baz = Foo->new("bar");
  print $baz->bar();


Classes can also handle inheritance of other modules:

  use Acme::Syntax::Python; 
  class Foo inherits File::Find:
      def bar:
          print "baz";

  import Foo;
  Foo::find(\&wanted, "./");

If you wanted to write an entire object class with this then you would put the class in it's own .pm file
like normal and include it in the Perl file like normal.

=head1 VERSION

This documentation describes version 0.02.

=head1 AUTHOR

 Madison Koenig <pedlar AT cpan DOT org>

=head1 COPYRIGHT

Copyright (c) 2013 Madison Koenig
All rights reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
