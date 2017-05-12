use Test::More tests => 4;

SKIP: {
    eval "use File::Temp qw{ tempfile tempdir } ";
    skip "File::Temp not installed", 4 if $@;

    my ($fh, $filename) = tempfile(UNLINK => 1);
    diag("using temporary program file '$filename' to test functionality");

    my $contents = <<'EOT';
use App::Rad;
App::Rad->run();

sub command {
    my $c = shift;

    $c->stash->{num} = 1;
    $c->stash->{string} = 'foo';
    $c->stash->{arrayref} = [ qw(one two three) ];
    $c->stash->{hashref} = { key => 'value' };
}

sub post_process {
    my $c = shift;

    foreach ( sort keys %{$c->stash} ) {
        print $_ . ':';
        if (ref $c->stash->{$_} eq 'ARRAY') {
            print @{ $c->stash->{$_} };
        }
        elsif (ref $c->stash->{$_} eq 'HASH') {
            print each %{ $c->stash->{$_} };
        }
        else {
            print $c->stash->{$_};
        }
        print ' ';
    }
}


EOT

    print $fh $contents;
    close $fh;
   
    my $ret = `$^X $filename command`;

    my @ret = split / /, $ret;

    # options testing (sorted alfabetically)
    is($ret[0], 'arrayref:onetwothree');
    is($ret[1], 'hashref:keyvalue');
    is($ret[2], 'num:1');
    is($ret[3], 'string:foo');
}
