package App::Munner;
$App::Munner::VERSION = '1.01';
=head1 NAME

Munner - Multi-Apps Runner

=head1 DESCRIPTION

This script "munner" run multiple apps in one commands.

=head1 Why we need this?

Some project may involves different APIs running at the background in order
to exchange information. But what if we just use munner to start these apis
in one call. It is a very handy tools to start multiple applications.

=head1 How to install it?

=head2 System perl

 cpan -i App::Munner

=head2 Perlbrew

 echo App::Munner >> ~/cpanmfile
 perlbrew install-cpanm
 perlbrew use <5.x.x>
 cat ~/cpanmfile | cpanm

=head2 Carton

 cd <to your main project>
 echo 'requires "App::Munner";' >> cpanfile
 carton install

=head1 How to use it?

=head2 System perl

after install, just call

 munner <command> <options>

=head2 Perlbrew

 perlbrew exec --with <PERL_VERSION> munner <command> <options>

=head2 carton

 carton exec munner <command> <options>

=head1 Commands and Options

 munner [start|duck|stop|restart|graceful|status|(access-|error-|)logs|help|doc] [-Aacdg] [long options...]
        -c --config       App runner config file ( default ./munner.yml )
        -d --base-dir     Global base directory ( default ../ )
        -a --app          run App
        -g --group        run Group
        -A --all          run All

=head1 What else?

=head2 Config file

To run munner, you will need a YAML format of config file.

The config file name is munner.yml

It looks like this:

 ---------------------------
 base_dir: "... base directory to find the app ..."
 apps:
    web-frontend:
        dir: "... either full path or the tail part after base_dir ..."
        run: "... command ..."
        carton: 1 or 0
    db-api:
        dir: "... path cound find the command to run ..."
        env:
            - foo: 1
            - bar: 2
        run: "... start up command ..."
    event-api:
        dir: "websrc/event-api"
        run: bin/app.pl
        carton: 1
    login-server:
        dir: websrc/login-server
        run: bin/app.pl
        carton: 1
 groups:
    database:
        ## only start these apps
        apps:
            - login-server
            - db-api
    events:
        apps:
            - login-server
            - event-api
    website:
        ## start apps and above groups
        apps:
            - web-frontend
        groups:
            - database
            - events

=head2 Where to save the config file?

By default munner will find the config file at the current directory. If you have
the config some where else, you will need to tell munner like below:

 pwd --> /home/micvu/websrc/website
 munner start -c /home/micvu/munner.yml <options> ...

If the config is in the current directory.

 pwd --> /home/micvu/websrc/website
 ls munner.yml --> munner.yml
 munner start <options> --> without telling the config file location

=head2 Command examples:

start web-frontend only

 munner start -a web-frontend

start event-api at the background and start web-frontend

 munner duck -a event-api
 munner start -a web-frontend

restart background event-api

 munner restart -a event-api 

start everything website (db, event and login)

 munner start -g website

start all apps in the config

 munner start -A

start all groups in the config?

 do we need one? and why? munner -G

show a simple help page

 munner help

show this perldoc

 either munner doc
 or perldoc App::Munner

=head1 AUTHOR

Michael Vu <micvu@cpan.org>

=head1 SUPPORT

Please submit bugs to the Bitbucket Issue Tracker: L<http://goo.gl/gHJQii>
or via email <micvu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Michael Vu.

This is free software, licensed under:

The Artistic License 2.0 (GPL Compatible)

=cut

1;
