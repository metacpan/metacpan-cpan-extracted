# Data::Hopen::Util::NameSet - set of strings and regexps
package Data::Hopen::Util::NameSet;
use strict;
use Data::Hopen::Base;

our $VERSION = '0.000015';

# Docs {{{1

=head1 NAME

Data::Hopen::Util::NameSet - set of names (strings or regexps)

=head1 SYNOPSIS

NameSet stores strings and regexps, and can quickly tell you whether
a given string matches one of the stored strings or regexps.

=cut

# }}}1

=head1 FUNCTIONS

=head2 new

Create a new instance.  Usage: C<< Data::Hopen::Util::Nameset->new(...) >>.
The parameters are as L</add>.

=cut

sub new {
    my $class = shift or croak 'Call as ' . __PACKAGE__ . '->new(...)';
    my $self = bless { _strings => [], _regexps => [], _RE => undef }, $class;
    $self->add(@_) if @_;
    return $self;
} #new()

=head2 add

Add one or more strings or regexps to the NameSet.  Usage:

    $instance->add(x1, x2, ...)

where each C<xn> can be a scalar, regexp, arrayref (processed recursively)
or hashref (the keys are added and the values are ignored).

=cut

sub add {
    my $self = shift or croak 'Need an instance';
    return unless @_;
    $self->{_RE} = undef;   # dirty the instance

    foreach my $arg (@_) {
        if(!ref $arg) {
            push @{$self->{_strings}}, "$arg";
        } elsif(ref $arg eq 'Regexp') {
            push @{$self->{_regexps}}, $arg;
        } elsif(ref $arg eq 'ARRAY') {
            $self->add(@$arg);
        } elsif(ref $arg eq 'HASH') {
            $self->add(keys %$arg);
        } else {
            use Data::Dumper;
            croak "I don't know how to handle this: " . Dumper($arg)
        }
    }
} #add()

=head2 contains

Return truthy if the NameSet contains the argument.  Usage:
C<< $set->contains('foo') >>.

=cut

sub contains {
    my $self = shift or croak 'Need an instance';
    $self->{_RE} = $self->_build unless $self->{_RE};   # Clean
    #say STDERR $self->{_RE};
    return shift =~ $self->{_RE};
} #contains()

=head2 smartmatch overload

For convenience, C<< 'foo' ~~ $nameset >> invokes
C<< $nameset->contains('foo') >>.  This is inspired by the Raku behaviour,
in which C<< $x ~~ $y >> calls C<< $y.ACCEPTS($x) >>

NOTE: C<< $nameset ~~ 'foo' >> (object first) is officially not supported by
this module.  This form is possible in stable perls at least through 5.26.
However, the changes (since reverted) in 5.27.7 would not have supported this
form.  See
L<http://blogs.perl.org/users/leon_timmermans/2017/12/smartmatch-in-5277.html>.
However, as far as I can tell, even 5.27.7 would have supported the
C<< 'foo' ~~ $nameset >> form.

=cut

use overload
    fallback => 1,
    '~~' => sub {
        #my ($self, $other, $swap) = @_;
        $_[0]->contains($_[1])
    };

=head2 strings

Accessor for the strings in the set.  Returns an arrayref.

=cut

sub strings { (shift)->{_strings} }

=head2 regexps

Accessor for the regexps in the set.  Returns an arrayref.

=cut

sub regexps { (shift)->{_regexps} }

=head2 complex

Returns truthy if the nameset has any regular expressions.

=cut

sub complex { @{(shift)->{_regexps}} > 0 }

=head2 _build

(Internal) Build a regex from all the strings and regexps in the set.
Returns the new regexp --- does not mutate $self.

In the current implementation, strings are matched case-sensitively.
Regexps are matched with whatever flags they were compiled with.

=cut

sub _build {
    my $self = shift or croak 'Need an instance';

    my @quoted_strs;
    if(@{$self->{_strings}}) {
        push @quoted_strs,
            join '|', map { quotemeta } @{$self->{_strings}};
            # TODO should I be using qr/\Q$_\E/ instead, since quotemeta
            # isn't quite right on 5.14?  Or should I be using 5.16+?
    }

    my $pattern = join '|', @{$self->{_regexps}}, @quoted_strs;
        # Each regexp stringifies with surrounding parens, so we
        # don't need to add any.

    return $pattern ? qr/\A(?:$pattern)\z/ : qr/(*FAIL)/;
        # If $pattern is empty, the nameset is empty (`(*FAIL)`).  Without the
        # ?:, qr// would match anything, when we want to match nothing.
} #_build()

1;
__END__
# vi: set fdm=marker: #
