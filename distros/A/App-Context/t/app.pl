$conf = {
  Session => {
    default => {
      class => "App::Session::CGI",
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
      class => "App::Repository::DBI",
      dbidriver => "mysql",
      dbname => "test",
      dbuser => "dbuser",
      dbpass => "dbuser7",
    },
    test => {
      class => "App::Repository::DBI",
      dbidriver => "mysql",
      dbname => "test",
      dbuser => "dbuser",
      dbpass => "dbuser7",
    },
  },
  ResourceLocker => {
    default => {
      class => "App::ResourceLocker::IPCLocker",
    },
  },
  Serializer => {
    conf => {
      class => "App::Serializer::Properties",
    },
    properties => {
      class => "App::Serializer::Properties",
    },
    xml => {
      class => "App::Serializer::XMLSimple",
    },
    ini => {
      class => "App::Serializer::Ini",
    },
    perl => {
      class => "App::Serializer::Perl",
    },
    stor => {
      class => "App::Serializer::Storable",
    },
  },
};

