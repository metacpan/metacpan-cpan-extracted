package Checkster;
# ABSTRACT: Checkster is a check perl module

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT_OK = qw(check);


# constructor
sub new {
    my $class = shift;

    return bless {
        _operator => undef, 
    }, $class || ref $class;
}


# accessors
sub check {
    return Checkster->new(@_);
}

sub Checkster::not {
    my $self = shift;
    $self->_operator('not');

    $self
}

sub any {
    my $self = shift;
    $self->_operator('any');

    $self
}

sub all {
    my $self = shift;
    $self->_operator('all');

    $self
}

sub op {
    return shift->{_operator};
}

# type check
sub Checkster::array {
    my $self = shift;
    my $value = @_ > 1 ? \@_ : [ shift ];

    # one param test
    if(int(@$value) == 1){
        return ref $value->[0] eq 'ARRAY' ? 1 : 0 unless $self->op;
        return ref $value->[0] eq 'ARRAY' ? 0 : 1 if $self->op && $self->op eq 'not';
    }

    # multi param test
    if(int(@$value) > 1){
        my $res = 0;
        
        do { $res = 1; map { $res = 0 unless ref $_ eq 'ARRAY' } @$value }
            if !$self->op || $self->op eq 'all';

        map { $res = 1 if ref $_ eq 'ARRAY' } @$value 
            if $self->op && $self->op eq 'any';

        return $res;
    }
}

sub number {
    my $self = shift;
    my $value = @_ > 1 ? \@_ : [ shift ];

    # one param test
    if(int(@$value) == 1){
        return $value->[0] =~ /^[\d\.\,]+$/ ? 1 : 0 unless $self->op;
        return $value->[0] =~ /^[\d\.\,]+$/ ? 0 : 1 if $self->op && $self->op eq 'not';
    }

    # multi param test
    if(int(@$value) > 1){
        my $res = 0;
        
        do { $res = 1; map { $res = 0 unless $_  =~ /^[\d\.\,]+$/ } @$value }
            if !$self->op || $self->op eq 'all';

        map { $res = 1 if ref $_ eq 'ARRAY' } @$value 
            if $self->op && $self->op eq 'any';

        return $res;
    }
}

# bool checkers
sub true {
    my $self = shift;
    my $value = @_ > 1 ? \@_ : [ shift ];

    # one param test
    if(int(@$value) == 1){
        return $value->[0] ? 1 : 0 unless $self->op;
        return $value->[0]? 0 : 1 if $self->op && $self->op eq 'not';
    }

    # multi param test
    if(int(@$value) > 1){
        my $res = 0;
        
        do { $res = 1; map { $res = 0 unless $_ } @$value }
            if !$self->op || $self->op eq 'all';

        map { $res = 1 if $_ } @$value 
            if $self->op && $self->op eq 'any';

        return $res;
    }
}

sub false {
    return !shift->true(@_);
}


# private methods
sub _operator {
    my $self = shift;
    $self->{_operator} = $_[0] if $_[0];
}

1;
__END__

=encoding utf8

=head1 NAME

Checkster - Is a check perl module

=head1 SINOPSYS

    use Checkster 'check';

    check->true(1);
    check->false($var);
    check->not->true($var);
    check->not->false($var);

=head1 DESCRIPTION

L<Checkster> is a perl module that provide functions to make validations.

The idea is make a framework to make your work with checks and validations more
easy and intuitive.

** ATENTION **
This module is a concept, an idea that is in development to be a stable module
in fucture. It's NOT production ready!

=head1 GUIDE AND MANUAL

You can read the guide for more informations about how to use L<Checkster> and
what you can do with it.

=over 4

=item See L<Checkster::Guide> for a complete list of features.

=back

=head1 BUGS

Send bugs and feature request for author's e-mail, I<daniel.vinciguerra@bivee.com.br>.

=head1 AUTHOR

Daniel Vinciguerra <daniel.vinciguerra@bivee.com>

=cut
