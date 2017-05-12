use Module::Build;

my $build = Module::Build->new
    (
     dist_version => '0.91',
     module_name => 'Activator',
     license     => 'perl',
     requires    => {
		     'Data::Dumper' => 0,
		     'Log::Log4perl' => 0,
		     'Scalar::Util' => 0,
		     'IO::Capture' => 0,
		     'Exception::Class' => 0,
		     'Test::Exception' => 0,
		     'Test::Pod' => 0,
		     'Class::StrongSingleton' => 0,
		     'Hash::Merge' => 0,
		     'Time::HiRes' => 0,
		     'Exception::Class::TryCatch' => 0,
		     'Exception::Class::DBI' => 0,
		     'Email::Send' => 0,
		     'MIME::Lite' => 0,
		     'HTML::Entities' => 0,
		     'Digest::SHA1' => 0,
		     'Crypt::CBC' => 0,
		     'MIME::Base64' => 0,
		     'CGI::Cookie' => 0,
		     'YAML::Syck' => 0,
		     'Template' => 0,
		     'Template::Plugin::HTML::Strip' => 0,

		    },

    );
$build->create_build_script;
