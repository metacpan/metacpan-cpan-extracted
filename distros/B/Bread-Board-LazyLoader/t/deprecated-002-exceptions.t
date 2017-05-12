use strict;
use warnings;

# test of Bread::Board::LazyLoader (Yet another lazy loader)
# which loads Bread::Board containers lazily from files
use Test::More;
use Test::Exception;
use t::Utils;

use Bread::Board::LazyLoader;

subtest 'File does not exist' => sub {
    my $loader = Bread::Board::LazyLoader->new;

    my $file = 'this_file_doesnot_exist.bb';
    throws_ok {
        $loader->add_file($file);
    } qr{\QNo file '$file' found};
};

subtest 'File does not return coderef' => sub {
    my $file = create_builder_file(<<'END_FILE');
use strict;

1;
END_FILE
    my $loader = Bread::Board::LazyLoader->new(name => 'Database');
    $loader->add_file($file);
    throws_ok {
        my $c = $loader->build;
    } qr{^\QEvaluation of file '$file' did not return a coderef};
};

subtest 'File returns a coderef, which doesnot return a container' => sub {
    my $file = create_builder_file(<<'END_FILE');
use strict;
{
    package OtherObj;
    use Moose;
}

sub {
    return OtherObj->new;
};

END_FILE
    my $loader = Bread::Board::LazyLoader->new;
    $loader->add_file($file);
    throws_ok {
        my $c = $loader->build;
    } qr{^\QBuilder for '' did not return a container};
};

subtest 'File returns a coderef, which returns a container with different name' => sub {
    my $file = create_builder_file(<<'END_FILE');
use strict;
use Bread::Board;
sub {
    container C => as {
    };
}
END_FILE
    my $loader = Bread::Board::LazyLoader->new(name => 'WebServices');
    $loader->add_file($file);
    throws_ok {
        my $c = $loader->build;
    } qr{^\QBuilder for '' returned container with unexpected name ('C')};
};

done_testing();
# vim: expandtab:shiftwidth=4:tabstop=4:softtabstop=0:textwidth=78: 
