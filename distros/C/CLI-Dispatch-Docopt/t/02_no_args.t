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
    my $opt = docopt(argv => []);

    stderr_like {
        run('MyApp::CLI' => $opt);
    } qr/MyApp::CLI run!/;
}

done_testing;

__END__

=head1 NAME

02_no_args.t

=head1 SYNOPSIS

    02_no_args.t [--foo]

=cut
