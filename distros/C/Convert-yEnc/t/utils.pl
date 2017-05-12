=pod EVIL

http://www.yenc.org/yEnc-draft-1.txt says

    a CRLF is added to terminate a line

BUT...no matter what the encoder does, 
the yEncoded data is then transported by NNTP,
and appears at its destination with native line endings.

Therefore, C<chomp>ing the line ending in Decoder::_body is the Right Thing.
In order to test this, we need a test file with native line endings.
Thus, we have...
 
=cut

sub whats_my_line
{
    my $line = "t/Decoder.d/line";
    open  LINE, "> $line" or die "whats_my_line: Can't open $line: $!\n";
    print LINE "\n";
    close LINE;

    open  LINE, "$line" or die "whats_my_line: Can't open $line: $!\n";
    local $/ = undef;
    my $nl = <LINE>;
    close LINE;

    for ($nl)
    {
	/\r\n/ and return 'crlf';
	/\n/   and return 'lf';
	/\r/   and return 'cr';
    }

    my @nl = map { ord } split //, $nl;
    die "whats_my_line: Unknown line ending: @nl\n";
}

sub CmpFiles
{
    my($a, $b) = @_;

    local $/ = undef;

    open A, $a or die "CmpFiles: Can't open $a: $!\n";
    open B, $b or die "CmpFiles: Can't open $b: $!\n";

    my $eq = not <A> cmp <B>;

    close A;
    close B;

    $eq
}

1
