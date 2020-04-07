package Data::Clean;

our $DATE = '2020-04-07'; # DATE
our $VERSION = '0.507'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

sub new {
    my ($class, %opts) = @_;
    my $self = bless {_opts=>\%opts}, $class;
    log_trace("Cleanser options: %s", \%opts);

    my $cd = $self->_generate_cleanser_code;
    for my $mod (keys %{ $cd->{modules} }) {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
    }
    $self->{_cd} = $cd;
    $self->{_code} = eval $cd->{src};
    {
        last unless $cd->{clone_func} =~ /(.+)::(.+)/;
        (my $mod_pm = "$1.pm") =~ s!::!/!g;
        require $mod_pm;
    }
    die "Can't generate code: $@" if $@;

    $self;
}

sub command_call_method {
    my ($self, $cd, $args) = @_;
    my $mn = $args->[0];
    die "Invalid method name syntax" unless $mn =~ /\A\w+\z/;
    return "{{var}} = {{var}}->$mn; \$ref = ref({{var}})";
}

sub command_call_func {
    my ($self, $cd, $args) = @_;
    my $fn = $args->[0];
    die "Invalid func name syntax" unless $fn =~ /\A\w+(::\w+)*\z/;
    return "{{var}} = $fn({{var}}); \$ref = ref({{var}})";
}

sub command_one_or_zero {
    my ($self, $cd, $args) = @_;
    return "{{var}} = {{var}} ? 1:0; \$ref = ''";
}

sub command_deref_scalar_one_or_zero {
    my ($self, $cd, $args) = @_;
    return "{{var}} = \${ {{var}} } ? 1:0; \$ref = ''";
}

sub command_deref_scalar {
    my ($self, $cd, $args) = @_;
    return '{{var}} = ${ {{var}} }; $ref = ref({{var}})';
}

sub command_stringify {
    my ($self, $cd, $args) = @_;
    return '{{var}} = "{{var}}"; $ref = ""';
}

sub command_replace_with_ref {
    my ($self, $cd, $args) = @_;
    return '{{var}} = $ref; $ref = ""';
}

sub command_replace_with_str {
    require String::PerlQuote;

    my ($self, $cd, $args) = @_;
    return "{{var}} = ".String::PerlQuote::double_quote($args->[0]).'; $ref=""';
}

sub command_unbless {
    my ($self, $cd, $args) = @_;

    return join(
        "",
        'my $reftype = Scalar::Util::reftype({{var}}); ',
        '{{var}} = $reftype eq "HASH" ? {%{ {{var}} }} :',
        ' $reftype eq "ARRAY" ? [@{ {{var}} }] :',
        ' $reftype eq "SCALAR" ? \(my $copy = ${ {{var}} }) :',
        ' $reftype eq "CODE" ? sub { goto &{ {{var}} } } :',
        '(die "Cannot unbless object with type $ref")',
    );
}

sub command_clone {
    my ($self, $cd, $args) = @_;

    my $limit = $args->[0] // 1;
    return join(
        "",
        "if (++\$ctr_circ <= $limit) { ",
        "{{var}} = $cd->{clone_func}({{var}}); redo ",
        "} else { ",
        "{{var}} = 'CIRCULAR'; \$ref = '' }",
    );
}

sub command_unbless_ffc_inlined {
    my ($self, $cd, $args) = @_;

    # code taken from Function::Fallback::CoreOrPP 0.07
    $cd->{subs}{unbless} //= <<'EOC';
    my $ref = shift;

    my $r = ref($ref);
    # not a reference
    return $ref unless $r;

    # return if not a blessed ref
    my ($r2, $r3) = "$ref" =~ /(.+)=(.+?)\(/
        or return $ref;

    if ($r3 eq 'HASH') {
        return { %$ref };
    } elsif ($r3 eq 'ARRAY') {
        return [ @$ref ];
    } elsif ($r3 eq 'SCALAR') {
        return \( my $copy = ${$ref} );
    } else {
        die "Can't handle $ref";
    }
EOC

    "{{var}} = \$sub_unbless->({{var}}); \$ref = ref({{var}})";
}

# test
sub command_die {
    my ($self, $cd, $args) = @_;
    return "die";
}

sub _generate_cleanser_code {
    my $self = shift;
    my $opts = $self->{_opts};

    # compilation data, a structure that will be passed around between routines
    # during the generation of cleanser code.
    my $cd = {
        modules => {}, # key = module name, val = version
        clone_func   => $self->{_opts}{'!clone_func'},
        code => '',
        subs => {},
    };

    $cd->{modules}{'Scalar::Util'} //= 0;
    $cd->{modules}{'Data::Dmp'} //= 0 if $opts->{'!debug'};

    if (!$cd->{clone_func}) {
        $cd->{clone_func} = 'Clone::PP::clone';
    }
    {
        last unless $cd->{clone_func} =~ /(.+)::(.+)/;
        $cd->{modules}{$1} //= 0;
    }

    my (@code, @stmts_ary, @stmts_hash, @stmts_main);

    my $n = 0;
    my $add_stmt = sub {
        my $which = shift;
        if ($which eq 'if' || $which eq 'new_if') {
            my ($cond0, $act0) = @_;
            for ([\@stmts_ary, '$e', 'ary'],
                 [\@stmts_hash, '$h->{$k}', 'hash'],
                 [\@stmts_main, '$_', 'main']) {
                my $act  = $act0 ; $act  =~ s/\Q{{var}}\E/$_->[1]/g;
                my $cond = $cond0; $cond =~ s/\Q{{var}}\E/$_->[1]/g;
                if ($opts->{'!debug'}) { unless (@{ $_->[0] }) { push @{ $_->[0] }, '    print "DEBUG:'.$_->[2].' cleaner: val=", Data::Dmp::dmp_ellipsis('.$_->[1].'), ", ref=$ref\n"; '."\n" } }
                push @{ $_->[0] }, "    ".($n && $which ne 'new_if' ? "els":"")."if ($cond) { $act }\n";
            }
            $n++;
        } else {
            my ($stmt0) = @_;
            for ([\@stmts_ary, '$e', 'ary'],
                 [\@stmts_hash, '$h->{$k}', 'hash'],
                 [\@stmts_main, '$_', 'main']) {
                my $stmt = $stmt0; $stmt =~ s/\Q{{var}}\E/$_->[1]/g;
                push @{ $_->[0] }, "    $stmt;\n";
            }
        }
    };
    my $add_if = sub {
        $add_stmt->('if', @_);
    };
    my $add_new_if = sub {
        $add_stmt->('new_if', @_);
    };
    my $add_if_ref = sub {
        my ($ref, $act0) = @_;
        $add_if->("\$ref eq '$ref'", $act0);
    };
    my $add_new_if_ref = sub {
        my ($ref, $act0) = @_;
        $add_new_if->("\$ref eq '$ref'", $act0);
    };

    # catch circular references
    my $circ = $opts->{-circular};
    if ($circ) {
        my $meth = "command_$circ->[0]";
        die "Can't handle command $circ->[0] for option '-circular'" unless $self->can($meth);
        my @args = @$circ; shift @args;
        my $act = $self->$meth($cd, \@args);
        if ($opts->{'!debug'}) { $add_stmt->('stmt', 'print "DEBUG: main cleaner: ref=$ref, " . {{var}} . "\n"'); }
        $add_new_if->('$ref && $refs{ {{var}} }++', $act);
    }

    # catch object of specified classes (e.g. DateTime, etc)
    for my $on (grep {/\A\w*(::\w+)*\z/} sort keys %$opts) {
        my $o = $opts->{$on};
        next unless $o;
        my $meth = "command_$o->[0]";
        die "Can't handle command $o->[0] for option '$on'" unless $self->can($meth);
        my @args = @$o; shift @args;
        my $act = $self->$meth($cd, \@args);
        $add_if_ref->($on, $act);
    }

    # catch general object not caught by previous
    for my $p ([-obj => 'Scalar::Util::blessed({{var}})']) {
        my $o = $opts->{$p->[0]};
        next unless $o;
        my $meth = "command_$o->[0]";
        die "Can't handle command $o->[0] for option '$p->[0]'" unless $self->can($meth);
        my @args = @$o; shift @args;
        $add_if->($p->[1], $self->$meth($cd, \@args));
    }

    # recurse array and hash
    if ($opts->{'!recurse_obj'}) {
        $add_stmt->('stmt', 'my $reftype=Scalar::Util::reftype({{var}})//""');
        $add_new_if->('$reftype eq "ARRAY"', '$process_array->({{var}})');
        $add_if->('$reftype eq "HASH"' , '$process_hash->({{var}})');
    } else {
        $add_new_if_ref->("ARRAY", '$process_array->({{var}})');
        $add_if_ref->("HASH" , '$process_hash->({{var}})');
    }

    # lastly, catch any reference left
    for my $p ([-ref => '$ref']) {
        my $o = $opts->{$p->[0]};
        next unless $o;
        my $meth = "command_$o->[0]";
        die "Can't handle command $o->[0] for option '$p->[0]'" unless $self->can($meth);
        my @args = @$o; shift @args;
        $add_if->($p->[1], $self->$meth($cd, \@args));
    }

    push @code, 'sub {'."\n";

    for (sort keys %{$cd->{subs}}) {
        push @code, "state \$sub_$_ = sub { ".$cd->{subs}{$_}." };\n";
    }

    push @code, 'my $data = shift;'."\n";
    push @code, 'state %refs;'."\n" if $circ;
    push @code, 'state $ctr_circ;'."\n" if $circ;
    push @code, 'state $process_array;'."\n";
    push @code, 'state $process_hash;'."\n";
    push @code, (
        'if (!$process_array) { $process_array = sub { my $a = shift; for my $e (@$a) { ',
        'my $ref=ref($e);'."\n",
        join("", @stmts_ary).'} } }'."\n"
    );
    push @code, (
        'if (!$process_hash) { $process_hash = sub { my $h = shift; for my $k (keys %$h) { ',
        'my $ref=ref($h->{$k});'."\n",
        join("", @stmts_hash).'} } }'."\n"
    );
    push @code, '%refs = (); $ctr_circ=0;'."\n" if $circ;
    push @code, (
        'for ($data) { ',
        'my $ref=ref($_);'."\n",
        join("", @stmts_main).'}'."\n"
    );
    push @code, 'print "DEBUG: main cleaner: result: ", Data::Dmp::dmp_ellipsis($data), "\n";'."\n" if $opts->{'!debug'};
    push @code, '$data'."\n";
    push @code, '}'."\n";

    my $code = join("", @code).";";

    if ($ENV{LOG_CLEANSER_CODE} && log_is_trace()) {
        require String::LineNumber;
        log_trace("Cleanser code:\n%s",
                     $ENV{LINENUM} // 1 ?
                         String::LineNumber::linenum($code) : $code);
    }

    $cd->{src} = $code;

    $cd;
}

sub clean_in_place {
    my ($self, $data) = @_;

    $self->{_code}->($data);
}

sub clone_and_clean {
    no strict 'refs';

    my ($self, $data) = @_;
    my $clone = &{$self->{_cd}{clone_func}}($data);
    $self->clean_in_place($clone);
}

1;
# ABSTRACT: Clean data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Clean - Clean data structure

=head1 VERSION

This document describes version 0.507 of Data::Clean (from Perl distribution Data-Clean), released on 2020-04-07.

=head1 SYNOPSIS

 use Data::Clean;

 my $cleanser = Data::Clean->new(
     # specify how to deal with specific classes
     'DateTime'     => [call_method => 'epoch'], # replace object with its epoch
     'Time::Moment' => [call_method => 'epoch'], # replace object with its epoch
     'Regexp'       => ['stringify'], # replace $obj with "$obj"

     # specify how to deal with all scalar refs
     SCALAR         => ['deref_scalar'], # replace \1 with 1

     # specify how to deal with circular reference
     -circular      => ['clone'],

     # specify how to deal with all other kinds of objects
     -obj           => ['unbless'],

     # recurse into object
     #'!recurse_obj'=> 1,

     # generate cleaner with debugging messages
     #'!debug'      => 1,
 );

 # to get cleansed data
 my $cleansed_data = $cleanser->clone_and_clean($data);

 # to replace original data with cleansed one
 $cleanser->clean_in_place($data);

=head1 DESCRIPTION

This class can be used to process a data structure by replacing some forms of
data items with other forms. One of the main uses is to clean "unsafe" data,
e.g. clean a data structure so it can be encoded to JSON (see
L<Data::Clean::ForJSON>, which is a thin wrapper over this class).

As can be seen from the example, you specify a list of transformations to be
done, and then this class will generate an appropriate Perl code to do the
cleansing. This class is faster than the other ways of processing, e.g.
L<Data::Rmap> (see L<Bencher::Scenarios::DataCleansing> for some benchmarks).

=for Pod::Coverage ^(command_.+)$

=head1 METHODS

=head2 new(%opts) => $obj

Create a new instance.

Options specify what to do with certain category of data. Option keys are either
reference types (like C<HASH>, C<ARRAY>, C<SCALAR>) or class names (like
C<Foo::Bar>), or C<-obj> (to match all kinds of objects, a.k.a. blessed
references), C<-circular> (to match circular references), C<-ref> (to refer to
any kind of references, used to process references not handled by other
options). Option values are arrayrefs, the first element of the array is command
name, to specify what to do with the reference/class. The rest are command
arguments.

Note that arrayrefs and hashrefs are always walked into, so it's not trapped by
C<-ref>.

Default for C<%opts>: C<< -ref => 'stringify' >>.

Option keys that start with C<!> are special:

=over

=item * !recurse_obj (bool)

Can be set to true to to recurse into objects if they are hash- or array-based.
By default objects are not recursed into. Note that if you enable this option,
object options (like C<Foo::Bar> or C<-obj>) won't work for hash- and
array-based objects because they will be recursed instead.

=item * !clone_func (str)

Set fully qualified name of clone function to use. The default is to use
C<Clone::PP::clone>.

The clone module (all but the last part of the C<!clone_func> value) will
automatically be loaded using C<require()>.

=item * !debug (bool)

If set to true, will generate code to print debugging messages. For debugging
only.

=back

Available commands:

=over 4

=item * ['stringify']

This will stringify a reference like C<{}> to something like C<HASH(0x135f998)>.

=item * ['replace_with_ref']

This will replace a reference like C<{}> with C<HASH>.

=item * ['replace_with_str', STR]

This will replace a reference like C<{}> with I<STR>.

=item * ['call_method' => STR]

This will call a method named I<STR> and use its return as the replacement. For
example: C<< DateTime->from_epoch(epoch=>1000) >> when processed with C<<
[call_method => 'epoch'] >> will become 1000.

=item * ['call_func', STR]

This will call a function named I<STR> with value as argument and use its return
as the replacement.

=item * ['one_or_zero']

This will perform C<< $val ? 1:0 >>.

=item * ['deref_scalar_one_or_zero']

This will perform C<< ${$val} ? 1:0 >>.

=item * ['deref_scalar']

This will replace a scalar reference like \1 with 1.

=item * ['unbless']

This will perform unblessing using L<Function::Fallback::CoreOrPP::unbless()>.
Should be done only for objects (C<-obj>).

=item * ['die']

Die. Only for testing.

=item * ['code', STR]

This will replace with I<STR> treated as Perl code.

=item * ['clone', INT]

This command is useful if you have circular references and want to expand/copy
them. For example:

 my $def_opts = { opt1 => 'default', opt2 => 0 };
 my $users    = { alice => $def_opts, bob => $def_opts, charlie => $def_opts };

C<$users> contains three references to the same data structure. With the default
behaviour of C<< -circular => [replace_with_str => 'CIRCULAR'] >> the cleaned
data structure will be:

 { alice   => { opt1 => 'default', opt2 => 0 },
   bob     => 'CIRCULAR',
   charlie => 'CIRCULAR' }

But with C<< -circular => ['clone'] >> option, the data structure will be
cleaned to become (the C<$def_opts> is cloned):

 { alice   => { opt1 => 'default', opt2 => 0 },
   bob     => { opt1 => 'default', opt2 => 0 },
   charlie => { opt1 => 'default', opt2 => 0 }, }

The command argument specifies the number of references to clone as a limit (the
default is 50), since a cyclical structure can lead to infinite cloning. Above
this limit, the circular references will be replaced with a string
C<"CIRCULAR">. For example:

 my $a = [1]; push @$a, $a;

With C<< -circular => ['clone', 2] >> the data will be cleaned as:

 [1, [1, [1, "CIRCULAR"]]]

With C<< -circular => ['clone', 3] >> the data will be cleaned as:

 [1, [1, [1, [1, "CIRCULAR"]]]]

=back

=head2 $obj->clean_in_place($data) => $cleaned

Clean $data. Modify data in-place.

=head2 $obj->clone_and_clean($data) => $cleaned

Clean $data. Clone $data first.

=head1 ENVIRONMENT

=over

=item * LOG_CLEANSER_CODE => BOOL (default: 0)

Can be enabled if you want to see the generated cleanser code. It is logged at
level C<trace> using L<Log::ger>.

=item * LINENUM => BOOL (default: 1)

When logging cleanser code, whether to give line numbers.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Clean>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Clean>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Clean>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Related modules: L<Data::Rmap>, L<Hash::Sanitize>, L<Data::Walk>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
