use strict;
use warnings;

use Test::More;

use version;
our(@old, @new);
BEGIN {
    @old = ('0.96', qv(3.0.0), qv(3.0.6));
    @new = (qv(3.0.7), qv(3.0.13));

    plan tests => (@old + @new) * 2 + 1;

    use_ok('Class::DBI::ViewLoader')
};

for my $version (@old) {
    change_version($version);
    is($Class::DBI::ViewLoader::_accessor_method, 'accessor_name');
    is($Class::DBI::ViewLoader::_mutator_method, 'mutator_name');
}

for my $version (@new) {
    change_version($version);
    is($Class::DBI::ViewLoader::_accessor_method, 'accessor_name_for');
    is($Class::DBI::ViewLoader::_mutator_method, 'mutator_name_for');
}

sub change_version {
    my $version = shift;
    $Class::DBI::VERSION = $version;
    Class::DBI::ViewLoader::__detect_version();
}

__END__

vim: ft=perl ts=8 sts=4 sw=4 noet sr
