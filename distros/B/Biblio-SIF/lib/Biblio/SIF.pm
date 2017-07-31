package Biblio::SIF;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.01';

use overload q("") => \&as_string;

sub new {
    my $cls = shift;
    my $self;
    if (@_ == 1) {
        my $str = shift;
        if (ref($str) eq 'SCALAR') {
            $self = bless $str, $cls;
        }
        else {
            $self = bless \$str, $cls;
        }
    }
    else {
        my %arg = @_;
        my $str = ' ' x $cls->_min_length;
        $self = bless \$str, $cls;
        while (my ($k, $v) = each %arg) {
            $self->$k($v);
        }
    }
    return $self;
}

sub clear {
    my ($self) = @_;
    $$self = ' ' x $self->_min_length;
}

sub iterator {
    my ($cls, $file, %arg) = @_;
    my $fh;
    if (ref $file) {
        $fh = $file;
    }
    else {
        open $fh, '<', $file or die "Can't open file: $!";
        binmode $fh;
    }
    my $term = delete $arg{'terminator'};
    $term = "\x00\x0a" unless defined $term;
    return sub {
        local $/ = $term;
        my $str = <$fh>;
        return if !defined $str;
        chomp $str if $arg{'chomp'};
        bless \$str, $cls;
    };
}

sub as_hash {
    my ($self) = @_;
    return +{ map { $_ => $self->$_ } $self->fields };
}

#sub from_hash {
#    my ($cls, $h) = @_;
#    $self->$_(exists $h->{$_} ? $h->{$_} : '') for $self->fields;
#}

sub _numeric {
    my $self = shift;
    my $pos  = shift;
    my $len  = shift;
    my $val;
    if (@_) {
        $val = shift;
        die "Bad params: @_" if @_;
        substr($$self, $pos, $len) = sprintf('%-*.*d', $len, $len, $val);
    }
    else {
        no warnings 'numeric';
        $val = substr($$self, $pos, $len) + 0;
    }
    return $val;
}

sub _string {
    my $self = shift;
    my $pos  = shift;
    my $len  = shift;
    my $val;
    if (@_) {
        $val = shift;
        die "Bad params: @_" if @_;
        substr($$self, $pos, $len) = sprintf('%-*.*s', $len, $len, $val);
    }
    else {
        $val = substr($$self, $pos, $len);
        $val =~ s/ +$//;
    }
    return $val;
}
sub _date {
    my $self = shift;
    my $pos  = shift;
    my $val;
    if (@_) {
        $val = shift;
        die "Bad params: @_" if @_;
        if ($val =~ /^ *$/) {
            $val = sprintf('%10.10s', '          ');  # 10 spaces
        }
        else {
            die "Bad date: $val" if $val !~ /^\d\d\d\d\.\d\d\.\d\d$/;
            die "Date exceeds maximum: $val" if $val gt '2382.12.31';
        }
        substr($$self, $pos, 10) = $val;
    }
    else {
        $val = substr($$self, $pos, 10);
    }
    return $val;
}

sub as_string {
    my ($self) = @_;
    return $$self;
}


1;

