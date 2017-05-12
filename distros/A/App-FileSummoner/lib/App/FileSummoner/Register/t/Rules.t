use Modern::Perl;
use Test::Spec;

use App::FileSummoner::Register;
use App::FileSummoner::Register::Rules;

describe HasExt => sub {
    it "matches file with correct extension" => sub {
        ok( ruleMatches( HasExt('pm'), 'file.pm' ) );
    };

    it "doesn't match file with different extension" => sub {
        ok( !ruleMatches( HasExt('pm'), 'file.php' ) );
    };
};

describe IsInsideDirectory => sub {
    it "matches file which is inside given directory" => sub {
        ok( ruleMatches( IsInsideDirectory('models'), '/models/file.pm' ) );
    };

    it "doesn't match if file isn't in given directory" => sub {
        ok( !ruleMatches( IsInsideDirectory('models'), '/models/other/file.pm' ) );
    };
};

describe PathContains => sub {
    it "matches file which path contains given string" => sub {
        ok( ruleMatches( PathContains('dir1/dir2'), '/dir1/dir2/file.pm' ) );
    };

    it "doesn't match file which path doesn't contain given string" => sub {
        ok( !ruleMatches( PathContains('dir1/dir3'), '/dir1/dir2/file.pm' ) );
    };
};

sub ruleMatches {
    my ( $rule, $fileName ) = @_;
    return App::FileSummoner::Register::ruleMatches( $rule, $fileName );
}

runtests unless caller;
