package DBIx::QuickORM::Util;
use strict;
use warnings;

our $VERSION = '0.000014';

use Data::Dumper;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

use Module::Pluggable sub_name => '_find_mods';
BEGIN {
    *_find_paths = \&search_path;
    no strict 'refs';
    delete ${\%{__PACKAGE__ . "\::"}}{search_path};
}

use Importer Importer => 'import';

our @EXPORT_OK = qw{
    load_class
    find_modules
    merge_hash_of_objs
    clone_hash_of_objs
    column_key
    debug
};

sub column_key { return join ', ' => sort @_ }

sub load_class {
    my ($class, $prefix) = @_;

    if ($prefix) {
        $class = "${prefix}::${class}" unless $class =~ s/^\+// or $class =~ m/^$prefix\b/;
    }

    my $file = $class;
    $file =~ s{::}{/}g;
    $file .= ".pm";

    eval { require $file; $class };
}

sub find_modules {
    my (@prefixes) = @_;

    __PACKAGE__->_find_paths(new => @prefixes);
    return __PACKAGE__->_find_mods();
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

        if ($a && $b) {
            my $r = ref($a);
            my $bl = blessed($a);

            if    ($bl)           { $out{$name} = $a->merge($b, %$merge_params) }
            elsif ($r eq 'HASH')  { $out{$name} = {%$a, %$b} }
            elsif ($r eq 'ARRAY') { $out{$name} = [@$b] }                           # Second array wins
            else                  { $out{$name} = $b }                              # Second value wins

            next;
        }

        my $v  = $a // $b;
        my $r  = ref($v);
        my $bl = blessed($v);
        if    ($bl)           { $out{$name} = $v->clone(%$merge_params) }
        elsif ($r eq 'ARRAY') { $out{$name} = [@$a] }
        elsif ($r eq 'HASH')  { $out{$name} = clone_hash_of_objs($v, %$merge_params) }
        else                  { $out{$name} = $v }
    }

    return \%out;
}

sub clone_hash_of_objs {
    my ($hash, $clone_params) = @_;

    croak "Need a hashref, got '$hash'" unless ref($hash) eq 'HASH';

    my %out;
    my %seen;

    for my $name (keys %$hash) {
        my $val = $hash->{$name} or next;
        if (blessed($val)) {
            $out{$name} = $hash->{$name}->clone(%$clone_params);
            next;
        }

        my $r = ref($val);
        if ($r eq 'ARRAY') {
            $out{$name} = [@$val];
        }
        elsif ($r eq 'HASH') {
            $out{$name} = clone_hash_of_objs($val, $clone_params);
        }
    }

    return \%out;
}


sub debug {
    local $Data::Dumper::Sortkeys      = 1;
    local $Data::Dumper::Terse         = 1;
    local $Data::Dumper::Quotekeys     = 0;
    local $Data::Dumper::Deepcopy      = 1;
    local $Data::Dumper::Trailingcomma = 1;
    my $out = Dumper(@_);
    return $out if defined wantarray;
    print $out;
}

1;

__END__

=head1 EXPORTS

=over 4

=item $class_or_false = load_class($class) or die "Error: $@"

Loads the class.

On success it returns the class name.

On Failure it returns false and the $@ variable is set to the error.

=back

=cut
