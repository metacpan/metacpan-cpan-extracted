use Test::Spec;
use Modern::Perl;

use App::FileSummoner::Register qw(chooseSkeleton registerSkeleton);

describe Register => sub {
    before each => sub {
        App::FileSummoner::Register::unregisterAll();
    };

    it "doesn't find any skeleton if none is registered" => sub {
        is(chooseSkeleton('/path/file.pm'), undef);
    };

    it "finds matching skeleton if there is one registered" => sub {
        registerSkeleton('file.pm', 'skeleton.pm');
        is(chooseSkeleton('file.pm'), 'skeleton.pm');
    };

    it "doesn't find skeleton if fileName doesn't match registered skeleton" => sub {
        registerSkeleton('file.pm', 'skeleton.pm');
        is(chooseSkeleton('file.txt'), undef);
    };

    it "returns first matching skeleton" => sub {
        registerSkeleton('file.pm', 'skeleton.pm');
        registerSkeleton('file.pm', 'skeleton2.pm');
        is(chooseSkeleton('file.pm'), 'skeleton.pm');
    };

    it "supports multiple rules" => sub {
        registerSkeleton(['models', 'pm'] => 'model-file.pm');
        registerSkeleton(['pm'] => 'file.pm');

        is(chooseSkeleton('/path/models/file.pm'), 'model-file.pm');
        is(chooseSkeleton('/path/file.pm'), 'file.pm');
    };

    it "supports codeRef matchers" => sub {
        registerSkeleton([FalseCodeRef()], 'file.php');
        registerSkeleton([TrueCodeRef()], 'file.pm');
        is(chooseSkeleton('/path/anything.ext'), 'file.pm');
    };

    it "passes fileName to codeRef matchers" => sub {
        registerSkeleton([RegExp('php')], 'file.php');
        registerSkeleton([RegExp('pm')], 'file.pm');

        is(chooseSkeleton('/path/file.php'), 'file.php');
        is(chooseSkeleton('/path/file.pm'), 'file.pm');
    };
};

sub RegExp {
    my ($re) = @_;
    return sub {
        my ($fileName) = @_;
        return $fileName =~ /$re/;
    }
}

sub TrueCodeRef {
    return sub { 1; }
}

sub FalseCodeRef {
    return sub { 0; }
}

runtests unless caller;
