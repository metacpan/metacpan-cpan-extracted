use Test::More;
use File::Find;
my @modules;
find(
    sub {
        return unless -f && /\.pm$/;
        my $name = $File::Find::name;
        $name =~ s!.*lib/!!;
        $name =~ s|\.pm$||;
        $name =~ s|/|::|g;
        return if $name eq 'Beagle::Web::Router';
        push @modules, $name;
    },
    'lib'
);

for my $module (@modules) {
    use_ok($module);
}

done_testing();
