package Data::Validate::Perl;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

our $VERSION = '0.03';

our @ISA       = qw/Exporter/;
our @EXPORT    = qw/gen_yp_rules/;
our @EXPORT_OK = qw/gen_yp_rules/;

=head1 NAME

Data::Validate::Perl - validates in-memory perl data using a specification

=head1 SYNOPSIS

Continue reading only when you want to generate L<Parse::Yapp> grammar
from the specification file and patch it, or understand how it works
internally, else please look into C<dvp_gen_parser> command-line
utility documentation instead.

    use Data::Validate::Perl qw/gen_yp_rules/;

    my $yapp_grammar = gen_yp_rules($spec_file);

=head1 EXPORTS

=over

=item gen_yp_rules

=back

=head1 SUBROUTINES

=over

=item gen_yp_rules

This function contains the main logic to parse the data specification
and translate it to L<Parse::Yapp> grammar. Returns the grammar string
on success.

=back

=cut


sub gen_yp_rules {
    my ( $spec_file, ) = @_;

    # contains all the rules defined
    my %rule = ();
    # contains all the rules being references in rule body
    my %rule_required = ();
    my $start;
    {
        my %lhs_type = ('%' => 'HASH', '@' => 'ARRAY', '$' => 'SCALAR');
        my %rhs_type = (%lhs_type, '\'' => 'SYMBOL',);
        my $lhs_type_regex = join('|', map { '\\'. $_ } sort keys %lhs_type);
        my $rhs_type_regex = join('|', map { '\\'. $_ } sort keys %rhs_type);
        open my $F, '<', $spec_file or croak "cannot open file to read: $!";
        my %rule_map = ();
        while (<$F>) {
            chomp;
            next if /^\s*#/io;
            my @l = split /\s*\:\s*/io, $_;
            croak "invalid rule line: $_" if @l != 2;
            my ( $k, $v ) = @l;
            croak "invalid rule name: $k" if $k !~ /^($lhs_type_regex)(\w+)$/io;
            # key = name:type
            my $type = $lhs_type{$1};
            my $name = $2;
            my $key = join(':', $name, $type);
            my @v = ();
            foreach my $i (split /\s+/io, $v) {
                if ($i =~ /^($rhs_type_regex)(?:\(((?:\w+|\*))\))?(\w+)$/io) {
                    my $t = $rhs_type{$1};
                    my $k = $2;
                    my $n = $3;
                    croak "left-hand side must be a hash: $name" if $k and $type ne 'HASH';
                    $k = $n if $type eq 'HASH' and !$k;
                    # [ name, type ]
                    push @v, $type eq 'HASH' ? [ $n, $t, $k ] : [ $n, $t ];
                    $rule_required{join(':', $n, $t)} = $t;
                }
                else {
                    croak "invalid rule item: $i";
                }
            }
            croak "duplicate rule declaration: $k" if exists $rule_map{$key};
            $rule{$key} = [ @v ];
            # first declared rule is start
            $start = $key if !defined $start;
            $rule_map{$key}++;
        }
        close $F;
    }
    # create the rules which have been referenced but not declared
    # they are simple arrays or hashes which contains text key/value
    foreach my $k (keys %rule_required) {
        if (!exists $rule{$k}) {
            if ($rule_required{$k} eq 'ARRAY' or $rule_required{$k} eq 'HASH') {
                # simple array or hash
                $rule{$k} = [];
            }
            elsif ($rule_required{$k} eq 'SCALAR') {
                $rule{$k} = [];
            }
        }
    }
    croak "$start rule declaration not found" if !exists $rule{$start};
    # if ($::opt{d}) {
    #     require Data::Dumper;
    #     no warnings 'once';
    #     local $Data::Dumper::Indent = 1;
    #     print STDERR Data::Dumper::Dumper(\%rule), "\n";
    # }

    my $yapp = "%%\n";
    my $count = 0;
    my @stack = ( [ $start, $count++ ], );
    my $cb_process_children = sub {
        my ( $children, ) = @_;

        for (my $i = 0; $i < @$children; $i++) {
            my $child= $children->[$i];
            my $key  = join(':', $child->[0], $child->[1]);
            my $name = $child->[0];
            my $type = $child->[1];
            my $cnt  = $count++;
            if (exists $rule{$key}) {
                if ($type eq 'ARRAY' or $type eq 'HASH') {
                    push @stack, [ $key, $cnt ];
                }
                elsif ($type eq 'SCALAR') {
                    push @stack, [ $key, $cnt ];
                }
                elsif ($type eq 'SYMBOL') {
                    # NOOP: skip
                }
                else {
                    croak "unknown rule type of $name: $type";
                }
            }
            else {
                croak "internal state error, no such rule: $key";
            }
        }
    };
    my $has_list_enum   = 0;
    my $has_scalar_enum = 0;
    my $has_simple_hash = 0;
    my $rule_format = 'rule%04d';
    while (@stack) {
        my $item = shift @stack;
        my $k = $item->[0];
        my $c = $item->[1];

        my ( $name, $type, ) = split /:/io, $k, 2;
        my $children = $rule{$k};
        my $rule = sprintf($rule_format, $c);
        if ($type eq 'HASH') {
            # there shouldn't be any enum (such as 'value) in hash declaration
            croak "invalid hash declaration for $name: scalar item found" if grep { $_->[1] eq 'SYMBOL' } @$children;
            if (@$children == 0) {
                # simple hash
                $has_simple_hash++;
                $yapp .= "$rule: '{' my_begin_simple_hash ${rule}_elements my_end_simple_hash  '}';\n";
                $yapp .= "${rule}_elements: TEXT ${rule}_elements | TEXT;\n";
            }
            else {
                $yapp .= "$rule: '{' ${rule}_elements  '}';\n";
                $yapp .= "${rule}_elements: ${rule}_element ${rule}_elements | ${rule}_element;\n";
                $yapp .= "${rule}_element: ". join(
                    ' | ', map { "'". $children->[$_][2]. "' ". sprintf($rule_format, $count+$_) } 0 .. $#{$children}). ";\n";
                $cb_process_children->($children);
            }
            # NOREACH
        }
        elsif ($type eq 'ARRAY') {
            if (grep { $_->[1] eq 'SYMBOL' } @$children) {
                # enum array, all the children must be enum in this case
                croak "invalid array declaration for $name: non scalar item found" if
                  grep { $_->[1] ne 'SYMBOL' } @$children;
                $has_list_enum++;
                $yapp .= "$rule: '[' my_begin_list_enum ${rule}_items my_end_list_enum ']';\n";
                $yapp .= "${rule}_items: ${rule}_item ${rule}_items | ${rule}_item;\n";
                $yapp .= "${rule}_item: ". join(' | ', map { "'$_'" } map { $_->[0] } @$children). ";\n";
            }
            else {
                $yapp .= "$rule: '[' ${rule}_items ']';\n";
                if (@$children == 0) {
                    # simple array
                    $yapp .= "${rule}_items: TEXT ${rule}_items | TEXT;\n";
                }
                else {
                    $yapp .= "${rule}_items: ${rule}_item ${rule}_items | ${rule}_item;\n";
                    $yapp .= "${rule}_item: ". join(
                        ' | ', map { sprintf($rule_format, $count+$_) } 0 .. $#{$children}). ";\n";
                    $cb_process_children->($children);
                }
            }
        }
        elsif ($type eq 'SCALAR') {
            if (@$children == 0) {
                $yapp .= "${rule}: ;\n";
            }
            else {
                croak "only constant values permitted for scalar rule" if grep { $_->[1] ne 'SYMBOL' } @$children;
                $has_scalar_enum++;
                $yapp .= "${rule}: my_begin_scalar_enum ${rule}_value my_end_scalar_enum;\n";
                $yapp .= "${rule}_value: ". join(' | ', map { "'". $_->[0]. "'" } @$children). ";\n";
            }
        }
        elsif ($type eq 'SYMBOL') {
            # there shouldn't be any symbol item being pushed onto stack
            croak "internal state error: $type item on stack";
        }
        else {
            croak "unknown type of rule $name: $type";
        }
    }
    $yapp .= <<'EOL' if $has_list_enum;
my_begin_list_enum: { $_[0]->YYData->{_flag}->{list_enum} = 1 };
my_end_list_enum:   { $_[0]->YYData->{_flag}->{list_enum} = 0 };
EOL
    $yapp .= <<'EOL' if $has_simple_hash;
my_begin_simple_hash: { $_[0]->YYData->{_flag}->{simple_hash} = 1 };
my_end_simple_hash  : { $_[0]->YYData->{_flag}->{simple_hash} = 0 };
EOL
    $yapp .= <<'EOL' if $has_scalar_enum;
my_begin_scalar_enum: { $_[0]->YYData->{_flag}->{scalar_enum} = 1 };
my_end_scalar_enum  : { $_[0]->YYData->{_flag}->{scalar_enum} = 0 };
EOL
    $yapp .= "%%\n";
    print STDERR $yapp if $::opt{v};
    $yapp .= do { local $/; <DATA> };
    return $yapp;
}

=head1 DESCRIPTION

In order to understand internal of this module, working knowledge of
parsing, especially Yacc is required. Stop and grab a book on topic if
you are unsure what this is.

A common parsing mechanism applies state machine onto a string, such
as regular expression. This part is easy to follow. In this module a
Yacc state machine is used, the target is not plain text but a
in-memory data structure - a tree made up by several perl
scalar/array/hash items.

The process to validate a data structure like that is a tree
traversal. The biggest challenge is how to put these 2 things
together.

The best way to figure a solution is, imagine each step to perform a
depth-first iteration on a tree. Each move can be abstracted as a
'token'. This is the key idea behind.

To elaborate, think how to validate a simple perl hash like below:

   my %hash = (key1 => value1, key2 => value2, key3 => value3);

To iterate the hash key/value pairs, use a cursor to describe the
following states:

   1. initial state: place the cursor onto hash itself;
   2. 1st state: move cursor to key1;
   3. 2nd state: move cursor to value1;
   4. 3rd state: move cursor to key2;
   5. 4th state: move cursor to value2;
   6. 5th state: move cursor to key3;
   7. 6th state: move cursor to value3;

A draft Yacc grammar written as:

   root_of_hash: key1 value1 | key2 value2 | key3 value3

The state machine needs token to decide which sub-rule to walk
into. Looking onto the key1/2/3, the corresponding token can
simply be the value of themselves. That is:

   root_of_hash: 'key1' value1 | 'key2' value2 | 'key3' value3

Note the quotes, they mark key1/2/3 as tokens. Next move to the hash
value. When the cursor points to a value, I do not care about the
actual value, instead I just want to hint the state machine that it is
a value. It requires another token to accept the state. How about a
plain text token - 'TEXT'. Finally the grammar to be:

   root_of_hash: 'key1' 'TEXT' | 'key2' 'TEXT' | 'key3' 'TEXT'

How to apply the generated state machine to the hash validation then?
Each time the parser cannot determine which is next state, it asks the
lexer for a token. The simplest form of a lexer is just a function to
return the corresponding tokens for each state. At this point, you
might be able to guess how it works:

   1. state machine initialized, it wants to move to next state, so it asks lexer;
   2. the lexer holds the hash itself, it calls keys function, returns the first key as token, put the key returned into its memory;
   3. by the time state machine got key1, it moves the cursor onto 'key1', then asks lexer again;
   4. the lexer checks its memory and figures it returned 'key1' just now, time to return its vlaue, as the state machine has no interest on the actual value, it returns 'TEXT';
   5. state machine finished the iteration of key1/value1 pair, asks for another token;
   6. lexer returns 'key2' and keeps it in its own memory;
   7. state machine steps into the sub-rule 'key2' 'TEXT';
   ...

The state loop is fairly straightforward. Parsing isn't that
difficult, huh :-)

To iterate a nested tree full of scalar/array/hash, other tokens are
introduced:

   1. '[' ']' indicates start/end state of array traversal;
   2. '{' '}' indicates start/end state of hash traversal;
   3. to meet special need, certain rule actions are defined to set some state flags, which influence the decision that the lexer returns the value as 'TEXT', or the actual value string itself;

The state maintenance in lexer is made up by a stack, the stack
simulates a depth-first traversal:

   1. when meets array, iterates array items one by one, if any item is another array or hash, push current array onto the stack together with an index marking where we are in this array. Iterates that item recursively;
   2. similar strategy is applied to hash;

The left piece is a DSL to describe the tree structure. By the time
you read here, I am fairly confident you are able to figure it out
yourself by exercising various pieces of this module, below is a small
leaf-note:

   1. gen_yp_rules function handles translation from data structure spec to corresponding Yacc grammar;
   2. bottom section of this module contains the Lexer function and other routines L<Parse::Yapp> requires to work (browse the module source to read);
   3. the command-line utility C<dvp_gen_parser> reads the spec file, calls gen_yp_rules to generate grammar, fits it into a file and calls C<yapp> to create the parser module;

Wish you like this little article and enjoy playing with this module.

=head1 SEE ALSO

   * L<Parse::Yapp>

=head1 AUTHOR

Dongxu Ma, C<< <dongxu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-validate-perl
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-Perl>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::Perl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validate-Perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Validate-Perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Validate-Perl>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Validate-Perl/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Dongxu Ma.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Data::Validate::Perl

__DATA__
sub Lexer {
    my ( $parser, ) = @_;

    my $stash = $parser->YYData;
    return('', undef) if @{$stash->{stack}} == 0;
    # item = [ array_or_hash_ref, next_item_index ]
    my $item = $stash->{stack}->[-1];
    if (ref($item->[0]) eq 'ARRAY') {
        if ($item->[1] == -1) {
            $item->[1]++;
            return('[', undef);
        }
        elsif ($item->[1] == @{$item->[0]}) {
            pop @{$stash->{stack}};
            return(']', undef);
        }
        else {
            my $v = $item->[0]->[$item->[1]++];
            if (ref($v) eq 'ARRAY') {
                push @{$stash->{stack}}, [ $v, 0 ];
                return('[', undef);
            }
            elsif (ref($v) eq 'HASH') {
                push @{$stash->{stack}}, [ $v, 0 ];
                return('{', undef);
            }
            elsif (!ref($v)) {
                if ($stash->{_flag}->{list_enum}) {
                    return($v, undef);
                }
                elsif ($stash->{_flag}->{scalar_enum}) {
                    return($v, undef);
                }
                else {
                    return('TEXT', undef);
                }
            }
            else {
                $parser->YYError;
                return;
            }
            # NOREACH
        }
    }
    elsif (ref($item->[0]) eq 'HASH') {
        # HACK: rollback index if in scalar_enum context
        $item->[1]-- if $stash->{_flag}->{scalar_enum};
        if ($item->[1] == -1) {
            $item->[1]++;
            return('{', undef);
        }
        elsif ($item->[1] == keys %{$item->[0]}) {
            pop @{$stash->{stack}};
            return('}', undef);
        }
        else {
            # ASSUMPTION: hash itself never changes
            # sort is important
            my @k = sort keys %{$item->[0]};
            my $k = $k[$item->[1]++];
            my $v = $item->[0]->{$k};
            if (ref($v) eq 'ARRAY') {
                push @{$stash->{stack}}, [ $v, -1 ];
                return($k, undef);
            }
            elsif (ref($v) eq 'HASH') {
                push @{$stash->{stack}}, [ $v, -1 ];
                return($k, undef);
            }
            elsif (!ref($v)) {
                if ($stash->{_flag}->{simple_hash}) {
                    return('TEXT', undef);
                }
                elsif ($stash->{_flag}->{scalar_enum}) {
                    return($v, undef);
                }
                else {
                    return($k, undef);
                }
            }
            else {
                $parser->YYError;
                return;
            }
            # NOREACH
        }
    }
    $parser->YYError;
}

sub Error {
    my ( $parser, ) = @_;

    my $stash = $parser->YYData;
    if (exists $stash->{ERRMSG}) {
        print STDERR $stash->{ERRMSG}, "\n";
        delete $stash->{ERRMSG};
        return;
    }
    print STDERR "Syntax error\n";
}

sub parse {
    my ( $self, $data, ) = @_;

    my $stash = $self->YYData;
    $stash->{stack} = [];
    push @{$stash->{stack}}, [ $data, -1 ];
    $self->YYParse(
        yylex   => \&Lexer,
        yyerror => \&Error,
        yydebug => $ENV{YYDEBUG}, # 0x1f
    );
}
