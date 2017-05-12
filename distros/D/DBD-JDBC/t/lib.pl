# Default username, password, driver name values for known databases.
sub get_defaults {
    my %defaults;
    $defaults{port} = $ENV{DBDJDBC_PORT} || 43321;
    return undef unless ($ENV{DBDJDBC_URL} or $ENV{DBDJDBC_DRIVER});
    if ($ENV{DBDJDBC_URL}) {
        if ($ENV{DBDJDBC_URL} =~ /^jdbc:opentext:basis/) {
            $defaults{driver}   = "com.opentext.basis.jdbc.BasisDriver";
            $defaults{user}     = $ENV{DBDJDBC_USER} || "user1";
            $defaults{password} = $ENV{DBDJDBC_PASSWORD} || "demo";
        }
        elsif ($ENV{DBDJDBC_URL} =~ /^jdbc:oracle/) {
            $defaults{driver}   = "oracle.jdbc.driver.OracleDriver";
            $defaults{user}     = $ENV{DBDJDBC_USER} || "scott";
            $defaults{password} = $ENV{DBDJDBC_PASSWORD} || "tiger";
        }
        elsif ($ENV{DBDJDBC_URL} =~ /^jdbc:hsqldb/) {
            $defaults{driver}   = "org.hsqldb.jdbcDriver";
            $defaults{user}     = $ENV{DBDJDBC_USER} || "sa";
            $defaults{password} = $ENV{DBDJDBC_PASSWORD} || "";
        }
    }
    elsif ($ENV{DBDJDBC_DRIVER}) {
        $defaults{driver}   = $ENV{DBDJDBC_DRIVER};
        $defaults{user}     = $ENV{DBDJDBC_USER} || "";
        $defaults{password} = $ENV{DBDJDBC_PASSWORD} || "";
    }
    \%defaults;
}



# Taken from Net::Daemon::Test
# Forks a server process.
sub start_server {
    my ($driver, $port) = @_;
    my @cmd = ($ENV{DBDJDBC_JAVA_BIN} || "java", 
               "-Djdbc.drivers=$driver", 
               "-Ddbd.port=$port", 
               "com.vizdom.dbd.jdbc.Server",
               );

    if ($^O =~ /mswin32/i) {
        require Win32;
        require Win32::Process;
        my $proc = $cmd[0];

        # Win32::Process seems to require an absolute path
        my $path;
        my @pdirs;
        if ($proc !~ /\./) {
            $proc .= ".exe";
        }
        if ($proc !~ /^\w\:\\/  &&  $proc !~ /^\\/) {
            # Doesn't look like an absolute path
            foreach my $dir (@pdirs = split(/;/, $ENV{'PATH'})) {
                if (-x "$dir/$proc") {
                    $path = "$dir/$proc";
                    last;
                }
            }
            if (!$path) {
                print STDERR ("Cannot find $proc in the following"
                              , " directories:\n");
                foreach my $dir (@pdirs) {
                    print STDERR "    $dir\n";
                }
                print STDERR "Terminating.\n";
                return undef;
            }
        } else {
            $path = $proc;
        }

        #print "Starting process: proc = $path, args = ", join(" ", @cmd), "\n";
        if (!&Win32::Process::Create($pid, $path,
                                     join(" ", @cmd), 0,
                                     Win32::Process::NORMAL_PRIORITY_CLASS(),
                                     ".")) {
            warn "Cannot create child process: "
                . Win32::FormatMessage(Win32::GetLastError());
            return undef;
        }
        return \$pid;
    }
    else {
        $pid = eval { fork() };
        if (defined($pid)) {
            if (!$pid) {
                # This is the child process, spawn the server.
                exec(@cmd);
            }
            return $pid;
        }
        else {
            return undef;
        }
    }
}

# Kills a server process.
sub stop_server {
    my $server = shift;
    if ($^O =~ /mswin32/i) {
        my $pid = $$server;
        $pid->Kill(0);  # What does this return?
    }
    else {
        kill 1, $server;
    }
}


1;
