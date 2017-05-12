package Devel::CodeObserver;
use strict;
use warnings;
use utf8;
use 5.010_001;

our $VERSION = "0.15";

our @WARNINGS;

use B qw(class ppname);
use B::Tap qw(tap);
use B::Tools qw(op_walk);
use Data::Dumper ();

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub null {
    my $op = shift;
    return class($op) eq "NULL";
}

sub call {
    my ($class,$code) = @_;

    my $cv = B::svref_2object($code);

    my @tap_results;

    my $root = $cv->ROOT;
    # local $B::overlay = {};
    if (not null $root) {
        op_walk {
            if (need_hook($_)) {
                my @buf = ($_);
                tap($_, $cv->ROOT, \@buf);
                push @tap_results, \@buf;
            }
        } $cv->ROOT;
    }
    if (0) {
        require B::Concise;
        my $walker = B::Concise::compile('', '', $code);
        $walker->();
    }

    my $retval = $code->();

    return (
        $retval,
        Devel::CallTrace::Result->new(
            code => $code,
            tap_results => [grep { @$_ > 1 } @tap_results],
        )
    );
}

sub need_hook {
    my $op = shift;
    return 1 if $op->name eq 'entersub';
    return 1 if $op->name eq 'padsv';
    return 1 if $op->name eq 'aelem';
    return 1 if $op->name eq 'helem';
    return 1 if $op->name eq 'null' && ppname($op->targ) eq 'pp_rv2sv';
    return 0;
}

package Devel::CallTrace::Result;

use Try::Tiny;
use constant { DEBUG => 0 };

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub dump_pairs {
    my ($self) = @_;
    my $tap_results = $self->{tap_results};
    my $code = $self->{code};

    # We should load B::Deparse lazily. Because loading B::Deparse is really slow.
    # It's really big module.
    #
    # And so, this module is mainly used for testing. And this part is only required if
    # the test case was failed. I make faster the passed test case.
    require B::Deparse;

    my @pairs;
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    for my $result (@$tap_results) {
        my $op = shift @$result;
        for my $value (@$result) {
            # take first argument if the value is scalar.
            try {
                # Suppress warnings for: sub { expect(\@p)->to_be(['a']) }
                local $SIG{__WARN__} = sub { };

                my $deparse = B::Deparse->new();
                $deparse->{curcv} = B::svref_2object($code);
                push @pairs, [
                    $deparse->deparse($op),
                    Data::Dumper::Dumper($value->[1])
                ];
            } catch {
                DEBUG && warn "[Devel::CodeObserver] [BUG]: $_";
                push @WARNINGS, "[Devel::CodeObserver] [BUG]: $_";
            };
        }
    }
    return \@pairs;
}

1;
__END__

=head1 NAME

Devel::CodeObserver - Code tracer

=head1 SYNOPSIS

    my $tracer = Devel::CodeObserver->new();
    my ($retval, $trace_data) = $tracer->call(sub { $dat->{foo}{bar} eq 200 });

=head1 DESCRIPTION

This module call the CodeRef, and fetch the Perl5 VM's temporary values.

=head1 METHODS

=over 4

=item C<< my $tracer = Devel::CodeObserver->new(); >>

Create new instance.

=item C<< $tracer->call($code: CodeRef) : (Scalar, Devel::CodeObserver::Result) >>

Call the C<$code> and get the tracing result.

=back

=head1 Devel::CodeObserver::Result's METHODS

=over 4

=item C<< $result->dump_pairs() : ArrayRef[ArrayRef[Str]] >>

Returns the pair of the dump result. Return value's each element contains ArrayRef.
Each element contains 2 values. First is the B::Deparse'd code. Second is the Dumper()'ed value.

=back

=head1 EXAMPLES

Here is the concrete example.

    use 5.014000;
    use Devel::CodeObserver;
    use Data::Dumper;

    my $dat = {
        x => {
            y => 0,
        },
        z => {
            m => [
                +{
                    n => 3
                }
            ]
        }
    };

    my $tracer = Devel::CodeObserver->new();
    my ($retval, $result) = $tracer->call(sub { $dat->{z}->{m}[0]{n} eq 4 ? 1 : 0 });
    print "RETVAL: $retval\n";
    for my $pair (@{$result->dump_pairs}) {
        my ($code, $val) = @$pair;
        print "$code => $val\n";
    }

Output is here:

    RETVAL: 0
    $$dat{'z'}{'m'}[0]{'n'} => 3
    $$dat{'z'}{'m'}[0] => {'n' => 3}
    $$dat{'z'}{'m'} => [{'n' => 3}]
    $$dat{'z'} => {'m' => [{'n' => 3}]}
    $dat => {'z' => {'m' => [{'n' => 3}]},'x' => {'y' => 0}}

Devel::CodeObserver fetches the temporary values and return it.

=head1 BUGS

=head2 LIST CONTEXT

There is no list context support. I don't want to implement this, for now.
But you can send me a patch.

=head2 METHOD CALL

This version can't handles following form:

    my $tracer = Devel::CodeObserver->new();
    $tracer->call(sub { defined($foo->bar()) });

Because B::Deparse::pp_entersub thinks next object is the `method_named` or LISTOP.
But B::Tap's b_tap_push_sv is SVOP!!!

I should fix this issue, but I have no time to fix this.

Patches welcome.

