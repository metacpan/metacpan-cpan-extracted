# Data::Hopen::Util::Data - general-purpose data-manipulation functions
package Data::Hopen::Util::Data;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000012';

use parent 'Exporter';
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    @EXPORT = qw();
    @EXPORT_OK = qw(boolify clone dedent forward_opts identical);
    %EXPORT_TAGS = (
        default => [@EXPORT],
        all => [@EXPORT, @EXPORT_OK]
    );
}

use Scalar::Util qw( refaddr blessed );

# Docs {{{1

=head1 NAME

Data::Hopen::Util::Data - general-purpose data-manipulation functions

=head1 FUNCTIONS

Nothing is exported by default --- specify C<:all> if you want it all.

=cut

# }}}1

=head2 boolify

Convert a scalar to a Boolean as Perl does, except:

=over

=item * Falsy

C</^(false|off|no)$/i>

=item * Truthy

C<"0">

=back

So C<false>, C<off>, C<no>, empty string, C<undef>, and numeric C<0> are falsy,
and all other values (including string C<'0'>) are truthy.

=cut

sub boolify {
    return false if $_[0] =~ /^(false|off|no)$/i;
    return true if $_[0] =~ /^0$/;
    return !!$_[0];
} #boolify()

=head2 clone

Clones a scalar or a reference.  Thin wrapper around L<Storable/dclone>.

=cut

sub clone {
    my $val = shift;
    return $val unless ref($val);
    return Storable::dclone($val);
} #clone()

=head2 dedent

Yet Another routine for dedenting multiline strings.  Removes the leading
horizontal whitespace on the first nonblank line from all lines.  If the first
argument is a reference, also trims for use in multiline C<q()>/C<qq()>.
Usage:

    dedent " some\n multiline string";
    dedent [], q(
        very indented
    );      # [] (or any ref) means do the extra trimming.

The extra trimming includes:

=over

=item *

Removing the initial C<\n>, if any; and

=item *

Removing trailing horizontal whitespace between the last C<\n> and the
end of the string.

=back

=cut

sub dedent {
    my $extra_trim = (@_ && ref $_[0]) ? (shift, true) : false;
    my $val = @_ ? $_[0] : $_;
    my $initial_NL;

    if($val =~ /\A\n/) {
        $initial_NL = true;
        $val =~ s/^\A\n//;
    }

    if($val =~ m/^(?<ws>\h+)\S/m) {
        $val =~ s/^$+{ws}//gm;
    }

    $val =~ s/^\h+\z//m if $extra_trim;

    return (($initial_NL && !$extra_trim) ? "\n" : '') . $val;
} #dedent()

=head2 forward_opts

Returns a list of key-value pairs extracted from a given hashref.  Usage:

    my %forwarded_opts = forward_opts(\%original_opts, [option hashref,]
                                        'name'[, 'name2'...]);

If the option hashref is given, the following can be provided:

=over

=item lc

If truthy, lower-case the key names in the output

=item '-'

If present, add C<-> to the beginning of each name in the output.
This is useful with L<Getargs::Mixed>.

=back

=cut

sub forward_opts {
    my $hrIn = shift or croak 'Need an input option set';
    croak 'Need a hashref' unless ref $hrIn eq 'HASH';
    my $hrOpts = {};
    $hrOpts = shift if ref $_[0] eq 'HASH';

    my %result;
    foreach my $name (@_) {
        next unless exists $hrIn->{$name};

        my $newname = $hrOpts->{lc} ? lc($name) : $name;
        $newname = "-$newname" if $hrOpts->{'-'};
        $result{$newname} = $hrIn->{$name}
    }

    return %result;
} #forward_opts()

=head2 identical

Return truthy if the given parameters are identical objects.
Taken from L<Test::Identity> by Paul Evans, which is licensed under the same
terms as Perl itself.

=cut

sub _describe
{
    my ( $ref ) = @_;

    if( !defined $ref ) {
        return "undef";
    }
    elsif( !refaddr $ref ) {
        return "a non-reference";
    }
    elsif( blessed $ref ) {
        return "a reference to a " . ref( $ref );
    }
    else {
        return "an anonymous " . ref( $ref ) . " ref";
    }
} #_describe()

sub identical($$)
{
    my ( $got, $expected ) = @_;

    my $got_desc = _describe $got;
    my $exp_desc = _describe $expected;

    # TODO: Consider if undef/undef ought to do this...
    if( $got_desc ne $exp_desc ) {
        return false;
    }

    if( !defined $got ) {
        # Two undefs
        return true;
    }

    my $got_addr = refaddr $got;
    my $exp_addr = refaddr $expected;

    if( $got_addr != $exp_addr ) {
        return false;
    }

    return true;
} #identical()

1;
__END__
# vi: set fdm=marker: #
