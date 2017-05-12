use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => 'test_strictures';

use warnings;
use strict;

use Test::More;
use File::Find;
use lib 't/lib';

# The rationale is - if we can load all our optdeps
# that are related to lib/ - then we should be able to run
# perl -c checks (via syntax_ok), and all should just work
my $missing_groupdeps_present = grep
  { DBIx::Class::Schema::Loader::Optional::Dependencies->req_ok_for($_) }
  grep
    { $_ !~ /^ (?: test | rdbms | dist ) _ /x }
    keys %{DBIx::Class::Schema::Loader::Optional::Dependencies->req_group_list}
;

find({
  wanted => sub {
    -f $_ or return;
    m/\.(?: pm | pl | t )$ /ix or return;

    return if m{^(?:
      lib/DBIx/Class/Schema/Loader/Optional/Dependencies.pm         # no stictures by design (load speed sensitive)
    )$}x;

    my $f = $_;

    Test::Strict::strict_ok($f);
    Test::Strict::warnings_ok($f);

    Test::Strict::syntax_ok($f)
      if ! $missing_groupdeps_present and $f =~ /^ (?: lib  )/x;
  },
  no_chdir => 1,
}, (qw(lib t script maint)) );

done_testing;
