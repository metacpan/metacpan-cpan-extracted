package Ambrosia::Utils::Util;
use strict;
use warnings;
use Carp;

use Ambrosia::error::Exceptions;

use base 'Exporter';
our @EXPORT_OK = qw/array_to_str escape_html unescape_html check_file_name pare_list pare/;

our $VERSION = 0.010;

sub array_to_str
{
    return join '_', @_ == 1 && ref $_[0] ? @{$_[0]} : (@_);
}

sub escape_html
{
    for ( shift )
    {
        return $_ unless $_;
        s/&/&amp;/sg;
        s/</&lt;/sg;
        s/>/&gt;/sg;
        s/"/&quot;/sg;
        return $_;
    }
}

sub unescape_html
{
    #my $latin = defined $self->{'.charset'}
    #            ? $self->{'.charset'} =~ /^(ISO-8859-1|WINDOWS-125[12]|KOI8-?R)$/i
    #            : 1;
    for ( shift )
    {
        s/&amp;/&/sg;
        s/&lt;/</sg;
        s/&gt;/>/sg;
        s/&quot;/"/sg;
        s/&nbsp;/ /sg;
        if ( @_ )
        {
            s/&#(\d+?);/chr($1)/ge;
            s/&#x([0-9a-f]+?);/chr(hex($1))/gei;
        }
        return $_;
    }
}

sub check_file_name
{
    my $fileName = shift;

    if ( $fileName =~ /^([\/\w.]+)$/ )
    {
        $fileName = $1;
        if ( $fileName =~ /\.\./ )
        {
            throw Ambrosia::core::Exception('Bad filename (you cannot use relative path): [' . $fileName . ']');
        }
    }
    else
    {
        throw Ambrosia::core::Exception('Bad filename: [' . $fileName . ']');
    }
    return $fileName;
}

sub pare_list
{
    my @l1 = ref $_[0] ? @{shift()} : shift;
    my @l2 = ref $_[0] ? @{shift()} : shift;

    return wantarray
        ? map { [$_, shift(@l2)] } @l1
        : [map { [$_, shift(@l2)] } @l1];
}

sub pare
{
    my @l1 = ref $_[0] ? @{shift()} : shift;
    my @l2 = ref $_[0] ? @{shift()} : shift;

    my %h;
    @h{@l1} = @l2;
    return %h;
}

1;

__END__

=head1 NAME

Ambrosia::Utils::Util - contains some tools for internal use.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::Utils::Util> contains some tools for internal use.

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
