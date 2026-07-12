package DBIO::Optional::Dependencies;
# ABSTRACT: Optional dependency declarations for DBIO

use warnings;
use strict;

use Carp ();

# NO EXTERNAL NON-5.8.1 CORE DEPENDENCIES EVER (e.g. C::A::G)
# This module is to be loaded by Makefile.PM on a pristine system

# POD is generated automatically by calling _gen_pod from the
# Makefile.PL in $AUTHOR mode

# NOTE: the rationale for 2 JSON::Any versions is that
# we need the newer only to work around JSON::XS, which
# itself is an optional dep
my $min_json_any = {
  'JSON::Any'                     => '1.23',
};
my $test_and_dist_json_any = {
  'JSON::Any'                     => '1.31',
};

my $config_files = {
  'Config::Any'                   => '0',
};

my $admin_script = {
  'Text::CSV'                 => '1.16',
};

my $datetime_basic = {
  'DateTime'                      => '0.55',
  'DateTime::Format::Strptime'    => '1.2',
};

my $rdbms_sqlite = {
  'DBD::SQLite'                   => '0',
};
my $rdbms_pg = {
  'DBD::Pg'                       => '0',
};
my $rdbms_mssql_odbc = {
  'DBD::ODBC'                     => '0',
};
my $rdbms_mssql_sybase = {
  'DBD::Sybase'                   => '0',
};
my $rdbms_mysql = {
  # Accept either DBD::mysql or DBD::MariaDB (the actively maintained fork)
  ( eval { require DBD::MariaDB; 1 }
    ? ( 'DBD::MariaDB' => '0' )
    : ( 'DBD::mysql'   => '0' )
  ),
};
my $rdbms_oracle = {
  'DBD::Oracle'                   => '0',
};
my $rdbms_ase = {
  'DBD::Sybase'                   => '0',
};
my $rdbms_db2 = {
  'DBD::DB2'                      => '0',
};
my $rdbms_informix = {
  'DBD::Informix'                 => '0',
};
my $rdbms_firebird = {
  'DBD::Firebird'                 => '0',
};
my $rdbms_firebird_interbase = {
  'DBD::InterBase'                => '0',
};
my $rdbms_firebird_odbc = {
  'DBD::ODBC'                     => '0',
};
my $reqs = {
  config_files => {
    req => {
      %$config_files,
    },
    pod => {
      title => 'Config file support',
      desc => 'Modules required to parse DBIO config and profile files',
    },
  },

  admin_script => {
    req => {
      %$admin_script,
    },
    pod => {
      title => 'dbioadmin',
      desc => 'Modules required for optional dbioadmin output formats',
    },
  },

  encoded_column => {
    req => {
      'Crypt::URandom' => '0',
    },
    pod => {
      title => 'EncodedColumn',
      desc => 'Recommended stronger RNG backend for L<DBIO::EncodedColumn> salt generation',
    },
  },

  deploy => {
    req => {
    },
    pod => {
      title => 'Storage::DBI::deploy()',
      desc => 'Modules required for native Deploy (if no L<DBIO::Storage::DBI/dbio_deploy_class>, throws an exception)',
    },
  },

  test_component_accessor => {
    req => {
      'Class::Unload'             => '0.07',
    },
  },

  test_pod => {
    req => {
      'Test::Pod'                 => '1.42',
    },
  },

  test_podcoverage => {
    req => {
      'Test::Pod::Coverage'       => '1.08',
      'Pod::Coverage'             => '0.20',
    },
  },

  test_whitespace => {
    req => {
      'Test::EOL'                 => '1.0',
      'Test::NoTabs'              => '0.9',
    },
  },

  test_strictures => {
    req => {
      'Test::Strict'              => '0.20',
    },
  },

  test_prettydebug => {
    req => $min_json_any,
  },

  test_admin_script => {
    req => {
      %$admin_script,
      $^O eq 'MSWin32'
        # for script invocation argument quoting on Win32
        ? ('Win32::ShellQuote' => 0)
        : ()
      ,
    }
  },

  test_leaks_heavy => {
    req => {
      'Class::MethodCache' => '0.02',
      'PadWalker' => '1.06',
    },
  },

  test_dt => {
    req => $datetime_basic,
  },

  test_dt_sqlite => {
    req => {
      %$datetime_basic,
      # t/36datetime.t
      # t/60core.t
      'DateTime::Format::SQLite'  => '0',
    },
  },

  test_dt_mysql => {
    req => {
      %$datetime_basic,
      # (doesn't need Mysql itself)
      'DateTime::Format::MySQL'   => '0',
    },
  },

  test_dt_pg => {
    req => {
      %$datetime_basic,
      # (doesn't need PG itself)
      'DateTime::Format::Pg'      => '0.16004',
    },
  },

  # this is just for completeness as SQLite
  # is a core dep of DBIO for testing
  rdbms_sqlite => {
    req => {
      %$rdbms_sqlite,
    },
    pod => {
      title => 'SQLite support',
      desc => 'Modules required to connect to SQLite',
    },
  },

  rdbms_pg => {
    req => {
      # when changing this list make sure to adjust xt/optional_deps.t
      %$rdbms_pg,
    },
    pod => {
      title => 'PostgreSQL support',
      desc => 'Modules required to connect to PostgreSQL',
    },
  },

  rdbms_mssql_odbc => {
    req => {
      %$rdbms_mssql_odbc,
    },
    pod => {
      title => 'MSSQL support via DBD::ODBC',
      desc => 'Modules required to connect to MSSQL via DBD::ODBC',
    },
  },

  rdbms_mssql_sybase => {
    req => {
      %$rdbms_mssql_sybase,
    },
    pod => {
      title => 'MSSQL support via DBD::Sybase',
      desc => 'Modules required to connect to MSSQL via DBD::Sybase',
    },
  },

  rdbms_mysql => {
    req => {
      %$rdbms_mysql,
    },
    pod => {
      title => 'MySQL support',
      desc => 'Modules required to connect to MySQL',
    },
  },

  rdbms_oracle => {
    req => {
      %$rdbms_oracle,
    },
    pod => {
      title => 'Oracle support',
      desc => 'Modules required to connect to Oracle',
    },
  },

  rdbms_ase => {
    req => {
      %$rdbms_ase,
    },
    pod => {
      title => 'Sybase ASE support',
      desc => 'Modules required to connect to Sybase ASE',
    },
  },

  rdbms_db2 => {
    req => {
      %$rdbms_db2,
    },
    pod => {
      title => 'DB2 support',
      desc => 'Modules required to connect to DB2',
    },
  },

  rdbms_informix => {
    req => {
      %$rdbms_informix,
    },
    pod => {
      title => 'Informix support',
      desc => 'Modules required to connect to Informix',
    },
  },

  rdbms_firebird => {
    req => {
      %$rdbms_firebird,
    },
    pod => {
      title => 'Firebird support',
      desc => 'Modules required to connect to Firebird',
    },
  },

  rdbms_firebird_interbase => {
    req => {
      %$rdbms_firebird_interbase,
    },
    pod => {
      title => 'Firebird support via DBD::InterBase',
      desc => 'Modules required to connect to Firebird via DBD::InterBase',
    },
  },

  rdbms_firebird_odbc => {
    req => {
      %$rdbms_firebird_odbc,
    },
    pod => {
      title => 'Firebird support via DBD::ODBC',
      desc => 'Modules required to connect to Firebird via DBD::ODBC',
    },
  },

# the order does matter because the rdbms support group might require
# a different version that the test group
  test_rdbms_pg => {
    req => {
      ($ENV{DBIO_TEST_PG_DSN})
        ? (
          # when changing this list make sure to adjust xt/optional_deps.t
          %$rdbms_pg,
          'DBD::Pg'               => '2.009002',
        ) : ()
    },
  },

  test_rdbms_mssql_odbc => {
    req => {
      ($ENV{DBIO_TEST_MSSQL_ODBC_DSN})
        ? (
          %$rdbms_mssql_odbc,
        ) : ()
    },
  },

  test_rdbms_mssql_sybase => {
    req => {
      ($ENV{DBIO_TEST_MSSQL_DSN})
        ? (
          %$rdbms_mssql_sybase,
        ) : ()
    },
  },

  test_rdbms_mysql => {
    req => {
      ($ENV{DBIO_TEST_MYSQL_DSN})
        ? (
          %$rdbms_mysql,
        ) : ()
    },
  },

  test_rdbms_oracle => {
    req => {
      ($ENV{DBIO_TEST_ORA_DSN})
        ? (
          %$rdbms_oracle,
          'DateTime::Format::Oracle' => '0',
          'DBD::Oracle'              => '1.24',
        ) : ()
    },
  },

  test_rdbms_ase => {
    req => {
      ($ENV{DBIO_TEST_SYBASE_DSN})
        ? (
          %$rdbms_ase,
        ) : ()
    },
  },

  test_rdbms_db2 => {
    req => {
      ($ENV{DBIO_TEST_DB2_DSN})
        ? (
          %$rdbms_db2,
        ) : ()
    },
  },

  test_rdbms_informix => {
    req => {
      ($ENV{DBIO_TEST_INFORMIX_DSN})
        ? (
          %$rdbms_informix,
        ) : ()
    },
  },

  test_rdbms_firebird => {
    req => {
      ($ENV{DBIO_TEST_FIREBIRD_DSN})
        ? (
          %$rdbms_firebird,
        ) : ()
    },
  },

  test_rdbms_firebird_interbase => {
    req => {
      ($ENV{DBIO_TEST_FIREBIRD_INTERBASE_DSN})
        ? (
          %$rdbms_firebird_interbase,
        ) : ()
    },
  },

  test_rdbms_firebird_odbc => {
    req => {
      ($ENV{DBIO_TEST_FIREBIRD_ODBC_DSN})
        ? (
          %$rdbms_firebird_odbc,
        ) : ()
    },
  },

  test_memcached => {
    req => {
      ($ENV{DBIO_TEST_MEMCACHED})
        ? (
          'Cache::Memcached' => 0,
        ) : ()
    },
  },

  dist_dir => {
    req => {
      %$config_files,
      %$admin_script,
      %$test_and_dist_json_any,
      'ExtUtils::MakeMaker' => '6.64',
      'Pod::Inherit'        => '0.91',
    },
  },

  dist_upload => {
    req => {
      'CPAN::Uploader' => '0.103001',
    },
  },

};

our %req_availability_cache;


sub req_list_for {
  my ($class, $group) = @_;

  Carp::croak "req_list_for() expects a requirement group name"
    unless $group;

  my $deps = $reqs->{$group}{req}
    or Carp::croak "Requirement group '$group' does not exist";

  return { %$deps };
}



sub die_unless_req_ok_for {
  my ($class, $group) = @_;

  Carp::croak "die_unless_req_ok_for() expects a requirement group name"
    unless $group;

  $class->_check_deps($group)->{status}
    or die sprintf( "Required modules missing, unable to continue: %s\n", $class->_check_deps($group)->{missing} );
}


sub req_ok_for {
  my ($class, $group) = @_;

  Carp::croak "req_ok_for() expects a requirement group name"
    unless $group;

  return $class->_check_deps($group)->{status};
}


sub req_missing_for {
  my ($class, $group) = @_;

  Carp::croak "req_missing_for() expects a requirement group name"
    unless $group;

  return $class->_check_deps($group)->{missing};
}


sub req_errorlist_for {
  my ($class, $group) = @_;

  Carp::croak "req_errorlist_for() expects a requirement group name"
    unless $group;

  return $class->_check_deps($group)->{errorlist};
}


sub _check_deps {
  my ($class, $group) = @_;

  return $req_availability_cache{$group} ||= do {

    my $deps = $class->req_list_for ($group);

    my %errors;
    for my $mod (keys %$deps) {
      my $req_line = "require $mod;";
      if (my $ver = $deps->{$mod}) {
        $req_line .= "$mod->VERSION($ver);";
      }

      eval $req_line;

      $errors{$mod} = $@ if $@;
    }

    my $res;

    if (keys %errors) {
      my $missing = join (', ', map { $deps->{$_} ? "$_ >= $deps->{$_}" : $_ } (sort keys %errors) );
      $missing .= " (see $class for details)" if $reqs->{$group}{pod};
      $res = {
        status => 0,
        errorlist => \%errors,
        missing => $missing,
      };
    }
    else {
      $res = {
        status => 1,
        errorlist => {},
        missing => '',
      };
    }

    $res;
  };
}


sub req_group_list {
  return { map { $_ => { %{ $reqs->{$_}{req} || {} } } } (keys %$reqs) };
}

# This is to be called by the author only (automatically in Makefile.PL)

sub _gen_pod {
  my ($class, $distver, $pod_dir) = @_;

  die "No POD root dir supplied" unless $pod_dir;

  $distver ||=
    eval { require DBIO; DBIO->VERSION; }
      ||
    die
"\n\n---------------------------------------------------------------------\n" .
'Unable to load core DBIO module to determine current version, '.
'possibly due to missing dependencies. Author-mode autodocumentation ' .
"halted\n\n" . $@ .
"\n\n---------------------------------------------------------------------\n"
  ;

  # do not ask for a recent version, use 1.x API calls
  # this *may* execute on a smoker with old perl or whatnot
  require File::Path;

  (my $modfn = __PACKAGE__ . '.pm') =~ s|::|/|g;

  (my $podfn = "$pod_dir/$modfn") =~ s/\.pm$/\.pod/;
  (my $dir = $podfn) =~ s|/[^/]+$||;

  File::Path::mkpath([$dir]);

  my @chunks = (
    <<"EOC",
#########################################################################
#####################  A U T O G E N E R A T E D ########################
#########################################################################
#
# The contents of this POD file are auto-generated.  Any changes you make
# will be lost. If you need to change the generated text edit _gen_pod()
# at the end of $modfn
#
EOC
    '=head1 NAME',
    "$class - Optional module dependency specifications (for module authors)",
    '=head1 SYNOPSIS',
    <<"EOS",
Somewhere in your build-file (e.g. L<Module::Install>'s Makefile.PL):

  ...

  configure_requires 'DBIO' => '$distver';

  require $class;

  my \$deploy_deps = $class->req_list_for('deploy');

  for (keys %\$deploy_deps) {
    requires \$_ => \$deploy_deps->{\$_};
  }

  ...

Note that there are some caveats regarding C<configure_requires()>, more info
can be found at L<Module::Install/configure_requires>
EOS
    '=head1 DESCRIPTION',
    <<'EOD',
Some of the less-frequently used features of L<DBIO> have external
module dependencies on their own. In order not to burden the average user
with modules he will never use, these optional dependencies are not included
in the base Makefile.PL. Instead an exception with a descriptive message is
thrown when a specific feature is missing one or several modules required for
its operation. This module is the central holding place for  the current list
of such dependencies, for DBIO core authors, and DBIO extension
authors alike.
EOD
    '=head1 CURRENT REQUIREMENT GROUPS',
    <<'EOD',
Dependencies are organized in C<groups> and each group can list one or more
required modules, with an optional minimum version (or 0 for any version).
The group name can be used in the
EOD
  );

  for my $group (sort keys %$reqs) {
    my $p = $reqs->{$group}{pod}
      or next;

    my $modlist = $reqs->{$group}{req}
      or next;

    next unless keys %$modlist;

    push @chunks, (
      "=head2 $p->{title}",
      "$p->{desc}",
      '=over',
      ( map { "=item * $_" . ($modlist->{$_} ? " >= $modlist->{$_}" : '') } (sort keys %$modlist) ),
      '=back',
      "Requirement group: B<$group>",
    );
  }

  push @chunks, (
    '=head1 METHODS',
    '=head2 req_group_list',
    '=over',
    '=item Arguments: none',
    '=item Return Value: \%list_of_requirement_groups',
    '=back',
    <<'EOD',
This method should be used by DBIO packagers, to get a hashref of all
dependencies keyed by dependency group. Each key (group name) can be supplied
to one of the group-specific methods below.
EOD

    '=head2 req_list_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Return Value: \%list_of_module_version_pairs',
    '=back',
    <<'EOD',
This method should be used by DBIO extension authors, to determine the
version of modules a specific feature requires in the B<current> version of
DBIO. See the L</SYNOPSIS> for a real-world
example.
EOD

    '=head2 req_ok_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Return Value: 1|0',
    '=back',
    <<'EOD',
Returns true or false depending on whether all modules required by
C<$group_name> are present on the system and loadable.
EOD

    '=head2 req_missing_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Return Value: $error_message_string',
    '=back',
    <<"EOD",
Returns a single line string suitable for inclusion in larger error messages.
This method would normally be used by DBIO core-module author, to
indicate to the user that he needs to install specific modules before he will
be able to use a specific feature.

For example if some of the requirements for C<deploy> are not available,
the returned string could look like:

 
The author is expected to prepend the necessary text to this message before
returning the actual error seen by the user.
EOD

    '=head2 die_unless_req_ok_for',
    '=over',
    '=item Arguments: $group_name',
    '=back',
    <<'EOD',
Checks if L</req_ok_for> passes for the supplied C<$group_name>, and
in case of failure throws an exception including the information
from L</req_missing_for>.
EOD

    '=head2 req_errorlist_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Return Value: \%list_of_loaderrors_per_module',
    '=back',
    <<'EOD',
Returns a hashref containing the actual errors that occurred while attempting
to load each module in the requirement group.
EOD
  );

  open (my $fh, '>', $podfn) or Carp::croak "Unable to write to $podfn: $!";
  print $fh join ("\n\n", @chunks);
  print $fh "\n";
  close ($fh);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Optional::Dependencies - Optional dependency declarations for DBIO

=head1 VERSION

version 0.900001

=head1 METHODS

=head2 req_list_for

Return the dependency hash for a requirement group.

=head2 die_unless_req_ok_for

Die with a formatted message unless dependencies for a group are available.

=head2 req_ok_for

Return true when dependencies for a group are all available.

=head2 req_missing_for

Return a one-line description of missing dependencies for a group.

=head2 req_errorlist_for

Return raw module-load errors for a requirement group.

=head2 _check_deps

Internal dependency checker with memoized results.

=head2 req_group_list

Return a hashref containing all requirement groups and their dependencies.

=head2 _gen_pod

Author-only helper generating optional dependency POD documentation.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
