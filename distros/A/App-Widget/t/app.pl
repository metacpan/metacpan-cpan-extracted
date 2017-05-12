$conf = {
  Session => {
    default => {
      sessionClass => "App::Session::CGI",
    },
  },
  Standard => {
    'Log-Dispatch' => {
      logdir => '/var/app',
    }
  },
  Authen => {
    passwd => '/etc/passwd',
    seed => 303292,
  },
  Repository => {
    default => {
      repositoryClass => "App::Repository::DBI",
      dbidriver => "mysql",
      dbname => "test",
      dbuser => "dbuser",
      dbpass => "dbuser7",
    },
    test => {
      repositoryClass => "App::Repository::DBI",
      dbidriver => "mysql",
      dbname => "test",
      dbuser => "dbuser",
      dbpass => "dbuser7",
    },
  },
  SharedResourceSet => {
    default => {
      sharedResourceSetClass => "App::SharedResourceSet::IPCLocker",
    },
  },
};

