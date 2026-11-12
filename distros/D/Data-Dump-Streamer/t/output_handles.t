use 5.012;
use strict;
use warnings;
use Test::More;
use Data::Dump::Streamer qw(Dump);

{

    package DDSOutputCapture;
    sub TIEHANDLE { bless { text => '', @_ > 1 ? %{ $_[1] } : () }, $_[0] }

    sub PRINT {
        my $self= shift;
        die "PRINT failed\n" if $self->{fail};
        $self->{text} .= join('', @_);
        $self->{callback}->() if $self->{callback};
        return 1;
    }

    package DDSOutputCaller;
    sub dump_from_package { Data::Dump::Streamer->Names('value')->Out([3]) }
}

{
    my $capture;
    {
        local *STDOUT;
        $capture= tie *STDOUT, 'DDSOutputCapture';
        Dump([1])->Names('value')->Out;
    }
    is(
        $capture->{text},
        "\$value = [ 1 ];\n",
        'void output invokes tied STDOUT PRINT'
    );
}

{
    my $text= '';
    {
        local *STDOUT;
        open STDOUT, '>', \$text or die $!;
        Dump([2])->Names('value')->Out;
    }
    is($text, "\$value = [ 2 ];\n", 'void output honors localized STDOUT');
}

{
    my $capture;
    {
        local *STDOUT;
        $capture= tie *STDOUT, 'DDSOutputCapture';
        DDSOutputCaller::dump_from_package();
    }
    is(
        $capture->{text},
        "\$value = [ 3 ];\n",
        'STDOUT dispatch is independent of the caller package'
    );
}

{
    my $d= Dump()->Names('value');
    my ($capture, $nested);
    {
        local *STDOUT;
        $capture= tie *STDOUT, 'DDSOutputCapture',
            { callback => sub { $nested= $d->Data([9])->Out }, };
        $d->Data([4])->Out;
    }
    is(
        $nested,
        "\$value = [ 9 ];\n",
        'tied PRINT may use the dumper recursively'
    );
    is(
        $capture->{text},
        "\$value = [ 4 ];\n",
        'outer output survives recursive PRINT'
    );
}

{
    my $d= Dump()->Names('value')->Data([5]);
    my ($ok, $error);
    {
        local *STDOUT;
        tie *STDOUT, 'DDSOutputCapture', { fail => 1 };
        $ok= eval { $d->Out; 1 };
        $error= $@;
    }
    ok(!$ok, 'tied PRINT failure propagates');
    like($error, qr/PRINT failed/,
        'PRINT exception survives operation cleanup');
    is(
        scalar($d->Data([6])->Out),
        "\$value = [ 6 ];\n",
        'dumper is reusable after PRINT failure'
    );
}

done_testing;
