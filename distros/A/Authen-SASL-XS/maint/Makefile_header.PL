use Devel::CheckLib;

my @inc_search = qw(/opt/local/include /usr/local/include);
my @lib_search = qw(/opt/local/lib64 /usr/local/lib64 /opt/local/lib /usr/local/lib);
my %args       = map {/^(\w+)=(.*)/} grep {/^\w+=/} @ARGV;
my $use_sasl2  = exists $args{DEFINE} and $args{DEFINE} =~ /-DSASL2/;

unless (exists $args{INC} or exists $args{LIB}) {

  my @incpath = grep {-d} @inc_search;
  my @libpath = grep {-d} @lib_search;
  my $have_sasl2 = eval {
    assert_lib(
      lib     => "sasl2",
      header  => "sasl/sasl.h",
      libpath => \@libpath,
      incpath => \@incpath
    );
    1;
  };

  if ($have_sasl2) {
    $args{DEFINE} = "-DSASL2" unless $use_sasl2;
  }
  else {
    exit(0) if $use_sasl2;
    @incpath = grep {-d} map { ("$_/sasl", $_) } @inc_search;
    check_lib_or_exit(
      lib     => "sasl",
      header  => "sasl.h",
      libpath => \@libpath,
      incpath => \@incpath
    );
  }

  $args{INC}  = join " ", map {"-I$_"} @incpath;
  $args{LIBS} = join " ", map {"-L$_"} @libpath;
  $args{LIBS} .= $have_sasl2 ? " -lsasl2" : " -lsasl";
}

