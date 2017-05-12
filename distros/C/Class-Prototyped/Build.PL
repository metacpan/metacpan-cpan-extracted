use Module::Build '0.24';

my $class = Module::Build->subclass(
		class => 'Module::Build::ClassPrototyped',
		code => q{
			sub ppm_name {
				my $self = shift;
				mkdir('MSWin32-x86-multi-thread');
				return 'MSWin32-x86-multi-thread/' . $self->dist_dir;
			}

			sub ACTION_ppmzip {
				my $self = shift;

				$self->depends_on('ppmdist');
				my $ppmzip = $self->dist_dir().'.ppm.zip';
				my $ppm_name = $self->ppm_name();
				unlink($ppmzip);
				system("zip -9 $ppmzip *.ppd $ppm_name.tar.gz");
			}

			sub ACTION_ppmdist {
				my ($self) = @_;
				
				$self->depends_on('build', 'html', 'ppd');
				opendir(TEMPDIR, $self->blib().'/libdoc');
				foreach my $i (grep(!/^\.\.?$/, readdir(TEMPDIR))) {
					unlink($self->blib().'/libdoc/'.$i);
				}
				closedir(TEMPDIR);
				rmdir($self->blib().'/libdoc');
				$self->add_to_cleanup($self->ppm_name);
				$self->make_tarball($self->blib, $self->ppm_name);
			}

		},
	);


my $build = $class->new(
		module_name => 'Class::Prototyped',
		license => 'perl',
		requires => {
		},
		create_makefile_pl => 'traditional',
		create_readme => 1,
	);
$build->create_build_script;
