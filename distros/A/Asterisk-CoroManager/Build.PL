use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Asterisk::CoroManager',
   license     => 'perl',
   requires    => {
                   'perl'                 => '5.8.8',
                   'Coro'                 => 0,
                   'Coro::AnyEvent'       => 0,
                   'IO::Socket'           => 0,
                   'Digest::MD5'          => 0,
                   'Data::Dumper::Simple' => 0,
                  },
   recommends  => {
                   Coro::EV               => 0,
                   Log::Log4perl          => 0,
                  },
  );

# Collect some info about AMI account to use for testing

my $ami_host   = $build->prompt("Specify AMI host   for test:", 'localhost');
my $ami_port   = $build->prompt("Specify AMI port   for test:", 5038       );
my $ami_user   = $build->prompt("Specify AMI user   for test:");
my $ami_secret = $build->prompt("Specify AMI secret for test:");

$build->notes(ami_host   => $ami_host  );
$build->notes(ami_port   => $ami_port  );
$build->notes(ami_user   => $ami_user  );
$build->notes(ami_secret => $ami_secret);

$build->create_build_script;
