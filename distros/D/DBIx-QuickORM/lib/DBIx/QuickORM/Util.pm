package DBIx::QuickORM::Util;
use strict;
use warnings;

our $VERSION = '0.000001';

use Carp qw/croak cluck/;
use Scalar::Util qw/blessed looks_like_number refaddr/;
use Sub::Util qw/subname set_subname/;

use Module::Pluggable sub_name => '_find_mods';
BEGIN {
    *_find_paths = \&search_path;
    no strict 'refs';
    delete ${\%{__PACKAGE__ . "\::"}}{search_path};
}

use base 'Exporter';
our @EXPORT = qw{
    mod2file
    delegate
    alias
    parse_hash_arg
    merge_hash_of_objs
    find_modules
    mesh_accessors
    accessor_field_inversion
    update_subname
    mask
    unmask
    masked
    equ
};

sub equ {
    my ($a, $b, $type) = @_;

    my ($ra, $rb);
    my ($an, $bn);

    # Differences in definedness or truthiness
    return 0 if (defined($a) xor defined($b));
    return 0 if ($a xor $b);
    return 0 if (($an = looks_like_number($a)) xor ($bn = looks_like_number($b)));
    return 0 if (defined($ra = refaddr($a)) xor defined($rb = refaddr($b)));

    unless ($type) {
        $type //= 'ref'    if $ra;
        $type //= 'number' if $an;
        $type //= 'string';
    }

#    require Carp::Always;
#    Carp::Always->import();

    return ((0 + $a) == (0 + $b))                       if $type eq 'number';
    return "$a" eq "$b"                                 if $type eq 'string';
    return ($ra // refaddr($a)) == ($rb // refaddr($b)) if $type eq 'ref';

#    Carp::Always->unimport();

    croak "Invalid compare type '$type'";
}

sub update_subname {
    my ($name, $sub) = @_;
    return $sub unless subname($sub) =~ /__ANON__/;
    return set_subname $name => $sub;
}

sub parse_hash_arg {
    my $self = shift;
    return $_[0] if @_ == 1 && ref($_[0]) eq 'HASH';
    return {@_};
}

sub mod2file {
    my ($mod) = @_;

    my $file = $mod;
    $file =~ s{::}{/}g;
    $file .= ".pm";

    return $file;
}

sub delegate {
    my ($meth, $to, $to_meth) = @_;
    my $caller = caller;
    $to_meth //= $meth;

    croak "A method name must be provided as the first argument" unless $meth;
    croak "A method that returns an object to which we will delegate must be provided" unless $to;
    croak "The '$meth' method is already defined for $caller" if $caller->can($meth);
    croak "The '$to' method has not been defined for $caller" unless $caller->can($to);

    my $code = sub {
        my $self = shift;
        my $del = $self->$to or croak "'$caller->$to' did not return an object for delegation";
        return $del->$to_meth(@_);
    };

    no strict 'refs';
    *{"$caller\::$meth"} = $code;
}

sub alias {
    my ($from, $to) = @_;
    my $caller = caller;

    croak "$caller already defines the '$to' method" if $caller->can($to);

    my $sub = $caller->can($from) or croak "$caller does not have the '$from' method defined";
    no strict 'refs';
    *{"$caller\::$to"} = $sub;
}

sub merge_hash_of_objs {
    my ($hash_a, $hash_b, $merge_params) = @_;

    $hash_a //= {};
    $hash_b //= {};

    my %out;
    my %seen;

    for my $name (keys %$hash_a, keys %$hash_b) {
        next if $seen{$name}++;

        my $a = $hash_a->{$name};
        my $b = $hash_b->{$name};

        if    ($a && $b) { $out{$name} = $a->merge($b, %$merge_params) }
        elsif ($a)       { $out{$name} = $a->clone }
        elsif ($b)       { $out{$name} = $b->clone }
    }

    return \%out;
}

sub find_modules {
    my (@prefixes) = @_;

    __PACKAGE__->_find_paths(new => @prefixes);
    return __PACKAGE__->_find_mods();
}

my %ACCESSOR_FIELDS = (
    ALL          => 'NONE',
    NONE         => 'ALL',
    RELATIONS    => 'NO_RELATIONS',
    NO_RELATIONS => 'RELATIONS',
    COLUMNS      => 'NO_COLUMNS',
    NO_COLUMNS   => 'COLUMNS',
);

sub accessor_field_inversion { $ACCESSOR_FIELDS{$_[0]} }

sub mesh_accessors {
    my $out;

    for my $set (@_) {
        next unless $set;

        $out //= {};

        $out->{include}  = {%{$out->{include} // {}}, %{$set->{include}}} if $set->{include};
        $out->{exclude}  = {%{$out->{exclude} // {}}, %{$set->{exclude}}} if $set->{exclude};
        $out->{name_cbs} = [@{$out->{name_cbs} // []}, @{$set->{name_cbs}}] if $set->{name_cbs};

        if (my $inj = $set->{inject_into}) {
            $out->{inject_into} //= $inj;
        }

        for my $field (sort keys %ACCESSOR_FIELDS) {
            next unless $set->{$field};
            $out->{$field} = 1;
            $out->{$ACCESSOR_FIELDS{$field}} = 0;
        }
    }

    return $out;
}

sub mask {
    my ($wrap, %params) = @_;

    my @caller = caller;

    croak "Nothing to wrap" unless defined $wrap;
    croak("'$wrap' is not a blessed object") unless blessed($wrap);
    cluck "Wrapping an already wrapped object" if $wrap->isa('DBIx::QuickORM::Util::Mask');

    my $weaken = delete $params{weaken};
    my $mask_class = delete $params{mask_class} // 'DBIx::QuickORM::Util::Mask';

    require(mod2file($mask_class));

    croak("Invalid params passed into new: " . join ', ' => sort keys %params)
        if keys %params;

    if ($weaken) {
        Scalar::Util::weaken($wrap);

        return bless(
            ["$wrap", sub { $wrap // croak("Weakly wrapped object created at $caller[1] line $caller[2] has gone away") }],
            $mask_class,
        );
    }

    return bless(["$wrap", sub { $wrap }], $mask_class);
}

sub unmask {
    my ($mask) = @_;
    return $mask unless defined($mask) && blessed($mask) && $mask->isa('DBIx::QuickORM::Util::Mask');
    return $mask->[1]->();
}

sub masked {
    my ($mask) = @_;
    return !!0 unless defined($mask) && blessed($mask) && $mask->isa('DBIx::QuickORM::Util::Mask');
    return !!1;
}

1;
