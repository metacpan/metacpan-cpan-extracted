package Array::Assign;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(
    arry_assign_i arry_assign_s
    arry_extract_i arry_extract_s
);

our $IDX_MAX = 1000;
our $VERSION = 0.01;

sub new {
    my ($cls,$idx_map) = @_;
    my $self = {};
    if(ref $idx_map eq 'HASH') {
        %$self = %$idx_map;
    } else {
        my @idx_arry;
        if(ref $idx_map eq 'ARRAY') {
            @idx_arry = @$idx_map;
        } else {
            @idx_arry = @_[1..$#_];
        }
        @{$self}{@idx_arry} = (0..$#idx_arry);
    }
    bless $self, $cls;
    return $self;
}

sub assign_s {
    my ($self,$target,%fields) = @_;
    &arry_assign_s($target, $self, %fields);
}

sub assign_i {
    shift;
    goto &arry_assign_i;
}

sub extract_s {
    my ($self,$source,%fields) = @_;
    &arry_extract_s($source, $self, %fields);
}

sub extract_i {
    shift;
    goto &arry_extract_i;
}


sub arry_assign_s(\@$%) {
    my ($target,$mapping,%assignments) = @_;
    while (my ($name,$value) = each %assignments) {
        my $idx = $mapping->{$name};
        die("Unknown name '$name'") unless defined $idx;
        $target->[$idx] = $value;
    }
    $target;
}

sub arry_assign_i(\@%)
{
    my ($target,%mappings) = @_;
    _idx_sanity_check(%mappings);
    
    @{$target}[keys %mappings] = values %mappings;
}


sub arry_extract_i(\@%)
{
    my ($source,%targets) = @_;
    _idx_sanity_check(%targets);
    while ( my ($idx,$ref) = each %targets) {
        $$ref = $source->[$idx];
    }
}

sub arry_extract_s(\@$%) {
    my ($source,$mappings,%targets) = @_;
    while (my ($name,$ref) = each %targets) {
        my $idx = $mappings->{$name};
        if(!defined $idx) {
            die("unknown parameter '$name'");
        }
        $$ref = $source->[$idx];
    }
}

sub _idx_sanity_check {
    my %mappings = @_;
    if(scalar (grep $_ > $IDX_MAX, keys %mappings) > 0) {
        die("Abnormally large index found. ".
            "Bump up \$IDX_MAX if this is not a mistake");
    }
}

__END__

=head1 NAME

Array::Assign - Assign and extract array elements by names.

=head1 SYNOPSIS

    use Array::Assign;
    
procedural interface:

    my @array;
   arry_assign_i @array, 4 => "Fifth", 0 => "First";
   ok $array[4] eq "Fifth" && $array[0] eq "First";
   
   my $mappings = { fifth => 4, second => 1 };
   
   arry_assign_s @array, $mappings, fifth => "hi", second => "bye";
   ok $array[4] eq "hi" && $array[1] eq "bye";
   
   my ($fooval,$bazval);
   
   my @arglist = qw(first foo bar baz);
   arry_extract_i @arglist, 3 => \$bazval, 1 => \$fooval;
   ok $fooval eq "foo" && $bazval eq "baz";
   
   my $emapping = { foovalue => 1, bazvalue => 3 };
   arry_extract_s @arglist, $emapping, foovalue => \$fooval, bazvalue => \$bazval;
   ok $fooval eq 'foo' && $bazval eq 'baz';
    
OO interface:

    my @array;
    my $assn = Array::Assign->new(qw(foo bar baz));
    $assn->assign_s(\@array, foo => "hi", baz => "bye");
    ok($array[0] eq 'hi' && $array[2] eq 'bye');
    
    $assn->assign_i(\@array, 0 => "first", 2 => "last");
    ok($array[0] eq 'first' && $array[2] eq 'last');
    
    my ($firstval,$lastval);
    $assn->extract_s(\@array, foo => \$firstval, baz => \$lastval);
    ok($firstval eq 'first' && $lastval eq 'last');
    $assn->extract_i(\@array, 2 => \$lastval, 0 => \$firstval);
    ok($firstval eq 'first' && $lastval eq 'last');

=head2 DESCRIPTION

C<Array::Assign> contains an object and various utilities to access and modify
array indexes based on un-ordered and hash-like string aliases.

Its main use is for sanely modifying arrays which are needed for other APIs, but
are not worth the while making classes for.

C<Array::Assign> offers both a procedural and object-oriented interface, which are
both documented below:

=head2 OO Interface

=head3 new(namelist)

Construct a new C<Array::Assign> object with a namelist. A namelist can either
be an array (or reference to one), in which case the index matching is implict
to the position of each name in C<namelist>.

If C<namelist> is a hash reference, then its keys are taken to be names, and
its values are taken to be indices.

=head3 assign_s(\@target, alias => value...)

Assign values to C<@target> based on the mappings passed to C<namelist> in C<new>.

It is an error (and will die) if you pass an alias which was not previously specified
in C<new>

=head3 assign_i(\@target, index => value..)

For each C<index>, $targed[$index] is assigned <value>. This does not strictly
have anything to do with the object, but is included for API symmetry.

Additionally, sanity checking is placed on the size of the index. If an index is
accidentally too large, your program (and possibly machine) will crash to to
excessive memory allocation. To increase the 'sanity' limit, you can set
the global package variable C<$Array::Assign::MAX_IDX>.

=head3 extract_s(\@source, alias => \$target..)

For each alias, assign the value of C<$source[$alias_idx]> to $$target, which is
a reference. This is effectively the reverse of L</assign_s>.

=head3 extract_i(\@source, idx => \$target..)

Reverse of L</assign_i>.

=head2 Procedural Interface

=head3 arry_assign_s @arry, $mapping, alias => value..

=head3 arry_assign_i @arry, idx => value..

=head3 arry_extract_s @source, $mapping, alias => \$target..

=head3 arry_extract_i @source, idx => \$target..

=head1 BUGS

Probably quite slow.

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2012 M. Nunberg.

You may use and distribute this software under the same terms as Perl itself.
