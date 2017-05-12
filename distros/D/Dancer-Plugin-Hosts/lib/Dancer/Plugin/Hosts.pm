package Dancer::Plugin::Hosts;

use strict;
use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Handler;
use Dancer::App;

=head1 NAME

Dancer::Plugin::Hosts - Config trigger for virtual sites

=cut

our $VERSION = '0.01';

my $settings = undef;
my %hosts;
my %excludes = map {$_ => 1} qw(alias application appdir);
my $defaultCallerModule = caller;

sub host {
    (shift =~ m#^https?://([a-z0-9\-\.]+(?:\:\d+)?)#io)[0] || 'default';
}

sub loadSettings {
    $settings = plugin_setting;

    foreach my $key (keys %$settings) {
	$hosts{host($key)} = $settings->{$key};
	$hosts{host($settings->{$key}{alias})} = $settings->{$key}
	    if $settings->{$key}{alias};
    }
}

loadSettings();

register_plugin;

my $prevHandleRequest;

{
    no warnings 'redefine';

    $prevHandleRequest = \&Dancer::Handler::handle_request;
    *Dancer::Handler::handle_request = sub {
	local $ENV{DANCER_APPDIR};
	hostTrigger(@_);
	goto &$prevHandleRequest;
    };
}



sub hostTrigger {
    my ($self, $request) = @_;

    if (exists $hosts{$request->host}) {
	my $conf = $hosts{$request->host};

	$ENV{DANCER_APPDIR} = $conf->{appdir};
	if ($conf->{application}) {
	    load_app($conf->{application});
	    Dancer::App->set_running_app($conf->{application});
	}
	else {
	    Dancer::App->set_running_app('main');
	    Dancer::_init_script_dir($defaultCallerModule);
	}
	foreach my $setting (keys %$conf) {
	    if (not exists $excludes{$setting}) {
		setting $setting => $conf->{$setting};
	    }
	}
    }
}

=head1 NOTES BEFORE

After this module has been written i found other way to make virtual hosts without this module.
Please to see L</"OTHER WAY"> section below

=head1 SYNOPSIS

This plugin doesn't have syntax commands. It has only configurable options in
Dancer config file. It changes appdir & application settings
by seeing in "Host:" HTTP header. For every site you can use different directories
and application settings in one Dancer process
(author tested from Starman + Dancer bundle). Also you can use your own signle
'App' module for some sites. Additional you can set any your own settings as
L<Dancer::setting> command does.

    use Dancer;
    use Dancer::Plugin::Hosts;

    get '/' => sub {
        template 'foo';
    };

    dance;

=head1 CONFIGURATION

=head2 Example

    plugins:
        Hosts:
	    http://app1.foo.com:
		alias: http://www.app1.foo.com
		appdir: /foo-2/dir
		application: My::App1

	    http://app1.foo2.com:
		alias: http://www.app1.foo2.com
		appdir: /foo-2/dir
		public: /where/public/dir

		# 'confdir' will be as "$appdir" setting
		# 'views' will be as "$appdir/veiws"
		# 'public' will be as "/where/public/dir"

		# Here we use same module of application as in previous example
		application: My::App1

	    http://app2.foo.com:
		alias: http://www.app2.foo.com
		appdir: /foo-3/dir

		# Here no 'application'
		# so will be used 'main' App of Dancer

	    # Here site is located at 81th port
	    http://app3.foo.com:81:
		appdir: /foo-4/dir
		application: My::App3

=head1 PLUGIN OPTIONS

=head2 appdir

I<This option is required>. If you have only one L</appdir> setting for directory
settings of one host site then other directory settings will be set to following
values (as L<Dancer> does itself):

    confdir	-> appdir
    public	-> appdir/public
    views	-> appdir/views

=head2 application

I<This option is optional>. If you will define it then the module after it will be
loaded if need through L<Dancer::load_app> command and all settings for this host will be
set for this App settings. Otherwise application will be 'main' (Dancer no App default)

=head1 OTHER WAY

=head2 Example without using this module

Here the example: one module (App) for some sites.

I<Your lib/YourApp.pm should be as:>

    package YourApp;

    use strict;
    use warnings;

    use Dancer ':syntax';

    setting apphandler => 'PSGI';

    Dancer::App->set_running_app('YourApp');

    # This and other routes ...
    get '/' => sub {
	# Static and template files will be from different directories are
	# based by host http header
	template 'index';
    };

    1;

I<Your bin/app.psgi should be as:>

    #!/usr/bin/perl
    use strict;
    use warnings;

    use Dancer;

    # The next line can miss but need for quickly loading in L<Starman> server
    use YourApp;

    use Plack::Builder;

    # Please notice that here no need ports in url
    # So for http://app1.foo.com:3000/ will work
    # http://app1.foo.com/
    my $hosts = {
      'http://app1.foo.com/' => '/appdir/1',
      'http://app2.foo.com/' => '/appdir/2'
    };

    builder {
	my $last;
	foreach my $host (keys %$hosts) {
	    $last = mount $host => sub {
		my $env = shift;
		local $ENV{DANCER_APPDIR} = $hosts->{$host};
		load_app "YourApp";
		Dancer::App->set_running_app('YourApp');
		setting appdir => $hosts->{$host};
		Dancer::Config->load;
		my $request = Dancer::Request->new( env => $env );
		Dancer->dance($request);
	    };
	 }
	$last;
    };

=head1 AUTHOR

This module has been written by Perlover <perlover@perlover.com>

=head1 LICENSE

This module is free software and is published under the same
terms as Perl itself.

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<http://github.com/Perlover/Dancer-Plugin-Hosts>.  Feel free to fork the repository and submit
pull requests!

=cut

1;
