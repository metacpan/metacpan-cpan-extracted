package Acme::Text::Rhombus;

use strict;
use warnings;
use base qw(Exporter);
use constant LINES   => 25;
use constant FILLUP  => '.';
use constant FORWARD => 1;

our ($VERSION, @EXPORT_OK, %EXPORT_TAGS);
my @subs;

$VERSION = '0.24';
@subs = qw(rhombus rhombus_letter rhombus_digit rhombus_random);
@EXPORT_OK = @subs;
%EXPORT_TAGS = ('all' => [ @subs ]);

my $get_opt = sub
{
    my ($opts, $opt, $regex, $default) = @_;
    return (exists $opts->{$opt}
        && defined $opts->{$opt}
               and $opts->{$opt} =~ $regex) ? $opts->{$opt} : $default;
};

sub _draw_rhombus
{
    my ($mode, $lines, $char, $case, $fillup, $forward) = @_;

    my ($is_letter, $is_digit, $is_random) = ($mode eq 'letter', $mode eq 'digit', $mode eq 'random');

    my %alter = (
        lower => sub { lc $_[0] },
        upper => sub { uc $_[0] },
    );
    $char = $alter{$case}->($char) if $is_letter;

    my @chars = map chr, (48..57, 65..90, 97..122);
    $char = $chars[int(rand(@chars))] unless defined $char;

    $lines++ if $lines % 2 == 0;

    my ($line, $repeat, $rhombus);

    for ($line = $repeat = 1; $line <= $lines; $line++) {
        my $spaces = ($lines - $repeat) / 2;

        $rhombus .= $fillup x $spaces;
        $rhombus .= $char   x $repeat;
        $rhombus .= $fillup x $spaces;
        $rhombus .= "\n";

        $repeat = $line < ($lines / 2) ? $repeat + 2 : $repeat - 2;

        if ($is_letter) {
            $char = $forward ? chr(ord($char) + 1) : chr(ord($char) - 1);
        }
        elsif ($is_digit) {
            $char = $forward ? $char + 1 : $char - 1;
        }
        elsif ($is_random) {
            $char = $chars[int(rand(@chars))];
        }

        if ($is_letter && $char !~ /[a-zA-Z]/) {
            $char = $alter{$case}->($forward ? 'a' : 'z');
        }
        elsif ($is_digit and $char > 9 || $char < 0) {
            $char = $forward ? 0 : 9;
        }
    }

    return $rhombus;
}

sub rhombus { return rhombus_letter(@_); }

sub rhombus_letter
{
    my %opts = @_;

    my $lines   = $get_opt->(\%opts, 'lines',   qr/^\d+$/,             LINES);
    my $letter  = $get_opt->(\%opts, 'letter',  qr/^[a-zA-Z]$/,          'a');
    my $case    = $get_opt->(\%opts, 'case',    qr/^(?:low|upp)er$/, 'upper');
    my $fillup  = $get_opt->(\%opts, 'fillup',  qr/^\S$/,             FILLUP);
    my $forward = $get_opt->(\%opts, 'forward', qr/^[01]$/,          FORWARD);

    return _draw_rhombus('letter', $lines, $letter, $case, $fillup, $forward);
}

sub rhombus_digit
{
    my %opts = @_;

    my $lines   = $get_opt->(\%opts, 'lines',   qr/^\d+$/,    LINES);
    my $digit   = $get_opt->(\%opts, 'digit',   qr/^\d$/,         0);
    my $fillup  = $get_opt->(\%opts, 'fillup',  qr/^\S$/,    FILLUP);
    my $forward = $get_opt->(\%opts, 'forward', qr/^[01]$/, FORWARD);

    return _draw_rhombus('digit', $lines, $digit, undef, $fillup, $forward);
}

sub rhombus_random
{
    my %opts = @_;

    my $lines  = $get_opt->(\%opts, 'lines',  qr/^\d+$/,  LINES);
    my $fillup = $get_opt->(\%opts, 'fillup', qr/^\S$/,  FILLUP);

    return _draw_rhombus('random', $lines, undef, undef, $fillup, undef);
}

1;
__END__

=head1 NAME

Acme::Text::Rhombus - Draw a rhombus with letters/digits

=head1 SYNOPSIS

 use Acme::Text::Rhombus qw(rhombus);

 print rhombus(
     lines   =>       15,
     letter  =>      'c',
     case    =>  'upper',
     fillup  =>      '.',
     forward =>        1,
 );

 __OUTPUT__
 .......C.......
 ......DDD......
 .....EEEEE.....
 ....FFFFFFF....
 ...GGGGGGGGG...
 ..HHHHHHHHHHH..
 .IIIIIIIIIIIII.
 JJJJJJJJJJJJJJJ
 .KKKKKKKKKKKKK.
 ..LLLLLLLLLLL..
 ...MMMMMMMMM...
 ....NNNNNNN....
 .....OOOOO.....
 ......PPP......
 .......Q.......

=head1 FUNCTIONS

=head2 rhombus, rhombus_letter

Draws a rhombus with letters and returns it as a string.

If no option value is supplied or if it is invalid, then a default
will be silently assumed (omitting all options will return a rhombus
of 25 lines).

Given that the specified number of lines is even, it will be
incremented to satisfy the requirement of being an odd number.

Options:

=over 4

=item * C<lines>

Number of lines to be printed. Defaults to 25.

=item * C<letter>

Letter to start with. Defaults to C<a>.

=item * C<case>

Lower/upper case of the letters within the rhombus. Defaults to C<upper>.

=item * C<fillup>

The fillup character. Defaults to C<'.'>.

=item * C<forward>

Forward letter enumeration. Defaults to boolean C<1>.

=back

=head2 rhombus_digit

Draws a rhombus with digits and returns it as a string.

If no option value is supplied or if it is invalid, then a default
will be silently assumed (omitting all options will return a rhombus
of 25 lines).

Given that the specified number of lines is even, it will be
incremented to satisfy the requirement of being an odd number.

Options:

=over 4

=item * C<lines>

Number of lines to be printed. Defaults to 25.

=item * C<digit>

Digit to start with. Defaults to C<0>.

=item * C<fillup>

The fillup character. Defaults to C<'.'>.

=item * C<forward>

Forward digit enumeration. Defaults to boolean C<1>.

=back

=head2 rhombus_random

Draws a rhombus with random letters/digits and returns it as a string.

If no option value is supplied or if it is invalid, then a default
will be silently assumed (omitting all options will return a rhombus
of 25 lines).

Given that the specified number of lines is even, it will be
incremented to satisfy the requirement of being an odd number.

Options:

=over 4

=item * C<lines>

Number of lines to be printed. Defaults to 25.

=item * C<fillup>

The fillup character. Defaults to C<'.'>.

=back

=head1 EXPORT

=head2 Functions

C<rhombus(), rhombus_letter(), rhombus_digit(), rhombus_random()> are exportable.

=head2 Tags

C<:all - *()>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
