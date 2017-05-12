package App::Reg;
use strict;
use warnings;
use Exporter 'import';
# Import re, but without warnings about empty list
use re ();

our $VERSION = '1.2.5';
our @EXPORT = our @EXPORT_OK = 'reg';

sub reg {
    my ($string, $pattern, %options) = @_;

    # works like use, but it isn't done at compile time
    re->import('eval', $options{color} ? 'debugcolor' : 'debug');

    # Check if multiple matches are requested
    if ($options{global}) {
        # Saved in variable, so it wouldn't depend on wantarray()
        my @output = $string =~ /$pattern/g;
        return @output;
    }
    else {
        return $string =~ /$pattern/;
    }
}

# Return positive value
1;

__END__

=head1 NAME

App::Reg - reg RegExp debugger

=head1 SYNOPSIS

    use App::Reg;
    # NOT using qr// is recommended unless you don't want compilation
    # messages (because qr// is compiled before my module has chance
    # to load re module).
    reg 'abc', 'a.c';

=head1 DESCRIPTION

App::Reg is the module that contains logic of L<reg> utility. It
contains one method, C<reg>.

=head1 EXPORTS

All functions are exported using L<Exporter>. If you don't want this
(but why you would use this module then) try importing it using empty
list of functions.

    use App::Reg ();

=over 4

=item reg($string, $pattern, %options)

The only function in this module. It matches C<$string> using
C<$pattern> and shows Perl's regular expression debugger. It supports
two options in hash C<%options>.

Returns the matches when called in list context with C<global> option,
number of matches otherwise.

=over 8

=item color

When set to true, C<use re> is called with C<debugcolor> instead of
C<debug>.

=item global

Sets the C</g> property in RegExp and matches RegExp in list context.

=back

=back

=head1 AUTHOR

Konrad Borowski <glitchmr@myopera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Konrad Borowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
