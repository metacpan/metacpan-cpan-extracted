use strictures 1;
use Test::More;
use App::MyPerl;
use App::MyPerl::Rewrite;

my @fix = ([
  __LINE__, [ qw(t/global t/project) ],
  [
    qw(global::always::dev global::always project::module::dev project::module)
  ],
  [
    qw(global::always project::module)
  ],
], [
  __LINE__, [ qw(t/global t/nonexistent) ],
  [
    qw(global::always::dev global::always global::default::dev global::default)
  ],
  [
    qw(global::always global::default)
  ],
]);

foreach my $fix (@fix) {
  my ($line, $dirs, $dev_result, $result) = @$fix;
  my %args;
  @args{qw(global_config_dir project_config_dir)} = @$dirs;
  my $myperl = App::MyPerl->new(%args);
  is(
    join("\n", @{$myperl->modules}),
    join("\n", @$dev_result),
    "myperl modules ok (line ${line})"
  );
  my $rewrite = App::MyPerl::Rewrite->new(%args);
  is(
    join("\n", @{$rewrite->modules}),
    join("\n", @$result),
    "myperl-rewrite modules ok (line ${line})"
  );
}

done_testing;
