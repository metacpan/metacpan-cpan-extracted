use Test2::V0 -no_srand => 1;

# please keep in alpha order
my @mods = qw(
  Acme::Alien::DontPanic
  Acme::Ford::Prefect
  Acme::Ford::Prefect::FFI
  Alien::Build
  Archive::Extract
  Archive::Tar
  Capture::Tiny
  File::Spec
  File::Temp
  File::chdir
  HTML::LinkExtor
  HTTP::Tiny
  Inline
  Inline::C
  Inline::CPP
  LWP::UserAgent
  Module::Build
  Net::FTP
  Shell::Config::Generate
  Shell::Guess
  Sort::Versions
  Test2::API
  Test2::V0
  Text::ParseWords
  URI
  parent
);

pass 'okay';

diag '';
diag sprintf "%25s %s", 'perl', $];

foreach my $mod (@mods) {
  my $version = eval qq{ no warnings; require $mod; \$$mod\::VERSION };
  $version = 'undefined' unless defined $version;
  diag sprintf "%25s %s", $mod, $version;
}

done_testing;
