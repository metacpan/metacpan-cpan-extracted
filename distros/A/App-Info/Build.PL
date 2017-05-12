use Module::Build;

my $class = Module::Build->subclass(
    class => 'My::Builder',
    code => q{
        sub ACTION_code {
             use File::Spec::Functions;
             my $self = shift;
             $self->SUPER::ACTION_code(@_);
             # Copy the test scripts and then set the shebang line and make
             # sure that they're executable.
             my $from_dir = $self->localize_file_path("t/bin");
             my $to_dir = $self->localize_file_path("t/scripts");

             opendir DIR, $from_dir or die "Cannot open directory '$from_dir': $!\n";
             my @files = grep { !/^\./ } readdir DIR;
             close DIR;

             my @scripts;
             for my $bin (@files) {
                 my $script = "$to_dir/$bin";
                 push @scripts, $self->localize_file_path($script);
                 my $orig = $self->localize_file_path("t/bin/$bin");
                 $self->copy_if_modified(
                     from    => $orig,
                     to_dir  => $to_dir,
                     flatten => 1,
                 );
             }
             $self->fix_shebang_line(@scripts);
             $self->make_executable(@scripts);
             $self->add_to_cleanup($to_dir);
         }
     },
);

my $build = $class->new(
    module_name        => 'App::Info',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.2701' },
    recommends         => { 'Test::Pod'     => '1.41'   },
    requires           => { File::Spec    => 0          },
    build_requires     => {
        'Module::Build' => '0.2701',
        'Test::More'    => '0.17',
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/App-Info/',
            bugtracker => 'http://github.com/theory/app-info/issues/',
            repository => 'http://github.com/theory/app-info/',
        }
    },
);
$build->create_build_script;
