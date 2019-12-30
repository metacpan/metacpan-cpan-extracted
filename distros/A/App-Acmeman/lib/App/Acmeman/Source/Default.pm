package App::Acmeman::Source::Default;
use strict;
use warnings;
use parent 'App::Acmeman::Source';

sub new {
    my $self;
    shift; # Skip class name.
    eval {
	require App::Acmeman::Source::Apache;
        $self = new App::Acmeman::Source::Apache(@_);
    };
    if ($@) {
	(my $s = $@) =~ s{ at /.+$}{};
	chomp($s);
	die <<EOT;
No valid domain source configured.

You are seeing this error because acmeman was unable to load the default
domain source module.
    
The default domain source "apache" scans Apache configuration files and
extracts names listed in ServerName and ServerAlias directives which have
LetsEncrypt certificates configured.

The source module couldn't be loaded because of the following error:

"$s"    
    
If you are going to use the "apache" source, fix this error and retry.
Otherwise, please create the /etc/acmeman.conf configuration file, and
configure another domain source, for example:

    [core]
	source = file DOMAINFILE

Please, see acmeman(1) (or run "acmeman --help") for a detailed discussion
of available domain sources.    

EOT
;    
    }
    return $self;
}

1;

	
