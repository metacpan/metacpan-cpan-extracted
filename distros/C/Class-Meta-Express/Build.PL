use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_tarball_name { print shift->dist_dir . ".tar.gz\n" }
        sub ACTION_latest_changes {
            my $self = shift;
            (my $dv = $self->dist_version) =~ s/^v//;
            open my $in, '<:raw', 'Changes' or die "Cannot open Changes: $!\n";
            open my $out, '>:raw', 'latest_changes.md' or die "Cannot open latest_changes.md: $!\n";
            while (<$in>) { last if /^\Q$dv\E\b/ }
            print {$out} "Changes for v$dv\n";
            while (<$in>) {
                last if /^\s*$/;
                chomp;
                if (s/^\s+-/-  /) {
                    print {$out} "\n";
                } else {
                    s/^\s+/ /;
                }
                print {$out} $_;
            }
            $self->add_to_cleanup('latest_changes.md');
        }
    },
);

$class->new(
    module_name        => 'Class::Meta::Express',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    requires           => { 'Class::Meta'   => '0.60'   },
    build_requires     => {
        'Test::More'    => '0.17',
        'Module::Build' => '0.2701',
    },
    meta-express_merge => {
        resources => {
            homepage   => 'https://search.cpan.org/dist/Class-Meta-Express/',
            bugtracker => 'https://github.com/theory/class-meta-express/issues/',
            repository => 'https://github.com/theory/class-meta-express/',
        }
    },
)->create_build_script;
