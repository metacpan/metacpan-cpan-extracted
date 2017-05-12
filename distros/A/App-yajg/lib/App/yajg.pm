package App::yajg;

use 5.014000;
use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use utf8;

use Data::Dumper;
use JSON qw();

our $VERSION = '0.20';

sub MAX_RECURSION () {300}

{
    my $inc = caller() ? $INC{ __PACKAGE__ =~ s/::/\//r . '.pm' } : undef;
    my $at = join '|' => "\Q$0\E", '\(eval [0-9]++\)', '-[eE]', $inc ? "\Q$inc\E" : ();
    my $re = qr/at (?:$at) line [0-9]++(?:\.|, <> (?:chunk|line) [0-9]++\.)/;
    sub remove_at_line ($) { (shift // '') =~ s/$re//r }
}

sub warn_without_line { warn remove_at_line shift }
sub die_without_line  { die remove_at_line shift }

sub size ($) {
    ref $_[0] eq 'ARRAY' and @{ $_[0] } or ref $_[0] eq 'HASH' and %{ $_[0] }
}

sub values_ref ($) {
    ref $_[0] eq 'ARRAY'    ? @{ $_[0] }
      : ref $_[0] eq 'HASH' ? (values %{ $_[0] })
      : wantarray           ? ()
      : 0
}

sub read_next_json_file () {
    local $/;
    local $SIG{__WARN__} = \&warn_without_line;
    while (<>) {
        utf8::encode($_) if utf8::is_utf8($_);
        $_ = eval { JSON::decode_json($_) };
        warn "Failed to parse $ARGV: $@" if $@;
        next unless ref $_;
        return $_;
    }
    return;
}

sub parse_select ($;$) {
    my $select = shift // return;
    my $args   = shift // {};
    my @select_path;
    # split by '.' exept '\.'
    for (split /(?<!\\)\.+/ => $select) {
        # now we can do unescape '\.'
        s/\\\././g;
        my $type = '';
        # {....}
        if (s/^\{(.*)\}$/$1/) {
            $type = 'HASH';
            if ($args->{'ignore_case'}) {
                $type = 'HASH_IC';
                $_    = lc($_);
            }
        }
        # [....]
        elsif (s/^\[(.*)\]$/$1/) {
            $type = 'SLICE';
            s/^\s*|\s*$//g;
            # '2, 3, -2' -> [2, 3, 4]
            my $list = [];
            my $err;
            for (split ',') {
                s/^\s*|\s*$//g;
                next unless length $_;
                unless (m/^[+-]?[0-9]++$/) {
                    warn "Failed to parse select: '$_' not a number\n";
                    $err = 1;
                    next;
                }
                push @$list, int($_);
            }
            die "Failed to parse select: '$_' not a number or list of numbers\n"
              if $err or not @$list;
            $_ = $list;
        }
        # /..../
        elsif (s/^\/(.*)\/$/$1/) {
            $type = 'REGEXP';
            local $SIG{__DIE__} = \&die_without_line;
            my $pat = $_;
            $pat = '(?i)' . $pat if $args->{'ignore_case'};
            eval { $_ = qr/$pat/ } or die "Failed to parse select: $@";
        }
        else {
            $type = 'UNKNOWN';
            no warnings 'uninitialized';
            s/^\\(\/)|\\(\/)$/$1$2/g;    # \/...\/ -> /.../
            s/^\\(\{)|\\(\})$/$1$2/g;    # \{...\} -> {...}
            s/^\\(\[)|\\(\])$/$1$2/g;    # \[...\] -> [...]
            if ($args->{'ignore_case'}) {
                $type = 'UNKNOWN_IC';
                $_    = lc($_);
            }
        }
        push @select_path, {
            type => $type,
            val  => $_,
        };
    }
    return @select_path;
}

sub select_by_path {
    my $data = shift;

    # no path
    return $data unless @_;
    # we can select only at ARRAY or HASH
    return undef unless ref $data ~~ [qw/HASH ARRAY/];

    my $current = shift;
    my $type    = $current->{'type'};
    my $val     = $current->{'val'};
    if (ref $data eq 'HASH') {
        given ($type) {
            when ([qw/HASH UNKNOWN/]) {
                return undef unless exists $data->{$val};
                my $selected = select_by_path($data->{$val}, @_);
                return undef if @_ and not defined $selected;
                return { $val => $selected };
            }
            when ([qw/HASH_IC UNKNOWN_IC/]) {
                my %selected = ();
                for (grep { lc($_) eq $val } keys %$data) {
                    my $selected = select_by_path($data->{$_}, @_);
                    next if @_ and not defined $selected;
                    $selected{$_} = $selected;
                }
                return %selected ? \%selected : undef;
            }
            when ('REGEXP') {
                my %selected = ();
                for (grep {m/$val/} keys %$data) {
                    my $selected = select_by_path($data->{$_}, @_);
                    next if @_ and not defined $selected;
                    $selected{$_} = $selected;
                }
                return %selected ? \%selected : undef;
            }
            default { return undef }
        }
    }
    elsif (ref $data eq 'ARRAY') {
        given ($type) {
            when ('SLICE') {
                my @slice = @$data[@$val];
                return undef unless @slice;
                my @selected;
                for (@slice) {
                    my $selected = select_by_path($_, @_);
                    next if @_ and not defined $selected;
                    push @selected, $selected;
                }
                return @selected ? \@selected : undef;
            }
            when ('REGEXP') {
                my @selected;
                for (grep {m/$val/} keys @$data) {
                    my $selected = select_by_path($data->[$_], @_);
                    next if @_ and not defined $selected;
                    push @selected, $selected;
                }
                return @selected ? \@selected : undef;
            }
            when ([qw/UNKNOWN UNKNOWN_IC/]) {
                return undef unless $val =~ m/^[+-]?[0-9]++$/;
                return undef unless exists $data->[$val];
                my $selected = select_by_path($data->[$val], @_);
                return undef if @_ and not defined $selected;
                return [$selected];
            }
            default { return undef }
        }
    }
    return undef;
}

sub filter {
    my ($data, $key_pat, $val_pat, $i, $visited, $r) = @_;

    # Nothing to filter if we have no filter patterns
    return $data unless defined $key_pat or defined $val_pat;

    # $i - invert match flag

    # Deep recursion protection
    $r //= 0;
    if (++$r > MAX_RECURSION) {
        warn "Too deep filtering\n";
        return $data;
    }

    # for $val_pat we do grep at array or hash loops
    return $data unless ref $data ~~ [qw/ARRAY HASH/];

    # If we have been already visited this ref
    $visited //= {};
    return $visited->{$data} if $visited->{$data};

    my $ret;

    if (ref $data eq 'HASH') {
        $ret = {};
        for (keys %$data) {
            if (
                # only key_pat
                (defined $key_pat and not defined $val_pat and m/$key_pat/)
                # otherwise data must be defined scalar
                or (not ref $data->{$_} and defined $data->{$_}
                    and (not defined $key_pat or m/$key_pat/)
                    and (not defined $val_pat or ($data->{$_} =~ m/$val_pat/ xor $i))
                )
                # if invert match and we have $val_pat we need to allow
                # empty arrays, empty hashes, undef values and other refes
                or ($i and defined $val_pat
                    and (not defined $data->{$_}
                        or ref $data->{$_} and not size($data->{$_})
                    )
                )
              ) {
                $ret->{$_} = $data->{$_};
            }
            elsif (ref $data->{$_} ~~ [qw/ARRAY HASH/]) {
                my $filtered = filter($data->{$_}, $key_pat, $val_pat, $i, $visited, $r);
                $ret->{$_} = $filtered if size($filtered);
            }
            else {
                next;
            }
        }
    }
    elsif (ref $data eq 'ARRAY') {
        $ret = [];
        for (@$data) {
            if (ref $_ ~~ [qw/HASH ARRAY/]) {
                my $filtered = filter($_, $key_pat, $val_pat, $i, $visited, $r);
                push @$ret, $filtered if size($filtered);
            }
            elsif (defined $val_pat
                and (defined $_ and not ref $_ and (m/$val_pat/ xor $i)
                    # if invert match and we have $val_pat we need to allow
                    # empty arrays, empty hashes, undef values and other refes
                    or ($i and (not defined $_ or ref $_ and not size($_)))
                )
              ) {
                push @$ret, $_;
            }
        }
    }

    return $visited->{$data} = $ret;
}

sub modify_data {
    return if @_ == 1;

    my $r       = 0;
    my $visited = {};
    if (@_ > 2) {
        $r       = pop;
        $visited = pop;
    }
    my $hooks = pop;
    return unless size $hooks;

    if (++$r > MAX_RECURSION) {
        warn "Too deep modification\n";
        return;
    }

    if (ref $_[0] eq 'HASH') {
        return if $visited->{ $_[0] };
        modify_data($_, $hooks, $visited, $r) for values %{ $_[0] };
        $visited->{ $_[0] } = 1;
    }
    elsif (ref $_[0] eq 'ARRAY') {
        return if $visited->{ $_[0] };
        modify_data($_, $hooks, $visited, $r) for @{ $_[0] };
        $visited->{ $_[0] } = 1;
    }
    else {
        $_->($_[0]) for @$hooks;
    }
}

sub output ($) {
    my $output = shift;
    state $supported = {
        'ddp'  => 'App::yajg::Output::DDP',
        'json' => 'App::yajg::Output::Json',
        'perl' => 'App::yajg::Output::Perl',
        'yaml' => 'App::yajg::Output::Yaml',
    };
    die 'Output must be one of ' . join(', ' => map {"'$_'"} sort keys %$supported) . "\n"
      unless $supported->{$output};

    eval "require $supported->{$output}";
    die "Can't init output $output: $@" if $@;

    return $supported->{$output}->new;
}

1;

__END__

=pod

=head1 NAME

App::yajg - yet another json grep

=head1 SYNOPSIS

B<yajg> [B<-cEhimquvz>]
[B<-p> F<key_pattern>] [B<-P> F<value_pattern>] [B<-s> F<select_path>] [B<-S> F<select_path>]
[B<-o> F<output_format>] [B<-b> F<boolean_type>] [B<-d> F<depth>] [B<--sort-keys>]
[B<-e> F<code>]
[F<files>]

=head1 DESCRIPTION

Simple grep and pretty output for json in each files or standard input.

=head1 OPTIONS

=head2 Grep control

=over 4

=item B<-p, --key-pattern>

Perl regexp pattern for matching hash keys.

=item B<-P, --value-pattern>

Perl regexp pattern for matching array or hash values.

B<WARNING> can change number type to string.

=item B<-z, --substring>

Interpret pattern given in the L</-p, --key-pattern> or the L</-P,
--value-pattern> options as the substring (calls perl C<quotemeta> for
pattern).

=item B<-s, --select>

Select the element at the structure for grep by the given path. For example:

 yajg -s {rows}.[0,1,2]./id|title/

If there are no L</-p, --key-pattern> or L</-P, --value-pattern> options
provided, the B<yajg> will dump the full structure by the path. The path must
be dot-separated (C<.>) string which can contains the following elements:

=over 4

=item B<{HASH KEY}>

If the element of the path in braces (C<{...}>) will try to select by key. Only
supported by hash types.

=item B<[SLICE]>

If the element of the path in brackets (C<[...]>) will try to select the
element by array slice (C<@{$data}[ elements ]>). The element must be an
integer value or comma-separated list of integer values.

=item B</REGEXP/>

If the element of the path between C</> (C</.../>) will try to select elements
by keys/indexes that matches given regexp. For example C</\d+/> will match the
hole array or hash keys that are positive integer numbers.

=item B<UNKNOWN>

If the element has no special symbols at the begin and end will try to select
elements by key or index (depends on data)

=back

If you want to path dot as the element symbol - you must escape it with C<\>.
For example: {data\.s}./^rt\.*/ means to select element by key C<data.s> and
then all elements which keys matches regexp C<m/^rt.*/>

=item B<-S, --select-tiny>

Same as the L</-s, --select> but will try to tiny output: will go throw the
data and while data is array or hash with one element this element will be
data. For example:

 $ echo '[{"1":1},{"2":2},{"3":3}]' | yajg -S '1'
 {"2":2}

 $ echo '[{"1":1},{"2":2},{"3":3}]' | yajg -S -s '1'
 {"2":2}

=item B<-i, --ignore-case>

Ignore case distinctions in the L</-p, --key-pattern>, the L</-P,
--value-pattern> and L</-s, --select> options.

=item B<-v, --invert-match>

Invert the sense of matching for the L</-P, --value-pattern> option.

=back

=head2 Output control

=over 4

=item B<-o, --output>

Select the output type. Supported types are:

=over 2

=item * json (via L<JSON>)

=item * perl (via L<Data::Dumper>)

=item * ddp (via L<Data::Printer>)

=item * yaml (via L<YAML>)

=back

If the L<Data::Printer> installed than the default value will be ddp otherwise
json.

=item B<-b, --boolean>

Convert boolean types to defined format:

=over 4

=item * ref, 1 - ref to scalar C<\0>, C<\1>

=item * int, 2 - integer C<0>, C<1>

=item * str, 3 - string C<'false'>, C<'true'>

=back

Maby usefull because by default all C<true> is ref to
C<Types::Serialiser::true> and all C<false> is ref to
C<Types::Serialiser::false> and the output in some formats can be hard to read

=item B<-c, --color, --no-color>

Enable/disable colorized output. For B<json> and B<perl> output types you need
to install the L<highlight|http://www.andre-simon.de/> program.

=item B<--filename, --no-filename>

Print or hide filenames. By default print filenames if there are more than one
files.

=item B<-d, --max-depth>

How deep to traverse the data (0 for all)

B<WARNING> when the json booleans has same level as the --max-depth then they
will be converted to string C<0>, C<1> or C<true>, C<false> (depends on JSON
version)

B<WARNING> can change number type to string.

=item B<-m, --minimal>

Minimize output. Does not supported by the B<yaml> output.

=item B<--sort-keys, --no-sort-keys>

Enable/disable sorting hash keys. By default enabled when the L</-m, --minimal>
option is disabled.

=item B<-E, --escapes, --no-escapes>

Print non-printable chars as "\n", "\t", etc. By default enabled when the
L</-m, --minimal> option is enabled. For B<json> output always enabled (JSON
format requires to escape this chars)

=item B<-q, --quiet>

Quiet; do not write anything to standard output.

=item B<-u, --url-parse>

Try to parse urls. Will be called after selection and filtering.

B<WARNING> can change number type to string.

=back

=head2 Miscellaneous

=over 4

=item B<-e, --exec>

Evaluate perl code on every item wich is niether hash nor array ref. Will be
called after selection and filtering. The item data that has been written is in
C<$_> and whatever is in there is written out afterwards.

=item B<-h, --help>

Display short help message

=back

=head1 EXIT STATUS

Normally the exit status is 0 if the any structure has size, 1 if no structures
has size, and 2 if an error occurred.

=head1 EXAMPLES

F<exaple.json>

 {
    "array" : [
       {
          "data" : {
             "a" : 1,
             "b" : 2
          },
          "id" : "test"
       },
       {
          "data" : {
             "a" : 100,
             "b" : 200
          },
          "id" : "test_2"
       }
    ],
    "hash" : {
       "numbers" : {
          "one" : 1,
          "three" : 3
       },
       "words" : [
          "cat",
          "dog",
          "bird"
       ]
    }
 }

=head2 Key grep and different output format

 $ yajg -p id exaple.json
 {
    "array" : [
       {
          "id" : "test"
       },
       {
          "id" : "test_2"
       }
    ]
 }

 $ yajg -p id -o perl exaple.json
 {
   'array' => [
     {
       'id' => 'test'
     },
     {
       'id' => 'test_2'
     }
   ]
 }

 $ yajg -p id -o ddp exaple.json
 \ {
     array   [
         [0] {
             id   "test"
         },
         [1] {
             id   "test_2"
         }
     ]
 }

 $ yajg -p id -o yaml exaple.json
 ---
 array:
   - id: test
   - id: test_2

=head2 Value grep

 yajg -P '^1$' exaple.json
 {
    "array" : [
       {
          "data" : {
             "a" : "1"
          }
       }
    ],
    "hash" : {
       "numbers" : {
          "one" : "1"
       }
    }
 }

 $ yajg -P 2 -p id exaple.json
 {
    "array" : [
       {
          "id" : "test_2"
       }
    ]
 }

 $ yajg -P 'cat|dog' exaple.json
 {
    "hash" : {
       "words" : [
          "cat",
          "dog"
       ]
    }
 }

=head2 Select option

Simple selection:

 $ yajg -s hash.words.0 exaple.json
 {
    "hash" : {
       "words" : [
          "cat"
       ]
    }
 }

C<words> not a hash:

 $ yajg -s {hash}.{words}.{0} exaple.json
 {}

Last element of C<words>:

 $ yajg -s hash.words.[-1] exaple.json
 {
    "hash" : {
       "words" : [
          "bird"
       ]
    }
 }

First and third element of C<words>:

 $ yajg -s hash.words.[0,2] exaple.json
 {
    "hash" : {
       "words" : [
          "cat",
          "bird"
       ]
    }
 }

Slice on hash will be empty:

 $ yajg -s hash.[0] exaple.json
 {}

Regexp example:

 $ yajg -s 'array./\d+/.id' exaple.json
 {
    "array" : [
       {
          "id" : "test"
       },
       {
          "id" : "test_2"
       }
    ]
 }

 $ yajg -s '/\.*/.numbers./^o/' exaple.json
 {
    "hash" : {
       "numbers" : {
          "one" : 1
       }
    }
 }

=head2 Select with grep

 $ yajg -s 'array.0' -P 1 exaple.json
 {
    "array" : [
       {
          "data" : {
             "a" : "1"
          }
       }
    ]
 }

=head2 Max depth

 $ yajg -d 2 -o json exaple.json
 {
    "array" : [
       "HASH(0x1d239b8)",
       "HASH(0x1ddb958)"
    ],
    "hash" : {
       "numbers" : "HASH(0x1ef51a0)",
       "words" : "ARRAY(0x1ef5218)"
    }
 }

 $ yajg -d 2 -o perl exaple.json
 {
   'array' => [
     'HASH(0xf87dc0)',
     'HASH(0xf87b38)'
   ],
   'hash' => {
     'numbers' => 'HASH(0xf87d78)',
     'words' => 'ARRAY(0x7a93d0)'
   }
 }

 $ yajg -d 2 -o ddp exaple.json
 \ {
     array   [
         [0] { ... },
         [1] { ... }
     ],
     hash    {
         numbers   { ... },
         words     [ ... ]
     }
 }

=head2 exec

 $ echo '[1,2,3]' | yajg -e '$_+=1' -m
 [2,3,4]

 $ echo '{"a":1,"b":2}' | yajg -e '$_+=1' -e '$_*=2'
 {
    "a" : 4,
    "b" : 6
 }

=head1 SEE ALSO

=over 4

=item L<JSON>

=item L<Data::Dumper>

=item L<Data::Printer>

=item L<YAML>

=item L<highlight(1)>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Grigoriy Koudrenko C<< <gragory.mail@gmail.com> >>.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

The full text of the license can be found in the LICENSE file included with
this program.

=cut
