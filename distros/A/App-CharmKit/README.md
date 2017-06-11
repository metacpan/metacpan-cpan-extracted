# NAME

App::CharmKit - ez pz charm authoring

# SYNOPSIS

    #!/usr/bin/env perl
    BEGIN {
        # Install charmkit
        system "curl -L http://charmkit.pl/setup.sh | sh";
    }

    use charm;

    pkg ['znc', 'znc-perl', 'znc-tcl', 'znc-python'],
        ensure => "present";

    my $hook_path = $ENV{JUJU_CHARM_DIR};

    file "/etc/systemd/system/znc.service", source => "$hook_path/templates/znc.service";

    my $content = template("$hook_path/templates/znc.conf", port => config 'port');
    file "/home/ubuntu/.znc/configs", ensure => "directory", owner => "ubuntu", group => "ubuntu";
    file "/home/ubuntu/.znc/configs/znc.conf",
      owner     => "ubuntu",
      group     => "ubuntu",
      content   => $content,
      on_change => sub { service znc => "restart" };

# DESCRIPTION

Sugar package for making Juju charm authoring easier. We import several
underlying packages such as [Rex](https://metacpan.org/pod/Rex) and [Path::Tiny](https://metacpan.org/pod/Path::Tiny).

# AUTHOR

Adam Stokes <adamjs@cpan.org>
