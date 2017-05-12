use Test::Spec;
use App::FileSummoner::CreateFile;

describe CreateFile => sub {
    my $summoner;

    before sub {
        $summoner = App::FileSummoner::CreateFile->new();
    };

    describe templateVarsForFile => sub {
        it "returns file name without ext as name" => sub {
            is_deeply( $summoner->templateVarsForFile('/path/File.ext') =>
                { name => 'File' } );
        };
    };
};

runtests unless caller;
