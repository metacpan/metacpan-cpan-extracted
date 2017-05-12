package Acme::Text::Rhombus;

use strict;
use warnings;
use base qw(Exporter);

our ($VERSION, @EXPORT_OK);

$VERSION = '0.19';
@EXPORT_OK = qw(rhombus);

sub rhombus
{
    my %opts = @_;

    my $get_opt = sub
    {
        my ($opt, $regex) = @_;
        return (exists $opts{$opt}
            && defined $opts{$opt}
                   and $opts{$opt} =~ $regex) ? $opts{$opt} : undef;
    };

    my $lines  = $get_opt->('lines',  qr/^\d+$/)           ||      25;
    my $letter = $get_opt->('letter', qr/^[a-zA-Z]$/)      ||     'a';
    my $case   = $get_opt->('case',   qr/^(?:low|upp)er$/) || 'upper';
    my $fillup = $get_opt->('fillup', qr/^\S$/)            ||     '+';

    my %alter = (
        lower => sub { lc $_[0] },
        upper => sub { uc $_[0] },
    );
    $letter = $alter{$case}->($letter);

    $lines++ if $lines % 2 == 0;

    my ($line, $repeat, $rhombus);

    for ($line = $repeat = 1; $line <= $lines; $line++) {
        my $spaces = ($lines - $repeat) / 2;

        $rhombus .= $fillup x $spaces;
        $rhombus .= $letter x $repeat;
        $rhombus .= $fillup x $spaces;
        $rhombus .= "\n";

        $repeat = $line < ($lines / 2) ? $repeat + 2 : $repeat - 2;
        $letter = chr(ord($letter) + 1);

        if ($letter !~ /[a-zA-Z]/) {
            $letter = $alter{$case}->('a');
        }
    }

    return $rhombus;
}

1;
__END__

=head1 NAME

Acme::Text::Rhombus - Draw a rhombus with letters

=head1 SYNOPSIS

 use Acme::Text::Rhombus qw(rhombus);

 print rhombus(
     lines   =>       15,
     letter  =>      'c',
     case    =>  'upper',
     fillup  =>      '+',
 );

 __OUTPUT__
 +++++++C+++++++
 ++++++DDD++++++
 +++++EEEEE+++++
 ++++FFFFFFF++++
 +++GGGGGGGGG+++
 ++HHHHHHHHHHH++
 +IIIIIIIIIIIII+
 JJJJJJJJJJJJJJJ
 +KKKKKKKKKKKKK+
 ++LLLLLLLLLLL++
 +++MMMMMMMMM+++
 ++++NNNNNNN++++
 +++++OOOOO+++++
 ++++++PPP++++++
 +++++++Q+++++++

=head1 FUNCTIONS

=head2 rhombus

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

The fillup character. Defaults to C<+>.

=back

=head1 EXPORT

=head2 Functions

C<rhombus()> is exportable.

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
