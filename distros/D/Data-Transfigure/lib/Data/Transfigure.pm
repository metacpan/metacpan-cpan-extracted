package Data::Transfigure 1.03;
use v5.26;
use warnings;

# ABSTRACT: performs rule-based data transfigurations of arbitrary structures

=encoding UTF-8
 
=head1 NAME
 
Data::Transfigure - performs rule-based data transfigurations of arbitrary structures
 
=head1 SYNOPSIS

    use Data::Transfigure;

    my $d = Data::Transfigure->std();
    $d->add_transfigurators(qw(
      Data::Transfigure::Type::DateTime::Duration
      Data::Transfigure::HashKeys::CamelCase
    ), Data::Transfigure::Type->new(
      type    => 'Activity::Run'.
      handler => sub ($data) {
        {
          start    => $data->start_time, # DateTime
          time     => $data->time,       # DateTime::Duration
          distance => $data->distance,   # number
          pace     => $data->pace,       # DateTime::Duration
        }
      }
    ));

    my $list = [
      { user_id => 3, run  => Activity::Run->new(...) },
      { user_id => 4, ride => Activity::Ride->new(...) },
    ];

    $d->transfigure($list); # [
                          #   {
                          #     userID => 3
                          #     run    => {
                          #                 start    => "2023-05-15T074:11:14",
                          #                 time     => "PT30M5S",
                          #                 distance => "5",
                          #                 pace     => "PT9M30S",
                          #               }
                          #   },
                          #   {
                          #     userID => 4,
                          #     ride   => "Activity::Ride=HASH(0x2bbd7d16f640)",
                          #   },
                          # ]

=head1 DESCRIPTION

C<Data::Transfigure> allows you to write reusable rules ('transfigurators') to modify
parts (or all) of a data structure. There are many possible applications of this,
but it was primarily written to handle converting object graphs of ORM objects
into a structure that could be converted to JSON and delivered as an API endpoint
response. One of the challenges of such a system is being able to reuse code
because many different controllers could need to convert the an object type to
the same structure, but then other controllers might need to convert that same
type to a different structure.

A number of transfigurator roles and classes are included with this distribution:

=over

=item * L<Data::Transfigure::Node>
the root role which all transfigurators must implement

=item * L<Data::Transfigure::Default>
a low priority transfigurator that only applies when no other transfigurators do

=item * L<Data::Transfigure::Default::ToString>
a transfigurator that stringifies any value that is not otherwise transfigured

=item * L<Data::Transfigure::Type>
a transfigurator that matches against one or more data types

=item * L<Data::Transfigure::Type::DateTime>
transfigures DateTime objects to L<ISO8601|https://en.wikipedia.org/wiki/ISO_8601> 
format.

=item * L<Data::Transfigure::Type::DateTime::Duration>
transfigures L<DateTime::Duration> objects to 
L<ISO8601|https://en.wikipedia.org/wiki/ISO_8601#Durations> (duration!) format

=item * L<Data::Transfigure::Type::DBIx>
transfigures L<DBIx::Class::Row> instances into hashrefs of colname->value 
pairs. Does not recurse across relationships

=item * L<Data::Transfigure::Type::DBIx::Recursive>
transfigures L<DBIx::Class::Row> instances into hashrefs of colname->value pairs,
recursing down to_one-type relationships

=item * L<Data::Transfigure::Value>
a transfigurator that matches against data values (exactly, by regex, or by coderef 
callback)

=item * L<Data::Transfigure::Position>
a compound transfigurator that specifies one or more locations within the data 
structure to apply to, in addition to whatever other criteria its transfigurator 
specifies

=item * L<Data::Transfigure::Tree>
a transfigurator that is applied to the entire data structure after all 
node transfigurations have been completed

=item * L<Data::Transfigure::HashKeys::CamelCase>
a transfigurator that converts all hash keys in the data structure to 
lowerCamelCase

=item * L<Data::Transfigure::HashKeys::SnakeCase>
a transfigurator that converts all hash keys in the data structure to 
snake_case

=item * L<Data::Transfigure::HashKeys::CapitalizedIDSuffix>
a transfigurator that converts "Id" at the end of hash keys (as results from 
lowerCamelCase conversion) to "ID"

=item * L<Data::Transfigure::HashFilter::Undef>
a transfigurator that removes key/value pairs where the value is undefined and
the key matches a certain pattern

=item * L<Data::Transfigure::Tree::Merge>
a transfigurator that expands marked hash keys' HashRef values into the enclosing
hash, overwriting common keys

=back

=cut

use Object::Pad;

class Data::Transfigure 1.00 {
  use Exporter qw(import);

  use Data::Compare;

  use Data::Transfigure::Default;
  use Data::Transfigure::Value;
  use Data::Transfigure::Position;

  use Data::Transfigure::Constants;

  use List::Util   qw(max);
  use Module::Util qw(module_path);
  use Scalar::Util qw(blessed);
  use Readonly;

  field @transfigurators;
  field @post_transfigurators;

  our @EXPORT_OK = qw(hk_rewrite_cb concat_position);

  sub hk_rewrite_cb ($h, $cb) {
    if (ref($h) eq 'HASH') {
      foreach (keys($h->%*)) {
        hk_rewrite_cb($h->{$cb->($_)} = delete($h->{$_}), $cb);
      }
    } elsif (ref($h) eq 'ARRAY') {
      foreach my $o ($h->@*) {
        hk_rewrite_cb($o, $cb);
      }
    }
    return $h;
  }

  sub concat_position ($base, $add) {
    $base //= q{};
    $add  //= q{};
    $base =~ s|/+$||;
    $add  =~ s|^/+||;
    return join('/', ($base eq '/' ? '' : $base, $add));
  }

#<<V perltidy can't handle Object::Pad's lexical methods
  method $check_frame ($frame, $stack) {
    foreach my $c (reverse $stack->@*) {
      return 1 if($c->[0] == $frame->[0] && Compare($c->[1], $frame->[1]));
    }
    return 0;
  }

  method $get_matching_transfigurator_idx ($data, $path) {
    my @match;
    for (my $i = 0 ; $i < @transfigurators ; $i++) {
      my $v = $transfigurators[$i]->applies_to(value => $data, position => $path);
      push(@match, {value => $v, index => $i}) if ($v != $NO_MATCH);
    }
    return undef unless (@match);

    my $best_match = max(map {$_->{value}} @match);
    @match = sort {$b->{index} - $a->{index}} grep {$_->{value} == $best_match} @match;
    return $match[0]->{index};
  }

  method $transfigure ($data, $path, $stack = []) {
    my ($idx, $frame);
    if(ref($data) eq 'ARRAY') {
      $frame = [-2, $data];
      die("Deep recursion detected in Data::Transfigure::transfigure\n") if($self->$check_frame($frame, $stack));
      $data = [ map{ __SUB__->($self, $data->[$_], concat_position($path, $_), [$stack->@*, ]) } 0..$#$data ] # transfigure members of array
    } elsif(ref($data) eq 'HASH') {
      $frame = [-1, $data];
      die("Deep recursion detected in Data::Transfigure::transfigure\n") if($self->$check_frame($frame, $stack));
      $data = { map { $_ => __SUB__->($self, $data->{$_}, concat_position($path, $_), [$stack->@*, $frame]) } keys($data->%*) } # trannsfigure values of hash
    }
      
    $idx = $self->$get_matching_transfigurator_idx($data, $path); # transfigure the data item
    return $data unless(defined($idx));

    $frame = [$idx, $data];
    die("Deep recursion detected in Data::Transfigure::transfigure\n") if($self->$check_frame($frame, $stack));
    $data = $transfigurators[$idx]->transfigure($data);
    $data = __SUB__->($self, $data, $path, [$stack->@*, $frame]) if (ref($data)); #recursively transfigure the transfigured data item
    return $data;
  }

  method $add_standard_transfigurators () {
    $self->add_transfigurators(
      'Data::Transfigure::Default::ToString',
      Data::Transfigure::Value->new(
        value   => undef,
        handler => sub ($data) {
          return undef;
        }
      ),
    );
  }

  method $remove_all_transfigurators () {
    @transfigurators = ();
    @post_transfigurators = ();
  }
#>>V

=pod

=head1 CONSTRUCTORS

=head2 Data::Transfigure->new()

Constructs a new default instance that pre-adds 
L<Data::Transfigure::Default::ToString> to stringify values that are not otherwise
transfigured by user-provided transfigurators. Preserves (does not transfigure to 
empty string) undefined values.

=head2 Data::Transfigure->bare()

Returns a "bare-bones" instance that has no builtin data transfigurators.

=cut

  sub bare ($class) {
    my $t = Data::Transfigure->new();
    $t->$remove_all_transfigurators();
    return $t;
  }

=pod

=head2 Data::Transfigure->dbix()

Adds L<Data::Transfigure::DBIx::Recursive> to to handle C<DBIx::Class> result rows

=cut

  sub dbix ($class) {
    my $t = $class->new();
    $t->add_transfigurators('Data::Transfigure::Type::DBIx::Recursive',);
    return $t;
  }

  ADJUST {
    $self->$add_standard_transfigurators();
  }

=pod

=head1 METHODS

=head2 add_transfigurators( @list )

Registers one or more data transfigurators with the C<Data::Transfigure> instance.

    $t->add_transfigurators(Data::Transfigure::Type->new(
      type    => 'DateTime',
      handler => sub ($data) {
        $data->strftime('%F')
      }
    ));

Each element of C<@list> must implement the L<Data::Transfigure::Node> role, though
these can either be strings containing class names or object instances.

C<Data::Transfigure> will automatically load class names passed in this list and 
construct an object instance from that class. This will fail if the class's C<new>
constructor does not exist or has required parameters.

    $t->add_transfigurators(qw(Data::Transfigure::Type::DateTime Data::Transfigure::Type::DBIx));

ArrayRefs passed in this list will be expanded and their contents will be treated
the same as any item passed directly to this method.

    my $default = Data::Transfigure::Type::Default->new(
      handler => sub ($data) {
        "[$data]"
      }
    );
    my $bundle = [q(Data::Transfigure::Type::DateTime), $default];
    $t->add_transfigurators($bundle);

When transfiguring data, only one transfigurator will be applied to each data element,
prioritizing the most-specific types of matches. Among transfigurators that have 
equal match types, those added later have priority over those added earlier.

=cut

  method add_transfigurators (@args) {
    foreach my $t (map {ref($_) eq 'ARRAY' ? $_->@* : $_} @args) {
      if (!defined($t)) {
        die("Cannot register undef");
      } elsif (ref($t)) {
        die("Cannot register non-Data::Transfigure::Node/Tree implementers ($t)")
          unless ($t->DOES('Data::Transfigure::Node') || $t->DOES('Data::Transfigure::Tree'));
      } elsif ($t eq 'Data::Transfigure::Node') {
        die('Cannot register Role');
      } else {
        require(module_path($t));
        die("Cannot register non-Data::Transfigure::Node/Tree implementers ($t)")
          unless ($t->DOES('Data::Transfigure::Node') || $t->DOES('Data::Transfigure::Tree'));
        $t = $t->new() unless (ref($t));
      }
      if ($t->DOES('Data::Transfigure::Node')) {
        push(@transfigurators, $t);
      } elsif ($t->DOES('Data::Transfigure::Tree')) {
        push(@post_transfigurators, $t);
      }
    }
    my @all = (@transfigurators, @post_transfigurators);
    return wantarray ? @all : scalar @all;
  }

=pod

=head2 add_transfigurator_at( $position => $transfigurator )

C<add_transfigurator_at> is a convenience method for creating and adding a 
positional transfigurator (one that applies to a specific data-path within the given
structure) in a single step.

See L<Data::Transfigure::Position> for more on positional transfigurators.

=cut

  method add_transfigurator_at ($position, $transfigurator) {
    push(
      @transfigurators,
      Data::Transfigure::Position->new(
        position       => $position,
        transfigurator => $transfigurator
      )
    );
  }

=pod

=head2 transfigure( $data )

Transfigures the data according to the transfigurators added to the instance and 
returns it. The data structure passed to the method is unmodified.

=cut

  method transfigure ($data) {
    my $d = $self->$transfigure($data, '/');
    $d = $_->transfigure($d) foreach (@post_transfigurators);
    return $d;
  }

}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
