package t::share;
use warnings;
use strict;

sub setup_request {
    my ($scheme, $req) = @_;
    $req =~ s/\r?\n/\r\n/g;
    open STDIN, '<', \$req or die "open: $!";

    $ENV{HTTPS} = 'on' if $scheme eq 'https';
    $ENV{REMOTE_ADDR} = '127.0.0.1';
    $ENV{REMOTE_PORT} = 12345;
    $ENV{SERVER_NAME} = 'localhost';
    $ENV{SERVER_PORT} = 80;

    my $line = <STDIN>;
    @ENV{qw( REQUEST_METHOD REQUEST_URI )} = split q{ }, $line;
    $_=uc for $ENV{REQUEST_METHOD};
    $ENV{QUERY_STRING} = $ENV{REQUEST_URI} =~ /\?(.*)/ ? $1 : q{};

    for ($line = <STDIN>; $line ne "\r\n"; $line = <STDIN>) {
        $line =~ s/\r?\n\z//;
        my ($name, $value) = split /:\s*/, $line, 2;
        s/-/_/g, $_=uc for $name;
        if ($name =~ /\ACONTENT_/) {
            $ENV{$name} = $value;
        } else {
            $ENV{"HTTP_$name"} = $value;
        }
    }

    if ($ENV{REQUEST_METHOD} eq 'POST' && $ENV{CONTENT_LENGTH} eq 'AUTO') {
        $ENV{CONTENT_LENGTH} = length($req) - tell STDIN;
    }

    return;
}


1;
