package Ambrosia::Validator::Constraint;
use strict;
use warnings;

use Ambrosia::Utils::Util qw(escape_html);

use Ambrosia::Meta;

class sealed
{
    public => [qw/name errorMessage/],
    private => [qw/constraint/],
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    $self->errorMessage = [];
    $self->constraint = sub() { return (shift(), [], []) };
}

sub check
{
    my $self = shift;
    my $v;
    ($v, $self->errorMessage) = $self->constraint->(@_);
    return $v;
}

sub error
{
    return scalar @{$_[0]->errorMessage};
}

sub Require
{
    my $self = shift;
    my %p = @_;

    unless (exists $p{notUndefined} || exists $p{notEmpty})
    {
        $p{notUndefined} = 1;
    }

    my $notUndefined_em = $p{errorMessage} || $self->name . ' not mast be undefined.';
    my $notEmpty_em = $p{errorMessage} || $self->name . ' not mast be empty.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        if ($p{notUndefined} && not defined $v)
        {
            push @$pEM, $notUndefined_em;
        }
        elsif($p{notEmpty} && !$v)
        {
            push @$pEM, $notEmpty_em;
        }
        return ($v, $pEM);
    };

    return $self;
}

sub Boolean
{
    my $self = shift;
    my %p = @_;

    my $notBoolean_em = $p{errorMessage} || $self->name . ' inposible convert to boolean.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        return (undef, $pEM) unless defined $v;
        if ( $v )
        {
            if ($v =~ /^[tT][rR][uU][eE]$/s || $v =~ /^[yY][eE][sS]$/s)
            {
                $v = 1;
            }
            elsif ($v =~ /^[fF][aA][lL][sS][eE]$/s || $v =~ /^[nN][oO]$/s)
            {
                $v = 0;
            }
            else
            {
                push @$pEM, $notBoolean_em;
            }
        }
        else
        {
            $v = 0;
        }

        return ($v, $pEM);
    };

    return $self;
}

sub Number
{
    my $self = shift;
    my %p = @_;

    my $notNumber_em = $p{errorMessage} || $self->name . ' is not number.';
    my $rangeViolation_em = $p{errorRangeViolation} || $self->name . ' have range violation.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        return (undef, $pEM) unless defined $v && length $v;

        if (($p{regexp} && $v !~ /$p{regexp}/) || ($v !~ /^[0-9]+$/s))
        {
            push @$pEM, $notNumber_em;
        }
        else
        {
            if ( (defined $p{min} && $v < $p{min}) || (defined $p{max} && $v > $p{max}) )
            {
                push @$pEM, $rangeViolation_em;
            }
        }
        return ($v, $pEM);
    };

    return $self;
}

sub Double
{
    my $self = shift;
    my %p = @_;
    $p{regexp} = qr/^\d+(?:\.\d+)?$/s;
    return $self->Number(%p);
}

sub Text
{
    goto &String;
}

sub String
{
    my $self = shift;
    my %p = @_;

    my $badFormat_em = $p{errorMessage} || 'Value not in the format.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        return ($v, $pEM) unless $v;

        if ($p{regexp} && $v !~ /$p{regexp}/)
        {
            push @$pEM, $badFormat_em;
        }
        return (escape_html($v), $pEM);
    };

    return $self;
}

sub Email
{
    my $self = shift;
    my %p = @_;
    $p{regexp} = qr/[a-z0-9-_]+@(?:[a-z0-9-_]+\.)+[a-z]{2,4}/s;
    return $self->String(%p);
}

sub StringLength
{
    my $self = shift;
    my %p = @_;

    my $notNumber_rv = $p{errorRangeViolation} || $self->name . ' length is range violation.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        my $lVal = length $v;

        if ( (defined $p{min} && $lVal < $p{min}) || (defined $p{max} && $lVal > $p{max}) )
        {
            push @$pEM, $notNumber_rv;
        }
        return (escape_html($v), $pEM);
    };

    return $self;
}

sub Date
{
    my $self = shift;
    my %p = @_;

    my $badFormat_em = $p{errorMessage} || 'Invalid format of date.';
    my $rangeViolation_em = $p{errorRangeViolation} || $self->name . ' date range violation.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        return (undef, $pEM) unless $v;

        my $err = 0;
        if ($p{format} && $v !~ /$p{format}/)
        {
            push @$pEM, $badFormat_em;
            $err = 1;
        }
        elsif(!$p{format})
        {
            if ( $v =~ /\d\d\d\d[\.\\\/-]\d\d[\.\\\/-]\d\d/s )
            {
                $v = undef if $v eq '0000-00-00';
            }
            elsif( $v =~ /(\d\d?)[\.\\\/-](\d\d?)[\.\\\/-](\d\d(?:\d\d)?)/s )
            {
                $v = sprintf("%4d-%2d-%2d", ($3 < 2000 ? $3+1900 : $3), $2, $1);
            }
            else
            {
                push @$pEM, $badFormat_em;
                $err = 1;
            }
        }

        unless ($err)
        {
            if ( (defined $p{min} && $v le $p{min}) || (defined $p{max} && $v ge $p{max}) )
            {
                push @$pEM, $rangeViolation_em . ($p{min} . '_' . $p{max}) . '---' . $v;
            }
        }
        return ($v, $pEM);
    };

    return $self;
}

sub Datetime
{
    my $self = shift;
    my %p = @_;

    my $badFormat_em = $p{errorMessage} || 'Value not in the format.';
    my $rangeViolation_em = $p{errorRangeViolation} || $self->name . ' length is range violation.';

    my $prev = $self->constraint;
    $self->constraint = sub {
        my ($v, $pEM) = $prev->(shift);

        return (undef, $pEM) unless $v;

        my $err = 0;
        if ($p{format} && $v !~ /$p{format}/)
        {
            push @$pEM, $badFormat_em;
            $err = 1;
        }
        elsif(!$p{format})
        {
            if ( $v =~ /\d\d\d\d[\.\\\/-]\d\d[\.\\\/-]\d\d \d\d:\d\d:\d\d/s )
            {
                $v = undef if $v eq '0000-00-00 00:00:00';
            }
            elsif( $v =~ /(\d\d?)[\.\\\/-](\d\d?)[\.\\\/-](\d\d(?:\d\d)?)/s )
            {
                $v = sprintf("%4d-%2d-%2d", ($3 < 100 ? $3+1900 : $3), $2, $1);
            }
            else
            {
                push @$pEM, $badFormat_em;
                $err = 1;
            }
        }

        unless ($err)
        {
            if ( (defined $p{min} && $v le $p{min}) || (defined $p{max} && $v ge $p{max}) )
            {
                push @$pEM, $rangeViolation_em;
            }
        }
        return ($v, $pEM);
    };

    return $self;
}

1;

__END__

=head1 NAME

Ambrosia::Validator::Constraint - creates constraint for entity classes.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::Validator::Constraint> creates constraint for entity classes.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
