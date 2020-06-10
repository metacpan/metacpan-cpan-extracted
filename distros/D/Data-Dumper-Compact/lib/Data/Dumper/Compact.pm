package Data::Dumper::Compact;

use List::Util qw(sum);
use Scalar::Util qw(blessed reftype);
use Data::Dumper ();
use Mu::Tiny;

our $VERSION = '0.005002';
$VERSION =~ tr/_//d;

sub import {
  my ($class, $ddc, $opts) = @_;
  return unless defined($ddc);
  die "Don't know how to export '$ddc'" unless ($ddc||'') =~ /^[jd]dc$/;
  my $targ = caller;
  my $cb = $class->new($opts||{})->dump_cb;
  no strict 'refs';
  *{"${targ}::${ddc}"} = $cb;
}

lazy max_width => sub { 78 };

lazy width => sub { shift->max_width };

lazy indent_width => sub { length($_[0]->indent_by) };

sub _next_width { $_[0]->width - $_[0]->indent_width }

lazy indent_by => sub { '  ' };

lazy transforms => sub { [] };

sub add_transform { push(@{$_[0]->transforms}, $_[1]); $_[0] }

sub _indent {
  my ($self, $string) = @_;
  my $ib = $self->indent_by;
  $string =~ s/^/$ib/msg;
  $string;
}

lazy dumper => sub {
  my ($self) = @_;
  my $dd = Data::Dumper->new([]);
  $dd->Trailingcomma(1) if $dd->can('Trailingcomma');
  $dd->Terse(1)->Indent(1)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1);
  my $indent_width = $self->indent_width;
  # feed the indent width down into B::Deparse - not using tabs because
  # it has no way to tell it how wide a tab is that I could find
  my $dp_new = do {
    require B::Deparse;
    my $orig = \&B::Deparse::new;
    sub { my ($self, @args) = @_; $self->$orig('-si'.$indent_width, @args) }
  };
  sub {
    no warnings 'redefine';
    local *B::Deparse::new = $dp_new;
    $dd->Values([ $_[0] ])->Dump
  },
};

sub _dumper { $_[0]->dumper->($_[1]) }

sub _optify {
  my ($self, $opts, $method, @args) = @_;
  # if we're an object, localize anything provided in the options,
  # and also blow away the dependent attributes if indent_by is changed
  ref($self) and $opts
    and (local @{$self}{keys %$opts} = values %$opts, 1)
    and $opts->{indent_by}
    and delete @{$self}{grep !$opts->{$_}, qw(indent_width dumper)};
  ref($self) or $self = $self->new($opts||{});
  $self->$method(@args);
}

sub dump {
  my ($self, $data, $opts) = @_;
  $self->_optify($opts, sub {
    my ($self) = @_;
    $self->format($self->transform($self->transforms, $self->expand($data)));
  });
}

sub dump_cb {
  my ($self) = @_;
  return sub { $self->dump(@_) };
}

sub expand {
  my ($self, $data) = @_;
  if (ref($data) eq 'HASH') {
    return [ hash => [
      [ sort keys %$data ],
      { map +($_ => $self->expand($data->{$_})), keys %$data }
    ] ];
  } elsif (ref($data) eq 'ARRAY') {
    return [ array => [ map $self->expand($_), @$data ] ];
  } elsif (blessed($data) and my $ret = $self->_expand_blessed($data)) {
    return $ret;
  }
  (my $thing = $self->_dumper($data)) =~ s/\n\Z//;

  # -foo and friends automatically become 'key' type, all else stays 'string'
  if (my ($string) = $thing =~ /^"(.*)"$/) {
    return [ ($string =~ /^-[a-zA-Z]\w*$/ ? 'key' : 'string') => $string ];
  }
  return [ thing => $thing ];
}

sub _expand_blessed {
  my ($self, $blessed) = @_;
  return unless grep { $_ eq 'ARRAY' or $_ eq 'HASH' } reftype($blessed);
  my $cursed = reftype($blessed) eq 'ARRAY' ? [ @$blessed ] : { %$blessed };
  return [ blessed => [ $self->expand($cursed), blessed($blessed) ] ];
}

sub transform {
  my ($self, $tfspec, $exp) = @_;
  return $exp unless $tfspec;
  # This is redundant from ->dump but consistent for direct user calls
  local $self->{transforms} = $tfspec;
  $self->_transform($exp, []);
}

sub _transform {
  my ($self, $exp, $path) = @_;
  my ($type, $payload) = @$exp;
  if ($type eq 'hash') {
    my %h = %{$payload->[1]};
    $payload = [
      $payload->[0],
      { map +(
          $_ => $self->_transform($h{$_}, [ @$path, $_ ])
        ), keys %h
      },
    ];
  } elsif ($type eq 'array') {
    my @a = @$payload;
    $payload = [ map $self->_transform($a[$_], [ @$path, $_ ]), 0..$#a ];
  }
  TF: foreach my $this_tf (@{$self->transforms}) {
    my $tf = $this_tf;
    my $last_tf = 0;
    while ($tf != $last_tf) {
      $last_tf = $tf;
      if (ref($tf) eq 'ARRAY') {
        my @match = @$tf;
        $tf = pop @match;
        next TF if @match > @$path; # not deep enough
        MATCH: foreach my $idx (0..$#match) {
          next MATCH unless defined(my $m = $match[$idx]);
          my $rpv = $path->[$idx-@match];
          if (!ref($m)) {
            next TF unless $rpv eq $m;
          } elsif (ref($m) eq 'Regexp') {
            next TF unless $rpv =~ $m;
          } elsif (ref($m) eq 'CODE') {
            local $_ = $rpv;
            next TF unless $m->($rpv);
          } else {
            die "Unknown path match type for $m";
          }
        }
      } elsif (ref($tf) eq 'HASH') {
        next TF unless $tf = $tf->{$type}||$tf->{_};
      }
    }
    ($type, $payload) = @{
      $self->$tf($type, $payload, $path)
      || [ $type, $payload ]
    };
  }
  return [ $type, $payload ];
}

sub format {
  my ($self, $exp) = @_;
  return $self->_format($exp)."\n";
  # If we realise we've flat run out of horizontal space, we need to be able
  # to jump back up the call stack to the top and start again - hence the
  # presence of this label to jump to from _format - of course, if that
  # clause never gets hit then our first _format call returns and therefore
  # the label is never reached.
  VERTICAL:
  local $self->{vertical} = 1;
  return $self->_format($exp)."\n";
}

sub _format {
  my ($self, $exp) = @_;
  my ($type, $payload) = @$exp;
  if (!$self->{vertical} and $self->width <= 0) {
    # We've run out of horizontal space, engage 'vertical sprawl mode' and
    # restart from the top by jumping back up the current call stack to the
    # VERTICAL label in the top-level call to format.
    no warnings 'exiting';
    goto VERTICAL;
  }
  return $self->${\"_format_${type}"}($payload);
}

sub _format_list {
  my ($self, $payload) = @_;
  my @plain = grep !/\s/, map $_->[1], grep $_->[0] eq 'string', @$payload;
  if (@plain == @$payload) {
    my $try = 'qw('.join(' ', @plain).')';
    return $try if $self->{oneline} or length($try) <= $self->width;
  }
  return $self->_format_arraylike('(', ')', $payload);
}

sub _format_array {
  my ($self, $payload) = @_;
  $self->_format_arraylike('[', ']', $payload);
}

sub _format_el {
  my ($self, $el) = @_;
  return $el->[1].' =>' if $el->[0] eq 'key';
  return $self->_format($el).',';
}

sub _format_arraylike {
  my ($self, $l, $r, $payload) = @_;
  if ($self->{vertical}) {
    return join("\n", $l,
      (map $self->_indent($self->_format($_).','), @$payload),
    $r);
  }
  return $l.$r unless my @pl = @$payload;
  my $last_pl = pop @pl;
  # We don't want 'foo =>' at the end of the array, so for the last
  # entry use plain _format which will render key-as-string, and don't
  # add a comma yet because we don't want a trailing comma on a single
  # line render
  my @oneline = do {
    local $self->{oneline} = 1;
    ((map $self->_format_el($_), @pl), $self->_format($last_pl));
  };
  if (!grep /\n/, @oneline) {
    my $try = join(' ', $l, @oneline, $r);
    return $try if $self->{oneline} or length $try <= $self->width;
  }
  local $self->{width} = $self->_next_width;
  if (@$payload == 1) {
    # single entry, re-format the payload without oneline set
    return $self->_format_single($l, $r, $self->_format($payload->[0]));
  }
  if (@$payload == 2 and $payload->[0][0] eq 'key') {
    my $s = (my $k = $self->_format_el($payload->[0]))
            .' '.$self->_format(my $p = $payload->[1]);
    return $self->_format_single($l, $r, do {
      $s =~ /\A(.{0,${\$self->width}})(?:\n|\Z)/
        ? $s
        : $k."\n".do {
            local $self->{width} = $self->_next_width;
            $self->_indent($self->_format($p));
          }
    });
  }
  my @lines;
  my @bits;
  $oneline[-1] .= ','; # going into multiline mode, *now* we add the comma
  foreach my $idx (0..$#$payload) {
    my $spare = $self->width - sum((scalar @bits)+1, map length($_), @bits);
    my $f = $oneline[$idx];
    if ($f !~ /\n/) {
      # single line entry, add to the bits for the current line if it'll fit
      # otherwise collapse bits into a line and start afresh with this entry
      if (length($f) <= $spare) {
        push @bits, $f;
        next;
      }
      if (length($f) <= $self->width) {
        push(@lines, join(' ', @bits));
        @bits = ($f);
        next;
      }
    }
    # If it didn't format as a single line, re-format to avoid confusion
    $f = $self->_format_el($payload->[$idx]);

    # if we can fit the first line in the available remaining space in the
    # current line, do that
    if ($spare > 0 and $f =~ s/^(.{0,${spare}})\n//sm) {
      push @bits, $1;
    }
    push(@lines, join(' ', @bits)) if @bits;
    @bits = ();
    # if the last line is less than our available width, turn that into
    # an entry in a new line
    if ($f =~ s/(?:\A|\n)(.{0,${\$self->width}})\Z//sm) {
      push @bits, $1;
    }
    # stuff whatever's left from the middle into the line array
    push(@lines, $f) if length($f);
  }
  push @lines, join(' ', @bits) if @bits;
  return join("\n", $l, (map $self->_indent($_), @lines), $r);
}

sub _format_hashkey {
  my ($self, $key) = @_;
  ($key =~ /^-?[a-zA-Z_]\w*$/
    ? $key
    # stick a space on the front to force dumping of e.g. 123, then strip it
    : do {
       s/^" //, s/"\n\Z// for my $s = $self->_dumper(" $key");
       $self->_format_string($s)
    }
  ).' =>';
}

sub _format_hash {
  my ($self, $payload) = @_;
  my ($keys, $hash) = @$payload;
  return '{}' unless @$keys;
  my %k = (map +(
    $_ => $self->_format_hashkey($_)), @$keys
  );
  if ($self->{vertical}) {
    return join("\n", '{',
      (map $self->_indent($k{$_}.' '.$self->_format($hash->{$_}).','), @$keys),
    '}');
  }
  my $oneline = do {
    local $self->{oneline} = 1;
    join(' ', '{', join(', ',
      map $k{$_}.' '.$self->_format($hash->{$_}), @$keys
    ), '}');
  };
  return $oneline if $self->{oneline};
  return $oneline if $oneline !~ /\n/ and length($oneline) <= $self->width;
  my $width = local $self->{width} = $self->_next_width;
  my @f = map {
    my $s = $k{$_}.' '.$self->_format(my $p = $hash->{$_});
    $s =~ /\A(.{0,${width}})(?:\n|\Z)/
      ? $s
      : $k{$_}."\n".do {
          local $self->{width} = $self->_next_width;
          $self->_indent($self->_format($p));
        }
  } @$keys;
  local $self->{width} = $self->_next_width;
  if (@f == 1) {
    return $self->_format_single('{', '}', $f[0]);
  }
  return join("\n",
    '{',
    (map $self->_indent($_).',', @f),
    '}',
  );
}

sub _format_key { shift->_format_string(@_) }

sub _format_string {
  my ($self, $str) = @_;
  my $q = $str =~ /[\\']/ ? q{"} : q{'};
  my $w = $self->{vertical} ? 20 : $self->_next_width;
  return $q.$str.$q if length($str) <= $w;
  $w--;
  my @f;
  while (length(my $chunk = substr($str, 0, $w, ''))) {
    push @f, $q.$chunk.$q;
  }
  return join("\n.", @f);
}

sub _format_thing { $_[1] }

sub _format_single {
  my ($self, $l, $r, $raw) = @_;
  my ($first, @lines) = split /\n/, $raw;
  return join("\n", $l, $self->_indent($first), $r) unless @lines;
  (my $pad = $self->indent_by) =~ s/^ //;
  my $last = $lines[-1] =~ /^[\}\]\)]/ ? (pop @lines).$pad: '';
  local $self->{width} = $self->_next_width;
  return join("\n",
    $l.($l eq '{' ? ' ' : $pad).$first,
    (map $self->_indent($_), @lines),
    $last.$r
  );
}

sub _format_blessed {
  my ($self, $payload) = @_;
  my ($content, $class) = @$payload;
  return 'bless( '.$self->_format($content).qq{, "${class}"}.' )';
}

1;
__END__

=head1 NAME

Data::Dumper::Compact - Vertically compact width-limited data formatter

=head1 SYNOPSIS

Basic usage as a function:

  use Data::Dumper::Compact 'ddc';
  
  warn ddc($some_data_structure);
  
  warn ddc($some_data_structure, \%options);

Slightly more clever usage as a function:

  use Data::Dumper::Compact ddc => \%default_options;
  
  warn ddc($some_data_structure);
  
  warn ddc($some_data_structure, \%extra_options);

OO usage:

  use Data::Dumper::Compact;
  
  warn Data::Dumper::Compact->dump($data, \%options);
  
  my $ddc = Data::Dumper::Compact->new(\%options);
  
  warn $ddc->dump($data);
  
  warn $ddc->dump($data, \%extra_options);

=head1 DESCRIPTION

L<Data::Dumper::Compact>, henceforth referred to as DDC, was born because
I was annoyed at valuable wasted whitespace paging through both
L<Data::Dumper> and L<Data::Dump> based logs - L<Data::Dump> attempts to
format horizontally first, but then if it fails, immediately switches to
formatting fully vertically, rather than trying to e.g. format a six element
arrayref three per line.

So here's a few of the specifics (noting that all examples unless otherwise
specified are dumped with default options):

=head2 Arrays and Strings

Given arrays consisting of reasonably long strings, DDC does its best to
produce a sane representation within its L</max_width>:

  [
    1, 2, [
      'longstringislonglongstringislonglongstringislong',
      'longstringislonglongstringislong', 'longstringislong',
      'longstringislonglongstringislonglongstringislong', 'longstringislong',
      'longstringislonglongstringislong', 'longstringislong',
      'longstringislonglongstringislong',
      'longstringislonglongstringislonglongstringislong',
      'longstringislonglongstringislong', 'longstringislonglongstringislong',
      'longstringislonglongstringislonglongstringislong', 'longstringislong',
      'longstringislong', 'longstringislonglongstringislonglongstringislong',
      'longstringislong', 'longstringislong', 'longstringislong',
      'longstringislonglongstringislong',
      'longstringislonglongstringislonglongstringislong', 'a', 'b', 'c',
      'longstringislonglongstringislonglongstringislonglongstringislong',
      'longstringislonglongstringislonglongstringislonglongstringislong',
      'longstringislonglongstringislonglongstringislonglongstringislong',
    ], 3,
  ]

=head2 Keys and Hashrefs

When faced with a C<-foo> style value, it gets a C<< => >> even in an array,
and hash values that we can are single-line formatted:

  [
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', [
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    ],
    -blah => { baz => 'quux', foo => 'bar' },
  ]

=head2 The String Thing

Strings are single quoted when DDC is absolutely sure that's safe, and
double quoted otherwise:

  [ { -foo => {
        bar =>
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        baz => "bbbbbbbbbbbbbbbbbbbb\nbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  } } ]

=head2 Lonely hash key

When a single hash key can't be formatted in a oneline form within the
length, DDC will try spilling it to its own line:

  {
    -xxxxxxxxxxxxx => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  }

If even that isn't enough, it formats it below and indented:

  { -xxxxxxxxxxxxx =>
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  }

=head2 Strings and the dot operator

If a string simply won't fit, DDC splits it and indents it using C<.>:

  [ 'xyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyx'
    .'yxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxy'
    .'xyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyxyx'
    .'yxyxyxyxyxyxyxyxyxyxyxyxyxyxyxy'
  ]

=head2 Unknown unknowns

Anything DDC doesn't understand is passed through its L</dumper> option,
though since L<Data::Dumper> (at the time of writing) forgets to pass through
its indentation level to L<B::Concise>, we slightly tweak that behaviour on
the way in for the default L</dumper>. But the end result looks like:

  { foo => { bar => sub {
        use warnings;
        use strict 'refs';
        my($x, $y) = @_;
        return $x * $y;
  } } }

=head2 Bless you

When encountering an object, if it's a blessed array or hashref, DDC will
attempt to format that too:

  [ bless( {
      x => 3,
      y => [ 'foo', 'bar', 'baz', 'quux', 'fleem', 'blather', 'obrien' ],
      z => 'lololololololololololololololol',
  }, "OhGods::Lol" ) ]

=head2 All together now

The full set of behaviours allows compact (and, we hope, readable) versions
of complex data structures. To provide one of the examples that expired this
module - here is the formatting under standard options for a moderately
complex L<SQL::Abstract> update statement:

  {
    _ => [
      'tree_table', -join => {
        as => 'tree',
        on => { 'tree.id' => 'tree_with_path.id' },
        to => { -select => {
            from => 'tree_with_path',
            select => '*',
            with_recursive => [
              [ 'tree_with_path', 'id', 'parent_id', 'path' ], { -select => {
                  _ => [
                    'id', 'parent_id', { -as =>
                        [
                          { -cast => { -as => [ 'id', 'char', 255 ] } },
                          'path',
                        ]
                    },
                  ],
                  from => 'tree_table',
                  union_all => { -select => {
                      _ => [
                        't.id', 't.parent_id', { -as => [
                            { -concat => [ 'r.path', \"'/'", 't.id' ] },
                            'path',
                        ] },
                      ],
                      from => [
                        'tree_table', -as => 't', -join => {
                          as => 'r',
                          on => { 't.parent_id' => 'r.id' },
                          to => 'tree_with_path',
                        },
                      ],
                  } },
                  where => { parent_id => undef },
              } },
            ],
        } },
      },
    ],
    set => { path => { -ident => [ 'tree', 'path' ] } },
  }

And the version (generated by setting L</max_width> to C<40>) that runs out
of space and thereby forces the "spill vertically" logic to kick in while
still attemping to be at least somewhat compact:

  {
    _ => [
      'tree_table',
      '-join',
      {
        as => 'tree',
        on => {
          'tree.id' => 'tree_with_path.id',
        },
        to => {
          -select => {
            from => 'tree_with_path',
            select => '*',
            with_recursive => [
              [
                'tree_with_path',
                'id',
                'parent_id',
                'path',
              ],
              {
                -select => {
                  _ => [
                    'id',
                    'parent_id',
                    {
                      -as => [
                        {
                          -cast => {
                            -as => [
                              'id',
                              'char',
                              255,
                            ],
                          },
                        },
                        'path',
                      ],
                    },
                  ],
                  from => 'tree_table',
                  union_all => {
                    -select => {
                      _ => [
                        't.id',
                        't.parent_id',
                        {
                          -as => [
                            {
                              -concat => [
                                'r.path',
                                \"'/'",
                                't.id',
                              ],
                            },
                            'path',
                          ],
                        },
                      ],
                      from => [
                        'tree_table',
                        '-as',
                        't',
                        '-join',
                        {
                          as => 'r',
                          on => {
                            't.parent_id' => 'r.id',
                          },
                          to => 'tree_with_path',
                        },
                      ],
                    },
                  },
                  where => {
                    parent_id => undef,
                  },
                },
              },
            ],
          },
        },
      },
    ],
    set => {
      path => {
        -ident => [
          'tree',
          'path',
        ],
      },
    },
  }

=head2 Summary

Hopefully it's clear what the goal is, and what we've done to achieve it.

While the system is already somewhat configurable, further options are almost
certainly implementable, although if you really want such an option then we
expect you to turn up with documentation and test cases for it so we just
have to write the code.

=head1 OPTIONS

=head2 max_width

Represents the width that DDC will attempt to keep as the maximum (if
something overflows it in spite of our best efforts, DDC will fall back to
a more vertically sprawling format to at least overflow as little as
feasible).

Default: C<78>

=head2 indent_by

The string to indent by. To set e.g. 4 space indent, pass C<' 'x4>.

Default: C<'  '> (two spaces).

=head2 indent_width

How many characters one indent should be considered to be. Generally you
only need to manually set this if your L</indent_by> is C<"\t">.

Default: C<< length($self->indent_by) >>

=head2 transforms

Set of transforms to apply on every L</dump> operation. See L</transform>
for more information.

Default: C<[]>

=head2 dumper

The dumper function to be used for dumping things DDC doesn't understand,
such as coderefs, regexprefs, etc.

Defaults to the same options as L<Data::Dumper::Concise> (which is, itself,
only a L<Data::Dumper> configuration albeit it comes with L<Devel::Dwarn>
which is rather more interesting) - although on top of that we add a little
bit of extra cleverness to make L<B::Deparse> use the correct indentation,
since for some reason L<Data::Dumper> doesn't (at the time of writing) do
that.

If you supply it yourself, it needs to be a single argument coderef - you
could for example use C<\&Data::Dumper::Dumper> though that would almost
certainly be pointless.

=head1 EXPORTS

=head2 ddc

  use Data::Dumper::Compact 'ddc';
  use Data::Dumper::Compact 'ddc' => \%options;

If the first argument to C<use>/C<import()> is 'ddc', a subroutine C<ddc()>
is installed in the calling package which behaves like calling L</dump>.

If the second argument is a hashref, it becomes the options passed to L</new>.

This feature is effectively sugar over L</dump_cb>, in that:

  Data::Dumper::Compact->import(ddc => \%options)

is equivalent to:

  *ddc = Data::Dumper::Compact->new(\%options)->dump_cb;

=head1 METHODS

=head2 new

  my $ddc = Data::Dumper::Compact->new;
  my $ddc = Data::Dumper::Compact->new(%options);
  my $ddc = Data::Dumper::Compact->new(\%options);

Constructor. Takes a hash or hashref of L</OPTIONS>

=head2 dump

  my $formatted = Data::Dumper::Compact->dump($data, \%options?);
  
  my $formatted = $ddc->dump($data, \%merge_options?);

This is the method you're going to want to call most of the time, and ties
together the rest of the functionality into a single data-structure-to-string
bundle. With just a data argument, it's equivalent to:

  $ddc->format( $ddc->transform( $ddc->transforms, $ddc->expand($data) );

In class method form, options provided are passed to L</new>; in instance
method form, options if provided are merged into C<$ddc> just for this
invocation.

=head2 dump_cb

  my $cb = $ddc->dump_cb;

Returns a subroutine reference that's a curried call to L</dump>:
  
  $cb->($data, \%extra_options); # equivalent to $ddc->dump(...)

Mostly useful for if you want to create a custom C<ddc()> like thing:

  use Data::Dumper::Compact;
  BEGIN { *Dumper = Data::Dumper::Compact->new->dump_cb }

=head2 expand

  my $exp = $ddc->expand($data);

Expands a data structure to DDC tagged data. The result is, recursively,

  [ $type, $payload ]

where if $type is one of C<string>, C<key>, or C<thing>, the payload is a
simple string (C<thing> meaning something unknown and therefore delegated to
L</dumper>). If the type is an array:

  [ array => \@values ]

and if the type is a hash:

  [ hash => [ \@keys, \%value_map ] ]

where the keys provide an order for formatting, and the value map is a
hashref of keys to expanded values.

A plain string becomes a C<string>, unless it fits the C<-foo> style
pattern that autoquotes, in which case it becomes a C<key>.

=head2 add_transform

  $ddc->add_transform(sub { ... });
  $ddc->add_transform({ hash => sub { ... }, _ => sub { ... });

Appends a transform to C<< $ddc->transforms >>, see L</transform> for
behaviour.

Returns C<$ddc> to enable chaining.

=head2 transform

  my $tf_exp = $ddc->transform($tfspec, $exp);

Takes a transform specification and expanded tagged data and returns the
transformed expanded expression. A transform spec is an arrayref containing
transforms, where each transform is applied in order, so the last transform
added via L</add_transform> will be the last one to transform the data (each
transform will consist of a datastructure representing which parts of the
C<$exp> tree it should be called for, plus subroutines representing the
relevant transforms).

Transform subroutines are called as a method on the C<$ddc> with the
arguments of C<$type, $payload, $path> where C<$path> is an arrayref of the
keys/values of the containing hashes and arrays, aggregated as DDC descends
through the C<$exp> tree.

Each transform is expected to return either nothing, to indicate it doesn't
wish to modify the result, or a replacement expanded data structure. The
simplest form of transform is a subref, which gets called for everything.

So, to add ' IN MICE' to every string that's part of an array under a hash
key called study_results, i.e.:

  my $data = { study_results => [
      'Sense Of Touch Is Formed In the Brain Before Birth'.
      "We can't currently cure MS but a single cell could change that",
  ] };
  
  my $tf_exp = $ddc->transform([ sub {
    my ($self, $type, $payload, $path) = @_;
    return unless $type eq 'string' and ($path->[-2]||'') eq 'study_results';
    return [ $type, $payload.' IN MICE' ];
  } ], $ddc->expand($data));

will return:

  [ hash => [
    [ 'study_results' ],
    { study_results => [ array => [
      [ string => 'Sense Of Touch Is Formed In the Brain Before Birth IN MICE' ],
      [ string => "We can't currently cure MS but a single cell could change that IN MICE", ],
    ] ] }
  ] ]

If a hashref is found, then the values are expected to be transforms, and
DDC will use C<< $hashref->{$type}||$hashref->{_} >> as the transform, or skip
if neither is present. So the previous example could be written as:

  $ddc->transform([ { string => sub {
    my ($self, $type, $payload, $path) = @_;
    return unless ($path->[-2]||'') eq 'study_results';
    return [ $type, $payload.' IN MICE' ];
  } } ], $ddc->expand($data));

If the value of the spec entry itself I<or> the relevant hash value is an
arrayref, it is assumed to contain a spec for trailing path entries, with
the last element being the transform subroutine. A path entry match can be
an exact scalar (tested via C<eq> since it works fine for both strings and
integer array indices), regexp, C<undef> to indicate "any value is fine here",
or a subroutine which will be called with the path entry as both C<$_[0]> and
C<$_>. So the example we've been using could B<also> be written as:

  $ddc->transform([ { string => [
    'study_results', undef,
    sub { [ string => $_[2].' IN MICE' ] }
  ] } ], $ddc->expand($data));

or

  $ddc->transform([ { string => [
    qr/^study_results$/, sub { 1 },
    sub { [ string => $_[2].' IN MICE' ] }
  ] } ], $ddc->expand($data));

Note that while the C<$tfspec> is not passed to transform subroutines,
for the duration of the L</transform> call the L</transforms> option is
localised to the provided routine, so

  sub {
    my ($self, $type, $payload, $path) = @_;
    my $tfspec = $self->transforms;
    ...
  }

will return the top level C<$tfspec> passed to the transform call.

Thanks to L<http://twitter.com/justsaysinmice> for the inspiration.

=head2 format

  my $formatted = $ddc->format($exp);

Takes expanded tagged data and renders it to a formatted string, suitable
for printing or warning or etc.

Accepts the following type tags: C<array>, C<list>,  C<hash>, C<key>,
C<string>, C<thing>. Arrays and hashes are formatted as compactly as possible
within the constraint of L</max_width>, but if overflow occurs then DDC falls
back to spilling everything vertically, so newlines are used for most spacing
and therefore it doesn't exceed the max width any more than strictly
necessary.

Strings are formatted as single quote if obvious, and double quote if not.

Keys are treated as strings when present as hash values, but when an
element of array values, are formatted ask C<< the_key => >> where possible.

Lists are formatted as single line C<qw()> expressions if possible, or
C<( ... )> if not.

Arrays and hashes are formatted in the manner to which one would hope readers
are accustomed, except more compact.

=head1 ALGORITHM

The following is a description of the current algorithm of DDC. We reserve
the right to change it for the better.

If you didn't already read the overview examples in L</WHY> do that first.

Vertical mode means DDC has given up on fitting within the desired width and
is now just trying to not use I<too> much vertical space.

Oneline mode is DDC testing to see if a single line rendering of something
will fit within the available space. Things will often be rendered more than
once since DDC is optimising for compact readable output rather than raw
straight line performance.

=head2 Top level formatting

If something is formatted and the remaining width is zero or negative, DDC
accepts default on L</max_width> and bails out to a fully vertical approach
so it overflows the desired width no more than necessary.

=head2 Array formatting

If already in vertical mode, formats one array element per line, appended
with C<,>:

  [
    1,
    2,
    3
  ]

If in possible oneline mode, formats all but the last element according to
the L</Array element> rules, the last element according to normal formatting,
and joins them with C<' '> in the hopes this is narrow enough. Return this if
oneline is forced or it fits:

  [ 1, 2, 3 ]

If there's only a single internal member, tries to use the
L</Single entry formatting> strategy to cuddle it.

  [ [
    <something inside>
  ] ]

Otherwise, attempts to bundle things as best possible: Each element is
formatted according to the L</Array element> rules, and multiple results
are concatenated together onto a single line where that still remains
within the available width.

  [
    'foo', 'bar', 'baz',
    'red', 'white', 'blue',
  ]

=head2 Array element

Elements are normally formatted as C<< $formatted.',' >> except if an
element is of type C<key> in which cases it becomes C<< $key => >>.

  "whatever the smeg",
  smeg_off =>

=head2 List formatting

The type C<list> is synthetic and only introduced by transforms.

It is formatted identically to an arrayref except with C<( )> instead of
C<[ ]>, with the exception that if it consists of only plain strings and
will fit onto a single line, it formats as a C<qw(x y x)> style list.

  qw(foo bar baz)
  (
    'foo',
    'bar',
    'baz',
  )

=head2 Single entry formatting

Where possible, a single entry will be cuddled such that the opening
delimiters are both on the first line, and the closing delimeters both on
the final line, to reduce the vertical space consumption of nested single
entry array and/or hashrefs.

  to => { -select => {
      ...
  } }

  [ 'SRV:8FB66F32' ], [ [
      '/opt/voice-srvc-native/bin/async-srvc-att-gateway-poller', 33,
      'NERV::Voice::SRV::Native::AsyncSRVATTGatewayPoller::main',
  ] ],

=head2 Hash formatting

If already in vertical mode, key/value pairs are formatted separated by
newlines, with no attention paid to key length.

  {
    foo => ...,
    bar => ...,
  }

If potentially in oneline mode, key/value pairs are formatted separated by
C<', '> and the value is returned if forced or if remaining width allows the
oneline rendering.

  { foo => ..., bar => ... }

Otherwise, all key/value pairs are formatted as C<< key => value >> where
possible, but if the first line of the value is too long, the value is
moved to the next line and indented.

  key => 'shortvalue'
  key =>
    'overlylongvalue'

If there's only a single such key/value pair, tries to use the
L</Single entry formatting> strategy to cuddle it.

  { zathrus => {
      listened_to => 0,
  } }

Otherwise returns key/value pairs indented and separated by newlines

  {
    foo => ...,
    bar => ...,
  }

=head2 String formatting

Uses single quotes if sure that's safe, double quotes otherwise.

  'foo bar baz quux'
  "could have been '' but nicer to not screw up\n the indents with a newline"

Attempts to format a string within the available width, using multiple
lines and the C<.> concatenation operator if necessary,.

  'this would be an'
  .'annoyingly long'
  .'string'

The target width is set to 20 in vertical mode to try and not be too ugly.

=head2 Object formatting

Objects are tested to see if their underlying reference is an array or hash.
If so, it's formatted with 'bless( ' prepended and ', $class)' appended. This
so far appears to interact nicely with everything else.

=head1 AUTHOR

mst - Matt S Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2019 the Data::Dumper::Compact L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
