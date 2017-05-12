use strict;
use warnings;
use Test::More skip_all => 'could not make';
use Test::Output;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Docopt;
use CLI::Dispatch::Docopt;

{
    my $opt = docopt(argv => [qw/qux --foo/]);

    stderr_like {
        run('MyApp::CLI' => $opt);
    } qr/MyApp::CLI::Qux run!/;
}

done_testing;

__END__

=head1 NAME

01_basic.t

=head1 SYNOPSIS

    01_basic.t <sub_command> [--foo]

=cut
