use utf8;
use strict;
use warnings;

package DR::Tarantool::Spaces;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;

my $LE = $] > 5.01 ? '<' : '';

=head1 NAME

DR::Tarantool::Spaces - Tarantool schema description 

=head1 SYNOPSIS

    use DR::Tarantool::Spaces;
    my $s = new DR::Tarantool::Spaces({
            1   => {
                name            => 'users',         # space name
                default_type    => 'STR',           # undescribed fields
                fields  => [
                    qw(login password role),
                    {
                        name    => 'counter',
                        type    => 'NUM'
                    },
                    {
                        name    => 'something',
                        type    => 'UTF8STR',
                    },
                    {
                        name    => 'opts',
                        type    => 'JSON',
                    }
                ],
                indexes => {
                    0   => 'login',
                    1   => [ qw(login password) ],
                    2   => {
                        name    => 'my_idx',
                        fields  => 'login',
                    },
                    3   => {
                        name    => 'my_idx2',
                        fields  => [ 'counter', 'something' ]
                    }
                }
            },

            0 => {
                ...
            }
    });

    my $f = $s->pack_field('users', 'counter', 10);
    my $f = $s->pack_field('users', 3, 10);             # the same
    my $f = $s->pack_field(1, 3, 10);                   # the same

    my $ts = $s->pack_keys([1,2,3] => 'my_idx');
    my $t = $s->pack_primary_key([1,2,3]);


=head1 DESCRIPTION

The package describes all spaces used in an application.
It supports the following field types:

=over

=item NUM, NUM64, STR

The standard L<Tarantool|http://tarantool.org> types.

=item UTF8STR

The same as B<STR>, but the string is utf8-decoded 
after it's received from the server.

=item INT & INT64

The same as B<NUM> and B<NUM64>, but contain signed values.

=item JSON

The field is encoded with L<JSON::XS> when putting
into a database, and decoded after is received back 
from the server.

=back

=head1 METHODS

=head2 new

    my $spaces = DR::Tarantool::Spaces->new( $spaces );

=cut

sub new {
    my ($class, $spaces, %opts) = @_;

    $opts{family} ||= 1;

    $spaces = {} unless defined $spaces;
    croak 'spaces must be a HASHREF' unless 'HASH' eq ref $spaces;

    my (%spaces, %fast);
    for (keys %$spaces) {
        my $s = new DR::Tarantool::Space($_ => $spaces->{ $_ }, %opts);
        $spaces{ $s->name } = $s;
        $fast{ $_ } = $s->name;
    }

    return bless {
        spaces  => \%spaces,
        fast    => \%fast,
        family  => $opts{family},
    } => ref($class) || $class;
}


sub family {
    my ($self, $family) = @_;
    return $self->{family} if @_ == 1;
    $self->{family} = $family;
    $_->family($family) for values %{ $self->{spaces} };
    return $self->{family};
}


=head2 space

Return space object by number or name.

    my $space = $spaces->space('name');
    my $space = $spaces->space(0);

=cut

sub space {
    my ($self, $space) = @_;
    croak 'space name or number is not defined' unless defined $space;
    if ($space =~ /^\d+$/) {
        croak "space '$space' is not defined"
            unless exists $self->{fast}{$space};
        return $self->{spaces}{ $self->{fast}{$space} };
    }
    croak "space '$space' is not defined"
        unless exists $self->{spaces}{$space};
    return $self->{spaces}{$space};
}


=head2 space_number

Return space number by its name.

=cut

sub space_number {
    my ($self, $space) = @_;
    return $self->space($space)->number;
}


=head2 pack_field

Packs one field into a format suitable for making a database request:

    my $field = $spaces->pack_field('space', 'field', $data);

=cut

sub pack_field {
    my ($self, $space, $field, $value) = @_;
    croak q{Usage: $spaces->pack_field('space', 'field', $value)}
        unless @_ == 4;
    return $self->space($space)->pack_field($field => $value);
}


=head2 unpack_field

Unpack one field after getting it from the server:

    my $field = $spaces->unpack_field('space', 'field', $data);

=cut

sub unpack_field {
    my ($self, $space, $field, $value) = @_;
    croak q{Usage: $spaces->unpack_field('space', 'field', $value)}
        unless @_ == 4;

    return $self->space($space)->unpack_field($field => $value);
}


=head2 pack_tuple

Pack a tuple before making database request.

    my $t = $spaces->pack_tuple('space', [ 1, 2, 3 ]);

=cut

sub pack_tuple {
    my ($self, $space, $tuple) = @_;
    croak q{Usage: $spaces->pack_tuple('space', $tuple)} unless @_ == 3;
    return $self->space($space)->pack_tuple( $tuple );
}


=head2 unpack_tuple

Unpack a tuple after getting it from the database: 

    my $t = $spaces->unpack_tuple('space', \@fields);

=cut

sub unpack_tuple {
    my ($self, $space, $tuple) = @_;
    croak q{Usage: $spaces->unpack_tuple('space', $tuple)} unless @_ == 3;
    return $self->space($space)->unpack_tuple( $tuple );
}

package DR::Tarantool::Space;
use Carp;
$Carp::Internal{ (__PACKAGE__) }++;
use JSON::XS ();
use Digest::MD5 ();


=head1 SPACES methods

=head2 new

constructor

    use DR::Tarantool::Spaces;
    my $space = DR::Tarantool::Space->new($no, $space);

=cut

sub new {
    my ($class, $no, $space, %opts) = @_;

    $opts{family} ||= 1;
    croak 'space number must conform the regexp qr{^\d+}'
        unless defined $no and $no =~ /^\d+$/;
    croak "'fields' not defined in space hash"
        unless 'ARRAY' eq ref $space->{fields};
    croak "wrong 'indexes' hash"
        if !$space->{indexes} or 'HASH' ne ref $space->{indexes};

    my $name = $space->{name};
    croak 'wrong space name: ' . (defined($name) ? $name : 'undef')
        unless $name and $name =~ /^[a-z_]\w*$/i;


    my $fqr = qr{^(?:STR|NUM|NUM64|INT|INT64|UTF8STR|JSON|MONEY|BIGMONEY)$};

    my (@fields, %fast, $default_type);
    $default_type = $space->{default_type} || 'STR';
    croak "wrong 'default_type'" unless $default_type =~ $fqr;

    for (my $no = 0; $no < @{ $space->{fields} }; $no++) {
        my $f = $space->{ fields }[ $no ];

        if (ref $f eq 'HASH') {
            push @fields => {
                name    => $f->{name} || "f$no",
                idx     => $no,
                type    => $f->{type}
            };
        } elsif(ref $f) {
            croak 'wrong field name or description';
        } else {
            push @fields => {
                name    => $f,
                idx     => $no,
                type    => $default_type,
            }
        }

        my $s = $fields[ -1 ];
        croak 'unknown field type: ' .
            (defined($s->{type}) ? $s->{type} : 'undef')
                unless $s->{type} and $s->{type} =~ $fqr;

        croak 'wrong field name: ' .
            (defined($s->{name}) ? $s->{name} : 'undef')
                unless $s->{name} and $s->{name} =~ /^[a-z_]\w*$/i;

        croak "Duplicate field name: $s->{name}" if exists $fast{ $s->{name} };
        $fast{ $s->{name} } = $no;
    }

    my %indexes;
    if ($space->{indexes}) {
        for my $no (keys %{ $space->{indexes} }) {
            my $l = $space->{indexes}{ $no };
            croak "wrong index number: $no" unless $no =~ /^\d+$/;

            my ($name, $fields);

            if ('ARRAY' eq ref $l) {
                $name = "i$no";
                $fields = $l;
            } elsif ('HASH' eq ref $l) {
                $name = $l->{name} || "i$no";
                $fields =
                    [ ref($l->{fields}) ? @{ $l->{fields} } : $l->{fields} ];
            } else {
                $name = "i$no";
                $fields = [ $l ];
            }

            croak "wrong index name: $name" unless $name =~ /^[a-z_]\w*$/i;

            for (@$fields) {
                croak "field '$_' is presend in index but isn't in fields"
                    unless exists $fast{ $_ };
            }

            $indexes{ $name } = {
                no      => $no,
                name    => $name,
                fields  => $fields
            };

        }
    }

    my $tuple_class = 'DR::Tarantool::Tuple::Instance' .
        Digest::MD5::md5_hex( join "\0", sort keys %fast );

    bless {
        fields          => \@fields,
        fast            => \%fast,
        name            => $name,
        number          => $no,
        default_type    => $default_type,
        indexes         => \%indexes,
        tuple_class     => $tuple_class,
        family          => $opts{family},
    } => ref($class) || $class;

}


sub family {
    my ($self, $family) = @_;
    return $self->{family} if @_ == 1;
    return $self->{family} = $family;
}


=head2 tuple_class

Create (or return) a class to hold tuple data.
The class is a descendant of L<DR::Tarantool::Tuple>. Returns a unique class
(package) name. If a package with such name is already exists, the method
doesn't recreate it.

=cut

sub tuple_class {
    my ($self) = @_;
    my $class = $self->{tuple_class};


    no strict 'refs';
    return $class if ${ $class . '::CREATED' };

    die unless eval "package $class; use base 'DR::Tarantool::Tuple'; 1";

    for my $fname (keys %{ $self->{fast} }) {
        my $fnumber = $self->{fast}{$fname};

        *{ $class . '::' . $fname } = eval "sub { \$_[0]->raw($fnumber) }";
    }

    ${ $class . '::CREATED' } = time;

    return $class;
}


=head2 name

Get a space name.

=cut

sub name { $_[0]{name} }


=head2 number

Get a space number.

=cut

sub number { $_[0]{number} }

sub _field {
    my ($self, $field) = @_;

    croak 'field name or number is not defined' unless defined $field;
    if ($field =~ /^\d+$/) {
        return $self->{fields}[ $field ] if $field < @{ $self->{fields} };
        return undef;
    }
    croak "field with name '$field' is not defined in this space"
        unless exists $self->{fast}{$field};
    return $self->{fields}[ $self->{fast}{$field} ];
}


=head2 field_number

Return field index by field name.

=cut

sub field_number {
    my ($self, $field) = @_;
    croak 'field name or number is not defined' unless defined $field;
    return $self->{fast}{$field} if exists $self->{fast}{$field};
    croak "Can't find field '$field' in this space";
}


=head2 tail_index

Return index of the first element that is not described in the space.

=cut

sub tail_index {
    my ($self) = @_;
    return scalar @{ $self->{fields} };
}


=head2 pack_field

Pack a field before making a database request.

=cut

sub pack_field {
    my ($self, $field, $value) = @_;
    croak q{Usage: $space->pack_field('field', $value)}
        unless @_ == 3;

    my $f = $self->_field($field);

    my $type = $f ? $f->{type} : $self->{default_type};

    if ($type eq 'JSON') {
        my $v = eval { JSON::XS->new->allow_nonref->utf8->encode( $value ) };
        croak "Can't pack json: $@" if $@;
        return $v;
    }

    my $v = $value;
    utf8::encode( $v ) if utf8::is_utf8( $v );
    return $v if $type eq 'STR' or $type eq 'UTF8STR';
    return pack "L$LE" => $v if $type eq 'NUM';
    return pack "l$LE" => $v if $type eq 'INT';
    return pack "Q$LE" => $v if $type eq 'NUM64';
    return pack "q$LE" => $v if $type eq 'INT64';

    if ($type eq 'MONEY' or $type eq 'BIGMONEY') {
        my ($r, $k) = split /\./, $v;
        for ($k) {
            $_ = '.00' unless defined $_;
            s/^\.//;
            $_ .= '0' if length $_ < 2;
            $_ = substr $_, 0, 2;
        }
        $r ||= 0;

        if ($r < 0) {
            $v = $r * 100 - $k;
        } else {
            $v = $r * 100 + $k;
        }

        return pack "l$LE", $v if $type eq 'MONEY';
        return pack "q$LE", $v;
    }


    croak 'Unknown field type:' . $type;
}


=head2 unpack_field

Unpack a single field in a server response.

=cut

sub unpack_field {
    my ($self, $field, $value) = @_;
    croak q{Usage: $space->pack_field('field', $value)}
        unless @_ == 3;

    my $f = $self->_field($field);

    my $type = $f ? $f->{type} : $self->{default_type};

    my $v = $value;
    utf8::encode( $v ) if utf8::is_utf8( $v );

    if ($type eq 'JSON') {
        $v = JSON::XS->new->allow_nonref->utf8->decode( $v );
        croak "Can't unpack json: $@" if $@;
        return $v;
    }

    $v = unpack "L$LE" => $v  if $type eq 'NUM';
    $v = unpack "l$LE" => $v  if $type eq 'INT';
    $v = unpack "Q$LE" => $v  if $type eq 'NUM64';
    $v = unpack "q$LE" => $v  if $type eq 'INT64';
    utf8::decode( $v )      if $type eq 'UTF8STR';
    if ($type eq 'MONEY' or $type eq 'BIGMONEY') {
        $v = unpack "l$LE" => $v if $type eq 'MONEY';
        $v = unpack "q$LE" => $v if $type eq 'BIGMONEY';
        my $s = '';
        if ($v < 0) {
            $v = -$v;
            $s = '-';
        }
        my $k = $v % 100;
        my $r = ($v - $k) / 100;
        $v = sprintf '%s%d.%02d', $s, $r, $k;
    }
    return $v;
}


=head2 pack_tuple

Pack a tuple to the binary protocol format:

=cut

sub pack_tuple {
    my ($self, $tuple) = @_;
    croak 'tuple must be ARRAYREF' unless 'ARRAY' eq ref $tuple;
    my @res;
    if ($self->family == 1) {
        for (my $i = 0; $i < @$tuple; $i++) {
            push @res => $self->pack_field($i, $tuple->[ $i ]);
        }
    } else {
        @res = @$tuple;
    }
    return \@res;
}


=head2 unpack_tuple

Unpack a tuple in a server response.

=cut

sub unpack_tuple {
    my ($self, $tuple) = @_;
    croak 'tuple must be ARRAYREF' unless 'ARRAY' eq ref $tuple;
    my @res;
    if ($self->family == 1) {
        for (my $i = 0; $i < @$tuple; $i++) {
            push @res => $self->unpack_field($i, $tuple->[ $i ]);
        }
    } else {
        @res = @$tuple;
    }
    return \@res;
}


sub _index {
    my ($self, $index) = @_;
    if ($index =~ /^\d+$/) {
        for (values %{ $self->{indexes} }) {
            return $_ if $_->{no} == $index;
        }
        croak "index $index is undefined";
    }

    return $self->{indexes}{$index} if exists $self->{indexes}{$index};
    croak "index `$index' is undefined";
}


=head2 index_number

returns index number by its name.

=cut

sub index_number {
    my ($self, $idx) = @_;
    croak "index name is undefined" unless defined $idx;
    return $self->_index( $idx )->{no};
}


=head2 index_name

returns index name by its number.

=cut

sub index_name {
    my ($self, $idx) = @_;
    croak "index number is undefined" unless defined $idx;
    return $self->_index( $idx )->{name};
}


sub pack_keys {
    my ($self, $keys, $idx, $disable_warn) = @_;

    $idx = $self->_index($idx);
    my $ksize = @{ $idx->{fields} };

    $keys = [[ $keys ]] unless 'ARRAY' eq ref $keys;
    unless('ARRAY' eq ref $keys->[0]) {
        if ($ksize == @$keys) {
            $keys = [ $keys ];
            carp "Ambiguous keys list (it was used as ONE key), ".
                    "Use brackets to solve the trouble."
                        if $ksize > 1 and !$disable_warn;
        } else {
            $keys = [ map { [ $_ ] } @$keys ];
        }
    }

    my @res;
    for my $k (@$keys) {
        croak "key must have $ksize elements" unless $ksize >= @$k;
        my @packed;
        for (my $i = 0; $i < @$k; $i++) {
            my $f = $self->_field($idx->{fields}[$i]);
            push @packed => $self->pack_field($f->{name}, $k->[$i])
        }
        push @res => \@packed;
    }
    return \@res;
}

sub pack_primary_key {
    my ($self, $key) = @_;

    croak 'wrong key format'
        if 'ARRAY' eq ref $key and 'ARRAY' eq ref $key->[0];

    my $t = $self->pack_keys($key, 0, 1);
    return $t->[0];
}

sub pack_operation {
    my ($self, $op) = @_;
    croak 'wrong operation' unless 'ARRAY' eq ref $op and @$op > 1;

    if ($self->family == 1) {
        my $fno = $op->[0];
        my $opname = $op->[1];

        my $f = $self->_field($fno);

        if ($opname eq 'delete') {
            croak 'wrong operation' unless @$op == 2;
            return [ $f->{idx} => $opname ];
        }

        if ($opname =~ /^(?:set|insert|add|and|or|xor)$/) {
            croak 'wrong operation' unless @$op == 3;
            return [ $f->{idx} => $opname, $self->pack_field($fno, $op->[2]) ];
        }

        if ($opname eq 'substr') {
            croak 'wrong operation11' unless @$op >= 4;
            croak 'wrong offset in substr operation' unless $op->[2] =~ /^\d+$/;
            croak 'wrong length in substr operation' unless $op->[3] =~ /^\d+$/;
            return [ $f->{idx}, $opname, $op->[2], $op->[3], $op->[4] ];
        }
        croak "unknown operation: $opname";
    }

    my $fno = $op->[1];
    my $f = $self->_field($fno);
    my @res = @$op;
    splice @res, 1, 1, $f->{idx};
    return \@res;
}

sub pack_operations {
    my ($self, $ops) = @_;

    croak 'wrong operation' unless 'ARRAY' eq ref $ops and @$ops >= 1;
    $ops = [ $ops ] unless 'ARRAY' eq ref $ops->[ 0 ];

    my @res;
    push @res => $self->pack_operation( $_ ) for @$ops;
    return \@res;
}

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=head1 VCS

The project is placed git repo on github:
L<https://github.com/dr-co/dr-tarantool/>.

=cut

1;
