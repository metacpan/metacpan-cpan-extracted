# NAME

Canella - Simple Deploy Tool A La Cinnamon

# SYNOPSIS

    use Canella::DSL;

    role "production" => (
        hosts => [ qw(host1 host2) ],
    );

    task "setup:perl" => sub {
        my $host = shift;
        remote {
            on_finish { run "rm", "-rf", "xbuild" };
            run "git", "clone", "git://github.com/tagomoris/xbuild.git";
            sudo {
                run "xbuild/perl-install", "5.16.3", "/opt/local/perl-5.16";
            };
        } $host;
    };

    task "setup:apache" => sub {
        my $host = shift;
        remote {
            sudo {
                run "yum", "install", "apache2";
            }
        } $host;
    };

    task 'setup:all' => sub {
        call 'setup:perl', 'setup:apache';
    };

    task syncfiles => sub {
        my $host = shift;
        remote {
            my $dir = get "deploy_to";
            run "cd $dir && git pull";
        } $host;
    };

    task "restart:app" => sub {
        my $host = shift;
        remote {
            sudo {
                run "svc -h /service/myapp";
            }
        } $host;
    };
    task "restart:apache" => sub {
        my $host = shift;
        remote {
            sudo {
                run "apachectl restart";
            }
        } $host;
    };

    task deploy => sub {
        call 'syncfiles', 'restart:app', 'restart:apache';
    };

# INVOCATION

Based on the config file shown in SYNOPSIS, you can invoke commands like so:

    # Run perl setup on production servers
    canella --config=/path/to/config.pl production setup:perl

    # Run apache setup AND perl setup on production servers
    canella --config=/path/to/config.pl production setup:apache setup:perl

    # Or, use the shortcut we defined: setup:all
    canella --config=/path/to/config.pl production setup:all

    # Run deploy (sync files) on production servers
    canella --config=/path/to/config.pl production syncfiles

    # Restart apps (controlled via daemontools)
    canella --config=/path/to/config.pl production restart:app



# DESCRIPTION

WARNING: ALPHA QUALITY CODE!

Canella is yet another deploy tool, based on [Cinnamon](http://search.cpan.org/perldoc?Cinnamon)

# DIFFERENCES WITH Cinnamon 0.22

- Goals

    Cinnamon wants to be "simple". Canella wants to be _extendable_ and 
    _bendable_. Canella project just started, so it may not be completely there
    yet, but hopefully it will eventually get there

    Cinnamon stores state in class-variables which are sorta globals, and stuff
    like `roles` and `tasks` are stored has hashrefs. Backend fo Canella is 
    completely OO ala `Moo`, which I believe is much easier to extend.

    You can (or you should be able to, if the current code is still not there)
    easily subclass Canella and bend it to do what you want.

- Supports multiple tasks

    Cinnamon 0.22 does not support specifying multiple tasks in one invocation.
    With Canella you can do

        canella ... task1 task2 task2

- Supports recursive task calls

    While it's in their TODO, Cinnamon 0.22 doesn't support calling tasks
    recursively. Canella allows you to call other tasks from within a task:

        task foo => sub {
            call 'bar';
        };
        task bar => sub { ... }

- Concurrency works

    Cinnamon 0.22 has a broken concurrency problem where some tasks are
    repeatedly run against the same host.

- I WANT ALL THE ABOVE TO WORK NOW

    Yes, I want all the above to work now, and not in a few months or weeks.

# SEE ALSO

[Cinnamon](http://search.cpan.org/perldoc?Cinnamon)

# LICENSE

Copyright (C) Daisuke Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Daisuke Maki <daisuke@endeworks.jp>
